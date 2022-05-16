local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local conf = require("telescope.config").values
local util = require 'lspconfig'.util

local M = {}

M.current_yaml_schema = "No YAML schema"

M._get_client = function()
  M.bufnr = vim.api.nvim_get_current_buf()
  M.uri = vim.uri_from_bufnr(M.bufnr)
  if vim.bo.filetype ~= "yaml" then return end
  if not M.client then
    M.client = util.get_active_client_by_name(M.bufnr, 'yamlls')
  end
  return M.client
end

M._load_all_schemas = function()
  local client = M._get_client()
  if not client then return end
  local params = { uri = M.uri }
  client.request('yaml/get/all/jsonSchemas', params, function(err, result, _, _)
    if err then
      return
    end
    if result then
      if vim.tbl_count(result) == 0 then
        return vim.notify('Schemas not loaded yet.')
      end
      M._open_telescope(result)
    end
  end)
end

M._telescope_action = function(prompt_bufnr, _)
  actions.select_default:replace(function()
    actions.close(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    M._change_settings(selection.value)
  end)
  return true
end

M._change_settings = function(schema)
  local client = M._get_client()
  local previous_settings = client.config.settings
  for key, value in pairs(previous_settings.yaml.schemas) do
    if vim.tbl_islist(value) then
      for idx, value_value in pairs(value) do
        if value_value == M.uri or string.find(value_value, '*') then
          table.remove(previous_settings.yaml.schemas[key], idx)
        end
      end
    elseif value == M.uri or string.find(value, '*') then
      previous_settings.yaml.schemas[key] = nil
    end
  end
  local new_settings = vim.tbl_deep_extend('force', previous_settings, {
    yaml = {
      schemas = {
        [schema] = M.uri
      }
    }
  })
  client.config.settings = new_settings
  client.notify("workspace/didChangeConfiguration")
  vim.notify('Successfully applied schema ' .. schema)
end

M._open_telescope = function(schemas)
  local opts = {}
  return pickers.new(opts, {
    prompt_title = "Yaml Schemas",
    finder = finders.new_table {
      results = schemas,
      entry_maker = function(entry)
        local ret_obj = {
          value = entry.uri,
          display = entry.uri,
          ordinal = entry.uri
        }
        if entry.name then
          ret_obj.display = entry.name
          ret_obj.ordinal = entry.name
        end
        return ret_obj
      end
    },

    sorter = conf.generic_sorter(opts),
    attach_mappings = M._telescope_action,
  }):find()
end

M._schema_name_mappings = {
  ["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.22.4-standalone-strict/all.json"] = "k8s-1.22.4"
}

M.select = function()
  M._get_client()
  if not M.client then return end
  M._load_all_schemas()
end

M.get_current_schema = function()
  local client = M._get_client()
  if not M.client or not M.uri then
    return ''
  end
  client.request('yaml/get/jsonSchema', { M.uri }, function(err, e)
    local current_schema
    if err then
      return
    end
    if e[0] ~= nil then
      current_schema = e[0].uri
    elseif e[1] ~= nil then
      current_schema = e[1].uri
    end
    if current_schema ~= nil then
      if M._schema_name_mappings[current_schema] then
        current_schema = M._schema_name_mappings[current_schema]
      else
        current_schema = current_schema:gsub('https://raw.githubusercontent.com/', '')
        current_schema = current_schema:gsub('https://json.schemastore.org/', '')
      end
    end
    if current_schema then
      M.current_yaml_schema = "YAML schema: " .. current_schema
    end
  end)
  return M.current_yaml_schema
end

M._get_client()

return M
