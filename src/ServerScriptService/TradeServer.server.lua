-- ServerScriptService/TradeServer.server.lua
-- Autoridad de sesiones + sync + persistencia + disputas

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")


-- Remotos (asegurar carpeta)
-- =========================
local remotes = RS:FindFirstChild("TradeRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "TradeRemotes"
	remotes.Parent = RS
end

local function ensure(name: string): RemoteEvent
	local r = remotes:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = remotes
	end
	return r :: RemoteEvent
end

local REQ      = ensure("RequestTrade")     -- notificaciones (toast)
local RESP     = ensure("RespondTrade")     -- aceptar/rechazar INVITE
local SUBMIT   = ensure("SubmitProposal")   -- enviar propuesta (enteros)
local CONFIRM  = ensure("ConfirmSummary")   -- confirmar resumen
local CANCEL   = ensure("CancelTrade")      -- cancelar flujo
local SYNC     = ensure("SyncState")        -- sync UI autoritativo (server -> cliente)
local SUB_DISP = ensure("SubmitDispute")    -- enviar disputa (prueba/video/razón)

-- =========================
-- Shared + zona
-- =========================
local TradeShared = require(RS:WaitForChild("TradeShared"))
local Zone = workspace:FindFirstChild(TradeShared.ZONE_NAME)
if not Zone then
	warn("No existe Workspace." .. TradeShared.ZONE_NAME .. " — crea un Part con ese nombre (Anchored=true, CanTouch=true).")
end

-- =========================
-- Persistencia (TradeStorage)
-- =========================
-- Requiere:
--   ServerScriptService/Trade/TradeStorage.lua
--   ServerStorage/Trade/TradeConfig.lua
local TradeStorage = require(script.Parent:WaitForChild("Trade").TradeStorage)
local Storage = TradeStorage.new(TradeShared)

-- ===================================================
-- [¡CAMBIO!] Barrido al entrar DESACTIVADO
-- ===================================================
--[[
Players.PlayerAdded:Connect(function(plr)
	task.spawn(function()
		Storage:SweepUserPendings(plr.UserId)
	end)
end)
-- En Studio puede haber ya jugadores conectados
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		Storage:SweepUserPendings(p.UserId)
	end)
end
--]]
-- ===================================================


-- =========================
-- SessionManager (autoridad de estado)
-- =========================
-- Requiere:
--   ServerScriptService/Trade/SessionManager.lua
local SessionManager = require(script.Parent:WaitForChild("Trade").SessionManager)
local SM = SessionManager.new(Zone, TradeShared, Storage) -- << [ARREGLADO]
-- =========================
-- Utilidades
-- =========================
local function plrFromTouchedPart(hit: BasePart?)
	if not hit then return nil end
	local mdl = hit:FindFirstAncestorOfClass("Model")
	return mdl and Players:GetPlayerFromCharacter(mdl) or nil
end

local function notify(plr: Player, typ: string, msg: string)
	REQ:FireClient(plr, { kind = "notify", type = typ or "info", message = msg or "" })
end

-- =========================
-- Hooks de zona
-- =========================
if Zone then
	Zone.Touched:Connect(function(hit)
		local plr = plrFromTouchedPart(hit)
		if plr then SM:OnTouched(plr) end
	end)

	Zone.TouchEnded:Connect(function(hit)
		local plr = plrFromTouchedPart(hit)
		if plr then SM:OnTouchEnded(plr) end
	end)
end

Players.PlayerRemoving:Connect(function(plr)
	SM:OnLeaving(plr)
end)

-- =========================
-- Handlers de remotos
-- =========================

-- 1) INVITE (auto-match): aceptar / rechazar
RESP.OnServerEvent:Connect(function(plr, data)
	if type(data) ~= "table" then return end
	local otherId = tonumber(data.otherId or 0) or 0
	local other = Players:GetPlayerByUserId(otherId)
	if not other then return end

	local accept = data.accept == true
	SM:OnInviteResponse(plr, other, accept)
end)

-- 2) PROPOSAL: validación + entregar a SM
--    Nota: 'mps' representa "unidades enteras" en tu diseño actual.
SUBMIT.OnServerEvent:Connect(function(plr, data)
	if type(data) ~= "table" then return end
	local otherId = tonumber(data.otherId or 0) or 0
	local other = Players:GetPlayerByUserId(otherId)
	if not other then return end

	local itemsList = data.itemsList
	local totalValue = tonumber(data.totalValue or 0) or 0
	-- [¡NUEVO!] Leer la solicitud de intermediario
	local wantsIntermediary = data.wantsIntermediary == true

	local ok, msg = TradeShared.validateProposal(itemsList, totalValue)
	if not ok then
		notify(plr, "error", msg)
		return
	end

	-- [¡NUEVO!] Pasar el dato al SessionManager
	SM:OnProposal(plr, other, itemsList, totalValue, wantsIntermediary)
end)

-- 3) SUMMARY: confirmar / cancelar
CONFIRM.OnServerEvent:Connect(function(plr, data)
	if type(data) ~= "table" then return end
	local otherId = tonumber(data.otherId or 0) or 0
	local other = Players:GetPlayerByUserId(otherId)
	if not other then return end

	local accept = data.accept == true
	SM:OnSummaryConfirm(plr, other, accept)
end)

-- 4) CANCEL manual
CANCEL.OnServerEvent:Connect(function(plr, otherId)
	local other = Players:GetPlayerByUserId(tonumber(otherId or 0) or 0)
	if not other then return end
	for _, s in pairs(SM.sessions) do
		if (s.a == plr and s.b == other) or (s.b == plr and s.a == other) then
			SM:CancelSession(s, "Cancelado por un jugador.")
			return
		end
	end
end)

-- 5) DISPUTA (ticket con video/prueba/razón)
SUB_DISP.OnServerEvent:Connect(function(plr, data)
	if type(data) ~= "table" then return end
	local proofCode = tostring(data.proofCode or "")
	local videoUrl  = tostring(data.videoUrl or "")
	local reason    = tostring(data.reason or "")

	if proofCode == "" then
		return notify(plr, "error", "Falta proofCode.")
	end

	local ok = Storage:MarkDisputed(proofCode, plr.UserId, videoUrl, reason)
	if ok then
		notify(plr, "info", "Disputa enviada. Gracias.")
	else
		notify(plr, "error", "No se pudo registrar la disputa.")
	end
end)

-- =========================
-- Notas de integración de persistencia
-- =========================
-- Para registrar PROMISED en DataStore y espejos (Sheets/Discord),
-- el momento correcto es cuando ambos confirman el resumen.
-- Si ya integraste la llamada dentro del SessionManager (recomendado):
--   self.Storage:CreatePromised(s.a, s.proposals[s.a], s.b, s.proposals[s.b])
-- entonces no necesitas nada extra aquí.
--
-- Alternativa rápida (si NO editaste SessionManager):
-- Puedes añadir un "callback" simple expuesto por SM cuando pase a PROMISED
-- o mover la llamada de CreatePromised al punto donde tu SM hace _syncPromised.
--
-- El barrido de 48h se ejecuta cada que un jugador entra al juego (ver arriba).