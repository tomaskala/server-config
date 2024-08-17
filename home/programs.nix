{
  # TODO
  home.packages = [ ];

  programs = {
    home-manager.enable = true;

    fzf = {
      enable = true;
      enableZshIntegration = true;
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
    };

    go = {
      enable = true;
      goBin = ".local/bin";
      goPath = ".local/share/go";
    };

    htop.enable = true;
    jq.enable = true;
    less.enable = true;

    mpv = {
      enable = true;

      bindings = {
        "h" = "seek -5; show_progress";
        "j" = "seek -60; show_progress";
        "k" = "seek 60; show_progress";
        "l" = "seek 5; show_progress";
        "S" = "cycle sub";
        "t" = "show_progress";
        "9" = "add volume -5";
        "0" = "add volume 5";
      };

      config = {
        "osd-font-size" = 32;
        "osd-bar-h" = 1;
        "osd-bar-w" = 100;
        "osd-bar-align-y" = 1;
        "af" = "scaletempo";
        "geometry" = "50%:50%";
        "script-opts-append" = "ytdl_hook-ytdl_path=yt-dlp";
        "ytdl-format" =
          "bestvideo[height<=?720][vcodec!=?vp9]+bestaudio/best[height<=?720]";
      };
    };

    neovim = {
      enable = true;
      defaultEditor = true;
      vimAlias = true;

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
          pattern = { "go", "python" },
          group = vim.api.nvim_create_augroup("indentmore", { clear = true }),
          callback = function()
            vim.opt_local.tabstop = 4
            vim.opt_local.softtabstop = 4
            vim.opt_local.shiftwidth = 4
          end,
        })

        vim.api.nvim_create_autocmd({ "FileType" }, {
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

    ripgrep.enable = true;

    # TODO: Take the IP addresses from intranet.
    ssh = {
      enable = true;
      addKeysToAgent = "yes";
      serverAliveInterval = 60;

      matchBlocks = {
        "github.com" = {
          user = "tomaskala";
          identitiesOnly = true;
          identityFile = "~/.ssh/id_ed25519_github";
        };

        "whitelodge" = {
          user = "tomas";
          hostname = "10.100.10.1";
          identitiesOnly = true;
          identityFile = "~/.ssh/id_ed25519_whitelodge";
        };

        "whitelodge-git" = {
          user = "git";
          hostname = "10.100.10.1";
          identitiesOnly = true;
          identityFile = "~/.ssh/id_ed25519_whitelodge_git";
        };

        "bob" = {
          user = "tomas";
          hostname = "10.0.0.2";
          identitiesOnly = true;
          identityFile = "~/.ssh/id_ed25519_bob";
        };

        "seedbox" = {
          user = "return9826";
          hostname = "nexus.usbx.me";
          identitiesOnly = true;
          identityFile = "~/.ssh/id_ed25519_seedbox";
        };
      };
    };

    yt-dlp = {
      enable = true;

      settings = {
        mtime = false;
        restrict-filenames = true;
        format = "bestvideo[height<=1080]+bestaudio/best[height<=1080]";
        merge-output-format = "mkv";
      };
    };

    zsh = {
      enable = true;
      autocd = true;
      defaultKeymap = "emacs";
      dotDir = ".config/zsh";

      localVariables = {
        PROMPT = "%B%F{magenta}%n@%m%f %F{blue}%~%f %#%b ";
        RPROMPT = "%(0?.%F{green}.%F{red})%?%f [%*]";
      };

      initExtraFirst = ''
        autoload -Uz colors && colors
      '';

      initExtra = ''
        setopt interactive_comments
        setopt nomatch
        unsetopt beep
        unsetopt extendedglob
        unestopt notify
      '';

      history.ignoreDups = true;
    };
  };
}
