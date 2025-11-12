local TradeShared = {}

-- Ahora trabajamos con ENTEROS (unidades), no millones reales
TradeShared.MIN_UNITS = 1
TradeShared.COOLDOWN_SEC = 8
TradeShared.MAX_PROMPT_LEN = 120
TradeShared.ZONE_NAME = "TradeZone"

local banned = { "http", "www", "discord.gg", "nitro" }

function TradeShared.sanitizeText(s)
	if type(s) ~= "string" then return "" end
	s = s:gsub("%s+", " "):sub(1, TradeShared.MAX_PROMPT_LEN)
	local lower = s:lower()
	for _, w in ipairs(banned) do
		if lower:find(w, 1, true) then
			return ""
		end
	end
	return s
end

-- mps ahora representa “unidades enteras”
-- NUEVO CÓDIGO (DESPUÉS) --
function TradeShared.validateProposal(itemsList, totalValue)
	-- Validamos la tabla de ítems
	if type(itemsList) ~= "table" or #itemsList == 0 then
		return false, "Debes ofrecer al menos un ítem."
	end
	
	-- (Opcional) Validación más profunda de la lista
	for _, item in ipairs(itemsList) do
		if type(item) ~= "table" or not item.name or not item.rarity or not item.value then
			return false, "Datos de la propuesta corruptos."
		end
	end

	-- Validamos el valor total
	if type(totalValue) ~= "number" then return false, "Ingresa un número válido." end
	
	if totalValue <= 0 then 
		return false, "El valor total debe ser mayor a 0."
	end

	return true
end

return TradeShared
