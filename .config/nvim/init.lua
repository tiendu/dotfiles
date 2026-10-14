-- ~/.config/nvim/init.lua
-- Plugin-free config. Native automatic completion requires Neovim 0.12+.
-- Earlier versions retain manual completion with Ctrl-N / Ctrl-P.

-- --- Startup / performance ---
if vim.loader then
  vim.loader.enable()
end

local opt, g, api, fn = vim.opt, vim.g, vim.api, vim.fn

-- --- Core timings & UI perf ---
opt.updatetime = 500
opt.redrawtime = 10000
opt.inccommand = "nosplit"
opt.fillchars = {
  eob = " ", fold = " ", foldopen = "▾", foldsep = " ", foldclose = "▸",
}
opt.shortmess:append({ I = true, W = true, C = true })

-- --- Leaders ---
g.mapleader = " "
g.maplocalleader = "\\"

-- --- UI & Navigation ---
opt.number = true
opt.relativenumber = true
opt.cursorline = true
pcall(function()
  opt.cursorlineopt = "number"
end)
opt.signcolumn = "yes"
opt.termguicolors = true
opt.laststatus = 3
opt.statusline = table.concat({
  "%#StatusLine#", " %f", "%h", "%m", "%r",
  "%#StatusLineNC#", "%=", "%y",
  " %{&fileencoding?&fileencoding:&encoding}",
  " %{&fileformat}", " [%p%%]", " %l/%L:%c",
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
if fn.has("clipboard") == 1 then
  opt.clipboard = "unnamedplus"
end
opt.timeoutlen = 300
opt.autoread = true
opt.confirm = true
opt.mouse = "a"

-- Prefer ripgrep for :grep; fall back when unavailable.
if fn.executable("rg") == 1 then
  opt.grepprg = "rg --vimgrep --smart-case"
  opt.grepformat = "%f:%l:%c:%m"
else
  opt.grepprg = "grep -nH $* /dev/null"
  opt.grepformat = "%f:%l:%m"
end

-- Search
opt.hlsearch = true
opt.incsearch = true
opt.ignorecase = true
opt.smartcase = true

-- Whitespace & indentation
opt.list = true
opt.listchars = { tab = "▸ ", space = "·", eol = "↴", trail = "•" }
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
opt.formatoptions:remove({ "r", "o" })
opt.formatoptions:append({ "j" })

-- --- Highlighting & Transparency ---
vim.cmd("syntax enable")

local function apply_highlights()
  for _, gname in ipairs({ "Normal", "NormalFloat", "Pmenu" }) do
    api.nvim_set_hl(0, gname, { bg = "none" })
  end
  local c = api.nvim_get_hl(0, { name = "Comment", link = false }) or {}
  api.nvim_set_hl(0, "FloatBorder", { bg = "none", fg = c.fg or "#808080" })
  local pm = api.nvim_get_hl(0, { name = "PmenuSel", link = false }) or {}
  api.nvim_set_hl(0, "PmenuSel", { bg = pm.bg or "#333333", fg = pm.fg or "NONE" })
  api.nvim_set_hl(0, "Whitespace", { fg = "#808080" })
  api.nvim_set_hl(0, "TabLine", { fg = "#808080" })
  api.nvim_set_hl(0, "LineNr", { fg = "#FF0000" })
  api.nvim_set_hl(0, "CursorLineNr", { fg = "#00FF00" })
  api.nvim_set_hl(0, "String", { fg = "#98C379" })
  api.nvim_set_hl(0, "Character", { fg = "#98C379" })
  api.nvim_set_hl(0, "Number", { fg = "#D19A66" })
  api.nvim_set_hl(0, "Boolean", { fg = "#D19A66" })
  api.nvim_set_hl(0, "Function", { fg = "#61AFEF" })
  api.nvim_set_hl(0, "Keyword", { fg = "#C678DD" })
  api.nvim_set_hl(0, "Type", { fg = "#E5C07B" })
  api.nvim_set_hl(0, "Comment", { fg = "#808080", italic = true })
  api.nvim_set_hl(0, "ExtraWhitespace", { bg = "#ff5f5f" })
  api.nvim_set_hl(0, "TodoKeyword", { fg = "#FFA500", bold = true })
  api.nvim_set_hl(0, "PreInsert", { fg = "#808080", italic = true })
  api.nvim_set_hl(0, "CursorTrail", { bg = "#C678DD", fg = "#C678DD" })
end

api.nvim_create_autocmd("ColorScheme", {
  group = api.nvim_create_augroup("custom_highlights", { clear = true }),
  callback = apply_highlights,
})
apply_highlights()

-- --- Keymaps ---
local map = vim.keymap.set
local kmopts = { noremap = true, silent = true }
local expr_opts = {
  expr = true, noremap = true, silent = true, replace_keycodes = true,
}

-- Save / Quit
map("n", "<leader>w", "<Cmd>w<CR>", kmopts)
map("n", "<leader>q", "<Cmd>q<CR>", kmopts)
map("n", "<leader>x", "<Cmd>wq<CR>", kmopts)
map("n", "<Esc>", "<Cmd>nohlsearch<CR>", kmopts)

-- Fast Escape
map("i", "jk", "<Esc>", kmopts)
map("i", "kj", "<Esc>", kmopts)
map("i", "jj", "<Esc>", kmopts)
map("i", "kk", "<Esc>", kmopts)

-- Quickfix
map("n", "<leader>co", "<Cmd>copen<CR>", kmopts)
map("n", "<leader>cc", "<Cmd>cclose<CR>", kmopts)
map("n", "<leader>cn", "<Cmd>cnext<CR>", kmopts)
map("n", "<leader>cp", "<Cmd>cprev<CR>", kmopts)

-- Tabs
map("n", "<C-l>", "<Cmd>tabnext<CR>", { silent = true, desc = "Next tab" })
map("n", "<C-h>", "<Cmd>tabprevious<CR>", { silent = true, desc = "Previous tab" })
map("n", "<leader>tc", "<Cmd>tabclose<CR>", { silent = true, desc = "Close current tab" })
map("n", "<leader>to", "<Cmd>tabonly<CR>", { silent = true, desc = "Close other tabs" })
map("n", "<leader>e", "<Cmd>tabnew | Explore<CR>", { silent = true, desc = "New tab file explorer" })

-- --- File Explorer (netrw) ---
g.netrw_banner = 0
g.netrw_liststyle = 3
g.netrw_browse_split = 0
g.netrw_winsize = 25
api.nvim_create_autocmd("FileType", {
  group = api.nvim_create_augroup("netrw_localmaps", { clear = true }),
  pattern = "netrw",
  callback = function()
    map("n", "/", "/", { buffer = true })
  end,
})

-- --- Autocommands ---
api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  group = api.nvim_create_augroup("autoread_checktime", { clear = true }),
  command = "checktime",
})
api.nvim_create_autocmd("FileType", {
  group = api.nvim_create_augroup("format_options", { clear = true }),
  callback = function()
    vim.opt_local.formatoptions:remove({ "r", "o" })
    vim.opt_local.formatoptions:append({ "j" })
  end,
})
api.nvim_create_autocmd("FileType", {
  group = api.nvim_create_augroup("indentation", { clear = true }),
  pattern = { "python" },
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
  end,
})
api.nvim_create_autocmd("FileType", {
  group = api.nvim_create_augroup("hard_tabs", { clear = true }),
  pattern = { "make", "go" },
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 0
  end,
})

-- Autosave current buffer on InsertLeave; report write failures.
api.nvim_create_autocmd("InsertLeave", {
  group = api.nvim_create_augroup("autosave_modified", { clear = true }),
  callback = function(args)
    local b = args.buf
    local name = api.nvim_buf_get_name(b)
    if name == "" then
      return
    end
    if vim.bo[b].buftype == ""
      and vim.bo[b].modifiable
      and vim.bo[b].buflisted
      and vim.bo[b].modified
    then
      local ok, err = pcall(api.nvim_buf_call, b, function()
        vim.cmd("silent keepalt write")
      end)
      if not ok then
        vim.notify(("Autosave failed for %s: %s"):format(name, tostring(err)), vim.log.levels.ERROR)
      end
    end
  end,
})

-- Trim trailing spaces on save, preserving intentional markup whitespace.
api.nvim_create_autocmd("BufWritePre", {
  group = api.nvim_create_augroup("trim_trailing_ws", { clear = true }),
  callback = function(args)
    local ft = vim.bo[args.buf].filetype
    if ft == "markdown" or ft == "asciidoc" then
      return
    end
    api.nvim_buf_call(args.buf, function()
      local view = fn.winsaveview()
      vim.cmd([[silent keepjumps keeppatterns %s/\s\+$//e]])
      fn.winrestview(view)
    end)
  end,
})
api.nvim_create_autocmd("TextYankPost", {
  group = api.nvim_create_augroup("yank_hi", { clear = true }),
  callback = function()
    local opts = { higroup = "IncSearch", timeout = 200 }
    if vim.hl and vim.hl.hl_op then
      vim.hl.hl_op(opts)
    elseif vim.hl and vim.hl.on_yank then
      vim.hl.on_yank(opts)
    elseif vim.highlight and vim.highlight.on_yank then
      vim.highlight.on_yank(opts)
    end
  end,
})

-- --- Quote autopair ---
local function get_chars()
  local col = fn.col(".")
  local line = fn.getline(".")
  return col > 1 and line:sub(col - 1, col - 1) or "", line:sub(col, col)
end
local function is_word(c)
  return c ~= "" and c:match("[%w_%%$%-]") ~= nil
end
local function is_closer(c)
  return c ~= "" and c:match("[%)%]%}]") ~= nil
end
local function is_boundary_char(c)
  return c == "" or c:match("[%s%p]") ~= nil
end
local function should_pair_quote(quote)
  local prevc, nextc = get_chars()
  if fn.pumvisible() == 1 then
    return quote
  end
  if nextc == quote then
    return "<Right>"
  end
  if is_word(prevc) or is_word(nextc) or is_closer(prevc) then
    return quote
  end
  if prevc == "\\" or prevc == "." then
    return quote
  end
  if nextc == "/" or nextc == "~" then
    return quote
  end
  if prevc == "=" and is_boundary_char(nextc) then
    return quote .. quote .. "<Left>"
  end
  if is_boundary_char(prevc) and is_boundary_char(nextc) then
    return quote .. quote .. "<Left>"
  end
  return quote
end
local function backspace_quote_pair()
  local prevc, nextc = get_chars()
  if (prevc == "'" and nextc == "'") or (prevc == '"' and nextc == '"') then
    return "<BS><Del>"
  end
  return "<BS>"
end
map("i", "'", function() return should_pair_quote("'") end, expr_opts)
map("i", '"', function() return should_pair_quote('"') end, expr_opts)
map("i", "<BS>", backspace_quote_pair, expr_opts)
map("i", "<C-h>", backspace_quote_pair, expr_opts)

-- --- Highlight TODOs & trailing whitespace ---
local function delete_window_match(name)
  local id = vim.w[name]
  if id then
    pcall(fn.matchdelete, id)
    vim.w[name] = nil
  end
end
local function refresh_window_matches()
  local buf = api.nvim_get_current_buf()
  delete_window_match("todo_match_id")
  delete_window_match("trail_match_id")
  if vim.bo[buf].buftype ~= "" then
    return
  end
  vim.w.todo_match_id = fn.matchadd("TodoKeyword", [[\v<(TODO|FIXME|NOTE)>]])
  local ft = vim.bo[buf].filetype
  if ft ~= "markdown" and ft ~= "asciidoc" then
    vim.w.trail_match_id = fn.matchadd("ExtraWhitespace", [[\s\+$]])
  end
end
api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "Syntax" }, {
  group = api.nvim_create_augroup("match_keywords_ws", { clear = true }),
  callback = refresh_window_matches,
})

-- --- Autosuggestions ---
-- Buffer words only; no plugins, external services, or language servers.
opt.complete = { ".", "w", "b" }
opt.completeopt = { "menuone", "noselect" }
if fn.exists("+autocomplete") == 1 then
  opt.autocomplete = true
  opt.autocompletedelay = 150
  opt.completeopt = { "menuone", "preinsert" }
  opt.infercase = true
end
map("i", "<Tab>", function()
  return fn.pumvisible() == 1 and "<C-n>" or "<Tab>"
end, expr_opts)
map("i", "<S-Tab>", function()
  return fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
end, expr_opts)
map("i", "<C-y>", "<C-y>", kmopts) -- Accept suggestion.
map("i", "<C-e>", "<C-e>", kmopts) -- Dismiss suggestion.

-- --- Native smooth cursor trail ---
-- A visual follower only: never delays or moves the actual editing cursor.
-- Six frames at 16 ms, with cubic ease-out. Toggle with <leader>ut.
do
  local uv = vim.uv or vim.loop
  local settings = { frames = 6, interval = 16, zindex = 40 }

  -- Dispose the previous instance when :source reloads this file.
  local old = rawget(_G, "__native_cursor_trail")
  if old and old.dispose then
    old.dispose()
  end
  local state = {
    enabled = true, generation = 0, disposed = false,
    timer = assert(uv.new_timer()),
  }
  _G.__native_cursor_trail = state
  local group = api.nvim_create_augroup("NativeCursorGlide", { clear = true })

  local function stop()
    -- Invalidate queued main-loop callbacks as well as stopping the timer.
    state.generation = state.generation + 1
    if not state.timer:is_closing() then
      state.timer:stop()
    end
    local win = state.win
    state.win = nil
    if win and api.nvim_win_is_valid(win) then
      pcall(api.nvim_win_close, win, true)
    end
  end

  local function reset()
    stop()
    state.previous = nil
  end

  function state.dispose()
    if state.disposed then return end
    state.disposed = true
    reset()
    if not state.timer:is_closing() then state.timer:close() end
    if state.buf and api.nvim_buf_is_valid(state.buf) then
      pcall(api.nvim_buf_delete, state.buf, { force = true })
    end
  end

  local function position()
    if state.disposed or not state.enabled or fn.pumvisible() == 1 then
      return nil
    end
    local mode = api.nvim_get_mode().mode:sub(1, 1)
    if mode ~= "n" and mode ~= "i" and mode ~= "v"
      and mode ~= "V" and mode ~= "\22" then
      return nil
    end
    local win, buf = api.nvim_get_current_win(), api.nvim_get_current_buf()
    if vim.bo[buf].buftype ~= "" or api.nvim_win_get_config(win).relative ~= "" then
      return nil
    end
    -- screenrow/screencol reflect the visible cursor, including tabs/wide text.
    local view = fn.winsaveview()
    return {
      win = win, buf = buf, row = fn.screenrow() - 1, col = fn.screencol() - 1,
      topline = view.topline, topfill = view.topfill, leftcol = view.leftcol,
      skipcol = view.skipcol,
    }
  end

  local function same_view(a, b)
    return a.win == b.win and a.buf == b.buf
      and a.topline == b.topline and a.topfill == b.topfill
      and a.leftcol == b.leftcol and a.skipcol == b.skipcol
  end

  local function animate()
    local current = position()
    if not current then reset(); return end
    local previous = state.previous
    state.previous = current
    if not previous or not same_view(previous, current) then stop(); return end
    if previous.row == current.row and previous.col == current.col then return end
    stop()

    if not state.buf or not api.nvim_buf_is_valid(state.buf) then
      state.buf = api.nvim_create_buf(false, true)
      vim.bo[state.buf].bufhidden = "hide"
      vim.bo[state.buf].swapfile = false
      api.nvim_buf_set_lines(state.buf, 0, -1, false, { " " })
      vim.bo[state.buf].modifiable = false
    end
    local ok, win = pcall(api.nvim_open_win, state.buf, false, {
      relative = "editor", row = previous.row, col = previous.col,
      width = 1, height = 1, focusable = false, style = "minimal",
      border = "none", noautocmd = true, zindex = settings.zindex,
    })
    if not ok then return end
    state.win = win
    vim.wo[win].winhighlight = "Normal:CursorTrail,NormalFloat:CursorTrail"
    vim.wo[win].winblend = 0

    local generation = state.generation
    local frame = 0
    state.timer:start(settings.interval, settings.interval, function()
      frame = frame + 1
      local this_frame = frame
      -- Capture each frame independently; do not read a mutable step later.
      if this_frame >= settings.frames then state.timer:stop() end
      vim.schedule(function()
        if state.disposed or generation ~= state.generation then return end
        local now = position()
        if not now or not same_view(current, now)
          or now.row ~= current.row or now.col ~= current.col
          or not state.win or not api.nvim_win_is_valid(state.win) then
          reset()
          return
        end
        if this_frame >= settings.frames then stop(); return end
        local progress = this_frame / settings.frames
        local ease = 1 - (1 - progress) ^ 3
        local row = math.floor(previous.row + (current.row - previous.row) * ease + 0.5)
        local col = math.floor(previous.col + (current.col - previous.col) * ease + 0.5)
        -- Hide upon reaching the cursor cell instead of covering its text.
        if row == current.row and col == current.col then stop(); return end
        local moved = pcall(api.nvim_win_set_config, state.win, {
          relative = "editor", row = row, col = col,
        })
        if not moved then reset() end
      end)
    end)
  end

  api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = group, callback = animate,
  })
  api.nvim_create_autocmd({
    "BufLeave", "WinLeave", "TabLeave", "InsertEnter", "InsertLeave",
    "CmdlineEnter", "FocusLost", "VimResized", "WinScrolled",
  }, { group = group, callback = reset })

  -- CompleteChanged has textlock: invalidate immediately, close after it ends.
  api.nvim_create_autocmd("CompleteChanged", {
    group = group,
    callback = function()
      state.generation = state.generation + 1
      if not state.timer:is_closing() then state.timer:stop() end
      state.previous = nil
      local generation = state.generation
      vim.schedule(function()
        if not state.disposed and generation == state.generation then reset() end
      end)
    end,
  })
  api.nvim_create_autocmd("CompleteDone", { group = group, callback = reset })
  api.nvim_create_autocmd("VimLeavePre", { group = group, callback = state.dispose })
  map("n", "<leader>ut", function()
    state.enabled = not state.enabled
    reset()
    vim.notify("Cursor trail " .. (state.enabled and "enabled" or "disabled"))
  end, { silent = true, desc = "Toggle cursor trail" })
end
