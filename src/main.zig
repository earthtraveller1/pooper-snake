const std = @import("std");
const raylib = @cImport(@cInclude("raylib.h"));

const assets = struct {
    const canpooper_png = @embedFile("assets/canpooper.png");
    const burger_png = @embedFile("assets/burger.png");
    const crate_png = @embedFile("assets/crate.png");
};

const PlayerPart = struct {
    position: raylib.Vector2,
    direction: Direction,
    offset: f32,
    unit_x: f32,
    unit_y: f32,
};

// Measured in pixel.
const window_width = 800;
const window_height = 600;

// Measured in pixels.
const unit_size = 50;

// Measured in units per second.
const player_speed = 6;

const Direction = enum { left, right, up, down };

pub fn main() !void {
    raylib.InitWindow(window_width, window_height, "Pooper Snake");
    defer raylib.CloseWindow();

    raylib.SetTargetFPS(60);

    const can_pooper_image = raylib.LoadImageFromMemory(".png", assets.canpooper_png, assets.canpooper_png.len);
    const can_pooper_texture = raylib.LoadTextureFromImage(can_pooper_image);

    const burger_image = raylib.LoadImageFromMemory(".png", assets.burger_png, assets.burger_png.len);
    const burger_texture = raylib.LoadTextureFromImage(burger_image);

    const crate_image = raylib.LoadImageFromMemory(".png", assets.crate_png, assets.crate_png.len);
    const crate_texture = raylib.LoadTextureFromImage(crate_image);

    const crate_background = raylib.LoadRenderTexture(window_width, window_height);
    {
        raylib.BeginTextureMode(crate_background);
        var i: u32 = 0;
        while (i < window_width) : (i += 1) {
            var j: u32 = 0;
            while (j < window_height) : (j += 1) {
                raylib.DrawTexture(crate_texture, @intCast(i * 50), @intCast(j * 50), raylib.WHITE);
            }
        }
        raylib.EndTextureMode();
    }

    var delta_time: f64 = 0;
    var player_head: PlayerPart = .{
        .unit_x = 0.0,
        .unit_y = 0.0,
        .offset = 0.0,
        .position = .{ .x = 0.0, .y = 0.0 },
        .direction = Direction.down,
    };

    var next_direction: Direction = Direction.down;

    while (!raylib.WindowShouldClose()) {
        const start_time = raylib.GetTime();

        if (raylib.IsKeyPressed(raylib.KEY_UP)) {
            next_direction = Direction.up;
        }
        if (raylib.IsKeyPressed(raylib.KEY_DOWN)) {
            next_direction = Direction.down;
        }
        if (raylib.IsKeyPressed(raylib.KEY_RIGHT)) {
            next_direction = Direction.right;
        }
        if (raylib.IsKeyPressed(raylib.KEY_LEFT)) {
            next_direction = Direction.left;
        }

        const threshold = 0.1;

        if (next_direction != player_head.direction) {
            if (next_direction == Direction.up or next_direction == Direction.down) {
                if (1.0 - (player_head.unit_x - std.math.floor(player_head.unit_x)) < threshold) {
                    player_head.direction = next_direction;
                    player_head.position.x = std.math.round(player_head.unit_x) * unit_size;
                }
            } else if (next_direction == Direction.left or next_direction == Direction.right) {
                if (1.0 - (player_head.unit_y - std.math.floor(player_head.unit_y)) < threshold) {
                    player_head.direction = next_direction;
                    player_head.position.y = std.math.round(player_head.unit_y) * unit_size;
                }
            }
        }

        switch (player_head.direction) {
            Direction.left => {
                player_head.position.x -= @floatCast(player_speed * unit_size * delta_time);
                player_head.unit_x -= @floatCast(player_speed * delta_time);
            },
            Direction.right => {
                player_head.position.x += @floatCast(player_speed * unit_size * delta_time);
                player_head.unit_x += @floatCast(player_speed * delta_time);
            },
            Direction.up => {
                player_head.position.y -= @floatCast(player_speed * unit_size * delta_time);
                player_head.unit_y -= @floatCast(player_speed * delta_time);
            },
            Direction.down => {
                player_head.position.y += @floatCast(player_speed * unit_size * delta_time);
                player_head.unit_y += @floatCast(player_speed * delta_time);
            },
        }

        raylib.BeginDrawing();

        raylib.ClearBackground(raylib.BLACK);

        // Tile the background.
        raylib.DrawTexture(crate_background.texture, 0, 0, raylib.WHITE);

        raylib.DrawTextureV(can_pooper_texture, player_head.position, raylib.WHITE);
        raylib.DrawTexture(burger_texture, 100, 100, raylib.WHITE);

        raylib.EndDrawing();

        const end_time = raylib.GetTime();
        delta_time = end_time - start_time;
    }
}
