local mc = require("sb_goap.utils.middleclass")
local Queue = require("sb_goap.utils.Queue")

--[[
Plans what actions can be completed in order to fulfill a goal state.
]]
---@class GoapPlanner
local GoapPlanner = mc.class("GoapPlanner")

--[[
Used for building up the graph and holding the running costs of actions.
]]
---@class Node
local Node = mc.class("Node")

---@param parent Node
---@param runningCost number
---@param state table<number,table<string,any>>
---@param action GoapAction
function Node:initialize(parent, runningCost, state, action)
	self.parent = parent
	self.runningCost = runningCost
	self.state = state
	self.action = action
end

--[[
	Plan what sequence of actions can fulfill the goal.
	Returns null if a plan could not be found, or a list of the actions
	that must be performed, in order, to fulfill the goal.
	 ]]
---@param ref tes3reference
---@param availableActions table<GoapAction>
---@param worldState table<number,table<string,any>>
---@param goal table<number,table<string,any>>
---@return Queue<GoapAction>
function GoapPlanner:plan(ref, availableActions, worldState, goal)

	-- reset the actions so we can start fresh with them
	for _, a in ipairs(availableActions) do
		a:doReset()
	end

	-- check what actions can run using their checkProceduralPrecondition
	---@type table<GoapAction>
	local usableActions = {}
	for _, a in ipairs(availableActions) do
		if (a:checkProceduralPrecondition(ref)) then
			table.insert(usableActions, a)
		end
	end

	-- we now have all actions that can run, stored in usableActions

	-- build up the tree and record the leaf nodes that provide a solution to the goal.
	---@type table<Node>
	local leaves = {}

	-- build graph
	---@type Node
	local start = Node:new(nil, 0, worldState, nil)
	local success = self:buildGraph(start, leaves, usableActions, goal)

	if (not success) then
		-- oh no, we didn't get a plan
		mwse.log("NO PLAN")
		return nil
	end

	-- get the cheapest leaf
	---@type Node
	local cheapest = nil
	for _, leaf in ipairs(leaves) do
		if (cheapest == nil) then
			cheapest = leaf
		elseif (leaf.runningCost < cheapest.runningCost) then
			cheapest = leaf
		end
	end

	-- get its node and work back through the parents
	---@type table<GoapAction>
	local result = {}
	---@type Node
	local n = cheapest
	while (n ~= nil) do
		if (n.action ~= nil) then
			table.insert(result, 1, n.action) -- insert the action in the front
		end
		n = n.parent
	end
	-- we now have this action list in correct order

	---@type Queue<GoapAction>
	local queue = Queue:new()
	for _, a in ipairs(result) do
		queue:push(a)
	end

	-- hooray we have a plan!
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
---@param goal table<number,table<string,any>>
---@return boolean
function GoapPlanner:buildGraph(parent, leaves, usableActions, goal)
	local foundOne = false

	-- go through each action available at this node and see if we can use it here
	for _, action in ipairs(usableActions) do

		-- if the parent state has the conditions for this action's preconditions, we can use it here
		if (self:inState(action.Preconditions, parent.state)) then

			-- apply the action's effects to the parent state
			---@type table<number,table<string,any>>
			local currentState = self:populateState(parent.state, action.Effects)
			--mwse.log(GoapAgent.prettyPrint(currentState))
			---@type Node
			local node = Node:new(parent, parent.runningCost + action.cost, currentState, action)

			if (self:inState(goal, currentState)) then
				-- we found a solution!
				table.insert(leaves, node)
				foundOne = true
			else
				-- not at a solution yet, so test all the remaining actions and branch out the tree
				---@type table<GoapAction>
				local subset = self:actionSubset(usableActions, action)
				local found = self:buildGraph(node, leaves, subset, goal)
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
function GoapPlanner:actionSubset(actions, removeMe)
	---@type table<GoapAction>
	local subset = {}
	for _, a in ipairs(actions) do
		if (a ~= removeMe) then
			table.insert(subset, a)
		end
	end
	return subset
end

--[[
Check that all items in 'test' are in 'state'. If just one does not match or is not there
then this returns false.
]]
---@param test table<number,table<string,any>>
---@param state table<number,table<string,any>>
---@return boolean
function GoapPlanner:inState(test, state)
	local allMatch = true
	for _, t in ipairs(test) do
		local match = false
		for _, s in ipairs(state) do
			if (s == t) then
				match = true
				break
			end
		end
		if (not match) then
			allMatch = false
		end
	end
	return allMatch
end

--[[
Apply the stateChange to the currentState
]]
---@param currentState table<number,table<string,any>>
---@param stateChange table<number,table<string,any>>
---@return table<number,table<string,any>>
function GoapPlanner:populateState(currentState, stateChange)
	---@type table<number,table<string,any>>
	local state = {}
	-- copy the KVPs over as new objects
	for _, s in ipairs(currentState) do
		table.insert(state, { s[1], s[2] })
	end

	for _, change in ipairs(stateChange) do
		-- if the key exists in the current state, update the Value
		local exists = false

		for _, s in ipairs(state) do
			if (s == change) then
				exists = true
				break
			end
		end

		if (exists) then
			for _, s in state do
				if (s[1] == change[1]) then
					table.removevalue(state, s)
				end
			end
			---@type table<string,any>
			local updated = { change[1], change[2] }
			table.insert(state, updated)

			-- if it does not exist in the current state, add it
		else
			table.insert(state, { change[1], change[2] })
		end
	end
	return state
end

return GoapPlanner
