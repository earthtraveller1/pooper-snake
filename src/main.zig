const std = @import("std");
const raylib = @cImport(@cInclude("raylib.h"));

const assets = struct {
    const canpooper_png = @embedFile("assets/canpooper.png");
    const burger_png = @embedFile("assets/burger.png");
    const crate_png = @embedFile("assets/crate.png");
};

const PlayerPart = struct {
    unit_x: u32,
    unit_y: u32,
};

const Rotation = struct {
    new_direction: Direction,
    timestamp: f64,
};

// Measured in pixel.
const window_width = 1400;
const window_height = 1000;

// Measured in pixels.
const unit_size = 100;

// Measured in units per second.
const player_speed = 6;

const Direction = enum { left, right, up, down };

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    _ = allocator;

    raylib.InitWindow(window_width, window_height, "Pooper Snake");
    defer raylib.CloseWindow();

    raylib.SetTargetFPS(60);

    const can_pooper_image = raylib.LoadImageFromMemory(".png", assets.canpooper_png, assets.canpooper_png.len);
    const can_pooper_texture = raylib.LoadTextureFromImage(can_pooper_image);
    raylib.UnloadImage(can_pooper_image);

    const burger_image = raylib.LoadImageFromMemory(".png", assets.burger_png, assets.burger_png.len);
    const burger_texture = raylib.LoadTextureFromImage(burger_image);
    raylib.UnloadImage(burger_image);

    const crate_image = raylib.LoadImageFromMemory(".png", assets.crate_png, assets.crate_png.len);
    const crate_texture = raylib.LoadTextureFromImage(crate_image);
    raylib.UnloadImage(crate_image);

    const crate_background = raylib.LoadRenderTexture(window_width, window_height);
    {
        raylib.BeginTextureMode(crate_background);
        var i: u32 = 0;
        while (i < window_width) : (i += 1) {
            var j: u32 = 0;
            while (j < window_height) : (j += 1) {
                raylib.DrawTexture(crate_texture, @intCast(i * unit_size), @intCast(j * unit_size), raylib.WHITE);
            }
        }
        raylib.EndTextureMode();
    }

    raylib.UnloadTexture(crate_texture);

    var delta_time: f64 = 0;

    while (!raylib.WindowShouldClose()) {
        const start_time = raylib.GetTime();

        raylib.BeginDrawing();

        raylib.DrawTexture(crate_background.texture, 0, 0, raylib.WHITE);

        raylib.DrawTexture(can_pooper_texture, 100, 100, raylib.WHITE);
        raylib.DrawTexture(burger_texture, 400, 200, raylib.WHITE);

        raylib.EndDrawing();

        const end_time = raylib.GetTime();
        delta_time = start_time - end_time;
    }
}
