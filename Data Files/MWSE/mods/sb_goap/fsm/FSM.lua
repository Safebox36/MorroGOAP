--[[
	Stack-based Finite State Machine.
	Push and pop states to the FSM.
	
	States should push other states onto the stack 
	and pop themselves off.
]]
---@class FSM
local FSM = {
    ---@type table<FSMState>
    stateStack = {},
    ---@type function<FSM, tes3reference>
    FSMState = {}
}
FSM.__index = FSM

function FSM.new()
    return setmetatable({}, FSM)
end

---@param ref tes3reference
function FSM:Update(ref)
    if (self.stateStack[1] ~= nil) then
        self.stateStack[1].Update(ref)
    end
end

---@param state FSMState
function FSM:pushState(state)
    table.insert(self.stateStack, 1, state)
end

function FSM:popState()
    table.remove(self.stateStack, 1);
end

return FSM
