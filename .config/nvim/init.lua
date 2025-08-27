-- --- Quality-of-life / performance ---
local ok = pcall(function() return vim.loader.enable() end)
local opt = vim.opt

opt.updatetime = 200
opt.redrawtime = 10000
opt.inccommand = "nosplit"
opt.fillchars = { eob = " ", fold = " ", foldopen = "▾", foldsep = " ", foldclose = "▸" }
opt.shortmess:append({ I = true, W = true, C = true })

-- --- Filetypes + Leaders ---
vim.cmd('filetype plugin indent on')
vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

-- --- UI + Navigation ---
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.termguicolors = true
opt.laststatus = 3
opt.statusline = table.concat({
  '%#StatusLine#','%F','%h','%m','%r',
  '%#StatusLineNC#','%=','%y',
  '%{&fileencoding?&fileencoding:&encoding}','%{&fileformat}',' [%p%%]',' %l/%L:%c',
})
opt.scrolloff = 4
opt.sidescrolloff = 8
opt.splitright = true
opt.splitbelow = true
opt.pumheight = 12
opt.showmode = false
opt.guicursor = "n-v-c:block,i:ver25-blinkon500"

-- --- Editing & Formatting ---
opt.wrap = false
opt.undofile = true
opt.clipboard = 'unnamedplus'
opt.timeoutlen = 300
opt.autoread = true

-- Search
opt.hlsearch = true
opt.incsearch = true
opt.ignorecase = true
opt.smartcase = true

-- Whitespace & indentation
opt.list = true
opt.listchars = { tab = '▸ ', space = '·', eol = '↴', trail = '·' }
opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.smartindent = true
opt.shiftround = true

-- Newline/EOL hygiene
opt.fixendofline = true
opt.endofline = true
opt.joinspaces = false

-- Comment behavior
opt.formatoptions:remove({ 'r', 'o' })  -- don't continue comments
opt.formatoptions:append({ 'j' })       -- remove comment leader when joining lines

-- --- Highlighting and Transparency ---
local function set_transparency()
  for _, g in ipairs({ "Normal", "NormalFloat", "FloatBorder", "Pmenu", "PmenuSel" }) do
    vim.api.nvim_set_hl(0, g, { bg = "none" })
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("transparency", { clear = true }),
  callback = set_transparency,
})
set_transparency()

vim.api.nvim_set_hl(0, 'Whitespace',   { fg = '#808080' })
vim.api.nvim_set_hl(0, 'TabLine',      { fg = '#808080' })
vim.api.nvim_set_hl(0, 'CursorLine',   { underline = true })
vim.api.nvim_set_hl(0, 'LineNr',       { fg = "#FF0000" })
vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = "#00FF00" })

-- --- Keymaps ---
local map, kmopts = vim.keymap.set, { noremap = true, silent = true }

-- Save / Quit
map('n', '<leader>w', '<Cmd>w<CR>', kmopts)
map('n', '<leader>q', '<Cmd>q<CR>', kmopts)
map('n', '<leader>x', '<Cmd>silent! wq<CR>', kmopts)
map('n', '<Esc>',     '<Cmd>nohlsearch<CR>', kmopts)

-- Move lines
map('n', '<A-j>', '<Cmd>m .+1<CR>==', kmopts)
map('n', '<A-k>', '<Cmd>m .-2<CR>==', kmopts)
map('i', '<A-j>', '<Esc><Cmd>m .+1<CR>==gi', kmopts)
map('i', '<A-k>', '<Esc><Cmd>m .-2<CR>==gi', kmopts)
map('v', '<A-j>', ":m '>+1<CR>gv=gv", kmopts)
map('v', '<A-k>', ":m '<-2<CR>gv=gv", kmopts)

-- Fast Escape
map('i', 'jk', '<Esc>', kmopts)
map('i', 'kj', '<Esc>', kmopts)
map('i', 'jj', '<Esc>', kmopts)
map('i', 'kk', '<Esc>', kmopts)

-- Cursor move in insert (stay in Insert, fold-aware)
map('i', '<C-h>', '<C-o>h', kmopts)
map('i', '<C-l>', '<C-o>l', kmopts)
map('i', '<C-k>', '<C-o>k', kmopts)
map('i', '<C-j>', '<C-o>j', kmopts)

-- Quickfix
map('n', '<leader>co', '<Cmd>copen<CR>', kmopts)
map('n', '<leader>cc', '<Cmd>cclose<CR>', kmopts)
map('n', '<leader>cn', '<Cmd>cnext<CR>', kmopts)
map('n', '<leader>cp', '<Cmd>cprev<CR>', kmopts)

-- Tabs
map('n', '<C-l>',     '<Cmd>tabnext<CR>',     { noremap = true, desc = 'Next tab' })
map('n', '<C-h>',     '<Cmd>tabprevious<CR>', { noremap = true, desc = 'Previous tab' })
map('n', '<leader>tc','<Cmd>tabclose<CR>',    { desc = 'Close current tab' })
map('n', '<leader>to','<Cmd>tabonly<CR>',     { desc = 'Close other tabs' })
map('n', '<leader>e', '<Cmd>tabnew | Explore<CR>', { desc = 'New tab file explorer' })

-- --- File Explorer (netrw) ---
vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3
vim.g.netrw_browse_split = 0
vim.g.netrw_winsize = 25

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("netrw_localmaps", { clear = true }),
  pattern = "netrw",
  callback = function()
    map('n', '/', '/', { buffer = true }) -- keep default feel explicitly
  end,
})

-- --- Autocommands ---
-- Keep buffers in sync with external changes
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  group = vim.api.nvim_create_augroup("autoread_checktime", { clear = true }),
  command = "checktime",
})

-- Gentler autosave: write only modified, listed buffers when leaving Insert
vim.api.nvim_create_autocmd("InsertLeave", {
  group = vim.api.nvim_create_augroup("autosave_modified", { clear = true }),
  callback = function()
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if vim.bo[b].buflisted and vim.bo[b].modifiable and vim.api.nvim_buf_get_option(b, "modified") then
        pcall(vim.api.nvim_buf_call, b, function() vim.cmd("silent keepalt write") end)
      end
    end
  end,
})

-- Trim trailing spaces on save (skip formats where two spaces are semantic)
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("trim_trailing_ws", { clear = true }),
  callback = function(args)
    local ft = vim.bo[args.buf].filetype
    if ft == "markdown" or ft == "asciidoc" then return end
    local view = vim.fn.winsaveview()
    vim.cmd([[silent! keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

-- Leave insert when window loses focus
vim.api.nvim_create_autocmd("FocusLost", {
  group = vim.api.nvim_create_augroup("stopinsert_on_blur", { clear = true }),
  command = "stopinsert",
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("yank_hi", { clear = true }),
  callback = function()
    vim.highlight.on_yank { higroup = "IncSearch", timeout = 200 }
  end,
})

-- --- Highlight TODOs & trailing whitespace (no match leaks) ---
vim.api.nvim_set_hl(0, "ExtraWhitespace", { bg = "#ff5f5f" })
vim.api.nvim_set_hl(0, "TodoKeyword",    { fg = "#FFA500", bold = true })

vim.api.nvim_create_autocmd({ "Syntax", "BufEnter" }, {
  group = vim.api.nvim_create_augroup("match_keywords_ws", { clear = true }),
  callback = function(args)
    -- one TODO match per buffer
    if vim.b[args.buf].todo_match_id then
      pcall(vim.fn.matchdelete, vim.b[args.buf].todo_match_id)
    end
    vim.b[args.buf].todo_match_id = vim.fn.matchadd("TodoKeyword", [[\v<(TODO|FIXME|NOTE)>]])

    -- one trailing whitespace match per buffer
    if vim.b[args.buf].trail_match_id then
      pcall(vim.fn.matchdelete, vim.b[args.buf].trail_match_id)
    end
    vim.b[args.buf].trail_match_id = vim.fn.matchadd("ExtraWhitespace", [[\s\+$]])
  end,
})