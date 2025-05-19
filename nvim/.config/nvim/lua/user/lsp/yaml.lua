local M = {
  k8s_schemas = {
    {
      name = 'Kubernetes 1.29.9',
      uri = 'https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.29.9-standalone-strict/all.json',
    },
  },
  all_schemas = {},
  yaml_cfg = {},
}

M.on_attach = function(client, bufnr)
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

  -- Don't forget to check the last section
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

  -- Define CRDs
  local crd = {
    'ExternalSecret',
  }

  -- Add comments before CRD resources
  local lines_to_add = {}
  for _, resource in ipairs(resources) do
    for _, v in ipairs(crd) do
      if resource.kind == v then
        -- Construct URL based on apiGroup and version
        local url = string.format(
          'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/%s/%s_%s.json',
          resource.apiGroup,
          resource.kind:lower(),
          resource.version
        )
        lines_to_add[resource.line] = string.format('# yaml-language-server: $schema=%s', url)
      end
    end
  end

  -- Insert the comments
  local offset = 0
  for line_num, comment in pairs(lines_to_add) do
    vim.api.nvim_buf_set_lines(bufnr, line_num - 1 + offset, line_num - 1 + offset, false, { comment })
    offset = offset + 1
  end

  -- add schema to yaml
  local schemas = require('schemastore').yaml.schemas()

  if #resources > 0 then
    -- schemas = vim.tbl_deep_extend('force', schemas, { [require('kubernetes').yamlls_schema()] = results })
    schemas = vim.tbl_deep_extend('force', schemas, { kubernetes = vim.uri_from_bufnr(bufnr) })
  end
  client.config.settings = M.yaml_cfg
  client.config.settings.yaml.schemas = schemas
end

M.setup = function(opts)
  local capabilities = opts.capabilities or require('user.lsp.config').capabilities
  local yaml_lspconfig = {
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
  -- require('lspconfig')['yamlls'].setup(yaml_cfg)
  M.yaml_cfg = yaml_cfg
  return yaml_cfg
end

return M
