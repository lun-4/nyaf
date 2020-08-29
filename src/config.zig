const std = @import("std");

pub const Config = struct {
    enabled: bool = false,
    debug: bool = false,
};

pub fn freeConfig(
    allocator: *std.mem.Allocator,
    cfg: Config,
) void {
    const options = std.json.ParseOptions{ .allocator = allocator };
    defer std.json.parseFree(Config, cfg, options);
}

pub fn parseConfig(
    allocator: *std.mem.Allocator,
    cfg_file: std.fs.File,
) !Config {
    var reader = cfg_file.reader();
    const file_data = try reader.readAllAlloc(allocator, 1024);
    defer allocator.free(file_data);

    const options = std.json.ParseOptions{ .allocator = allocator };
    var stream = std.json.TokenStream.init(file_data);
    const cfg = try std.json.parse(
        Config,
        &stream,
        options,
    );

    return cfg;
}
