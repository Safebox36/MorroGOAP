local sb_goap = require("sb_goap.sb_goap")

local fleeWhenAttacked = sb_goap.GoapAction.new()

function fleeWhenAttacked:init()
	self:addPrecondition("beenAttacked", true)
	self:addPrecondition("enemyWeaponed", false)
	self:addEffect("runAway", true)
end

function fleeWhenAttacked:reset()
	self.beenAttacked = false
end

function fleeWhenAttacked:isDone()
	return self.beenAttacked
end

function fleeWhenAttacked.requiresInRange()
	return true
end

---@param agent tes3reference
function fleeWhenAttacked.checkProceduralPrecondition(agent)
	return agent.mobile.attacked and agent.mobile.actionData.target.weaponDrawn
end

---@param agent tes3reference
function fleeWhenAttacked.perform(agent)
	agent.mobile:stopCombat(true)
	agent.object.aiConfig.flee = 100
	agent.object.aiConfig.fight = 0
	return true
end

return fleeWhenAttacked
