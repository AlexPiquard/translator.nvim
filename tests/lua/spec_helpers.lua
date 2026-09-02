local stub = require("luassert.stub")

local M = {}

local active_stubs = {}

---@param target table
---@param key string
---@param replacement? function
function M.stash_stub(target, key, replacement)
    local s = stub(target, key, replacement)
    active_stubs[#active_stubs + 1] = s
    return s
end

function M.revert_stubs()
    for _, s in ipairs(active_stubs) do
        s:revert()
    end
    active_stubs = {}
end

return M
