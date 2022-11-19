local sb_goap = require("sb_goap.sb_goap")
local fargoth = require("sb_goap_example.agents.fargoth")
local attackWhenAttacked = require("sb_goap_example.actions.attackWhenAttacked")
local fleeWhenAttacked = require("sb_goap_example.actions.fleeWhenAttacked")

local fargothAgent = sb_goap.GoapAgent.new()

--- @param e loadedEventData
local function loadedCallback(e)
    fargoth.init()

    attackWhenAttacked:init()
    fleeWhenAttacked:init()
    fargothAgent:loadedCallback(sb_goap, { fargoth, { attackWhenAttacked, fleeWhenAttacked } })
end

event.register(tes3.event.loaded, loadedCallback)

--- @param e simulateEventData
local function simulateCallback(e)
    fargothAgent:simulateCallback(fargoth.ref)
end

event.register(tes3.event.simulate, simulateCallback)
