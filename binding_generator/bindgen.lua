local c11parser = require 'c11' -- from: https://github.com/edubart/lpegrex/blob/main/parsers/c11.lua
local astutil = require 'astutil' -- from: https://github.com/edubart/lpegrex/blob/main/parsers/astutil.lua
local inspect = require 'nelua.thirdparty.inspect'

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
}

local function map(tbl, fn)
  local result = {}
  for k, v in pairs(tbl) do
    result[k] = fn(v)
  end
  return result
end

local function unwrap(tbl)
  return map(tbl, function(node) return node[1] end)
end

local function collect_child_nodes(ast, target_tag, result, depth)
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

local function concat_string_wrappers_nodes(nodes, separator)
  local result = {}
  for i = 1, #nodes do
    result[i] = nodes[i]
  end
  return table.concat(result, separator)
end

-- convert from the C ast to a simplified conversion friendly syntax, for example:
-- struct-or-union-specifier
-- | "struct"
-- | identifier
-- | | "Vector2"
-- | struct-declaration-list
-- | | struct-declaration
-- | | | specifier-qualifier-list
-- | | | | type-specifier
-- | | | | | "float"
-- | | | struct-declarator-list
-- | | | | struct-declarator
-- | | | | | declarator
-- | | | | | | identifier
-- | | | | | | | "x"
-- | | struct-declaration
-- | | | specifier-qualifier-list
-- | | | | type-specifier
-- | | | | | "float"
-- | | | struct-declarator-list
-- | | | | struct-declarator
-- | | | | | declarator
-- | | | | | | identifier
-- | | | | | | | "y"
-- will be:
-- { -- struct
--   tag = 'struct',
--   identifier = 'Vector2',
--   fields = {
--     {identifier = {'x'}, type = 'float'},
--     {identifier = {'y'}, type = 'float'},
--   },
-- }
local ast_converters = {}

function ast_converters.struct(struct_ast, result)
  local struct_node = {
    tag = 'struct',
    identifier = 'struct-name',
    fields = {}, -- { {identifiers = {'field-name'}, type = 'ctype-name' }, --[[...]] }
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
      type = ctype
    }

    table.insert(struct_node.fields, struct_field)
  end

  result[#result + 1] = struct_node

  return result
end

function ast_converters.struct_or_union_specifier(ast, result)
  if ast[1] == 'struct' then
    ast_converters.struct(ast, result)
  end
end

function ast_converters.declaration(ast, result)
  -- try get different types of node

  -- struct or union
  local possible_struct_or_union_node = collect_child_nodes(ast, 'struct-or-union-specifier')
  for i, struct_or_union_node in ipairs(possible_struct_or_union_node) do
    ast_converters.struct_or_union_specifier(struct_or_union_node, result)
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
  local result = {}

  local fields = map(struct_ast.fields, function(field)
    local fields_tbl = {}
    for i, field_id in ipairs(field.identifiers) do
      fields_tbl[i] = string.format('%s: %s,', field_id, ctypes[field.type])
    end
    return '  ' .. table.concat(fields_tbl, ' ')
  end)

  table.insert(result, string.format(
    "global %s: type <cimport, nodecl> = @record{\n%s\n}",
    struct_ast.identifier,
    table.concat(fields, '\n')
  ))

  return table.concat(result)
end

function simplified_ast_2_nelua(ast)
  local result = {}

  for i, node in ipairs(ast) do
    table.insert(result, simpleast2nelua[node.tag](node) )
  end

  return table.concat(result, '\n\n')
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

    print(simplified_ast_2_nelua( ast_converters.convert(ast) ))
  end
end
source:close()
