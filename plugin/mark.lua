--- plugin/mark.lua
-- This file serves as the entry point for the Neovim Mark plugin.
-- It is loaded automatically by Neovim because it resides in the 'plugin' directory.

-- Ensure the Lua module is loaded only once to prevent re-initialization issues.
if vim.g.mark_plugin_loaded then
  return
end
vim.g.mark_plugin_loaded = true

-- Load the main Lua module containing the plugin's logic.
local mark = require("mark")

-- Call the setup function to define highlight groups.
mark.setup()
-- Set up autocommands for managing marks across buffers.
mark.autocmds()

-- Create the :Mark user command.
-- It accepts variable arguments (`nargs = "*"`) and provides tab completion.
vim.api.nvim_create_user_command(
  "Mark",
  mark.mark_command, -- The handler function for the command.
  {
    nargs = "*", -- Accepts zero or more arguments.
    -- Custom completion function for the command.
    complete = function(_, cmdline, _)
      local args = vim.split(cmdline, "%s+", { plain = true, trimempty = true })
      if #args == 1 then
        -- If only ":Mark" is typed, suggest subcommands.
        return { "add", "clear", "list" }
      elseif #args == 2 and args[2] == "clear" then
        -- If ":Mark clear" is typed, suggest currently active patterns for clearing.
        return mark.get_active_patterns()
      end
      return {} -- No completion for other cases.
    end,
    desc = "Highlight words/patterns with different colors", -- Description for :h :Mark.
  }
)

-- Define default key mappings using <Plug> mappings.
-- These mappings are not active by default but can be mapped by the user
-- in their `init.lua` or `init.vim` to their preferred key combinations.

-- Normal and Visual mode mapping to mark the word under the cursor or visual selection.
vim.keymap.set(
  { "n", "v" },
  "<Plug>MarkWord",
  mark.mark_word,
  { desc = "Mark word under cursor (or visual selection in visual mode)" }
)
-- Visual mode specific mapping to mark the visual selection.
vim.keymap.set("v", "<Plug>MarkVisual", mark.mark_visual, { desc = "Mark visual selection" })

-- Example mappings you can add to your `init.lua` or `init.vim`:
--
-- Lua (init.lua):
-- vim.keymap.set("n", "<leader>m", "<Plug>MarkWord", { desc = "Mark word" })
-- vim.keymap.set("v", "<leader>m", "<Plug>MarkVisual", { desc = "Mark visual selection" })
-- vim.keymap.set("n", "<leader>mc", ":Mark clear<CR>", { desc = "Clear all marks" })
-- vim.keymap.set("n", "<leader>ml", ":Mark list<CR>", { desc = "List marks" })
--
-- Vimscript (init.vim):
-- nmap <Leader>m <Plug>MarkWord
-- vmap <Leader>m <Plug>MarkVisual
-- nmap <Leader>mc :Mark clear<CR>
-- nmap <Leader>ml :Mark list<CR>
