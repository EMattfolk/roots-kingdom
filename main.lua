isDown = love.keyboard.isDown
player = nil
npcs = nil

function createPlayer()
	return {
		x = 0,
		y = 0,
		speed = 250,
		update = function(player, dt)
			if isDown("up") then
				player.y = player.y - dt * player.speed
			end
			if isDown("down") then
				player.y = player.y + dt * player.speed
			end
			if isDown("left") then
				player.x = player.x - dt * player.speed
			end
			if isDown("right") then
				player.x = player.x + dt * player.speed
			end
		end,
		draw = function(player)
			love.graphics.setColor(1, 1, 0)
			love.graphics.rectangle("fill", player.x, player.y, 100, 100)
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
	if isDown("q") or isDown("escape") then
		love.event.quit()
	end
end
