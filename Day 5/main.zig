const std = @import("std");
const sort = std.sort;

const MapRange = struct {
    sourceBase: u64,
    sourceMax: u64,
    destinationBase: u64,
};

const BUF_SIZE = 8192;

const ParseError = error{UnexpectedHeader};

const MapRangeList = struct {
    mapRanges: []MapRange,

    pub fn map(self: *const MapRangeList, source: u64) u64 {
        for (self.mapRanges) |m| {
            if (m.sourceBase > source) {
                break;
            } else if (m.sourceMax >= source) {
                return m.destinationBase + source - m.sourceBase;
            }
        }

        return source;
    }
};

const LocationMapper = struct {
    seeds: []u64,
    seedToSoil: MapRangeList,
    soilToFertilizer: MapRangeList,
    fertilizerToWater: MapRangeList,
    waterToLight: MapRangeList,
    lightToTemperature: MapRangeList,
    temperatureToHumidity: MapRangeList,
    humidityToLocation: MapRangeList,

    pub fn mapSeedToLocation(self: *const LocationMapper, seed: u64) u64 {
        const soil = self.seedToSoil.map(seed);
        const fertilizer = self.soilToFertilizer.map(soil);
        const water = self.fertilizerToWater.map(fertilizer);
        const light = self.waterToLight.map(water);
        const temperature = self.lightToTemperature.map(light);
        const humidity = self.temperatureToHumidity.map(temperature);
        const location = self.humidityToLocation.map(humidity);

        return location;
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const locationMapper = try initLocationMapper(allocator, "input.txt");
    const lowestLocation = findLowestLocation(locationMapper);

    std.debug.print("Part1: {d}\n", .{lowestLocation});
}

fn findLowestLocation(locationMapper: *const LocationMapper) u64 {
    var min: u64 = std.math.maxInt(u64);

    for (locationMapper.*.seeds) |x| {
        const loc = locationMapper.*.mapSeedToLocation(x);
        if (loc < min) {
            min = loc;
        }
    }

    return min;
}

fn initLocationMapper(arena: std.mem.Allocator, path: []const u8) !*const LocationMapper {
    var result = try arena.create(LocationMapper);

    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [BUF_SIZE]u8 = undefined;

    const firstLine = (try in_stream.readUntilDelimiterOrEof(&buf, '\n')).?;
    result.seeds = try initSeeds(arena, firstLine);

    _ = try in_stream.readUntilDelimiterOrEof(&buf, '\n');

    result.seedToSoil = (try initMapRangeList(arena, in_stream, &buf, "seed-to-soil map:")).*;
    result.soilToFertilizer = (try initMapRangeList(arena, in_stream, &buf, "soil-to-fertilizer map:")).*;
    result.fertilizerToWater = (try initMapRangeList(arena, in_stream, &buf, "fertilizer-to-water map:")).*;
    result.waterToLight = (try initMapRangeList(arena, in_stream, &buf, "water-to-light map:")).*;
    result.lightToTemperature = (try initMapRangeList(arena, in_stream, &buf, "light-to-temperature map:")).*;
    result.temperatureToHumidity = (try initMapRangeList(arena, in_stream, &buf, "temperature-to-humidity map:")).*;
    result.humidityToLocation = (try initMapRangeList(arena, in_stream, &buf, "humidity-to-location map:")).*;

    return result;
}

fn initSeeds(arena: std.mem.Allocator, line: []const u8) ![]u64 {
    const prefix = "seeds: ";
    const remainder = line[prefix.len..];

    var seeds = std.ArrayList(u64).init(arena);

    var it = std.mem.split(u8, remainder, " ");
    while (it.next()) |x| {
        try seeds.append(try std.fmt.parseInt(u64, x, 10));
    }

    const result = seeds.items;
    //std.debug.print("Seeds\n", .{});
    //std.debug.print("{any}\n\n", .{seeds.items});
    return result;
}

fn initMapRangeList(arena: std.mem.Allocator, in_stream: anytype, buf: *[BUF_SIZE]u8, expectedHeader: []const u8) !*const MapRangeList {
    var result = try arena.create(MapRangeList);
    var mapRanges = std.ArrayList(MapRange).init(arena);

    while (try in_stream.readUntilDelimiterOrEof(buf, '\n')) |line| {
        if (!std.mem.eql(u8, line, expectedHeader)) {
            return ParseError.UnexpectedHeader;
        }
        break;
    }

    while (try in_stream.readUntilDelimiterOrEof(buf, '\n')) |line| {
        if (line.len == 0) {
            break;
        }

        var it = std.mem.split(u8, line, " ");
        const dest = try std.fmt.parseInt(u64, it.next().?, 10);
        const src = try std.fmt.parseInt(u64, it.next().?, 10);
        const cnt = try std.fmt.parseInt(u64, it.next().?, 10);

        var mapRange = try arena.create(MapRange);
        mapRange.*.sourceBase = src;
        mapRange.*.sourceMax = src + cnt - 1;
        mapRange.*.destinationBase = dest;

        try mapRanges.append(mapRange.*);
    }

    result.*.mapRanges = mapRanges.items;
    sort.heap(MapRange, result.*.mapRanges, {}, compareBySourceBase);

    //std.debug.print("{s}\n", .{expectedHeader});
    //std.debug.print("{any}\n\n", .{result.*});

    return result;
}

fn compareBySourceBase(context: void, a: MapRange, b: MapRange) bool {
    return sort.asc(u64)(context, a.sourceBase, b.sourceBase);
}
