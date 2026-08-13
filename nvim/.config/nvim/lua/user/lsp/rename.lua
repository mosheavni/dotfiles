local function lsp_rename_changes(old_path, new_path)
  return { { oldUri = vim.uri_from_fname(old_path), newUri = vim.uri_from_fname(new_path) } }
end

local function lsp_will_rename(changes)
  require('user.utils').for_each_client(nil, 'workspace/willRenameFiles', function(client)
    ---@diagnostic disable-next-line: param-type-mismatch
    local resp = client:request_sync('workspace/willRenameFiles', { files = changes }, 1000)
    if resp and resp.result then
      vim.lsp.util.apply_workspace_edit(resp.result, client.offset_encoding)
    end
  end)
end

local function lsp_did_rename(changes)
  require('user.utils').for_each_client(nil, 'workspace/didRenameFiles', function(client)
    client:notify('workspace/didRenameFiles', { files = changes })
  end)
end

-- nvim-tree NodeRenamed fires after the rename already happened, so this
-- post-hoc combined notification is the best it can do
_G._notify_lsp_rename = function(old_path, new_path)
  local changes = lsp_rename_changes(old_path, new_path)
  lsp_will_rename(changes)
  lsp_did_rename(changes)
end

vim.api.nvim_create_user_command('Rename', function()
  local old = vim.api.nvim_buf_get_name(0)
  vim.ui.input({ prompt = 'New filename: ', default = old }, function(new)
    if not new or new == old then
      return
    end
    local changes = lsp_rename_changes(old, new)
    -- LSP spec: willRenameFiles must be requested BEFORE the file operation
    lsp_will_rename(changes)
    vim.fn.rename(old, new)
    vim.cmd('keepalt saveas ' .. vim.fn.fnameescape(new))
    lsp_did_rename(changes)
  end)
end, { desc = 'Rename file' })

require('user.menu').add_actions('File', {
  ['Rename current file (:Rename)'] = function()
    vim.cmd [[Rename]]
  end,
})
