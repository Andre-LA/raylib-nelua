## raylib-nelua

This is a [Raylib](https://www.raylib.com/) wrapper for [Nelua language](https://nelua.io/)

## Example

```Lua
    -- moves raylib.nelua file to your project
    require 'raylib'

    local screenWidth: integer <comptime> = 800
    local screenHeight: integer <comptime> = 450

    Raylib.InitWindow(screenWidth, screenHeight, "raylib [core] example - basic window")
    Raylib.SetTargetFPS(60)

    while not Raylib.WindowShouldClose() do
       Raylib.BeginDrawing()
          Raylib.ClearBackground(RaylibColors.Raywhite)
          Raylib.DrawText("Congrats! You created your first window!", 190, 200, 20, RaylibColors.Lightgray)
       Raylib.EndDrawing()
    end

    Raylib.CloseWindow()

```
