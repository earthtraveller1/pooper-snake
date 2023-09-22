const std = @import("std");
const raylib = @cImport(@cInclude("raylib.h"));

const assets = struct {
    const canpooper_png = @embedFile("assets/canpooper.png");
    const burger_png = @embedFile("assets/burger.png");
};

// Measured in pixel.
const window_width = 800;
const window_height = 600;

// Measured in pixels.
const unit_size = 50;

// Measured in units per second.
const player_speed = 3;

pub fn main() !void {
    raylib.InitWindow(window_width, window_height, "Pooper Snake");
    defer raylib.CloseWindow();

    raylib.SetTargetFPS(60);

    const can_pooper_image = raylib.LoadImageFromMemory(".png", assets.canpooper_png, assets.canpooper_png.len);
    const can_pooper_texture = raylib.LoadTextureFromImage(can_pooper_image);

    const burger_image = raylib.LoadImageFromMemory(".png", assets.burger_png, assets.burger_png.len);
    const burger_texture = raylib.LoadTextureFromImage(burger_image);

    var delta_time: f64 = 0;
    var player_position: raylib.Vector2 = .{ .x = 0.0, .y = 0.0 };

    while (!raylib.WindowShouldClose()) {
        const start_time = raylib.GetTime();

        player_position.y += @floatCast(player_speed * unit_size * delta_time);

        raylib.BeginDrawing();

        raylib.ClearBackground(raylib.BLACK);
        raylib.DrawTextureV(can_pooper_texture, player_position, raylib.WHITE);
        raylib.DrawTexture(burger_texture, 100, 100, raylib.WHITE);

        raylib.EndDrawing();

        raylib.PollInputEvents();

        const end_time = raylib.GetTime();
        delta_time = end_time - start_time;
    }
}
