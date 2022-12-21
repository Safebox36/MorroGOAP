local mc = require("sb_goap.utils.middleclass")

---@class IGoap
local IGoap = mc.class("IGoap")

--[[
The starting state of the Agent and the world.
Supply what states are needed for actions to run.
]]
--[ABSTRACT METHOD]
---@return table<string,any>
function IGoap:getWorldState()
	mwse.log("IGoap:getWorldState() is ABSTRACT")
	return {}
end

--[[
Give the planner a new goal so it can figure out 
the actions needed to fulfill it.
]]
---@return table<string,any>
function IGoap:createGoalState()
	mwse.log("IGoap:createGoalState() is ABSTRACT")
	return {}
end

--[[
No sequence of actions could be found for the supplied goal.
You will need to try another goal
]]
--[ABSTRACT METHOD]
---@param failedGoal table<string,any>
function IGoap:planFailed(failedGoal)
	mwse.log("IGoap:planFailed(failedGoal) is ABSTRACT")
end

--[[
A plan was found for the supplied goal.
These are the actions the Agent will perform, in order.
]]
--[ABSTRACT METHOD]
---@param goal table<string,any>
---@param actions table<GoapAction>
function IGoap:planFound(goal, actions)
	mwse.log("IGoap:planFound(goal, actions) is ABSTRACT")
end

--[[
All actions are complete and the goal was reached. Hooray!
]]
--[ABSTRACT METHOD]
function IGoap:actionsFinished()
	mwse.log("IGoap:actionsFinished() is ABSTRACT")
end

--[[
One of the actions caused the plan to abort.
]]
--[[
That action is returned.
]]
--[ABSTRACT METHOD]
---@param aborter GoapAction
function IGoap:planAborted(aborter)
	mwse.log("IGoap:planAborted(aborter) is ABSTRACT")
end

--[[
Called during Update. Move the agent towards the target in order
for the next action to be able to perform.
]]
--[[
Return true if the Agent is at the target and the next action can perform.
False if it is not there yet.
]]
--[ABSTRACT METHOD]
---@param nextAction GoapAction
---@return boolean
function IGoap:moveAgent(nextAction)
	mwse.log("IGoap:moveAgent(nextAction) is ABSTRACT")
	return false
end

return IGoap
