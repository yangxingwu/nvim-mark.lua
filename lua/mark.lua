-- MIT License
--
-- Copyright (c) 2024 Your Name (or your GitHub username)
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

--- lua/mark.lua
-- Core logic for the Neovim Mark plugin.
-- This module handles highlight group definition, state management,
-- applying/clearing extmarks, and the logic for the :Mark command and key mappings.

local M = {}

-- Define a namespace for our extmarks to manage them efficiently.
local mark_ns = vim.api.nvim_create_namespace("mark_plugin_namespace")

-- Default highlight colors matching vim-mark 'original' palette
-- Users can override these by setting vim.g.mark_plugin_colors
-- before the plugin loads (e.g., in their init.lua/init.vim).
local default_hl_colors = {
  "#8CCBEA", -- Cyan background (MarkWord1)
  "#A4E57E", -- Green background (MarkWord2)
  "#FFDB72", -- Yellow background (MarkWord3)
  "#FF7272", -- Red background (MarkWord4)
  "#FFB3FF", -- Magenta background (MarkWord5)
  "#9999FF", -- Blue background (MarkWord6)
}

-- Table to store dynamically created highlight group names.
local hl_groups = {}
-- Index to cycle through the available highlight colors.
local current_color_idx = 1

-- Global state for active marks.
-- Each entry:
-- {
--   pattern = "word_or_regex",
--   hl_group = "MarkHighlightX",
--   is_literal = true/false, -- true if pattern is a literal string, false if it's a regex
--   extmark_ids = {
--     [buf_id] = {id1, id2, ...} -- Stores extmark IDs for each buffer where this mark is applied
--   }
-- }
local active_marks = {}

--- M.setup()
-- Initializes the plugin by defining highlight groups.
function M.setup()
  -- Use user-defined colors if available, otherwise use defaults.
  local colors_to_use = vim.g.mark_plugin_colors or default_hl_colors

  -- Use Vim's standard MarkWord highlight groups
  for i, color in ipairs(colors_to_use) do
    local group_name = "MarkWord" .. i
    hl_groups[i] = group_name
    -- Set the highlight group with a background color. `force = true` ensures it takes precedence.
    vim.api.nvim_set_hl(0, group_name, { bg = color, force = true })
  end
end

--- apply_mark_to_buffer_literal(bufnr, mark_entry)
-- Applies a literal string mark to a specific buffer.
-- @param bufnr (number): The buffer number.
-- @param mark_entry (table): The mark entry containing pattern and highlight group.
local function apply_mark_to_buffer_literal(bufnr, mark_entry)
  local pattern = mark_entry.pattern
  local hl_group = mark_entry.hl_group

  -- Clear existing extmarks for this pattern in this buffer before re-applying.
  -- This prevents duplicate highlights if the buffer content changes or is reloaded.
  for _, extmark_id in ipairs(mark_entry.extmark_ids[bufnr] or {}) do
    pcall(vim.api.nvim_buf_del_extmark, bufnr, mark_ns, extmark_id)
  end
  mark_entry.extmark_ids[bufnr] = {} -- Reset the list of extmark IDs for this buffer.

  -- Get all lines from the buffer.
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- Iterate through each line to find occurrences of the pattern.
  for line_idx, line in ipairs(lines) do
    local col_start = 0
    -- Use string.find for literal string search. The 'true' argument makes it a plain search.
    while true do
      local start_pos, end_pos = string.find(line, pattern, col_start, true)
      if start_pos then
        -- Add an extmark for the found match.
        local extmark_id = vim.api.nvim_buf_set_extmark(
          bufnr,
          mark_ns,
          line_idx - 1, -- 0-indexed line number
          start_pos - 1, -- 0-indexed column start
          {
            end_col = end_pos, -- 0-indexed column end (exclusive)
            hl_group = hl_group,
          }
        )
        -- Store the extmark ID so we can clear it later.
        table.insert(mark_entry.extmark_ids[bufnr], extmark_id)
        col_start = assert(end_pos) -- Continue search from after the current match.
      else
        break -- No more matches on this line.
      end
    end
  end
end

--- apply_mark_to_buffer_regex(bufnr, mark_entry)
-- Applies a regex pattern mark to a specific buffer.
-- @param bufnr (number): The buffer number.
-- @param mark_entry (table): The mark entry containing pattern and highlight group.
local function apply_mark_to_buffer_regex(bufnr, mark_entry)
  local pattern = mark_entry.pattern
  local hl_group = mark_entry.hl_group

  -- Clear existing extmarks for this pattern in this buffer before re-applying.
  for _, extmark_id in ipairs(mark_entry.extmark_ids[bufnr] or {}) do
    pcall(vim.api.nvim_buf_del_extmark, bufnr, mark_ns, extmark_id)
  end
  mark_entry.extmark_ids[bufnr] = {}

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- Use vim.regex for proper Vim regex support
  local ok, regex = pcall(vim.regex, pattern)
  if not ok then
    vim.notify("Mark: Invalid regex pattern '" .. pattern .. "'", vim.log.levels.ERROR, { title = "Mark Plugin" })
    return
  end

  -- Iterate through each line to find occurrences of the regex pattern
  for line_idx, line in ipairs(lines) do
    local current_line_idx = line_idx - 1 -- 0-indexed line
    local col_start = 0

    while col_start < #line do
      local match_start, match_end = regex:match_str(line:sub(col_start + 1))
      if match_start then
        -- Adjust positions to account for the substring offset
        match_start = match_start + col_start
        match_end = match_end + col_start

        local extmark_id = vim.api.nvim_buf_set_extmark(
          bufnr,
          mark_ns,
          current_line_idx,
          match_start, -- 0-indexed column start
          {
            end_col = match_end, -- 0-indexed column end (exclusive)
            hl_group = hl_group,
          }
        )
        table.insert(mark_entry.extmark_ids[bufnr], extmark_id)

        -- Move to next position to find overlapping matches
        col_start = match_start + 1
      else
        break
      end
    end
  end
end

--- apply_all_marks_to_buffer(bufnr)
-- Applies all currently active marks to a specific buffer.
-- @param bufnr (number): The buffer number.
local function apply_all_marks_to_buffer(bufnr)
  for _, mark_entry in ipairs(active_marks) do
    if mark_entry.is_literal then
      apply_mark_to_buffer_literal(bufnr, mark_entry)
    else
      apply_mark_to_buffer_regex(bufnr, mark_entry)
    end
  end
end

--- clear_extmarks_for_buffer(bufnr)
-- Clears all extmarks managed by this plugin from a specific buffer.
-- @param bufnr (number): The buffer number.
local function clear_extmarks_for_buffer(bufnr)
  -- Clear all extmarks in our namespace from the given buffer.
  vim.api.nvim_buf_clear_namespace(bufnr, mark_ns, 0, -1)
  -- Also clear the stored extmark IDs from our active_marks state.
  for _, mark_entry in ipairs(active_marks) do
    mark_entry.extmark_ids[bufnr] = {}
  end
end

--- add_mark(pattern, is_literal)
-- Adds a new pattern to the active marks and applies it to the current buffer.
-- @param pattern (string): The word or regex pattern to mark.
-- @param is_literal (boolean): True if the pattern should be treated as a literal string, false for regex.
local function add_mark(pattern, is_literal)
  if not pattern or pattern:len() == 0 then
    vim.notify("Mark: No pattern provided.", vim.log.levels.WARN, { title = "Mark Plugin" })
    return
  end

  -- Check if pattern already exists to avoid duplicates.
  for _, mark_entry in ipairs(active_marks) do
    if mark_entry.pattern == pattern and mark_entry.is_literal == is_literal then
      vim.notify("Mark: Pattern '" .. pattern .. "' is already marked.", vim.log.levels.INFO, { title = "Mark Plugin" })
      return
    end
  end

  -- Get the next available highlight group from our defined colors.
  local hl_group = hl_groups[current_color_idx]
  -- Cycle to the next color for the next mark.
  current_color_idx = (current_color_idx % #hl_groups) + 1

  -- Create a new mark entry.
  local new_mark = {
    pattern = pattern,
    hl_group = hl_group,
    is_literal = is_literal,
    extmark_ids = {}, -- Initialize extmark_ids for this new mark.
  }
  table.insert(active_marks, new_mark)

  -- Apply the new mark to the current buffer.
  if is_literal then
    apply_mark_to_buffer_literal(vim.api.nvim_get_current_buf(), new_mark)
  else
    apply_mark_to_buffer_regex(vim.api.nvim_get_current_buf(), new_mark)
  end
  vim.notify("Marked '" .. pattern .. "' with color " .. hl_group, vim.log.levels.INFO, { title = "Mark Plugin" })
end

--- clear_mark(pattern)
-- Clears a specific mark by its pattern.
-- @param pattern (string): The pattern of the mark to clear.
local function clear_mark(pattern)
  if not pattern or pattern:len() == 0 then
    vim.notify("MarkClear: No pattern provided.", vim.log.levels.WARN, { title = "Mark Plugin" })
    return
  end

  local found_idx = -1
  for i, mark_entry in ipairs(active_marks) do
    if mark_entry.pattern == pattern then
      found_idx = i
      break
    end
  end

  if found_idx ~= -1 then
    local mark_entry = table.remove(active_marks, found_idx)
    -- Clear extmarks for this pattern across all buffers where it was applied.
    for bufnr, ids in pairs(mark_entry.extmark_ids) do
      for _, extmark_id in ipairs(ids) do
        pcall(vim.api.nvim_buf_del_extmark, bufnr, mark_ns, extmark_id)
      end
    end
    vim.notify("Cleared mark for '" .. pattern .. "'", vim.log.levels.INFO, { title = "Mark Plugin" })
  else
    vim.notify(
      "MarkClear: Pattern '" .. pattern .. "' not found in active marks.",
      vim.log.levels.WARN,
      { title = "Mark Plugin" }
    )
  end
end

--- clear_all_marks()
-- Clears all active marks from all buffers.
local function clear_all_marks()
  -- Iterate through all active marks and clear their associated extmarks.
  for _, mark_entry in ipairs(active_marks) do
    for bufnr, ids in pairs(mark_entry.extmark_ids) do
      for _, extmark_id in ipairs(ids) do
        pcall(vim.api.nvim_buf_del_extmark, bufnr, mark_ns, extmark_id)
      end
    end
  end
  active_marks = {} -- Reset the list of active marks.
  current_color_idx = 1 -- Reset color index for future marks.
  vim.notify("Cleared all marks.", vim.log.levels.INFO, { title = "Mark Plugin" })
end

--- list_marks()
-- Displays a list of all currently active marks.
local function list_marks()
  if #active_marks == 0 then
    vim.notify("No active marks.", vim.log.levels.INFO, { title = "Mark Plugin" })
    return
  end
  local msg = "Active Marks:\n"
  for _, mark_entry in ipairs(active_marks) do
    local type_str = mark_entry.is_literal and "Literal" or "Regex"
    msg = msg .. "  - '" .. mark_entry.pattern .. "' (Type: " .. type_str .. ", HL: " .. mark_entry.hl_group .. ")\n"
  end
  vim.notify(msg, vim.log.levels.INFO, { title = "Mark Plugin" })
end

--- M.mark_command(args)
-- The handler function for the :Mark user command.
-- Supports :Mark <pattern>, :Mark add <pattern>, :Mark clear [pattern], :Mark list.
-- @param args (table): Arguments passed by Neovim's user command system.
function M.mark_command(args)
  local cmd = args.fargs[1]
  -- Combine remaining arguments to form the pattern.
  local pattern = table.concat(vim.list_slice(args.fargs, 2), " ")

  if cmd == "clear" then
    if pattern and pattern:len() == 0 then -- Changed from > 0 to == 0 to allow :Mark clear
      clear_all_marks()
    else
      clear_mark(pattern)
    end
  elseif cmd == "list" then
    list_marks()
  elseif cmd == "add" then
    -- Explicit 'add' subcommand, always treat as regex unless user specifies literal via mapping.
    add_mark(pattern, false)
  elseif not cmd and args.args then
    -- Direct :Mark <pattern> usage. Check if pattern is wrapped in slashes for regex.
    if args.args:sub(1, 1) == "/" and args.args:sub(-1, -1) == "/" and args.args:len() > 2 then
      add_mark(args.args:sub(2, -2), false) -- Remove slashes, treat as regex
    else
      add_mark(args.args, true) -- Default to literal if no slashes
    end
  else
    vim.notify(
      "Mark: Unknown subcommand or invalid usage. Use: \n"
        .. "  :Mark <pattern> (literal or /regex/)\n"
        .. "  :Mark add <pattern> (regex)\n"
        .. "  :Mark clear [pattern]\n"
        .. "  :Mark list",
      vim.log.levels.ERROR,
      { title = "Mark Plugin" }
    )
  end
end

--- get_visual_selection()
-- Helper function to retrieve the text from the current visual selection.
-- @return (string|nil): The selected text, or nil if no visual selection.
local function get_visual_selection()
  -- Save current view and restore it later.
  local view = vim.fn.winsaveview()
  vim.cmd("normal! gv") -- Re-select last visual selection.

  local start_pos = vim.api.nvim_buf_get_mark(0, "<")
  local end_pos = vim.api.nvim_buf_get_mark(0, ">")

  if not start_pos or not end_pos then
    vim.fn.winrestview(view)
    return nil
  end

  local start_row, start_col = start_pos[1], start_pos[2]
  local end_row, end_col = end_pos[1], end_pos[2]

  -- nvim_buf_get_lines uses 0-indexed rows, but Lua string.sub is 1-indexed.
  -- end_row for nvim_buf_get_lines is exclusive, so we need end_row + 1.
  local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
  local selected_text = {}

  if start_row == end_row then
    -- Single line selection.
    table.insert(selected_text, string.sub(lines[1], start_col + 1, end_col))
  else
    -- Multi-line selection.
    table.insert(selected_text, string.sub(lines[1], start_col + 1)) -- First line from start_col
    for i = 2, #lines - 1 do
      table.insert(selected_text, lines[i]) -- Full intermediate lines
    end
    table.insert(selected_text, string.sub(lines[#lines], 1, end_col)) -- Last line up to end_col
  end

  vim.fn.winrestview(view) -- Restore original view.
  return table.concat(selected_text, "\n")
end

--- M.mark_visual()
-- Function to be called by the <Plug>MarkVisual mapping.
-- Marks the currently visually selected text as a literal string.
function M.mark_visual()
  local selected_text = get_visual_selection()
  if selected_text and selected_text:len() > 0 then
    add_mark(selected_text, true) -- Visual selection is always treated as a literal string.
  else
    vim.notify("Mark: No visual selection.", vim.log.levels.WARN, { title = "Mark Plugin" })
  end
  -- Exit visual mode after marking
  vim.cmd("normal! \\<Esc>")
end

--- M.mark_word()
-- Function to be called by the <Plug>MarkWord mapping.
-- Marks the word under the cursor as a literal string.
function M.mark_word()
  local word = vim.fn.expand("<cword>") -- Get the word under the cursor.
  if word and word:len() > 0 then
    add_mark(word, true) -- Word under cursor is always treated as a literal string.
  else
    vim.notify("Mark: No word under cursor.", vim.log.levels.WARN, { title = "Mark Plugin" })
  end
end

--- M.autocmds()
-- Sets up Neovim autocommands for managing marks across buffers and sessions.
function M.autocmds()
  -- Autocmd Group for Mark Plugin to allow clearing.
  local mark_augroup = vim.api.nvim_create_augroup("MarkPluginAutocmds", { clear = true })

  -- Apply marks when entering a buffer.
  vim.api.nvim_create_autocmd("BufEnter", {
    group = mark_augroup,
    callback = function(args)
      apply_all_marks_to_buffer(args.buf)
    end,
  })

  -- Re-apply marks on BufWritePost in case content changes.
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = mark_augroup,
    callback = function(args)
      apply_all_marks_to_buffer(args.buf)
    end,
  })

  -- Clear marks for a buffer when it's unloaded or closed.
  vim.api.nvim_create_autocmd("BufUnload", {
    group = mark_augroup,
    callback = function(args)
      clear_extmarks_for_buffer(args.buf)
    end,
  })

  -- Clear all marks when Neovim is about to exit.
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = mark_augroup,
    callback = function()
      clear_all_marks()
    end,
  })
end

--- M.get_active_patterns()
-- Exposes active patterns for tab completion of :Mark clear.
-- @return (table): A list of strings, where each string is an active pattern.
function M.get_active_patterns()
  local patterns = {}
  for _, m in ipairs(active_marks) do
    table.insert(patterns, m.pattern)
  end
  return patterns
end

return M
