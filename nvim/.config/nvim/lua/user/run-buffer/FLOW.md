# run-buffer: F3 flow

What happens when you press **F3** on a buffer. This document starts with the simplest case: a saved shell script.

## Basic case

Assumptions:

- Named file on disk (e.g. `/path/to/script.sh`)
- `filetype` is `sh`
- Buffer is not modified
- No shebang on line 1
- First F3 press for this file (no existing run-terminal registered)

## Flowchart

```mermaid
flowchart TD
  F3["F3 keymap"] --> execute["execute_file()"]
  execute --> buftype{buftype == terminal?}
  buftype -->|yes| stop1[return — no-op]
  buftype -->|no| prep["buffer.filename_and_ft()"]

  prep --> hasName{buffer has a path?}
  hasName -->|yes /script.sh| modified{modified?}
  hasName -->|no| unnamed[unnamed-buffer path — not this case]
  modified -->|no| gotPath["file_name = /path/to/script.sh<br/>ft = sh"]

  gotPath --> resolve["resolve.run(sh, file_name)"]
  resolve --> buildCtx["ctx = { ft, file_name, first_line }"]
  buildCtx --> lookup{registered handler?}
  lookup -->|yes| resolveH["handler.resolve(ctx)"]
  lookup -->|no| default["default_resolve(ctx)"]
  default --> cmdLookup["utils.command_for_filetype('sh') → bash"]
  cmdLookup --> shebang{first line starts with #!?}
  shebang -->|no| buildCmd["cmd = 'bash /path/to/script.sh'"]
  shebang -->|yes| shebangCmd["cmd = file path only"]
  buildCmd --> result["{ cmd, spawn=true }"]
  shebangCmd --> result
  resolveH --> result

  result --> spawnCheck{result.spawn?}
  spawnCheck -->|no| stop2[return]
  spawnCheck -->|yes| cwd["resolve.cwd(sh) → buffer's directory"]
  cwd --> where{where arg set?}
  where -->|F3: nil| terminal["run_in_terminal(file, cmd, {cwd})"]
  where -->|:RunInTab| wezterm[wezterm.spawn_and_send — not F3]

  terminal --> existing{terminal already<br/>registered for this file?}
  existing -->|no — first run| newTerm["create terminal buffer<br/>jobstart($SHELL)<br/>register in user.terminal"]
  newTerm --> send["terminal.send('bash /path/to/script.sh')"]
  existing -->|yes — re-run| reuse["show terminal, Ctrl-C<br/>wait 50ms, send command again"]
```

## Step-by-step

1. **F3** calls `execute_file()` with no `where` argument → Neovim terminal split (not Wezterm tab).

2. **`buffer.filename_and_ft`** — file has a path and is not dirty → returns `/path/to/script.sh`, `sh`.

3. **`resolve.run`** — no `sh` handler in the registry → **`default_resolve`**:
   - `utils.command_for_filetype('sh')` → `bash`
   - no shebang → `bash /path/to/script.sh`
   - returns `{ cmd = 'bash /path/to/script.sh', spawn = true }`

4. **`resolve.cwd`** — no custom `cwd` handler for `sh` → parent directory of the buffer file.

5. **`run_in_terminal`** (first run for this file):
   - creates a terminal buffer in a split
   - starts `$SHELL` with that `cwd`
   - sends `bash /path/to/script.sh`

## Re-run (F3 again on the same file)

Resolution is the same. `run_in_terminal` finds the existing terminal registered for that file path, shows it, sends `<C-c>`, waits 50ms, then sends the command again (and `cd` first if `cwd` changed).

## Related entry points

| Trigger | `where` | Destination |
| ------- | ------- | ------------- |
| `<F3>` | `nil` | `run_in_terminal` |
| `:RunInTerminal` | `'terminal'` | `run_in_terminal` |
| `:RunInTab` | `'tab'` | `wezterm.spawn_and_send` |

## Module map

| Step | Module |
| ---- | ------ |
| Keymap / orchestration | `init.lua` |
| Registry, default resolve, `run`, `cwd` | `resolve.lua` |
| Buffer path + save prompt | `buffer.lua` |
| Builtin handlers | `handlers/*.lua` (one per filetype) |
| Makefile target picker | `handlers/make.lua` |
| Terminal split + per-file state | `user.terminal` |
