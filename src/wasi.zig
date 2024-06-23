const std = @import("std");
const wasm = @import("./wasm.zig");

/// Custom error set for WASI operations
pub const WasiError = error{
    ConfigInit,
    PreopenDirFailed,
    MapDirFailed,
    EnvInit,
    ReadStdoutFailed,
    ReadStderrFailed,
    InitializeInstanceFailed,
    GetImportsFailed,
    StartFunctionNotFound,
};

/// Opaque type representing WASI configuration
pub const WasiConfig = opaque {
    /// Options to inherit when inheriting configs
    const InheritOptions = struct {
        argv: bool = true,
        env: bool = true,
        std_in: bool = true,
        std_out: bool = true,
        std_err: bool = true,
    };

    /// Initialize a new WASI configuration
    pub fn init() !*WasiConfig {
        return wasi_config_new() orelse WasiError.ConfigInit;
    }

    /// Clean up WASI configuration
    /// The `wasi_env_new` function takes the ownership of the wasm_config_t
    /// https://github.com/wasmerio/wasmer/issues/2468
    pub fn deinit(self: *WasiConfig) void {
        _ = self;
        @compileError("not implemented in wasmer");
    }

    /// Inherit native environment settings
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

    /// Set a command-line argument
    pub fn setArg(self: *WasiConfig, arg: []const u8) void {
        wasi_config_arg(self, arg.ptr);
    }

    /// Set an environment variable
    pub fn setEnv(self: *WasiConfig, key: []const u8, value: []const u8) void {
        wasi_config_env(self, key.ptr, value.ptr);
    }

    /// Pre-open a directory
    pub fn preopenDir(self: *WasiConfig, dir: []const u8) !void {
        if (!wasi_config_preopen_dir(self, dir.ptr)) {
            return WasiError.PreopenDirFailed;
        }
    }

    /// Map a directory
    pub fn mapDir(self: *WasiConfig, alias: []const u8, dir: []const u8) !void {
        if (!wasi_config_mapdir(self, alias.ptr, dir.ptr)) {
            return WasiError.MapDirFailed;
        }
    }

    /// Capture stdout
    pub fn captureStdout(self: *WasiConfig) void {
        wasi_config_capture_stdout(self);
    }

    /// Capture stderr
    pub fn captureStderr(self: *WasiConfig) void {
        wasi_config_capture_stderr(self);
    }

    // External C function declarations
    extern "c" fn wasi_config_new() ?*WasiConfig;
    extern "c" fn wasi_config_delete(?*WasiConfig) void;
    extern "c" fn wasi_config_inherit_argv(?*WasiConfig) void;
    extern "c" fn wasi_config_inherit_env(?*WasiConfig) void;
    extern "c" fn wasi_config_inherit_stdin(?*WasiConfig) void;
    extern "c" fn wasi_config_inherit_stdout(?*WasiConfig) void;
    extern "c" fn wasi_config_inherit_stderr(?*WasiConfig) void;
    extern "c" fn wasi_config_arg(?*WasiConfig, [*]const u8) void;
    extern "c" fn wasi_config_env(?*WasiConfig, [*]const u8, [*]const u8) void;
    extern "c" fn wasi_config_preopen_dir(?*WasiConfig, [*]const u8) bool;
    extern "c" fn wasi_config_mapdir(?*WasiConfig, [*]const u8, [*]const u8) bool;
    extern "c" fn wasi_config_capture_stdout(?*WasiConfig) void;
    extern "c" fn wasi_config_capture_stderr(?*WasiConfig) void;
};

/// Opaque type representing WASI environment
pub const WasiEnv = opaque {
    /// Initialize a new WASI environment
    pub fn init(store: *wasm.Store, config: *WasiConfig) !*WasiEnv {
        return wasi_env_new(store, config) orelse WasiError.EnvInit;
    }

    /// Clean up WASI environment
    pub fn deinit(self: *WasiEnv) void {
        wasi_env_delete(self);
    }

    /// Read from captured stdout
    pub fn readStdout(self: *WasiEnv, buffer: []u8) !usize {
        const result = wasi_env_read_stdout(self, buffer.ptr, buffer.len);
        return if (result >= 0) @as(usize, @intCast(result)) else WasiError.ReadStdoutFailed;
    }

    /// Read from captured stderr
    pub fn readStderr(self: *WasiEnv, buffer: []u8) !usize {
        const result = wasi_env_read_stderr(self, buffer.ptr, buffer.len);
        return if (result >= 0) @as(usize, @intCast(result)) else WasiError.ReadStderrFailed;
    }

    /// Initialize a WASI instance
    pub fn initializeInstance(self: *WasiEnv, store: *wasm.Store, instance: *wasm.Instance) !void {
        if (!wasi_env_initialize_instance(self, store, instance)) {
            return WasiError.InitializeInstanceFailed;
        }
    }

    // External C function declarations
    extern "c" fn wasi_env_new(?*wasm.Store, ?*WasiConfig) ?*WasiEnv;
    extern "c" fn wasi_env_delete(?*WasiEnv) void;
    extern "c" fn wasi_env_read_stdout(?*WasiEnv, [*]u8, usize) isize;
    extern "c" fn wasi_env_read_stderr(?*WasiEnv, [*]u8, usize) isize;
    extern "c" fn wasi_env_initialize_instance(?*WasiEnv, ?*wasm.Store, ?*wasm.Instance) bool;
};

/// Enum representing different WASI versions
pub const WasiVersion = enum(c_int) {
    InvalidVersion = -1,
    Latest = 0,
    Snapshot0 = 1,
    Snapshot1 = 2,
    Wasix32v1 = 3,
    Wasix64v1 = 4,
};

/// Get the WASI version of a module
pub fn getWasiVersion(module: *wasm.Module) WasiVersion {
    return @enumFromInt(wasi_get_wasi_version(module));
}

/// Get WASI imports for a module
pub fn getImports(store: *wasm.Store, wasi_env: *WasiEnv, module: *wasm.Module) !wasm.ExternVec {
    var imports = wasm.ExternVec.empty();
    if (!wasi_get_imports(store, wasi_env, module, &imports)) {
        return WasiError.GetImportsFailed;
    }
    return imports;
}

/// Get the start function of a WASI module
pub fn getStartFunction(instance: *wasm.Instance) !*wasm.Func {
    return wasi_get_start_function(instance) orelse WasiError.StartFunctionNotFound;
}

// External C function declarations
extern "c" fn wasi_get_wasi_version(?*wasm.Module) c_int;
extern "c" fn wasi_get_imports(?*wasm.Store, ?*WasiEnv, ?*wasm.Module, ?*wasm.ExternVec) bool;
extern "c" fn wasi_get_start_function(?*wasm.Instance) ?*wasm.Func;
