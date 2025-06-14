local M = {
  k8s_schemas = {
    {
      name = 'Kubernetes 1.29.9',
      uri = 'https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.29.9-standalone-strict/all.json',
    },
  },
  all_schemas = {},
  yaml_cfg = {},
  core_api_groups = {
    [''] = true, -- core group (v1)
    ['apps'] = true,
    ['batch'] = true,
    ['autoscaling'] = true,
    ['networking.k8s.io'] = true,
    ['policy'] = true,
    ['rbac.authorization.k8s.io'] = true,
    ['storage.k8s.io'] = true,
  },
}

M.add_crds = function(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local resources = {}
  local current = { line = nil }

  for i, line in ipairs(lines) do
    if line:match '^kind:' then
      current.kind = line:match '^kind:%s*(.+)'
      if not current.line then
        current.line = i
      end
    elseif line:match '^apiVersion:' then
      current.apiVersion = line:match '^apiVersion:%s*(.+)'
      if not current.line then
        current.line = i
      end
    elseif line:match '^%-%-%-' then
      if current.apiVersion and current.kind then
        -- Split apiVersion into group and version
        local group, version
        if current.apiVersion:find '/' then
          group, version = current.apiVersion:match '(.+)/(.+)'
        else
          group = ''
          version = current.apiVersion
        end

        table.insert(resources, {
          kind = current.kind,
          apiVersion = current.apiVersion,
          apiGroup = group,
          version = version,
          line = current.line,
        })
      end
      current = { line = nil }
    end
  end

  -- check the last section
  if current.apiVersion and current.kind then
    local group, version
    if current.apiVersion:find '/' then
      group, version = current.apiVersion:match '(.+)/(.+)'
    else
      group = ''
      version = current.apiVersion
    end

    table.insert(resources, {
      kind = current.kind,
      apiVersion = current.apiVersion,
      apiGroup = group,
      version = version,
      line = current.line,
    })
  end

  -- Add comments before CRD resources
  local lines_to_add = {}
  local added_kinds = {}
  for _, resource in ipairs(resources) do
    -- If the API group is not in M.core_api_groups, it's likely a CRD
    if resource.apiGroup ~= '' and not M.core_api_groups[resource.apiGroup] then
      -- Construct URL based on apiGroup and version
      local url =
        string.format('https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/%s/%s_%s.json', resource.apiGroup, resource.kind:lower(), resource.version)
      local modeline = string.format('# yaml-language-server: $schema=%s', url)
      -- Check if the modeline already exists in the previous line
      local prev_line = vim.api.nvim_buf_get_lines(bufnr, resource.line - 2, resource.line - 1, false)[1]
      if not prev_line or not prev_line:match '# yaml%-language%-server: %$schema=' then
        lines_to_add[resource.line] = modeline
        if not vim.list_contains(added_kinds, resource.kind) then
          table.insert(added_kinds, resource.kind)
        end
      end
    end
  end

  -- Insert the comments
  local offset = 0
  for line_num, comment in pairs(lines_to_add) do
    vim.api.nvim_buf_set_lines(bufnr, line_num - 1 + offset, line_num - 1 + offset, false, { comment })
    offset = offset + 1
  end

  -- return the kind: of the modelines that were added
  return added_kinds
end

M.setup = function(opts)
  local capabilities = opts.capabilities or require('user.lsp.config').capabilities
  local yaml_lspconfig = {
    on_attach = function(_, bufnr)
      local modeline_added = M.add_crds(bufnr)
      if modeline_added then
        -- vim.notify('Added YAML modeline for CRDs', vim.log.levels.INFO, { title = 'YAML LSP' })
        -- print the CRDs that were added
        local crds = table.concat(modeline_added, ', ')
        vim.notify('Added YAML modeline for CRDs: ' .. crds, vim.log.levels.INFO, { title = 'YAML LSP' })
      end
    end,
    capabilities = vim.tbl_deep_extend('force', capabilities, {
      textDocument = {
        foldingRange = {
          dynamicRegistration = true,
        },
      },
    }),
    settings = {
      yaml = {
        format = {
          bracketSpacing = false,
        },
        -- schemas = require('schemastore').yaml.schemas(),
        schemaStore = {
          -- Must disable built-in schemaStore support to use
          -- schemas from SchemaStore.nvim plugin
          enable = false,
          -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
          url = '',
        },
      },
    },
  }
  -- Merge the lists
  vim.list_extend(M.all_schemas, M.k8s_schemas)
  -- vim.list_extend(M.all_schemas, require('schemastore').json.schemas())
  -- vim.list_extend(M.all_schemas, require('user.additional-schemas').crds_as_schemas())
  local yaml_cfg = require('yaml-companion').setup {
    -- log_level = 'debug',
    builtin_matchers = {
      -- Detects Kubernetes files based on content
      kubernetes = { enabled = true },
    },
    -- schemas = M.all_schemas,
    lspconfig = yaml_lspconfig,
  }
  vim.lsp.config('yamlls', yaml_cfg)
  M.yaml_cfg = yaml_cfg
  return yaml_cfg
end

return M
