---@class sb_goap
---@field FSM FSM
---@field FSMState FSMState
---@field GoapAction GoapAction
---@field GoapAgent GoapAgent
---@field GoapPlanner GoapPlanner
---@field IGoap IGoap
return {
    FSM = require("sb_goap.fsm.FSM"),
    FSMState = require("sb_goap.fsm.FSMState"),
    
    GoapAction = require("sb_goap.goap.GoapAction"),
    GoapAgent = require("sb_goap.goap.GoapAgent"),
    GoapPlanner = require("sb_goap.goap.GoapPlanner"),
    IGoap = require("sb_goap.goap.IGoap"),
}