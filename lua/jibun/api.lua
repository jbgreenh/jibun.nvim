local util = require("jibun.utils")
local todo = require("jibun.todos")
local markdown = require("jibun.markdown")
local config = require("jibun.config")

local M = {}

-- update the todo under the cursor in jibun.md or a query md file
---@param header_name HeaderName
function M.update_under_cursor(header_name)
	if not util.in_jibun_file() and not util.in_query_file() then
		return
	end
	local _, todos = todo.read_jibun_csv()
	todo.update_under_cursor(todos, header_name)
end

-- folow the next link in an md file, wraps to the top of the file if neccessary, works with absolute and relative links
function M.follow_link()
	if util.in_markdown_file() then
		markdown.follow_next_md_link()
	end
end

-- add a todo
function M.add_todo()
	if not util.in_jibun_file() and not util.in_query_file() then
		return
	end
	local _, todos = todo.read_jibun_csv()
	todo.add(todos)
end

-- open jibun.md
function M.open_jibun()
	local jibun_md_path = config.current.root_dir .. "/.jibun/jibun.md"
	if vim.fn.filereadable(jibun_md_path) then
		vim.cmd.edit(jibun_md_path)
	else
		todo.refresh_jibun()
		vim.cmd("edit! " .. jibun_md_path)
	end
end

return M
