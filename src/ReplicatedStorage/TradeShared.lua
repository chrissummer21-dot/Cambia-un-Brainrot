local TradeShared = {}

TradeShared.MIN_MPS = 1_000_000
TradeShared.COOLDOWN_SEC = 8
TradeShared.MAX_PROMPT_LEN = 120
TradeShared.ZONE_NAME = "TradeZone"

local banned = {"http", "www", "discord.gg", "nitro"}
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

function TradeShared.validateProposal(itemsText, mps)
    itemsText = TradeShared.sanitizeText(itemsText)
    if itemsText == "" or #itemsText < 3 then
        return false, "Describe los brainrots a intercambiar (sin links)."
    end
    if type(mps) ~= "number" or mps < TradeShared.MIN_MPS then
        return false, ("Mínimo %d millones/seg."):format(TradeShared.MIN_MPS)
    end
    return true
end

return TradeShared
