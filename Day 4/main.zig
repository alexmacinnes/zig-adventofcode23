const std = @import("std");
const sort = std.sort;

const ScratchCard = struct { lineNo: u16, winningNumbers: []const u8, actualNumbers: []const u8, matches: u8 = 0, part1Value: u64 = 0, part2Value: u64 = 0 };

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var scratchCards = try readAllScratchCards(allocator, "input.txt");
    assignPoints(scratchCards);
    const totals = totalPoints(scratchCards);

    std.debug.print("Part 1: {d}\n", .{totals.part1});
    std.debug.print("Part 2: {d}\n", .{totals.part2});
}

fn totalPoints(scratchCards: []*const ScratchCard) struct { part1: u64, part2: u64 } {
    var totalPart1: u64 = 0;
    var totalPart2: u64 = 0;

    for (scratchCards) |s| {
        totalPart1 += s.*.part1Value;
        totalPart2 += s.*.part2Value;
    }

    return .{ .part1 = totalPart1, .part2 = totalPart2 };
}

fn assignPoints(scratchCards: []*ScratchCard) void {
    var i = scratchCards.len;
    while (i > 0) {
        i -= 1;

        var s = scratchCards[i];
        s.*.matches = countMatches(s);

        s.*.part1Value = part1Points(s.*.matches);

        s.*.part2Value = 1;
        for (1..s.*.matches + 1) |offset| {
            s.part2Value += scratchCards[i + offset].*.part2Value;
        }
    }
}

fn readAllScratchCards(arena: std.mem.Allocator, path: []const u8) ![]*ScratchCard {
    var result = std.ArrayList(*ScratchCard).init(arena);

    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [8192]u8 = undefined;

    var lineNumber: u16 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const scratchCard = try parseScratchCard(arena, lineNumber, line);
        try result.append(scratchCard);

        lineNumber += 1;
    }

    return result.items;
}

fn cmpByValue(context: void, a: u8, b: u8) bool {
    return sort.asc(u8)(context, a, b);
}

fn countMatches(scratchCard: *const ScratchCard) u8 {
    var aIdx: u8 = 0;
    var wIdx: u8 = 0;

    var matches: u8 = 0;

    while (aIdx < scratchCard.actualNumbers.len and wIdx < scratchCard.winningNumbers.len) {
        var a = scratchCard.actualNumbers[aIdx];
        var w = scratchCard.winningNumbers[wIdx];

        if (a == w) {
            matches += 1;
            aIdx += 1;
            wIdx += 1;
        } else if (a < w) {
            aIdx += 1;
        } else {
            wIdx += 1;
        }
    }

    return matches;
}

fn part1Points(matches: u8) u32 {
    if (matches == 0) {
        return 0;
    }
    return std.math.shl(u32, 1, matches - 1);
}

fn parseScratchCard(arena: std.mem.Allocator, lineNumber: u16, line: []const u8) !*ScratchCard {
    const colon = ": ";
    const colonIdx = std.mem.indexOf(u8, line, colon).?;
    const remainder = line[colonIdx + colon.len ..];

    const sep = " | ";
    const sepIndex = std.mem.indexOf(u8, remainder, sep).?;

    const left = remainder[0..sepIndex];
    const right = remainder[sepIndex + sep.len ..];

    const winning = try parse2DigitNumbers(arena, left);
    const actual = try parse2DigitNumbers(arena, right);

    sort.heap(u8, winning, {}, cmpByValue);
    sort.heap(u8, actual, {}, cmpByValue);

    var result = try arena.create(ScratchCard);
    result.*.lineNo = lineNumber;
    result.*.winningNumbers = winning;
    result.*.actualNumbers = actual;

    return result;
}

fn parse2DigitNumbers(arena: std.mem.Allocator, text: []const u8) ![]u8 {
    var result = std.ArrayList(u8).init(arena);

    var i: u8 = 0;
    while (i < text.len) {
        var nextVal: u8 = undefined;
        if (text[i] == ' ') {
            nextVal = digit(text[i + 1]);
        } else {
            nextVal = (digit(text[i]) * 10) + digit(text[i + 1]);
        }

        try result.append(nextVal);
        i += 3;
    }

    return result.items;
}

inline fn digit(ch: u8) u8 {
    return ch - '0';
}
