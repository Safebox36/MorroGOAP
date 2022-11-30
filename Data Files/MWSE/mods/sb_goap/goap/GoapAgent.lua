local mc = require("sb_goap.utils.middleclass")
local FSM = require("sb_goap.fsm.FSM")
local GoapPlanner = require("sb_goap.goap.GoapPlanner")

---@class GoapAgent
local GoapAgent = mc.class("GoapAgent")

---@type FSM
GoapAgent.stateMachine = {}

---@type FSMState
GoapAgent.idleState = {} --finds something to do
---@type FSMState
GoapAgent.moveToState = {} --moves to a target
---@type FSMState
GoapAgent.performActionState = {} --performs an action

---@type table<GoapAction>
GoapAgent.availableActions = {}
---@type table<GoapAction>
GoapAgent.currentActions = {}

---@type IGoap
GoapAgent.dataProvider = {} --this is the implementing class that provides our world data and listens to feedback on planning

---@type GoapPlanner
GoapAgent.planner = {}

---@param refData table<IGoap, table<GoapAction>>
function GoapAgent:loadedCallback(refData)
    self.stateMachine = FSM:new()
    self.availableActions = {}
    self.currentActions = {}
    self.planner = GoapPlanner:new()
    self:findDataProvider(refData[1])
    self:createIdleState()
    self:createMoveToState()
    self:createPerformActionState()
    table.insert(self.stateMachine, self.idleState)
    self:loadActions(refData[2])
end

---@param ref tes3reference
function GoapAgent:simulateCallback(ref)
    self.stateMachine:Update(ref)
end

---@param a GoapAction
function GoapAgent:addAction(a)
    table.insert(self.availableActions, a)
end

---@param action GoapAction
---@return GoapAction | nil
function GoapAgent:getAction(action)
    ---@param g GoapAction
    for _, g in ipairs(self.availableActions) do
        if (g == action) then
            return g
        end
    end
    return nil
end

---@param action GoapAction
function GoapAgent:removeAction(action)
    table.removevalue(self.availableActions, action)
end

---@return boolean
function GoapAgent:hasActionPlan()
    return #self.currentActions > 0
end

function GoapAgent:createIdleState()
    --GOAP planning

    --get the world state and the goal we want to plan for
    ---@type table<string, any>
    local worldState = self.dataProvider.getWorldState()
    ---@type table<string, any>
    local goal = self.dataProvider.createGoalState()

    --Plan
    ---@type table<GoapAction>
    local plan = assert(self.planner:plan(self.idleState.ref, self.availableActions, worldState, goal),
        "self.planner:plan(self.idleState.ref, self.availableActions, worldState, goal)")
    if (plan ~= nil) then
        --we have a plan, hooray!
        self.currentActions = plan
        self.dataProvider.planFound(goal, plan)

        table.remove(self.idleState.fsm, 1) --move to PerformAction state
        table.insert(self.idleState.fsm, self.performActionState)

    else
        --ugh, we couldn't get a plan
        mwse.log("Failed Plan: " .. json.encode(goal))
        self.dataProvider.planFailed(goal)
        table.remove(self.idleState.fsm, 1) --move back to IdleAction state
        table.insert(self.idleState.fsm, self.idleState)
    end
end

function GoapAgent:createMoveToState()
    --move the game object

    ---@type GoapAction
    local action = self.currentActions[1]
    if (action.requiresInRange() and action.target == nil) then
        mwse.log("Fatal error: Action requires a target but has none. Planning failed. You did not assign the target in your Action.checkProceduralPrecondition()")
        table.remove(self.moveToState.fsm, 1) --move
        table.remove(self.moveToState.fsm, 1) --perform
        table.insert(self.moveToState.fsm, self.idleState)
        return
    end

    --get the agent to move itself
    if (self.dataProvider.moveAgent(action)) then
        table.remove(self.moveToState.fsm, 1)
    end
end

function GoapAgent:createPerformActionState()
    --perform the action

    if (self:hasActionPlan() == false) then
        --no actions to perform
        mwse.log("Done actions")
        table.remove(self.performActionState.fsm, 1)
        table.insert(self.performActionState.fsm, self.idleState)
        self.dataProvider.actionsFinished()
        return
    end

    ---@type GoapAction
    local action = self.currentActions[1]
    if (action.isDone()) then
        --the action is done. Remove it so we can perform the next one
        table.remove(self.currentActions, #self.currentActions)
    end

    if (self:hasActionPlan()) then
        --perform the next action
        action = self.currentActions[1]
        ---@type boolean
        local inRange = action.requiresInRange() and action.isInRange() or true

        if (inRange) then
            --we are in range, so perform the action
            ---@type boolean
            local success = action.perform(self.performActionState.ref)

            if (success == false) then
                --action failed, we need to plan again
                table.remove(self.performActionState, 1)
                table.insert(self.performActionState, self.idleState)
                self.dataProvider.planAborted(action)
            end
        else
            --we need to move there first
            --push moveTo state
            table.insert(self.performActionState, self.moveToState)
        end

    else
        --no actions left, move to Plan state
        table.remove(self.performActionState, 1)
        table.insert(self.performActionState, self.idleState)
        self.dataProvider.actionsFinished()
    end
end

---@param comp IGoap
function GoapAgent:findDataProvider(comp)
    self.dataProvider = comp
end

---@param actions GoapAction
function GoapAgent:loadActions(actions)
    for _, a in ipairs(actions) do
        table.insert(self.availableActions, a)
    end
    mwse.log("Found actions: " .. json.encode(actions))
end

return GoapAgent
