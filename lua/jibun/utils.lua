local M = {}

---@param date_str? string
---@return integer? timestamp
function M.parse_date(date_str)
	if not date_str or date_str == "" then
		return nil
	end
	local month, day, year = date_str:match("(%d+)/(%d+)/(%d+)")
	if not month then
		return nil
	end
	return os.time({ year = tonumber(year), month = tonumber(month), day = tonumber(day) })
end

---@param value any
---@return boolean
function M.is_number(value)
	return value and tonumber(value) ~= nil
end

---@param path string
---@param source_file string
---@return string
function M.normalize_link(path, source_file)
	-- add ../ if in a .query. table so relative links work
	local is_query_file = source_file:match("/query/")
	local is_note = path:match("^notes/")

	if is_query_file and is_note then
		return "../" .. path
	end
	return path
end

---@return boolean
function M.in_jibun_file()
	local filename = vim.api.nvim_buf_get_name(0)
	return filename:match("%.jibun/jibun%.md$") ~= nil
end

---@return boolean
function M.in_query_file()
	local filename = vim.api.nvim_buf_get_name(0)
	return filename:match("/%.jibun/query/.+%.md$") ~= nil
end

---@return boolean
function M.in_markdown_file()
	local ft = vim.bo.filetype
	local name = vim.api.nvim_buf_get_name(0)
	return ft == "markdown" or name:match("%.md$")
end

return M
