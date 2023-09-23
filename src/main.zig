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

const PlayerPartList = std.DoublyLinkedList(PlayerPart);

// Measured in pixel.
const window_width = 1400;
const window_height = 1000;

// Measured in units.
const initial_head_x = 4;
const initial_head_y = 5;
const game_width = window_width / unit_size;
const game_height = window_height / unit_size;

// Measured in pixels.
const unit_size = 100;

// Measured in frames.
const frames_per_second = 60;
const movement_delay = frames_per_second / 3;

const Direction = enum { left, right, up, down };

fn create_node(comptime T: type, allocator: std.mem.Allocator, data: T) !*std.DoublyLinkedList(T).Node {
    const node = try allocator.create(std.DoublyLinkedList(T).Node);
    node.*.prev = null;
    node.*.next = null;
    node.*.data = data;
    return node;
}

fn random_burger_position(random_generator: std.rand.Random, player_parts: PlayerPartList) struct { x: u16, y: u16 } {
    while (true) {
        var x: u16 = random_generator.int(u16) % game_width;
        var y: u16 = random_generator.int(u16) % game_height;

        var valid_position = true;

        var optional_node = player_parts.first;
        while (optional_node) |node| {
            if (node.*.data.unit_x == x and node.*.data.unit_y == y) {
                valid_position = false;
            }

            optional_node = node.next;
        }

        if (valid_position) {
            return .{ .x = x, .y = y };
        }
    }
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

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

    var random_generator = std.rand.DefaultPrng.init(@intCast(std.time.timestamp()));

    var player_direction: Direction = Direction.right;

    var player_tail = PlayerPartList{};
    player_tail.append(try create_node(PlayerPart, allocator, PlayerPart{ .unit_x = player_x - 1, .unit_y = player_y }));
    player_tail.append(try create_node(PlayerPart, allocator, PlayerPart{ .unit_x = player_x - 2, .unit_y = player_y }));

    var burger_pos = random_burger_position(random_generator.random(), player_tail);

    // Destroy everything in the linked list.
    defer {
        var node = player_tail.first;
        while (node) |inner_node| {
            node = inner_node.next;
            allocator.destroy(inner_node);
        }
    }

    var movement_countdown: i16 = movement_delay;

    while (!raylib.WindowShouldClose()) {
        const player_at_burger: bool = player_x == burger_pos.x and player_y == burger_pos.y;

        if (raylib.IsKeyPressed(raylib.KEY_UP)) {
            player_direction = Direction.up;
        }
        if (raylib.IsKeyPressed(raylib.KEY_DOWN)) {
            player_direction = Direction.down;
        }
        if (raylib.IsKeyPressed(raylib.KEY_RIGHT)) {
            player_direction = Direction.right;
        }
        if (raylib.IsKeyPressed(raylib.KEY_LEFT)) {
            player_direction = Direction.left;
        }

        if (movement_countdown <= 0) {
            movement_countdown = movement_delay;
            player_tail.append(try create_node(PlayerPart, allocator, PlayerPart{ .unit_x = player_x, .unit_y = player_y }));

            switch (player_direction) {
                Direction.up => player_y -= 1,
                Direction.down => player_y += 1,
                Direction.right => player_x += 1,
                Direction.left => player_x -= 1,
            }

            // Grow the tail, if we are at a burger.
            if (!player_at_burger) {
                const to_be_removed = player_tail.popFirst();
                if (to_be_removed) |to_be_removed_real| {
                    allocator.destroy(to_be_removed_real);
                }
            } else {
                burger_pos = random_burger_position(random_generator.random(), player_tail);
            }
        }

        raylib.BeginDrawing();

        raylib.DrawTexture(crate_background.texture, 0, 0, raylib.WHITE);
        raylib.DrawTexture(burger_texture, @intCast(burger_pos.x * unit_size), @intCast(burger_pos.y * unit_size), raylib.WHITE);

        {
            var node = player_tail.first;
            while (node) |inner_node| {
                raylib.DrawTexture(can_pooper_texture, @intCast(inner_node.*.data.unit_x * unit_size), @intCast(inner_node.*.data.unit_y * unit_size), raylib.BLUE);
                node = inner_node.next;
            }
        }

        raylib.DrawTexture(can_pooper_texture, @intCast(player_x * unit_size), @intCast(player_y * unit_size), raylib.WHITE);

        raylib.EndDrawing();

        movement_countdown -= 1;
    }
}
