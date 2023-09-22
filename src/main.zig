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
    next_direction: Direction,
    offset: f32,
    unit_x: f32,
    unit_y: f32,
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

    var player_parts = std.ArrayList(PlayerPart).init(allocator);
    try player_parts.append(.{
        .unit_x = 0.0,
        .unit_y = 0.0,
        .offset = 0.0,
        .position = .{ .x = 0.0, .y = 0.0 },
        .direction = Direction.down,
        .next_direction = Direction.down,
    });
    try player_parts.append(.{
        .unit_x = 0.0,
        .unit_y = 1.0,
        .offset = 1.0 / @as(f32, player_speed),
        .position = .{ .x = 0.0, .y = 0.0 },
        .direction = Direction.down,
        .next_direction = Direction.down,
    });

    var rotations = std.ArrayList(Rotation).init(allocator);

    const player_head = &player_parts.items[0];

    while (!raylib.WindowShouldClose()) {
        const start_time = raylib.GetTime();

        if (raylib.IsKeyPressed(raylib.KEY_UP)) {
            player_head.*.next_direction = Direction.up;
            try rotations.append(.{ .new_direction = player_head.*.next_direction, .timestamp = raylib.GetTime() });
        }
        if (raylib.IsKeyPressed(raylib.KEY_DOWN)) {
            player_head.*.next_direction = Direction.down;
            try rotations.append(.{ .new_direction = player_head.*.next_direction, .timestamp = raylib.GetTime() });
        }
        if (raylib.IsKeyPressed(raylib.KEY_RIGHT)) {
            player_head.*.next_direction = Direction.right;
            try rotations.append(.{ .new_direction = player_head.*.next_direction, .timestamp = raylib.GetTime() });
        }
        if (raylib.IsKeyPressed(raylib.KEY_LEFT)) {
            player_head.*.next_direction = Direction.left;
            try rotations.append(.{ .new_direction = player_head.*.next_direction, .timestamp = raylib.GetTime() });
        }

        const threshold = 0.1;

        for (player_parts.items) |*player_part| {
            if (rotations.items.len >= 1) {
                var i: i32 = @intCast(rotations.items.len - 1);
                while (i >= 0) : (i -= 1) {
                    if (rotations.items[@intCast(i)].timestamp + player_part.offset < raylib.GetTime()) {
                        player_part.next_direction = rotations.items[@intCast(i)].new_direction;
                        break;
                    }
                }
            }

            if (player_part.next_direction != player_part.direction) {
                if (player_part.next_direction == Direction.up or player_part.next_direction == Direction.down) {
                    if (1.0 - (player_part.unit_x - std.math.floor(player_head.unit_x)) < threshold) {
                        player_part.direction = player_part.next_direction;
                        player_part.position.x = std.math.round(player_head.unit_x) * unit_size;
                    }
                } else if (player_part.next_direction == Direction.left or player_part.next_direction == Direction.right) {
                    if (1.0 - (player_part.unit_y - std.math.floor(player_head.unit_y)) < threshold) {
                        player_part.direction = player_part.next_direction;
                        player_part.position.y = std.math.round(player_head.unit_y) * unit_size;
                    }
                }
            }

            switch (player_part.direction) {
                Direction.left => {
                    player_part.position.x -= @floatCast(player_speed * unit_size * delta_time);
                    player_part.unit_x -= @floatCast(player_speed * delta_time);
                },
                Direction.right => {
                    player_part.position.x += @floatCast(player_speed * unit_size * delta_time);
                    player_part.unit_x += @floatCast(player_speed * delta_time);
                },
                Direction.up => {
                    player_part.position.y -= @floatCast(player_speed * unit_size * delta_time);
                    player_part.unit_y -= @floatCast(player_speed * delta_time);
                },
                Direction.down => {
                    player_part.position.y += @floatCast(player_speed * unit_size * delta_time);
                    player_part.unit_y += @floatCast(player_speed * delta_time);
                },
            }
        }

        raylib.BeginDrawing();

        raylib.ClearBackground(raylib.BLACK);

        // Tile the background.
        raylib.DrawTexture(crate_background.texture, 0, 0, raylib.WHITE);

        for (player_parts.items) |part| {
            raylib.DrawTextureV(can_pooper_texture, part.position, raylib.WHITE);
        }

        raylib.DrawTexture(burger_texture, 100, 100, raylib.WHITE);

        raylib.EndDrawing();

        const end_time = raylib.GetTime();
        delta_time = end_time - start_time;
    }
}
