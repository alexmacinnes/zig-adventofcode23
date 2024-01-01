const std = @import("std");

const CubeSet = struct { red: u32 = 0, green: u32 = 0, blue: u32 = 0 };

const Game = struct { id: u32, cubeSets: []const CubeSet };

const NODIGIT = 255;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var total: u32 = 0;

    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [8192]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const game = try readGame(allocator, line);
        if (gamePasses(&game)) {
            std.debug.print("Game {d}\n", .{game.id});
            total += game.id;
        }
    }

    std.debug.print("Total {d}\n", .{total});
    return;
}

fn readGame(arena: std.mem.Allocator, line: []u8) !Game {
    const colon = std.mem.indexOf(u8, line, ":").?;
    const gameId = line[5..colon];
    const gameIdInt = try std.fmt.parseInt(u32, gameId, 10);

    var cubeSets = std.ArrayList(CubeSet).init(arena);

    const remainder = line[colon + 1 ..];
    var rgbItr = std.mem.split(u8, remainder, ";");
    while (rgbItr.next()) |rgb| {
        //e.g. " 11 red, 2 blue, 6 green"
        var cubeSet = CubeSet{};
        var commaItr = std.mem.split(u8, rgb, ",");
        while (commaItr.next()) |x| {
            //e.g. " 11 red"
            const trim = x[1..];
            const space = std.mem.indexOf(u8, trim, " ").?;
            const qty = trim[0..space];
            const qtyInt = try std.fmt.parseInt(u32, qty, 10);
            const colourCode = trim[space + 1];

            switch (colourCode) {
                'r' => cubeSet.red = qtyInt,
                'g' => cubeSet.green = qtyInt,
                'b' => cubeSet.blue = qtyInt,
                else => unreachable,
            }
        }
        try cubeSets.append(cubeSet);
    }

    const game = Game{ .id = gameIdInt, .cubeSets = cubeSets.items };
    return game;
}

fn gamePasses(game: *const Game) bool {
    for (game.*.cubeSets) |c| {
        if (c.red > 12 or c.green > 13 or c.blue > 14) {
            return false;
        }
    }
    return true;
}
