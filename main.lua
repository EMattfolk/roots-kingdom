local isDown = love.keyboard.isDown
local player = nil
local npcs = nil
local dialog = nil
local input = nil
local choice = nil
local areas = nil
local area = nil

function createPortal(x, y, next)
	return {
		x = x,
		y = y,
		next = next,
		draw = function(portal)
			love.graphics.setColor(0, 0, 1)
			love.graphics.rectangle("fill", portal.x, portal.y, 50, 50)
		end,
	}
end

function createArea(npcs, color, portals)
	return {
		npcs = npcs,
		portals = portals,
		draw = function(area)
			love.graphics.setColor(color)
			love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
			table.foreach(area.portals, function(_, portal)
				portal:draw()
			end)
		end,
	}
end

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
		ending = function(next)
			table.insert(dt.data, { type = "end", next = next })
			return dt
		end,
		advance = function(choseYes, npc)
			if dt.get().type == "text" or dt.get().type == "end" then
				dt.index = dt.get().next
			elseif dt.get().type == "choice" then
				if choseYes then
					dt.get().yes(dt, npc)
				else
					dt.get().no(dt, npc)
				end
			end
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
		getCloseEntity = function(player, entities)
			range = 100
			res = nil
			table.foreach(entities, function(_, entity)
				local dx = player.x - entity.x
				local dy = player.y - entity.y
				if dx * dx + dy * dy <= range * range then
					res = entity
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
	if node.type == "end" then
		return nil
	end
	return {
		time = 0,
		update = function(dialog, delta)
			dialog.time = dialog.time + delta
		end,
		draw = function(dialog)
			local dialogHeight = love.graphics.getHeight() / 4
			local dialogWidth = love.graphics.getWidth()
			local dialogY = love.graphics.getHeight() - dialogHeight
			local padding = love.graphics.getHeight() / 20
			local npcStart = love.graphics.getWidth() * 3 / 4
			local scale = 2
			local typingSpeed = 50
			local charactersShown = math.max(1, math.floor(dialog.time * typingSpeed))
			love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
			love.graphics.rectangle("fill", 0, dialogY, dialogWidth, dialogHeight)
			love.graphics.setColor(1, 1, 1)
			if node.type == "text" then
				love.graphics.printf(
					node.text:sub(1, charactersShown),
					padding,
					dialogY + padding,
					(npcStart - padding) / scale,
					"left",
					0,
					scale
				)
			elseif node.type == "choice" then
				local yt = node.yesText
				local nt = node.noText
				if choice then
					yt = yt .. " <-"
				else
					nt = nt .. " <-"
				end
				love.graphics.printf(
					yt:sub(1, charactersShown),
					padding,
					dialogY + padding,
					(npcStart - padding) / scale,
					"left",
					0,
					scale
				)
				love.graphics.printf(
					nt:sub(1, charactersShown),
					padding,
					dialogY + 3 * padding,
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
				.text("there.", 3)
				.choice(function(dt, npc)
					dt.index = 1
				end, function(dt, npc)
					dt.index = 4
				end, "yes", "no")
				.ending(1)
		),
		createNpc(700, 300, createDialogTree().text("Wow", 2).text("Such text", 1)),
	}
	dialog = nil
	input = { space = false }
	choice = nil
	areas = {
		createArea({ npcs[1], npcs[2] }, { 0, 0.5, 0 }, { createPortal(100, 400, 2) }),
		createArea({}, { 0.5, 0, 0 }, { createPortal(100, 400, 1) }),
	}
	area = areas[1]
end

function love.load()
	love.window.setFullscreen(true)
	restart()
end

function love.keypressed(key)
	if key == "space" then
		input.space = true
	end
end

function love.update(dt)
	if dialog == nil then
		player:update(dt)
	else
		dialog:update(dt)
	end
	table.foreach(area.npcs, function(_, npc)
		npc:update()
	end)
	if isDown("up") then
		choice = true
	elseif isDown("down") then
		choice = false
	end
	if isDown("r") then
		restart()
	end
	if isDown("q") or isDown("escape") then
		love.event.quit()
	end
	closePortal = player:getCloseEntity(area.portals)
	if closePortal ~= nil and input.space then
		area = areas[closePortal.next]
	end
	closeNpc = player:getCloseEntity(area.npcs)
	if closeNpc ~= nil then
		if input.space then
			local dt = closeNpc.dialogTree
			if dialog ~= nil then
				dt.advance(choice, closeNpc)
				choice = true
			end
			dialog = createDialog(dt.get())
			if dialog == nil then -- We arrived at ending
				dt.advance(choice, closeNpc) -- Args not needed here
				choice = true
			end
		end
	else
		dialog = nil
	end

	input.space = false
end

function love.draw()
	area:draw()
	table.foreach(area.npcs, function(_, npc)
		npc:draw()
	end)
	player:draw()
	if dialog ~= nil then
		dialog:draw()
	end
end
