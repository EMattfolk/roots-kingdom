local utf8 = require("utf8")
local isDown = love.keyboard.isDown
local player = nil
local npcs = nil
local dialog = nil
local input = nil
local choice = nil
local areas = nil
local area = nil
local scene = nil
local transition = nil

-- Bilder för NPCs
local reskantis = nil
local restrattis = nil
local resmorfar = nil
local resfont = nil
local resbigfont = nil
local resguard = nil
local resfancyfancy = nil
local resbackground = nil
local resthedarkside = nil
local resemo = nil
local resptsd = nil
local resblygsvamp = nil
local resghost = nil
local resking = nil
local resmodern = nil
local rescastle = nil
local resdamm = nil

local dammsystem = nil

function utf8sub(s, to)
	return s:sub(1, (utf8.offset(s, to) or #s + 1) - 1)
end

function toScreenX(x)
	return love.graphics.getWidth() / 1920 * x
end

function toScreenY(y)
	return love.graphics.getHeight() / 1080 * y
end

function createTransition(dir, onTransition)
	return {
		progress = 0,
		transitioned = false,
		draw = function(tr)
			local xdir = dir.x
			local ydir = dir.y
			love.graphics.setColor(0, 0, 0)
			if tr.transitioned then
				love.graphics.rectangle(
					"fill",
					xdir * tr.progress * love.graphics.getWidth(),
					ydir * tr.progress * love.graphics.getHeight(),
					love.graphics.getWidth(),
					love.graphics.getHeight()
				)
			else
				love.graphics.rectangle(
					"fill",
					love.graphics.getWidth() * -xdir + xdir * tr.progress * love.graphics.getWidth(),
					love.graphics.getHeight() * -ydir + ydir * tr.progress * love.graphics.getHeight(),
					love.graphics.getWidth(),
					love.graphics.getHeight()
				)
			end
		end,
		update = function(tr, delta)
			local speed = 2
			tr.progress = math.min(1, tr.progress + delta * speed)
			if not tr.transitioned and tr.progress == 1 then
				tr.transitioned = true
				tr.progress = 0
				onTransition()
			end
		end,
	}
end

function createPortal(x, y, next, newX, newY)
	return {
		x = x,
		y = y,
		next = next,
		newX = newX,
		newY = newY,
		draw = function(portal)
			love.graphics.setColor(0, 0, 1)
			love.graphics.ellipse("line", toScreenX(portal.x), toScreenY(portal.y), 50, 25)
		end,
	}
end

function createArea(image, npcs, portals)
	return {
		npcs = npcs,
		portals = portals,
		draw = function(area)
			local xscale = love.graphics.getWidth() / image:getWidth()
			local yscale = love.graphics.getHeight() / image:getHeight()
			love.graphics.setColor(1, 1, 1)
			love.graphics.draw(image, 0, 0, 0, xscale, yscale)
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
		x = 1100,
		y = 600,
		vx = 0,
		vy = 0,
		dir = 1,
		speed = 400,
		acc = 850,
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

				local dir = math.atan2(-player.vy, -player.vx)
				dammsystem:setDirection(dir)
				dammsystem:setPosition(toScreenX(player.x), toScreenY(player.y + reskantis:getHeight() / 2))
				dammsystem:start()
			else
				dammsystem:pause()
			end

			local drag = 0.001
			player.vx = math.pow(drag, dt) * player.vx + dt * dx * player.acc
			player.vy = math.pow(drag, dt) * player.vy + dt * dy * player.acc

			local vlen = math.sqrt(player.vx * player.vx + player.vy * player.vy)
			local speedScale = vlen / math.max(vlen, player.speed)
			player.vx = player.vx + dt * dx * player.acc
			player.vy = player.vy + dt * dy * player.acc

			player.x = player.x + dt * player.vx
			player.y = player.y + dt * player.vy

			if dx < 0 then
				player.dir = -1
			elseif dx > 0 then
				player.dir = 1
			end
		end,
		draw = function(player)
			local vlen = math.sqrt(player.vx * player.vx + player.vy * player.vy)
			local speedSquash = math.sqrt(vlen) / 500
			local wiggle = 2 * (math.sqrt(vlen) / 500) * math.sin(love.timer.getTime() * 10)
			local scale = toScreenX(2)
			love.graphics.setColor(1, 1, 1)
			love.graphics.draw(
				reskantis,
				toScreenX(player.x),
				toScreenY(player.y),
				wiggle,
				-player.dir * scale,
				scale * (1 + 0.03 * math.sin(love.timer.getTime() * 7 + 2)) * (1 - speedSquash),
				reskantis:getWidth() / 2,
				reskantis:getHeight() / 2
			)
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

function createNpc(x, y, image, dialogTree, breathSpeed)
	local breathSpeed = breathSpeed or 5
	return {
		x = x,
		y = y,
		accepted = false,
		dialogTree = dialogTree,
		update = function(npc) end,
		draw = function(npc)
			local scale = toScreenX(2)
			love.graphics.setColor(1, 1, 1)
			love.graphics.draw(
				image,
				toScreenX(npc.x),
				toScreenY(npc.y),
				0,
				scale,
				scale * (1 + 0.02 * math.sin(love.timer.getTime() * breathSpeed)),
				image:getWidth() / 2,
				image:getHeight() / 2
			)
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
			local typingSpeed = 60
			local charactersShown = math.max(1, math.floor(dialog.time * typingSpeed))
			love.graphics.setColor(0, 0, 0, 0.4)
			love.graphics.rectangle("fill", 0, dialogY, dialogWidth, dialogHeight)
			love.graphics.setColor(1, 1, 1)
			love.graphics.setFont(resfont)
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
				local arrow = " <-"
				local _, frac = math.modf(love.timer.getTime())
				if frac > 0.5 then
					arrow = "  <-"
				end
				if choice then
					yt = yt .. arrow
				else
					nt = nt .. arrow
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
			1250,
			350,
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
						dt.index = 14
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
						npc.accepted = true
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
					11
				)
				.ending(13)
				.ending(12)
				.text("Jag har inte tid att prata, jag måste göra mig iordning.", 11)
				.text("Låt mig vara ifred med mina daggdroppar, kära du.", 10)
				.text("Precis. Så var så snäll och gå. Jag har ett glas daggdroppar som väntar på mig nu.", 10)
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
					npc.accepted = true
				end, function(dt, npc)
					dt.index = 5
					npc.accepted = true
				end, "Två", "Inga")
				.text(
					"Två? Nej inga! Moses var inte på arken, det var Noah. Du behöver studera dina bibelverser, min lilla kantarell. Du vill inte att prästen hör dig svara sådär. Bäst att jag följer med på festen och ser till att du läser på lite, hehe.",
					6
				)
				.text("Precis! Inga! Moses var inte på arken, det var Noah. Jag antar att detta innebär fest för mig!", 6)
				.ending(7)
				.text("Vad väger mest, ett kilo bomull eller ett kilo bly?", 8)
				.choice(function(dt, npc)
					dt.index = 9
				end, function(dt, npc)
					dt.index = 9
				end, "Bomull", "Bly")
				.text(
					"Fel svar, min lilla! Ett kilo bomull och ett kilo bly väger lika mycket! Du har ärvt din mors intellekt hör jag. Men det är okej, man kan inte vara bra på allt.",
					10
				)
				.ending(11)
				.text("Varför kan en svamp inte gifta sig med sin änkas syster?", 12)
				.choice(function(dt, npc)
					dt.index = 13
				end, function(dt, npc)
					dt.index = 13
				end, "Olagligt", "Omoraliskt")
				.text("Fel svar! Man kan väl inte gifta sig om man är död!", 14)
				.ending(15)
				.text("Hur många äpplen växer på ett träd?", 16)
				.choice(function(dt, npc)
					dt.index = 17
				end, function(dt, npc)
					dt.index = 18
				end, "Alla", "Inga")
				.text("Fel svar! Äpplen växer väl ändå på äppelträd?", 19)
				.text("Fel svar! Alla äpplen växer väl på träd?", 19)
				.ending(20)
				.text("När var det partajet började, min lilla kantarell?", 19)
		),
		-- Trattis mamma
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
						npc.accepted = true
					end,
					function(dt, npc)
						dt.index = 3
						npc.accepted = true
					end,
					"Jag ska bjuda in hela riket! Så klart att de släpper in er!",
					"Det kommer säkert en massa barn på balen, den är till för hela riket!"
				)
				.text(
					"På riktigt? Nämen, oj, då måste vi ju passa på! En bal på slotten, kan du tänka dig! Tack lilla kantarell! Lycka till med ditt uppdrag så ses vi på balen. Nu har jag en massa förberedelser att stå i!",
					4
				)
				.ending(5)
				.text("Så mycket att göra, så lite tid!", 4)
		),
		-- PTSD svamp
		createNpc(
			600,
			500,
			resptsd,
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
		-- EMO svamp
		createNpc(
			1200,
			300,
			resemo,
			createDialogTree()
				.text(
					"En bal? Usch va tråkigt! Det är säkert bara en massa Basic Bitch musik som Ted Gärdestad och Selena Gomez! Nej tack! De andra svamparna förstår inte min utsökta musiksmak. De skulle inte förstå sig på de fantastiska verken av Bill Kaulitz och resten i Tokio Hotel. Jag skulle inte passa in.",
					2
				)
				.choice(
					function(dt, npc)
						dt.index = 3
					end,
					function(dt, npc)
						dt.index = 4
						npc.accepted = true
					end,
					"Du har rätt. Stanna här och lyssna på din udda musik. Det är nog bäst.",
					"Jag har hört att det kommer finnas en DJ som tar önskemål! Och du hittar säkert några andra som gillar samma sort som dig! Du skulle passa in perfekt!"
				)
				.text(
					"Eller hur. Jag stannar mycket hellre här och lyssnar på Tokio Hotel… *nynnar* I'm staring at a broken door…. There's nothing left here anymore…My room is cold, it's making me insane…*mhmm*",
					5
				)
				.text(
					"Lilla kantarell, tror du på riktigt att det är något för mig? Hmm, antar att det inte skulle skada att gå dit en stund.",
					6
				)
				.ending(7)
				.ending(8)
				.text(
					"Running through the monsoon..... Beyond the world... Til' the end of time...Where the rain won't hurt",
					5
				)
				.text("Vi ses väl på balen senare då. Eller nåt'.", 6)
		),
		-- Ghost
		createNpc(
			1200,
			700,
			resghost,
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
		-- Long
		createNpc(
			600,
			300,
			resblygsvamp,
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
		-- Kungen
		createNpc(
			940,
			250,
			resking,
			createDialogTree()
				.text(
					"Oj oj oj. Vad ska jag ta mig till? Livsträdet har äntligen fått nya rötter och det är min födelsedag! Jag vill så gärna fira…..",
					2
				)
				.text(
					"Allt har varit så dystert i mitt kungadöme sedan kriget. Jag vill bringa lite glädje till mina undersåtar. Men hur?! Hmmm…",
					3
				)
				.text(
					"Vad vill folket alltid ha?...... Jag har det! Så klart! Jag måste anordna en bal! Men hur ska jag kunna bjuda in folket? Jag är för gammal för att resa.",
					4
				)
				.text(
					"*Kungen sjunker ihop och hans ögon fylls med tårar. Men plötsligt får han syn på dig och ser genast mer hoppfull ut.*",
					5
				)
				.text(
					"Lilla kantarell! Skulle inte du kunna hjälpa mig? Jag vill att hela riket bjuds in till min bal ikväll! Med din eviga optimism och livsglädje borde du kunna övertyga dem att komma! Godtar du detta uppdrag?",
					6
				)
				.choice(function(dt, npc)
					dt.index = 7
					npc.accepted = true -- Att kungen har accepterat sin egen inbjudan.
					table.insert(areas[1].portals, createPortal(960, 1050, 2, 100, 800))
				end, function(dt, npc)
					dt.index = 7
					npc.accepted = true -- Att kungen har accepterat sin egen inbjudan.
					table.insert(areas[1].portals, createPortal(960, 1050, 2, 100, 800))
				end, "Ja!", "Självklart!")
				.text("*Man tackar inte nej till en kung så du accepterar gladeligen ditt uppdrag.*", 8)
				.text("Underbart! Se så, skynda iväg och bjud in ALLA!", 9)
				.ending(10)
				.text("Jag hoppas det går bra med inbjudningarna, lilla kantarell", 9)
		),
		-- Alla vakter (9 st i princip identiska utöver att de introducerar till olika namn)
		-- Vakterna på Solsidan
		createNpc(200, 850, resguard, createDialogTree().text("Välkommen till Slottet!", 2).ending(1)),
		createNpc(
			1700,
			850,
			resguard,
			createDialogTree().text("Välkommen till Farmsidan! Det är här vi sköter all vår odling!", 2).ending(1)
		),
		createNpc(
			750,
			200,
			resguard,
			createDialogTree().text("Välkommen till Framsidan! Det är här våra ingenjörer bor.", 2).ending(1)
		),
		-- Vakter på Farmsidan
		createNpc(
			200,
			850,
			resguard,
			createDialogTree().text("Välkommen till Solsidan! Vårt finaste stadskvarter!", 2).ending(1)
		),
		createNpc(
			1300,
			200,
			resguard,
			createDialogTree()
				.text("Var försiktig när du går till Skuggsidan! Den är nära gränsen till ", 2)
				.ending(1)
		),
		-- Vakter på Skuggsidan
		createNpc(
			1300,
			900,
			resguard,
			createDialogTree().text("Välkommen till Farmsidan! Det är här vi sköter all vår odling!", 2).ending(1)
		),
		createNpc(
			200,
			350,
			resguard,
			createDialogTree().text("Välkommen till Framsidan! Det är här våra ingenjörer bor.", 2).ending(1)
		),
		-- Vakter på Framsidan
		createNpc(
			1700,
			400,
			resguard,
			createDialogTree()
				.text("Var försiktig när du går till Skuggsidan! Den är nära gränsen till ", 2)
				.ending(1)
		),
		createNpc(
			600,
			900,
			resguard,
			createDialogTree().text("Välkommen till Solsidan! Vårt finaste stadskvarter!", 2).ending(1)
		),
	}

	dialog = nil
	input = { interact = false }
	choice = nil
	areas = {
		createArea(rescastle, { npcs[8] }, {}), -- Slottet
		createArea(resfancyfancy, { npcs[1], npcs[9], npcs[10], npcs[11] }, {
			createPortal(100, 800, 1, 960, 1050),
			createPortal(650, 100, 5, 650, 1000),
			createPortal(1800, 750, 3, 100, 750),
		}),
		createArea(
			resbackground,
			{ npcs[2], npcs[3], npcs[12], npcs[13] },
			{ createPortal(100, 750, 2, 1800, 750), createPortal(1200, 100, 4, 1200, 1000) }
		),
		createArea(
			resthedarkside,
			{ npcs[4], npcs[5], npcs[14], npcs[15] },
			{ createPortal(1200, 1000, 3, 1200, 100), createPortal(100, 300, 5, 1800, 300) }
		),
		createArea(
			resmodern,
			{ npcs[6], npcs[7], npcs[16], npcs[17] },
			{ createPortal(650, 1000, 2, 650, 100), createPortal(1800, 300, 4, 100, 300) }
		),
	}
	area = areas[1]
	scene = "menu"
	transition = nil
end

function love.load()
	love.window.setFullscreen(true)
	love.graphics.setDefaultFilter("nearest", "nearest")
	reskantis = love.graphics.newImage("res/kantis.png")
	restrattis = love.graphics.newImage("res/famly50.png")
	resmorfar = love.graphics.newImage("res/morfar.png")
	resfont = love.graphics.newFont("res/Chalkduster.ttf", toScreenX(28))
	resbigfont = love.graphics.newFont("res/Chalkduster.ttf", toScreenX(72))
	resguard = love.graphics.newImage("res/mosh40.png")
	resfancyfancy = love.graphics.newImage("res/fancyfancy.png", { linear = true })
	resbackground = love.graphics.newImage("res/background.png")
	resthedarkside = love.graphics.newImage("res/thedarkside.png")
	resemo = love.graphics.newImage("res/emo.png")
	resptsd = love.graphics.newImage("res/angry40.png")
	resblygsvamp = love.graphics.newImage("res/long40.png")
	resghost = love.graphics.newImage("res/ghosty40.png")
	resking = love.graphics.newImage("res/KONUNGEN.png")
	resmodern = love.graphics.newImage("res/4thdimention.png")
	rescastle = love.graphics.newImage("res/castleinthesky.png")
	resdamm = love.graphics.newImage("res/damm.png")

	dammsystem = love.graphics.newParticleSystem(resdamm)
	dammsystem:setSizes(2, 2, 3)
	dammsystem:setColors({ 1.0, 1.0, 1.0, 0.3 }, { 1.0, 1.0, 1.0, 0.3 }, { 1.0, 1.0, 1.0, 0.0 })
	dammsystem:setRotation(0, 6)
	dammsystem:setSpread(0.3)
	dammsystem:setSpinVariation(0.3)
	dammsystem:setSpeed(50, 100)
	dammsystem:setParticleLifetime(0.1, 0.5)
	dammsystem:setEmissionRate(15)

	restart()
end

function love.keypressed(key)
	if key == "space" or key == "return" then
		input.interact = true
	end
end

function love.update(dt)
	dammsystem:update(dt)
	if scene == "menu" then
		if input.interact then
			scene = "game"
		end
	elseif scene == "game" then
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
		local closePortal = player:getCloseEntity(area.portals)
		if closePortal ~= nil and input.interact then
			local xdir = 0
			local ydir = 0
			if closePortal.x < 300 or 1600 < closePortal.x then
				xdir = (closePortal.x - love.graphics.getWidth() / 2)
					/ math.abs(closePortal.x - love.graphics.getWidth() / 2)
			else
				ydir = (closePortal.y - love.graphics.getHeight() / 2)
					/ math.abs(closePortal.y - love.graphics.getHeight() / 2)
			end
			transition = createTransition({ x = xdir, y = ydir }, function()
				area = areas[closePortal.next]
				player.x = closePortal.newX
				player.y = closePortal.newY
			end)
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

		if transition ~= nil then
			transition:update(dt)
		end

		input.interact = false
	end
	if isDown("r") then
		restart()
	end
	if isDown("q") or isDown("escape") then
		love.event.quit()
	end
end

function love.draw()
	if scene == "menu" then
		love.graphics.setFont(resbigfont)
		love.graphics.clear(0, 0.6, 0.3)
		love.graphics.setColor(1, 1, 1)
		love.graphics.printf("Roots Kingdom", 0, love.graphics.getHeight() / 4, love.graphics.getWidth(), "center")
		love.graphics.setFont(resfont)
		love.graphics.printf(
			"use space or enter to interact",
			0,
			love.graphics.getHeight() * 10 / 20,
			love.graphics.getWidth(),
			"center"
		)
		love.graphics.printf(
			"arrow keys to move around",
			0,
			love.graphics.getHeight() * 11 / 20,
			love.graphics.getWidth(),
			"center"
		)
		love.graphics.printf(
			"talk to the inhabitants of the world",
			0,
			love.graphics.getHeight() * 13 / 20,
			love.graphics.getWidth(),
			"center"
		)
		love.graphics.printf(
			"interact to begin",
			0,
			love.graphics.getHeight() * 15 / 20,
			love.graphics.getWidth(),
			"center"
		)
	elseif scene == "game" then
		area:draw()
		table.foreach(area.npcs, function(_, npc)
			npc:draw()
		end)
		love.graphics.draw(dammsystem)
		player:draw()
		if dialog ~= nil then
			dialog:draw()
		end
		if transition ~= nil then
			transition:draw()
		end
	end
end
