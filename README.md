# raylib-nelua

This is a [Raylib 3.0](https://www.raylib.com/) binding for [Nelua language](https://nelua.io/).

## How to use

After [installing Nelua](https://nelua.io/installing/) and [Raylib](https://github.com/raysan5/raylib#build-and-installation),
move to your project either `raylib.nelua` **(recommended)** or `generated-raylib.nelua`:

* `generated-raylib.nelua`: is a binding generated automatically by running `$ lua binding_generator/binding_generator.lua`
* `raylib.nelua`: manually tweaked from `generated-raylib.nelua` to make use of some useful nelua features:
    * for every record an `is_*` field is defined on type information, for example, `rAudioBuffer.value.is_raudiobuffer` is `true`;
    * record functions to `Vector2`, `Vector3`, `Matrix` and `Quaternion` records from `raymath.h`, for example, `Vector3.Add` calls `Vector3Add`;
    * operator overloading functions:
        * `Vector2`: 
            * `__add`: calls `Vector2Add`
            * `__sub`: calls `Vector2Subtract`
            * `__len`: calls `Vector2Length`
            * `__unm`: calls `Vector2Negate`
            * `__div`: calls `Vector2Divide` or `Vector2DivideV`
            * `__mul`: calls `Vector2Scale` or `Vector2MultiplyV`
        * `Vector3`: 
            * `__add`: calls `Vector3Add`
            * `__sub`: calls `Vector3Subtract`
            * `__len`: calls `Vector3Length`
            * `__unm`: calls `Vector3Negate`
            * `__mul`: calls `Vector3Scale` or `Vector3Multiply`
            * `__div`: calls `Vector3Divide` or `Vector3DivideV`
        * `Matrix`: 
            * `__add`: calls `MatrixAdd`
            * `__sub`: calls `MatrixSubtract`
            * `__mul`: calls `MatrixMultiply`
        * `Quaternion`: 
            * `__len`: calls `QuaternionLength`
            * `__mul`: calls `QuaternionMultiply`

## Example

```Lua
-- move raylib.nelua file to your project
require 'raylib'

-- [ Initialization [
local screen_width: integer <comptime> = 800
local screen_height: integer <comptime> = 450

Raylib.InitWindow(screen_width, screen_height, "raylib-nelua [core] example - keyboard input")

local ball_position: Vector2 = { screen_width / 2, screen_height / 2}

Raylib.SetTargetFPS(60) -- Set our game to run at 60 frames-per-second
-- ] Initialization ]

-- Main game loop
while not Raylib.WindowShouldClose() do -- Detect window close button or ESC key
   -- [ Update [
   if Raylib.IsKeyDown(KeyboardKey.KEY_RIGHT) then
      ball_position.x = ball_position.x + 2
   end
   if Raylib.IsKeyDown(KeyboardKey.KEY_LEFT) then
      ball_position.x = ball_position.x - 2
   end
   if Raylib.IsKeyDown(KeyboardKey.KEY_UP) then
      ball_position.y = ball_position.y - 2
   end
   if Raylib.IsKeyDown(KeyboardKey.KEY_DOWN) then
      ball_position.y = ball_position.y + 2
   end
   -- ] Update ]

   -- [ Draw [
   Raylib.BeginDrawing() --[
      Raylib.ClearBackground(RAYWHITE)
      Raylib.DrawText("move the ball with arrow keys", 10, 10, 20, DARKGRAY)
      Raylib.DrawCircleV(ball_position, 50, MAROON)
   Raylib.EndDrawing() --]
   -- ] Draw ]
end

-- [ De-Initialization [
Raylib.CloseWindow() -- Close window and OpenGL context
-- ] De-Initialization ]
```
