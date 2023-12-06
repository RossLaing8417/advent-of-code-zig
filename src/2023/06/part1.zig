const std = @import("std");

pub fn main() !void {
    const data = @embedFile("input.txt");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var result = try solve(data, gpa.allocator());
    try std.io.getStdOut().writer().print("{d}\n", .{result});
}

fn solve(data: []const u8, _: std.mem.Allocator) !usize {
    var result: usize = 1;

    var data_itr = std.mem.split(u8, data, "\n");

    var time_line = data_itr.first();
    var dist_line = data_itr.next().?;

    var time_colon = std.mem.indexOf(u8, time_line, ":").?;
    var dist_colon = std.mem.indexOf(u8, dist_line, ":").?;

    var time_itr = std.mem.splitSequence(u8, time_line[time_colon + 1 ..], " ");
    var dist_itr = std.mem.splitSequence(u8, dist_line[dist_colon + 1 ..], " ");

    while (time_itr.next()) |time_str| {
        if (time_str.len == 0) {
            continue;
        }

        var time = try std.fmt.parseUnsigned(usize, time_str, 10);
        var dist: usize = 0;

        while (dist_itr.next()) |dist_str| {
            if (dist_str.len == 0) {
                continue;
            }

            dist = try std.fmt.parseUnsigned(usize, dist_str, 10);
            break;
        }

        var count: usize = 0;

        for (1..time) |t| {
            var d = (time - t) * t;
            if (d > dist) {
                count += 1;
            }
        }

        result *= count;
    }

    return result;
}

test "Example" {
    const data =
        \\Time:      7  15   30
        \\Distance:  9  40  200
    ;

    var result = try solve(data, std.testing.allocator);

    try std.testing.expectEqual(@as(@TypeOf(result), 288), result);
}
