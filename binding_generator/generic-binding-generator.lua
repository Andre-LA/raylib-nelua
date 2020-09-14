--[[ This Source Code Form is subject to the terms of the Mozilla Public
     License, v. 2.0. If a copy of the MPL was not distributed with this
     file, You can obtain one at https://mozilla.org/MPL/2.0/. ]]

local ins = require 'inspect'

local config = {
   -- change this if you want a different indentation level
   identation = '  ',
   record_in_use = '',
   cinclude_in_use = '',
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

-- table with functions to convert an AST node to nelua code string
local converters = {}

local function traverse(values, separator)
   local result = new_result()

   for i = 1, #values do
      local value = values[i].value

      local converter = converters[values[i].name]
      if not converter then
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
   local list = traverse(value)


   -- for C bindings, <const>s should be not used
   for i = #list, 1, -1 do
      if list[i] == '<const>' then
         list:remove(i)
      end
   end

   return new_result(list:concat())
end

function converters.pointer(value)
   return new_result(string.rep('*', value))
end

function converters.initializer(value)
   return new_result('=', value)
end

function converters.declarator(value)
   local list = traverse(value)
   -- TODO: avoid other keywords in future version
   if list[#list] == 'end' then
      list[#list] = '_end'
   end
   return new_result(list:concat())
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

function converters.array(value)
    return new_result('[' .. tostring(value) .. ']')
end

function converters.var_decl(value)
   local list = traverse(value)

   local list_type = list[1]
   local adjusted_list = new_result()

   for i, s in list:iter(2) do
      local ptr, _s = extract_pointer(s)
      s = ptr and _s or s

      if list_type == 'void' and stars then
         ptr = 'pointer'
      end

      local arr_s, arr_e = string.find(s, '%[%d+%]')
      if arr_s then
         local array_str = string.sub(s, arr_s, arr_e)
         s = string.sub(s, 1, arr_s - 1)
         list_type = list_type .. array_str
      end

      adjusted_list:insert(s .. ': ' .. list_type .. (ptr or ''))
   end

   return new_result(adjusted_list:concat(', '))
end

function converters.func_args(value)
   return new_result(traverse(value):concat(', '))
end

function converters.func_arg(value)

   local func_arg_transformations = {
      function(l) --> ... or void
         if l[1] == 'void' then
            l:remove()
         end
      end, --< ... or `empty`
      function(l) --> type, declarator
         l:swap(1, 2)
      end, --< declarator, type
      function(l) --> qualifier, type, declarator
         l:swap(1, 3)
      end --< declarator, type, qualifier
   }

   local list = traverse(value)


   -- #list is 1 when "void" or "....";
   -- #list is 2 when "type" "declarator";
   -- #list is 3 when "qualifier" "type" "declarator"
   local transformation_fn = func_arg_transformations[#list]
   transformation_fn(list)

   if list[2] then
      list:append(':', 1)
   end


   if #list > 1 then
      local ptr, decl = extract_pointer(list[1])
      if ptr then
         list:append(ptr, 2)
         list[2] = string.gsub(list[2], 'cchar%*', 'cstring')
         list[2] = string.gsub(list[2], 'void%*', 'pointer')

         list[1] = decl
      end
   end



   local result = new_result(list:concat())
   return result
end

function converters.func_decl(value)
   local list = traverse(value)

   list:prepend('): ', 1)

   local ptr, func_name = extract_pointer(list[2])

   if ptr then
      list:append(ptr, 1)
      list[1] = string.gsub(list[1], 'cchar%*', 'cstring')
      list[1] = string.gsub(list[1], 'void%*', 'pointer')

      list[2] = func_name
   end

   local contains_comment = find(value, 'comment')
   local move_offset = contains_comment and 0 or 1

   list:move(1, #list + move_offset)

   list:insert("function " .. config.record_in_use .. ".", 1)
   list:insert("(", 3)
   list:insert(" <cimport'"..list[2].."', cinclude'<"..config.cinclude_in_use..">', nodecl>", #list + move_offset)
   list:insert(' end ', #list + move_offset)

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
            s = s:gsub('void%*', 'pointer')
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
   list:insert("<cimport, cinclude'<"..config.cinclude_in_use..">', nodecl> = @record{\n", 2)
   list:insert('}')

   local struct_name = find(value, 'struct_name').value
   list:insert('\n## ' .. struct_name .. '.value.is_' .. string.lower(struct_name) .. ' = true')

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

   local result = new_result('global')

   local expr_value = find(value, 'expression')

   if expr_value then
      local expr_type = guess_expression_value_type(expr_value.value)
      if expr_type then
         list:append(': ' .. expr_type, 1)
      end
   end

   list:insert("<cimport, cinclude'<"..config.cinclude_in_use..">', nodecl>", 2)
   result:insert(list:concat())

   return result
end

function converters.convert(subject)
   local result = new_result()

   if type(subject) == 'string' then
      error('subject is string: ' .. subject)
      --result:insert(subject)
   elseif type(subject) == 'table' then
      for i = 1, #subject do
         local converter = converters[subject[i].name]
         if converter then
            result:insert(converter(subject[i].value):concat())
         else
         end
      end
   end

   return result
end

return {
   converters = converters,
   config = config
}
