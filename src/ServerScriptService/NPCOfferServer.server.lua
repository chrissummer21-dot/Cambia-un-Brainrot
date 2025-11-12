-- Ruta: src/ServerScriptService/NPCOfferServer.server.lua
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")

-- ===================================================
-- [¡CAMBIO!] Crear los Remotes PRIMERO
-- ===================================================
local remotes = RS:FindFirstChild("NPCOfferRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "NPCOfferRemotes"
	remotes.Parent = RS
end
local SUBMIT_OFFER = Instance.new("RemoteEvent")
SUBMIT_OFFER.Name = "SubmitNPCOffer"
SUBMIT_OFFER.Parent = remotes

-- ===================================================
-- Ahora, cargar la configuración
-- ===================================================
local Config = require(ServerStorage:WaitForChild("Trade"):WaitForChild("TradeConfig"))

-- Helper para HTTP Post
local function httpPost(url, payload)
    if not url or url == "" then return true end
    
    -- [¡NUEVO!] Verificar que la URL no sea nil antes de codificar
    local body
    pcall(function()
        body = HttpService:JSONEncode(payload)
    end)
    
    if not body then
        warn(">>> HTTP POST (NPC Offer) falló: Payload no se pudo codificar a JSON.")
        return false
    end
    
    local ok, res = pcall(function()
        return HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson, false)
    end)
    if ok then
        print(">>> HTTP POST (NPC Offer) ÉXITO:", res)
        return true
    else
        warn(string.format(">>> HTTP POST (NPC Offer) falló para: %s | Error: %s", url, tostring(res)))
        return false
    end
end

-- Función para formatear los ítems (para Discord)
local function buildItemsString(itemsList)
	local strList = {}
	for _, item in ipairs(itemsList) do
		-- Formato: Nombre (Valor Multiplicador, Rareza)
		local valueString
		if item.value == math.floor(item.value) then
			valueString = tostring(item.value)
		else
			valueString = string.format("%.1f", item.value)
		end
		table.insert(strList, string.format("%s (%s %s, %s)", item.name, valueString, item.unit, item.rarity))
	end
	return table.concat(strList, "\n")
end

-- El listener
SUBMIT_OFFER.OnServerEvent:Connect(function(player, itemsList)
	if type(itemsList) ~= "table" or #itemsList == 0 then
		return 
	end
	
	-- 1. Preparar datos para Discord (como estaba antes)
	local itemsString = buildItemsString(itemsList)
	
	-- 2. [¡NUEVO!] Preparar datos para Google Sheets (una fila por item)
	-- Creamos un payload que Google Apps Script pueda iterar fácilmente.
	local sheetsPayload = {
		action = "addNpcOfferRows", -- Un identificador para tu script de Google
		rows = {} -- Una lista de todas las filas a añadir
	}
	
	local username = player.Name
	local userId = player.UserId
	local displayName = player.DisplayName
	
	for _, item in ipairs(itemsList) do
		-- Convertir el valor a string para el sheet
		local valueString
		if item.value == math.floor(item.value) then
			valueString = tostring(item.value)
		else
			valueString = string.format("%.1f", item.value)
		end
		
		-- Crear el objeto de fila con los datos exactos que pediste
		local rowData = {
			Username = username,
			IdJugador = userId,
			DisplayName = displayName,
			Brainrot = item.name,
			Dinero = valueString,  -- "Dinero que da"
			Multiplo = item.unit,
			Rareza = item.rarity or "N/A" -- (Dato extra que es útil)
		}
		
		-- Añadir esta fila a la lista
		table.insert(sheetsPayload.rows, rowData)
	end
	
	-- 3. [¡NUEVO!] Enviar al Webhook de Google Sheets para ofertas NPC
    -- Esto usa la nueva URL que definiste en TradeConfig.lua
    if Config.NPC_OFFER_SHEETS_URL then
	    httpPost(Config.NPC_OFFER_SHEETS_URL, sheetsPayload)
    else
        warn("NPC_OFFER_SHEETS_URL no está definida en TradeConfig.lua. No se enviará a Google Sheets.")
    end

	-- 4. Enviar a Discord (como estaba antes)
	httpPost(Config.DISCORD_WEBHOOK_URL, {
		username = "Bot de Ofertas (NPC)",
		embeds = {{
			title = "Nueva Oferta para Fundadores",
			color = 0x00BFFF, 
			fields = {
				{
					name = "Jugador",
					value = string.format("%s (`%d`)", player.Name, player.UserId),
					inline = false
				},
				{
					name = "Brainrots Ofrecidos",
					value = itemsString,
					inline = false
				}
			},
			footer = {
				text = "Oferta enviada: " .. os.date("!%Y-%m-%d %H:%M:%S UTC")
			}
		}}
	})
end)