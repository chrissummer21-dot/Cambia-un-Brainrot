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
	if type(units) ~= "number" then return false, "Ingresa un número entero." end
	if units ~= math.floor(units) then return false, "Usa solo enteros (sin decimales)." end
	if units < TradeShared.MIN_UNITS then
		return false, ("Mínimo %d unidad(es)."):format(TradeShared.MIN_UNITS)
	end

	return true
end

return TradeShared
