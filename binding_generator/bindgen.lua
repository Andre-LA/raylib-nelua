-- C11 to nelua binding generator, while I'm trying to make it agnostic, it only targets the raylib library

local c11parser = require 'c11' -- from: https://github.com/edubart/lpegrex/blob/main/parsers/c11.lua
local astutil = require 'astutil' -- from: https://github.com/edubart/lpegrex/blob/main/parsers/astutil.lua

local inspect = require 'inspect'

-- utility function
local function insprint(t, d)
  print(inspect(t, d and {depth = d} or nil))
end

local ctypes = {
  ['int64_t'] = 'integer',
  ['unt64_t'] = 'uinteger',
  ['double'] = 'number',
  ['uint8_t'] = 'byte',
  ['intptr_t'] = 'isize',
  ['int8_t'] = 'int8',
  ['int16_t'] = 'int16',
  ['int32_t'] = 'int32',
  ['int64_t'] = 'int64',
  ['__int128'] = 'int128',
  ['uintptr_t'] = 'usize',
  ['uint8_t'] = 'uint8',
  ['uint16_t'] = 'uint16',
  ['uint32_t'] = 'uint32',
  ['uint64_t'] = 'uint64',
  ['unsigned __int128'] = 'uint128',
  ['float'] = 'float32',
  ['double'] = 'float64',
  ['_Float128'] = 'float128',

  ['bool'] = 'boolean',
  ['_Bool'] = 'boolean',

  ['short'] = 'cshort',
  ['int'] = 'cint',
  ['long'] = 'clong',
  ['long long'] = 'clonglong',
  ['ptrdiff'] = 'cptrdiff',
  ['char'] = 'cchar',
  ['signed char'] = 'cschar',
  ['unsigned char'] = 'cuchar',
  ['unsigned short'] = 'cushort',
  ['unsigned int'] = 'cuint',
  ['unsigned long'] = 'culong',
  ['unsigned long long'] = 'culonglong',
  ['size'] = 'csize',
  ['long double'] = 'clongdouble',
  ['char*'] = 'cstring',

  ['void*'] = 'pointer',
}

-- map utility function
local function map(tbl, fn)
  local result = {}
  for k, v in pairs(tbl) do
    result[k] = fn(v)
  end
  return result
end

-- unwrap utility function
local function unwrap(tbl)
  return map(tbl, function(node) return node[1] end)
end

--[[
iterate over `ast` collecting nodes tagged with the `target_tag`
when a `result` table is passed, it will populate it, otherwise it will
populate a new result table.
you can pass a limit of how deep the iteration goes (this function is recursive) on
the `depth` parameter.
]]
local function collect_child_nodes(ast, target_tag, result, depth)
  assert(type(ast) == 'table', "'ast' is not a table, got " .. type(ast) .. " instead.")
  assert(type(target_tag) == 'string', "'target_tag' is not a string, got " .. type(target_tag) .. " instead.")

  if depth and depth <= 0 then
    return
  end

  if not result then
    result = {}
  end

  for i = 1, #ast do
    local node = ast[i]
    local ty = type(node)

    if node.tag == target_tag then
      result[#result + 1] = node
    end

    if ty == 'table' then
      collect_child_nodes(node, target_tag, result, depth and depth - 1 or nil)
    end
  end

  return result
end

--[[
convert from the C ast to a simplified conversion friendly syntax, for example, this AST:

struct-or-union-specifier
| "struct"
| identifier
| | "Vector2"
| struct-declaration-list
| | struct-declaration
| | | specifier-qualifier-list
| | | | type-specifier
| | | | | "float"
| | | struct-declarator-list
| | | | struct-declarator
| | | | | declarator
| | | | | | identifier
| | | | | | | "x"
| | struct-declaration
| | | specifier-qualifier-list
| | | | type-specifier
| | | | | "float"
| | | struct-declarator-list
| | | | struct-declarator
| | | | | declarator
| | | | | | identifier
| | | | | | | "y"

will result in this table:

{
  tag = 'struct',
  identifier = 'Vector2',
  fields = {
    {identifiers = {'x'}, type = 'float', pointers = 0},
    {identifiers = {'y'}, type = 'float', pointers = 0},
  },
}

]]
local ast_converters = {}

function ast_converters.struct(struct_ast, result)
  local struct_node = {
    tag = 'struct',
    identifier = 'struct-name',
    fields = {}, -- { { identifiers = {'field_name', ...}, type = 'type_name_t', pointers = 0 }, ... }
  }

  local identifier = collect_child_nodes(struct_ast, 'identifier', nil, 1)[1]
  struct_node.identifier = identifier[1]

  local struct_declarations = collect_child_nodes(struct_ast, 'struct-declaration')
  for i, decl_node in ipairs(struct_declarations) do
    local specifier_qualifier_list = collect_child_nodes(decl_node, 'specifier-qualifier-list', {}, 1)
    local specifier_declarator_list = collect_child_nodes(decl_node, 'struct-declarator-list', {}, 1)

    local type_specifiers = collect_child_nodes(specifier_qualifier_list, 'type-specifier')
    local identifiers_from_type_specifiers = collect_child_nodes(type_specifiers, 'identifier')

    local field_identifiers = collect_child_nodes(specifier_declarator_list, 'identifier')
    local field_is_pointer = collect_child_nodes(specifier_declarator_list, 'pointer')

    local ctype
    if #identifiers_from_type_specifiers > 0 then
      ctype = unwrap(identifiers_from_type_specifiers)[1]
    else
      ctype = table.concat(unwrap(type_specifiers), ' ')
    end
    assert(type(ctype) == 'string')

    local field_names = unwrap(field_identifiers)
    assert(#field_names > 0)

    local struct_field = {
      identifiers = field_names,
      type = ctype,
      pointers = #field_is_pointer
    }

    if struct_field.type == 'void' and struct_field.pointers then
      struct_field.pointers = struct_field.pointers - 1
      struct_field.type = 'void*'
    end

    table.insert(struct_node.fields, struct_field)
  end

  table.insert(result, struct_node)

  return result
end

function ast_converters.struct_or_union_specifier(ast, result, declaration_ast)
  if ast[1] == 'struct' then
    ast_converters.struct(ast, result)
  end
end

function ast_converters.enum(ast, result, declaration_ast)
  local enum_node = {
    tag = 'enum',
    identifier = 'enum-name',
    fields = {} -- { { identifier = 'field_name', constant = '0' or nil}, ... }
  }

  -- get enum name
  local typedef_id = collect_child_nodes(declaration_ast, 'typedef-identifier')
  local id = collect_child_nodes(typedef_id, 'identifier') -- returns for example { { 'id_value',  } }
  enum_node.identifier = id[1][1] -- using id[1][1] to get 'id_value' of the example above

  -- get enum fields
  local enum_list = collect_child_nodes(ast, 'enumerator-list')
  local enumerators = collect_child_nodes(enum_list, 'enumerator')

  for i, enumerator in ipairs(enumerators) do
    local enumerator_id = collect_child_nodes(enumerator, 'identifier')
    local enumerator_int_const = collect_child_nodes(enumerator, 'integer-constant')

    local field_tbl = {
      identifier = enumerator_id[1][1],
      constant = nil, -- added just for code clarity
    }

    if #enumerator_int_const > 0 then -- enumerator contains constant value
      field_tbl.constant = enumerator_int_const[1][1]
    end

    table.insert(enum_node.fields, field_tbl)
  end

  table.insert(result, enum_node)
end

function ast_converters.declaration(ast, result)
  -- "macro" for each conversion try
  -- if found, the resulting node will always return 1 node, since we're inspecting a declaration
  -- also, it will returns true, otherwise (if the node isn't found), returns false
  local function find_and_convert(target_tag, converter)
    local possible_node = collect_child_nodes(ast, target_tag)
    if #possible_node > 0 then
      converter(possible_node[1], result, ast)
      return true
    end
  end

  -- try convert a struct or union
  if find_and_convert('struct-or-union-specifier', ast_converters.struct_or_union_specifier) then
    return
  end

  -- try convert a enum
  if find_and_convert('enum-specifier', ast_converters.enum) then
    return
  end
end

function ast_converters.convert(ast)
  local result = {}

  local declarations = collect_child_nodes(ast, 'declaration')
  for i = 1, #declarations do
    ast_converters.declaration(declarations[i], result)
  end

  return result
end

local simpleast2nelua = {}

function simpleast2nelua.struct(struct_ast)
  local fields = map(struct_ast.fields, function(field)
    local fields_tbl = {}

    for i, field_id in ipairs(field.identifiers) do
      -- field.type may be a ctype, in this case get the corresponding nelua type, otherwise, use field.type
      local nltype = ctypes[field.type] and ctypes[field.type] or field.type

      -- create the string of record field
      fields_tbl[i] = string.format('%s: %s%s,', field_id, string.rep('*', field.pointers), nltype)
    end

    -- return the string of all field lines
    return '  ' .. table.concat(fields_tbl, ' ')
  end)

  -- create record decl. string
  return string.format(
    "global %s: type <cimport, nodecl> = @record{\n%s\n}",
    struct_ast.identifier,
    table.concat(fields, '\n')
  )
end

function simpleast2nelua.enum(enum_ast)
  local fields = map(enum_ast.fields, function(field)
    if field.constant then
      return string.format('  %s = %s,', field.identifier, field.constant)
    else
      return string.format('  %s,', field.identifier)
    end
  end)

  return string.format(
    "global %s = @enum{\n%s\n}",
    enum_ast.identifier,
    table.concat(fields, '\n')
  )
end

function simplified_ast_2_nelua(ast)
  local result = {}

  for i, node in ipairs(ast) do
    table.insert(result, simpleast2nelua[node.tag](node) )
  end

  return table.concat(result, '\n\n')
end

local function print_binding(binding_str)
  print(binding_str)
end

local source, err = io.open'raylib-preprocessed.h'
if not source then
  error('could not open raylib.h: ' .. err)
else
  local raylib_src = source:read'a'
  if raylib_src then
    local ast = c11parser(raylib_src)

    --print('ast:\n' .. astutil.ast2string(ast))
    --print('\n--==========--\n')
    --print('inspect:\n' .. inspect(ast))
    --print('\n--==========--\n')
    --print('\nast_converter:\n' .. inspect(ast_converters.convert(ast)) )
    --print('\n--==========--\n')
    --print('\nnelua:\n' .. simplified_ast_2_nelua( ast_converters.convert(ast)) )

    print_binding(simplified_ast_2_nelua( ast_converters.convert(ast) ))
  end
end
source:close()
