const std = @import("std");

pub fn main() !void {
    const data = @embedFile("input.txt");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var result = try solve(data, gpa.allocator());
    try std.io.getStdOut().writer().print("{d}\n", .{result});
}

const Galaxy = struct {
    row: i64 = 0,
    col: i64 = 0,
};

fn solve(data: []const u8, child_allocator: std.mem.Allocator) !usize {
    var result: usize = 0;

    var line_length = std.mem.indexOf(u8, data, "\n").?;

    var arena = std.heap.ArenaAllocator.init(child_allocator);
    defer arena.deinit();

    var allocator = arena.allocator();

    var galaxies = try std.ArrayListUnmanaged(Galaxy).initCapacity(allocator, std.mem.count(u8, data, "#"));

    var empty_rows = std.ArrayListUnmanaged(i64){};
    var empty_cols = std.ArrayListUnmanaged(i64){};

    var data_itr = std.mem.splitSequence(u8, data, "\n");

    var row: i64 = 0;
    var index: usize = 0;
    while (data_itr.next()) |line| : (row += 1) {
        var empty_row = true;
        for (line, 0..) |char, col| {
            if (char == '#') {
                try galaxies.append(allocator, .{ .row = row, .col = @intCast(col) });
                index += 1;
                empty_row = false;
            }
            if (row == 0) {
                var col_index = col;
                var empty_col = true;
                while (col_index < data.len) : (col_index += line_length + 1) {
                    if (data[col_index] == '#') {
                        empty_col = false;
                        break;
                    }
                }
                if (empty_col) {
                    try empty_cols.append(allocator, @intCast(col));
                }
            }
        }
        if (empty_row) {
            try empty_rows.append(allocator, row);
        }
    }

    for (0..galaxies.items.len - 1) |i| {
        var galaxy = galaxies.items[i];

        for (i + 1..galaxies.items.len) |j| {
            var other_galaxy = galaxies.items[j];

            var distance: usize = std.math.absCast(galaxy.row - other_galaxy.row);
            distance += std.math.absCast(galaxy.col - other_galaxy.col);

            var min = @min(galaxy.row, other_galaxy.row);
            var max = @max(galaxy.row, other_galaxy.row);
            for (empty_rows.items) |empty_row| {
                if (empty_row > min and empty_row < max) {
                    distance += 1;
                }
            }

            min = @min(galaxy.col, other_galaxy.col);
            max = @max(galaxy.col, other_galaxy.col);
            for (empty_cols.items) |empty_col| {
                if (empty_col > min and empty_col < max) {
                    distance += 1;
                }
            }

            result += @intCast(distance);
        }
    }

    return result;
}

test "Example" {
    const data =
        \\...#......
        \\.......#..
        \\#.........
        \\..........
        \\......#...
        \\.#........
        \\.........#
        \\..........
        \\.......#..
        \\#...#.....
    ;

    var result = try solve(data, std.testing.allocator);

    try std.testing.expectEqual(@as(@TypeOf(result), 374), result);
}
