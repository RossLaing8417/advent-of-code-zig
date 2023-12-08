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

    while (data_itr.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        try map.put(allocator, line[0..3], .{
            .left = line[7..10],
            .right = line[12..15],
        });
    }

    var current_entry = map.getEntry("AAA").?;
    while (!std.mem.eql(u8, current_entry.key_ptr.*, "ZZZ")) {
        result += 1;

        var next_key: []const u8 = switch (lr_instruction[lr_index]) {
            'L' => current_entry.value_ptr.left,
            'R' => current_entry.value_ptr.right,
            else => unreachable,
        };

        current_entry = map.getEntry(next_key).?;

        lr_index += 1;
        if (lr_index == lr_instruction.len) {
            lr_index = 0;
        }
    }

    return result;
}

test "Example 1" {
    const data =
        \\RL
        \\
        \\AAA = (BBB, CCC)
        \\BBB = (DDD, EEE)
        \\CCC = (ZZZ, GGG)
        \\DDD = (DDD, DDD)
        \\EEE = (EEE, EEE)
        \\GGG = (GGG, GGG)
        \\ZZZ = (ZZZ, ZZZ)
    ;

    var result = try solve(data, std.testing.allocator);

    try std.testing.expectEqual(@as(@TypeOf(result), 2), result);
}

test "Example 2" {
    const data =
        \\LLR
        \\
        \\AAA = (BBB, BBB)
        \\BBB = (AAA, ZZZ)
        \\ZZZ = (ZZZ, ZZZ)
    ;

    var result = try solve(data, std.testing.allocator);

    try std.testing.expectEqual(@as(@TypeOf(result), 6), result);
}
