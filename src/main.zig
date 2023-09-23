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

// Measured in pixel.
const window_width = 1400;
const window_height = 1000;

const initial_head_x = 4;
const initial_head_y = 5;

// Measured in pixels.
const unit_size = 100;

// Measured in frames.
const frames_per_second = 60;
const movement_delay = frames_per_second / 2;

const Direction = enum { left, right, up, down };

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    _ = allocator;

    raylib.InitWindow(window_width, window_height, "Pooper Snake");
    defer raylib.CloseWindow();

    raylib.SetTargetFPS(frames_per_second);

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

    var player_x: u32 = initial_head_x;
    var player_y: u32 = initial_head_y;

    var movement_countdown: i16 = movement_delay;

    while (!raylib.WindowShouldClose()) {
        if (movement_countdown <= 0) {
            movement_countdown = movement_delay;
            player_y += 1;
        }

        raylib.BeginDrawing();

        raylib.DrawTexture(crate_background.texture, 0, 0, raylib.WHITE);

        raylib.DrawTexture(can_pooper_texture, @intCast(player_x * unit_size), @intCast(player_y * unit_size), raylib.WHITE);
        raylib.DrawTexture(burger_texture, 400, 200, raylib.WHITE);

        raylib.EndDrawing();

        movement_countdown -= 1;
    }
}
