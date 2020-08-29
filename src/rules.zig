const std = @import("std");

pub const Action = enum {
    Allow,
    Deny,
};

pub const Flow = enum {
    In,
    Out,
    Any,
};

pub const Protocol = enum {
    TCP,
    UDP,
    Any,
};

pub const Port = union(enum) {
    All: void,
    Numeric: u16,
    Range: struct { from: u16, to: u16 },
};

// TODO CIDR?
pub const Target = union(enum) {
    Address: std.net.Address,
    Any: void,
    Local: void,
};

pub const Rule = struct {
    interface: ?[]const u8,

    action: Action,
    flow: Flow,
    protocol: Protocol,
    port: Port,
    from: Target,
    to: Target,

    fn printTarget(writer: anytype, comptime fmt: []const u8, target: Target) !void {
        switch (target) {
            .Any => {},
            .Local => {
                // TODO iface goes here
                try writer.print(fmt, .{"inet4(wm0)"});
            },
            .Address => |addr| {
                try writer.print(fmt, .{addr});
            },
        }
    }

    /// Print this rule as an NPF rule.
    /// Caller owns the memory.
    pub fn emitNpf(self: @This(), allocator: *std.mem.Allocator) ![]const u8 {
        var list = std.ArrayList(u8).init(allocator);
        defer list.deinit();

        var writer = list.writer();

        _ = switch (self.action) {
            .Allow => try writer.write("pass"),
            .Deny => try writer.write("block"),
        };

        if (self.protocol == .TCP) {
            try writer.print(" stateful", .{});
        }

        switch (self.flow) {
            .In => {
                try writer.print(" in", .{});
            },
            .Out => {
                try writer.print(" out", .{});
            },
            .Any => {},
        }

        if (self.interface) |interface| {
            try writer.print(" on {}", .{self.interface});
        }

        _ = switch (self.protocol) {
            .TCP => try writer.write(" proto tcp"),
            .UDP => try writer.write(" proto udp"),
            .Any => 0,
        };

        if (self.protocol == .TCP) {
            try writer.print(" flags S/SA", .{});
        }

        try @This().printTarget(writer, " from {}", self.from);
        try @This().printTarget(writer, " to {}", self.to);

        switch (self.port) {
            .All => try writer.print(" all", .{}),
            .Numeric => |port_num| {
                try writer.print(" port {}", .{port_num});
            },
            .Range => |range| {
                try writer.print(" port {}-{}", .{ range.from, range.to });
            },
        }

        return list.toOwnedSlice();
    }
};

test "ensure rules print out to good npf rules" {
    const iface = "wm0";

    const rules = [_]Rule{
        .{
            .interface = null,
            .action = .Deny,
            .flow = .Any,
            .protocol = .Any,
            .port = Port{ .All = {} },
            .from = Target{ .Any = {} },
            .to = Target{ .Any = {} },
        },
        .{
            .interface = iface,
            .action = .Allow,
            .flow = .In,
            .protocol = .TCP,
            .port = Port{ .Numeric = 80 },
            .from = Target{ .Any = {} },
            .to = Target{ .Any = {} },
        },
    };
    const npf_rules = [_][]const u8{
        "block all",
        "pass stateful in on " ++ iface ++ " proto tcp flags S/SA port 80",
    };

    for (rules) |rule, idx| {
        const npf_rule = try rule.emitNpf(std.testing.allocator);
        defer std.testing.allocator.free(npf_rule);
        std.debug.warn("{} => {}\n", .{ rule, npf_rule });
        const wanted_npf_rule = npf_rules[idx];
        std.debug.assert(std.mem.eql(u8, npf_rule, wanted_npf_rule));
    }
}
