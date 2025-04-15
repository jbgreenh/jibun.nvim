local M = {}

---@type Config
M.default = {
	root_dir = vim.fn.stdpath("data") .. "/jibun",
	warn_days = 7,
}

---@type Config
M.current = vim.deepcopy(M.default)

---@param opts? ConfigOptional
function M.setup(opts)
	M.current = vim.tbl_deep_extend("force", M.default, opts or {})
	M.current.root_dir = M.current.root_dir:gsub("^~", os.getenv("HOME")):gsub("/+$", "")
	require("jibun.autocmds").setup()
end

return M
