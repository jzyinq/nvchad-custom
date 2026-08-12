local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

-- if you just want default config for the servers then put them in a table
local servers = { "html", "cssls", "ts_ls", "clangd", "ruff", "basedpyright", "gopls", "yamlls", "jsonls", "lemminx", "helm_ls", "bashls"}

for _, lsp in ipairs(servers) do
  vim.lsp.config(lsp, {
    on_attach = on_attach,
    capabilities = capabilities,
  })
end

vim.lsp.enable(servers)

-- Detect Helm templates and set filetype accordingly
vim.api.nvim_create_autocmd("BufRead", {
  pattern = "*.yaml,*.yml",
  callback = function(args)
    local filepath = args.file
    -- Check if file matches Helm chart structure: .../templates/... or .../charts/.../templates/...
    -- This works for structures like: /helm/templates/file.yaml, /charts/mychart/templates/file.yaml, etc.
    local is_helm_template = filepath:match("charts/[^/]+/templates/") or filepath:match("/helm/templates/")

    if is_helm_template then
      vim.bo.filetype = "helm"
      vim.bo.syntax = "yaml" -- Use YAML syntax highlighting
    end
  end,
})

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
