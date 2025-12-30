local ts = vim.treesitter
local M = {}

-- I. Configuration and Constants
M.config = {
  -- The plugin version
  version = '0.3.2',
  -- The vim user command that will trigger the plugin.
  command_name = 'OpenDoc',
  -- Base URL for documentation
  base_url = 'https://registry.terraform.io/providers/',
  -- If true, the cursor will jump to the anchor in the documentation.
  jump_anchor = true,
  -- Map Terraform block types to URL segments
  block_type_url_mapping = {
    resource = 'resources',
    data = 'data-sources',
  },
  -- Default provider source for providers not in the map
  default_provider_source = 'hashicorp',
  provider_source_map = {
    cloudflare = 'cloudflare',
    fastly = 'fastly',
    ibm = 'IBM-Cloud',
    newrelic = 'newrelic',
    shell = 'scottwinkler',
    spotinst = 'spotinst',
    vcd = 'vmware',
    mongodbatlas = 'mongodb',
  },
}

-- II. Tree-sitter Traversal and Data Extraction

--- Find the most encompassing 'block' node ancestor (e.g., 'resource' or 'data').
--- Uses efficient ancestor traversal (node:parent()).[6]
---@param start_node TSNode The starting node (cursor position).
---@return TSNode? The encompassing 'block' node.
local function find_block_node(start_node)
  ---@type TSNode?
  local node = start_node
  while node do
    -- The top-level definition in HCL is usually a 'block' node
    if node:type() == 'block' then
      return node
    end
    node = node:parent()
  end
  return nil
end

--- Extract the resource identifier string (e.g., "aws_instance") from the block node.
---@param block_node TSNode The node representing the resource/data block.
---@param bufnr integer The buffer number.
---@return string? The full resource identifier without quotes.
local function get_resource_identifier_from_block(block_node, bufnr)
  -- The resource type name is held within the first string_lit child of the block.
  for i = 0, block_node:named_child_count() - 1 do
    local child = block_node:named_child(i)

    if child and child:type() == 'string_lit' then
      local text = ts.get_node_text(child, bufnr)
      -- Remove surrounding quotes (e.g., `"aws_instance"` -> `aws_instance`)
      return (text:gsub('^"(.+)"$', '%1'))
    end
  end
  return nil
end

--- Splits a Terraform resource identifier at the first underscore.
--- Uses efficient Lua pattern matching.[7]
---@param resource_id string The full resource identifier (e.g., "aws_instance").
---@return string? provider The provider prefix (e.g., 'aws').
---@return string? type_suffix The resource type suffix (e.g., 'instance').
local function split_identifier(resource_id)
  -- Pattern: capture non-underscores (^([^_]+)), then the rest (.*) after the first underscore.
  local provider, type_suffix = resource_id:match '^([^_]+)_(.*)$'
  if not provider then
    return nil, nil
  end
  return provider, type_suffix
end

--- Find the corresponding provider source (e.g., 'hashicorp') using the optimized map.
---@param provider_prefix string The provider prefix (e.g., 'ibm').
---@return string The provider source name (e.g., 'IBM-Cloud' or 'hashicorp').
local function find_provider_source(provider_prefix)
  local source = M.config.provider_source_map[provider_prefix]
  return source or M.config.default_provider_source
end

--- Get all resource documentation components from the current cursor position.
---@return table? A table containing all necessary info for URL construction.
local function get_resource_info()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)

  local start_node = ts.get_node { bufnr = bufnr, pos = { cursor_pos[1] - 1, cursor_pos[2] } }
  if not start_node then
    return nil
  end

  local block_node = find_block_node(start_node)
  if not block_node then
    return nil
  end

  local resource_id = get_resource_identifier_from_block(block_node, bufnr)
  if not resource_id then
    return nil
  end

  local provider_prefix, type_suffix = split_identifier(resource_id)
  if not provider_prefix or not type_suffix then
    return nil
  end

  local source = find_provider_source(provider_prefix)

  -- Get the block type (e.g., "resource" or "data") for URL segment lookup
  local block_type_node = block_node:named_child(0)
  local block_type = block_type_node and ts.get_node_text(block_type_node, bufnr) or ''
  local url_type = M.config.block_type_url_mapping[block_type]

  local argument_name
  if M.config.jump_anchor then
    -- Find the attribute identifier for the jump anchor.
    ---@type TSNode?
    local current = start_node
    while current and current ~= block_node and not argument_name do
      if current:type() == 'attribute' then
        local arg_id_node = current:named_child(0)
        if arg_id_node and arg_id_node:type() == 'identifier' then
          argument_name = ts.get_node_text(arg_id_node, bufnr)
        end
      end
      current = current:parent()
    end
  end

  return {
    resource_id = resource_id,
    source = source,
    provider_prefix = provider_prefix,
    type_suffix = type_suffix,
    url_type = url_type,
    argument_name = argument_name,
  }
end

--- Build the final documentation URL.
---@param info table Resource info.
---@return string
local function build_url(info)
  local url = string.format('%s%s/%s/latest/docs/%s/%s', M.config.base_url, info.source, info.provider_prefix, info.url_type, info.type_suffix)

  -- Handle jump anchor (Terraform docs typically normalize '_' to '-')
  if M.config.jump_anchor and info.argument_name then
    -- url = url .. '#' .. info.argument_name:gsub('_', '-')
    url = url .. '#' .. info.argument_name .. '-1'
  end

  return url
end

-- III. Public API and Command Execution

--- Open the terraform documentation from the current cursor position.
M.open_docs = function()
  local info = get_resource_info()

  if not info or not info.provider_prefix or not info.url_type then
    vim.notify("Could not find a valid Terraform 'resource' or 'data' block under the cursor.", vim.log.levels.WARN, { title = 'Terraform Docs' })
    return
  end

  local url = build_url(info)

  -- Use vim.ui.open() for non-blocking, cross-platform URL opening
  vim.ui.open(url)

  vim.notify('Opening documentation for ' .. info.resource_id .. '...', vim.log.levels.INFO, { title = 'Terraform Docs' })
end

--- Setup the configuration and register the user command.
---@param config table The configuration table.
M.setup = function(config)
  config = config or {}
  -- Merge user settings over defaults reliably [2]
  M.config = vim.tbl_extend('force', M.config, config)

  local command_name = M.config.command_name

  -- Register the user command, which triggers M.open_docs
  vim.api.nvim_create_user_command(command_name, M.open_docs, { nargs = 0, desc = 'Open Terraform documentation for the resource under the cursor' })
end

return M
