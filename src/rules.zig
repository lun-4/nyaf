const std = @import("std");

pub const Action = enum {
    Allow,
    Deny,
};

pub const Flow = enum {
    In,
    Out,
};

pub const Protocol = enum {
    TCP,
    UDP,
    Any,
};

pub const Port = union(enum) {
    All: void,
    Numeric: u16,
};

pub const AddressRange = struct {
    from: std.net.Address,
    to: std.net.Address,
};

pub const Target = union(enum) {
    Address: std.net.Address,
    Range: AddressRange,
    Any: void,
    Local: void,
};

pub const Rule = struct {
    interface: []const u8,

    action: Action,
    flow: Flow,
    protocol: Protocol,
    port: Port,
    from: Target,
    to: Target,

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

        _ = switch (self.flow) {
            .In => try writer.write(" in"),
            .Out => try writer.write(" out"),
        };

        try writer.print(" on {}", .{self.interface});

        _ = switch (self.protocol) {
            .TCP => try writer.write(" proto tcp"),
            .UDP => try writer.write(" proto udp"),
            .Any => 0,
        };

        if (self.protocol == .TCP) {
            try writer.print(" flags S/SA", .{});
        }

        // TODO: from to
        try writer.print(" to {}", .{self.to});
        switch (self.port) {
            .All => {},
            .Numeric => |port_num| try writer.print("{}", .{port_num}),
        }

        return list.toOwnedSlice();
    }
};

test "ensure rules print out to good npf rules" {
    const iface = "wm0";

    const rules = [_]Rule{
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
        "pass stateful in on " ++ iface ++ " proto tcp flags S/SA to any port 80",
    };

    for (rules) |rule, idx| {
        const npf_rule = try rule.emitNpf(std.testing.allocator);
        std.debug.warn("{} => {}\n", .{ rule, npf_rule });
        const wanted_npf_rule = npf_rules[idx];
        std.debug.assert(std.mem.eql(u8, npf_rule, wanted_npf_rule));
    }
}
