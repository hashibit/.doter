local M = {}

function M.setup()
  -- Enable filetype plugin and indent
  vim.cmd('filetype plugin indent on')

  -- Load matchparen plugin
  vim.cmd('runtime! plugin/matchparen.vim')

  -- File type settings
  vim.api.nvim_create_autocmd('FileType', {
      pattern = 'qf',
      command = 'wincmd J',
      desc = 'Move quickfix window to bottom'
  })

  -- JSON file types
  local json_patterns = { '*.json', '*.webapp', '*.jshintrc', '*.eslintrc' }
  vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
    pattern = json_patterns,
    callback = function()
      vim.bo.filetype = 'json'
    end,
    desc = 'Set JSON filetype for config files'
  })

  -- Language-specific indentation settings
  local indent_settings = {
    go = { shiftwidth = 4, softtabstop = 4, expandtab = false },
    cpp = { shiftwidth = 4, tabstop = 4, softtabstop = 4 },
    c = { shiftwidth = 4, tabstop = 4, softtabstop = 4 },
    h = { shiftwidth = 4, tabstop = 4, softtabstop = 4 },
    coffee = { shiftwidth = 2, softtabstop = 2 },
    javascript = { shiftwidth = 2, softtabstop = 2, tabstop = 2 },
    scss = { shiftwidth = 4, softtabstop = 4 },
    sh = { shiftwidth = 4, softtabstop = 4 },
    lua = { shiftwidth = 4, softtabstop = 4 },
    json = { shiftwidth = 4, softtabstop = 4 },
  }

  for filetype, settings in pairs(indent_settings) do
    local patterns = {}
    if filetype == 'cpp' then
      patterns = { '*.cpp', '*.cc', '*.hh' }
    elseif filetype == 'c' then
      patterns = { '*.c' }
    elseif filetype == 'h' then
      patterns = { '*.h' }
    elseif filetype == 'go' then
      patterns = { '*.go' }
    elseif filetype == 'coffee' then
      patterns = { '*.coffee' }
    elseif filetype == 'javascript' then
      patterns = { '*.js', '*.jsx', '*.ts', '*.tsx', '*.mjs', '*.cjs' }
    elseif filetype == 'scss' then
      patterns = { '*.scss' }
    elseif filetype == 'sh' then
      patterns = { '*.sh' }
    elseif filetype == 'lua' then
      patterns = { '*.lua' }
    elseif filetype == 'json' then
      patterns = { '*.json' }
    end

    if #patterns > 0 then
      vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
        pattern = patterns,
        callback = function()
          for option, value in pairs(settings) do
            vim.bo[option] = value
          end
        end,
        desc = 'Set ' .. filetype .. ' indentation'
      })
    end
  end

  -- Special file type mappings
  vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
    pattern = '*.coffee',
    callback = function()
      vim.bo.filetype = 'coffee'
    end,
    desc = 'Set CoffeeScript filetype'
  })

  vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
    pattern = '*.js',
    callback = function()
      vim.bo.filetype = 'javascript.jsx'
    end,
    desc = 'Set JavaScript with JSX support'
  })

  vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
    pattern = '*.ejs',
    callback = function()
      vim.bo.filetype = 'html'
    end,
    desc = 'Set EJS as HTML'
  })

  vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
    pattern = '*.qml',
    callback = function()
      vim.bo.filetype = 'qml'
    end,
    desc = 'Set QML filetype'
  })

  -- CoffeeScript compilation
  vim.api.nvim_create_autocmd('BufWritePost', {
    pattern = '*.coffee',
    command = 'silent make!',
    desc = 'Compile CoffeeScript on save'
  })

  -- QuickFix auto-open
  vim.api.nvim_create_autocmd('QuickFixCmdPost', {
    pattern = '*',
    command = 'nested cwindow | redraw!',
    desc = 'Auto-open quickfix window'
  })

  -- SCSS keyword settings
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'scss',
    callback = function()
      vim.bo.iskeyword = vim.bo.iskeyword .. ',-'
    end,
    desc = 'Include dash in SCSS keywords'
  })

  -- Markdown file detection
  vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
    pattern = { '*.md', '*.mdwn', '*.mkd', '*.mkdn', '*.mark*' },
    callback = function()
      vim.bo.filetype = 'markdown'
    end,
    desc = 'Set markdown filetype for various extensions'
  })

  -- Disable specific mappings for file tree types
  local tree_types = { 'vista', 'NvimTree' }
  local disabled_keys = { '<c-j>', '<c-i>', '<c-o>', '<c-h>', '<c-l>', '<c-e>', '<Leader>L', '<Leader>q', '<Leader>x', '<Leader>j' }

  vim.api.nvim_create_autocmd('FileType', {
    pattern = tree_types,
    callback = function()
      for _, key in ipairs(disabled_keys) do
        vim.keymap.set('n', key, '<nop>', { buffer = true, silent = true })
      end
    end,
    desc = 'Disable conflicting keymaps in file trees'
  })

  -- EasyMotion diagnostic management
  vim.api.nvim_create_autocmd('User', {
    pattern = 'EasyMotionPromptBegin',
    callback = function()
      vim.diagnostic.disable()
    end,
    desc = 'Disable diagnostics during EasyMotion'
  })

  vim.api.nvim_create_autocmd('User', {
    pattern = 'EasyMotionPromptEnd',
    callback = function()
      vim.defer_fn(function()
        vim.diagnostic.enable()
      end, 5000)
    end,
    desc = 'Re-enable diagnostics after EasyMotion'
  })

  -- BQF quickfix settings
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'qf',
    callback = function()
      vim.keymap.set('n', 'q', '<cmd>cclose<cr>', { buffer = true, silent = true })
    end,
    desc = 'Close quickfix with q'
  })

  -- Window view save/restore using our Lua functions
  local functions = require('config.functions')
  vim.api.nvim_create_autocmd('BufLeave', {
    pattern = '*',
    callback = functions.auto_save_win_view,
    desc = 'Save window view on buffer leave'
  })

  vim.api.nvim_create_autocmd('BufEnter', {
    pattern = '*',
    callback = functions.auto_restore_win_view,
    desc = 'Restore window view on buffer enter'
  })


  -- Remove trailing spaces on save
  vim.api.nvim_create_autocmd('BufWritePre', {
    pattern = '*',
    callback = function()
      local save_cursor = vim.fn.getpos('.')
      vim.cmd([[%s/\s\+$//e]])
      vim.fn.setpos('.', save_cursor)
    end,
    desc = 'Remove trailing whitespace on save'
  })

  -- Claude Code file tree keymaps
  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'NvimTree', 'neo-tree', 'oil' },
    callback = function()
      vim.keymap.set('n', '<leader>at', '<cmd>ClaudeCodeTreeAdd<cr>', {
        desc = 'Add file',
        buffer = true
      })
    end,
    desc = 'Set Claude Code keymaps for file trees'
  })

  -- Update lightline (if using lightline)
  if vim.fn.exists('*lightline#update') == 1 then
    vim.api.nvim_create_autocmd({ 'BufWritePost', 'TextChanged', 'TextChangedI' }, {
      pattern = '*',
      command = 'call lightline#update()',
      desc = 'Update lightline on text changes'
    })
  end
end

return M
