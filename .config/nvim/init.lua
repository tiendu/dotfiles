-- === General Settings ===
local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.hlsearch = true
opt.incsearch = true
opt.ignorecase = true
opt.smartcase = true
opt.expandtab = false
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.wrap = false
opt.cursorline = true
opt.clipboard = 'unnamedplus'
opt.timeoutlen = 300
opt.autoread = true
opt.list = true
opt.listchars = { tab = '▸ ', space = '·', eol = '↴' }
opt.guicursor = "n-v-c:block,i:ver25-blinkon500"
opt.termguicolors = true
opt.laststatus = 3
opt.statusline = table.concat({
  '%#StatusLine#', '%F', '%h', '%m', '%r',
  '%#StatusLineNC#', '%=', '%y',
  '%{&fileencoding?&fileencoding:&encoding}', '%{&fileformat}', ' [%p%%]', ' %l/%L:%c',
})

vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

-- === Highlighting and Transparency ===
local function set_transparency()
  local transparent_groups = {
    "Normal", "NormalFloat", "FloatBorder", "Pmenu", "PmenuSel"
  }
  for _, group in ipairs(transparent_groups) do
    vim.api.nvim_set_hl(0, group, { bg = "none" })
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = set_transparency,
})
set_transparency()

vim.api.nvim_set_hl(0, 'Whitespace', { fg = '#808080' })
vim.api.nvim_set_hl(0, 'TabLine', { fg = '#808080' })
vim.api.nvim_set_hl(0, 'EndOfLine', { fg = '#808080' })
vim.api.nvim_set_hl(0, 'CursorLine', { underline = true })

-- === Keymaps ===
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Save/Quit
map('n', '<leader>w', ':w<CR>', opts)
map('n', '<leader>q', ':q<CR>', opts)
map('n', '<leader>x', ':silent! wq<CR>', opts)
map('n', '<Esc>', '<Cmd>nohlsearch<CR>', opts)

-- Move lines
map('n', '<A-j>', ':m .+1<CR>==', opts)
map('n', '<A-k>', ':m .-2<CR>==', opts)
map('i', '<A-j>', '<Esc>:m .+1<CR>==gi', opts)
map('i', '<A-k>', '<Esc>:m .-2<CR>==gi', opts)
map('v', '<A-j>', ":m '>+1<CR>gv=gv", opts)
map('v', '<A-k>', ":m '<-2<CR>gv=gv", opts)

-- Fast Escape
map('i', 'jk', '<Esc>', opts)
map('i', 'kj', '<Esc>', opts)
map('i', 'jj', '<Esc>', opts)
map('i', 'kk', '<Esc>', opts)

-- Cursor move in insert
map('i', '<C-k>', '<Esc>ka', opts)
map('i', '<C-j>', '<Esc>ja', opts)
map('i', '<C-h>', '<Esc>ha', opts)
map('i', '<C-l>', '<Esc>la', opts)

-- Quickfix
map('n', '<leader>co', ':copen<CR>', opts)
map('n', '<leader>cc', ':cclose<CR>', opts)
map('n', '<leader>cn', ':cnext<CR>', opts)
map('n', '<leader>cp', ':cprev<CR>', opts)

-- Tabs
map('n', '<C-l>', 'gt', { noremap = true, desc = 'Next tab' })
map('n', '<C-h>', 'gT', { noremap = true, desc = 'Previous tab' })
map('n', '<leader>tc', ':tabclose<CR>', { desc = 'Close current tab' })
map('n', '<leader>to', ':tabonly<CR>', { desc = 'Close other tabs' })
map('n', '<leader>e', ':tabnew | Explore<CR>', { desc = 'New tab file explorer' })

-- === File Explorer (netrw) ===
vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3
vim.g.netrw_browse_split = 0
vim.g.netrw_winsize = 25

vim.api.nvim_create_autocmd("FileType", {
  pattern = "netrw",
  callback = function()
    map('n', '/', '/', { buffer = true })
  end,
})

-- === OSC52 Clipboard Copy ===
local function osc52_copy()
  local text = vim.fn.getreg('"')
  local encoded = vim.fn.systemlist("echo -n " .. vim.fn.shellescape(text) .. " | base64")
  local osc52 = '\x1b]52;c;' .. table.concat(encoded, '') .. '\x1b\\'

  local function write(seq)
    if vim.fn.filewritable('/dev/fd/2') == 1 then
      return vim.fn.writefile({ seq }, '/dev/fd/2', 'b') == 0
    else
      return vim.fn.chansend(vim.v.stderr, seq) > 0
    end
  end

  if not write(osc52) then
    vim.api.nvim_echo({ { "Failed to copy to OSC52", "ErrorMsg" } }, false, {})
  end
end

-- === Autocommands ===
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  command = "checktime",
})

vim.api.nvim_create_autocmd("InsertLeave", {
  command = "silent! wall",
})

vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function()
    local file = vim.fn.expand("<afile>")
    local dir = vim.fn.expand("<afile>:p:h")
    if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, "p") end
    if vim.fn.filereadable(file) == 1 then
      vim.fn.writefile(vim.fn.readfile(file), file .. ".bak")
    end
    local view = vim.fn.winsaveview()
    vim.cmd([[silent! %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

vim.api.nvim_create_autocmd("FocusLost", {
  command = "stopinsert",
})

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank { higroup = "IncSearch", timeout = 200 }
    if vim.v.event.operator == 'y' then osc52_copy() end
  end,
})

-- === Highlight TODOs & Whitespace ===
vim.api.nvim_set_hl(0, "ExtraWhitespace", { bg = "#ff5f5f" })
vim.fn.matchadd("ExtraWhitespace", [[\s\+$]])

vim.api.nvim_set_hl(0, "TodoKeyword", { fg = "#FFA500", bold = true })

vim.api.nvim_create_autocmd({ "Syntax", "BufEnter" }, {
  callback = function()
    vim.fn.matchadd("TodoKeyword", [[\v<(TODO|FIXME|NOTE)]], 100)
  end,
})

-- === (Optional) Line Numbers — Custom Color ===
vim.api.nvim_set_hl(0, "LineNr", { fg = "#FF0000" })
vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#00FF00" })

-- === Disable legacy plugins ===
vim.cmd('filetype plugin off')
