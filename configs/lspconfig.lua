local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

-- if you just want default config for the servers then put them in a table
local servers = { "html", "cssls", "ts_ls", "clangd", "ruff", "basedpyright", "gopls", "yamlls", "jsonls", "lemminx", "helm_ls", "bashls", "marksman"}

for _, lsp in ipairs(servers) do
  vim.lsp.config(lsp, {
    on_attach = on_attach,
    capabilities = capabilities,
  })
end

vim.lsp.enable(servers)

-- Helm filetype detection lives in lua/custom/init.lua (vim.filetype.add)

-- Configure yamlls to NOT attach to helm filetype
vim.lsp.config("yamlls", {
  filetypes = { "yaml", "yml" }, -- explicitly exclude "helm"
})

-- Configure helm_ls to attach to helm filetype
vim.lsp.config("helm_ls", {
  filetypes = { "helm" },
})

vim.lsp.config("basedpyright", {
  settings = {
    basedpyright = {
      analysis = {
        typeCheckingMode = "standard",
      },
    },
  }
})

--
-- lspconfig.pyright.setup { blabla}
