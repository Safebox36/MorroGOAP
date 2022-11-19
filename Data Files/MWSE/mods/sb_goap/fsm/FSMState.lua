---@class FSMState
local FSMState = {
    ---@type FSM
    fsm = {},
    ---@type tes3reference
    ref = {}
}
FSMState.__index = FSMState

function FSMState.new()
    return setmetatable({}, FSMState)
end

--[ABSTRACT METHOD]
---@param fsm FSM
---@param ref tes3reference
function FSMState.Update(fsm, ref)

end

return FSMState
