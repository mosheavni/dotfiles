---@meta

--- Context passed to every run handler when resolving how to run a buffer.
---@class RunContext
---@field ft string Neovim filetype of the buffer (defaults to `sh` when empty).
---@field file_name string Absolute path to the file on disk.
---@field first_line string Contents of line 1 (used for shebang detection in the default handler).

--- Result returned from command resolution.
---@class RunResult
---@field cmd string|nil Shell command when `spawn` is true.
---@field spawn boolean When true, run `cmd` in terminal/wezterm; when false, stop orchestration.

--- Resolve how to run a buffer synchronously.
---@alias RunResolve fun(ctx: RunContext): RunResult

--- Per-filetype handler registered in the run-buffer registry.
---@class RunHandler
---@field resolve? RunResolve Build a command or run in-buffer; return the result.
---@field cwd? fun(): string Override working directory for terminal/wezterm (default: buffer directory).

--- Builtin or plugin handler module shape (`require(...)` + register).
---@class RunHandlerModule
---@field ft string Filetype key used in the registry.
---@field handler RunHandler Handler table for this filetype.
