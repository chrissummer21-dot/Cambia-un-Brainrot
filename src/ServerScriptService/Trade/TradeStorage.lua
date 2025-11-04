-- ServerScriptService/Trade/TradeStorage.lua
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ServerStorage:WaitForChild("Trade"):WaitForChild("TradeConfig"))

local TradeStorage = {}
TradeStorage.__index = TradeStorage

-- DataStores
local DS_TRADES   = DataStoreService:GetDataStore("Trades_v1")        -- key = proofCode
local DS_BYUSER   = DataStoreService:GetDataStore("UserTrades_v1")    -- key = "U:<userId>" -> {proofCodes}
local DS_POINTS   = DataStoreService:GetDataStore("UserPoints_v1")    -- key = "U:<userId>" -> {trades=0, strikes=0}

-- Helpers
local function now() return os.time() end
local function genCode()
	-- corto y único: YYYYMMDDhhmmss + 4 hex
	local stamp = os.date("!%Y%m%d%H%M%S", now())
	local rand = string.format("%04x", math.random(0, 0xFFFF))
	return ("P%s-%s"):format(stamp, rand)
end

local function safeUpdate(ds, key, transform)
	for i = 1, 6 do
		local ok, res = pcall(function()
			return ds:UpdateAsync(key, function(old)
				local new = transform(old or nil)
				return new
			end)
		end)
		if ok then return res end
		task.wait(0.25 * i)
	end
	return nil
end

local function httpPost(url, payload)
    if not url or url == "" then return true end
    local body = HttpService:JSONEncode(payload)
    for i = 1, Config.HTTP_MAX_RETRIES do
        local ok, res = pcall(function()
            return HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson, false)
        end)
        if ok then return true end
        warn(string.format(">>> HTTP POST falló (Intento %d/%d) para: %s | Error: %s", i, Config.HTTP_MAX_RETRIES, url, tostring(res)))
        warn(("POST fail (%d/%d) to %s"):format(i, Config.HTTP_MAX_RETRIES, url))
        task.wait(0.5 * i)
    end
    return false
end

-- Clase
function TradeStorage.new(shared)
	local self = setmetatable({}, TradeStorage)
	self.Shared = shared
	return self
end

-- Registrar PROMISED (compromiso), devuelve record con proofCode
function TradeStorage:CreatePromised(aPlr, aProp, bPlr, bProp)
	local createdAt = now()
	local expiresAt = createdAt + 48*3600
	local record = {
		proofCode = genCode(),
		state = "PROMISED",               -- PROMISED | SUCCESS | DISPUTED | CANCELED
		createdAt = createdAt,
		expiresAt = expiresAt,

		aUserId = aPlr.UserId,
		aName   = string.format("%s (@%s)", aPlr.DisplayName, aPlr.Name),
		aItems  = aProp.items, aUnits = aProp.mps,

		bUserId = bPlr.UserId,
		bName   = string.format("%s (@%s)", bPlr.DisplayName, bPlr.Name),
		bItems  = bProp.items, bUnits = bProp.mps,
	}

	-- Guarda por proofCode
	local ok = safeUpdate(DS_TRADES, record.proofCode, function() return record end)
	if not ok then return nil, "No se pudo guardar trade" end

	-- Index por usuario (para auditorías/finalización al reconectar)
	local function addToUser(uId)
		local key = "U:"..uId
		safeUpdate(DS_BYUSER, key, function(old)
			old = old or {}
			table.insert(old, record.proofCode)
			if #old > 50 then
				-- corta histórico largo (opcional)
				table.remove(old, 1)
			end
			return old
		end)
	end
	addToUser(aPlr.UserId); addToUser(bPlr.UserId)

	-- Espejo HTTP (Sheets o Discord)
	httpPost(Config.SHEETS_WEBAPP_URL, record)
	httpPost(Config.DISCORD_WEBHOOK_URL, {
		username = "TradeBot",
		embeds = {{
			title = "Nuevo trade PROMISED",
			description = ("**%s** ↔ **%s**\nItems A: %s\nItems B: %s\nUnits A: %d | Units B: %d\nProof: `%s`\nCierra en: <t:%d:R>"):
				format(record.aName, record.bName, record.aItems, record.bItems, record.aUnits, record.bUnits, record.proofCode, record.expiresAt),
			color = 0x55cc88
		}}
	})

	return record
end

-- Marcar DISPUTED con evidencia
function TradeStorage:MarkDisputed(proofCode, whoUserId, videoUrl, reason)
	local updated = safeUpdate(DS_TRADES, proofCode, function(old)
		if not old then return nil end
		if old.state == "SUCCESS" or old.state == "CANCELED" then return old end
		old.state = "DISPUTED"
		old.dispute = {
			by = whoUserId,
			video = tostring(videoUrl or ""),
			reason = tostring(reason or ""),
			at = now(),
		}
		return old
	end)
	if not updated then return false end

	httpPost(Config.DISCORD_WEBHOOK_URL, {
		username = "TradeBot",
		embeds = {{
			title = "Trade DISPUTED",
			description = ("Proof `%s`\nBy UserId: %d\nVideo: %s\nReason: %s"):
				format(proofCode, whoUserId, tostring(videoUrl or ""), tostring(reason or "")),
			color = 0xcc5555
		}}
	})

	return true
end

-- Intentar autocerrar a SUCCESS si pasaron 48h y no hay disputa
function TradeStorage:TryAutoClose(proofCode)
	return safeUpdate(DS_TRADES, proofCode, function(old)
		if not old then return nil end
		if old.state ~= "PROMISED" then return old end
		if now() >= (old.expiresAt or 0) then
			old.state = "SUCCESS"
			-- sumar puntos a ambos
			local function addPoint(uId)
				local key = "U:"..uId
				safeUpdate(DS_POINTS, key, function(p)
					p = p or { trades = 0, strikes = 0 }
					p.trades += 1
					return p
				end)
			end
			addPoint(old.aUserId); addPoint(old.bUserId)

			httpPost(Config.DISCORD_WEBHOOK_URL, {
				username = "TradeBot",
				content = ("✅ Trade SUCCESS `%s` (cerrado automáticamente)").format(old.proofCode)
			})
		end
		return old
	end) ~= nil
end

-- Al conectar un usuario, revisa sus trades pendientes y autocierra si toca
function TradeStorage:SweepUserPendings(userId)
	local list = DS_BYUSER:GetAsync("U:"..userId) or {}
	for _, code in ipairs(list) do
		local rec = DS_TRADES:GetAsync(code)
		if rec and rec.state == "PROMISED" and now() >= (rec.expiresAt or 0) then
			self:TryAutoClose(code)
		end
	end
end

return TradeStorage
