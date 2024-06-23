pub const wasm = @import("./wasm.zig");

pub const WasiConfig = opaque {
    /// Options to inherit when inherriting configs
    /// By default all is `true` as you often want to
    /// inherit everything rather than something specifically.
    const InheritOptions = struct {
        argv: bool = true,
        env: bool = true,
        std_in: bool = true,
        std_out: bool = true,
        std_err: bool = true,
    };

    pub fn init() !*WasiConfig {
        return wasi_config_new() orelse error.ConfigInit;
    }

    pub fn deinit(self: *WasiConfig) void {
        wasi_config_delete(self);
    }

    /// Allows to inherit the native environment into the current config.
    /// Inherits everything by default.
    pub fn inherit(self: *WasiConfig, options: InheritOptions) void {
        if (options.argv) self.inheritArgv();
        if (options.env) self.inheritEnv();
        if (options.std_in) self.inheritStdIn();
        if (options.std_out) self.inheritStdOut();
        if (options.std_err) self.inheritStdErr();
    }

    pub fn inheritArgv(self: *WasiConfig) void {
        wasi_config_inherit_argv(self);
    }

    pub fn inheritEnv(self: *WasiConfig) void {
        wasi_config_inherit_env(self);
    }

    pub fn inheritStdIn(self: *WasiConfig) void {
        wasi_config_inherit_stdin(self);
    }

    pub fn inheritStdOut(self: *WasiConfig) void {
        wasi_config_inherit_stdout(self);
    }

    pub fn inheritStdErr(self: *WasiConfig) void {
        wasi_config_inherit_stderr(self);
    }

    extern "c" fn wasi_config_new() ?*WasiConfig;
    extern "c" fn wasi_config_delete(?*WasiConfig) void;
    extern "c" fn wasi_config_inherit_argv(?*WasiConfig) void;
    extern "c" fn wasi_config_inherit_env(?*WasiConfig) void;
    extern "c" fn wasi_config_inherit_stdin(?*WasiConfig) void;
    extern "c" fn wasi_config_inherit_stdout(?*WasiConfig) void;
    extern "c" fn wasi_config_inherit_stderr(?*WasiConfig) void;
};
