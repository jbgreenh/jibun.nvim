---@module jibun
local M = {}

local config = require("jibun.config")
local api = require("jibun.api")

---@param user_opts? ConfigOptional
---@return JibunAPI
function M.setup(user_opts)
	config.setup(user_opts)
	return api
end

setmetatable(M, {
	---@param _ table
	---@param k string
	---@return function
	__index = function(_, k)
		return require("jibun.api")[k] or function() end
	end,
})

return M
