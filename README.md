# 自分

a task management plugin for nvim

## setup

set the `root_dir` option with where you want the `/.jibun/` directory to live (defaults to `~/.local/share/nvim/jibun`):

```lua

require("jibun").setup({ root_dir = "~" })
```

set the `warn_days` option to set how long before the due date todos should be highlighted (defaults to 7)  
find suggested setup using lazy below:

```lua
{
	"jbgreenh/jibun.nvim",
	config = function()
		require("jibun").setup({
            root_dir = "~",
            warn_days = 7, -- default
        })
	end,
	keys = {
		{
			"<leader>jb",
			function()
				require("jibun").open_jibun()
			end,
			desc = "open jibun",
		},
		{
			"<leader>jl",
			function()
				require("jibun").follow_link()
			end,
			desc = "follow next md link",
		},
		{
			"<leader>jc",
			function()
				require("jibun").update_under_cursor("complete")
			end,
			desc = "toggle complete",
		},
		{
			"<leader>jd",
			function()
				require("jibun").update_under_cursor("due")
			end,
			desc = "edit due date",
		},
		{
			"<leader>jn",
			function()
				require("jibun").update_under_cursor("notes")
			end,
			desc = "edit notes",
		},
		{
			"<leader>jt",
			function()
				require("jibun").update_under_cursor("task")
			end,
			desc = "edit task",
		},
		{
			"<leader>jg",
			function()
				require("jibun").update_under_cursor("tags")
			end,
			desc = "edit tags",
		},
		{
			"<leader>ja",
			function()
				require("jibun").add_todo()
			end,
			desc = "add todo",
		},
		{
			"<leader>jx",
			function()
				require("jibun").remove_under_cursor()
			end,
			desc = "remove todo",
		},
	},
}

```

### planned features

- add a delete function [complete]
- add a way for users to add custom queries
