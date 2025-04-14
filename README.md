# 自分

a task management plugin for nvim

## setup

```lua
{
    "jbgreenh/jibun.nvim",
	config = function()
		require("jibun").setup({ root_dir = "~" })
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
	},
}

```
