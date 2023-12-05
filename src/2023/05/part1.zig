const std = @import("std");

pub fn main() !void {
    const data = @embedFile("input.txt");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var result = try solve(data, gpa.allocator());
    try std.io.getStdOut().writer().print("{d}\n", .{result});
}

const Range = struct {
    destination_start: usize,
    source_start: usize,
    length: usize,
};

const RangeList = std.ArrayListUnmanaged(Range);

const Mapping = struct {
    @"seed-to-soil": RangeList = RangeList{},
    @"soil-to-fertilizer": RangeList = RangeList{},
    @"fertilizer-to-water": RangeList = RangeList{},
    @"water-to-light": RangeList = RangeList{},
    @"light-to-temperature": RangeList = RangeList{},
    @"temperature-to-humidity": RangeList = RangeList{},
    @"humidity-to-location": RangeList = RangeList{},
};

fn solve(data: []const u8, alloc: std.mem.Allocator) !usize {
    var result: usize = std.math.maxInt(usize);

    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    var allocator = arena.allocator();

    var data_itr = std.mem.split(u8, data, "\n");

    var seeds: []usize = undefined;
    var mapping_field: []const u8 = undefined;

    var mapping = Mapping{};
    comptime var mapping_fields: []const std.builtin.Type.StructField = std.meta.fields(Mapping);

    while (data_itr.next()) |line| {
        if (line.len == 0) {
            mapping_field = "";
            continue;
        }

        if (std.mem.startsWith(u8, line, "seeds:")) {
            var seed_list_itr = std.mem.splitBackwardsSequence(u8, line, ":");
            var seed_list = seed_list_itr.first();
            var seed_itr = std.mem.splitSequence(u8, seed_list, " ");
            seeds = try allocator.alloc(usize, std.mem.count(u8, seed_list, " "));

            var i: usize = 0;
            while (seed_itr.next()) |seed_str| {
                if (seed_str.len != 0) {
                    seeds[i] = try std.fmt.parseUnsigned(usize, seed_str, 10);
                    i += 1;
                }
            }

            continue;
        }

        if (std.ascii.isAlphabetic(line[0])) {
            var field_itr = std.mem.splitSequence(u8, line, " ");
            mapping_field = field_itr.first();
            continue;
        }

        var mapping_itr = std.mem.splitSequence(u8, line, " ");

        // Tried something different...
        inline for (mapping_fields) |field| {
            if (std.mem.eql(u8, field.name, mapping_field)) {
                try @field(mapping, field.name).append(allocator, Range{
                    .destination_start = try std.fmt.parseUnsigned(usize, mapping_itr.first(), 10),
                    .source_start = try std.fmt.parseUnsigned(usize, mapping_itr.next().?, 10),
                    .length = try std.fmt.parseUnsigned(usize, mapping_itr.next().?, 10),
                });
            }
        }
    }

    for (seeds) |seed| {
        var source = seed;
        var destination = seed;

        inline for (mapping_fields) |field| {
            const ranges: []Range = @field(mapping, field.name).items;

            range: for (ranges) |range| {
                source = destination;

                var start = range.source_start;
                var end = range.source_start + range.length;

                if (source >= start and source < end) {
                    destination = range.destination_start + source - start;
                    break :range;
                }
            }
        }

        if (destination < result) {
            result = destination;
        }
    }

    return result;
}

test "Example" {
    const data =
        \\seeds: 79 14 55 13
        \\
        \\seed-to-soil map:
        \\50 98 2
        \\52 50 48
        \\
        \\soil-to-fertilizer map:
        \\0 15 37
        \\37 52 2
        \\39 0 15
        \\
        \\fertilizer-to-water map:
        \\49 53 8
        \\0 11 42
        \\42 0 7
        \\57 7 4
        \\
        \\water-to-light map:
        \\88 18 7
        \\18 25 70
        \\
        \\light-to-temperature map:
        \\45 77 23
        \\81 45 19
        \\68 64 13
        \\
        \\temperature-to-humidity map:
        \\0 69 1
        \\1 0 69
        \\
        \\humidity-to-location map:
        \\60 56 37
        \\56 93 4
    ;

    var result = try solve(data, std.testing.allocator);

    try std.testing.expectEqual(@as(@TypeOf(result), 35), result);
}
