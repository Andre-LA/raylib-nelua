--[[ This Source Code Form is subject to the terms of the Mozilla Public
     License, v. 2.0. If a copy of the MPL was not distributed with this
     file, You can obtain one at https://mozilla.org/MPL/2.0/. ]]

local ins = require 'inspect'

local lpeg_raylib_parser = require 'binding_generator/lpeg-raylib-parser'
local bindgen = require 'binding_generator/generic-binding-generator'
local converters = bindgen.converters
local config = bindgen.config

local linklibs = {'raylib'}

local final_result = {}

table.insert(final_result, '-- links: \n')

for i = 1, #linklibs do
  table.insert(final_result, "## linklib '" .. linklibs[i] .. "' \n")
end

-- TODO: Implement callback!
table.insert(final_result, '\nglobal TraceLogCallback = @record{}\n')

-- [ raylib.h [
config.record_in_use = 'Raylib'
config.cinclude_in_use = 'raylib.h'

local raylib_table = lpeg_raylib_parser.read'binding_generator/modified-raylib.h'
local raylib_result = converters.convert(raylib_table)

table.insert(final_result, '\n-- raylib binding:\n')
table.insert(final_result, 'global Raylib = @record{}')

for i = 1, #raylib_result do
  table.insert(final_result, raylib_result[i])
end

table.insert(final_result, '')

-- ] raylib.h ]

-- [ raymath.h [
config.record_in_use = 'Raymath'
config.cinclude_in_use = 'raymath.h'

local raymath_table = lpeg_raylib_parser.read'binding_generator/modified-raymath.h'
local raymath_result = converters.convert(raymath_table)

table.insert(final_result, '\n\n-- raymath binding: \n')
table.insert(final_result, 'global Raymath = @record{}\n')

for i = 1, #raymath_result do
  table.insert(final_result, raymath_result[i])
end

table.insert(final_result, '\n')

for i = 1, #final_result do
  if string.find(final_result[i], 'global Font ') then
    final_result[i] = string.gsub(final_result[i], 'recs: %*Rectangle', 'recs: *[0]Rectangle')
    final_result[i] = string.gsub(final_result[i], 'chars: %*CharInfo', 'recs: *[0]CharInfo')
  end

  if string.find(final_result[i], 'global Mesh ') then
    final_result[i] = string.gsub(final_result[i], 'vertices: %*float32', 'vertices: *[0]float32')
    final_result[i] = string.gsub(final_result[i], 'texcoords: %*float32', 'texcoords: *[0]float32')
    final_result[i] = string.gsub(final_result[i], 'texcoords2: %*float32', 'texcoords2: *[0]float32')
    final_result[i] = string.gsub(final_result[i], 'normals: %*float32', 'normals: *[0]float32')
    final_result[i] = string.gsub(final_result[i], 'tangents: %*float32', 'tangents: *[0]float32')
    final_result[i] = string.gsub(final_result[i], 'colors: %*cuchar', 'colors: *[0]cuchar')
    final_result[i] = string.gsub(final_result[i], 'indices: %*cushort', 'indices: *[0]cushort')
    final_result[i] = string.gsub(final_result[i], 'animVertices: %*float32', 'animVertices: *[0]float32')
    final_result[i] = string.gsub(final_result[i], 'animNormals: %*float32', 'animNormals: *[0]float32')
    final_result[i] = string.gsub(final_result[i], 'boneIds: %*cint', 'boneIds: *[0]cint')
    final_result[i] = string.gsub(final_result[i], 'boneWeights: %*float32', 'boneWeights: *[0]float32')
    final_result[i] = string.gsub(final_result[i], 'vboId: %*cuint', 'vboId: *[0]cuint')
  end

  if string.find(final_result[i], 'global Shader ') then
    final_result[i] = string.gsub(final_result[i], 'locs: %*cint', 'locs: *[0]cint')
  end

  if string.find(final_result[i], 'global Material ') then
    final_result[i] = string.gsub(final_result[i], 'maps: %*MaterialMap', 'maps: *[0]MaterialMap')
    final_result[i] = string.gsub(final_result[i], 'params: %*float32', 'params: *[0]float32')
  end

  if string.find(final_result[i], 'global Model ') then
    final_result[i] = string.gsub(final_result[i], 'meshes: %*Mesh', 'meshes: *[0]Mesh')
    final_result[i] = string.gsub(final_result[i], 'materials: %*Material', 'materials: *[0]Material')
    final_result[i] = string.gsub(final_result[i], 'meshMaterial: %*cint', 'meshMaterial: *[0]cint')
    final_result[i] = string.gsub(final_result[i], 'bones: %*BoneInfo', 'bones: *[0]BoneInfo')
    final_result[i] = string.gsub(final_result[i], 'bindPose: %*Transform', 'bindPose: *[0]Transform')
  end

  if string.find(final_result[i], 'global ModelAnimation ') then
    final_result[i] = string.gsub(final_result[i], 'bones: %*BoneInfo', 'bones: *[0]BoneInfo')
    final_result[i] = string.gsub(final_result[i], 'framePoses: %*%*Transform', 'framePoses: *[0]*[0]Transform')
  end
end

table.insert(final_result, [[
-- [ operator overloading [

-- [ Vector2 [
-- Add two vectors (v1 + v2)
function Vector2.__add(v1: Vector2, v2: Vector2): Vector2 <cimport'Vector2Add', nodecl> end
-- Subtract two vectors (v1 - v2)
function Vector2.__sub(v1: Vector2, v2: Vector2): Vector2 <cimport'Vector2Subtract', nodecl> end
-- Calculate vector length
function Vector2.__len(v: Vector2): float32 <cimport'Vector2Length', nodecl> end
-- Negate vector
function Vector2.__unm(v: Vector2): Vector2 <cimport'Vector2Negate', nodecl> end
-- Divide vector by a float value or vector
function Vector2.__div(v: Vector2, divisor: overload(Vector2, number)): Vector2
  ## if divisor.is_vector2 then
    return Vector2.DivideV(v, divisor)
  ## else
    return Vector2.Divide(v, divisor)
  ## end
end
-- Scale vector (multiply by value) or Multiply vector by vector
function Vector2.__mul(v: Vector2, multiplier: overload(Vector2, number)): Vector2
  ## if multiplier.is_vector2 then
    return Vector2.MultiplyV(v, multiplier)
  ## else
    return Vector2.Scale(v, multiplier)
  ## end
end
-- ] Vector2 ]

-- [ Vector3 [
-- Add two vectors
function Vector3.__add(v1: Vector3, v2: Vector3): Vector3 <cimport'Vector3Add', nodecl> end
-- Subtract two vectors
function Vector3.__sub(v1: Vector3, v2: Vector3): Vector3 <cimport'Vector3Subtract', nodecl> end
-- Calculate vector length
function Vector3.__len(v: Vector3): float32 <cimport'Vector3Length', nodecl> end
-- Negate provided vector (invert direction)
function Vector3.__unm(v: Vector3): Vector3 <cimport'Vector3Negate', nodecl> end
-- Multiply vector by scalar or by vector
function Vector3.__mul(v: Vector3, multiplier: overload(Vector3, number)): Vector3
  ## if multiplier.is_vector3 then
    return Vector3.MultiplyV(v, multiplier)
  ## else
    return Vector3.Scale(v, multiplier)
  ## end
end
-- Divide vector by a float value or by vector
function Vector3.__div(v: Vector3, divisor: overload(Vector3, number)): Vector3
   ## if divisor.is_vector3 then
    return Vector3.DivideV(v, divisor)
  ## else
    return Vector3.Divide(v, divisor)
  ## end
end
-- ] Vector3 ]

-- [ Matrix [
-- Add two matrices
function Matrix.__add(left: Matrix, right: Matrix): Matrix <cimport'MatrixAdd', nodecl> end
-- Subtract two matrices (left - right)
function Matrix.__sub(left: Matrix, right: Matrix): Matrix <cimport'MatrixSubtract', nodecl> end
-- Returns two matrix multiplication
-- NOTE: When multiplying matrices... the order matters!
function Matrix.__mul(left: Matrix, right: Matrix): Matrix <cimport'MatrixMultiply', nodecl> end
-- ] Matrix ]

-- [ Quaternion [
-- Computes the length of a quaternion
function Quaternion.__len(q: Quaternion): float32 <cimport'QuaternionLength', nodecl> end
-- Calculate two quaternion multiplication
function Quaternion.__mul(q1: Quaternion, q2: Quaternion): Quaternion <cimport'QuaternionMultiply', nodecl> end
-- ] Quaternion ]

-- ] operator overloading ]
]])

do
  local records_with_functions = {
    'Vector2',
    'Vector3',
    'Matrix',
    'Quaternion',
  }

  local function add_rec_fn (line, rec_name)
    local rec_name_len = string.len(rec_name)
    if string.sub(line, 1, 17 + rec_name_len) == 'function Raymath.' .. rec_name then
      local lparen_pos = string.find(line, "%(")
      local record_fn_name = 'function ' .. rec_name .. '.' .. string.sub(line, 18 + rec_name_len)
      return record_fn_name
    end
  end

  for i = #final_result, 1, -1 do
    for j = 1, #records_with_functions do
      local ok_extra_line = add_rec_fn(final_result[i], records_with_functions[j])
      if ok_extra_line then
        table.insert(final_result, i+1, '\n' .. ok_extra_line)
        break
      end
    end
  end
end
--] raymath.h ]

local file_to_generate = io.open('raylib.nelua', 'w+')
file_to_generate:write(table.concat(final_result))
file_to_generate:close()
