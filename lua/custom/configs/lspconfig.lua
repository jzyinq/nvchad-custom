-- on_attach keymaps and capabilities come from nvchad.configs.lspconfig.defaults()
-- (LspAttach autocmd + vim.lsp.config("*")), called before this file.
local servers = { "html", "cssls", "ts_ls", "clangd", "ruff", "basedpyright", "gopls", "yamlls", "jsonls", "lemminx", "helm_ls", "bashls", "marksman"}

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
