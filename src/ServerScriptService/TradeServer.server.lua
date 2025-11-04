-- TradeServer.server.lua (autoridad + sync vía SessionManager)
-- Colocar en: ServerScriptService/TradeServer.server.lua

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

-- ==== Remotos: asegura carpeta y RemoteEvents ====
local remotes = RS:FindFirstChild("TradeRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "TradeRemotes"
	remotes.Parent = RS
end

local function ensure(name)
	local r = remotes:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = remotes
	end
	return r
end

local REQ     = ensure("RequestTrade")   -- Para notificaciones simples al cliente (toast)
local RESP    = ensure("RespondTrade")   -- Aceptar / Rechazar invitación (auto-match)
local SUBMIT  = ensure("SubmitProposal") -- Enviar propuesta
local CONFIRM = ensure("ConfirmSummary") -- Confirmar resumen
local CANCEL  = ensure("CancelTrade")    -- Cancelar flujo
local SYNC    = ensure("SyncState")      -- << NUEVO: Sync autoritativo de UI

-- ==== Shared y zona ====
local TradeShared = require(RS:WaitForChild("TradeShared"))
local Zone = workspace:FindFirstChild(TradeShared.ZONE_NAME)
if not Zone then
	warn("No existe Workspace." .. TradeShared.ZONE_NAME .. " — crea un Part con ese nombre (Anchored=true, CanTouch=true).")
end

-- ==== SessionManager (autoridad de estado) ====
-- Estructura esperada:
--   ServerScriptService/
--     TradeServer.server.lua
--     Trade/
--       SessionManager.lua
local SessionManager = require(script.Parent:WaitForChild("Trade").SessionManager)
local SM = SessionManager.new(Zone, TradeShared)

-- ==== Helpers ====
local function playerFromTouchedPart(hit)
	local model = hit and hit:FindFirstAncestorOfClass("Model")
	return model and Players:GetPlayerFromCharacter(model) or nil
end

-- ==== Hooks de zona ====
if Zone then
	Zone.Touched:Connect(function(hit)
		local plr = playerFromTouchedPart(hit)
		if plr then SM:OnTouched(plr) end
	end)

	Zone.TouchEnded:Connect(function(hit)
		local plr = playerFromTouchedPart(hit)
		if plr then SM:OnTouchEnded(plr) end
	end)
end

-- Limpieza al salir
Players.PlayerRemoving:Connect(function(plr)
	SM:OnLeaving(plr)
end)

-- ==== Handlers de remotos (delegan en SM) ====

-- 1) INVITE (auto-match): aceptar / rechazar
RESP.OnServerEvent:Connect(function(plr, data)
	if type(data) ~= "table" then return end
	local otherId = tonumber(data.otherId or 0) or 0
	local other = Players:GetPlayerByUserId(otherId)
	if not other then return end

	local accept = data.accept == true
	SM:OnInviteResponse(plr, other, accept)
end)

-- 2) PROPOSAL: validar y entregar a SM
SUBMIT.OnServerEvent:Connect(function(plr, data)
	if type(data) ~= "table" then return end
	local otherId = tonumber(data.otherId or 0) or 0
	local other = Players:GetPlayerByUserId(otherId)
	if not other then return end

	local items = tostring(data.items or "")
	local mps = tonumber(data.mps or 0) or 0

	-- Validaciones compartidas
	local ok, msg = TradeShared.validateProposal(items, mps)
	if not ok then
		REQ:FireClient(plr, { kind = "notify", type = "error", message = msg })
		return
	end

	items = TradeShared.sanitizeText(items)
	SM:OnProposal(plr, other, items, mps)
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

-- 4) CANCEL manual (si agregas botón de cancelar en cliente)
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

-- (Opcional) Helper para mandar notificaciones rápidas
local function notify(plr, typ, msg)
	REQ:FireClient(plr, { kind = "notify", type = typ or "info", message = msg or "" })
end

-- Listo: El SessionManager hará SYNC continuo con cada cambio de estado:
-- INVITE  -> PROPOSAL -> SUMMARY -> PROMISED
-- y forzará la UI correcta en ambos clientes.
