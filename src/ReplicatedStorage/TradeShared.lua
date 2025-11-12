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
function TradeShared.validateProposal(itemsText, units)
	itemsText = TradeShared.sanitizeText(itemsText)
	if itemsText == "" or #itemsText < 3 then
		return false, "Describe los brainrots a intercambiar (sin links)."
	end

	-- Debe ser entero >= MIN_UNITS
	if type(units) ~= "number" then return false, "Ingresa un número válido." end
	
	-- Eliminamos la validación de math.floor para permitir decimales

	-- El cliente ya valida que el total sea > 0
	-- El servidor debe confirmar esto.
	if units <= 0 then 
		return false, "El valor total debe ser mayor a 0."
	end

	return true
end

return TradeShared
