-- ServerScriptService/Trade/TradeStorage.lua
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ServerStorage:WaitForChild("Trade"):WaitForChild("TradeConfig"))

local TradeStorage = {}
TradeStorage.__index = TradeStorage

-- ===================================================
-- [¡NUEVO!] Definición de las nuevas bases de datos
-- ===================================================
local DS_TRADES   = DataStoreService:GetDataStore("Trades_v2")        -- Tabla 1 (Maestra)
local DS_ITEMS    = DataStoreService:GetDataStore("TradeItems_v2")    -- Tabla 2 (Detalle)
-- ===================================================
local DS_BYUSER   = DataStoreService:GetDataStore("UserTrades_v1")    -- (Se mantiene para auditoría)
local DS_POINTS   = DataStoreService:GetDataStore("UserPoints_v1")    -- (Se mantiene)

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

-- (Función httpPost se mantiene igual que antes)
local function httpPost(url, payload)
    if not url or url == "" then return true end
    local body = HttpService:JSONEncode(payload)
    local ok, res = pcall(function()
        return HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson, false)
    end)
    if ok then
        print(">>> HTTP POST ÉXITO (Intento 1/1). Respuesta:", res)
        return true
    else
        warn(string.format(">>> HTTP POST falló (Intento 1/1) para: %s | Error: %s", url, tostring(res)))
        return false
    end
end


-- Clase
function TradeStorage.new(shared)
	local self = setmetatable({}, TradeStorage)
	self.Shared = shared
	return self
end

-- ===================================================
-- [¡REDISIEÑO!] CreatePromised
-- Esta función ahora guarda en AMBAS tablas (Trades y Items)
-- ===================================================
function TradeStorage:CreatePromised(aPlr, aProp, bPlr, bProp)
	local createdAt = now()
	local expiresAt = createdAt + 48*3600
	local proofCode = genCode()
	
	-- Helper para construir el string de "BrainrotsCambiados"
	local function buildItemsString(itemsList)
		local strList = {}
		for _, item in ipairs(itemsList) do
			table.insert(strList, string.format("%s (%.1f %s)", item.name, item.value, item.unit))
		end
		return table.concat(strList, ", ")
	end
	
	-- 1. Construir el registro de la Tabla 1 (DS_TRADES)
	local tradeRecord = {
		proofCode = proofCode,
		state = "PROMISED",
		timestamp = createdAt,
		expiresAt = expiresAt,
		
		aUserId = aPlr.UserId,
		aUsername = aPlr.Name,
		
		bUserId = bPlr.UserId,
		bUsername = bPlr.Name,
		
		aBrainrotsChanged = buildItemsString(aProp.itemsList),
		bBrainrotsChanged = buildItemsString(bProp.itemsList),

		-- [¡NUEVO!] Guardar el estado del intermediario
		-- Si CUALQUIERA de los dos lo pide, el trade es con intermediario
		isIntermediary = aProp.wantsIntermediary or bProp.wantsIntermediary,
		aWantsIntermediary = aProp.wantsIntermediary or false,
		bWantsIntermediary = bProp.wantsIntermediary or false,
		
		-- (Campos 'intermediaryId' y 'intermediaryUsername' se mantienen nil por ahora)
		intermediaryId = nil,
		intermediaryUsername = nil,
		
		dataHash = HttpService:GenerateGUID(false)
	}

	-- 2. Construir la lista de ítems para la Tabla 2 (DS_ITEMS)
	local itemsRecord = {}
	
	-- Añadir ítems de A
	for _, item in ipairs(aProp.itemsList) do
		table.insert(itemsRecord, {
			proofCode = proofCode,
			ownerUserId = aPlr.UserId,
			itemName = item.name,
			rarity = item.rarity,
			value = item.value,
			multiplier = item.unit,
		})
	end
	
	-- Añadir ítems de B
	for _, item in ipairs(bProp.itemsList) do
		table.insert(itemsRecord, {
			proofCode = proofCode,
			ownerUserId = bPlr.UserId,
			itemName = item.name,
			rarity = item.rarity,
			value = item.value,
			multiplier = item.unit,
		})
	end

	-- 3. Guardar en DataStores
	local ok_trades = safeUpdate(DS_TRADES, proofCode, function() return tradeRecord end)
	local ok_items = safeUpdate(DS_ITEMS, proofCode, function() return itemsRecord end)

	if not ok_trades or not ok_items then
		-- Si falla, intentar revertir (básico)
		if ok_trades then pcall(DS_TRADES.RemoveAsync, DS_TRADES, proofCode) end
		if ok_items then pcall(DS_ITEMS.RemoveAsync, DS_ITEMS, proofCode) end
		return nil, "No se pudo guardar el trade (error de BD)"
	end

	-- 4. Indexar por usuario (se mantiene)
	local function addToUser(uId)
		local key = "U:"..uId
		safeUpdate(DS_BYUSER, key, function(old)
			old = old or {}; table.insert(old, proofCode)
			if #old > 50 then table.remove(old, 1) end
			return old
		end)
	end
	addToUser(aPlr.UserId); addToUser(bPlr.UserId)

	-- 5. Espejo HTTP (Sheets o Discord) - (se mantiene)
	-- Enviamos el registro maestro
	local sheetsPayload = {
		tradeRecord = tradeRecord, -- Tu "Tabla 1" (Datos del Trade)
		itemsRecord = itemsRecord  -- Tu "Tabla 2" (Lista de Items)
	}
	
	-- Enviar el payload combinado a Sheets
	httpPost(Config.SHEETS_WEBAPP_URL, sheetsPayload) 
	
	-- El payload de Discord se mantiene simple (sin cambios)
	httpPost(Config.DISCORD_WEBHOOK_URL, {
		username = "TradeBot (v2)",
		embeds = {{
			title = "Nuevo trade PROMISED",
			description = ("**%s** ↔ **%s**\nItems A: %s\nItems B: %s\nProof: `%s`\nCierra en: <t:%d:R>"):
				format(tradeRecord.aUsername, tradeRecord.bUsername, tradeRecord.aBrainrotsChanged, tradeRecord.bBrainrotsChanged, proofCode, expiresAt),
			color = 0x55cc88
		}}
	})

	return tradeRecord -- Devuelve el registro maestro
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
		username = "TradeBot (v2)",
		embeds = {{
			title = "Trade DISPUTED",
			description = ("Proof `%s`\nBy UserId: %d\nVideo: %s\nReason: %s"):
				format(proofCode, whoUserId, tostring(videoUrl or ""), tostring(reason or "")),
			color = 0xcc5555
		}}
	})

	return true
end

-- ===================================================
-- FUNCIÓN TryAutoClose (¡ARREGLADA!)
-- (Ahora solo actualiza DS_TRADES)
-- ===================================================
function TradeStorage:TryAutoClose(proofCode)
	
	local didChange = false
	
	-- Paso 1: Actualizar el DataStore de Trades
	local updatedRecord = safeUpdate(DS_TRADES, proofCode, function(old)
		if not old then return nil end
		if old.state == "PROMISED" and now() >= (old.expiresAt or 0) then
			old.state = "SUCCESS"
			didChange = true
		end
		return old
	end)

	-- Paso 2: Si cambió, ejecutar acciones externas
	if didChange and updatedRecord then
		
		-- Acción 1: Sumar puntos
		local function addPoint(uId)
			local key = "U:"..uId
			safeUpdate(DS_POINTS, key, function(p)
				p = p or { trades = 0, strikes = 0 }
				p.trades += 1
				return p
			end)
		end
		addPoint(updatedRecord.aUserId)
		addPoint(updatedRecord.bUserId)

		-- Acción 2: Enviar a Discord
		httpPost(Config.DISCORD_WEBHOOK_URL, {
			username = "TradeBot (v2)",
			content = ("✅ Trade SUCCESS `%s` (cerrado automáticamente)").format(updatedRecord.proofCode)
		})
		
		return true
	end

	return false
end
-- ===================================================

-- Al conectar un usuario, revisa sus trades pendientes y autocierra si toca
function TradeStorage:SweepUserPendings(userId)
	local list = DS_BYUSER:GetAsync("U:"..userId) or {}
	for _, code in ipairs(list) do
		-- Solo necesita leer la tabla maestra
		local rec = DS_TRADES:GetAsync(code) 
		if rec and rec.state == "PROMISED" and now() >= (rec.expiresAt or 0) then
			task.spawn(function()
				self:TryAutoClose(code)
			end)
		end
	end
end

return TradeStorage