--[[ This Source Code Form is subject to the terms of the Mozilla Public
     License, v. 2.0. If a copy of the MPL was not distributed with this
     file, You can obtain one at https://mozilla.org/MPL/2.0/. ]]

local ins = require 'inspect'
local lpeg_raylib_reader = require 'binding_generator/lpeg-raylib-reader'

-- configure your generation here:
local config = {
   identation = '  ',
}

local function typecheck_assert(value, _types)
   local valuetype = type(value)
   local result = false

   for i = 1, #_types do
      result = result or valuetype == _types[i]
   end

   if not result then
      local msg = "typechecking assert: '" .. table.concat(_types, "' or '") .. "' expected, got '" .. valuetype .. "' (value: '" .. ins(value) .. "')"
      error(msg, 2)
   end

   return value
end

-- TODO: rename "value" to "node" in the whole code
local function find(value, name, depth_limit, depth)
   depth = depth and depth + 1 or 1
   depth_limit = depth_limit or math.huge

   if depth > depth_limit or type(value) ~= 'table' then
      return nil, 'value is not a table'
   end

   for i = 1, #value do
      local v = value[i]

      if v.name == name then
         return v
      else
         if type(v.value) == 'table' then
            local v_result = find(v.value, name, depth_limit, depth)
            if v_result then
               return v_result
            end
         end
      end
   end

   return nil, "'" .. name .. "' not found"
end

local function guess_expression_value_type(vl)
   -- contains a cast?
   local possible_cast = find(vl, 'cast')

   if possible_cast then
      local custom_type = find(possible_cast.value, 'custom_type') -- TODO: standard types should be supported, however, for raylib, is sufficient :)
      if custom_type then
         return custom_type.value
      end
   end
end

local function extract_pointer(decl_str)
   local decl_result = typecheck_assert(decl_str, {'string'})

   local stars_s, stars_e = string.find(decl_str, '(%*+)')
   local stars = nil

   if stars_s then
      stars = string.sub(decl_str, stars_s, stars_e)
      decl_result = decl_str:sub(stars_e + 1):gsub('^(%s+)', '')
   end

   return stars, decl_result
end

-- returns {...} (like table.pack) with the following metatable:
-- __index: set result_mt as __index, result_mt contains useful methods:
--          -> insert(self, str [, pos]): works like table.insert, it also verifies if str is a string
--          -> concat(self [, separator]): returns table.concat(self, ' '), for example: {'x', 'y'} -> "x y"
--          -> remove(self [, pos]): removes the `pos` element on result (the last by default), just like table.remove
--          -> iter(self [, _start [, _end [, filter]]]) returns a iterator
--          -> move(self, from, to) moves self[from] to self[to]
--          -> swap(self, v1, v2) swaps v1 and v2; v1 and v2 should be indexes
--          -> append(self, str [, pos]) same as self[pos] = self[pos] .. str; pos by default is #self
--          -> prepend(self, str [, pos]) same as self[pos] = str .. self[pos]; pos by default is #self
-- __newindex: does typechecking when inserting a new index on result table,
--             so trying to insert a non-number field or non-string value will trigger an error.

local function new_result(...)
   local result = {}

   local result_mt = {
      insert = function(self, str, pos)
         if typecheck_assert(pos, {'number', 'nil'}) then
            table.insert(self, pos, typecheck_assert(str, {'string'}))
         else
            table.insert(self, typecheck_assert(str, {'string'}))
         end
      end,
      remove = function(self, pos)
         table.remove(self, pos or #self)
      end,
      concat = function(self, separator)
         typecheck_assert(self, {'table'})
         return table.concat(self, separator or ' ')
      end,
      iter = function(self, _start, _end, filter --[[TODO]]) -- TODO: use typecheck
         _start = typecheck_assert(_start, {'number', 'nil'})
         _end = typecheck_assert(_end, {'number', 'nil'})
         _filter = typecheck_assert(_filter, {'function', 'nil'})

         local idx = (_start or 1) - 1

         local iterator = function()
            if idx < (_end or #self) then
               idx = idx + 1
               return idx, self[idx]
            end
         end

         return iterator
      end,
      move = function(self, from, to)
         from = typecheck_assert(from, {'number'})
         to = typecheck_assert(to, {'number'})

         self:insert(self[from], to)
         self:remove(from + (from > to and 1 or 0))
      end,
      swap = function(self, v1, v2)
         v1 = typecheck_assert(v1, {'number'})
         v2 = typecheck_assert(v2, {'number'})

         local _v = self[v1]
         self[v1] = self[v2]
         self[v2] = _v
      end,
      append = function(self, str, pos)
         str = typecheck_assert(str, {'string'})
         pos = typecheck_assert(pos, {'number', 'nil'})
         pos = pos or #self
         self[pos] = self[pos] .. str
      end,
      prepend = function(self, str, pos)
         str = typecheck_assert(str, {'string'})
         pos = typecheck_assert(pos, {'number', 'nil'})
         pos = pos or #self
         self[pos] = str .. self[pos]
      end
   }

   setmetatable(result, {
      __newindex = function(tbl, key, value)
         rawset(
            tbl,
            typecheck_assert(key, {'number'}),
            typecheck_assert(value, {'string'})
         )
      end,
      __index = result_mt
   })

   local pre_values = {...}
   table.move(pre_values, 1, #pre_values, 1, result)

   return result
end

local converters = {}

local function traverse(values, separator)
   local result = new_result()

   for i = 1, #values do
      local value = values[i].value
      print('traversing ' .. i .. ' ~> ' .. values[i].name)

      local converter = converters[values[i].name]
      if not converter then
         print('converter not found: ' .. values[i].name)
      else
         local value_result = converter(values[i].value):concat(separator)
         result:insert(value_result)
      end
   end

   return result
end

function converters.void(value)
   return new_result('void')
end

function converters.basic_type(value)
   local translated_value = value

   if value == 'bool' then
      translated_value = 'boolean'
   elseif value == 'float' then
      translated_value = 'float32'
   elseif value == 'double' then
      translated_value = 'float64'
   elseif value == 'short' then
      translated_value = 'cshort'
   elseif value == 'int' then
      translated_value = 'cint'
   elseif value == 'long' then
      translated_value = 'clong'
   elseif value == 'long long' then
      translated_value = 'clonglong'
   elseif value == 'ptrdiff_t' then
      translated_value = 'cptrdiff'
   elseif value == 'char' then
      translated_value = 'cchar'
   elseif value == 'signed char' then
      translated_value = 'cschar'
   elseif value == 'unsigned char' then
      translated_value = 'cuchar'
   elseif value == 'unsigned short' then
      translated_value = 'cushort'
   elseif value == 'unsigned int' then
      translated_value = 'cuint'
   elseif value == 'unsigned long' then
      translated_value = 'culong'
   elseif value == 'unsigned long long' then
      translated_value = 'culonglong'
   elseif value == 'size_t' then
      translated_value = 'csize'
   elseif value == 'long double' then
      translated_value = 'clongdouble'
   end

   return new_result(translated_value)
end

function converters.literal(value)
   local _value = string.gsub(value, '([fF])$', '_f32')
   _value = string.gsub(_value, '([lL])$', '_f64')
   return new_result(_value)
end

function converters.custom_type(value)
   return new_result(value)
end

function converters.qualifier_name(value)
   return new_result('<' .. value .. '>')
end

function converters.specifiers_and_qualifiers(value)
   return new_result(traverse(value):concat())
end

function converters.pointer(value)
   return new_result(string.rep('*', value))
end

function converters.initializer(value)
   return new_result('=', value)
end

function converters.declarator(value)
   return new_result(traverse(value):concat())
end

function converters.declarator_and_initializer(value)
   return new_result(traverse(value):concat())
end

function converters.empty_space(value)
   return new_result(value)
end

function converters.parentheses(value)
   return new_result(value)
end

function converters.unary_operator(value)
   return new_result(value)
end

function converters.binary_operator(value)
   return new_result(value)
end

function converters.ternary_operator(value)
   return new_result(value)
end

function converters.arithmetic_expr(value)
   return new_result(traverse(value):concat())
end

function converters.values_on_braces(value)
   local result = new_result('{')
   result:insert(traverse(value):concat(', '))
   result:insert('}')
   return result
end

function converters.variadic_arg(value)
   return new_result('...')
end

function converters.cast(value)
   local result = new_result('(@')
   result:insert(traverse(value, ''):concat())
   result:insert(')')
   return result
end

function converters.expression(value)
   return new_result(traverse(value, ''):concat(''))
end

function converters.comment(value)
   return new_result('--', value)
end

function converters.identifier(value)
   return new_result(value)
end

function converters.var_decl(value)
   local list = traverse(value)
   local list_type = list[1]
   local adjusted_list = new_result()

   for i, s in list:iter(2) do
      local ptr, _s = extract_pointer(s)
      if ptr then
         s = _s
      end

      if list_type == 'void' and stars then
         ptr = 'pointer'
      end

      adjusted_list:insert(s .. ': ' .. list_type .. (ptr or ''))
   end

   return new_result(adjusted_list:concat(', '))
end

function converters.func_arg(value)
   local list = traverse(value)
   local result = new_result(list:concat())
   return result
end

function converters.func_decl(value)
   local list = traverse(value)

   list:prepend('): ', 1)
   list:move(1, #list);

   list:insert("function Raylib.", 1)
   list:insert("(", 3)
   list:insert(' end ', #list)

   local result = new_result()
   result:insert(list:concat(''))
   return result
end
function converters.struct_declaration_list(value)
   local result = new_result()
   local list = traverse(value)

   for i, s in list:iter() do
      if s ~= '' then
         s = s:gsub('^\n%s+', '\n')

         local is_comment = s:sub(1, 2) == '--'
         local space_only = s:find('^%s')

         if is_comment then
            list[i] = config.identation .. s .. '\n'
         elseif not space_only then
            list[i] = config.identation .. s .. ','
         else
            list[i] = s
         end
      end
   end

   result:insert(list:concat(''))

   return result
end

function converters.struct_name(value)
   return new_result() -- ignored
end

function converters.struct_decl(value)
   local list = traverse(value)

   local result = new_result()
   list:insert('= @record{\n', 2)
   list:insert('}')
   result:insert(list:concat(''))

   return result
end

function converters.enum_member_list(value)
   local list = traverse(value)

   for i, s in list:iter() do
      if s ~= '' then
         s = s:gsub('^\n%s+', '\n')

         local is_comment = s:sub(1, 2) == '--'
         local space_only = s:find('^%s')

         if is_comment then
            list[i] = config.identation .. s .. '\n'
         elseif not space_only then
            list[i] = config.identation .. s .. ','
         else
            list[i] = s
         end
      end
   end

   return new_result(list:concat())
end

function converters.enum_decl(value)
   local list = traverse(value)

   local result = new_result()
   list:insert('= @enum {\n', 1)
   list:insert('\n}')
   result:insert(list:concat())

   return result
end

function converters.typedef_alias(value)
   return new_result(value)
end

function converters.typedef_type_definition(value)
   return new_result(traverse(value):concat())
end

function converters.typedef(value)
   local list = traverse(value)
   local is_not_type_alias = string.find(list[1], "%p")

   if is_not_type_alias then
      list:swap(#list, 1)
   else
      list:prepend('@', 1)
      list:append(': type =', 2)
      list:swap(1, 2)
   end

   local result = new_result('global', list:concat())
   return result
end

function converters.define_replacement(value)
   local list = traverse(value)
   local result = new_result()

   local contains_expression = find(value, 'expression', 1)

   if not contains_expression then
      result:insert('=')
      result:insert(list:concat())
   end

   return result
end

function converters.define(value)
   local list = traverse(value)

   if list[#list] == '' then
      list:remove()
   end

   --local result = new_result('global', list:concat(), '<cimport, nodecl>')
   local result = new_result('global')

   local expr_value = find(value, 'expression')

   if expr_value then
      local expr_type = guess_expression_value_type(expr_value.value)
      if expr_type then
         list:append(': ' .. expr_type, 1)
      end
   end

   list:insert('<cimport, nodecl>', 2)
   result:insert(list:concat())

   return result
end

function converters.convert(subject)
   print('subject: ', subject)
   local result = new_result()

   if type(subject) == 'string' then
      error('subject is string: ' .. subject)
      --result:insert(subject)
   elseif type(subject) == 'table' then
      for i = 1, #subject do
         print('trying to convert subject: ' .. subject[i].name)
         local converter = converters[subject[i].name]
         if converter then
            print ('converting subsubject [' .. i .. '] -> ' .. subject[i].name)
            result:insert(converter(subject[i].value):concat())
         else
            print ('**FAIL** to convert subsubject [' .. i .. '] -> ' .. subject[i].name)
         end
      end
   end

   return result
end

local linklibs = {
   'raylib',
   'GL',
   'glfw',
   'openal',
   'm',
   'pthread',
   'dl',
   'X11',
   'Xrandr',
   'Xinerama',
   'Xi',
   'Xxf86vm',
   'Xcursor'
}

local cincludes = {
   '<raylib.h>', '<raymath.h>'
}

local raylib_table = lpeg_raylib_reader.read'binding_generator/modified-raylib.h'
print ("#raylib_table " .. #raylib_table, ins({raylib_table}))

local raylib_result = converters.convert(raylib_table)


local final_result = {}

table.insert(final_result, '-- links: \n')

for i = 1, #linklibs do
   table.insert(final_result, "## linklib '" .. linklibs[i] .. "' \n")
end

table.insert(final_result, '\n-- includes: \n')

for i = 1, #cincludes do
   table.insert(final_result, "## cinclude '" .. cincludes[i] .. "' \n")
end

table.insert(final_result, '\n-- raylib binding: \n')

for i = 1, #raylib_result do
   table.insert(final_result, raylib_result[i])
end

table.insert(final_result, '')

local file_to_generate = io.open('raylib.nelua', 'w+')
file_to_generate:write(table.concat(final_result))
file_to_generate:close()

--[=[
local function fmt_comment(comment)
   if comment:sub(1, 2) ~= '--' then
      comment = '-- ' .. comment
   end
   comment = comment:gsub('\n', '\n-- ')
   comment = comment:gsub(' +', ' ')

   if comment == '-- ' then
      comment = ''
   end

   return comment
end

local types = {
   ["void"]     = function() return 'void' end,
   ["char"]     = function() return 'char' end,
   ["float"]    = function() return 'float32' end,
   ["double"]   = function() return 'float64' end,
   ["*"]        = function(t) return 'pointer(' .. t .. ')' end,
   ['unsigned'] = function(t)
      return 'u'
   end,
   ['int']      = function(t) return 'int' end,
   ['[n]']      = function(t, n) return 'array(' .. t .. ', ' .. n .. ')' end,
   ['bool']     = function() return 'boolean' end,
}

local function c_type(t)
   local _type = ''

   for i = 1, #t do
      --print('t[i]: ', i, t[i])

      local ti = t[i]

      local as_number = tonumber(ti)
      if as_number then
         as_number = math.tointeger(as_number)
         ti = '[n]'
      end

      local types_ti = types[ti]

      local i_type = types_ti and types_ti(_type or '', as_number) or ti
      --print('i_type ' .. tostring(i) .. ' ' .. i_type)


      --print('end/i_type ' .. tostring(i) .. ' ' .. i_type)
      _type = i_type

      if i_type == 'char' or i_type == 'uchar' or i_type == 'int'
      or i_type == 'uint' or i_type == 'size' or i_type == 'long'
      or i_type == 'short' or i_type == 'ushort' then
         _type = 'c' .. _type
      end

      --print('type_i ' .. tostring(i) .. ' ' .. _type .. '\n')
   end

   --print('_type ' .. _type)

   return _type
end

local function generate_type(t)
   local type_result = c_type(t)

   if type_result == 'pointer(cchar)' then
      type_result = 'cstring'
   elseif type_result == 'pointer(void)' then
      type_result = 'pointer'
   end

   return type_result
end

local function generate_record(struct)
   local new_record = {
      fmt_comment(struct.comment),
      '\nglobal',
      struct.name,
      "<cimport, nodecl>",
      "=",
      "@record{\n",
   }

   for i = 1, #struct.members do
      local member = struct.members[i]
      table.insert(
         new_record,
         table.concat({
            subindent .. fmt_comment(member.comment),
            (member.comment ~= '' and '\n' .. indent or '') .. member.name,
            ': ',
            struct.name ~= 'Color' and generate_type(member.type) or 'uint8',
            ',',
            '\n'
         })
      )
   end

   new_record[#new_record] = new_record[#new_record] .. '}\n'

   return new_record
end

local function generate_alias(alias)
   return {'global', alias.name .. ':', 'type', '=', '@' .. alias.from, '\n'}
end

local function generate_enum(enum)
   local new_enum = {
      fmt_comment(enum.comment),
      '\nglobal',
      enum.name,
      '=',
      '@enum {\n'
   }

   local last_was_comment = false
   for i = 1, #enum.members do
      local member = enum.members[i]
      local m_value = member.value
      local v_or_1st = member.value or i == 1
      local underline_pos = member.name:find'_'

      table.insert(
         new_enum,
         table.concat({
            (v_or_1st and '' or (last_was_comment and '\n' or '')),
            ((v_or_1st) and subindent or (last_was_comment and indent or subindent)) .. fmt_comment(member.comment),
            ((member.comment ~= '' and m_value) and '\n' .. indent or '') .. member.name,
            m_value and ' = ' or '',
            (m_value and math.tointeger(m_value) or '') .. (m_value and ',' or ''),
            '\n'
         })
      )

      last_was_comment = v_or_1st
   end

   new_enum[#new_enum] = new_enum[#new_enum] .. '}\n'

   return new_enum
end

local function generate_RLAPI(RLAPI)
   local new_RLAPI = {
      '\n' .. fmt_comment(RLAPI.comment),
      '\nfunction' ,
      'Raylib.' .. RLAPI.name .. '('
   }

   for i = 1, #RLAPI.args do
      local _arg = RLAPI.args[i]
      _arg.name = _arg.name ~= 'end' and _arg.name or '_end'
      _arg.name = _arg.name ~= 'DOTDOTDOT' and _arg.name or '...'

      table.insert(
         new_RLAPI,
         table.concat({
            _arg.name,
            _arg.name ~= '...' and ': ' or '',
            generate_type(_arg.type),
            i <  #RLAPI.args and ',' or ''
         })
      )
   end

   table.insert(new_RLAPI, '): ')
   table.insert(new_RLAPI, generate_type(RLAPI.return_type))
   table.insert(new_RLAPI, '<cimport')
   table.insert(new_RLAPI, "'" .. RLAPI.name .. "', nodecl> end")

   return new_RLAPI
end

-- "global TraceLogCallback: type = function(logType: cint, text: cstring, args: va_list)",

local function generate_callback(callback)
   local new_callback = {
      fmt_comment(callback.comment),
      '\nglobal',
      callback.name .. ':',
      'type',
      '=',
      '@function('
   }

   for i = 1, #callback.args do
      local _arg = callback.args[i]

      table.insert(
         new_callback,
         table.concat({
            generate_type(_arg.type),
            i <  #callback.args and ',' or ''
         })
      )
   end

   table.insert(new_callback, ')')

   return new_callback
end

-- this is specific for Color constants
local function generate_define(define)
   return {
      'global',
      define.name .. ':',
      'Color',
      '<cimport, nodecl>'
   }
end

local generated_lines = {
   "--[[ This Source Code Form is subject to the terms of the Mozilla Public",
   "     License, v. 2.0. If a copy of the MPL was not distributed with this",
   "     file, You can obtain one at https://mozilla.org/MPL/2.0/. ]]",
   "",
   "-- Raylib and Raymath 3.0 wrapper",
   "-- based on raylib.h (https://github.com/raysan5/raylib/blob/3.0.0/src/raylib.h)",
   "-- and raymath.h (https://github.com/raysan5/raylib/blob/3.0.0/src/raymath.h)",
   "",
   "## linklib 'raylib'",
   "## linklib 'GL'",
   "## linklib 'glfw'",
   "## linklib 'openal'",
   "## linklib 'm'",
   "## linklib 'pthread'",
   "## linklib 'dl'",
   "## linklib 'X11'",
   "## linklib 'Xrandr'",
   "## linklib 'Xinerama'",
   "## linklib 'Xi'",
   "## linklib 'Xxf86vm'",
   "## linklib 'Xcursor'",
   "",
   "## cinclude '<raylib.h>'",
   "## cinclude '<raymath.h>'",
   "",
   "global Raymath = @record{}",
   "global Raylib  = @record{}",
   "",
   "local va_list <cimport, nodecl> = @record{}",
}

for i = 1, #raylib_table.callbacks do
   local callback = raylib_table.callbacks[i]
   local generated_line = table.concat(generate_callback(callback), ' ')
   table.insert(generated_lines, generated_line)
end

table.insert(generated_lines, "")

for i = 1, #raylib_table.enums do
   local enum = raylib_table.enums[i]
   local generated_line = table.concat(generate_enum(enum), ' ')
   table.insert(generated_lines, generated_line)
end

table.insert(generated_lines, "")

for i = 1, #raylib_table.structs do
   local struct = raylib_table.structs[i]
   local generated_line = table.concat(generate_record(struct), ' ')
   table.insert(generated_lines, generated_line)


   for j = 1, #raylib_table.aliases do
      local alias = raylib_table.aliases[j]

      if alias.from == struct.name then
         local generated_alias = generate_alias(alias)
         local generated_line = table.concat(generated_alias, ' ')
         table.insert(generated_lines, generated_line)
      end
   end
end

table.insert(generated_lines, "")

for i = 1, #raylib_table.RLAPIs do
   local RLAPI = raylib_table.RLAPIs[i]
   local generated_line = table.concat(generate_RLAPI(RLAPI), ' ')
   table.insert(generated_lines, generated_line)
end

table.insert(generated_lines, "")

for i = 1, #raylib_table.defines do
   local define = raylib_table.defines[i]
   local generated_line = table.concat(generate_define(define), ' ')
   table.insert(generated_lines, generated_line)
end

table.insert(generated_lines, " ")

local result = table.concat(generated_lines, '\n')

local file_to_generate = io.open('raylib.nelua', 'w+')
file_to_generate:write(result)
file_to_generate:close()
--]=]
