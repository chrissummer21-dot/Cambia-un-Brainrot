-- Ruta: src/ServerScriptService/NPCOfferServer.server.lua
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")

-- ===================================================
-- [¡CAMBIO!] Crear los Remotes PRIMERO
-- Esto evita el error "Infinite Yield" en el cliente,
-- incluso si la carga de 'Config' falla después.
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
    local body = HttpService:JSONEncode(payload)
    local ok, res = pcall(function()
        return HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson, false)
    end)
    if ok then
        print(">>> HTTP POST (NPC Offer) ÉXITO:", res)
        return true
    else
        warn(string.format(">>> HTTP POST (NPC Offer) falló: %s | Error: %s", url, tostring(res)))
        return false
    end
end

-- Función para formatear los ítems
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
	
	local itemsString = buildItemsString(itemsList)
	
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