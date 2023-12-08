const std = @import("std");

pub fn main() !void {
    const data = @embedFile("input.txt");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var result = try solve(data, gpa.allocator());
    try std.io.getStdOut().writer().print("{d}\n", .{result});
}

const HandType = enum {
    high_card,
    one_pair,
    two_pair,
    three_of_a_kind,
    full_house,
    four_of_a_kind,
    five_of_a_kind,
};

const Hand = struct {
    hand: []const u8,
    type: HandType,
    bid: usize,

    pub fn lessThan(_: void, lhs: Hand, rhs: Hand) bool {
        if (lhs.type != rhs.type) {
            return @intFromEnum(lhs.type) < @intFromEnum(rhs.type);
        }

        for (lhs.hand, rhs.hand) |lhs_hand, rhs_hand| {
            if (lhs_hand != rhs_hand) {
                return Hand.cardWeight(lhs_hand) < cardWeight(rhs_hand);
            }
        }

        return false;
    }

    pub fn cardWeight(card: u8) usize {
        return switch (card) {
            'A' => 14,
            'K' => 13,
            'Q' => 12,
            'J' => 11,
            'T' => 10,
            else => @intCast(card - '0'),
        };
    }
};

fn solve(data: []const u8, child_allocator: std.mem.Allocator) !usize {
    var result: usize = 0;

    var data_itr = std.mem.split(u8, data, "\n");

    var arena = std.heap.ArenaAllocator.init(child_allocator);
    defer arena.deinit();

    var allocator = arena.allocator();

    var hands = std.ArrayList(Hand).init(allocator);
    hands.deinit();

    while (data_itr.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        var hand_itr = std.mem.split(u8, line, " ");
        var hand = hand_itr.first();

        try hands.append(.{
            .hand = hand,
            .type = blk: {
                var map = [_]u8{0} ** 255;
                var counts = [_]u8{0} ** 6; // Only need five but accessing [5] is nice to read

                for (hand) |char| {
                    map[char] += 1;
                }

                for (map) |count| {
                    if (count > 0) {
                        counts[count] += 1;
                    }
                }

                if (counts[5] == 1) {
                    break :blk HandType.five_of_a_kind;
                }

                if (counts[4] == 1) {
                    break :blk HandType.four_of_a_kind;
                }

                if (counts[3] == 1) {
                    if (counts[2] == 1) {
                        break :blk HandType.full_house;
                    }

                    break :blk HandType.three_of_a_kind;
                }

                if (counts[2] == 2) {
                    break :blk HandType.two_pair;
                }

                if (counts[2] == 1) {
                    break :blk HandType.one_pair;
                }

                break :blk HandType.high_card;
            },
            .bid = try std.fmt.parseUnsigned(usize, hand_itr.next().?, 10),
        });
    }

    std.mem.sort(Hand, hands.items, {}, Hand.lessThan);

    for (hands.items, 1..) |hand, i| {
        result += hand.bid * i;
    }

    return result;
}

test "Example" {
    const data =
        \\32T3K 765
        \\T55J5 684
        \\KK677 28
        \\KTJJT 220
        \\QQQJA 483
    ;

    var result = try solve(data, std.testing.allocator);

    try std.testing.expectEqual(@as(@TypeOf(result), 6440), result);
}
