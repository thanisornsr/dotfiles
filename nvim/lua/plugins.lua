
-- Sets up lazy.nvim

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    {
        "loctvl842/monokai-pro.nvim",
        config = function()
            vim.cmd.colorscheme("monokai-pro")
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
    },
    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        branch = "main",
        keys = {
            { "af", mode = { "x", "o" } },
            { "if", mode = { "x", "o" } },
            { "ac", mode = { "x", "o" } },
            { "ic", mode = { "x", "o" } },
            { "as", mode = { "x", "o" } },
        },
        config = function()
            require("nvim-treesitter-textobjects").setup({
                select = {
                    enable = true,

                    lookahead = true,

                    selection_modes = {
                        ["@parameter.outer"] = "v", -- charwise
                        ["@function.outer"] = "V", -- linewise
                        ["@class.outer"] = "<c-v>", -- blockwise
                    },
                    include_surrounding_whitespace = true,
                },
            })

            local select =  require("nvim-treesitter-textobjects.select").select_textobject

            vim.keymap.set({ "x", "o" }, "af", function()
                select("@function.outer", "textobjects")
            end)
            vim.keymap.set({ "x", "o" }, "if", function()
                select("@function.inner", "textobjects")
            end)
            vim.keymap.set({ "x", "o" }, "ac", function()
                select("@class.outer", "textobjects")
            end)
            vim.keymap.set({ "x", "o" }, "ic", function()
                select("@class.inner", "textobjects")
            end)
            vim.keymap.set({ "x", "o" }, "as", function()
                select("@local.scope", "locals")
            end)
        end,
    },
    {
        "MeanderingProgrammer/treesitter-modules.nvim",
        config = function()
            require("treesitter-modules").setup({
                ensure_installed = {"c", "lua", "vim", "vimdoc", "query", "go", "python"},

                auto_install = true,
                
                highlight = {
                    enable = true,
                },

                incremental_selection = {
                    enable = true,
                    keymaps = {
                        init_selection = "<Leader>ss",
                        node_incremental = "<Leader>si",
                        scope_incremental = "<Leader>sc",
                        node_decremental = "<Leader>sd",
                    },
                },
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
    },
    {
        "mason-org/mason.nvim", 
        branch = "main",
        config = function()
            require("mason").setup()
        end,
    },
    {
        "mason-org/mason-lspconfig.nvim",
        dependencies = { "mason.nvim" },
        config = function()
            require("mason-lspconfig").setup()
        end,
    },
    {
        "saghen/blink.cmp",
        dependencies = { "rafamadriz/friendly-snippets" },

        version = "1.*",

        opts = {
            keymap = { preset = "super-tab" },

            appearance = {
                nerd_font_variant = "mono"
            },

            completion = { documentation = { auto_show = true } },

            sources = {
                default = { "lazydev", "lsp", "path", "snippets", "buffer" },
                providers = {
                    lazydev = {
                        name = "LazyDev",
                        module = "lazydev.integrations.blink",
                        score_offset = 100,
                    },
                },
            },

            fuzzy = { implementation = "prefer_rust_with_warning" }
        },
        opts_extend = { "sources.default" }
    },
    {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
            library = {
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
        },
    },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("lualine").setup({
                options = {
                    theme = "auto",
                },
            })
        end,
    },
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup({
                on_attach = function(bufnr)
                    local gs = require("gitsigns")
                    local function map(mode, l, r, desc)
                        vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
                    end

                    -- เลื่อนไปมาระหว่าง hunk
                    map("n", "]h", function() gs.nav_hunk("next") end, "Next hunk")
                    map("n", "[h", function() gs.nav_hunk("prev") end, "Prev hunk")

                    -- ดู/จัดการ hunk
                    map("n", "<Leader>hp", gs.preview_hunk, "Preview hunk")
                    map("n", "<Leader>hs", gs.stage_hunk, "Stage hunk")
                    map("n", "<Leader>hr", gs.reset_hunk, "Reset hunk")
                    map("n", "<Leader>hb", function() gs.blame_line({ full = true }) end, "Blame line")
                end,
            })
        end,
    },
    {
        "nvim-tree/nvim-tree.lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("nvim-tree").setup({
                view = { width = 30 },
                filters = { dotfiles = false },
            })
            vim.keymap.set("n", "<Leader>t", "<cmd>NvimTreeToggle<cr>", { desc = "Toggle file tree" })
            vim.keymap.set("n", "<Leader>f", "<cmd>NvimTreeFindFile<cr>", { desc = "Find current file in tree" })
        end,
    },
})

vim.keymap.set("n", "<Leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic error messages" })
