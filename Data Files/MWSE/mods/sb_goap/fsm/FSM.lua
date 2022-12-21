local mc = require("sb_goap.utils.middleclass")
local Stack = require("sb_goap.utils.Stack")

--[[
	Stack-based Finite State Machine.
	Push and pop states to the FSM.
	
	States should push other states onto the stack 
	and pop themselves off.
]]
---@class FSM
local FSM = mc.class("FSM")

function FSM:initialize()
    ---@type Stack FSMState
    self.stateStack = Stack:new()
end

---@param ref tes3reference
function FSM:Update(ref)
    if (self.stateStack:peek() ~= nil) then
        self.stateStack:peek()(self, ref)
    end
end

---@param state FSMState
function FSM:pushState(state)
    self.stateStack:push(state)
end

function FSM:popState()
    self.stateStack:pop()
end

return FSM
