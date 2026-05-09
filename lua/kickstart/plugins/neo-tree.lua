-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

local plugins = {
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim', version = vim.version.range '*' },
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/MunifTanjim/nui.nvim',
}

if vim.g.have_nerd_font then
  table.insert(plugins, 'https://github.com/nvim-tree/nvim-web-devicons') -- not strictly required, but recommended
end

vim.pack.add(plugins)

vim.keymap.set('n', '\\', '<Cmd>Neotree reveal<CR>', { desc = 'NeoTree reveal', silent = true })

local neotree = require 'neo-tree'

--- @param state neotree.StateWithTree
local function toggle_terminal(state)
  local function find_last(haystack, needle)
    local found = haystack:reverse():find(needle:reverse(), nil, true)
    if found then
      return haystack:len() - needle:len() - found + 2
    else
      return found
    end
  end

  local node = state.tree:get_node()
  local neo_tree = vim.api.nvim_get_current_win()
  local tabpage = vim.api.nvim_win_get_tabpage(neo_tree)
  local wins = vim.api.nvim_tabpage_list_wins(tabpage)

  local path = nil
  if node.type == 'file' then
    local path_end = find_last(node.path, '/')
    path = string.sub(node.path, 0, path_end - 1)
  elseif node.type == 'directory' then
    path = node.path
  else
    vim.notify('Unknown node type ' .. node.type, vim.log.levels.ERROR)
    return
  end

  local target_win = nil
  for _, win in ipairs(wins) do
    if win ~= neo_tree then
      target_win = win
      break
    end
  end
  if not target_win then
    vim.notify('Suitable target window not found', vim.log.levels.ERROR)
    return
  end

  vim.api.nvim_set_current_win(target_win)
  local cmd = ':let $CD_DIR="' .. path .. '"\n:terminal\n:startinsert!\n'
  vim.api.nvim_exec2(cmd, {})
end

neotree.setup {
  close_if_last_window = true,
  filesystem = {
    window = {
      mappings = {
        ['\\'] = 'close_window',
        ['t'] = {
          'open_tabnew',
          nowait = false,
        },
        ['tt'] = {
          toggle_terminal,
          desc = 'toggle_terminal',
          nowait = true,
        },
      },
    },
  },
}
