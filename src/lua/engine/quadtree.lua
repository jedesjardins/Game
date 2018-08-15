local Node = {}
Node.__index = Node

function Node.new(x, y, w, h)
	local self = setmetatable({}, Node)

	self.x = x
	self.y = y
	self.w = w
	self.h = h

	self.ids = {}		-- list of entity ids at this level
	self.children = nil	-- children nodes

	return self
end

function Node:add(id)
	self.ids[#self.ids+1] = id
end

-- Split the Node into 4 children
function Node:split()
	local bl = Node.new(self.x-self.w/4, self.y-self.h/4, self.w/2, self.h/2)
	local br = Node.new(self.x+self.w/4, self.y-self.h/4, self.w/2, self.h/2)
	local tl = Node.new(self.x-self.w/4, self.y+self.h/4, self.w/2, self.h/2)
	local tr = Node.new(self.x+self.w/4, self.y+self.h/4, self.w/2, self.h/2)


	self.children = {tl, bl, tr, br}
end

-- Get the child that the rect fits in
function Node:getIndex(rect)
	--[[
		in rect, x and y are the middle of the square
	]]

	local index = 0

	local topQuadrant = rect.y - rect.h/2 > self.y and rect.y + rect.h/2 < self.y + self.h/2

	local botQuadrant = rect.y - rect.h/2 > self.y - self.h/2 and rect.y + rect.h/2 < self.y

	if rect.x + rect.w/2 < self.x and rect.x - rect.w/2 > self.x - self.w/2 then -- left quadrant
		if topQuadrant then
			index = 1
		else if botQuadrant then
			index = 2
		end end
	else if rect.x - rect.w/2 > self.x and rect.x + rect.w/2 < self.x + self.w/2 then -- right quadrant
		if topQuadrant then
			index = 3
		else if botQuadrant then
			index = 4
		end end
	end end

	return index
end



local QuadTree = {}
QuadTree.__index = QuadTree

function QuadTree.new(x, y, w, h)
	local self = setmetatable({}, QuadTree)

	self.root = Node.new(x, y, w, h)
	self.id_to_node = {}

	return self
end

function QuadTree:insert(id, rect)

	-- insert
	local node = self.root
	local inserted = false
	local child_index = -1

	-- try and insert it into the Node
	for d = 1, 4 do
		child_index = node:getIndex(rect)

		if child_index == 0 then
			node:add(id)
			self.id_to_node[id] = node
			inserted = true
			break
		else
			-- recurse
			if not node.children then
				node:split()
			end
			node = node.children[child_index]
		end
	end

	if not inserted then
		node:add(id)
	end

end

--[[

while not stopped
	if index = 0
		add all children
	else 

]]

function QuadTree:retrieve(rect)

	local ids = {}
	local child_index = 0

	local node = self.root
	local nodes = List.new()

	nodes:pushright(node)

	while nodes:size() > 0 do
		node = nodes:popleft()
		table.join(ids, node.ids)

		if node.children then
			child_index = node:getIndex(rect)
			if child_index == 0 then
				-- add all children
				for i = 1, #node.children do
					nodes:pushleft(node.children[i])
				end
			else
				-- add only the index node
				nodes:pushleft(node.children[child_index])
			end
		end
	end

	return ids
end

function QuadTree:clear()
	self.ids = {}

	local node = self.root
	local nodes = List.new()
	nodes:pushleft(node)

	while nodes:size() > 0 do
		node = nodes:popright()
		node.ids = nil
		if node.children then
			for i = 1, #node.children do
				nodes:pushleft(node.children[i])
				node.children[i] = nil
			end
		end
	end
	self.root = nil
end

return QuadTree

