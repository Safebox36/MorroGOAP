GoapAgent = {}

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
function GoapAgent.loadedCallback(refData)
    GoapAgent.stateMachine = {}
    GoapAgent.availableActions = {}
    GoapAgent.currentActions = {}
    GoapAgent.planner = {}
    GoapAgent.findDataProvider(refData[1])
    GoapAgent.createIdleState()
    GoapAgent.createMoveToState()
    GoapAgent.createPerformActionState()
    table.insert(GoapAgent.stateMachine, GoapAgent.idleState)
    GoapAgent.loadActions(refData[2])
end

---@param ref tes3reference
function GoapAgent.simulateCallback(ref)
    GoapAgent.stateMachine.Update(ref)
end

---@param a GoapAction
function GoapAgent.addAction(a)
    table.insert(GoapAgent.availableActions, a)
end

---@param action GoapAction
---@return GoapAction | nil
function GoapAgent.getAction(action)
    for _, g in ipairs(GoapAgent.availableActions) do
        if (g == action) then
            return g
        end
    end
    return nil
end

---@param action GoapAction
function GoapAgent.removeAction(action)
    table.removevalue(GoapAgent.GoapAgent.availableActions, action)
end

---@return boolean
function GoapAgent.hasActionPlan()
    return #GoapAgent.currentActions > 0
end

function GoapAgent.createIdleState()
    --GOAP planning

    --get the world state and the goal we want to plan for
    ---@type table<string, function>
    local worldState = GoapAgent.dataProvider.getWorldState()
    ---@type table<string, function>
    local goal = GoapAgent.dataProvider.createGoalState()

    --Plan
    ---@type table<GoapAction>
    local plan = assert(GoapAgent.planner.plan(GoapAgent.idleState.ref, GoapAgent.availableActions, worldState, goal))
    if (plan ~= nil) then
        --we have a plan, hooray!
        GoapAgent.currentActions = plan
        GoapAgent.dataProvider.planFound(goal, plan)

        table.remove(GoapAgent.idleState.fsm, 1) --move to PerformAction state
        table.insert(GoapAgent.idleState.fsm, GoapAgent.performActionState)

    else
        --ugh, we couldn't get a plan
        mwse.log("Failed Plan: " .. json.encode(goal))
        GoapAgent.dataProvider.planFailed(goal)
        table.remove(GoapAgent.idleState.fsm, 1) --move back to IdleAction state
        table.insert(GoapAgent.idleState.fsm, GoapAgent.idleState)
    end
end

function GoapAgent.createMoveToState()
    --move the game object

    ---@type GoapAction
    local action = GoapAgent.currentActions[1]
    if (action.requiresInRange() and action.target == nil) then
        mwse.log("Fatal error: Action requires a target but has none. Planning failed. You did not assign the target in your Action.checkProceduralPrecondition()")
        table.remove(GoapAgent.moveToState.fsm, 1) --move
        table.remove(GoapAgent.moveToState.fsm, 1) --perform
        table.insert(GoapAgent.moveToState.fsm, GoapAgent.idleState)
        return
    end

    --get the agent to move itself
    if (GoapAgent.dataProvider.moveAgent(action)) then
        table.remove(GoapAgent.moveToState.fsm, 1)
    end
end

function GoapAgent.createPerformActionState()
    --perform the action

    if (~GoapAgent.hasActionPlan()) then
        --no actions to perform
        mwse.log("Done actions")
        table.remove(GoapAgent.performActionState.fsm, 1)
        table.insert(GoapAgent.performActionState.fsm, GoapAgent.idleState)
        GoapAgent.dataProvider.actionsFinished()
        return
    end

    ---@type GoapAction
    local action = GoapAgent.currentActions[1]
    if (action.isDone()) then
        --the action is done. Remove it so we can perform the next one
        table.remove(GoapAgent.currentActions, #GoapAgent.currentActions)
    end

    if (GoapAgent.hasActionPlan()) then
        --perform the next action
        action = GoapAgent.currentActions[1]
        ---@type boolean
        local inRange = action.requiresInRange() and action.isInRange() or true

        if (inRange) then
            --we are in range, so perform the action
            ---@type boolean
            local success = action.perform(GoapAgent.performActionState.ref)

            if (~success) then
                --action failed, we need to plan again
                table.remove(GoapAgent.performActionState, 1)
                table.insert(GoapAgent.performActionState, GoapAgent.idleState)
                GoapAgent.dataProvider.planAborted(action)
            end
        else
            --we need to move there first
            --push moveTo state
            table.insert(GoapAgent.performActionState, GoapAgent.moveToState)
        end

    else
        --no actions left, move to Plan state
        table.remove(GoapAgent.performActionState, 1)
        table.insert(GoapAgent.performActionState, GoapAgent.idleState)
        GoapAgent.dataProvider.actionsFinished()
    end
end

---@param comp IGoap
function GoapAgent.findDataProvider(comp)
    GoapAgent.dataProvider = comp
end

---@param actions GoapAction
function GoapAgent.loadActions(actions)
    for _, a in ipairs(actions) do
        table.insert(GoapAgent.availableActions, a)
    end
    mwse.log("Found actions: " .. json.encode(actions))
end
