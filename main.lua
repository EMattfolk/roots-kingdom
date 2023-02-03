local isDown = love.keyboard.isDown
local player = nil
local npcs = nil

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
			table.foreach(npcs, function(npc) end)
			return res
		end,
	}
end

function createNpc(x, y)
	return {
		x = x,
		y = y,
		update = function(npc) end,
		draw = function(npc)
			love.graphics.setColor(0, 1, 0)
			love.graphics.rectangle("fill", npc.x, npc.y, 100, 100)
		end,
	}
end

function love.draw()
	love.graphics.print("Hello World!", 400, 300)
	player:draw()

	table.foreach(npcs, function(_, npc)
		npc:draw()
	end)
end

function restart()
	player = createPlayer()
	npcs = { createNpc(700, 500), createNpc(400, 500) }
end

function love.load()
	restart()
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
end
