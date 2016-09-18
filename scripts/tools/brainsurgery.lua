local function FindNode(root, name)
	for i,ch in ipairs(root.children) do
		if (ch.name == "Parallel" or ch.name == "Sequence") and ch.children[1].name == name or ch.name == name then
			return ch, i
		end
	end
end

local function MoveNode(root, move_this, near_this, before)
	before = before == false or true
	local move_node, move_i = FindNode(root, move_this)
	local near_node, near_i = FindNode(root, near_this)
	if move_i < near_i then --because we remove move_node, near_node got shifted downward
		near_i = near_i - 1
	end
	if not before then --we want it after near_node, so bump the index up one
		near_i = near_i + 1
	end
	table.remove(root.children, move_i)
	table.insert(root.children, near_i, move_node)
end

return {
	FindNode = FindNode,
	MoveNode = MoveNode,
}