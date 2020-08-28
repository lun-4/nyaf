const std = @import("std");

const Context = struct {
    allocator: *std.mem.Allocator,

    const Self = @This();

    pub fn status(self: *Self) !void {}
};

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        _ = gpa.deinit();
    }

    var allocator = &gpa.allocator;

    var args_it = std.process.args();
    _ = args_it.skip();

    const action = try (args_it.next(allocator) orelse @panic("expected action"));
    defer allocator.free(action);

    var ctx = Context{ .allocator = allocator };

    if (std.mem.eql(u8, action, "enable")) {
        // ctx.enable();
    } else if (std.mem.eql(u8, action, "disable")) {
        // ctx.enable();
    } else if (std.mem.eql(u8, action, "allow")) {
        const port = try (args_it.next(allocator) orelse @panic("expected action"));
        defer allocator.free(port);

        // if port == all, warn("allow all is unwanted"), ctx.allowAll();

        // ctx.allow(port, from, to);
    } else if (std.mem.eql(u8, action, "deny")) {
        const port = try (args_it.next(allocator) orelse @panic("expected action"));
        defer allocator.free(port);

        // if port == all, ctx.denyAll();

        // ctx.deny();
    } else if (std.mem.eql(u8, action, "status") or std.mem.eql(u8, action, "list")) {
        try ctx.status();
    } else if (std.mem.eql(u8, action, "version")) {
        std.log.info("nyaf v0.0.1\n", .{});
    }
}
