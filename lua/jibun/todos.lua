local utils = require("jibun.utils")
local markdown = require("jibun.markdown")
local config = require("jibun.config")

local jibun_csv_headers = "n,complete,task,tags,created,due,completed,notes,modified\n"

local M = {}

---@return string[] headers
---@return Todo[] todos
function M.read_jibun_csv()
	local jibun_dir = config.current.root_dir .. "/.jibun/"
	local jibun_csv_path = jibun_dir .. "jibun.csv"
	local file = io.open(jibun_csv_path, "r")
	if not file then
		vim.fn.mkdir(vim.fn.fnamemodify(jibun_csv_path, ":h"), "p")
		file = assert(io.open(jibun_csv_path, "w"))
		file:write(jibun_csv_headers)
		file:close()
		file = assert(io.open(jibun_csv_path, "r"))
	end

	local contents = file:read("*a")
	file:close()

	-- parse csv
	local headers = {}
	local todos = {}

	for i, line in ipairs(vim.split(contents, "[\r\n]+")) do
		if #line > 0 then -- skip empty lines
			local fields = vim.split(line, ",%s*")
			if i == 1 then
				headers = fields
			else
				-- initialize todo with all fields
				local todo = {
					fields = fields,
					n = nil,
					complete = nil,
					task = nil,
					tags = nil,
					created = nil,
					due = nil,
					completed = nil,
					notes = nil,
					modified = nil,
				}

				-- map each field by header name
				for j, header in ipairs(headers) do
					local lower_header = header:lower()
					if lower_header == "n" then
						todo.n = fields[j]
					elseif lower_header == "complete" then
						todo.complete = fields[j]
					elseif lower_header == "task" then
						todo.task = fields[j]
					elseif lower_header == "tags" then
						todo.tags = fields[j]
					elseif lower_header == "created" then
						todo.created = fields[j]
					elseif lower_header == "due" then
						todo.due = fields[j]
					elseif lower_header == "completed" then
						todo.completed = fields[j]
					elseif lower_header == "notes" then
						todo.notes = fields[j]
					elseif lower_header == "modified" then
						todo.modified = fields[j]
					end
				end

				table.insert(todos, todo)
			end
		end
	end

	return headers, todos
end

---@param headers string[]
---@param todos Todo[]
---@param selected_headers string[]
---@return string[] new_headers
---@return Todo[] new_todos
function M.select(headers, todos, selected_headers)
	local lower_selected = {}
	for _, header in ipairs(selected_headers) do
		table.insert(lower_selected, header:lower())
	end

	local header_positions = {}
	for i, header in ipairs(headers) do
		header_positions[header:lower()] = i
	end

	local new_headers = {}
	local selected_positions = {}
	for _, selected in ipairs(lower_selected) do
		if header_positions[selected] then
			table.insert(new_headers, headers[header_positions[selected]])
			table.insert(selected_positions, header_positions[selected])
		end
	end

	local new_todos = {}
	for _, todo in ipairs(todos) do
		local new_fields = {}
		local new_todo = {
			fields = new_fields,
			n = nil,
			complete = nil,
			task = nil,
			tags = nil,
			created = nil,
			due = nil,
			completed = nil,
			notes = nil,
			modified = nil,
		}

		for _, pos in ipairs(selected_positions) do
			table.insert(new_fields, todo.fields[pos])

			local header_lower = headers[pos]:lower()
			if header_lower == "n" then
				new_todo.n = todo.n
			elseif header_lower == "complete" then
				new_todo.complete = todo.complete
			elseif header_lower == "task" then
				new_todo.task = todo.task
			elseif header_lower == "tags" then
				new_todo.tags = todo.tags
			elseif header_lower == "created" then
				new_todo.created = todo.created
			elseif header_lower == "due" then
				new_todo.due = todo.due
			elseif header_lower == "completed" then
				new_todo.completed = todo.completed
			elseif header_lower == "notes" then
				new_todo.notes = todo.notes
			elseif header_lower == "modified" then
				new_todo.modified = todo.modified
			end
		end

		table.insert(new_todos, new_todo)
	end

	return new_headers, new_todos
end

---@param headers string[]
---@param todos Todo[]
---@param header_name HeaderName
---@param operator FilterOperator
---@param value string|number|nil
---@return string[] headers
---@return Todo[] filtered
function M.filter(headers, todos, header_name, operator, value)
	local filtered = {}

	local property = header_name:lower()

	for _, todo in ipairs(todos) do
		local field_value = todo[property]
		local match = false

		-- numeric comparisons
		if utils.is_number(field_value) and utils.is_number(value) then
			local num_val = tonumber(field_value)
			local num_compare = tonumber(value)

			if operator == "equal" then
				match = num_val == num_compare
			elseif operator == "gt" then
				match = num_val > num_compare
			elseif operator == "lt" then
				match = num_val < num_compare
			elseif operator == "gte" then
				match = num_val >= num_compare
			elseif operator == "lte" then
				match = num_val <= num_compare
			end
		-- date comparisons
		elseif utils.parse_date(field_value) and utils.parse_date(value) then
			local date_val = utils.parse_date(field_value)
			local date_compare = utils.parse_date(value)

			if operator == "equal" then
				match = date_val == date_compare
			elseif operator == "gt" then
				match = date_val > date_compare
			elseif operator == "lt" then
				match = date_val < date_compare
			elseif operator == "gte" then
				match = date_val >= date_compare
			elseif operator == "lte" then
				match = date_val <= date_compare
			end
		-- string comparisons
		else
			if operator == "equal" then
				match = tostring(field_value) == tostring(value)
			elseif operator == "contains" then
				match = tostring(field_value):lower():find(tostring(value):lower(), 1, true) ~= nil
			end
		end

		if match then
			table.insert(filtered, todo)
		end
	end

	return headers, filtered
end

---@param headers string[]
---@param todos Todo[]
---@param header_name HeaderName
---@param opts? { desc?: boolean }
---@return string[] headers
---@return Todo[] sorted_todos
function M.sort(headers, todos, header_name, opts)
	opts = opts or {}
	local desc = opts.desc or false
	local property = header_name:lower()

	local sorted_todos = vim.list_extend({}, todos)

	local positions = {}
	for i = 1, #todos do
		positions[todos[i]] = i
	end

	table.sort(sorted_todos, function(a, b)
		local val_a = a[property]
		local val_b = b[property]

		local a_is_empty = val_a == nil or val_a == ""
		local b_is_empty = val_b == nil or val_b == ""

		-- empty after not empty, otherwise stay the same
		if a_is_empty and b_is_empty then
			return positions[a] < positions[b]
		elseif a_is_empty then
			return false
		elseif b_is_empty then
			return true
		end

		-- numeric comparison
		if utils.is_number(val_a) and utils.is_number(val_b) then
			val_a = tonumber(val_a)
			val_b = tonumber(val_b)
			if desc then
				return val_a > val_b
			else
				return val_a < val_b
			end
		end

		-- date comparison
		local date_a = utils.parse_date(val_a)
		local date_b = utils.parse_date(val_b)
		if date_a and date_b then
			if desc then
				return date_a > date_b
			else
				return date_a < date_b
			end
		end

		-- string comparison (fallback)
		val_a = tostring(val_a):lower()
		val_b = tostring(val_b):lower()
		if desc then
			return val_a > val_b
		else
			return val_a < val_b
		end
	end)

	return headers, sorted_todos
end

---@param todos Todo[]
---@param header_name "n"|"complete"|"task"|"tags"|"created"|"due"|"completed"|"notes"|"modified"
function M.update_under_cursor(todos, header_name)
	local jibun_dir = config.current.root_dir .. "/.jibun/"
	local jibun_csv_path = jibun_dir .. "jibun.csv"
	local line_num = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]

	-- check if in table row
	if not line or not line:match("^|") then
		vim.notify("not on a todo item row", vim.log.levels.WARN)
		return
	end

	local fields = {}
	for field in line:gmatch("|([^|]+)") do
		table.insert(fields, vim.trim(field))
	end

	-- n
	local todo_n = fields[1]
	if not todo_n or not tonumber(todo_n) then
		vim.notify("couldn't find todo number in this row", vim.log.levels.WARN)
		return
	end

	local todo_to_update = nil
	for _, todo in ipairs(todos) do
		if todo.n == todo_n then
			todo_to_update = todo
			break
		end
	end

	if not todo_to_update then
		vim.notify("couldn't find todo with number " .. todo_n, vim.log.levels.WARN)
		return
	end

	local lower_header = header_name:lower()

	if lower_header == "complete" then
		if todo_to_update.complete == "FALSE" then
			todo_to_update.complete = "TRUE"
			todo_to_update.completed = os.date("%m/%d/%Y")
		else
			todo_to_update.complete = "FALSE"
			todo_to_update.completed = ""
		end
		todo_to_update.modified = os.date("%m/%d/%Y")
	elseif lower_header == "due" then
		local date_str = vim.fn.input("due date (m/d/Y): ", todo_to_update.due or "")
		if date_str == "" then
			todo_to_update.due = ""
		else
			if not utils.parse_date(date_str) then
				vim.notify("invalid date format. please use m/d/Y", vim.log.levels.ERROR)
				return
			end
			todo_to_update.due = date_str
		end
		todo_to_update.modified = os.date("%m/%d/%Y")
	elseif lower_header == "notes" then
		local notes_input = vim.fn.input("enter notes or md file name: ")
		if notes_input ~= "" then
			if notes_input:match("%.md$") then
				local dir_path = jibun_dir .. "notes/"
				local notes_path = dir_path .. notes_input
				vim.fn.mkdir(vim.fn.fnamemodify(notes_path, ":h"), "p")
				if markdown.make_new_notes_md(notes_path, todo_to_update) then
					-- input of work/timecard.md will make a link like [timecard.md](notes/work/timecard.md)
					local display_name = notes_input:match("([^/]+)$") or notes_input
					todo_to_update.notes = string.format("[%s](notes/%s)", display_name, notes_input)
				end
			else
				todo_to_update.notes = notes_input
			end
		end
		todo_to_update.modified = os.date("%m/%d/%Y")
	elseif lower_header == "task" then
		local current_task = todo_to_update.task or ""
		local new_task = vim.fn.input("enter task: ", current_task)
		if new_task ~= "" then
			todo_to_update.task = new_task
			todo_to_update.modified = os.date("%m/%d/%Y")
		end
	elseif lower_header == "tags" then
		local current_tags = todo_to_update.tags or ""
		local new_tags = vim.fn.input("enter tag(s): ", current_tags)
		todo_to_update.tags = new_tags
		todo_to_update.modified = os.date("%m/%d/%Y")
	else
		-- default case for other fields
		-- shouldn't get here
		local current_value = todo_to_update[lower_header] or ""
		local new_value = vim.fn.input(string.format("enter new %s: ", header_name), current_value)
		if new_value ~= "" then
			todo_to_update[lower_header] = new_value
			todo_to_update.modified = os.date("%m/%d/%Y")
		end
	end

	-- update the csv file
	local file = io.open(jibun_csv_path, "w")
	if not file then
		vim.notify("couldn't open todo.csv for writing", vim.log.levels.ERROR)
		return
	end

	file:write(jibun_csv_headers)
	for _, todo in ipairs(todos) do
		file:write(
			string.format(
				"%s,%s,%s,%s,%s,%s,%s,%s,%s\n",
				todo.n or "",
				todo.complete or "",
				todo.task or "",
				todo.tags or "",
				todo.created or "",
				todo.due or "",
				todo.completed or "",
				todo.notes or "",
				todo.modified or ""
			)
		)
	end

	file:close()

	M.refresh_jibun()
end

---@param todos Todo[]
function M.add(todos)
	local jibun_dir = config.current.root_dir .. "/.jibun/"
	local jibun_csv_path = jibun_dir .. "jibun.csv"
	local max_n = 0
	for _, todo in ipairs(todos) do
		local current_n = tonumber(todo.n) or 0
		if current_n > max_n then
			max_n = current_n
		end
	end

	-- defaults
	local new_todo = {
		n = tostring(max_n + 1),
		complete = "FALSE",
		task = "",
		tags = "",
		created = os.date("%m/%d/%Y"),
		due = "",
		completed = "",
		notes = "",
		modified = os.date("%m/%d/%Y"),
	}

	new_todo.task = vim.fn.input("enter task: ")
	if new_todo.task == "" then
		vim.notify("cancelled...", vim.log.levels.INFO)
		return
	end

	new_todo.tags = vim.fn.input("enter tags: ")

	local due_input = vim.fn.input("enter due date (m/d/Y): ")
	if due_input ~= "" then
		if utils.parse_date(due_input) then
			new_todo.due = due_input
		else
			vim.notify("invalid date format, using blank due date", vim.log.levels.WARN)
		end
	end

	local notes_input = vim.fn.input("enter notes or md file name: ")
	if notes_input ~= "" then
		if notes_input:match("%.md$") then
			local dir_path = jibun_dir .. "notes/"
			local notes_path = dir_path .. notes_input

			vim.fn.mkdir(vim.fn.fnamemodify(notes_path, ":h"), "p")

			if markdown.make_new_notes_md(notes_path, new_todo) then
				local display_name = vim.fn.fnamemodify(notes_input, ":t")
				new_todo.notes = string.format("[%s](notes/%s)", display_name, notes_input)
			end
		else
			new_todo.notes = notes_input
		end
	end

	table.insert(todos, new_todo)

	-- update csv
	local file = io.open(jibun_csv_path, "w")
	if not file then
		vim.notify("couldn't open jibun.csv for writing", vim.log.levels.ERROR)
		return
	end

	file:write(jibun_csv_headers)
	for _, todo in ipairs(todos) do
		file:write(
			string.format(
				"%s,%s,%s,%s,%s,%s,%s,%s,%s\n",
				todo.n,
				todo.complete,
				todo.task,
				todo.tags or "",
				todo.created,
				todo.due or "",
				todo.completed or "",
				todo.notes or "",
				todo.modified or ""
			)
		)
	end

	file:close()

	M.refresh_jibun()

	vim.notify("added new todo #" .. new_todo.n, vim.log.levels.INFO)
end

function M.refresh_jibun()
	local jibun_dir = config.current.root_dir .. "/.jibun/"
	local jibun_md_path = jibun_dir .. "jibun.md"
	vim.notify("refreshing 自分...", vim.log.levels.INFO)
	local headers, todos = M.read_jibun_csv()
	assert(headers)

	-- queries
	----all
	local all_path = jibun_dir .. "query/all.md"
	markdown.make_new_query_md(headers, todos, all_path, "all todos")
	local all_link = "[all.md](query/all.md)\n"
	----recently completed
	local rec_path = jibun_dir .. "query/recently_completed.md"
	local rec_headers, rec_todos = M.sort(headers, todos, "completed", { desc = true })
	rec_headers, rec_todos = M.filter(rec_headers, rec_todos, "completed", "gte", "1/1/1000")
	markdown.make_new_query_md(rec_headers, rec_todos, rec_path, "recently completed")
	local rec_link = "[recently_completed.md](query/recently_completed.md)\n"

	-- jibun
	local file = assert(io.open(jibun_md_path, "w"))

	---- in progress
	local ip_headers, ip_todos = M.filter(headers, todos, "complete", "equal", "FALSE")
	ip_headers, ip_todos = M.sort(ip_headers, ip_todos, "n", { desc = true })
	ip_headers, ip_todos = M.sort(ip_headers, ip_todos, "due")
	ip_headers, ip_todos = M.select(ip_headers, ip_todos, { "n", "complete", "task", "tags", "due", "notes" })
	local lines = markdown.create_markdown_table(ip_headers, ip_todos)
	local in_prog = "## in progress\n" .. table.concat(lines, "\n")

	-- write to jibun.md
	file:write(
		"# 自分\n\n"
			.. in_prog
			.. "\n\n"
			.. "## queries\n"
			.. "- all todos: "
			.. all_link
			.. "- recently completed: "
			.. rec_link
	)
	file:close()
	vim.cmd(":e")
end

return M
