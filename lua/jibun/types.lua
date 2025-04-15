---@class Todo
---@field fields string[]
---@field n? string
---@field complete? string
---@field task? string
---@field tags? string
---@field created? string
---@field due? string
---@field completed? string
---@field notes? string
---@field modified? string

---@class Config
---@field root_dir string
---@field warn_days number

---@class ConfigOptional
---@field root_dir? string
---@field warn_days number

---@alias FilterOperator
---| 'equal'
---| 'gt'
---| 'lt'
---| 'gte'
---| 'lte'
---| 'contains'

---@alias HeaderName
---| 'n'
---| 'complete'
---| 'task'
---| 'tags'
---| 'created'
---| 'due'
---| 'completed'
---| 'notes'
---| 'modified'

---@class JibunAPI
---@field setup fun(opts?: ConfigOptional)
---@field update_under_cursor fun(header_name: HeaderName)
---@field follow_link fun()
---@field add_todo fun()
---@field open_jibun fun()
---@field refresh_jibun fun()

return {}
