# highlight-str-nvim 插件

一个简单的 Neovim 插件，用于高亮显示文件中多个单词或正则表达式，类似于 Vim 内置的 hlsearch 和 * 命令。这对于在大型代码文件或文档中追踪多个标识符或概念非常有用。

该插件旨在完整复制 [inkarkat/vim-mark](https://github.com/inkarkat/vim-mark) 的核心功能。

## ✨ 特性

- 多重高亮：同时高亮显示多个单词或正则表达式，每个使用不同的颜色。
- `:Mark` 命令：通过灵活的命令界面添加、清除和列出标记。
- 快捷键映射：快速高亮光标下的单词或视觉选择的文本。
- 持久性：标记在缓冲区切换和文件保存后会自动重新应用。
- 可自定义颜色：轻松配置您自己的高亮颜色。

## 🚀 安装

您可以使用任何您喜欢的 Neovim 插件管理器来安装 `highlight-str-nvim`。

`lazy.nvim`

```lua
-- init.lua
{
  'your-github-username/highlight-str-nvim', -- 请替换为您的 GitHub 用户名和仓库名
  config = function()
    require('mark').setup()
    require('mark').autocmds() -- 确保 autocommands 被设置

    -- 可选：自定义颜色 (在 setup() 之前设置)
    -- vim.g.mark_plugin_colors = {
    --     "#FFC0CB", -- 粉色
    --     "#ADD8E6", -- 浅蓝色
    --     "#90EE90", -- 浅绿色
    --     "#FFD700", -- 金色
    -- }

    -- 默认快捷键映射 (推荐添加到您的 init.lua)
    vim.keymap.set({"n", "v"}, "<leader>m", "<Plug>MarkWord", { desc = "Mark: 高亮光标下或视觉选择的单词" })
    vim.keymap.set("v", "<leader>M", "<Plug>MarkVisual", { desc = "Mark: 高亮视觉选择的文本" })
    vim.keymap.set("n", "<leader>mc", ":Mark clear<CR>", { desc = "Mark: 清除所有标记" })
    vim.keymap.set("n", "<leader>ml", ":Mark list<CR>", { desc = "Mark: 列出所有标记" })
    vim.keymap.set("n", "<leader>mC", ":Mark clear <C-r><C-w><CR>", { desc = "Mark: 清除光标下单词的标记" })
  end
}
```

`packer.nvim`

```lua
-- init.lua
use {
  'your-github-username/highlight-str-nvim', -- 请替换为您的 GitHub 用户名和仓库名
  config = function()
    require('mark').setup()
    require('mark').autocmds()

    -- 默认快捷键映射 (推荐添加到您的 init.lua)
    vim.keymap.set({"n", "v"}, "<leader>m", "<Plug>MarkWord", { desc = "Mark: 高亮光标下或视觉选择的单词" })
    vim.keymap.set("v", "<leader>M", "<Plug>MarkVisual", { desc = "Mark: 高亮视觉选择的文本" })
    vim.keymap.set("n", "<leader>mc", ":Mark clear<CR>", { desc = "Mark: 清除所有标记" })
    vim.keymap.set("n", "<leader>ml", ":Mark list<CR>", { desc = "Mark: 列出所有标记" })
    vim.keymap.set("n", "<leader>mC", ":Mark clear <C-r><C-w><CR>", { desc = "Mark: 清除光标下单词的标记" })
  end
}
```

`vim-plug`

```
" init.vim
Plug 'your-github-username/highlight-str-nvim' " 请替换为您的 GitHub 用户名和仓库名

" 在 init.vim 中配置
lua << EOF
  require('mark').setup()
  require('mark').autocmds()

  -- 默认快捷键映射
  vim.keymap.set({"n", "v"}, "<leader>m", "<Plug>MarkWord", { desc = "Mark: 高亮光标下或视觉选择的单词" })
  vim.keymap.set("v", "<leader>M", "<Plug>MarkVisual", { desc = "Mark: 高亮视觉选择的文本" })
  vim.keymap.set("n", "<leader>mc", ":Mark clear<CR>", { desc = "Mark: 清除所有标记" })
  vim.keymap.set("n", "<leader>ml", ":Mark list<CR>", { desc = "Mark: 列出所有标记" })
  vim.keymap.set("n", "<leader>mC", ":Mark clear <C-r><C-w><CR>", { desc = "Mark: 清除光标下单词的标记" })
EOF
```

## 💡 使用方法

### 命令

- `:Mark <pattern>`
  - 高亮显示 `<pattern>`。
  - 如果 `<pattern>` 用斜杠 `/` 包裹（例如 `/my_regex/`），则将其视为正则表达式。否则，将其视为字面字符串。
  - `:Mark my_variable` (高亮字面字符串 "my_variable")
  - `:Mark /function\s*call/` (高亮正则表达式 `function\s*call`)
- `:Mark add <pattern>`
  - 明确地添加一个模式进行高亮。该模式始终被视为正则表达式。
  - 示例：`:Mark add ^local` (高亮所有以 "local" 开头的行)
- `:Mark clear [pattern]`
  - 不带参数时，清除所有活动标记。
  - 带参数时，清除指定模式的标记。
  - 示例：
    - `:Mark clear` (清除所有标记)
    - `:Mark clear my_variable` (清除 "my_variable" 的标记)
    - Tab 补全：在 `:Mark clear` 后按 Tab 键可以补全当前活动的模式。
- `:Mark list`
  - 列出所有当前活动的标记，包括它们的模式、类型（字面或正则表达式）和高亮组。

### 快捷键映射

这些是插件提供的 `<Plug>` 映射。您需要将它们映射到您自己的快捷键。

- `<Plug>MarkWord`
  - 在普通模式下：高亮光标下的单词。
  - 在视觉模式下：高亮当前视觉选择的文本。
  - 示例映射：`nmap <Leader>m <Plug>MarkWord`
- `<Plug>MarkVisual`
  - 仅在视觉模式下：高亮当前视觉选择的文本。
  - 示例映射：`vmap <Leader>M <Plug>MarkVisual`

## ⚙️ 配置

您可以通过在插件加载之前（例如在 `init.lua` 或 `init.vim` 的顶部）设置全局变量 `vim.g.mark_plugin_colors` 来自定义高亮颜色。

```lua
-- init.lua
vim.g.mark_plugin_colors = {
    "#FFC0CB", -- 粉色
    "#ADD8E6", -- 浅蓝色
    "#90EE90", -- 浅绿色
    "#FFD700", -- 金色
    "#BA55D3", -- 中兰紫色
    -- 添加更多十六进制颜色代码以获得更多高亮选项
}

-- 确保在设置颜色后加载插件
-- require('lazy').setup({...}) 或 use {...}
```

## 🤝 贡献

欢迎贡献！如果您有任何功能请求、错误报告或改进建议，请随时在 GitHub 仓库中提交 issue 或 pull request。

## 📜 许可

本项目在 MIT 许可下发布。有关详细信息，请参阅 lua/mark.lua 文件顶部的许可声明。

## 🙏 致谢

[inkarkat/vim-mark](https://github.com/inkarkat/vim-mark)：本插件的灵感来源和功能参考。
