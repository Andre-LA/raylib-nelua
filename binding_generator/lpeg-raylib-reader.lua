--[[ This Source Code Form is subject to the terms of the Mozilla Public
     License, v. 2.0. If a copy of the MPL was not distributed with this
     file, You can obtain one at https://mozilla.org/MPL/2.0/. ]]

-- this is a raylib header parser, uses LPEG library to parse the declarations and comments
-- of raylib library, it tries to be more "generic C" possible, but it's very limited
-- because the goal it just to parse a simplified raylib.h and return an AST-like
-- table with all declarations and comments on it

-- this script uses LPEG by Roberto Ierusalimschy: http://www.inf.puc-rio.br/~roberto/lpeg/
-- and uses some pieces of lexer.lua by Mitchell from textadept editor: https://foicica.com/textadept/

-- C reference (this peg script doesn't follow it strictly):
-- https://en.cppreference.com/w/c/language
-- https://en.wikipedia.org/wiki/Typedef#cite_ref-2


--[[ TODO LIST:
   - [x] parse declarator with optional initializer
   - [x] parse variable declaration
   - [x] parse struct declaration
      - [x] with comments
   - [x] parse enum declaration
      - [x] with comments
   - [x] pointer
   - [x] array
   - [x] parse function declaration
   - [ ] ~~parse callbacks~~ (added manually)
   - [x] parse comments
   - [x] parse typedef
   - [x] parse defines
]]

local ins = require 'inspect'
local lpeg = require 'lpeg'

local lowercase = lpeg.R'az'
local uppercase = lpeg.R'AZ'
local alphabet = lpeg.R('az', 'AZ')

local digit = lpeg.R'09' + lpeg.P'.'
local xdigit = lpeg.R('09', 'af', 'AF')
local number = digit^1 * lpeg.S'uUlLfF'^-1

local alphanumeric = alphabet + digit

local newline = lpeg.P'\r'^-1 * '\n'

local space = lpeg.S'\t\v\f\n\r '

local eq = lpeg.P'='
local ops = lpeg.S'=/*-+%'

local unary_ops = lpeg.P'++' + lpeg.P'--' + lpeg.S'-+!&*~^'

local binary_ops = (
   lpeg.P'<<' + lpeg.P'>>' + lpeg.P'<=' + lpeg.P'>=' + lpeg.P'==' + lpeg.P'!=' +
   lpeg.P'&&' + lpeg.P'||' + lpeg.S'&|^<>*%/+-='
)

local ternary_ops = lpeg.S'?:'

local lparen, rparen = lpeg.P'(', lpeg.P')'
local lbrace, rbrace = lpeg.P'{', lpeg.P'}'
local lbracket, rbracket = lpeg.P'[', lpeg.P']'

local identifier = (alphabet + lpeg.P'_') * (alphanumeric + lpeg.P'_')^0

local comma = lpeg.P','
local semicolon = lpeg.P';'

local word = (lpeg.P(1) - space)^1


local function typecheck_assert(value, _types)
   local valuetype = type(value)
   local result = false

   for i = 1, #_types do
      result = result or valuetype == _types[i]
   end

   if not result then
      local msg = "'" .. table.concat(_types, "' or '") .. "' expected, got '" .. valuetype .. "' (value: '" .. tostring(value) .. "')"
      error(msg, 2)
   end

   return value
end

-- kw: c KeyWords
local kw = {}

local function add_keywords(keywords_table)
   keywords_table = typecheck_assert(keywords_table, {'table'})

   for i=1, #keywords_table do
      local k = typecheck_assert(keywords_table[i], {'string'})
      kw[k] = lpeg.P(k)
   end
end

setmetatable(kw, {
   __call = function(kw, k)
      k = typecheck_assert(k, {'string'})
      return kw[k] or error('keyword typo: ' .. k)
   end
})

-- default keywords
add_keywords({
   'auto',
   'break',
   'case',
   'char',
   'const',
   'continue',
   'default',
   'do',
   'double',
   'else',
   'enum',
   'extern',
   'float',
   'for',
   'goto',
   'if',
   'inline',
   'int',
   'long',
   'register',
   'restrict',
   'return',
   'short',
   'signed',
   'sizeof',
   'static',
   'struct',
   'switch',
   'typedef',
   'union',
   'unsigned',
   'void',
   'volatile',
   'while',
   '_Alignas',
   '_Alignof',
   '_Atomic',
   '_Bool',
   '_Complex',
   '_Generic',
   '_Imaginary',
   '_Noreturn',
   '_Static_assert',
   '_Thread_local',
})

add_keywords({ -- extra C keywords
   'bool' -- same as _Bool, used by raylib
})

local function gen_capture(capture_name, capture_value, value_expected_type)
   return {
      name = capture_name,
      value = typecheck_assert(capture_value, value_expected_type),
   }
end

local c_patterns;

local captures = {
   var_decl = function(...)
      return gen_capture('var_decl', {...}, {'table'})
   end,

   identifier = function (identifier_name)
      return gen_capture('identifier', identifier_name, {'string'})
   end,

   declarator = function(...)
      return gen_capture('declarator', {...}, {'table'})
   end,

   initializer = function (initializer_value)
      return gen_capture('initializer', initializer_value, {'string'})
   end,

   struct_name = function(struct_name)
      c_patterns:update_custom_types(struct_name)
      return gen_capture('struct_name', struct_name, {'string'})
   end,

   struct_decl = function(...)
      return gen_capture('struct_decl', {...}, {'table'})
   end,

   struct_declaration_list = function(...)
      return gen_capture('struct_declaration_list', {...}, {'table'})
   end,

   typedef_alias = function(alias)
      c_patterns:update_custom_types(alias)
      return gen_capture('typedef_alias', alias, {'string'})
   end,

   typedef_type_definition = function(type_definition)
      return gen_capture('typedef_type_definition', type_definition, {'table', 'string'})
   end,

   typedef = function(...)
      return gen_capture('typedef', {...}, {'table'})
   end,

   basic_type = function(type_name)
      return gen_capture('basic_type', type_name, {'string'})
   end,

   enum_decl = function(...)
      return gen_capture('enum_decl', {...}, {'table'})
   end,

   enum_member_list = function(...)
      return gen_capture('enum_member_list', {...}, {'table'})
   end,

   enum_name = function(enum_name)
      c_patterns:update_custom_types(enum_name)
      return gen_capture('enum_name', enum_name, {'string'})
   end,

   declarator_and_initializer = function(...)
      return gen_capture('declarator_and_initializer', {...}, {'table'})
   end,

   comment = function(comment)
      return gen_capture('comment', comment, {'string'})
   end,

   define = function(...)
      return gen_capture('define', {...}, {'table'})
   end,

   define_params = function(...)
      return gen_capture('define_params', {...}, {'table'})
   end,

   define_replacement = function(...)
      return gen_capture('define_replacement', {...}, {'table'})
   end,

   specifiers_and_qualifiers = function (...)
      return gen_capture('specifiers_and_qualifiers', {...}, {'table'})
   end,

   specifier = function(specifier_name)
      return gen_capture('specifier_name', specifier_name, {'string'})
   end,

   qualifier = function(qualifier_name)
      return gen_capture('qualifier_name', qualifier_name, {'string'})
   end,

   pointer = function(stars_count)
      return gen_capture('pointer', string.len(stars_count), {'number'})
   end,

   void = function()
      return gen_capture('void', true, {'boolean'})
   end,

   custom_type = function(type_name)
      return gen_capture('custom_type', type_name, {'string'})
   end,

   array = function (arraysize)
      return gen_capture('array', tonumber(arraysize), {'number'})
   end,

   func_decl = function(...)
      return gen_capture('func_decl', {...}, {'table'})
   end,

   func_arg = function(...)
      return gen_capture('func_arg', {...}, {'table'})
   end,

   variadic_arg = function()
      return gen_capture('variadic_arg', true, {'boolean'})
   end,

   callback = function(...)
      return gen_capture('callback', {...}, {'table'})
   end,

   literal = function(value)
      return gen_capture('literal', value, {'string'})
   end,

   unary_operator = function(operator)
      return gen_capture('unary_operator', operator, {'string'})
   end,

   binary_operator = function(operator)
      return gen_capture('binary_operator', operator, {'string'})
   end,

   ternary_operator = function(operator)
      return gen_capture('ternary_operator', operator, {'string'})
   end,

   arithmetic_expr = function(...)
      return gen_capture('arithmetic_expr:', {...}, {'table'})
   end,

   parentheses = function(paren)
      return gen_capture('parentheses', paren, {'string'})
   end,

   bracket = function(bracket)
      return gen_capture('bracket', bracket, {'string'})
   end,

   brace = function(brace)
      return gen_capture('brace', brace, {'string'})
   end,

   values_on_braces = function(...)
      return gen_capture('values_on_braces', {...}, {'table'})
   end,
}

-- collection of literal patterns
c_patterns = {}

local function sort_fn(a, b)
   return string.len(a) > string.len(b)
end

c_patterns.custom_types_table = {}

function c_patterns:update_custom_types (type_name)
   for i = 1, #self.custom_types_table do
      if self.custom_types_table[i] == type_name then
         return;
      end
   end

   table.insert(self.custom_types_table, type_name)
   table.sort(self.custom_types_table, sort_fn)
end

c_patterns.custom_type = lpeg.P(function(subj, pos)
   if #c_patterns.custom_types_table == 0 then
      return false
   end

   local patt = lpeg.P(c_patterns.custom_types_table[1])

   for i = 2, #c_patterns.custom_types_table do
      patt = patt + lpeg.P(c_patterns.custom_types_table[i])
   end

   local final_patt = patt / captures.custom_type
   local match = lpeg.match(final_patt, string.sub(subj, pos))
   local result = match and pos + (string.len(match.value)) or false

   return result, match
end)

c_patterns.parentheses = lparen + rparen / captures.parentheses
c_patterns.bracket = lbracket + rbracket / captures.bracket
c_patterns.brace = lbrace + rbrace / captures.brace

c_patterns.unary_ops = unary_ops / captures.unary_operator
c_patterns.binary_ops = binary_ops / captures.binary_operator
c_patterns.ternary_ops = ternary_ops / captures.ternary_operator

c_patterns.ops = c_patterns.unary_ops + c_patterns.binary_ops + c_patterns.ternary_ops

c_patterns.comment_line = lpeg.P{
   'comment_line';
   comment_line = lpeg.P'//' * space^0 * lpeg.V'comment',
   comment = (word + space - newline)^0 / captures.comment
}

c_patterns.comment_multiline = lpeg.P{
   'comment_multiline';
   comment_multiline = lpeg.P'/*' * space^0 * lpeg.V'comment' * lpeg.P'*/',
   comment = ((word - lpeg.P'*') + space + (lpeg.P'*' - (lpeg.P'*/')))^0 / captures.comment
}

c_patterns.identifier = identifier / captures.identifier

c_patterns.literal = (
   (lpeg.S'\'"' * ((word - lpeg.S'\'"') + space)^0 * lpeg.S'\'"') + number
) / captures.literal

c_patterns.comment = c_patterns.comment_line + c_patterns.comment_multiline
c_patterns.void = kw'void' / captures.void
c_patterns.pointer = lpeg.P'*'^1 / captures.pointer
c_patterns.array = lbracket * space^0 * (digit^1 / captures.array) * space^0 * rbracket
c_patterns.variadic_arg = lpeg.P'...' / captures.variadic_arg

c_patterns.basic_type = lpeg.P{
   'basic_type';
   basic_type = (lpeg.V'boolean' + lpeg.V'character' + lpeg.V'integer' + lpeg.V'floating') / captures.basic_type,

   boolean = kw'_Bool' + kw'bool',

   character = (
      kw'char' +
      kw'signed' * space^1 * kw'char' +
      kw'unsigned' * space^1 * kw'char'
   ),

   integer = (
      kw'unsigned' * space^1 * kw'long' * space^1 * kw'long' * (space^1 * kw'int')^-1 +

      (kw'signed' * space^1)^-1 * kw'long' * space^1 * kw'long' * (space^1 * kw'int')^-1 +

      kw'unsigned' * space^1 * kw'long' * (space^1 * kw'int')^-1 +

      (kw'signed' * space^1)^-1 * kw'long' * (space^1 * kw'int')^-1 +

      kw'unsigned' * space^1 * kw'short' * (space^1 * kw'int')^-1 +

      (kw'signed' * space^1)^-1 * kw'short' * (space^1 * kw'int')^-1 +

      kw'unsigned' * (space^1 * kw'int')^-1 +

      ((kw'signed' * space^1 * kw'int') + (kw'signed' + kw'int'))
   ),

   floating = lpeg.V'floating_complex' + lpeg.V'floating_imaginary' + lpeg.V'floating_real',

   floating_complex = (
      -- NYI Note (from cppreference):
      -- as with all type specifiers, any order is permitted: long double complex, complex long double,
      -- and even double complex long name the same type.
      kw'long' * space^1 * kw'double' * space^1 * kw'_Complex' +

      kw'double' * space^1 * kw'_Complex' +

      kw'float' * space^1 * kw'_Complex'
   ),

   floating_imaginary = (
      -- NYI Note (from cppreference):
      -- as with all type specifiers, any order is permitted: long double imaginary, imaginary long double,
      -- and even double imaginary long name the same type.
      kw'long' * space^1 * kw'double' * space^1 * kw'_Imaginary' +

      kw'double' * space^1 * kw'_Imaginary' +

      kw'float' * space^1 * kw'_Imaginary'
   ),

   floating_real = (
      kw'long' * space^1 * kw'double' +

      kw'double' +

      kw'float'
   ),
}

c_patterns.alignment_specifier = kw'_Alignas' -- * space^0 * lpeg.P'(' * c_patterns.type * lpeg.P')'
c_patterns.storage_class_specifier = kw'auto' + kw'register' + kw'static' + kw'extern' + kw'_Thread_local'
c_patterns.function_specifier = kw'inline' + kw'_Noreturn'

c_patterns.specifier = (
   c_patterns.alignment_specifier + c_patterns.storage_class_specifier + c_patterns.function_specifier
) / captures.specifier

c_patterns.qualifier = kw'const' + kw'volatile' + kw'restrict' / captures.qualifier

c_patterns.atomic = kw'_Atomic'

c_patterns.specifiers_and_qualifiers = lpeg.P{
   'specifiers_and_qualifiers';
   specifiers_and_qualifiers = (
      (
         c_patterns.void +
         c_patterns.custom_type +
         c_patterns.basic_type +
         c_patterns.specifier +
         c_patterns.qualifier
      ) / captures.specifiers_and_qualifiers
   ) * (space^1 * lpeg.V'specifiers_and_qualifiers')^-1,
}

c_patterns.declarator = lpeg.P{
   'declarator';
   declarator = c_patterns.pointer^-1 * space^0 * c_patterns.identifier * space^0 * c_patterns.array^0 / captures.declarator
}

c_patterns.declarator_and_initializer = lpeg.P{
   'declarator_and_initializer';
   declarator_and_initializer = c_patterns.declarator * space^0 * lpeg.V'initializer'^-1 / captures.declarator_and_initializer,
   initializer = eq * space^0 * ((number^1 + identifier) / captures.initializer)
}

c_patterns.var_decl = lpeg.P{
   'var_decl';
   var_decl = (
      c_patterns.specifiers_and_qualifiers * space^0 * c_patterns.declarator_and_initializer * (
         space^0 * comma * space^0 * c_patterns.declarator_and_initializer
      )^0
   ) / captures.var_decl
}

c_patterns.func_decl = lpeg.P{
   'func_decl';
   func_decl = (
      c_patterns.specifiers_and_qualifiers * space^0 * c_patterns.declarator * space^0 *
      lparen * space^0 * (lpeg.V'func_arg'^-1 / captures.func_arg) * space^0 * rparen *
      space^0 * semicolon * space^0 * c_patterns.comment^-1
   ) / captures.func_decl,

   func_arg = (
      c_patterns.variadic_arg + (
         c_patterns.specifiers_and_qualifiers * space^0 * c_patterns.declarator * (
            space^0 * comma * space^0 * lpeg.V'func_arg'^-1
         )^0
      ) +
      c_patterns.void
   )
}

c_patterns.callback = lpeg.P{
   'callback';
   callback = (
      c_patterns.specifiers_and_qualifiers * space^0 * lparen * c_patterns.pointer * c_patterns.declarator_and_initializer * rparen *
      space^0 * lparen * space^0 * (lpeg.V'func_arg'^-1 / captures.func_arg) * space^0 * rparen
   ) / captures.callback,

   func_arg = (
      c_patterns.specifiers_and_qualifiers * space^0 * c_patterns.declarator_and_initializer * (
         space^0 * comma * space^0 * lpeg.V'func_arg'^-1
      )^0
   )
}

c_patterns.arithmetic_expr = lpeg.P{
   'arithmetic_expr';
   arithmetic_expr = (
      (
         (
            (c_patterns.unary_ops * lpeg.V'value') +
            (lpeg.V'value' * space^0 * c_patterns.binary_ops * space^0 * lpeg.V'value') +
            (lpeg.V'value' * space^0 * c_patterns.ternary_ops * space^0 * lpeg.V'value' * space^0 * c_patterns.ternary_ops * space^0 * lpeg.V'value') +
            lpeg.V'value'
         ) * space^0
      )^1 + (
         (lparen / captures.parentheses) *
         lpeg.V'arithmetic_expr'^1 *
         (rparen / captures.parentheses)
      )
   ) / captures.arithmetic_expr,

   value = c_patterns.literal + c_patterns.identifier
}

c_patterns.expression = c_patterns.arithmetic_expr

c_patterns.struct_decl = lpeg.P{
   'struct_declaration';
   struct_declaration = (
      kw'struct' * space^1 * lpeg.V'struct_name'^-1 * (
         space^0 * lbrace * space^0 * lpeg.V'struct_declaration_list' * space^0 * rbrace
      )^-1
   ) / captures.struct_decl,

   struct_declaration_list = lpeg.V'struct_member_decl'^1 / captures.struct_declaration_list,

   struct_member_decl = (
      (space^0 * c_patterns.var_decl * space^0 * semicolon * space^0 * c_patterns.comment^-1) +
      (space^0 * c_patterns.comment^1)
   ),

   struct_name = identifier / captures.struct_name
}

c_patterns.values_on_braces = lpeg.P{
   'values_on_braces';
   values_on_braces = (
      lbrace * space^0 * lpeg.V'values' * space^0 * rbrace
   ) / captures.values_on_braces,

   values = lpeg.V'value' * (space^0 * comma * space^0 * lpeg.V'values')^-1,

   value = c_patterns.literal + c_patterns.identifier + c_patterns.expression
}

c_patterns.enum_decl = lpeg.P{
   'enum_declaration';
   enum_declaration = (
      kw'enum' * space^1 * lpeg.V'enum_name'^-1 * space^0 * lbrace * space^0 *
      lpeg.V'enum_member_list' *
      space^0 * rbrace
   ) / captures.enum_decl,

   enum_member_list = lpeg.V'enum_member_decl'^1 / captures.enum_member_list,

   enum_member_decl = (
      (space^0 * c_patterns.declarator_and_initializer * space^0 * comma^-1 * space^0 * c_patterns.comment^-1) +
      (space^0 * c_patterns.comment^1)
   ),

   enum_name = identifier / captures.enum_name,
}

c_patterns.type_decl = c_patterns.struct_decl + c_patterns.enum_decl

c_patterns.typedef = lpeg.P{
   'typedef';
   typedef = kw'typedef' * space^1 * lpeg.V'type_definition' * space^1 * lpeg.V'typedef_alias' * space^0 * semicolon / captures.typedef,
   typedef_alias = identifier / captures.typedef_alias,
   type_definition = (c_patterns.type_decl + c_patterns.custom_type) / captures.typedef_type_definition,
}

c_patterns.define = lpeg.P{
   'define';
   define = (
      lpeg.P'#define' * space^1 * c_patterns.identifier * (lparen *  (lpeg.V'define_params' / captures.define_params) * rparen)^-1 * space^1 * lpeg.V'replacement' * c_patterns.comment^-1
   ) / captures.define,

   replacement = (
      c_patterns.identifier + c_patterns.values_on_braces + c_patterns.expression +
      (space - newline - c_patterns.comment)
   )^1 / captures.define_replacement,

   define_params = c_patterns.identifier * (comma * space^0 * lpeg.V'define_params')^-1
}

local raylib_pattern = (
   c_patterns.comment +
   c_patterns.define +
   c_patterns.typedef +
   c_patterns.func_decl +
   space^1 / function(spaces_str)
      return gen_capture('empty_space', spaces_str, {'string'})
   end
)

-- [=[
local teste1 = "float x = 3, y;"
local teste1_25 = "float x;"
local teste1_30 = "float *x;"
local teste1_5 = "float x0, y1, z, w2;"

local teste1_75 = "float x; float y;"

local teste1_999 = "struct Vector1 {float x;}"
local teste2 = "struct Vector2 {float x; float y; }"

local teste3 = [[typedef struct Vector4 {
    float x;
    float y;
    float z;
    float w;
} Vector4;]]

local teste4 = "typedef Vector4 Quaternion;"

local teste5 = [[typedef struct Matrix {
    float m0, m4, m8, m12;
    float m1, m5, m9, m13;
    float m2, m6, m10, m14;
    float m3, m7, m11, m15;
} Matrix;]]

local teste6 = [[typedef struct Color {
    unsigned char r;
    unsigned char g;
    unsigned char b;
    unsigned char a;
} Color;]]

local teste7 = [[enum {
    MAP_ALBEDO    = 0,       // MAP_DIFFUSE
    MAP_METALNESS = 1,       // MAP_SPECULAR
    MAP_NORMAL    = 2,
    MAP_ROUGHNESS = 3,
    MAP_OCCLUSION,
    MAP_EMISSION,
    MAP_HEIGHT,
    MAP_CUBEMAP,             // NOTE: Uses GL_TEXTURE_CUBE_MAP
    MAP_IRRADIANCE,          // NOTE: Uses GL_TEXTURE_CUBE_MAP
    MAP_PREFILTER,           // NOTE: Uses GL_TEXTURE_CUBE_MAP
    MAP_BRDF
}]]

local teste8 = [[typedef enum {
    MAP_ALBEDO    = 0,       // MAP_DIFFUSE
    MAP_METALNESS = 1,       // MAP_SPECULAR
    MAP_NORMAL    = 2,
    MAP_ROUGHNESS = 3,
    MAP_OCCLUSION,
    MAP_EMISSION,
    MAP_HEIGHT,
    MAP_CUBEMAP,             // NOTE: Uses GL_TEXTURE_CUBE_MAP
    MAP_IRRADIANCE,          // NOTE: Uses GL_TEXTURE_CUBE_MAP
    MAP_PREFILTER,           // NOTE: Uses GL_TEXTURE_CUBE_MAP
    MAP_BRDF
} MaterialMapType;]]

local teste9 = "// NOTE: Uses GL_TEXTURE_CUBE_MAP\n"

local teste10 = [[/*
   my
   super
   multi-line
   *comment*
*/]]

local teste11 = [[/*******
*   my
*   super
*   multi-line
*   *comment*
*******/]]

local teste12 = "#define MAX_TOUCH_POINTS 10 // Maximum number of touch points supported"
local teste13 = "#define FormatText  TextFormat\n"
local teste14 = "#define MAGENTA    (Color){ 255, 0, 255, 255 }     // Magenta\n"

local teste15 = [[typedef struct Shader {
    unsigned int id;        // Shader program id
    int **locs;              // Shader locations array (MAX_SHADER_LOCATIONS)
} Shader;]]

local teste16 = "float myarray[16]"

local teste17 = "int addsubroutine(int a, int b);"
local teste18 = "void *other(Color **a, int b);"

local teste19 = '3.14f'
local teste20 = '(3.14f)'
local teste21 = '(3.14f + 10)'
local teste22 = '#define PI (3.14f)'

local teste23 = '{ 255, 0, 255, 255 }'
local teste24 = '(Color){ 255, 0, 255, 255 }'

local function test(patt, str)
   print('\nstring to parse:{' .. str .. '}')
   return { lpeg.match(patt, str) }
end

print(ins(test(c_patterns.var_decl, teste1)))
print(ins(test(c_patterns.var_decl, teste1_25)))
print(ins(test(c_patterns.var_decl, teste1_30)))
print(ins(test(c_patterns.var_decl, teste1_5)))
print(ins(test(c_patterns.var_decl * space^0 * semicolon * space^0 * c_patterns.var_decl, teste1_75)))

print(ins(test(c_patterns.struct_decl, teste1_999)))
print(ins(test(c_patterns.struct_decl, teste2)))

print(ins(test(c_patterns.typedef, teste3)))
print(ins(test(c_patterns.typedef, teste4)))
print(ins(test(c_patterns.typedef, teste5)))
print(ins(test(c_patterns.typedef, teste6)))

print(ins(test(c_patterns.enum_decl, teste7)))
print(ins(test(c_patterns.typedef, teste8)))

print(ins(test(c_patterns.comment, teste9)))
print(ins(test(c_patterns.comment, teste10)))
print(ins(test(c_patterns.comment, teste11)))

print(ins(test(c_patterns.define, teste12)))
print(ins(test(c_patterns.define, teste13)))
print(ins(test(c_patterns.define, teste14)))

print(ins(test(c_patterns.typedef, teste15)))

print(ins(test(c_patterns.specifiers_and_qualifiers, 'static float')))
print(ins(test(c_patterns.var_decl, 'static Vector4 x')))

print("custom_types_table: ", ins(c_patterns.custom_types_table))

print(ins(test(c_patterns.var_decl, teste16)))

print(ins(test(c_patterns.func_decl, teste17)))
print(ins(test(c_patterns.func_decl, teste18)))

print(ins(test(c_patterns.expression, teste19)))
print(ins(test(c_patterns.expression, teste20)))
print(ins(test(c_patterns.expression, teste21)))

print(ins(test(c_patterns.define, teste22)))

print(ins(test(c_patterns.values_on_braces, teste23)))

print(ins(c_patterns.custom_types_table))

print(ins(test(c_patterns.expression, teste24)))


print((
   ("/*this should not*/exist"):gsub("/%*(.-)%*/", "")
))

print((
   ([[line 1
line 2
/*******
* line 3
* line 4
*******/
line5
]]):gsub("/%*(.-)%*/", "")
))
--]=]

return {
   read = function(filename)
      local raylib_h = io.open(filename)
      local raylib_h_str = raylib_h:read'a'
      raylib_h:close()

      raylib_h_str = raylib_h_str:gsub("/%*(.-)%*/", "") --:gsub("\n+", "\n")

      local len = raylib_h_str:len()
      local pos = 1
      local results = {}

      -- another hack, sorry
      table.insert(
         results,
         lpeg.match(c_patterns.callback, [[void (*TraceLogCallback)(int logType, const char *text, va_list args)]])
      )
      c_patterns:update_custom_types('TraceLogCallback')

      repeat
         local result, _pos = lpeg.match(raylib_pattern * lpeg.Cp(), raylib_h_str, pos)

         if not _pos then -- _pos is nil when something is wrong
            print('_pos is nil ~> ' .. raylib_h_str:sub(pos))
            print(ins(results))
            error('error on lpeg raylib reader')
         end

         pos = _pos
         table.insert(results, result)
      until pos >= len

      --print(ins(results))

      return results
   end,
}
