--[[
	Stack-based Finite State Machine.
	Push and pop states to the FSM.
	
	States should push other states onto the stack 
	and pop themselves off.
]]
---@class FSM
FSM = {}

---@type table<FSMState>
FSM.stateStack = {}

---@type function<FSM, tes3reference>
FSM.FSMState = {}

---@param ref tes3reference
function FSM.Update(ref)
    if (FSM.stateStack[1] ~= nil) then
        FSM.stateStack[1].Update(ref)
    end
end

---@param state FSMState
function FSM.pushState(state)
    table.insert(FSM.stateStack, 1, state)
end

function FSM.popState()
    table.remove(FSM.stateStack, 1);
end
