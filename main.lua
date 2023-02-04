local isDown = love.keyboard.isDown
local player = nil
local npcs = nil
local dialog = nil
local input = nil

function createDialogTree()
	local dt = nil
	dt = {
		text = function(t, next)
			table.insert(dt.data, { type = "text", text = t, next = next })
			return dt
		end,
		choice = function(yes, no, yesText, noText)
			table.insert(dt.data, {
				type = "choice",
				yes = yes,
				no = no,
				yesText = yesText,
				noText = noText,
			})
			return dt
		end,
		index = 1,
		data = {},
		get = function()
			return dt.data[dt.index]
		end,
	}
	return dt
end

function createPlayer()
	return {
		x = 0,
		y = 0,
		speed = 400,
		update = function(player, dt)
			local dx = 0
			local dy = 0
			if isDown("up") then
				dy = -1
			end
			if isDown("down") then
				dy = 1
			end
			if isDown("left") then
				dx = -1
			end
			if isDown("right") then
				dx = 1
			end

			local tot = math.sqrt(dx * dx + dy * dy)
			if tot ~= 0 then
				dx = dx / tot
				dy = dy / tot
			end

			player.x = player.x + dt * dx * player.speed
			player.y = player.y + dt * dy * player.speed
		end,
		draw = function(player)
			love.graphics.setColor(1, 1, 0)
			love.graphics.rectangle("fill", player.x, player.y, 100, 100)
		end,
		getCloseNpc = function(player, npcs)
			range = 100
			res = nil
			table.foreach(npcs, function(_, npc)
				local dx = player.x - npc.x
				local dy = player.y - npc.y
				if dx * dx + dy * dy <= range * range then
					res = npc
				end
			end)
			return res
		end,
	}
end

function createNpc(x, y, dialogTree)
	return {
		x = x,
		y = y,
		dialogTree = dialogTree,
		update = function(npc) end,
		draw = function(npc)
			love.graphics.setColor(0, 1, 0)
			love.graphics.rectangle("fill", npc.x, npc.y, 100, 100)
		end,
	}
end

function createDialog(node)
	return {
		draw = function()
			local dialogHeight = love.graphics.getHeight() / 4
			local dialogWidth = love.graphics.getWidth()
			local dialogY = love.graphics.getHeight() - dialogHeight
			local padding = love.graphics.getHeight() / 20
			local npcStart = love.graphics.getWidth() * 3 / 4
			local scale = 2
			love.graphics.setColor(0.5, 0.5, 0.5)
			love.graphics.rectangle("fill", 0, dialogY, dialogWidth, dialogHeight)
			love.graphics.setColor(1, 1, 1)
			if true then
				love.graphics.printf(
					node.text,
					padding,
					dialogY + padding,
					(npcStart - padding) / scale,
					"left",
					0,
					scale
				)
			end
		end,
	}
end

function restart()
	player = createPlayer()
	npcs = {
		createNpc(
			400,
			300,
			createDialogTree()
				.text("Hello", 2)
				.text("there.", 1)
				.choice(function(dt) end, function(dt) end, "yes", "no")
		),
		createNpc(700, 300, createDialogTree().text("Wow", 2).text("Such text", 1)),
	}
	dialog = nil
	input = { space = false }
end

function love.load()
	restart()
end

function love.keypressed(key)
	if key == "space" then
		input.space = true
	end
end

function love.update(dt)
	player:update(dt)
	table.foreach(npcs, function(_, npc)
		npc:update()
	end)
	if isDown("r") then
		restart()
	end
	if isDown("q") or isDown("escape") then
		love.event.quit()
	end
	closeNpc = player:getCloseNpc(npcs)
	if closeNpc ~= nil then
		if input.space then
			if dialog ~= nil then
				closeNpc.dialogTree.index = closeNpc.dialogTree.get().next
			end
			dialog = createDialog(closeNpc.dialogTree.get())
		end
	else
		dialog = nil
	end

	input.space = false
end

function love.draw()
	love.graphics.print("Hello World!", 400, 300)
	table.foreach(npcs, function(_, npc)
		npc:draw()
	end)
	player:draw()
	if dialog ~= nil then
		dialog:draw()
	end
end
