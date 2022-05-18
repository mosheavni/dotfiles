local wk = require 'which-key'
local opts = {
  mode = 'n', -- NORMAL mode
  prefix = '',
  buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
  silent = true, -- use `silent` when creating keymaps
  noremap = true, -- use `noremap` when creating keymaps
  nowait = false, -- use `nowait` when creating keymaps
}

local mappings = {
  g = {
    a = { 'Motion Pending Align' },
    c = { 'Motion Pending Comment' },
    D = { 'Go to Declaration' },
    d = { 'Go to Definition' },
    y = { 'Go to Type Definition' },
    i = { 'Go to Implementation' },
    r = { 'Go to References' },
    V = { 'Visually select last inserted text' },
  },
  ['<leader>'] = {
    c = {
      c = { 'Select YAML schema' },
      p = { 'Copy [n] lines and paste below' },
      d = { 'Change directory to current file' },
      f = {
        name = '+Copy file path',
        p = { 'Copy file path' },
        a = { 'Copy full file path' },
      },
      t = {
        ['<SPACE'] = { 'Convert tabs to spaces' },
      },
    },
    b = {
      name = '+Buffer',
      c = { 'Close' },
      o = { 'Close all but current' },
      d = { 'Delete' },
      n = { 'Next' },
    },
    d = {
      name = '+Diff',
      n = { 'On' },
      f = { 'Off' },
      p = { 'Put' },
      g = { 'Get' },
    },
    e = {
      name = '+Edit',
      p = { 'Plugins file' },
      v = { 'Options file' },
    },
    f = {
      name = '+Fold',
      f = { 'Fold' },
      c = { 'Close All' },
      o = { 'Open All' },
      l = { 'Open level folds' },
    },
    r = { 'Search and Replace Word Under Cursor' },
    S = { 'Spectre Search and Replace' },
    v = { 'Show current file on NerdTree' },
    ['('] = 'Split param line',
    ['\\'] = 'Split bash line',
    ['<CR>'] = { 'Change \\n to new lines' },
    ['<SPACE>'] = { 'Change buffer' },
    ['='] = { 'Underline with equals (=)' },
    qq = { 'Close all buffers and quit' },
    g = {
      name = '+Git',
      g = { 'Status' },
      h = { 'History (current file)' },
      p = { 'Push' },
      l = { 'Pull' },
      c = { 'CD to root' },
      f = { 'Focus on Git window' },
    },
    l = {
      name = '+LSP',
      a = { 'Code Actions' },
      x = { 'Run CodeLens' },
      q = { 'Open Diagnostics on QuickFix' },
      p = { 'Format Document' },
      e = { 'Open Diagnostics Float' },
      k = { 'Signature Help' },
    },
    m = {
      name = '+Mouse',
      a = { 'All modes' },
      v = { 'Visual mode' },
    },
  },
}
wk.register(mappings, opts)
