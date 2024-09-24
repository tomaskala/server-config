{ lib, pkgs, ... }:

{
  home-manager.users.tomas = {
    home.stateVersion = "24.05";

    programs = {
      home-manager.enable = true;

      fzf.enable = true;
      htop.enable = true;
      jq.enable = true;
      ripgrep.enable = true;

      yt-dlp = {
        enable = true;

        settings = {
          mtime = false;
          restrict-filenames = true;
          format = "bestvideo[height<=1080]+bestaudio/best[height<=1080]";
          merge-output-format = "mkv";
        };
      };

      neovim = {
        enable = true;
        package = pkgs.unstable.neovim-unwrapped;
        withNodeJs = false;
        withPython3 = false;
        withRuby = false;

        extraPackages = with pkgs; [
          # TODO: Move this to the work shell.
          biome
          gopls
          lua-language-server
          nil
          nodePackages.typescript-language-server
          pyright
          unstable.ruff
        ];

        plugins = with pkgs.vimPlugins; [
          {
            plugin = catppuccin-nvim;
            type = "lua";
            config = ''
              require("catppuccin").setup({
                background = {
                  light = "latte",
                  dark = "macchiato",
                },
              })
              vim.cmd.colorscheme("catppuccin")
            '';
          }
          {
            plugin = lualine-nvim;
            type = "lua";
            config = ''
              require("lualine").setup({
                options = {
                  theme = "catppuccin",
                },
                sections = {
                  lualine_x = { "filetype" },
                },
              })
            '';
          }
          {
            plugin = nvim-treesitter.withAllGrammars;
            type = "lua";
            config = ''
              require("nvim-treesitter.configs").setup({
                highlight = { enable = true },
                indent = { enable = true },
              })
            '';
          }
          {
            plugin = nvim-lspconfig;
            type = "lua";
            config = ''
              local lspconfig = require("lspconfig")
              lspconfig.biome.setup({})
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
              lspconfig.nil_ls.setup({})
              lspconfig.tsserver.setup({})
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
                  local opts = { buffer = args.buf }

                  -- Trigger code completion
                  vim.keymap.set("i", "<C-Space>", "<C-x><C-o>")

                  -- Go to definition
                  vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>")

                  -- List implementations
                  vim.keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<cr>")

                  -- Go to type definition
                  vim.keymap.set("n", "go", "<cmd>lua vim.lsp.buf.type_definition()<cr>")

                  -- List references
                  vim.keymap.set("n", "grr", "<cmd>lua vim.lsp.buf.references()<cr>")

                  -- Display a function's signature
                  vim.keymap.set("n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<cr>")

                  -- Rename all references
                  vim.keymap.set("n", "grn", "<cmd>lua vim.lsp.buf.rename()<cr>")

                  -- Format file
                  vim.keymap.set("n", "grf", "<cmd>lua vim.lsp.buf.format()<cr>")

                  -- Select a code action
                  vim.keymap.set("n", "gra", "<cmd>lua vim.lsp.buf.code_action()<cr>")
                end,
              })
            '';
          }
        ];

        extraLuaConfig = ''
          vim.g.mapleader = ","

          vim.opt.path = "**"
          vim.opt.fileformat = "unix"
          vim.opt.ttimeoutlen = 0

          vim.opt.shortmess:append({ I = true })
          vim.opt.tabstop = 2
          vim.opt.softtabstop = 2
          vim.opt.shiftwidth = 2
          vim.opt.expandtab = true

          vim.opt.termguicolors = true
          vim.opt.splitbelow = true
          vim.opt.splitright = true
          vim.opt.backup = false
          vim.opt.swapfile = false
          vim.opt.cpoptions:remove("a")

          vim.opt.cursorline = true
          vim.opt.scrolloff = 3
          vim.opt.colorcolumn = { 80 }
          vim.opt.number = true
          vim.opt.relativenumber = true
          vim.opt.wildmode = { "longest:full", "full" }

          vim.opt.ignorecase = true
          vim.opt.smartcase = true

          vim.opt.cinoptions = { "t0", "l1", ":0" }
          vim.opt.cinkeys:remove("0#")

          vim.g.netrw_banner = 0
          vim.g.netrw_winsize = 25

          vim.keymap.set("n", "<leader><space>", ":nohlsearch<CR>", { noremap = true })
          vim.keymap.set("n", "[q", ":cprevious<CR>", { noremap = true })
          vim.keymap.set("n", "]q", ":cnext<CR>", { noremap = true })
          vim.keymap.set("n", "[Q", ":cfirst<CR>", { noremap = true })
          vim.keymap.set("n", "]Q", ":clast<CR>", { noremap = true })

          vim.api.nvim_create_autocmd({ "FileType" }, {
            desc = "Go settings",
            pattern = "go",
            group = vim.api.nvim_create_augroup("golang", { clear = true }),
            callback = function(args)
              vim.opt_local.makeprg = "go build"
              vim.opt_local.expandtab = false
              vim.keymap.set("n", "<leader>f", [[
                :update<CR>
                :cexpr system("goimports -w " . expand("%"))<CR>
                :edit<CR>
              ]], { noremap = true, buffer = args.buf, silent = true })
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

      fish = {
        enable = true;

        interactiveShellInit = ''
          set -gx EMAIL me@tomaskala.com
          set -gx EDITOR nvim
          set -gx SSH_AUTH_SOCK ~/.ssh/agent.sock

          set -gx XDG_CACHE_HOME ~/.cache
          set -gx XDG_CONFIG_HOME ~/.config
          set -gx XDG_DATA_HOME ~/.local/share

          set -gx GOPATH "$XDG_DATA_HOME/go"
          set -gx GOBIN ~/.local/bin
          set -gx GOTOOLCHAIN local

          set -g fish_greeting
          fish_add_path ~/.local/bin
        '';

        functions = {
          diff = "diff --color=auto $argv";
          grep = "grep --color=auto $argv";
          ll = "ls -l $argv";
          lla = "ls -la $argv";
          ls =
            "${pkgs.coreutils}/bin/ls -FNh --color=auto --group-directories-first $argv";
          vim = "nvim $argv";
          ya = "mpv --no-video --ytdl-format=bestaudio $argv";
        };
      };

      starship = {
        enable = true;

        settings = {
          format = lib.concatStrings [
            "$username"
            "$hostname"
            "$directory"
            "$git_branch"
            "$git_state"
            "$git_status"
            "$fill"

            "$c"
            "$docker_context"
            "$fennel"
            "$golang"
            "$haskell"
            "$lua"
            "$nodejs"
            "$python"

            "$status"
            "$line_break"
            "$character"
          ];

          fill.symbol = " ";
          hostname.ssh_symbol = "";
          status.disabled = false;
          username.format = "[$user]($style)@";

          character = {
            success_symbol = "[❯](purple)";
            error_symbol = "[❯](red)";
            vimcmd_symbol = "[❯](green)";
          };

          directory = {
            style = "blue";
            truncate_to_repo = false;
            truncation_length = 5;
            truncation_symbol = ".../";
          };

          git_branch = {
            symbol = " ";
            format = "[$symbol $branch]($style)";
            style = "green";
          };

          git_status = {
            format =
              "[[( $conflicted$untracked$modified$staged$renamed$deleted)](218) ($ahead_behind$stashed)]($style)";
            style = "cyan";
            conflicted = "=$count ";
            untracked = "?$count ";
            modified = "!$count ";
            staged = "+$count ";
            renamed = "»$count ";
            deleted = "✘$count ";
            stashed = "≡";
          };

          git_state = {
            format = "([$state( $progress_current/$progress_total)]($style)) ";
            style = "bright-black";
          };

          c.symbol = " ";
          directory.read_only = " 󰌾";
          docker_context.symbol = " ";
          fennel.symbol = " ";
          golang.symbol = " ";
          haskell.symbol = " ";
          lua.symbol = " ";
          nix_shell.symbol = " ";
          nodejs.symbol = " ";
          package.symbol = "󰏗 ";
          python.symbol = " ";
        };
      };

      git = {
        enable = true;
        lfs.enable = true;

        extraConfig = {
          user = {
            name = "Tomas Kala";
            email = "me@tomaskala.com";
          };

          init.defaultBranch = "master";
          fetch.prune = true;
          pull.ff = "only";

          rebase = {
            autoSquash = true;
            autoStash = true;
          };

          merge = {
            ff = "only";
            conflictStyle = "zdiff3";
          };

          diff.algorithm = "histogram";
        };

        includes = [{
          condition = "gitdir:~/IPFabric/";
          contents.user.email = "tomas.kala@ipfabric.io";
        }];
      };

      tmux = {
        enable = true;
        baseIndex = 1;
        clock24 = true;
        keyMode = "vi";
        mouse = true;
        prefix = "C-s";
        sensibleOnTop = true;

        extraConfig = ''
          set -g  renumber-windows on
          set -gw automatic-rename on
          set -g bell-action none

          bind - split-window -v -c "#{pane_current_path}"
          bind | split-window -h -c "#{pane_current_path}"
        '';
      };
    };
  };
}
