const std = @import("std");

const InputLine = struct { isSymbol: []bool };

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const path = "input.txt";

    const lineLength = try firstLineLength(path);
    const inputLines = try readAllLines(allocator, path, lineLength);
    const total = try totalNumbers(path, inputLines, lineLength);

    std.debug.print("{d}", .{total});
}

fn totalNumbers(path: []const u8, lines: []InputLine, lineLength: u16) !u64 {
    var total: u64 = 0;

    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [8192]u8 = undefined;

    var rowIdx: u16 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var colIdx: u16 = 0;
        while (colIdx < lineLength) {
            if (isDigit(line[colIdx])) {
                var nextIdx = colIdx + 1; // the first non digit character after this point
                while (nextIdx < lineLength and isDigit(line[nextIdx])) {
                    nextIdx += 1;
                }

                if (nextToSymbol(rowIdx, colIdx, nextIdx, lines)) {
                    const text = line[colIdx..nextIdx];
                    const val = try std.fmt.parseInt(u64, text, 10);
                    total += val;

                    std.debug.print("{s}: YES\n", .{line[colIdx..nextIdx]});
                } else {
                    std.debug.print("{s}: NO\n", .{line[colIdx..nextIdx]});
                }

                colIdx = nextIdx;
                continue;
            }
            colIdx += 1;
        }

        rowIdx += 1;
    }

    return total;
}

inline fn nextToSymbol(rowIdx: u16, colIdx: u16, colAfterIdx: u16, lines: []InputLine) bool {

    // lines has been padded with empty row/column in all directions, so indexes must be offset by 1
    const row = lines[rowIdx + 1];
    const rowAbove = lines[rowIdx];
    const rowBelow = lines[rowIdx + 2];

    const leftIdx = colIdx; // the index to the left of the number start
    const rightIdx = colAfterIdx + 1; // the index to the right of the number end

    if (row.isSymbol[leftIdx] or row.isSymbol[rightIdx]) {
        return true;
    }

    for (leftIdx..rightIdx + 1) |i| {
        // left to right inclusive
        if (rowAbove.isSymbol[i] or rowBelow.isSymbol[i]) {
            return true;
        }
    }

    return false;
}

fn firstLineLength(path: []const u8) !u16 {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [8192]u8 = undefined;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const length: u16 = @intCast(line.len);
        return length;
    }

    unreachable;
}

fn readAllLines(arena: std.mem.Allocator, path: []const u8, lineLength: u16) ![]InputLine {
    const paddingLine = try initBlankLine(arena, lineLength);

    var lines = std.ArrayList(InputLine).init(arena);
    try lines.append(paddingLine); //blank line at start

    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [8192]u8 = undefined;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const inputLine = try initInputLine(arena, line);
        try lines.append(inputLine);
    }

    try lines.append(paddingLine); //blank line at end

    return lines.items;
}

inline fn initBlankLine(arena: std.mem.Allocator, lineLength: u16) !InputLine {
    var blanks = std.ArrayList(bool).init(arena);

    var i: u16 = 0;
    const count = lineLength + 2; // padded with false at either end
    while (i < count) {
        try blanks.append(false);
        i += 1;
    }

    const result = InputLine{ .isSymbol = blanks.items };
    return result;
}

inline fn initInputLine(arena: std.mem.Allocator, line: []u8) !InputLine {
    var list = std.ArrayList(bool).init(arena);
    try list.append(false); // padded with false at start

    for (line) |ch| {
        try list.append(isSymbol(ch));
    }

    try list.append(false);

    const result = InputLine{ .isSymbol = list.items };
    return result;
}

inline fn isDigit(ch: u8) bool {
    return ch >= '0' and ch <= '9';
}

inline fn isSymbol(ch: u8) bool {
    return !(isDigit(ch) or ch == '.');
}
