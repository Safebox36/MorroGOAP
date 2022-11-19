local sb_goap = require("sb_goap.sb_goap")

local attackWhenAttacked = sb_goap.GoapAction.new()

function attackWhenAttacked:init()
    self:addPrecondition("beenAttacked", true)
    self:addPrecondition("enemyWeaponed", true)
    self:addEffect("runAway", false)
end

function attackWhenAttacked:reset()
    self.beenAttacked = false
end

function attackWhenAttacked:isDone()
    return self.beenAttacked
end

function attackWhenAttacked.requiresInRange()
    return true
end

---@param agent tes3reference
function attackWhenAttacked.checkProceduralPrecondition(agent)
    return agent.mobile.attacked and agent.mobile.actionData.target.weaponDrawn == false
end

---@param agent tes3reference
function attackWhenAttacked.perform(agent)
    agent.object.aiConfig.flee = 0
    agent.object.aiConfig.fight = 100
    return true
end

return attackWhenAttacked
