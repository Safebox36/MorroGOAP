---@class GoapAction
local GoapAction = {
	---@type table<string,function>
	preconditions = {},
	---@type table<string,function>
	effects = {},

	---@type boolean
	inRange = false,

	--[[
	The cost of performing the action. 
	Figure out a weight that suits the action. 
	Changing it will affect what actions are chosen during planning.
]]
	---@type number
	cost = 1,

	--[[
	An action often has to perform on an object. This is that object. Can be null.
]]
	---@type tes3reference
	target = nil
}
GoapAction.__index = GoapAction

function GoapAction.new()
	return setmetatable({}, GoapAction)
end

function GoapAction:doReset()
	self.inRange = false
	self.target = nil
	self.reset()
end

--[[
	Reset any variables that need to be reset before planning happens again.
]]
--[ABSTRACT METHOD]
function GoapAction.reset()

end

--[[
	Is the action done?
]]
--[ABSTRACT METHOD]
---@return boolean
function GoapAction.isDone()
	return false
end

--[[
	Procedurally check if this action can run. Not all actions
	will need this, but some might.
]]
--[ABSTRACT METHOD]
---@param agent tes3reference
---@return boolean
function GoapAction.checkProceduralPrecondition(agent)
	return false
end

--[[
	Run the action.
	Returns True if the action performed successfully or false
	if something happened and it can no longer perform. In this case
	the action queue should clear out and the goal cannot be reached.
]]
--[ABSTRACT METHOD]
---@param agent tes3reference
---@return boolean
function GoapAction.perform(agent)
	return false
end

--[[
	Does this action need to be within range of a target game object?
	If not then the moveTo state will not need to run for this action.
]]
--[ABSTRACT METHOD]
---@return boolean
function GoapAction.requiresInRange()
	return false
end

--[[
	Are we in range of the target?
	The MoveTo state will set this and it gets reset each time this action is performed.
]]
---@return boolean
function GoapAction:isInRange()
	return self.inRange
end

---@param inRange boolean
function GoapAction:setInRange(inRange)
	self.inRange = inRange
end

---@param key string
---@param value function
function GoapAction:addPrecondition(key, value)
	self.preconditions[key] = value
end

---@param key string
function GoapAction:removePrecondition(key)
	self.preconditions[key] = nil
end

---@param key string
---@param value function
function GoapAction:addEffect(key, value)
	self.effects[key] = value
end

---@param key string
function GoapAction:removeEffect(key)
	self.effects[key] = nil
end

---@return table<string, function>
function GoapAction:getPreconditions()
	return self.preconditions
end

---@return table<string, function>
function GoapAction:getEffects()
	return self.effects
end

return GoapAction
