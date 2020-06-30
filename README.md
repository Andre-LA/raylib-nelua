# raylib-nelua

This is a [Raylib](https://www.raylib.com/) binding for [Nelua language](https://nelua.io/).

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
