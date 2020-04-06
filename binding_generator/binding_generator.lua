--[[ This Source Code Form is subject to the terms of the Mozilla Public
     License, v. 2.0. If a copy of the MPL was not distributed with this
     file, You can obtain one at https://mozilla.org/MPL/2.0/. ]]

local indent = '   '

local ins = require'inspect'
local header_reader = require 'binding_generator.header_reader'

local raylib_table = header_reader.read 'binding_generator/raylib.h'

print(ins(raylib_table.aliases))

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
      print('t[i]: ', i, t[i])

      local ti = t[i]

      local as_number = tonumber(ti)
      if as_number then
         as_number = math.tointeger(as_number)
         ti = '[n]'
      end

      local types_ti = types[ti]

      local i_type = types_ti and types_ti(_type or '', as_number) or ti
      print('i_type ' .. tostring(i) .. ' ' .. i_type)


      print('end/i_type ' .. tostring(i) .. ' ' .. i_type)
      _type = i_type

      if i_type == 'char' or i_type == 'uchar' or i_type == 'int'
      or i_type == 'uint' or i_type == 'size' or i_type == 'long'
      or i_type == 'short' or i_type == 'ushort' then
         _type = 'c' .. _type
      end

      print('type_i ' .. tostring(i) .. ' ' .. _type .. '\n')
   end

   print('_type ' .. _type)

   return _type
end

local function generate_type(t)
   return c_type(t)
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
            indent:sub(1, #indent-1) .. member.name,
            ': ',
            generate_type(member.type),
            ',',
            ' ' .. fmt_comment(member.comment),
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

   for i = 1, #enum.members do
      local member = enum.members[i]
      local m_value = member.value
      local underline_pos = member.name:find'_'

      table.insert(
         new_enum,
         table.concat({
            ((m_value or i == 1) and '' or '\n'),
            indent:sub(1, #indent-1) .. member.name,
            m_value and ' = ' or '',
            (m_value and math.tointeger(m_value) or '') .. (m_value and ',' or ''),
            (m_value and ' ' or '') .. fmt_comment(member.comment),
            '\n'
         })
      )
   end

   new_enum[#new_enum] = new_enum[#new_enum] .. '}\n'

   return new_enum
end

local generated_lines = {
   "--[[ This Source Code Form is subject to the terms of the Mozilla Public",
   "     License, v. 2.0. If a copy of the MPL was not distributed with this",
   "     file, You can obtain one at https://mozilla.org/MPL/2.0/. ]]",
   "",
   "-- Raylib and Raymath 2.6 wrapper",
   "-- based on raylib.h (https://github.com/raysan5/raylib/blob/2.6/src/raylib.h)",
   "-- and raymath.h (https://github.com/raysan5/raylib/blob/2.6/src/raymath.h)",
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
}

for i = 1, #raylib_table.enums do
   local enum = raylib_table.enums[i]
   local generated_line = table.concat(generate_enum(enum), ' ')
   table.insert(generated_lines, generated_line)
end

for i = 1, #raylib_table.structs do
   local struct = raylib_table.structs[i]
   local generated_line = table.concat(generate_record(struct), ' ')
   table.insert(generated_lines, generated_line)


   for i = 1, #raylib_table.aliases do
      local alias = raylib_table.aliases[i]

      if alias.from == struct.name then
         local generated_alias = generate_alias(alias)
         local generated_line = table.concat(generated_alias, ' ')
         table.insert(generated_lines, generated_line)
         break
      end
   end
end

local result = table.concat(generated_lines, '\n')

local file_to_generate = io.open('raylib.nelua', 'w+')
file_to_generate:write(result)
file_to_generate:close()
