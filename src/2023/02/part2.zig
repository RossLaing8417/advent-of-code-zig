const std = @import("std");

pub fn main() !void {
    const data = @embedFile("input.txt");
    var result = solve(data);
    try std.io.getStdOut().writer().print("{d}\n", .{result});
}

const Color = enum { red, green, blue };

const Cubes = struct {
    red: u32 = 0,
    green: u32 = 0,
    blue: u32 = 0,
};

fn solve(data: []const u8) u32 {
    var itr = std.mem.split(u8, data, "\n");
    var result: u32 = 0;

    while (itr.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var data_itr = std.mem.split(u8, line, ":");
        _ = data_itr.first();

        var game_itr = std.mem.split(u8, data_itr.next().?, ";");

        var max_cubes = Cubes{};

        while (game_itr.next()) |game_str| {
            var cube_itr = std.mem.split(u8, game_str, ",");

            var played = Cubes{};

            while (cube_itr.next()) |cube_str| {
                var value_itr = std.mem.split(u8, cube_str, " ");

                var count_str = value_itr.first();
                if (count_str.len == 0) {
                    count_str = value_itr.next().?;
                }
                const count = std.fmt.parseUnsigned(u32, count_str, 10) catch unreachable;

                var color = value_itr.next().?;

                if (std.meta.stringToEnum(Color, color)) |color_tag| {
                    switch (color_tag) {
                        .red => played.red += count,
                        .green => played.green += count,
                        .blue => played.blue += count,
                    }
                } else {
                    std.log.err("Invalid color: {s}", .{color});
                    std.os.exit(1);
                }
            }

            if (played.red > max_cubes.red) {
                max_cubes.red = played.red;
            }
            if (played.green > max_cubes.green) {
                max_cubes.green = played.green;
            }
            if (played.blue > max_cubes.blue) {
                max_cubes.blue = played.blue;
            }
        }

        result += (max_cubes.red * max_cubes.green * max_cubes.blue);
    }

    return result;
}

test "Example" {
    const data =
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    ;

    var result = solve(data);

    try std.testing.expectEqual(@as(@TypeOf(result), 2286), result);
}
