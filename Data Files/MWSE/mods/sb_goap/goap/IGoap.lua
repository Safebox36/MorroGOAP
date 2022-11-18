---@class IGoap
IGoap = {}

--[[
	The starting state of the Agent and the world.
	Supply what states are needed for actions to run.
]]
---@type table<string,any>
IGoap.getWorldState = nil

--[[
	Give the planner a new goal so it can figure out 
	the actions needed to fulfill it.
]]
---@type table<string,any>
IGoap.createGoalState = nil

--[[
	No sequence of actions could be found for the supplied goal.
	You will need to try another goal
]]
---@param failedGoal table<string,any>
function IGoap.planFailed (failedGoal)

end

--[[
	A plan was found for the supplied goal.
	These are the actions the Agent will perform, in order.
]]
---@param goal table<string,any>
---@param actions table<GoapAction>
function IGoap.planFound (goal, actions)

end

--[[
	All actions are complete and the goal was reached. Hooray!
]]
--[ABSTRACT METHOD]
function IGoap.actionsFinished()

end

--[[
	One of the actions caused the plan to abort.
]]
--[[
	That action is returned.
]]
--[ABSTRACT METHOD]
---@param aborter GoapAction
function IGoap.planAborted(aborter)

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
function IGoap.moveAgent(nextAction)
	return false
end

function IGoap:new()
    local new_class = {}
    local class_mt = { __index = new_class }

    function new_class:create()
        local newinst = {}
        setmetatable( newinst, class_mt )
        return newinst
    end

    if self then
        setmetatable( new_class, { __index = self } )
    end

    return new_class
end

