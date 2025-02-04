{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    package = pkgs.unstable.neovim-unwrapped;
    withNodeJs = false;
    withPython3 = false;
    withRuby = false;

    extraPackages = with pkgs; [
      gopls
      lua-language-server
      nil
      nixfmt-rfc-style
      pyright
      ruff
    ];

    plugins = with pkgs.vimPlugins; [
      {
        plugin = catppuccin-nvim;
        type = "lua";
        config = # lua
          ''
            do
              require("catppuccin").setup({
                background = {
                  light = "latte",
                  dark = "macchiato",
                },
              })
              vim.cmd.colorscheme("catppuccin")
            end
          '';
      }
      {
        plugin = lualine-nvim;
        type = "lua";
        config = # lua
          ''
            do
              require("lualine").setup({
                options = {
                  theme = "catppuccin",
                },
                sections = {
                  lualine_x = { "filetype" },
                },
              })
            end
          '';
      }
      {
        plugin = nvim-treesitter.withAllGrammars;
        type = "lua";
        config = # lua
          ''
            do
              require("nvim-treesitter.configs").setup({
                highlight = { enable = true },
                indent = { enable = true },
              })
            end
          '';
      }
      {
        plugin = nvim-lspconfig;
        type = "lua";
        config = # lua
          ''
            do
              local lspconfig = require("lspconfig")
              lspconfig.gopls.setup({})
              lspconfig.lua_ls.setup({
                settings = {
                  Lua = {
                    diagnostics = {
                      globals = {
                        "vim",
                      },
                    },
                  },
                },
              })
              lspconfig.nil_ls.setup({
                settings = {
                  ["nil"] = {
                    formatting = { command = { "nixfmt" } },
                  },
                },
              })
              lspconfig.pyright.setup({
                settings = {
                  pyright = {
                    -- Using Ruff's import organizer.
                    disableOrganizeImports = true,
                  },
                  python = {
                    analysis = {
                      -- Ignore all files for analysis to exclusively use Ruff for linting.
                      ignore = { "*" },
                    },
                  },
                },
              })
              lspconfig.ruff.setup({})

              vim.api.nvim_create_autocmd({ "LspAttach" }, {
                desc = "Configure LSP keymaps",
                group = vim.api.nvim_create_augroup("lsp", { clear = true }),
                callback = function(args)
                  local opts = { buffer = args.buf, noremap = true, silent = true }

                  -- Trigger code completion
                  vim.keymap.set("i", "<C-Space>", "<C-x><C-o>", opts)

                  -- Display a function's signature
                  vim.keymap.set("n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<cr>", opts)

                  -- Rename all references
                  vim.keymap.set("n", "grn", "<cmd>lua vim.lsp.buf.rename()<cr>", opts)

                  -- Format file
                  vim.keymap.set("n", "grf", "<cmd>lua vim.lsp.buf.format()<cr>", opts)

                  -- Select a code action
                  vim.keymap.set("n", "gra", "<cmd>lua vim.lsp.buf.code_action()<cr>", opts)

                  -- The following is done using telescope.nvim.
                  -- List references
                  -- vim.keymap.set("n", "grr", "<cmd>lua vim.lsp.buf.references()<cr>", opts)

                  -- Go to definition
                  -- vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", opts)

                  -- List implementations
                  -- vim.keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<cr>", opts)

                  -- Go to type definition
                  -- vim.keymap.set("n", "go", "<cmd>lua vim.lsp.buf.type_definition()<cr>", opts)
                end,
              })
            end
          '';
      }
      {
        plugin = nvim-web-devicons;
        type = "lua";
        config = # lua
          ''
            do
              require("nvim-web-devicons").setup()
            end
          '';
      }
      {
        plugin = nvim-tree-lua;
        type = "lua";
        config = # lua
          ''
            do
              local height_ratio = 0.8
              local width_ratio = 0.5

              require("nvim-tree").setup({
                update_focused_file = { enable = true },
                view = {
                  float = {
                    enable = true,
                    open_win_config = function()
                      local screen_w = vim.opt.columns:get()
                      local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()

                      local window_w = screen_w * width_ratio
                      local window_h = screen_h * height_ratio

                      local window_w_int = math.floor(window_w)
                      local window_h_int = math.floor(window_h)

                      local center_x = (screen_w - window_w) / 2
                      local center_y = ((vim.opt.lines:get() - window_h) / 2) - vim.opt.cmdheight:get()

                      return {
                        border = "rounded",
                        relative = "editor",
                        row = center_y,
                        col = center_x,
                        width = window_w_int,
                        height = window_h_int,
                      }
                    end,
                  },
                  width = function()
                    return math.floor(vim.opt.columns:get() * width_ratio)
                  end,
                },
                on_attach = function(bufnr)
                  local api = require("nvim-tree.api")
                  local opts = { buffer = bufnr, noremap = true, silent = true, nowait = true }

                  local function edit_or_open()
                    local node = api.tree.get_node_under_cursor()
                    api.node.open.edit()
                    if node.nodes == nil then
                      api.tree.close()
                    end
                  end

                  local function vsplit_preview()
                    local node = api.tree.get_node_under_cursor()
                    if node.nodes == nil then
                      api.node.open.vertical()
                    else
                      api.node.open.edit()
                    end
                    api.tree.focus()
                  end

                  api.config.mappings.default_on_attach(bufnr)
                  vim.keymap.set("n", "l", edit_or_open, opts)
                  vim.keymap.set("n", "L", vsplit_preview, opts)
                  vim.keymap.set("n", "h", api.node.navigate.parent_close, opts)
                  vim.keymap.set("n", "H", api.tree.collapse_all, opts)
                end,
              })

              vim.api.nvim_set_keymap("n", "<C-h>", "<cmd>NvimTreeToggle<cr>", { silent = true, noremap = true })
            end
          '';
      }
      {
        plugin = telescope-fzf-native-nvim;
        type = "lua";
      }
      {
        plugin = telescope-nvim;
        type = "lua";
        config = # lua
          ''
            do
              local telescope = require("telescope.builtin")
              local opts = { noremap = true, silent = true }

              vim.keymap.set("n", "<C-p>", telescope.find_files, opts)
              vim.keymap.set("n", "<C-S-p>", telescope.live_grep, opts)
              vim.keymap.set("n", "<C-b>", telescope.buffers, opts)

              vim.keymap.set("n", "grr", telescope.lsp_references, opts)
              vim.keymap.set("n", "gd", function()
                telescope.lsp_definitions({ reuse_win = true })
              end, opts)
              vim.keymap.set("n", "gi", function()
                telescope.lsp_implementations({ reuse_win = true })
              end, opts)
              vim.keymap.set("n", "go", function()
                telescope.lsp_type_definitions({ reuse_win = true })
              end, opts)

              require("telescope").load_extension("fzf");
            end
          '';
      }
    ];

    extraLuaConfig = # lua
      ''
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1
        vim.g.mapleader = ","

        vim.opt.tabstop = 2
        vim.opt.softtabstop = 2
        vim.opt.shiftwidth = 2
        vim.opt.expandtab = true
        vim.opt.breakindent = true

        vim.opt.shortmess:append({ I = true })
        vim.opt.splitbelow = true
        vim.opt.splitright = true
        vim.opt.termguicolors = true

        vim.opt.backup = false
        vim.opt.swapfile = false

        vim.opt.cursorline = true
        vim.opt.scrolloff = 3
        vim.opt.number = true
        vim.opt.relativenumber = true
        vim.opt.wildmode = { "longest:full", "full" }
        vim.opt.showmode = false

        vim.opt.ignorecase = true
        vim.opt.smartcase = true

        vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { noremap = true })
        vim.keymap.set("n", "[q", "<cmd>cprevious<cr>", { noremap = true })
        vim.keymap.set("n", "]q", "<cmd>cnext<cr>", { noremap = true })
        vim.keymap.set("n", "[Q", "<cmd>cfirst<cr>", { noremap = true })
        vim.keymap.set("n", "]Q", "<cmd>clast<cr>", { noremap = true })

        vim.api.nvim_create_autocmd({ "FileType" }, {
          desc = "Go settings",
          pattern = "go",
          group = vim.api.nvim_create_augroup("golang", { clear = true }),
          callback = function(args)
            vim.opt_local.expandtab = false
            vim.opt_local.makeprg = "go build"
          end,
        })

        vim.api.nvim_create_autocmd({ "FileType" }, {
          desc = "Indent to 4 spaces",
          pattern = { "go", "python" },
          group = vim.api.nvim_create_augroup("indentmore", { clear = true }),
          callback = function()
            vim.opt_local.tabstop = 4
            vim.opt_local.softtabstop = 4
            vim.opt_local.shiftwidth = 4
          end,
        })

        vim.api.nvim_create_autocmd({ "FileType" }, {
          desc = "Plaintext settings",
          pattern = { "markdown", "text" },
          group = vim.api.nvim_create_augroup("plaintext", { clear = true }),
          callback = function()
            vim.opt_local.textwidth = 79
            vim.opt_local.formatoptions:append({ w = true })
            vim.opt_local.tabstop = 2
            vim.opt_local.softtabstop = 2
            vim.opt_local.shiftwidth = 2
          end,
        })
      '';
  };
}
