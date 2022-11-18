--[[
Plans what actions can be completed in order to fulfill a goal state.
]]
---@class GoapPlanner
GoapPlanner = {}

--[[
	Used for building up the graph and holding the running costs of actions.
]]
---@class Node
---@field parent Node | nil
---@field runningCost number
---@field state table<string, function>
---@field action GoapAction | nil
local Node = {}

---@param parent Node | nil
---@param runningCost number
---@param state table<string, function>
---@param action GoapAction | nil
function Node:new(parent, runningCost, state, action)
	Node.parent = parent
	Node.runningCost = runningCost
	Node.state = state
	Node.action = action
end

--[[
	Plan what sequence of actions can fulfill the goal.
	Returns nil if a plan could not be found, or a list of the actions
	that must be performed, in order, to fulfill the goal.
]]
---@param agent tes3reference
---@param availableActions table<GoapAction>
---@param worldState table<string,function>
---@param goal table<string,function>
---@return table<GoapAction> | nil
function GoapPlanner.plan(agent, availableActions, worldState, goal)
	--reset the actions so we can start fresh with them
	for _, a in ipairs(availableActions) do
		a.doReset()
	end

	--check what actions can run using their checkProceduralPrecondition
	---@type table<GoapAction>
	local usableActions = {}
	for _, a in ipairs(availableActions) do
		if (a.checkProceduralPrecondition(agent)) then
			table.insert(usableActions, a)
		end
	end

	--we now have all actions that can run, stored in usableActions

	--build up the tree and record the leaf nodes that provide a solution to the goal.
	---@type table<Node>
	local leaves = {}

	--build graph
	---@type Node
	local start = assert(Node:new(nil, 0, worldState, nil))
	---@type boolean
	local success = GoapPlanner.buildGraph(start, leaves, usableActions, goal)

	if (~success) then
		--oh no, we didn't get a plan
		mwse.log("NO PLAN")
		return nil
	end

	--get the cheapest leaf
	---@type Node
	local cheapest = nil
	for _, leaf in ipairs(leaves) do
		if (cheapest == nil) then
			cheapest = leaf
		else
			if (leaf.runningCost < cheapest.runningCost) then
				cheapest = leaf
			end
		end
	end

	--get its node and work back through the parents
	---@type table<GoapAction>
	local result = {}
	---@type Node
	local n = cheapest
	while (n ~= nil) do
		if (n.action ~= nil) then
			table.insert(result, 1, n.action) --insert the action in the front
		end
		n = n.parent
	end
	--we now have this action list in correct order

	---@type table<GoapAction>
	local queue = {}
	for _, a in ipairs(result) do
		table.insert(queue, a)
	end

	--hooray we have a plan!
	return queue
end

--[[
	Returns true if at least one solution was found.
	The possible paths are stored in the leaves list. Each leaf has a
	'runningCost' value where the lowest cost will be the best action
	sequence.
]]
---@param parent Node
---@param leaves table<Node>
---@param usableActions table<GoapAction>
---@param goal table<string, function>
---@return boolean
function GoapPlanner.buildGraph(parent, leaves, usableActions, goal)
	---@type boolean
	local foundOne = false

	--go through each action available at this node and see if we can use it here
	for _, action in ipairs(usableActions) do

		--if the parent state has the conditions for this action's preconditions, we can use it here
		if (GoapPlanner.inState(action.Preconditions, parent.state)) then

			--apply the action's effects to the parent state
			---@type table<string, function>
			local currentState = GoapPlanner.populateState(parent.state, action.Effects)
			---@type Node
			local node = assert(Node:new(parent, parent.runningCost + action.cost, currentState, action))

			if (GoapPlanner.inState(goal, currentState)) then
				--we found a solution!
				table.insert(leaves, node)
				foundOne = true
			else
				--not at a solution yet, so test all the remaining actions and branch out the tree
				---@type table<GoapAction>
				local subset = GoapPlanner.actionSubset(usableActions, action)
				---@type boolean
				local found = GoapPlanner.buildGraph(node, leaves, subset, goal)
				if (found) then
					foundOne = true
				end
			end
		end
	end

	return foundOne
end

--[[
	Create a subset of the actions excluding the removeMe one. Creates a new set.
]]
---@param actions table<GoapAction>
---@param removeMe GoapAction
---@return table<GoapAction>
function GoapPlanner.actionSubset(actions, removeMe)
	---@type table<GoapAction>
	local subset = {}
	for _, a in ipairs(actions) do
		if (~a.Equals(removeMe)) then
			table.insert(subset, a)
		end
	end
	return subset
end

--[[
	Check that all items in 'test' are in 'state'. If just one does not match or is not there
	then this returns false.
]]
---@param test table<string, function>
---@param state table<string, function>
---@return boolean
function GoapPlanner.inState(test, state)
	---@type boolean
	local allMatch = true
	for tk, tv in pairs(test) do
		---@type boolean
		local match = false
		for sk, sv in pairs(state) do
			if (sk == tk and sv == tv) then
				match = true
				break
			end
		end
		if (~match) then
			allMatch = false
		end
	end
	return allMatch
end

--[[
	Apply the stateChange to the currentState
]]
---@param currentState table<string, function>
---@param stateChange table<string, function>
---@return table<string, function>
function GoapPlanner.populateState(currentState, stateChange)
	---@type table<string, function>
	local state = {}
	--copy the KVPs over as new objects
	for sk, sv in pairs(currentState) do
		state[sk] = sv
	end

	for changeK, changeV in pairs(stateChange) do
		state[changeK] = changeV
	end
	return state
end
