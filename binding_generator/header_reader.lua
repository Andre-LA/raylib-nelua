--[[ This Source Code Form is subject to the terms of the Mozilla Public
     License, v. 2.0. If a copy of the MPL was not distributed with this
     file, You can obtain one at https://mozilla.org/MPL/2.0/. ]]

-- this is a basic c header reader, it just implement sufficient
-- features to read the raylib.h and generates a table contaiing
-- enough information.

-- it's a experimental thing

local ins = require'inspect'

local function table_union(t1, t2)
   local r = {}
   for i=1, #t1 do r[#r+1] = t1[i] end
   for i=1, #t2 do r[#r+1] = t2[i] end
   for k, v in pairs(t1) do r[k] = v end
   for k, v in pairs(t2) do r[k] = v end
   return r
end

local function table_clone(t1)
   local r = {}
   for i=1, #t1 do r[#r+1] = t1[i] end
   for k, v in pairs(t1) do r[k] = v end
   return r
end

local function split(line)
   local split_line = {}
   for cap in line:gmatch'[%w%*%/_]+' do
      table.insert(split_line, cap)
   end
   return split_line
end

local function join(split_line, words_count, start)
   local t = {}
   start = start or 0
   for i = start, words_count or #split_line do
      table.insert(t, split_line[i])
   end
   return table.concat(t, ' ')
end

local function detach_comment(split_line)
   local start = -1
   local comment_tbl = {}
   local comment;
   local new_split_line = {}

   for i = 1, #split_line do
      if start < 0 then
         if split_line[i] == '//' then
            start = i
         end
      else
         table.insert(comment_tbl, split_line[i])
      end
   end

   if #comment_tbl == 0 then
      return split_line
   else
      comment = table.concat(comment_tbl, ' ')
      for i = 1, start-1 do
         new_split_line[i] = split_line[i]
      end
   end

   return new_split_line, comment
end

local primitive_types = {
   ['va_list'] = true, -- not primitive I know
   ['void'] = true,
   ['int'] = true,
   ['short'] = true,
   ['long'] = true,
   ['char'] = true,
   ['*'] = true,
   ['float'] = true,
   ['double'] = true,
   ['bool'] = true,
}

local qualifiers = {
   ['const'] = true,
   ['unsigned'] = true,
}

local RLAPIs = {}
local structs = {}
local enums = {}
local defines = {}
local aliases = {}
local callbacks = {}

local function find_name(tbl, name)
   for i = 1, #tbl do
      if tbl[i].name == name then
         return i
      end
   end
   return nil
end

local function RLAPI_continue_line(split_line)
   local last_RLAPI = RLAPIs[#RLAPIs]

   local function add_rlapi_arg()
      table.insert(last_RLAPI.args, {type = {}, name = ''})
   end

   local uncomment_split_line, comment = detach_comment(split_line)
   last_RLAPI.comment = comment

   -- collect RLAPI arguments
   add_rlapi_arg()

   for i = 1, #uncomment_split_line do
      local word = uncomment_split_line[i]

      local is_prim_type = primitive_types[word]
      local is_qualifier = qualifiers[word]
      local is_known_struct = find_name(structs, word)
      local is_typealias = find_name(aliases, word)
      local is_callback = find_name(callbacks, word)

      if is_prim_type or is_qualifier or is_known_struct or is_typealias or is_callback then
         table.insert(last_RLAPI.args[#last_RLAPI.args].type, word)
      else
         last_RLAPI.args[#last_RLAPI.args].name = word
         add_rlapi_arg()
      end
   end

   table.remove(last_RLAPI.args)
end

local function RLAPI_line(split_line)
   local RLAPI = {
      return_type = {},
      name = '',
      args = {},
      comment = ''
   }

   local function add_rlapi_arg()
      table.insert(RLAPI.args, {type = {}, name = ''})
   end

   table.remove(split_line, 1) -- remove 'RLAPI'

   local uncomment_split_line, comment = detach_comment(split_line)
   RLAPI.comment = comment

   --print ('UN RLAPI: ' .. ins(uncomment_split_line))

   local s = 1

   -- collect RLAPI return types
   for i = s, #uncomment_split_line do
      local word = uncomment_split_line[i]

      local is_prim_type = primitive_types[word]
      local is_qualifier = qualifiers[word]
      local is_known_struct = find_name(structs, word)
      local is_typealias = find_name(aliases, word)
      local is_callback = find_name(callbacks, word)

      if is_prim_type or is_qualifier or is_known_struct or is_typealias or is_callback then
         table.insert(RLAPI.return_type, word)
      else
         s = i
         break
      end
   end

   -- collect RLAPI name
   RLAPI.name = uncomment_split_line[s]
   s = s + 1

   -- collect RLAPI arguments
   add_rlapi_arg()

   for i = s, #uncomment_split_line do
      local word = uncomment_split_line[i]

      local is_prim_type = primitive_types[word]
      local is_qualifier = qualifiers[word]
      local is_known_struct = find_name(structs, word)
      local is_typealias = find_name(aliases, word)
      local is_callback = find_name(callbacks, word)

      if is_prim_type or is_qualifier or is_known_struct or is_typealias or is_callback then
         table.insert(RLAPI.args[#RLAPI.args].type, word)
      else
         RLAPI.args[#RLAPI.args].name = word
         add_rlapi_arg()
      end
   end

   table.remove(RLAPI.args)

   --print('RLAPI added to RLAPIs: ' .. ins(RLAPI))

   table.insert(RLAPIs, RLAPI)
end

local function struct_typedef_line(split_line, prev_comments)
   local struct = {
      name = '',
      members = {},
      comment = ''
   }

   struct.name = split_line[3]
   if prev_comments and #prev_comments > 0 then
      struct.comment = table.concat(prev_comments, '\n')
   end

   --print('struct added to structs: ' .. ins(struct))

   table.insert(structs, struct)
end

local function struct_member_line(split_line)
   local last_struct = structs[#structs]

   local function new_struct_member(_name, _type, _comment)
      return {
         name = _name or '',
         type = _type and table_clone(_type) or {},
         comment = _comment or '',
      }
   end

   local uncomment_split_line, comment = detach_comment(split_line)

   --print('add struct member: ', ins(uncomment_split_line))

   local member_type = {}
   local members_name = {}

   for i = 1, #uncomment_split_line do
      local word = uncomment_split_line[i]

      local is_prim_type = primitive_types[word]
      local is_qualifier = qualifiers[word]
      local is_known_struct = find_name(structs, word)
      local is_typealias = find_name(aliases, word)
      local is_callback = find_name(callbacks, word)

      if is_prim_type or is_qualifier or is_known_struct or tonumber(word) or is_typealias or is_callback then
         table.insert(member_type, word)
      else
         table.insert(members_name, word)
      end
   end

   for i = 1, #members_name do
      local member = new_struct_member(members_name[i], member_type, comment)
      --print('struct member added: ' .. ins(member))
      table.insert(last_struct.members, member)
   end
end

local function enum_typedef_line(split_line, prev_comments)
   local new_enum =  {
      comment = '',
      name = '',
      members = {}
   }

   if prev_comments and #prev_comments > 0 then
      new_enum.comment = table.concat(prev_comments, '\n')
   end

   table.insert(enums, new_enum)
end

local function enum_member_line(split_line)
   local last_enum = enums[#enums]

   if split_line[1] ~= '//' then
      local new_member = {
         name = '',
         value = (#last_enum.members > 0 and (
               (last_enum.members[#last_enum.members].value or 0) + 1
            ) or (
               0
            )
         ),
         comment = '',
      }

      --print('inspect enum member line: ', ins(split_line))

      local uncomment_split_line, comment = detach_comment(split_line)

      if comment then
         new_member.comment = comment
      end

      if #uncomment_split_line > 1 then
         new_member.name = split_line[1]
         new_member.value = split_line[2]

         --print('enum member added: ' .. ins(new_member))
         table.insert(last_enum.members, new_member)
      else
         local uppername = string.upper(split_line[1])

         --print('uppertest', uppername, split_line[1])
         if uppername == split_line[1] or split_line[1]:find'%d' then -- is enum member
            new_member.name = split_line[1]

            --print('enum member added: ' .. ins(new_member))
            table.insert(last_enum.members, new_member)
         else -- then is the end of enum
            last_enum.name = split_line[1]
            return true
         end
      end
   else
      table.insert(
         last_enum.members,
         {
            name = '',
            value = nil,
            comment = join(split_line, #split_line, 2),
         }
      )
   end

   return false
end

local function define_line(split_line, prev_comments)
   local last_define = defines[#defines]

   local new_define = {
      name = '',
      comment = '',
      value = {},
   }

   local uncomment_split_line, comment = detach_comment(split_line)

   new_define.name = uncomment_split_line[2]

   for i = 3, #uncomment_split_line do
      table.insert(new_define.value, uncomment_split_line[i])
   end
   new_define.comment = comment

   --print('new define added: ' .. ins(new_define))

   table.insert(defines, new_define)
end

local function callback_line(split_line, prev_comments)
   local new_callback = {
      name = split_line[4],
      args = {},
      comment = '',
   }

   if prev_comments and #prev_comments > 0 then
      new_callback.comment = table.concat(prev_comments, '\n')
   end

   local function add_callback_arg()
      table.insert(new_callback.args, {type = {}, name = ''})
   end

   -- collect callback arguments
   add_callback_arg()

   for i = 5, #split_line do
      local word = split_line[i]

      local is_prim_type = primitive_types[word]
      local is_qualifier = qualifiers[word]
      local is_known_struct = find_name(structs, word)
      local is_typealias = find_name(aliases, word)
      local is_callback = find_name(callbacks, word)

      if is_prim_type or is_qualifier or is_known_struct or is_typealias or is_callback then
         table.insert(new_callback.args[#new_callback.args].type, word)
      else
         new_callback.args[#new_callback.args].name = word
         add_callback_arg()
      end
   end

   table.remove(new_callback.args)

   table.insert(callbacks, new_callback)
end

-- main:

local function read(header)

   local state = 'neutral' -- can be
   local raylib_h = io.open(header)

   local comments_split_lines = {}
   local line_number =  0

   for line in raylib_h:lines() do
      line_number = line_number + 1

      -- separate * so the split function will split it as different words
      --print("line! " .. line)
      line = line:gsub('CLITERAL%(Color%)', '')
      line = line:gsub('%*', '* ')
      line = line:gsub('//', '// ')
      line = line:gsub('%(', ' ( ')
      line = line:gsub('%)', ' ) ')

      -- split the line
      local split_line = split(line)

      --print('line split: ' .. line ..  ' ~> ' .. ins(split_line))

      -- if the line have contents and it's after 123th line
      if #split_line > 0 and line_number > 123 then
         if state == 'neutral' then
            -- if the line start with a "RLAPI"
            if split_line[1] == 'RLAPI' then
               RLAPI_line(split_line)
               if not RLAPIs[#RLAPIs].comment then
                  state = 'giant RLAPI'
               end
            elseif split_line[1] == '//' then
               local _, comment = detach_comment(split_line)
               if comment then
                  table.insert(comments_split_lines, line:sub(3))
               end
            elseif join(split_line, 2) == 'typedef struct' then
               if #split_line < 4 then
                  state = 'typedef struct'
               end
               struct_typedef_line(split_line, comments_split_lines)
               comments_split_lines = {}
            elseif join(split_line, 2) == 'typedef enum' then
               state = 'typedef enum'
               enum_typedef_line(split_line, comments_split_lines)
               comments_split_lines = {}
            elseif split_line[1] == 'define' then
               define_line(split_line, comments_split_lines)
               comments_split_lines = {}
            elseif join(split_line, 2) == 'if defined' then
               state = 'pif'
            elseif split_line[1] == 'typedef' then
               if split_line[2] ~= 'void' then
                  table.insert(aliases, {
                     name = split_line[3],
                     from = split_line[2]
                  })
               elseif split_line[3] == '*' then
                  callback_line(split_line, comments_split_lines)
                  comments_split_lines = {}
               end
            end
         elseif state == 'typedef struct' then
            --print('then typedef struct state', ins(split_line))

            -- if struct declaration ends
            if split_line[1] == (structs[#structs]).name then
               --print('"typedef struct" state ends: ' .. ins(structs[#structs]))
               state = 'neutral'
            else
               struct_member_line(split_line)
            end
         elseif state == 'typedef enum' then
            --print('then typedef enum state', ins(split_line))
            local should_end_state = enum_member_line(split_line)

            if should_end_state then
               state = 'neutral'
               --print('"typedef enum" state ends: ' .. ins(enums[#enums]))
            end
         elseif state == 'pif' then
            if split_line[1] == 'endif' then
               state = 'neutral'
            end
         elseif state == 'giant RLAPI' then
            RLAPI_continue_line(split_line)
            state = 'neutral'
         end
      end
   end

   raylib_h:close()

   return {
      defines = defines,
      structs = structs,
      enums = enums,
      RLAPIs = RLAPIs,
      aliases = aliases,
      callbacks = callbacks
   }
end

return {
   read = read
}
