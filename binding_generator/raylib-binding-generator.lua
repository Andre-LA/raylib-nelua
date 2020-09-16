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

-- creates a code pattern
-- e.g.:  "Raylib.DecompressData(compData: *cuchar" -> "Raylib%.DecompressData%(compData: %*cuchar"
local function codepatt(code)
  return code:gsub('%%', '%%%%')
             :gsub('%.', '%%.')
             :gsub('%*', '%%*')
             :gsub('%(', '%%(')
             :gsub('%)', '%%)')
             :gsub('%[', '%%[')
             :gsub('%]', '%%]')
end
-- this modifies final_result[i]!
local function apply_unbounded_array(i, originalcode, replcode)
  local patt = codepatt(originalcode)
  local fr_i, n = string.gsub(final_result[i], patt, replcode)
  assert(n > 0, string.format('apply_unbounded_array: nothing was applied: codepatt: %s; replcode: %s', patt, replcode))
  final_result[i] = fr_i
end

for i = 1, #final_result do
  local find = string.find

  -- apply undbounded array type to records
  if find(final_result[i], 'global Font ', 1, true) then
    apply_unbounded_array(i, 'recs: *Rectangle', 'recs: *[0]Rectangle')
    apply_unbounded_array(i, 'chars: *CharInfo', 'chars: *[0]CharInfo')
  end

  if find(final_result[i], 'global Mesh ', 1, true) then
    apply_unbounded_array(i, 'vertices: *float32', 'vertices: *[0]float32')
    apply_unbounded_array(i, 'texcoords: *float32', 'texcoords: *[0]float32')
    apply_unbounded_array(i, 'texcoords2: *float32', 'texcoords2: *[0]float32')
    apply_unbounded_array(i, 'normals: *float32', 'normals: *[0]float32')
    apply_unbounded_array(i, 'tangents: *float32', 'tangents: *[0]float32')
    apply_unbounded_array(i, 'colors: *cuchar', 'colors: *[0]cuchar')
    apply_unbounded_array(i, 'indices: *cushort', 'indices: *[0]cushort')
    apply_unbounded_array(i, 'animVertices: *float32', 'animVertices: *[0]float32')
    apply_unbounded_array(i, 'animNormals: *float32', 'animNormals: *[0]float32')
    apply_unbounded_array(i, 'boneIds: *cint', 'boneIds: *[0]cint')
    apply_unbounded_array(i, 'boneWeights: *float32', 'boneWeights: *[0]float32')
    apply_unbounded_array(i, 'vboId: *cuint', 'vboId: *[0]cuint')
  end

  if find(final_result[i], 'global Shader ', 1, true) then
    apply_unbounded_array(i, 'locs: *cint', 'locs: *[0]cint')
  end

  if find(final_result[i], 'global Material ', 1, true) then
    apply_unbounded_array(i, 'maps: *MaterialMap', 'maps: *[0]MaterialMap')
    apply_unbounded_array(i, 'params: *float32', 'params: *[0]float32')
  end

  if find(final_result[i], 'global Model ', 1, true) then
    apply_unbounded_array(i, 'meshes: *Mesh', 'meshes: *[0]Mesh')
    apply_unbounded_array(i, 'materials: *Material', 'materials: *[0]Material')
    apply_unbounded_array(i, 'meshMaterial: *cint', 'meshMaterial: *[0]cint')
    apply_unbounded_array(i, 'bones: *BoneInfo', 'bones: *[0]BoneInfo')
    apply_unbounded_array(i, 'bindPose: *Transform', 'bindPose: *[0]Transform')
  end

  if find(final_result[i], 'global ModelAnimation ', 1, true) then
    apply_unbounded_array(i, 'bones: *BoneInfo', 'bones: *[0]BoneInfo')
    apply_unbounded_array(i, 'framePoses: **Transform', 'framePoses: *[0]*[0]Transform')
  end

  -- apply undbounded array type to functions
  if find(final_result[i], 'Raylib.LoadFileData(fileName: cstring, bytesRead: *cuint): *cuchar', 1, true) then
    apply_unbounded_array(i, 'Raylib.LoadFileData(fileName: cstring, bytesRead: *cuint): *cuchar', 'Raylib.LoadFileData(fileName: cstring, bytesRead: *cuint): *[0]cuchar')
  end
  if find(final_result[i], 'Raylib.GetDirectoryFiles(dirPath: cstring, count: *cint): *cstring', 1, true) then
    apply_unbounded_array(i, 'Raylib.GetDirectoryFiles(dirPath: cstring, count: *cint): *cstring', 'Raylib.GetDirectoryFiles(dirPath: cstring, count: *cint): *[0]cstring')
  end
  if find(final_result[i], 'Raylib.GetDroppedFiles(count: *cint): *cstring', 1, true) then
    apply_unbounded_array(i, 'Raylib.GetDroppedFiles(count: *cint): *cstring', 'Raylib.GetDroppedFiles(count: *cint): *[0]cstring')
  end
  if find(final_result[i], 'Raylib.CompressData(data: *cuchar, dataLength: cint, compDataLength: *cint): *cuchar', 1, true) then
    apply_unbounded_array(i, 'Raylib.CompressData(data: *cuchar, dataLength: cint, compDataLength: *cint): *cuchar', 'Raylib.CompressData(data: *[0]cuchar, dataLength: cint, compDataLength: *cint): *[0]cuchar')
  end
  if find(final_result[i], 'Raylib.DecompressData(compData: *cuchar, compDataLength: cint, dataLength: *cint): *cuchar', 1, true) then
    apply_unbounded_array(i, 'Raylib.DecompressData(compData: *cuchar, compDataLength: cint, dataLength: *cint): *cuchar', 'Raylib.DecompressData(compData: *[0]cuchar, compDataLength: cint, dataLength: *cint): *[0]cuchar')
  end
  if find(final_result[i], 'Raylib.DrawLineStrip(points: *Vector2, numPoints: cint, color: Color): void', 1, true) then
    apply_unbounded_array(i, 'Raylib.DrawLineStrip(points: *Vector2, numPoints: cint, color: Color): void', 'Raylib.DrawLineStrip(points: *[0]Vector2, numPoints: cint, color: Color): void')
  end
  if find(final_result[i], 'Raylib.LoadImageEx(pixels: *Color, width: cint, height: cint): Image', 1, true) then
    apply_unbounded_array(i, 'Raylib.LoadImageEx(pixels: *Color, width: cint, height: cint): Image', 'Raylib.LoadImageEx(pixels: *[0]Color, width: cint, height: cint): Image')
  end
  if find(final_result[i], 'Raylib.GetImageData(image: Image): *Color', 1, true) then
    apply_unbounded_array(i, 'Raylib.GetImageData(image: Image): *Color', 'Raylib.GetImageData(image: Image): *[0]Color')
  end
  if find(final_result[i], 'Raylib.GetImageDataNormalized(image: Image): *Vector4', 1, true) then
    apply_unbounded_array(i, 'Raylib.GetImageDataNormalized(image: Image): *Vector4', 'Raylib.GetImageDataNormalized(image: Image): *[0]Vector4')
  end
  if find(final_result[i], 'Raylib.ImageExtractPalette(image: Image, maxPaletteSize: cint, extractCount: *cint): *Color', 1, true) then
    apply_unbounded_array(i, 'Raylib.ImageExtractPalette(image: Image, maxPaletteSize: cint, extractCount: *cint): *Color', 'Raylib.ImageExtractPalette(image: Image, maxPaletteSize: cint, extractCount: *cint): *[0]Color')
  end
  if find(final_result[i], 'Raylib.LoadFontEx(fileName: cstring, fontSize: cint, fontChars: *cint, charsCount: cint): Font', 1, true) then
    apply_unbounded_array(i, 'Raylib.LoadFontEx(fileName: cstring, fontSize: cint, fontChars: *cint, charsCount: cint): Font', 'Raylib.LoadFontEx(fileName: cstring, fontSize: cint, fontChars: *[0]cint, charsCount: cint): Font')
  end
  if find(final_result[i], 'Raylib.LoadFontData(fileName: cstring, fontSize: cint, fontChars: *cint, charsCount: cint, type: cint): *CharInfo', 1, true) then
    apply_unbounded_array(i, 'Raylib.LoadFontData(fileName: cstring, fontSize: cint, fontChars: *cint, charsCount: cint, type: cint): *CharInfo', 'Raylib.LoadFontData(fileName: cstring, fontSize: cint, fontChars: *[0]cint, charsCount: cint, type: cint): *[0]CharInfo')
  end
  if find(final_result[i], 'Raylib.GenImageFontAtlas(chars: *CharInfo, recs: **Rectangle, charsCount: cint, fontSize: cint, padding: cint, packMethod: cint): Image', 1, true) then
    apply_unbounded_array(i, 'Raylib.GenImageFontAtlas(chars: *CharInfo, recs: **Rectangle, charsCount: cint, fontSize: cint, padding: cint, packMethod: cint): Image', 'Raylib.GenImageFontAtlas(chars: *[0]CharInfo, recs: **[0]Rectangle, charsCount: cint, fontSize: cint, padding: cint, packMethod: cint): Image')
  end
  if find(final_result[i], 'Raylib.TextJoin(textList: *cstring, count: cint, delimiter: cstring): cstring', 1, true) then
    apply_unbounded_array(i, 'Raylib.TextJoin(textList: *cstring, count: cint, delimiter: cstring): cstring', 'Raylib.TextJoin(textList: *[0]cstring, count: cint, delimiter: cstring): cstring')
  end
  if find(final_result[i], 'Raylib.TextSplit(text: cstring, delimiter: cchar, count: *cint): *cstring', 1, true) then
    apply_unbounded_array(i, 'Raylib.TextSplit(text: cstring, delimiter: cchar, count: *cint): *cstring', 'Raylib.TextSplit(text: cstring, delimiter: cchar, count: *cint): *[0]cstring')
  end
  if find(final_result[i], 'Raylib.TextToUtf8(codepoints: *cint, length: cint): cstring', 1, true) then
    apply_unbounded_array(i, 'Raylib.TextToUtf8(codepoints: *cint, length: cint): cstring', 'Raylib.TextToUtf8(codepoints: *[0]cint, length: cint): cstring')
  end
  if find(final_result[i], 'Raylib.GetCodepoints(text: cstring, count: *cint): *cint', 1, true) then
    apply_unbounded_array(i, 'Raylib.GetCodepoints(text: cstring, count: *cint): *cint', 'Raylib.GetCodepoints(text: cstring, count: *cint): *[0]cint')
  end
  if find(final_result[i], 'Raylib.LoadMeshes(fileName: cstring, meshCount: *cint): *Mesh', 1, true) then
    apply_unbounded_array(i, 'Raylib.LoadMeshes(fileName: cstring, meshCount: *cint): *Mesh', 'Raylib.LoadMeshes(fileName: cstring, meshCount: *cint): *[0]Mesh')
  end
  if find(final_result[i], 'Raylib.LoadMaterials(fileName: cstring, materialCount: *cint): *Material', 1, true) then
    apply_unbounded_array(i, 'Raylib.LoadMaterials(fileName: cstring, materialCount: *cint): *Material', 'Raylib.LoadMaterials(fileName: cstring, materialCount: *cint): *[0]Material')
  end
  if find(final_result[i], 'Raylib.LoadModelAnimations(fileName: cstring, animsCount: *cint): *ModelAnimation', 1, true) then
    apply_unbounded_array(i, 'Raylib.LoadModelAnimations(fileName: cstring, animsCount: *cint): *ModelAnimation', 'Raylib.LoadModelAnimations(fileName: cstring, animsCount: *cint): *[0]ModelAnimation')
  end
  if find(final_result[i], 'Raylib.GetWaveData(wave: Wave): *float32', 1, true) then
    apply_unbounded_array(i, 'Raylib.GetWaveData(wave: Wave): *float32', 'Raylib.GetWaveData(wave: Wave): *[0]float32')
  end

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
