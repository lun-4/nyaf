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
    Numerci: u16,
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
    pub fn emitNpf(self: @This(), allocator: *std.mem.Allocator) []const u8 {
        var list = std.ArrayList(u8).init(allocator);
        defer list.deinit();

        var writer = list.writer();

        try writer.print("{}", .{switch (self.action) {
            .Allow => "pass",
            .Deny => "block",
        }});

        if (self.protocol == .TCP) {
            try writer.print(" stateful", .{});
        }

        try writer.print(" {}", .{switch (self.flow) {
            .In => "in",
            .Out => "out",
        }});

        try writer.print(" on {}", .{self.interface});

        if (self.protocol != .Any) {
            try writer.print(" proto {}", .{switch (self.protocol) {
                .TCP => "tcp",
                .UDP => "udp",
            }});
        }

        if (self.protocol == .TCP) {
            try writer.print(" flags S/SA", .{});
        }

        // TODO: from to
        try writer.write("to {}", .{self.to});
        switch (self.port) {
            .Any => {},
            .Numeric => |port_num| try writer.print("{}", .{port_num}),
        }

        return list.toOwnedSlice();
    }
};

pub fn printRule(rule: Rule, allocator: *std.mem.Allocator, rule) []u8 {}
