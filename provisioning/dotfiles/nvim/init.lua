-- ~/.config/nvim/init.lua  (managed by data-tools/provisioning)
-- Simple, fast Neovim: sane defaults + Python LSP + completion.
--   * basedpyright -> completion, go-to-definition, type errors  (no Node needed)
--   * ruff         -> fast lint + format
-- The LSP servers are installed by provisioning/bootstrap.sh via `uv tool install`.
-- Plugins are fetched on first launch (needs internet); base editing works offline.

-- ── Leader ──
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- ── Options ──
local o = vim.opt
o.number = true
o.mouse = 'a'
o.ignorecase = true
o.smartcase = true
o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.termguicolors = true
o.signcolumn = 'yes'
o.updatetime = 250
o.undofile = true
vim.cmd.colorscheme('habamax')

-- ── Keymaps (old muscle memory + LSP) ──
vim.keymap.set('i', 'jk', '<Esc>')
vim.keymap.set('n', '<C-l>', '<cmd>nohlsearch<cr><C-l>')
vim.keymap.set('n', '<leader>s', [[:%s/\<<C-r><C-w>\>//g<Left><Left>]])
vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'Goto definition' })
vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = 'Hover docs' })
vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { desc = 'Rename symbol' })
vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'Code action' })
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Prev diagnostic' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic' })
vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format() end, { desc = 'Format' })

-- ── Bootstrap lazy.nvim ──
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable',
    'https://github.com/folke/lazy.nvim.git', lazypath })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  -- Syntax highlighting
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs',
    opts = {
      ensure_installed = { 'python', 'lua', 'bash', 'json', 'yaml', 'toml', 'markdown' },
      highlight = { enable = true },
      indent = { enable = true },
    },
  },

  -- Completion popup
  {
    'saghen/blink.cmp',
    version = '*',
    opts = {
      keymap = { preset = 'default' },
      completion = { documentation = { auto_show = true } },
    },
  },

  -- LSP
  {
    'neovim/nvim-lspconfig',
    dependencies = { 'saghen/blink.cmp' },
    config = function()
      local lsp = require('lspconfig')
      local caps = require('blink.cmp').get_lsp_capabilities()
      lsp.basedpyright.setup({ capabilities = caps })
      lsp.ruff.setup({ capabilities = caps })
      vim.diagnostic.config({ virtual_text = true, severity_sort = true })
    end,
  },
}, { ui = { border = 'rounded' } })
