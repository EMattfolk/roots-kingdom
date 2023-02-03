isDown = love.keyboard.isDown

player = {
	x = 0,
	y = 0,
	speed = 250,
	move = function(dt)
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
}

function love.draw()
	love.graphics.print("Hello World!", 400, 300)
	love.graphics.rectangle("fill", player.x, player.y, 100, 100)
end

function love.update(dt)
	player.move(dt)
	if isDown("q") or isDown("escape") then
		love.event.quit()
	end
end
