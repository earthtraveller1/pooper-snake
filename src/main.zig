const std = @import("std");
const raylib = @cImport(@cInclude("raylib.h"));

const window_width = 800;
const window_height = 600;

pub fn main() !void {
    raylib.InitWindow(window_width, window_height, "Pooper Snake");
    defer raylib.CloseWindow();

    raylib.SetTargetFPS(60);

    while (!raylib.WindowShouldClose()) {
        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.BLACK);
        raylib.EndDrawing();

        raylib.PollInputEvents();
    }
}
