const std = @import("std");

pub fn main() !void {
    const data = @embedFile("input.txt");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var result = try solve(data, gpa.allocator());
    try std.io.getStdOut().writer().print("{d}\n", .{result});
}

const Node = struct {
    left: []const u8,
    right: []const u8,
};

fn solve(data: []const u8, child_allocator: std.mem.Allocator) !usize {
    var result: usize = 0;

    var arena = std.heap.ArenaAllocator.init(child_allocator);
    defer arena.deinit();

    var allocator = arena.allocator();

    var data_itr = std.mem.split(u8, data, "\n");

    const lr_instruction = data_itr.first();
    var lr_index: usize = 0;

    var map = std.StringHashMapUnmanaged(Node){};
    var entries = std.ArrayListUnmanaged([]const u8){};

    while (data_itr.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        var key = line[0..3];
        try map.put(allocator, key, .{
            .left = line[7..10],
            .right = line[12..15],
        });

        if (line[2] == 'A') {
            try entries.append(allocator, key);
        }
    }

    var path_lengths = try allocator.alloc(usize, entries.items.len);

    for (entries.items, 0..) |key, i| {
        var entry = map.getEntry(key).?;

        path_lengths[i] = 0;
        lr_index = 0;

        while (entry.key_ptr.*[2] != 'Z') {
            path_lengths[i] += 1;

            var next_key: []const u8 = switch (lr_instruction[lr_index]) {
                'L' => entry.value_ptr.left,
                'R' => entry.value_ptr.right,
                else => unreachable,
            };

            lr_index += 1;
            if (lr_index == lr_instruction.len) {
                lr_index = 0;
            }

            entry = map.getEntry(next_key).?;
        }
    }

    result = path_lengths[0];
    for (1..path_lengths.len) |i| {
        result = lcm(result, path_lengths[i]);
    }

    return result;
}

fn lcm(x: usize, y: usize) usize {
    return (x * y) / gcd(x, y);
}

fn gcd(x: usize, y: usize) usize {
    return if (y == 0) x else gcd(y, x % y);
}

test "Example" {
    const data =
        \\LR
        \\
        \\11A = (11B, XXX)
        \\11B = (XXX, 11Z)
        \\11Z = (11B, XXX)
        \\22A = (22B, XXX)
        \\22B = (22C, 22C)
        \\22C = (22Z, 22Z)
        \\22Z = (22B, 22B)
        \\XXX = (XXX, XXX)
    ;

    var result = try solve(data, std.testing.allocator);

    try std.testing.expectEqual(@as(@TypeOf(result), 6), result);
}
