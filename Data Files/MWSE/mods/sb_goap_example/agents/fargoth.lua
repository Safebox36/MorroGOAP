local sb_goap = require("sb_goap.sb_goap")

local fargoth = sb_goap.IGoap.new()

function fargoth.init()
    fargoth.ref = tes3.getReference("fargoth")
end

function fargoth:getWorldState ()
    ---@type table<string, any>
    local worldData = {
        {"beenAttacked", true},
        {"enemyWeaponed", false},
        {"runAway", false}
    }
    
    return worldData
end

function fargoth:createGoalState()
    return {{"runAway", true}}
end

function fargoth.planFailed(failedGoal)
end

function fargoth.planFound(actions)
    mwse.log("Plan found: " + json.encode(actions))
end

function fargoth.actionsFinished()
    mwse.log("Actions completed")
end

function fargoth.planAborted(aborter)
    mwse.log("Plan Aborted: " + json.encode(aborter))
end

function fargoth.moveAgent(nextAction)
end

return fargoth
