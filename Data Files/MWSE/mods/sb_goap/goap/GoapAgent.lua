local mc = require("sb_goap.utils.middleclass")
local FSM = require("sb_goap.fsm.FSM")
local Queue = require("sb_goap.utils.Queue")
local GoapPlanner = require("sb_goap.goap.GoapPlanner")
local IGoap = require("sb_goap.goap.IGoap")

---@class GoapAgent
local GoapAgent = mc.class("GoapAgent")

---@param ref tes3reference
function GoapAgent:initialize(ref)
    ---@type FSM
    self.stateMachine = nil

    ---@type FSMState
    self.idleState = nil -- finds something to do
    ---@type FSMState
    self.moveToState = nil -- moves to a target
    ---@type FSMState
    self.performActionState = nil -- performs an action

    ---@type table<GoapAction>
    self.availableActions = nil
    ---@type Queue<GoapAgent>
    self.currentActions = nil

    ---@type IGoap
    self.dataProvider = nil -- this is the implementing class that provides our world data and listens to feedback on planning

    ---@type GoapPlanner
    self.planner = nil

    ---@type tes3reference
    self.ref = ref
end

function GoapAgent:Start()
    self.stateMachine = FSM:new()
    self.availableActions = {}
    self.currentActions = Queue:new()
    self.planner = GoapPlanner:new()
    self:findDataProvider()
    self:createIdleState()
    self:createMoveToState()
    self:createPerformActionState()
    self.stateMachine:pushState(self.idleState)
    self:loadActions()
end

function GoapAgent:Update()
    self.stateMachine:Update(self.ref)
end

---comment
---@param a GoapAction
function GoapAgent:addAction(a)
    table.insert(self.availableActions, a)
end

---@param action GoapAction
---@return GoapAction
function GoapAgent:getAction(action)
    for _, g in ipairs(self.availableActions) do
        if (g:isInstanceOf(action)) then
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
    return table.size(self.currentActions) > 0
end

function GoapAgent:createIdleState()
    self.idleState = function(fsm, ref)
        -- GOAP planning

        -- get the world state and the goal we want to plan for
        ---@type table<number<string, any>>
        local worldState = self.dataProvider:getWorldState()
        ---@type table<number<string, any>>
        local goal = self.dataProvider:createGoalState()

        -- Plan
        ---@type Queue<GoapAction>
        local plan = self.planner:plan(self.ref, self.availableActions, worldState, goal)
        if (plan ~= nil) then
            -- we have a plan, hooray!
            self.currentActions = plan
            self.dataProvider:planFound(goal, plan)

            fsm:popState() -- move to PerformAction state
            fsm:pushState(performActionState)

        else
            -- ugh, we couldn't get a plan
            mwse.log("Failed Plan:%s" + json.encode(goal))
            dataProvider.planFailed(goal)
            fsm:popState() -- move back to IdleAction state
            fsm:pushState(self.idleState)
        end
    end
end

function GoapAgent:createMoveToState()
    self.moveToState = function(fsm, ref)
        -- move the game object

        ---@type GoapAction
        local action = self.currentActions:peek()
        if (action:requiresInRange() and action.target == nil) then
            mwse.log("Fatal error: Action requires a target but has none. Planning failed. You did not assign the target in your Action:checkProceduralPrecondition()")
            fsm:popState() -- move
            fsm:popState() -- perform
            fsm:pushState(idleState)
            return
        end

        -- get the ref to move itself
        if (dataProvider.moveAgent(action)) then
            fsm:popState()
        end
    end
end

function GoapAgent:createPerformActionState()
    self.performActionState = function(fsm, ref)
        -- perform the action

        if (not self:hasActionPlan()) then
            -- no actions to perform
            mwse.log("Done actions")
            fsm:popState()
            fsm:pushState(idleState)
            dataProvider.actionsFinished()
            return
        end

        ---@type GoapAction
        local action = self.currentActions:peek()
        if (action:isDone()) then
            -- the action is done. Remove it so we can perform the next one
            self.currentActions:pop()
        end

        if (self:hasActionPlan()) then
            -- perform the next action
            action = self.currentActions:peek()
            local inRange = action:requiresInRange() and action:isInRange() or true

            if (inRange) then
                -- we are in range, so perform the action
                local success = action:perform(ref)

                if (not success) then
                    -- action failed, we need to plan again
                    fsm:popState()
                    fsm:pushState(idleState)
                    dataProvider:planAborted(action)
                end
            else
                -- we need to move there first
                -- push moveTo state
                fsm:pushState(moveToState)
            end

        else
            -- no actions left, move to Plan state
            fsm:popState()
            fsm:pushState(idleState)
            dataProvider:actionsFinished()
        end
    end
end

function GoapAgent:findDataProvider()
    for _, data in ipairs(self.ref.data) do
        if (data:isInstanceOf(IGoap)) then
            self.dataProvider = data
            return
        end
    end
end

function GoapAgent:loadActions()
    for _, data in ipairs(self.ref.data) do
        if (data:isInstanceOf(GoapAction)) then
            table.insert(self.availableActions, data)
        end
    end
    mwse.log("Found actions: %s", json.encode(self.availableActions))
end

return GoapAgent
