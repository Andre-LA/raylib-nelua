# raylib-nelua

This is a [Raylib](https://www.raylib.com/) wrapper for [Nelua language](https://nelua.io/)

## Example

```Lua
    -- moves raylib.nelua file to your project
    require 'raylib'

    local screenWidth: integer <comptime> = 800
    local screenHeight: integer <comptime> = 450
    local ballPosition: Vector2 = {x = screenWidth/2, y = screenHeight/2}

    Raylib.InitWindow(screenWidth, screenHeight, "raylib [core] example - keyboard input")
    Raylib.SetTargetFPS(60)

    while (not Raylib.WindowShouldClose()) do
        if Raylib.IsKeyDown(KeyboardKey.RIGHT) then
            ballPosition.x = ballPosition.x + 2.0
        end
        if Raylib.IsKeyDown(KeyboardKey.LEFT) then
            ballPosition.x = ballPosition.x - 2.0
        end
        if Raylib.IsKeyDown(KeyboardKey.UP) then
            ballPosition.y = ballPosition.y - 2.0
        end
        if Raylib.IsKeyDown(KeyboardKey.DOWN) then
            ballPosition.y = ballPosition.y + 2.0
        end

        Raylib.BeginDrawing()
            Raylib.ClearBackground(RaylibColors.Raywhite)
            Raylib.DrawText("move the ball with arrow keys", 10, 10, 20, RaylibColors.Darkgray)
            Raylib.DrawCircleV(ballPosition, 50, RaylibColors.Maroon)
        Raylib.EndDrawing()
    end

    Raylib.CloseWindow()
```
