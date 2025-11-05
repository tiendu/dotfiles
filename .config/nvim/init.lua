-- ~/.config/nvim/init.lua
-- --- Startup / performance ---
local ok = pcall(function() return vim.loader.enable() end)
local opt, g, api, fn = vim.opt, vim.g, vim.api, vim.fn

-- --- Core timings & UI perf ---
opt.updatetime   = 200
opt.redrawtime   = 10000
opt.inccommand   = "nosplit"
opt.fillchars    = { eob = " ", fold = " ", foldopen = "▾", foldsep = " ", foldclose = "▸" }
opt.shortmess:append({ I = true, W = true, C = true })

-- --- Leaders ---
g.mapleader      = ' '
g.maplocalleader = '\\'

-- --- UI & Navigation ---
opt.number         = true
opt.relativenumber = true
opt.cursorline     = true
pcall(function() opt.cursorlineopt = "number" end) -- lighter cursorline (NVIM ≥0.9)
opt.signcolumn    = "yes"
opt.termguicolors = true
opt.laststatus    = 3
opt.statusline    = table.concat({
  '%#StatusLine#','%F','%h','%m','%r',
  '%#StatusLineNC#','%=','%y',
  '%{&fileencoding?&fileencoding:&encoding}','%{&fileformat}',' [%p%%]',' %l/%L:%c',
})
opt.scrolloff     = 4
opt.sidescrolloff = 8
opt.splitright    = true
opt.splitbelow    = true
opt.pumheight     = 12
opt.showmode      = false
opt.guicursor     = "n-v-c:block,i:ver25-blinkon500"

-- --- Editing & Formatting ---
opt.wrap       = false
opt.undofile   = true
opt.clipboard  = 'unnamedplus'
opt.timeoutlen = 300
opt.autoread   = true
opt.confirm    = true       -- be nice on :w over readonly files
opt.mouse      = "a"        -- easy selection/resize when needed

-- If ripgrep is installed, use it for :grep
if fn.executable("rg") == 1 then
  opt.grepprg = "rg --vimgrep --smart-case"
end

-- Search
opt.hlsearch   = true
opt.incsearch  = true
opt.ignorecase = true
opt.smartcase  = true

-- Whitespace & indentation
opt.list        = true
opt.listchars   = { tab = '▸ ', space = '·', eol = '↴', trail = '•' }
opt.expandtab   = true
opt.tabstop     = 2
opt.shiftwidth  = 2
opt.softtabstop = 2
opt.smartindent = true
opt.shiftround  = true

-- Newline/EOL hygiene
opt.fixendofline = true
opt.endofline    = true
opt.joinspaces   = false

-- Comment behavior
opt.formatoptions:remove({ 'r', 'o' })  -- don't continue comments
opt.formatoptions:append({ 'j' })       -- remove comment leader when joining lines

-- --- Highlighting & Transparency ---
local function set_transparency()
  local groups = { "Normal", "NormalFloat", "Pmenu" }
  for _, gname in ipairs(groups) do
    api.nvim_set_hl(0, gname, { bg = "none" })
  end
  -- keep FloatBorder visible (match Comment fg if possible)
  local c = api.nvim_get_hl(0, { name = "Comment", link = false }) or {}
  api.nvim_set_hl(0, "FloatBorder", { bg = "none", fg = c.fg or "#808080" })
  -- Menu selection should still show
  local pm = api.nvim_get_hl(0, { name = "PmenuSel", link = false }) or {}
  api.nvim_set_hl(0, "PmenuSel", { bg = pm.bg or "#333333", fg = pm.fg or "NONE" })
end

api.nvim_create_autocmd("ColorScheme", {
  group = api.nvim_create_augroup("transparency", { clear = true }),
  callback = set_transparency,
})
set_transparency()

api.nvim_set_hl(0, 'Whitespace',   { fg = '#808080' })
api.nvim_set_hl(0, 'TabLine',      { fg = '#808080' })
api.nvim_set_hl(0, 'CursorLine',   { underline = true })
api.nvim_set_hl(0, 'LineNr',       { fg = "#FF0000" })
api.nvim_set_hl(0, 'CursorLineNr', { fg = "#00FF00" })

-- --- Keymaps ---
local map, kmopts = vim.keymap.set, { noremap = true, silent = true }

-- Save / Quit
map('n', '<leader>w', '<Cmd>w<CR>', kmopts)
map('n', '<leader>q', '<Cmd>q<CR>', kmopts)
map('n', '<leader>x', '<Cmd>silent! wq<CR>', kmopts)
map('n', '<Esc>',     '<Cmd>nohlsearch<CR>', kmopts)

-- Fast Escape
map('i', 'jk', '<Esc>', kmopts)
map('i', 'kj', '<Esc>', kmopts)
map('i', 'jj', '<Esc>', kmopts)
map('i', 'kk', '<Esc>', kmopts)

-- Quickfix
map('n', '<leader>co', '<Cmd>copen<CR>', kmopts)
map('n', '<leader>cc', '<Cmd>cclose<CR>', kmopts)
map('n', '<leader>cn', '<Cmd>cnext<CR>', kmopts)
map('n', '<leader>cp', '<Cmd>cprev<CR>', kmopts)

-- Tabs
map('n', '<C-l>',        '<Cmd>tabnext<CR>',     { noremap = true, desc = 'Next tab' })
map('n', '<C-h>',        '<Cmd>tabprevious<CR>', { noremap = true, desc = 'Previous tab' })
map('n', '<leader>tc',   '<Cmd>tabclose<CR>',    { desc = 'Close current tab' })
map('n', '<leader>to',   '<Cmd>tabonly<CR>',     { desc = 'Close other tabs' })
map('n', '<leader>e',    '<Cmd>tabnew | Explore<CR>', { desc = 'New tab file explorer' })

-- --- File Explorer (netrw) ---
g.netrw_banner       = 0
g.netrw_liststyle    = 3
g.netrw_browse_split = 0
g.netrw_winsize      = 25

api.nvim_create_autocmd("FileType", {
  group = api.nvim_create_augroup("netrw_localmaps", { clear = true }),
  pattern = "netrw",
  callback = function()
    map('n', '/', '/', { buffer = true }) -- keep default feel explicitly
  end,
})

-- --- Autocommands ---
-- Keep buffers in sync with external changes
api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  group = api.nvim_create_augroup("autoread_checktime", { clear = true }),
  command = "checktime",
})

-- Gentler autosave: write only modified, listed, modifiable buffers on InsertLeave
api.nvim_create_autocmd("InsertLeave", {
  group = api.nvim_create_augroup("autosave_modified", { clear = true }),
  callback = function()
    for _, b in ipairs(api.nvim_list_bufs()) do
      if fn.buflisted(b) == 1 and vim.bo[b].modifiable and vim.bo[b].modified then
        pcall(api.nvim_buf_call, b, function()
          vim.cmd("silent keepalt write")
        end)
      end
    end
  end,
})

-- Trim trailing spaces on save (skip formats where two spaces are semantic)
api.nvim_create_autocmd("BufWritePre", {
  group = api.nvim_create_augroup("trim_trailing_ws", { clear = true }),
  callback = function(args)
    local ft = vim.bo[args.buf].filetype
    if ft == "markdown" or ft == "asciidoc" then return end
    local view = fn.winsaveview()
    vim.cmd([[silent! keeppatterns %s/\s\+$//e]])
    fn.winrestview(view)
  end,
})

-- Leave insert when window loses focus (but not in terminal/prompt buffers)
api.nvim_create_autocmd("FocusLost", {
  group = api.nvim_create_augroup("stopinsert_on_blur", { clear = true }),
  callback = function(args)
    local bt = vim.bo[args.buf].buftype
    if bt == "" then vim.cmd("stopinsert") end
  end,
})

-- Highlight on yank
api.nvim_create_autocmd("TextYankPost", {
  group = api.nvim_create_augroup("yank_hi", { clear = true }),
  callback = function()
    vim.highlight.on_yank { higroup = "IncSearch", timeout = 200 }
  end,
})

-- --- Autopair
local expr_opts = { expr = true, noremap = true, silent = true, replace_keycodes = true }

-- Helpers
local function get_chars()
  local col  = vim.fn.col('.')
  local line = vim.fn.getline('.')
  local prevc = (col > 1) and line:sub(col-1, col-1) or ""
  local nextc = line:sub(col, col)
  return prevc, nextc
end

local function is_word(c) return c and c:match("[%w_]") end
local function is_closer(c) return c and c:match("[%)%]%}]") end
local function is_hardstop(c) return c and c:match("[.%$=]") end
local function is_busy(c) return c and c:match("[$%?!%.,:;=]") end
local function is_boundary_char(c) return c == "" or c:match("[%s%p]") ~= nil end

local function open_pair(open, close, mode)
  return function()
    local prevc, nextc = get_chars()
    -- don't meddle during completion menu
    if vim.fn.pumvisible() == 1 then
      return open
    end
    -- double-tap opener -> literal; if closer is next, nudge it right
    if prevc == open then
      if nextc == close then
        return open .. close .. "<Left>"
      else
        return open
      end
    end
    -- quotes: conservative near words / after '=' / after closers
    if open == '"' or open == "'" then
      -- allow pairing after '=' only if the next char is a boundary (EOL/space/punct)
      if prevc == "=" and is_boundary_char(nextc) then
        return open .. close .. "<Left>"
      end
      -- conservative: block near words/closers
      if is_word(nextc) or is_word(prevc) or is_closer(prevc) then
        return open
      end
    end
    -- HARD STOP: after dot/dollar/equals -> literal
    if is_hardstop(prevc) then
      return open
    end
    -- identifier-adjacent pairing for ([{, but NOT after closers
    if (open == "(" or open == "[" or open == "{") and is_word(prevc) then
      return open .. close .. "<Left>"
    end
    -- skip when next looks "busy" or like a path start
    if is_busy(nextc) or nextc == "/" or nextc == "~" then
      return open
    end
    -- mode-based pairing
    if mode == "always" then
      return open .. close .. "<Left>"
    end
    if mode == "boundary" then
      if not is_closer(prevc) then
        if is_boundary_char(prevc) and is_boundary_char(nextc) then
          return open .. close .. "<Left>"
        end
      end
    end
    return open
  end
end

local function close_pair(close)
  return function()
    local _, nextc = get_chars()
    if nextc == close then
      return "<Right>"
    else
      return close
    end
  end
end

local function backspace_pair()
  local prevc, nextc = get_chars()
  local pairs = { ["'"]="'", ['"']='"', ["("]=")", ["["]="]", ["{"]="}" }
  if pairs[prevc] and pairs[prevc] == nextc then
    return "<BS><Del>"
  end
  return "<BS>"
end

-- Autopair mappings
map("i", "(", open_pair("(", ")", "boundary"), expr_opts)
map("i", "[", open_pair("[", "]", "boundary"), expr_opts)
map("i", "{", open_pair("{", "}", "boundary"), expr_opts)
map("i", ")", close_pair(")"), expr_opts)
map("i", "]", close_pair("]"), expr_opts)
map("i", "}", close_pair("}"), expr_opts)

map("i", "'", open_pair("'", "'", "boundary"), expr_opts)
map("i", '"', open_pair('"', '"', "boundary"), expr_opts)

map("i", "<BS>", backspace_pair, expr_opts)
map("i", "<C-h>", backspace_pair, expr_opts)

map("i", "<CR>", function()
  if vim.fn.pumvisible() == 1 then return "<CR>" end
  local prevc, nextc = get_chars()
  local matchers = { ["("]=")", ["["]="]", ["{"]="}" }
  if matchers[prevc] and matchers[prevc] == nextc then
    return "<CR><Esc>O"
  end
  return "<CR>"
end, expr_opts)

-- --- Highlight TODOs & trailing whitespace (no match leaks) ---
api.nvim_set_hl(0, "ExtraWhitespace", { bg = "#ff5f5f" })
api.nvim_set_hl(0, "TodoKeyword",     { fg = "#FFA500", bold = true })

api.nvim_create_autocmd({ "Syntax", "BufEnter" }, {
  group = api.nvim_create_augroup("match_keywords_ws", { clear = true }),
  callback = function(args)
    -- one TODO match per buffer
    if vim.b[args.buf].todo_match_id then
      pcall(fn.matchdelete, vim.b[args.buf].todo_match_id)
    end
    vim.b[args.buf].todo_match_id = fn.matchadd("TodoKeyword", [[\v<(TODO|FIXME|NOTE)>]])
    -- one trailing whitespace match per buffer
    if vim.b[args.buf].trail_match_id then
      pcall(fn.matchdelete, vim.b[args.buf].trail_match_id)
    end
    vim.b[args.buf].trail_match_id = fn.matchadd("ExtraWhitespace", [[\s\+$]])
  end,
})

