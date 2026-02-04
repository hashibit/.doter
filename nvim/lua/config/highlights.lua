-- Apply colorscheme
vim.cmd('colorscheme vscode')

-- Custom highlight settings using vim.cmd for compatibility
vim.cmd([[
  " Terminal colors
  hi Normal                  ctermfg=white       ctermbg=234         guibg=#181818
  hi NonText                 ctermfg=59          ctermbg=234         guifg=#415367       guibg=#181818
  hi EndOfBuffer             ctermfg=234         ctermbg=234         guifg=#181818       guibg=#181818
  hi LineNr                  ctermfg=59          ctermbg=234         guifg=#415367       guibg=#181818
  hi Search                  cterm=reverse       ctermfg=214         ctermbg=232         gui=reverse         guifg=goldenrod2    guibg=black
  hi SpellCap                ctermfg=black       ctermbg=green       guifg=black         guibg=springgreen

  " UI elements
  hi SignColumn              ctermfg=white       ctermbg=234         guifg=white         guibg=#181818
  hi WinSeparator            ctermfg=237                             guifg=#569CD6       guibg=NONE
  hi CursorLine              cterm=NONE                              gui=NONE            guibg=NONE

  " Multiple cursors
  hi multiple_cursors_cursor ctermfg=green       ctermbg=red         guifg=springgreen   guibg=red
  hi multiple_cursors_visual ctermfg=black       ctermbg=white       guifg=black         guibg=white

  " NvimTree
  hi NvimTreeNormal          ctermfg=white       ctermbg=234         guifg=white         guibg=#181818
  hi NvimTreeEndOfBuffer     ctermfg=234         ctermbg=234         guifg=#181818       guibg=#181818

  " Tabline
  hi TabLine                 ctermfg=white       ctermbg=234         guifg=white         guibg=#181818
  hi TabLineFill             ctermfg=white       ctermbg=234         guifg=white         guibg=#181818
  hi TabLineSel              ctermfg=white       ctermbg=237         guifg=white         guibg=#383b3e

  " BufferLine
  hi BufferLineFill          ctermfg=white       ctermbg=234         guifg=white         guibg=#181818
  hi BufferLineBackground    ctermfg=white       ctermbg=234         guifg=white         guibg=#181818
  hi BufferLineBuffer        ctermfg=white       ctermbg=234         guifg=white         guibg=#181818

  " LSP floating windows
  hi FloatBorder             guifg=#569CD6       guibg=NONE
  hi NormalFloat             guifg=white         guibg=#1e1e1e

  hi MatchParen guifg=#4cf600 guibg=#1c4f13
]])

-- Create autocmd to reapply highlights when colorscheme changes
vim.api.nvim_create_autocmd('ColorScheme', {
  pattern = '*',
  callback = function()
    vim.cmd([[
      " Reapply custom highlights
      hi FloatBorder           guifg=#569CD6       guibg=NONE
      hi NormalFloat           guifg=white         guibg=#1e1e1e
    ]])
  end,
  desc = 'Reapply custom highlights after colorscheme change'
})
