const std = @import("std");
const raylib = @cImport(@cInclude("raylib.h"));

const assets = struct {
    const can_pooper_right_png = @embedFile("assets/canpooper.png");
};

const window_width = 800;
const window_height = 600;

pub fn main() !void {
    raylib.InitWindow(window_width, window_height, "Pooper Snake");
    defer raylib.CloseWindow();

    raylib.SetTargetFPS(60);

    const can_pooper_image = raylib.LoadImageFromMemory(".png", assets.can_pooper_right_png, assets.can_pooper_right_png.len);
    const can_pooper_texture = raylib.LoadTextureFromImage(can_pooper_image);

    while (!raylib.WindowShouldClose()) {
        raylib.BeginDrawing();

        raylib.ClearBackground(raylib.BLACK);
        raylib.DrawTexture(can_pooper_texture, 10, 10, raylib.WHITE);

        raylib.EndDrawing();

        raylib.PollInputEvents();
    }
}
