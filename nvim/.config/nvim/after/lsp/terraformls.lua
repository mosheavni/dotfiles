return {
  on_attach = function(client)
    -- terraform-ls emits semantic tokens whose ranges fall short of the full
    -- identifier, splitting object keys into two colors. Drop them and let
    -- treesitter handle terraform highlighting uniformly.
    client.server_capabilities.semanticTokensProvider = nil
  end,
}
