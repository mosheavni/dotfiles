---@meta

--- Context passed to every run handler when resolving how to run a buffer.
---@class RunContext
---@field ft string Neovim filetype of the buffer (defaults to `sh` when empty).
---@field file_name string Absolute path to the file on disk.
---@field first_line string Contents of line 1 (used for shebang detection in the default handler).

--- Result of a synchronous resolve, or the values passed to `on_done`.
---@class RunResult
---@field cmd string|nil Shell command to run; `nil` when the handler already executed in-buffer.
---@field done boolean When true, orchestration stops (no terminal/tab spawn).

--- Callback invoked when command resolution finishes.
---@alias RunOnDone fun(cmd: string|nil, done: boolean)

--- Resolve how to run a buffer. Must always call `on_done` (immediately or after async UI).
---@alias RunResolve fun(ctx: RunContext, on_done: RunOnDone)

--- Per-filetype handler registered in the run-buffer registry.
---@class RunHandler
---@field resolve? RunResolve Build a command or run in-buffer; call `on_done` when finished.
---@field cwd? fun(): string Override working directory for terminal/wezterm (default: buffer directory).

--- Builtin or plugin handler module shape (`require(...)` + register).
---@class RunHandlerModule
---@field ft string Filetype key used in the registry.
---@field handler RunHandler Handler table for this filetype.
