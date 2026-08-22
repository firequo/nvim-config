require("asa")

vim.g.mapleader = " "
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldtext = ""

-- function JavaFoldText()
--     local fold_start = vim.v.foldstart
--     local fold_end = vim.v.foldend
--     local line = vim.api.nvim_buf_get_lines(0, fold_start - 1, fold_start, false)[1]
--     if line:match("^%s*@") then
--         line = vim.api.nvim_buf_get_lines(0, fold_start, fold_start + 1, false)[1]
--     end
--     local lines_count = fold_end - fold_start + 1
--     return line .. "  ... (" .. lines_count .. " lines)"
-- end

_G.JavaFoldText = function()
  local fs = vim.v.foldstart
  local fe = vim.v.foldend
  local buf = vim.api.nvim_get_current_buf()

  -- Safely pull the initial line string
  local first_line_table = vim.api.nvim_buf_get_lines(buf, fs - 1, fs, false)
  local first_line = first_line_table[1] or ""
  local target_line_idx = fs - 1 -- Convert to 0-index for buffer API calls

  -- If the first line is an annotation, scan forward for the signature row
  if first_line:match("^%s*@") then
    for i = fs, fe - 1 do
      local next_line_table = vim.api.nvim_buf_get_lines(buf, i, i + 1, false)
      local next_line = next_line_table[1] or ""
      
      -- Match visibility modifiers or method declaration identifiers
      if next_line:match("public") or next_line:match("private") or next_line:match("protected") or next_line:match("%(") then
        target_line_idx = i
        break
      end
    end
  end

  -- Get the chosen string line text
  local target_line_table = vim.api.nvim_buf_get_lines(buf, target_line_idx, target_line_idx + 1, false)
  local line_text = target_line_table[1] or ""

  -- Initialize an empty container for our highlight tuples
  local result = {}
  
  -- Use Neovim's core parser to extract tokens from the chosen signature line
  local highlighter = vim.treesitter.highlighter.active[buf]
  if highlighter then
    local line_len = #line_text
    local col = 0
    while col < line_len do
      local ok, captures = pcall(vim.treesitter.get_captures_at_pos, buf, target_line_idx, col)
      local hl_group = "Folded"
      
      -- If captures are found, translate the highest priority capture to an @ keyword group
      if ok and captures and #captures > 0 then
        hl_group = "@" .. captures[#captures].capture
      end
      
      -- Consume matching continuous token blocks to keep execution lightweight
      local next_col = col + 1
      while next_col < line_len do
        local ok_next, next_captures = pcall(vim.treesitter.get_captures_at_pos, buf, target_line_idx, next_col)
        local next_hl = (ok_next and next_captures and #next_captures > 0) and ("@" .. next_captures[#next_captures].capture) or "Folded"
        if next_hl ~= hl_group then break end
        next_col = next_col + 1
      end
      
      -- Format and insert the parsed visual chunk
      local chunk_text = string.sub(line_text, col + 1, next_col)
      table.insert(result, { chunk_text, hl_group })
      col = next_col
    end
  else
    -- Fallback safety measure if Tree-sitter isn't ready on buffer init
    table.insert(result, { line_text, "Folded" })
  end

  -- Append a clean line count block using the Comment highlight group
  local lines_count = fe - fs + 1
  table.insert(result, { "    (" .. lines_count .. " lines) ", "Comment" })
  
  return result
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWinEnter" }, {
  pattern = "*.java",
  callback = function(args)
    local buf = args.buf

    -- Assign fold options
    vim.opt_local.foldmethod = "expr"
    vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.opt_local.foldtext = "v:lua.JavaFoldText()"

    -- Force Tree-sitter to parse synchronously immediately
    local ok, parser = pcall(vim.treesitter.get_parser, buf)
    if ok and parser then
      parser:parse(true)
    end

    -- Defer recalculation to give the window engine time to settle
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_get_current_buf() == buf then
        vim.cmd("silent! normal! zx")
      end
    end, 80)
  end,
})

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWinEnter" }, {
  pattern = "*.zig",
  callback = function(args)
    local buf = args.buf

    -- Force Tree-sitter to parse synchronously immediately
    local ok, parser = pcall(vim.treesitter.get_parser, buf)
    if ok and parser then
      parser:parse(true)
    end

    -- Defer recalculation to give the window engine time to settle
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_get_current_buf() == buf then
        vim.cmd("silent! normal! zx")
      end
    end, 80)
  end,
})

-- vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
--   pattern = "java",
--   callback = function()
--     -- Small defer prevents LazyVim's default setup scripts from resetting it
--     vim.schedule(function()
--       vim.opt_local.foldtext = "v:lua.JavaFoldText()"
--       vim.opt_local.foldnestmax = 2
--     end)
--   end,
-- })
-- vim.api.nvim_create_autocmd({'BufWinLeave'}, {
--   pattern = {"*.*"},
--   desc = "save view (folds), when closing file",
--   command = "mkview",
-- })
-- vim.api.nvim_create_autocmd({"BufWinEnter"}, {
--   pattern = {"*.*"},
--   desc = "load view (folds), when opening file",
--   command = "silent! loadview"
-- })

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup(
{
{ 'nvim-mini/mini.files', version = false },
{ 'nvim-mini/mini.pick', version = false },
{"shortcuts/no-neck-pain.nvim", version = "*"},
{
    "bluz71/vim-moonfly-colors",
    name = "moonfly",
    lazy = false,
    priority = 1000,
    config = function()
        -- load the colorscheme here
        vim.cmd [[colorscheme moonfly]]
    end,
},
{
    -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
        'nvim-treesitter/nvim-treesitter-textobjects',
    },
    build = ':TSUpdate',
},
{
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" }
},
{
    -- Autocompletion
    'hrsh7th/nvim-cmp',
    dependencies = {
        -- Snippet Engine & its associated nvim-cmp source
        'L3MON4D3/LuaSnip',
        'saadparwaiz1/cmp_luasnip',

        -- Adds LSP completion capabilities
        'hrsh7th/cmp-nvim-lsp',
        'hrsh7th/cmp-path',
    },
},
{
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
   -- "debugloop/telescope-undo.nvim",
  },
  config = function()
    require("telescope").setup({
      -- the rest of your telescope config goes here
      extensions = {
        -- other extensions:
        -- file_browser = { ... }
      },
    })
  end,
},
{
  "jiaoshijie/undotree",
  dependencies = "nvim-lua/plenary.nvim",
  config = true,
  keys = { -- load the plugin only when using it's keybinding:
    { "<leader>u", "<cmd>lua require('undotree').toggle()<cr>" },
  },
},
  {
    -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  {
    -- Main LSP Configuration
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for Neovim
      -- Mason must be loaded before its dependents so we need to set it up here.
      -- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
      { 'mason-org/mason.nvim', opts = {} },
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      -- Useful status updates for LSP.
      { 'j-hui/fidget.nvim', opts = {} },

      -- Allows extra capabilities provided by blink.cmp
      'saghen/blink.cmp',
    },
    config = function()
      -- Brief aside: **What is LSP?**
      --
      -- LSP is an initialism you've probably heard, but might not understand what it is.
      --
      -- LSP stands for Language Server Protocol. It's a protocol that helps editors
      -- and language tooling communicate in a standardized fashion.
      --
      -- In general, you have a "server" which is some tool built to understand a particular
      -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
      -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
      -- processes that communicate with some "client" - in this case, Neovim!
      --
      -- LSP provides Neovim with features like:
      --  - Go to definition
      --  - Find references
      --  - Autocompletion
      --  - Symbol Search
      --  - and more!
      --
      -- Thus, Language Servers are external tools that must be installed separately from
      -- Neovim. This is where `mason` and related plugins come into play.
      --
      -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
      -- and elegantly composed help section, `:help lsp-vs-treesitter`

      --  This function gets run when an LSP attaches to a particular buffer.
      --    That is to say, every time a new file is opened that is associated with
      --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
      --    function will be executed to configure the current buffer
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          -- NOTE: Remember that Lua is a real programming language, and as such it is possible
          -- to define small helper and utility functions so you don't have to repeat yourself.
          --
          -- In this case, we create a function that lets us more easily define mappings specific
          -- for LSP related items. It sets the mode, buffer and description for us each time.
                        --
    local nmap = function(keys, func, desc)
        if desc then
            desc = 'LSP: ' .. desc
        end

        vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
    end

    nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
    nmap('<leader>ca', function()
        vim.lsp.buf.code_action { context = { only = { 'quickfix', 'refactor', 'source' } } }
    end, '[C]ode [A]ction')

    nmap('<leader>rt', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
    nmap('<leader>rs', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
    nmap('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
    nmap('<leader>wt', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
    nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
    nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

    -- See `:help K` for why this keymap
    nmap('<leader>i', vim.lsp.buf.hover, 'Hover Documentation')
    nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

    -- Lesser used LSP functionality
    nmap('<leader>gT', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
    nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
    nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
    nmap('<leader>wl', function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, '[W]orkspace [L]ist Folders')

          -- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
          ---@param client vim.lsp.Client
          ---@param method vim.lsp.protocol.Method
          ---@param bufnr? integer some lsp support methods only in specific files
          ---@return boolean
          local function client_supports_method(client, method, bufnr)
            if vim.fn.has 'nvim-0.11' == 1 then
              return client:supports_method(method, bufnr)
            else
              return client.supports_method(method, { bufnr = bufnr })
            end
          end

          -- The following two autocommands are used to highlight references of the
          -- word under your cursor when your cursor rests there for a little while.
          --    See `:help CursorHold` for information about when this is executed
          --
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          -- The following code creates a keymap to toggle inlay hints in your
          -- code, if the language server you are using supports them
          --
          -- This may be unwanted, since they displace some of your code
          if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
            nmap('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      -- Diagnostic Config
      -- See :help vim.diagnostic.Opts
      vim.diagnostic.config {
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many' },
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN] = '󰀪 ',
            [vim.diagnostic.severity.INFO] = '󰋽 ',
            [vim.diagnostic.severity.HINT] = '󰌶 ',
          },
        } or {},
        virtual_text = {
          source = 'if_many',
          spacing = 2,
          format = function(diagnostic)
            local diagnostic_message = {
              [vim.diagnostic.severity.ERROR] = diagnostic.message,
              [vim.diagnostic.severity.WARN] = diagnostic.message,
              [vim.diagnostic.severity.INFO] = diagnostic.message,
              [vim.diagnostic.severity.HINT] = diagnostic.message,
            }
            return diagnostic_message[diagnostic.severity]
          end,
        },
      }

      -- LSP servers and clients are able to communicate to each other what features they support.
      --  By default, Neovim doesn't support everything that is in the LSP specification.
      --  When you add blink.cmp, luasnip, etc. Neovim now has *more* capabilities.
      --  So, we create new capabilities with blink.cmp, and then broadcast that to the servers.
      local capabilities = require('blink.cmp').get_lsp_capabilities()

      -- Enable the following language servers
      --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
      --
      --  Add any additional override configuration in the following tables. Available keys are:
      --  - cmd (table): Override the default command used to start the server
      --  - filetypes (table): Override the default list of associated filetypes for the server
      --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
      --  - settings (table): Override the default settings passed when initializing the server.
      --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
      local servers = {
        -- clangd = {},
        -- gopls = {},
        -- pyright = {},
        -- rust_analyzer = {},
        -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
        --
        -- Some languages (like typescript) have entire language plugins that can be useful:
        --    https://github.com/pmizio/typescript-tools.nvim
        --
        -- But for many setups, the LSP (`ts_ls`) will work just fine
        -- ts_ls = {},
        --

        lua_ls = {
          -- cmd = { ... },
          -- filetypes = { ... },
          -- capabilities = {},
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
              -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
              -- diagnostics = { disable = { 'missing-fields' } },
            },
          },
        },
      }

      -- Ensure the servers and tools above are installed
      --
      -- To check the current status of installed tools and/or manually install
      -- other tools, you can run
      --    :Mason
      --
      -- You can press `g?` for help in this menu.
      --
      -- `mason` had to be setup earlier: to configure its options see the
      -- `dependencies` table for `nvim-lspconfig` above.
      --
      -- You can add other tools here that you want Mason to install
      -- for you, so that they are available from within Neovim.
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        'stylua', -- Used to format Lua code
      })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      require('mason-lspconfig').setup {
        ensure_installed = {}, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
        automatic_installation = false,
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            -- This handles overriding only values explicitly passed
            -- by the server configuration above. Useful when disabling
            -- certain features of an LSP (for example, turning off formatting for ts_ls)
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            require('lspconfig')[server_name].setup(server)
          end,
        },
      }
    end,
  },
}, {})
vim.defer_fn(function()
    require('nvim-treesitter.configs').setup {
        -- Add languages to be installed here that you want installed for treesitter
        ensure_installed = { 'java', 'lua' },

        -- Autoinstall languages that are not installed. Defaults to false (but you can change for yourself!)
        auto_install = false,
        -- Install languages synchronously (only applied to `ensure_installed`)
        sync_install = false,
        -- List of parsers to ignore installing
        ignore_install = {},
        -- You can specify additional Treesitter modules here: -- For example: -- playground = {--enable = true,-- },
        modules = {},
        highlight = { enable = true },
        indent = { enable = true },
        incremental_selection = {
            enable = true,
            keymaps = {
                init_selection = '<c-space>',
                node_incremental = '<c-space>',
                scope_incremental = '<c-s>',
                node_decremental = '<M-space>',
            },
        },
        textobjects = {
            select = {
                enable = true,
                lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
                keymaps = {
                    -- You can use the capture groups defined in textobjects.scm
                    ['aa'] = '@parameter.outer',
                    ['ia'] = '@parameter.inner',
                    ['af'] = '@function.outer',
                    ['if'] = '@function.inner',
                    ['ac'] = '@class.outer',
                    ['ic'] = '@class.inner',
                },
            },
            swap = {
                enable = true,
                swap_next = {
                    ['<leader>r'] = '@parameter.inner',
                },
                swap_previous = {
                    ['<leader>R'] = '@parameter.inner',
                },
            },
            move = {
                enable = true,
                set_jumps = true, -- whether to set jumps in the jumplist
                goto_next_start = {
                    [']m'] = '@function.outer',
                    [']]'] = '@class.outer',
                },
                goto_next_end = {
                    [']M'] = '@function.outer',
                    [']['] = '@class.outer',
                },
                goto_previous_start = {
                    ['[m'] = '@function.outer',
                    ['[['] = '@class.outer',
                },
                goto_previous_end = {
                    ['[M'] = '@function.outer',
                    ['[]'] = '@class.outer',
                },
            },
        },
    }
end, 0)

local nmap_leader = function(suffix, rhs, desc)
  vim.keymap.set('n', '<Leader>' .. suffix, rhs, { desc = desc })
end

require('mini.files').setup(
    {
        mappings = {
            go_in_plus = '<CR>',
            go_out = '-',
        }
    }
)
require('mini.pick').setup()
vim.api.nvim_set_hl(0, 'MiniPickMatchCurrent', { bg = '#ffffff', fg = '#000000', bold = true })
vim.o.ignorecase = true
require("no-neck-pain").setup({
    autocmds = {
        enableOnVimEnter = true,
    },
    buffers = {
        scratchPad = {
            -- set to `false` to
            -- disable auto-saving
            enabled = true,
            -- set to `nil` to default 
            -- to current working directory
            location = nil;
        },
        bo = {
            filetype = "md"
        },
        right = {
            enabled = false,
        },
    },
})


local explore_at_file = '<Cmd>lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<CR>'
local explore_quickfix = function()
  vim.cmd(vim.fn.getqflist({ winid = true }).winid ~= 0 and 'cclose' or 'copen')
end

local function live_filename_grep()
  local last_query = nil

  MiniPick.start({
    source = {
      name = 'Ripgrep (Filenames Only)',
      items = {},
      match = function(items, indices, query)
        local pattern = table.concat(query)

        -- If query hasn't changed, set_picker_items() triggered this match.
        -- Return indices to display ripgrep's matches.
        if pattern == last_query then
          return indices
        end
        last_query = pattern

        if pattern == '' then
          MiniPick.set_picker_items({})
          return {}
        end

        MiniPick.set_picker_items_from_cli({
          'rg',
          '-l',
          '-i',
          pattern,
        }, {
          set_opts = { querytick = MiniPick.get_querytick() },
        })

        return {}
      end,
      show = function(buf_id, items, query)
        MiniPick.default_show(buf_id, items, query, { show_icons = true })
      end,
    },
  })
end

nmap_leader('ff', explore_at_file,                              'File directory')
nmap_leader('fl', explore_quickfix,                             'Quickfix list')
nmap_leader('lf', '<Cmd>Pick files<CR>',                        'Files');
nmap_leader('lg', '<Cmd>Pick grep_live<CR>',                    'Grep live')
nmap_leader('lb', live_filename_grep,                               'Grep filenames')


-- 1. Persistent queue to hold selected file paths
local file_queue = {}
local done_file_queue = {}

-- 2. Helper function to capture marked or highlighted items from an active picker
local function add_to_queue()
  local matches = MiniPick.get_picker_matches()
  if not matches then return end

  -- Priority: process all marked items first; if none are marked, process the current item
  local items_to_add = {}
  if matches.marked and #matches.marked > 0 then
    items_to_add = matches.marked
  elseif matches.current then
    items_to_add = { matches.current }
  end

  if #items_to_add == 0 then return end

  -- Append to queue while preventing duplicate paths
  local added_count = 0
  for _, item in ipairs(items_to_add) do
    if not vim.tbl_contains(file_queue, item) then
      table.insert(file_queue, item)
      added_count = added_count + 1
    end
  end

  vim.notify(string.format("Queued %d file(s). Total in queue: %d", added_count, #file_queue))
end

-- 3. Secondary picker for the queue
local function open_queue_picker()
  if #file_queue == 0 then
    vim.notify("File queue is empty!", vim.log.levels.WARN)
    return
  end

  MiniPick.start({
    source = {
      name = string.format('Queued Files (%d)', #file_queue),
      items = file_queue,
      show = function(buf_id, items, query)
        MiniPick.default_show(buf_id, items, query, { show_icons = true })
      end,
      -- Custom choose handler for single selection (<CR>)
      choose = function(item)
        if not item then return end

        for i, queued_path in ipairs(file_queue) do
          if queued_path == item then
            table.remove(file_queue, i)
              if not vim.tbl_contains(done_file_queue, queued_path) then
                table.insert(done_file_queue, queued_path)
              end
            break
          end
        end

        MiniPick.default_choose(item)
      end,
      -- Custom choose handler for marked items (<M-a>)
      choose_marked = function(items)
        if not items then return end

        for _, item in ipairs(items) do
          for i, queued_path in ipairs(file_queue) do
            if queued_path == item then
              table.remove(file_queue, i)
              if not vim.tbl_contains(done_file_queue, queued_path) then
                table.insert(done_file_queue, queued_path)
              end
              break
            end
          end
        end

        MiniPick.default_choose_marked(items)
      end,
    },
  })
end
local open_done_picker = function ()
  if #done_file_queue == 0 then
    vim.notify("Done file queue is empty!", vim.log.levels.WARN)
    return
  end

  MiniPick.start({
    source = {
      name = string.format('Used Queued Files (%d)', #done_file_queue),
      items = done_file_queue,
    }})
end

local clear_done_list = function ()
    done_file_queue = {}
end
-- 4. Register custom keymap inside mini.pick
MiniPick.setup({
  mappings = {
    -- Press <C-s> while inside ANY mini.pick window to queue items
    add_to_queue = {
      char = '<C-s>',
      func = add_to_queue,
    },
    clear_done_list = {
      char = '<C-z>',
      func = clear_done_list,
    },
  },
})

-- 5. Hotkey to open the queue picker
vim.keymap.set('n', '<leader>lq', open_queue_picker, { desc = 'Open queued files picker' })
vim.keymap.set('n', '<leader>ld', open_done_picker, { desc = 'Open done files picker' })



nmap_leader('ic', '<Cmd>NoNeckPain<CR>',                        'no neck pain lhs');

nmap_leader('be', '<Cmd>bn<CR>',                                'next buf');
nmap_leader('bn', '<Cmd>bp<CR>',                                'prev buf');

nmap_leader('si', 'gg?import <CR><Down>',                             'skip imports');
local widths = { 60, 20, 10 }

local ensure_center_layout = function(ev)
    local state = MiniFiles.get_explorer_state()
    if state == nil then return end

    -- Compute "depth offset" - how many windows are between this and focused
    local path_this = vim.api.nvim_buf_get_name(ev.data.buf_id):match('^minifiles://%d+/(.*)$')
    local depth_this
    for i, path in ipairs(state.branch) do
        if path == path_this then depth_this = i end
    end
    if depth_this == nil then return end
    local depth_offset = depth_this - state.depth_focus

    -- Adjust config of this event's window
    local i = math.abs(depth_offset) + 1
    local win_config = vim.api.nvim_win_get_config(ev.data.win_id)
    win_config.width = i <= #widths and widths[i] or widths[#widths]

    win_config.col = math.floor(0.5 * (vim.o.columns - widths[1]))
    for j = 1, math.abs(depth_offset) do
        local sign = depth_offset == 0 and 0 or (depth_offset > 0 and 1 or -1)
        -- widths[j+1] for the negative case because we don't want to add the center window's width 
        local prev_win_width = (sign == -1 and widths[j+1]) or widths[j] or widths[#widths]
        -- Add an extra +2 each step to account for the border width
        win_config.col = win_config.col + sign * (prev_win_width + 2)
    end

    win_config.height = depth_offset == 0 and 25 or 20
    win_config.row = math.floor(0.5 * (vim.o.lines - win_config.height))
    win_config.border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" }
    vim.api.nvim_win_set_config(ev.data.win_id, win_config)
end

vim.api.nvim_create_autocmd("User", { pattern = 'MiniFilesWindowUpdate', callback = ensure_center_layout })


-- [[ Configure LSP ]]
--  This function gets run when an LSP connects to a particular buffer.
local on_attach = function(_, bufnr)
    -- NOTE: Remember that lua is a real programming language, and as such it is possible
    -- to define small helper and utility functions so you don't have to repeat yourself
    -- many times.
    --
    -- In this case, we create a function that lets us more easily define mappings specific
    -- for LSP related items. It sets the mode, buffer and description for us each time.
    local nmap = function(keys, func, desc)
        if desc then
            desc = 'LSP: ' .. desc
        end

        vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
    end

    nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
    nmap('<leader>ca', function()
        vim.lsp.buf.code_action { context = { only = { 'quickfix', 'refactor', 'source' } } }
    end, '[C]ode [A]ction')

    nmap('<leader>rt', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
    nmap('<leader>rs', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
    nmap('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
    nmap('<leader>wt', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
    nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
    nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

    -- See `:help K` for why this keymap
    nmap('<leader>i', vim.lsp.buf.hover, 'Hover Documentation')
    nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

    -- Lesser used LSP functionality
    nmap('<leader>gT', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
    nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
    nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
    nmap('<leader>wl', function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, '[W]orkspace [L]ist Folders')

    -- Create a command `:Format` local to the LSP buffer
    vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
        vim.lsp.buf.format()
    end, { desc = 'Format current buffer with LSP' })
end

-- mason-lspconfig requires that these setup functions are called in this order
-- before setting up the servers.
require('mason').setup()
require('mason-lspconfig').setup()

-- Enable the following language servers
--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
--
--  Add any additional override configuration in the following tables. They will be passed to
--  the `settings` field of the server config. You must look up that documentation yourself.
--
--  If you want to override the default filetypes that your language server will attach to you can
--  define the property 'filetypes' to the map in question.
local servers = {
    -- clangd = {},
    -- gopls = {},
    -- pyright = {},
    -- rust_analyzer = {},
    -- tsserver = {},
    -- html = { filetypes = { 'html', 'twig', 'hbs'} },
    -- java_language_server = {},

    lua_ls = {
        Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
            -- NOTE: toggle below to ignore Lua_LS's noisy `missing-fields` warnings
            -- diagnostics = { disable = { 'missing-fields' } },
        },
    },
}

-- Setup neovim lua configuration


-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- Ensure the servers above are installed
--
vim.lsp.enable('zls')
vim.lsp.config('zls', {on_attach = on_attach})
-- [[ Configure nvim-cmp ]]
-- See `:help cmp`
local cmp = require 'cmp'
local luasnip = require 'luasnip'
require('luasnip.loaders.from_vscode').lazy_load()
luasnip.config.setup {}

cmp.setup {
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end,
    },
    completion = {
        completeopt = 'menu,menuone,noinsert',
    },
    mapping = cmp.mapping.preset.insert {
        ['<C-n>'] = cmp.mapping.select_next_item(),
        ['<C-e>'] = cmp.mapping.select_prev_item(),
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete {},
        ['<C-y>'] = cmp.mapping.confirm {
            behavior = cmp.ConfirmBehavior.Insert,
            select = true,
        },
        ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
                luasnip.expand_or_jump()
            else
                fallback()
            end
        end, { 'i', 's' }),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            elseif luasnip.locally_jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, { 'i', 's' }),
    },
    sources = {
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
        { name = 'path' },
    },
}
local harpoon = require("harpoon")

-- REQUIRED
harpoon:setup()
-- REQUIRED

vim.keymap.set("n", "<leader>a",  function() harpoon:list():add() end)
vim.keymap.set("n", "<C-u>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

vim.keymap.set("n", "<C-n>", function() harpoon:list():select(1) end)
vim.keymap.set("n", "<C-e>", function() harpoon:list():select(2) end)
vim.keymap.set("n", "<C-i>", function() harpoon:list():select(3) end)
vim.keymap.set("n", "<C-o>", function() harpoon:list():select(4) end)

-- Toggle previous & next buffers stored within Harpoon list
vim.keymap.set("n", "<C-S-Q>", function() harpoon:list():prev() end)
vim.keymap.set("n", "<C-S-W>", function() harpoon:list():next() end)


require('undotree').setup()
