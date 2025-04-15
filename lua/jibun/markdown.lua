local utils = require("jibun.utils")
local config = require("jibun.config")

local M = {}

---@param headers string[]
---@param rows Todo[]
---@param source_file? string
---@return string[] lines
function M.create_markdown_table(headers, rows, source_file)
	source_file = source_file or ""
	local lines = {}

	if #headers > 0 then
		-- header row
		table.insert(lines, "| " .. table.concat(headers, " | ") .. " |")

		-- separator row
		local separators = {}
		for _ in ipairs(headers) do
			table.insert(separators, "---")
		end
		table.insert(lines, "|" .. table.concat(separators, "|") .. "|")

		-- data rows
		for _, row in ipairs(rows) do
			local processed = {}
			for i, field in ipairs(row.fields) do
				local header_lower = headers[i]:lower()
				if header_lower == "notes" then
					local link = field:match("%((.-)%)")
					if link then
						local normalized = utils.normalize_link(link, source_file)
						processed[i] = field:gsub("%(.-%)", "(" .. normalized .. ")")
					else
						processed[i] = field
					end
				else
					processed[i] = field
				end
			end
			table.insert(lines, "| " .. table.concat(processed, " | ") .. " |")
		end
	end

	return lines
end

---@param notes_path string
---@param todo Todo
---@return boolean
function M.make_new_notes_md(notes_path, todo)
	if vim.fn.filereadable(notes_path) == 0 then
		local dir = vim.fn.fnamemodify(notes_path, ":h")
		vim.fn.mkdir(dir, "p")
		local file = io.open(notes_path, "w")
		if file then
			-- calculate relative path to jibun.md
			local jibun_dir = config.current.root_dir .. "/.jibun/"
			local notes_rel_path = notes_path:sub(#jibun_dir + 2)
			local notes_base = "notes/"
			local rel_to_notes = notes_rel_path:sub(#notes_base + 1)
			local dir_depth = #vim.split(vim.fn.fnamemodify(rel_to_notes, ":h"), "/")

			local backlink = string.rep("../", dir_depth + 1) .. "jibun.md"

			local content = "# " .. todo.task .. "\n" .. string.format("[back to jibun.md](%s)\n\n", backlink)

			file:write(content)
			file:close()
			vim.notify("created md file: " .. notes_path, vim.log.levels.INFO)
			return true
		else
			vim.notify("failed to create file: " .. notes_path, vim.log.levels.ERROR)
			return false
		end
	end
	return true -- file already exists
end

---@param headers string[]
---@param todos Todo[]
---@param query_path string
---@param title string
---@return boolean
function M.make_new_query_md(headers, todos, query_path, title)
	local dir = vim.fn.fnamemodify(query_path, ":h")
	vim.fn.mkdir(dir, "p")
	local file = io.open(query_path, "w")
	if file then
		local lines = M.create_markdown_table(headers, todos, query_path)
		local content = "# "
			.. title
			.. "\n"
			.. string.format("[back to jibun.md](../jibun.md)\n\n")
			.. table.concat(lines, "\n")
		file:write(content)
		file:close()
		return true
	else
		vim.notify("failed to update file: " .. query_path, vim.log.levels.ERROR)
		return false
	end
end

---@return nil
function M.follow_next_md_link()
	local current_file = vim.api.nvim_buf_get_name(0)
	local current_dir = vim.fn.fnamemodify(current_file, ":h")
	local line_count = vim.api.nvim_buf_line_count(0)
	local current_line = vim.api.nvim_win_get_cursor(0)[1]

	local function resolve_path(link_path)
		-- absolute paths
		if link_path:match("^/") then
			return link_path
		end
		-- relative paths
		return vim.fn.resolve(current_dir .. "/" .. link_path)
	end

	local function get_md_link_from_line(line_num)
		local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
		return line and line:match("%[.-%]%((.-)%)")
	end

	local function open_file_or_notify(file_path)
		local resolved = resolve_path(file_path)
		if vim.fn.filereadable(resolved) == 1 then
			vim.cmd("edit " .. resolved)
		else
			vim.notify("file not found: " .. resolved, vim.log.levels.ERROR)
		end
	end

	for i = current_line, line_count do
		local file_path = get_md_link_from_line(i)
		if file_path then
			return open_file_or_notify(file_path)
		end
	end

	-- wrap to top of doc if needed
	for i = 1, current_line - 1 do
		local file_path = get_md_link_from_line(i)
		if file_path then
			return open_file_or_notify(file_path)
		end
	end

	vim.notify("no markdown links found in document", vim.log.levels.WARN)
end

---@type integer
local ns_id = vim.api.nvim_create_namespace("jibun_md_highlights")

-- highlight rows based on completion status and due dates
---@return nil
function M.highlight_table_rows()
	local buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

	local header_line, header_row
	for i, line in ipairs(lines) do
		if line:match("^|") and line:match("|$") then
			if i < #lines and lines[i + 1]:match("^|[-:|]+|$") then
				header_line = line
				header_row = i
				break
			end
		end
	end

	if not header_line then
		return
	end

	local headers = {}
	for header in header_line:gmatch("|([^|]+)") do
		table.insert(headers, vim.trim(header):lower())
	end

	local complete_col, due_col
	for i, header in ipairs(headers) do
		if header == "complete" then
			complete_col = i
		elseif header == "due" then
			due_col = i
		end
	end

	if not complete_col or not due_col then
		return
	end

	-- highlight rows
	for i = header_row + (lines[header_row + 1]:match("^|[-:|]+|$") and 2 or 1), #lines do
		local line = lines[i]
		if line and line:match("^|") and line:match("|$") then
			local columns = {}
			for col in line:gmatch("|([^|]+)") do
				table.insert(columns, vim.trim(col))
			end

			if #columns >= math.max(complete_col, due_col) then
				local comp = columns[complete_col]:upper()
				local ddate_str = columns[due_col]
				local ddate = utils.parse_date(ddate_str)
				local line_index = i - 1

				if comp == "FALSE" and ddate then
					local now = os.time()
					if ddate - now < 60 * 60 * 24 then
						vim.api.nvim_buf_add_highlight(buf, ns_id, "constant", line_index, 0, -1)
					elseif ddate - now < 60 * 60 * 24 * 3 then
						vim.api.nvim_buf_add_highlight(buf, ns_id, "Conditional", line_index, 0, -1)
					end
				elseif comp == "TRUE" then
					vim.api.nvim_buf_add_highlight(buf, ns_id, "comment", line_index, 0, -1)
				end
			end
		end
	end
end

return M
