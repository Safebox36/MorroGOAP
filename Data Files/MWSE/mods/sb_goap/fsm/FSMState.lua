local mc = require("sb_goap.utils.middleclass")

---@class FSMState
local FSMState = mc.class("FSMState")

--[ABSTRACT METHOD]
---@param fsm FSM
---@param ref tes3reference
function FSMState:Update(fsm, ref)
    mwse.log("FSMState:Update(fsm, ref) is ABSTRACT")
end

return FSMState
