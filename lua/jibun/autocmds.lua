local M = {}

function M.setup()
	local jibun = vim.api.nvim_create_augroup("jibun", { clear = true })

	-- highlight and refresh on relevant files
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
		group = jibun,
		pattern = { "*/.jibun/jibun.md", "*/.jibun/query/*.md" },
		callback = function()
			require("jibun.todos").refresh_jibun()
			require("jibun.markdown").highlight_table_rows()

			local disable_keys = { "i", "a", "o", "c", "I", "A", "O", "C", "d", "D" }
			for _, key in ipairs(disable_keys) do
				vim.keymap.set({ "n", "v" }, key, "<Nop>", { buffer = true })
			end
		end,
	})

	vim.api.nvim_create_autocmd("BufEnter", {
		group = jibun,
		pattern = "*.md",
		callback = function()
			vim.diagnostic.enable(false, { bufnr = 0 })

			local utils = require("jibun.utils")
			local has_rm, rm = pcall(require, "render-markdown")
			if has_rm then
				rm.setup({
					anti_conceal = {
						enabled = not utils.in_jibun_file() and not utils.in_query_file(),
					},
				})
			end
		end,
	})
end

return M
