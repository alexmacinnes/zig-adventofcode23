const std = @import("std");

const InputLine = struct { isSymbol: []bool };

const NumberDef = struct { value: u64, touchesLeft: u16, touchesRight: u16 };

const NumberLine = struct { numberDefs: []NumberDef };

const SymbolIndexList = struct { symbvolIndexes: []u16 };

pub fn main() !void {
    const path = "input.txt";

    try part1(path);
    try part2(path);
}

fn part1(path: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const lineLength = try firstLineLength(path);
    const inputLines = try readAllLines(allocator, path, lineLength);
    const total = try totalNumbers(path, inputLines, lineLength);

    std.debug.print("Part 1: {d}\n", .{total});
}

fn part2(path: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const numberLines = try readAllNumberLines(allocator, path);
    const total = try totalGearValue(allocator, path, numberLines);

    std.debug.print("Part 2: {d}\n", .{total});
}

fn totalGearValue(arena: std.mem.Allocator, path: []const u8, numberLines: []const NumberLine) !u64 {
    var grandTotal: u64 = 0;

    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [8192]u8 = undefined;

    var i: u32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        grandTotal += try totalGearValueFromLine(arena, i, line, numberLines);
        i += 1;
    }

    return grandTotal;
}

fn totalGearValueFromLine(arena: std.mem.Allocator, lineIndex: u32, line: []const u8, numberLines: []const NumberLine) !u64 {
    var lineTotal: u64 = 0;

    for (0.., line) |colIdx, ch| {
        if (isSymbol(ch)) {
            var connectedValues = std.ArrayList(u64).init(arena);

            const lowerLineIndex: u32 = switch (lineIndex) {
                0 => 0,
                else => lineIndex - 1,
            };

            var upperLineIndex: u32 = lineIndex + 1;
            if (upperLineIndex == numberLines.len) {
                upperLineIndex -= 1;
            }

            for (lowerLineIndex..upperLineIndex + 1) |rowIdx| {
                for (numberLines[rowIdx].numberDefs) |numDef| {
                    if (numDef.touchesLeft > colIdx) {
                        // they are stored in order left to right, all remaining items are too far to the right on the line
                        break;
                    }
                    if (numDef.touchesLeft <= colIdx and numDef.touchesRight >= colIdx) {
                        try connectedValues.append(numDef.value);
                    }
                }
            }

            const vals = connectedValues.items;
            if (vals.len == 2) {
                lineTotal += vals[0] * vals[1];
            }
        }
    }

    return lineTotal;
}

fn readAllNumberLines(arena: std.mem.Allocator, path: []const u8) ![]const NumberLine {
    var lines = std.ArrayList(NumberLine).init(arena);

    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [8192]u8 = undefined;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const nextLine = try readNumberLine(arena, line);
        try lines.append(nextLine);
    }

    return lines.items;
}

fn readNumberLine(arena: std.mem.Allocator, line: []const u8) !NumberLine {
    var nums = std.ArrayList(NumberDef).init(arena);

    var i: u16 = 0;
    while (i < line.len) {
        if (isDigit(line[i])) {
            var right = i + 1; // the index immediately to the right of the digit
            while (right < line.len and isDigit(line[right])) {
                right += 1;
            }

            const text = line[i..right];
            const val = try std.fmt.parseInt(u64, text, 10);
            const left: u16 = switch (i) {
                0 => 0,
                else => i - 1,
            };

            const numDef = NumberDef{ .value = val, .touchesLeft = left, .touchesRight = right };
            try nums.append(numDef);

            i = right + 1; // we know line[right] is not a digit
        } else {
            i += 1;
        }
    }

    const result = NumberLine{ .numberDefs = nums.items };
    return result;
}

fn totalNumbers(path: []const u8, lines: []const InputLine, lineLength: u16) !u64 {
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

inline fn nextToSymbol(rowIdx: u16, colIdx: u16, colAfterIdx: u16, lines: []const InputLine) bool {

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
