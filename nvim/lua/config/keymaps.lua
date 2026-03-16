local M = {}

local functions = require("config.functions")

local function disable_diagnostic_temp_then_reactivate(c)
  vim.diagnostic.disable()
  vim.cmd.execute(c)
  vim.diagnostic.enable()
end

function M.setup()
  local keymap = vim.keymap.set

  -- Enhanced paste mappings for Insert mode (using system clipboard)
  -- This ensures clean paste from system clipboard, bypassing keyboard protocol issues
  keymap("i", "<C-r>+", "<C-r><C-o>+", { noremap = true, desc = "Paste from clipboard (literal)" })
  keymap("i", "<C-y>", "<C-r><C-o>+", { noremap = true, desc = "Paste from clipboard (literal)" })

  -- Map common paste shortcuts in Normal mode to enter insert mode and paste
  -- keymap("n", "<D-v>", '"+p', { noremap = true, desc = "Paste from clipboard" })  -- Super/Cmd+V in Normal mode

  -- AI/Claude Code keymaps are now handled by lazy.nvim in plugins/claudecode.lua

  -- Easymotion keymaps are now handled by lazy.nvim in plugins/editing.lua

  -- Telescope keymaps are now handled by lazy.nvim in plugins/telescope.lua

  -- NvimTree keymaps are now handled by lazy.nvim in plugins/file-tree.lua

  -- Vista keymaps are now handled by lazy.nvim in plugins/navigation.lua

  -- Comment keymaps are now handled by lazy.nvim in plugins/comments.lua

  -- CtrlSF keymaps are now handled by lazy.nvim in plugins/navigation.lua

  -- Prettier keymaps are now handled by lazy.nvim in plugins/editing.lua

  -- Insert mode emacs-like keybindings
  vim.api.nvim_set_keymap("i", "<C-d>", "<C-o>x", { noremap = true })
  vim.api.nvim_set_keymap("i", "<C-e>", "<C-o>$", { noremap = true })
  vim.api.nvim_set_keymap("i", "<C-a>", "<C-o>^", { noremap = true })
  vim.api.nvim_set_keymap("i", "<C-b>", "<Left>", { noremap = true })
  vim.api.nvim_set_keymap("i", "<C-f>", "<Right>", { noremap = true })
  vim.api.nvim_set_keymap("i", "<C-k>", "<C-o>D", { noremap = true })
  vim.api.nvim_set_keymap("i", "<M-k>", "<C-o>d0", { noremap = true })
  vim.api.nvim_set_keymap("i", "<C-t>", "<C-o>O", { noremap = true })
  vim.api.nvim_set_keymap("i", "<M-BS>", "<C-w>", { noremap = true })

  -- 将 Ctrl-\ 映射为退出 terminal 到 Normal 模式（标准 ASCII 0x1C，无需 extended keys）
  vim.api.nvim_set_keymap("t", "<C-\\>", "<C-\\><C-N>", { noremap = true, silent = false })

  -- Advanced insert mode navigation
  keymap("i", "<M-d>", function()
    disable_diagnostic_temp_then_reactivate('"normal dea"')
  end, { noremap = true })
  keymap("i", "<M-f>", function()
    disable_diagnostic_temp_then_reactivate('"normal wa"')
  end, { noremap = true })
  keymap("i", "<M-b>", function()
    disable_diagnostic_temp_then_reactivate('"normal ba"')
  end, { noremap = true })
  keymap("i", "<C-_>", function()
    disable_diagnostic_temp_then_reactivate('"normal ua"')
  end, { noremap = true })
  keymap("i", "<C-l>", function()
    disable_diagnostic_temp_then_reactivate('"normal zza"')
  end, { noremap = true })
  keymap("i", "<C-n>", function()
    disable_diagnostic_temp_then_reactivate('"normal j"')
  end, { noremap = true })
  keymap("i", "<C-p>", function()
    disable_diagnostic_temp_then_reactivate('"normal k"')
  end, { noremap = true })

  -- Normal mode word navigation
  keymap("n", "<M-d>", function()
    disable_diagnostic_temp_then_reactivate('"normal de"')
  end, { noremap = true })
  keymap("n", "<M-f>", function()
    disable_diagnostic_temp_then_reactivate('"normal w"')
  end, { noremap = true })
  keymap("n", "<M-b>", function()
    disable_diagnostic_temp_then_reactivate('"normal b"')
  end, { noremap = true })

  -- Quick escape
  vim.api.nvim_set_keymap("i", "<C-q>", "<Esc>", { noremap = true })
  vim.api.nvim_set_keymap("n", "<C-q>", "a", { noremap = true })

  -- Buffer navigation
  keymap("n", "<Leader>h", "<cmd>bprev<cr>", { desc = "Previous buffer" })
  keymap("n", "<Leader>l", "<cmd>bnext<cr>", { desc = "Next buffer" })
  keymap("n", "<C-s>h", "<cmd>bprev<cr>", { desc = "Previous buffer" })
  keymap("n", "<C-s>l", "<cmd>bnext<cr>", { desc = "Next buffer" })
  keymap("n", "<Leader>k", "<cmd>Bclose<cr>", { desc = "Close buffer" })
  keymap("n", "<Leader>K", "<cmd>BufOnly<cr><cmd>bfirst<cr>", { desc = "Close all other buffers" })

  -- Window management
  keymap("n", "<C-h><C-h>", "<cmd>only<cr>", { desc = "Close other windows" })

  -- Window management
  vim.api.nvim_set_keymap("n", "<Leader>x", "<C-w>c", { noremap = true })
  vim.api.nvim_set_keymap("n", "<Leader>w", "<C-w>", { noremap = true })

  -- Utility mappings
  vim.api.nvim_set_keymap("n", "<Leader>L", ":set invnumber<CR>", { noremap = true })
  vim.api.nvim_set_keymap("n", "<Leader>U", ":g/^$/d<CR>", { noremap = true })
  vim.api.nvim_set_keymap("n", "<Leader>R", ":retab<CR>", { noremap = true })
  vim.api.nvim_set_keymap("n", "<Leader>.", ":@:<CR>", { noremap = true })
  vim.api.nvim_set_keymap("n", "<leader>;", ":nohlsearch<CR>", { noremap = true })
  vim.api.nvim_set_keymap("n", "<Leader>c", ":let @+=expand('%:p')<CR>", { noremap = true })

  -- Enhanced navigation
  vim.api.nvim_set_keymap("n", "J", "mzJ`z", { noremap = true })
  vim.api.nvim_set_keymap("n", "H", "^", { noremap = true })
  vim.api.nvim_set_keymap("n", "L", "$", { noremap = true })
  vim.api.nvim_set_keymap("v", "H", "^", { noremap = true })
  vim.api.nvim_set_keymap("v", "L", "g_", { noremap = true })
  vim.api.nvim_set_keymap("o", "H", "^", { noremap = true })
  vim.api.nvim_set_keymap("o", "L", "g_", { noremap = true })

  vim.api.nvim_set_keymap("n", "m", "%", { noremap = true })
  vim.api.nvim_set_keymap("v", "m", "%", { noremap = true })

  vim.api.nvim_set_keymap("n", "<C-l>", "zz", { noremap = true })

  -- Save shortcuts
  vim.api.nvim_set_keymap("n", "<C-j>", ":w<CR>", { noremap = true })
  vim.api.nvim_set_keymap("i", "<C-j>", "<ESC>:w<CR>", { noremap = true })
  vim.api.nvim_set_keymap("v", "<C-j>", "<ESC>:w<CR>", { noremap = true })
  vim.api.nvim_set_keymap("n", "<Leader>j", ":w<CR>", { noremap = true })

  -- Visual mode copy
  vim.api.nvim_set_keymap("v", "c", "y", { noremap = true })

  -- Scrolling
  vim.api.nvim_set_keymap("n", ";", "<C-d>", { noremap = true })
  vim.api.nvim_set_keymap("n", "'", "<C-u>", { noremap = true })
  vim.api.nvim_set_keymap("v", ";", "<C-d>", { noremap = true })
  vim.api.nvim_set_keymap("v", "'", "<C-u>", { noremap = true })

  -- Tab management
  vim.api.nvim_set_keymap("n", "th", ":tabfirst<CR>", { noremap = true })
  vim.api.nvim_set_keymap("n", "tj", ":tabnext<CR>", { noremap = true })
  vim.api.nvim_set_keymap("n", "tk", ":tabprev<CR>", { noremap = true })
  vim.api.nvim_set_keymap("n", "tl", ":tablast<CR>", { noremap = true })
  vim.api.nvim_set_keymap("n", "tt", ":tabedit<Space>", { noremap = true })
  vim.api.nvim_set_keymap("n", "tn", ":tabnext<Space>", { noremap = true })
  vim.api.nvim_set_keymap("n", "tm", ":tabm<Space>", { noremap = true })
  vim.api.nvim_set_keymap("n", "td", ":tabclose<CR>", { noremap = true })

  -- Paste without yanking
  vim.api.nvim_set_keymap("v", "p", '"_dp', { noremap = true })
  vim.api.nvim_set_keymap("v", "P", '"_dP', { noremap = true })

  -- Buffer switching
  vim.api.nvim_set_keymap("n", ",b", "<C-6>", { noremap = true })
  vim.api.nvim_set_keymap("n", "<Leader>o", ":ClangdSwitchSourceHeader<CR>", { noremap = true })

  -- Escape sequences
  vim.api.nvim_set_keymap("n", "<C-g>", "<ESC><ESC><ESC>", { noremap = true })
  vim.api.nvim_set_keymap("i", "<C-g>", "<ESC><ESC><ESC>", { noremap = true })
  vim.api.nvim_set_keymap("v", "<C-g>", "<ESC><ESC><ESC>", { noremap = true })

  -- Search and replace
  vim.api.nvim_set_keymap("v", "<C-r>", '"hy:%sno#<C-r>h##gc<left><left><left>', { noremap = true })
  vim.api.nvim_set_keymap("n", "S", ":%sno##g<LEFT><LEFT>", { noremap = true })
  vim.api.nvim_set_keymap("v", "//", 'y/<C-R>"<CR>"', { noremap = true })

  -- Command line emacs bindings
  vim.api.nvim_set_keymap("c", "<C-A>", "<Home>", { noremap = true })
  vim.api.nvim_set_keymap("c", "<C-F>", "<Right>", { noremap = true })
  vim.api.nvim_set_keymap("c", "<C-B>", "<Left>", { noremap = true })
  vim.api.nvim_set_keymap("c", "<Esc><Left>", "<S-Left>", { noremap = true })
  vim.api.nvim_set_keymap("c", "<Esc>b", "<S-Left>", { noremap = true })
  vim.api.nvim_set_keymap("c", "<Esc><Right>", "<S-Right>", { noremap = true })
  vim.api.nvim_set_keymap("c", "<Esc>f", "<S-Right>", { noremap = true })
  vim.api.nvim_set_keymap("c", "<Esc><BS>", "<C-W>", { noremap = true })
  vim.api.nvim_set_keymap("c", "w!!", "%!sudo tee > /dev/null %", { noremap = true })

  -- Window resizing
  vim.api.nvim_set_keymap("n", ">", ':exe "vertical resize +20"<CR>', { noremap = true })
  vim.api.nvim_set_keymap("n", "<", ':exe "vertical resize -20"<CR>', { noremap = true })

  -- Select mode
  vim.api.nvim_set_keymap("s", "<BS>", "<BS>i", { noremap = true })
  vim.api.nvim_set_keymap("s", "<C-k>", "<BS>i<C-o>D", { noremap = true })

  -- Text objects
  vim.api.nvim_set_keymap("v", "al", ":<C-U>normal 0v$h<CR>", { noremap = true })
  vim.api.nvim_set_keymap("v", "il", ":<C-U>normal ^vg_<CR>", { noremap = true })
  vim.api.nvim_set_keymap("o", "al", ":normal val<CR>", { noremap = true })
  vim.api.nvim_set_keymap("o", "il", ":normal vil<CR>", { noremap = true })

  -- Alt navigation
  vim.api.nvim_set_keymap("n", "<A-j>", "<C-e>", { noremap = true })
  vim.api.nvim_set_keymap("n", "<A-k>", "<C-y>", { noremap = true })
  vim.api.nvim_set_keymap("n", "<A-h>", ":bprev<CR>", { noremap = true })
  vim.api.nvim_set_keymap("n", "<A-l>", ":bnext<CR>", { noremap = true })

  -- Disable some keys
  keymap("n", "K", "<nop>", { desc = "Disabled" })
  keymap("n", "Q", "<nop>", { desc = "Disabled" })

  -- CMP completion
  -- nvim-cmp keymaps are now handled by lazy.nvim in plugins/completion.lua

  -- Function key mappings (moved from init.lua)
  keymap("n", "<F3>", "<cmd>set wrap!<cr>", { desc = "Toggle line wrap" })
  keymap("n", "<F4>", functions.toggle_mouse, { desc = "Toggle mouse" })
  keymap("n", "<F6>", "<cmd>LspRestart<cr>", { desc = "Restart LSP" })
  keymap("n", "<F8>", "*", { desc = "Search word under cursor" })
  keymap("n", "zm", functions.toggle_fold, { desc = "Toggle fold level" })
  keymap("n", "zo", "zA", { desc = "Toggle fold" })
  keymap("v", "Y", functions.copy_to_tmux, { silent = true, desc = "Copy to tmux" })

  -- Copy file path
  keymap("n", "<leader>PP", function()
    local filepath = vim.fn.expand("%:p")
    vim.fn.setreg("+", filepath)
    print("Copied to clipboard: " .. filepath)
  end, { desc = "Copy absolute file path to clipboard" })
end

return M
