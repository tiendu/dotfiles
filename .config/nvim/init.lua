-- ~/.config/nvim/init.lua

-- === General Settings ===
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.expandtab = false
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.wrap = false
vim.opt.cursorline = true
vim.opt.clipboard = 'unnamedplus'
vim.opt.timeoutlen = 300
vim.opt.autoread = true

vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

-- === Whitespace & Cursor Display ===
vim.opt.list = true
vim.opt.listchars = { tab = '▸ ', space = '·', eol = '↴' }
vim.opt.guicursor = "n-v-c:block,i:ver25-blinkon500"

vim.api.nvim_set_hl(0, 'Whitespace', { fg = '#808080' })
vim.api.nvim_set_hl(0, 'TabLine', { fg = '#808080' })
vim.api.nvim_set_hl(0, 'EndOfLine', { fg = '#808080' })
vim.api.nvim_set_hl(0, 'CursorLine', { underline = true })

-- === UI Colors ===
vim.o.termguicolors = true
vim.cmd [[
  highlight LineNr guifg=#FF0000
  highlight CursorLineNr guifg=#00FF00
  highlight Normal guibg=none
  highlight NonText guibg=none
  highlight Normal ctermbg=none
  highlight NonText ctermbg=none
]]

-- === Status Line ===
vim.o.laststatus = 3
vim.o.statusline = table.concat({
  '%#StatusLine#',
  '%F', '%h', '%m', '%r',
  '%#StatusLineNC#',
  '%=',
  '%y',
  '%{&fileencoding?&fileencoding:&encoding}',
  '%{&fileformat}', ' [%p%%]', ' %l/%L:%c',
})

-- === Keymaps: General ===
vim.keymap.set('n', '<leader>w', ':w<CR>', { noremap = true })
vim.keymap.set('n', '<leader>q', ':q<CR>', { noremap = true })
vim.keymap.set('n', '<leader>x', ':silent! wq<CR>', { noremap = true })

-- === Keymaps: Line Movement ===
vim.keymap.set('n', '<A-j>', ':m .+1<CR>==', { noremap = true })
vim.keymap.set('n', '<A-k>', ':m .-2<CR>==', { noremap = true })
vim.keymap.set('i', '<A-j>', '<Esc>:m .+1<CR>==gi', { noremap = true })
vim.keymap.set('i', '<A-k>', '<Esc>:m .-2<CR>==gi', { noremap = true })
vim.keymap.set('v', '<A-j>', ":m '>+1<CR>gv=gv", { noremap = true })
vim.keymap.set('v', '<A-k>', ":m '<-2<CR>gv=gv", { noremap = true })

-- === Keymaps: Escape Insert Mode ===
vim.keymap.set('i', 'jk', '<Esc>', { noremap = true })
vim.keymap.set('i', 'kj', '<Esc>', { noremap = true })
vim.keymap.set('i', 'kk', '<Esc>', { noremap = true })
vim.keymap.set('i', 'jj', '<Esc>', { noremap = true })

-- === Keymaps: Cursor Movement in Insert Mode ===
vim.keymap.set('i', '<C-k>', '<Esc>ka', { noremap = true, silent = true })
vim.keymap.set('i', '<C-j>', '<Esc>ja', { noremap = true, silent = true })
vim.keymap.set('i', '<C-h>', '<Esc>ha', { noremap = true, silent = true })
vim.keymap.set('i', '<C-l>', '<Esc>la', { noremap = true, silent = true })

-- === Keymaps: Quickfix ===
vim.keymap.set('n', '<leader>co', ':copen<CR>', { noremap = true })
vim.keymap.set('n', '<leader>cc', ':cclose<CR>', { noremap = true })
vim.keymap.set('n', '<leader>cn', ':cnext<CR>', { noremap = true })
vim.keymap.set('n', '<leader>cp', ':cprev<CR>', { noremap = true })

-- === Keymaps: Tab Navigation ===
vim.keymap.set('n', '<C-l>', 'gt', { noremap = true, desc = 'Next tab' })
vim.keymap.set('n', '<C-h>', 'gT', { noremap = true, desc = 'Previous tab' })
vim.keymap.set('n', '<leader>tc', ':tabclose<CR>', { desc = 'Close current tab' })
vim.keymap.set('n', '<leader>to', ':tabonly<CR>', { desc = 'Close all other tabs' })
vim.keymap.set('n', '<leader>e', ':tabnew | Explore<CR>', { desc = 'File explorer in new tab' })

-- === File Explorer: Netrw Settings ===
vim.api.nvim_create_autocmd("filetype", {
  pattern = "netrw",
  callback = function()
    -- Allow `/` to start normal search in netrw
    vim.keymap.set('n', '/', '/', { buffer = true })
  end,
})
vim.g.netrw_banner = 0        -- disable banner
vim.g.netrw_liststyle = 3     -- tree-style view
vim.g.netrw_browse_split = 0  -- open files in same window
vim.g.netrw_winsize = 25

-- === OSC52 Copy Functionality ===
function osc52_copy()
  -- Helper function to send OSC52 sequence
  local function write(osc52)
    local success = false

    -- Try writing to /dev/fd/2 (stderr)
    if vim.fn.filewritable('/dev/fd/2') == 1 then
      success = vim.fn.writefile({osc52}, '/dev/fd/2', 'b') == 0
    else
      -- Fall back to chansend if the above fails
      success = vim.fn.chansend(vim.v.stderr, osc52) > 0
    end

    return success
  end

  local text = vim.fn.getreg('"')  -- Get the yanked text from the unnamed register (")
  local encoded_text = vim.fn.systemlist("echo -n " .. vim.fn.shellescape(text) .. " | base64")  -- Base64 encode the yanked text
  local osc52 = '\27]52;c;' .. table.concat(encoded_text, '') .. '\27\\'  -- Create the OSC52 control sequence

  -- Use write function to send OSC52 control sequence to terminal
  local success = write(osc52)

  if not success then
    vim.api.nvim_echo({{"Failed to copy selection", "ErrorMsg"}}, false, {})
  end
end

-- === Auto Commands ===
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  command = "checktime",
})

vim.api.nvim_create_autocmd("InsertLeave", {
  pattern = "*",
  command = "silent! wall",
})

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    local file = vim.fn.expand("<afile>")
    local dir = vim.fn.expand("<afile>:p:h")

    -- Ensure directory exists
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end

    -- Create .bak backup like nano if file exists
    if vim.fn.filereadable(file) == 1 then
      local backup = file .. '.bak'
      vim.fn.writefile(vim.fn.readfile(file), backup)
    end

    -- Remove trailing whitespace and restore view
    local save = vim.fn.winsaveview()
    vim.cmd([[silent! %s/\s\+$//e]])
    vim.fn.winrestview(save)
  end,
})

vim.api.nvim_create_autocmd("FocusLost", {
  pattern = "*",
  command = "stopinsert",
})

vim.api.nvim_create_autocmd("TextYankPost", {
  pattern = "*",
  callback = function()
    -- Highlight yanked text
    vim.highlight.on_yank { higroup = "IncSearch", timeout = 200 }

    -- Only copy to OSC52 if the operator is 'y' (meaning yank)
    if vim.v.event.operator == 'y' then
      osc52_copy()  -- Call the copy function when text is yanked
    end
  end,
})

-- === Highlight Setup ===
vim.cmd [[
  " Highlight TODO, FIXME, NOTE globally in the entire text
  function! HighlightTodoKeywords()
    " Match TODO, FIXME, and NOTE globally and highlight them
    call matchadd('TodoKeyword', '\(TODO\|FIXME\|NOTE\)', 100)
  endfunction

  " Apply the function on file open or syntax change
  autocmd Syntax * call HighlightTodoKeywords()
  autocmd BufEnter * call HighlightTodoKeywords()

  " Highlight extra whitespace (trailing spaces)
  highlight ExtraWhitespace ctermbg=red guibg=#ff5f5f
  match ExtraWhitespace /\s\+$/

  " Highlight TODO/FIXME/NOTE in yellow/orange and bold
  highlight TodoKeyword ctermfg=Yellow guifg=#FFA500 gui=bold
]]

-- === Other ===
vim.keymap.set('n', '<Esc>', '<Cmd>nohlsearch<CR>', { noremap = true, silent = true })

-- Disable filetype plugins & treesitter
vim.cmd('filetype plugin off')
