return {
    dir = '/Users/mavni/Repos/kubectl.nvim',
    -- 'mosheavni/kubectl.nvim',
    opts = {
      diff = { bin = 'kdiff' },
      custom_views = {
        ['externalsecrets.external-secrets.io'] = {
          resource = 'externalsecrets',
          display_name = 'ExternalSecrets',
          ft = 'k8s_externalsecret',
          -- url = { '{{BASE}}/apis/external-secrets.io/v1beta1/externalsecrets' },
          -- cmd = 'curl',
          headers = {
            { name = 'NAMESPACE', func = false }, -- part of fallback view, no need to recalculate
            { name = 'NAME', func = false }, -- part of fallback view, no need to recalculate
            {
              name = 'STORE',
              func = function(row)
                return row.spec.secretStoreRef.name
              end,
            },
            {
              name = 'REFRESH_INTERVAL',
              func = function(row)
                return row.spec.refreshInterval
              end,
            },
            {
              name = 'STATUS',
              func = function(row)
                return row.status.conditions[1].reason
              end,
            },
            {
              name = 'READY',
              func = function(row)
                return row.status.conditions[1].type
              end,
            },
            { name = 'AGE', func = false }, -- part of fallback view, no need to recalculate
          },
        },
      },
    },
    keys = {
      { '<leader>k', '<cmd>lua require("kubectl").open()<cr>' },
    },
  }
