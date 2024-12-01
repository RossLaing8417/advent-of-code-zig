const std = @import("std");

pub fn main() !void {
    const data = @embedFile("input.txt");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const result = try solve(gpa.allocator(), data);
    try std.io.getStdOut().writer().print("{d}\n", .{result});
}

fn solve(allocator: std.mem.Allocator, data: []const u8) !isize {
    var result: isize = 0;

    var data_itr = std.mem.split(u8, data, "\n");
    var left_nums = try std.ArrayList(i32).initCapacity(allocator, std.mem.count(u8, data, "\n") + 1);
    defer left_nums.deinit();

    var right_nums = try std.ArrayList(i32).initCapacity(allocator, left_nums.capacity);
    defer right_nums.deinit();

    while (data_itr.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        var itr = std.mem.tokenizeScalar(u8, line, ' ');
        const left = try std.fmt.parseInt(i32, itr.next().?, 10);
        const right = try std.fmt.parseInt(i32, itr.next().?, 10);

        left_nums.appendAssumeCapacity(left);
        right_nums.appendAssumeCapacity(right);
    }

    for (left_nums.items) |num| {
        result += num * @as(i32, @intCast(std.mem.count(i32, right_nums.items, &[1]i32{num})));
    }

    return result;
}

test "Example" {
    const data =
        \\3   4
        \\4   3
        \\2   5
        \\1   3
        \\3   9
        \\3   3
    ;

    const result = try solve(std.testing.allocator, data);

    try std.testing.expectEqual(@as(@TypeOf(result), 31), result);
}
