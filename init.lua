-- Basic Settings
vim.opt.number = true                          -- Show line numbers
vim.opt.relativenumber = true                  -- Show relative line numbers
vim.opt.hlsearch = true                        -- Highlight search results
vim.opt.incsearch = true                       -- Incremental search
vim.opt.ignorecase = true                      -- Ignore case in search patterns
vim.opt.smartcase = true                       -- Override ignorecase if search pattern contains uppercase
vim.opt.expandtab = true                       -- Use spaces instead of tabs
vim.opt.tabstop = 4                            -- Set the width of a tab character to 4 spaces
vim.opt.shiftwidth = 4                         -- Set the number of spaces to use for autoindenting
vim.opt.softtabstop = 4                        -- Set the number of spaces for a Tab in insert mode
vim.opt.wrap = false                           -- Disable line wrapping
vim.opt.cursorline = true                      -- Highlight the current line
vim.opt.clipboard = "unnamedplus"              -- Use system clipboard for yanking and pasting

-- Enable list mode to show whitespace characters
vim.opt.list = true

-- Customize list characters
vim.opt.listchars = {
  tab = '▸ ',
  space = '·',
  eol = '↴',
}

-- Key Mappings
vim.g.mapleader = " "                          -- Set the leader key to space

-- Save and quit
vim.api.nvim_set_keymap('n', '<leader>w', ':w<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<leader>q', ':q<CR>', { noremap = true })

-- Move lines up and down
vim.api.nvim_set_keymap('n', '<A-j>', ':m .+1<CR>==', { noremap = true })
vim.api.nvim_set_keymap('n', '<A-k>', ':m .-2<CR>==', { noremap = true })
vim.api.nvim_set_keymap('i', '<A-j>', '<Esc>:m .+1<CR>==gi', { noremap = true })
vim.api.nvim_set_keymap('i', '<A-k>', '<Esc>:m .-2<CR>==gi', { noremap = true })
vim.api.nvim_set_keymap('v', '<A-j>', ':m \'>+1<CR>gv=gv', { noremap = true })
vim.api.nvim_set_keymap('v', '<A-k>', ':m \'<-2<CR>gv=gv', { noremap = true })

-- Map 'jk' to Esc
vim.api.nvim_set_keymap('i', 'jk', '<Esc>', { noremap = true })
vim.api.nvim_set_keymap('i', 'kj', '<Esc>', { noremap = true })

-- Map 'jj' to Esc
vim.api.nvim_set_keymap('i', 'jj', '<Esc>', { noremap = true })

-- Move up in insert mode
vim.api.nvim_set_keymap('i', '<C-k>', '<Esc>ka', { noremap = true, silent = true })

-- Move down in insert mode
vim.api.nvim_set_keymap('i', '<C-j>', '<Esc>ja', { noremap = true, silent = true })

-- Move left in insert mode
vim.api.nvim_set_keymap('i', '<C-h>', '<Esc>ha', { noremap = true, silent = true })

-- Move right in insert mode
vim.api.nvim_set_keymap('i', '<C-l>', '<Esc>la', { noremap = true, silent = true })

-- Enable the status line
vim.o.laststatus = 2

-- Define the status line format
vim.o.statusline = table.concat({
  "%#StatusLine#",              -- Highlight group for the main section
  "%F",                         -- File path
  "%h",                         -- Help flag
  "%m",                         -- Modified flag
  "%r",                         -- Read-only flag
  "%#StatusLineNC#",            -- Highlight group for secondary sections
  "%=",                         -- Right-align the rest
  "%y",                         -- File type
  "%{&fileencoding?&fileencoding:&encoding}", -- File encoding
  "%{&fileformat}",             -- File format (e.g., unix, dos)
  " [%p%%]",                    -- File percentage through
  " %l/%L:%c",                  -- Line number/Total lines: Column number
})

-- Set color for line numbers
vim.o.termguicolors = true
vim.cmd[[highlight LineNr guifg=#FF0000]]   -- Red color for line numbers
vim.cmd[[highlight CursorLineNr guifg=#00FF00]]  -- Green color for the current line number

-- Customize the highlight groups for list characters
vim.api.nvim_set_hl(0, 'Whitespace', { fg = '#808080' }) -- Grey color
vim.api.nvim_set_hl(0, 'TabLine', { fg = '#808080' })   -- Grey color
vim.api.nvim_set_hl(0, 'EndOfLine', { fg = '#808080' }) -- Grey color
