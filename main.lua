local utf8 = require("utf8")
local isDown = love.keyboard.isDown
local player = nil
local npcs = nil
local dialog = nil
local input = nil
local choice = nil
local areas = nil
local area = nil

-- Bilder för NPCs
local reskantis = nil
local restrattis = nil
local resmorfar = nil
local resfont = nil

function utf8sub(s, to)
	return s:sub(1, (utf8.offset(s, to) or #s + 1) - 1)
end

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

function createNpc(x, y, image, dialogTree)
	return {
		x = x,
		y = y,
		dialogTree = dialogTree,
		update = function(npc) end,
		draw = function(npc)
			love.graphics.setColor(1, 1, 1)
			love.graphics.draw(image, npc.x, npc.y)
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
			local scale = 1
			local typingSpeed = 50
			local charactersShown = math.max(1, math.floor(dialog.time * typingSpeed))
			love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
			love.graphics.rectangle("fill", 0, dialogY, dialogWidth, dialogHeight)
			love.graphics.setColor(1, 1, 1)
			if node.type == "text" then
				love.graphics.printf(
					utf8sub(node.text, charactersShown),
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
					utf8sub(yt, charactersShown),
					padding,
					dialogY + padding,
					(npcStart - padding) / scale,
					"left",
					0,
					scale
				)
				love.graphics.printf(
					utf8sub(nt, charactersShown),
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

		-- Den rika änkan
		createNpc(
			400,
			300,
			reskantis,
			createDialogTree()
				.text(
					"Och varför skulle jag vilja gå på en sådan tillställning? Där alla de andra snofsiga svamparna kommer prata illa om mig bakom min rygg?",
					2
				)
				.choice(
					function(dt, npc)
						dt.index = 4
					end,
					function(dt, npc)
						dt.index = 10
					end,
					"Jag tror inte att någon skulle prata illa om dig!",
					"Sant, det låter inte så trevligt att gå dit."
				)
				-- Om de väljer alternativet där de förlorar NPCn i val 1
				.text("Nej, exakt! Så om du ursäktar har jag ett glas daggdroppar som väntar på mig.", 10)
				-- Om spelaren väljer alternativet där de fortfarande kan vinna NPCn i val 1
				.text(
					"Åh, så naiv du är! Det är klart att de kommer göra det, de har det gjort ända sedan mitt giftermål till min älskade Gerald… Du förstår, jag var en fattig liten svamp när jag träffade min man för första gången. Ingen familj kvar efter kriget. Min man, Bertil, var i militären och försvann. Det var en ensam tillvaro… Men sen kom Gerald.",
					5
				)
				.text(
					"Han gav mig hopp om livet och vi gifte oss. Jag trodde att mitt liv äntligen vänt. Han blev min bästa vän och vår tid tillsammans var underbar... *suckar och ser drömmande ut*",
					6
				)
				.text(
					"Men… alla andra trodde att jag gifte mig för pengarna och sedan dess har de andra aristokraterna alltid sett ner på mig. Det var svårt att få vänner. *hennes uppsyn blir mer och mer bister igen* Och inte blev det bättre när min älskade gick bort. Jag har varit helt ensam sedan dess. Men hellre ensam än i ett rum med dömande och tråkiga svampar!!",
					7
				)
				.choice(
					function(dt, npc)
						dt.index = 8
					end,
					function(dt, npc)
						dt.index = 9
					end,
					"Du inbillar dig säkert bara! Jag tror alla tycker om dig!",
					"Jag ska bjuda alla, du kommer säkert hitta nya vänner! Då blir du inte lika ensam längre."
				)
				-- Förlorar karaktären
				.text(
					"Inbillning? Det tror jag knappast! Nej nu är det bäst att du springer vidare lilla svamp, jag har viktigare saker för mig.",
					10
				)
				-- Vinner karaktären
				.text(
					"Verkligen? Hmm... Det kanske, fast nej… eller okej. Det vore trevligt att få umgås med vanligt folk igen… Jag gör det, lilla kantarell. Vi ses på balen!",
					10
				)
				.ending(10)
		),

		-- Morfar
		createNpc(
			700,
			300,
			resmorfar,
			createDialogTree()
				.text(
					"Hejsan, min lilla kantarell. Är du ute på uppdrag åt kungen? Jag har ju sagt till din mor att du borde vara här på gården med mig. Men men… en bal säger du? Hmm… det var länge sedan jag var på fest. Du skulle ha sett mig i mina glansdagar! Jag var bäst på fest!",
					2
				)
				.text(
					"Vi gör så här: Om du kan lösa min gåta så går jag med dig på balen. Hur många av varje djurart tog Moses med sig på arken?",
					3
				)
				.choice(function(dt, npc)
					dt.index = 4
				end, function(dt, npc)
					dt.index = 5
				end, "Två", "Inga")
				.text(
					"Två? Nej inga! Moses var inte på arken, det var Noah. Du behöver studera dina bibelverser, min lilla kantarell. Du vill inte att prästen hör dig svara sådär.",
					6
				)
				.text("Precis! Inga! Moses var inte på arken, det var Noah. Jag antar att detta innebär fest för mig!", 6)
				.ending(6)
		),
		createNpc(
			600,
			400,
			restrattis,
			createDialogTree()
				.text(
					"Mig? På en bal? Men lilla kantarell, tror du de skulle släppa in mig med alla mina barn? Du vet att jag inte kan lämna dem ensamma och inte har jag någon som kan ta hand om dem.",
					2
				)
				.choice(
					function(dt, npc)
						dt.index = 3
					end,
					function(dt, npc)
						dt.index = 3
					end,
					"Jag ska bjuda in hela riket! Så klart att de släpper in er!",
					"Det kommer säkert en massa barn på balen, den är till för hela riket!"
				)
				.text(
					"På riktigt? Nämen, oj, då måste vi ju passa på! En bal på slotten, kan du tänka dig! Tack lilla kantarell! Lycka till med ditt uppdrag så ses vi på balen. Nu har jag en massa förberedelser att stå i!",
					4
				)
				.ending(4)
		),
	}
	dialog = nil
	input = { interact = false }
	choice = nil
	areas = {
		createArea({ npcs[1] }, { 0, 0.5, 0 }, { createPortal(100, 400, 2) }),
		createArea({ npcs[2], npcs[3] }, { 0.5, 0, 0 }, { createPortal(100, 400, 1) }),
	}
	area = areas[1]
end

function love.load()
	love.window.setFullscreen(true)
	reskantis = love.graphics.newImage("res/kantis.png")
	restrattis = love.graphics.newImage("res/famly50.png")
	resmorfar = love.graphics.newImage("res/morfar.png")
	resfont = love.graphics.newFont("res/Chalkduster.ttf", 28)
	love.graphics.setFont(resfont)
	restart()
end

function love.keypressed(key)
	if key == "space" or key == "return" then
		input.interact = true
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
	if closePortal ~= nil and input.interact then
		area = areas[closePortal.next]
	end
	closeNpc = player:getCloseEntity(area.npcs)
	if closeNpc ~= nil then
		if input.interact then
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

	input.interact = false
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
