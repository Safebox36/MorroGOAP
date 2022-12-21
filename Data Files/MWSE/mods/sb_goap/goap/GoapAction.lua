local mc = require("sb_goap.utils.middleclass")

---@class GoapAction
local GoapAction = mc.class("GoapAction")

function GoapAction:initialize()
	---@type table<number,table<string, any>>
	self.preconditions = nil
	---@type table<number,table<string, any>>
	self.effects = nil

	---@type boolean
	self.inRange = false

	--[[
	The cost of performing the action. 
	Figure out a weight that suits the action. 
	Changing it will affect what actions are chosen during planning.
	]]
	---@type number
	self.cost = 1

	--[[
	An action often has to perform on an object. This is that object. Can be null.
	]]
	---@type tes3reference
	self.target = nil
end

function GoapAction:doReset()
	self.inRange = false
	self.target = nil
	self:reset()
end

--[[
Reset any variables that need to be reset before planning happens again.
]]
--[ABSTRACT METHOD]
function GoapAction:reset()
	mwse.log("GoapAction:reset() is ABSTRACT")
end

--[[
Is the action done?
]]
--[ABSTRACT METHOD]
---@return boolean
function GoapAction:isDone()
	mwse.log("GoapAction:isDone() is ABSTRACT")
	return false
end

--[[
Procedurally check if this action can run. Not all actions
will need this, but some might.
]]
--[ABSTRACT METHOD]
---@param ref tes3reference
---@return boolean
function GoapAction:checkProceduralPrecondition(ref)
	mwse.log("GoapAction:checkProceduralPrecondition(ref) is ABSTRACT")
	return false
end

--[[
Run the action.
Returns True if the action performed successfully or false
if something happened and it can no longer perform. In this case
the action queue should clear out and the goal cannot be reached.
]]
--[ABSTRACT METHOD]
---@param ref tes3reference
---@return boolean
function GoapAction:perform(ref)
	mwse.log("GoapAction:perform(ref) is ABSTRACT")
	return false
end

--[[
Does this action need to be within range of a target game object?
If not then the moveTo state will not need to run for this action.
]]
--[ABSTRACT METHOD]
---@return boolean
function GoapAction:requiresInRange()
	mwse.log("GoapAction:requiresInRange() is ABSTRACT")
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
---@param value any
function GoapAction:addPrecondition(key, value)
	table.insert(self.preconditions, { key, value })
end

---@param key string
function GoapAction:removePrecondition(key)
	for k, v in ipairs(self.preconditions) do
		if (v[1] == key) then
			self.preconditions[k] = nil
		end
	end
end

---@param key string
---@param value any
function GoapAction:addEffect(key, value)
	table.insert(self.effects, { key, value })
end

---@param key string
function GoapAction:removeEffect(key)
	for k, v in ipairs(self.effects) do
		if (v[1] == key) then
			self.effects[k] = nil
		end
	end
end

---@return table<number,table<string,any>>
function GoapAction:getPreconditions()
	return self.preconditions
end

---@return table<number,table<string,any>>
function GoapAction:getEffects()
	return self.effects
end

return GoapAction
