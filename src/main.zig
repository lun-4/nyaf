const std = @import("std");

// TODO make it a build option or smth?
const MAIN_FOLDER_PATH = "/etc/nyaf";
const CFG_FILE_PATH = MAIN_FOLDER_PATH ++ "/config";

const configs = @import("config.zig");
const Config = configs.Config;

const Context = struct {
    allocator: *std.mem.Allocator,
    cfg: ?Config = null,

    const Self = @This();

    pub fn readConfig(self: *Self) !void {
        var config_file_opt = std.fs.cwd().openFile(
            CFG_FILE_PATH,
            .{ .read = true },
        ) catch |err| blk: {
            if (err == error.FileNotFound)
                break :blk null
            else
                return err;
        };

        if (config_file_opt) |config_file| {
            self.cfg = try configs.parseConfig(self.allocator, config_file);
        } else {
            self.cfg = Config{};
        }
    }

    pub fn saveConfig(self: *Self) !void {
        std.fs.makeDirAbsolute(MAIN_FOLDER_PATH) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };

        var config_file = try std.fs.cwd().createFile(CFG_FILE_PATH, .{
            .read = false,
            .truncate = true,
        });

        try std.json.stringify(self.cfg.?, .{}, config_file.writer());
    }

    pub fn deinit(self: *const Self) void {
        if (self.cfg) |cfg| {
            configs.freeConfig(self.allocator, cfg);
        }
    }

    pub fn status(self: *Self) !void {
        try self.readConfig();
        if (self.cfg) |cfg| {
            std.debug.warn("enabled? {}\n", .{cfg.enabled});
        } else {
            std.debug.warn("nyaf config file not found\n", .{});
        }
    }

    pub fn enable(self: *Self) !void {
        try self.readConfig();
        self.cfg.?.enabled = true;
        try self.saveConfig();
    }

    pub fn disable(self: *Self) !void {
        try self.readConfig();
        self.cfg.?.enabled = false;
        try self.saveConfig();
    }
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
    defer ctx.deinit();

    if (std.mem.eql(u8, action, "enable")) {
        try ctx.enable();
    } else if (std.mem.eql(u8, action, "disable")) {
        try ctx.disable();
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
        std.log.info("nyaf v0.0.1", .{});
    }
}
