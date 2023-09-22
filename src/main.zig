const std = @import("std");
const raylib = @cImport(@cInclude("raylib.h"));

const assets = struct {
    const canpooper_png = @embedFile("assets/canpooper.png");
    const burger_png = @embedFile("assets/burger.png");
};

const window_width = 800;
const window_height = 600;

pub fn main() !void {
    raylib.InitWindow(window_width, window_height, "Pooper Snake");
    defer raylib.CloseWindow();

    raylib.SetTargetFPS(60);

    const can_pooper_image = raylib.LoadImageFromMemory(".png", assets.canpooper_png, assets.canpooper_png.len);
    const can_pooper_texture = raylib.LoadTextureFromImage(can_pooper_image);

    const burger_image = raylib.LoadImageFromMemory(".png", assets.burger_png, assets.burger_png.len);
    const burger_texture = raylib.LoadTextureFromImage(burger_image);

    while (!raylib.WindowShouldClose()) {
        raylib.BeginDrawing();

        raylib.ClearBackground(raylib.BLACK);
        raylib.DrawTexture(can_pooper_texture, 10, 10, raylib.WHITE);
        raylib.DrawTexture(burger_texture, 100, 100, raylib.WHITE);

        raylib.EndDrawing();

        raylib.PollInputEvents();
    }
}
