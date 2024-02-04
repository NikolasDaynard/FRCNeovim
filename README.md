# FRCNeovim
This is a plugin for Neovim allowing deploying and building in java.

IMPORTANT NOTE: You have to set JAVA_HOME in your .zshrc / .bashrc to link to the wpilib java jdk. For 2024, that should look somthing like
```
export JAVA_HOME="/Users/[Your Name]/wpilib/2024/jdk"
```
If you skip this Java will throw a huge page of errors at you when opening FRC java code.

You can run a build with
```vim
:BuildRobotCode
```
You can deploy with
```vim
:DeployRobotCode
```
For help or reference you can run
```vim
:FRCNeovimHelp
```
This is much faster than VSCode. To setup the plugin, using vim-plug, use
```lua
vim.cmd [[
  call plug#begin()
  Plug 'NikolasDaynard/FRCNeovim'
  call plug#end()
]]
```
in lua, or 
```vim
call plug#begin()
Plug 'NikolasDaynard/FRCNeovim'
call plug#end()
```
in vim

To configure it, in lua,
```lua
require'FRCNeovim'.setup{
  terminal_size = 60,
  robot_directory = '~/swerve2024/',
  autoQuitOnSuccess = true,
  autoQuitOnFailure = false,
  teamNumber = 1740,
  printOnFailure = true,
  printOnSuccess = true,
  -- This option is strongly discoraged because without java home, the lsp fails to read the java code
  javaHome = '/Users/NikolasDaynard/wpilib/2024/jdk'
}
```
in vim,
```vim
call FRCNeovim#setup({
  \ 'terminal_size': 60,
  \ 'robot_directory': '~/swerve2024/',
  \ 'autoQuitOnSuccess': 1,
  \ 'autoQuitOnFailure': 1,
  \ 'teamNumber': 1740
  \ 'printOnFailure : 1'
  \ 'printOnSuccess : 1'
  \ " This option is strongly discoraged because without java home, the lsp fails to read the java code
  \ javaHome : '/Users/NikolasDaynard/wpilib/2024/jdk'
  \ })
```
Here is an example init.lua with java syntax highlighting (lsp-config and treesitter) and FRCNeovim. I also included cmp to add auto-completion.
```lua
-- Plugin manager setup (use 'vim-plug' here)
vim.cmd [[
  call plug#begin()
  
  Plug 'neovim/nvim-lspconfig'

  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
    
  " LSP completion
  Plug 'hrsh7th/cmp-nvim-lsp'
  Plug 'hrsh7th/cmp-buffer'
  Plug 'hrsh7th/cmp-path'
  Plug 'hrsh7th/cmp-cmdline'
  Plug 'hrsh7th/nvim-cmp'
  Plug 'hrsh7th/cmp-vsnip'
  Plug 'hrsh7th/vim-vsnip'

  Plug 'NikolasDaynard/FRCNeovim'

  call plug#end()
]]

-- Load FRC specific settings
require'FRCNeovim'.setup{
  terminal_size = 60,
  robot_directory = '~/swerve2024/',
  autoQuitOnSuccess = true,
  autoQuitOnFailure = false,
  teamNumber = 1740,
  printOnFailure = true,
  printOnSuccess = true,
}

-- LSP diagnostics signs configuration
vim.fn.sign_define('LspDiagnosticsSignError', { text = '✘', texthl = 'LspDiagnosticsSignError', linehl = '', numhl = '' })
vim.fn.sign_define('LspDiagnosticsSignWarning', { text = '⚠', texthl = 'LspDiagnosticsSignWarning', linehl = '', numhl = '' })
vim.fn.sign_define('LspDiagnosticsSignInformation', { text = 'ℹ', texthl = 'LspDiagnosticsSignInformation', linehl = '', numhl = '' })
vim.fn.sign_define('LspDiagnosticsSignHint', { text = '➤', texthl = 'LspDiagnosticsSignHint', linehl = '', numhl = '' })

  -- Set up nvim-cmp.
  local cmp = require'cmp'

  cmp.setup({
    snippet = {
      -- REQUIRED - you must specify a snippet engine
      expand = function(args)
        vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
      end,
    },
    window = {
      -- completion = cmp.config.window.bordered(),
      -- documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.abort(),
      ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    }),
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'vsnip' }, -- For vsnip users.
      }, {
      { name = 'buffer' },
    })
  })

  -- Set configuration for specific filetype.
  cmp.setup.filetype('gitcommit', {
    sources = cmp.config.sources({
      { name = 'git' }, -- You can specify the `git` source if [you were installed it](https://github.com/petertriho/cmp-git).
    }, {
      { name = 'buffer' },
    })
  })

  -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = 'buffer' }
    }
  })

  -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = 'path' }
    }, {
      { name = 'cmdline' }
    })
  })
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  
  local lspconfig = require('lspconfig')
  lspconfig.jdtls.setup {
    capabilities = capabilities,
    on_attach = function(client, bufnr)
        -- Your additional customizations for attaching the LSP client
    end,
}

-- Treesitter setup
require'nvim-treesitter.configs'.setup {
    enable = true,
    -- Other treesitter configurations as needed
}
```
