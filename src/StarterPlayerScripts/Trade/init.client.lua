-- init.client.lua (cliente orquestador + SyncState autoritativo)
-- Ruta: StarterPlayerScripts/Trade/init.client.lua

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Módulos locales
local RemotesMod     = require(script.Parent.Remotes)
local Components     = require(script.Parent.Components)
local ToastClass     = require(script.Parent.Toast)

local InviteScreen   = require(script.Parent.Screens.Invite)
local ProposalScreen = require(script.Parent.Screens.Proposal)
local SummaryScreen  = require(script.Parent.Screens.Summary)
local InstrScreen    = require(script.Parent.Screens.Instructions)

-- ===== Remotos =====
local R = RemotesMod.Get()
local REQ, RESP, SUBMIT, CONFIRM, CANCEL, SYNC =
	R.REQ, R.RESP, R.SUBMIT, R.CONFIRM, R.CANCEL, R.SYNC

-- ===== UI raíz + pantallas =====
local gui    = Components.MakeScreenGui()
local Toast  = ToastClass.new(gui)

local Invite   = InviteScreen.new(gui)
local Proposal = ProposalScreen.new(gui)
local Summary  = SummaryScreen.new(gui)
local Instr    = InstrScreen.new(gui)

-- ===== Estado local =====
local currentOtherId = nil
local inviteActive   = false

-- ===== Clicks =====
Invite.okBtn.MouseButton1Click:Connect(function()
	if Invite.otherId then
		RESP:FireServer({ accept = true, otherId = Invite.otherId })
		inviteActive = false
		Invite:Hide()
	end
end)

Invite.noBtn.MouseButton1Click:Connect(function()
	if Invite.otherId then
		RESP:FireServer({ accept = false, otherId = Invite.otherId })
		inviteActive = false
		Invite:Hide()
	end
end)

Proposal.sendBtn.MouseButton1Click:Connect(function()
	if not Proposal.otherId then return end
	local n = tonumber(Proposal.mps.Text or "0") or 0
	SUBMIT:FireServer({
		otherId = Proposal.otherId,
		items   = Proposal.items.Text or "",
		mps     = n
	})
end)

Proposal.cancelBtn.MouseButton1Click:Connect(function()
	if Proposal.otherId then
		CANCEL:FireServer(Proposal.otherId)
		Proposal:Close()
	end
end)

Summary.acceptBtn.MouseButton1Click:Connect(function()
	if Summary.otherId then
		CONFIRM:FireServer({ otherId = Summary.otherId, accept = true })
	end
end)

Summary.backBtn.MouseButton1Click:Connect(function()
	if Summary.otherId then
		CANCEL:FireServer(Summary.otherId)
		Summary:Close()
	end
end)

Instr.okBtn.MouseButton1Click:Connect(function()
	Instr:Close()
end)

-- ===== Notificaciones simples =====
REQ.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	if payload.kind == "notify" then
		local t = (payload.type or "info"):upper()
		Toast:Show(("["..t.."] "..(payload.message or "")), 1.4)
	end
end)

-- ===== Eventos “legacy” (por compatibilidad si el server los emite) =====
RESP.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	if payload.kind == "invite" then
		currentOtherId = payload.otherId
		Invite:Show(payload.otherId, payload.otherName or "Jugador")
		inviteActive = true
	elseif payload.kind == "peerAccepted" then
		Toast:Show("El otro jugador aceptó. Falta tu confirmación…", 1.4)
	end
end)

SUBMIT.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	if payload.kind == "openProposal" then
		currentOtherId = payload.otherId
		inviteActive = false
		Invite:Hide()
		Proposal:Open(payload.otherId, payload.otherName or "Jugador")
	end
end)

CONFIRM.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	if payload.kind == "openSummary" then
		Proposal:Close()
		Summary:Open(
			currentOtherId,
			payload.a.mps, payload.a.items,
			payload.b.mps, payload.b.items,
			payload.warning
		)
	elseif payload.kind == "peerConfirmed" then
		Toast:Show("El otro jugador confirmó el resumen.", 1.4)
	elseif payload.kind == "promised" then
		Summary:Close()
		Instr:Open()
	end
end)

-- ===== Sync autoritativo del servidor =====
-- El servidor envía { state = "INVITE"/"PROPOSAL"/"SUMMARY"/"PROMISED"/"CANCELED", ... }
SYNC.OnClientEvent:Connect(function(payload)
	if not payload or type(payload) ~= "table" then return end
	local state = payload.state

	if state == "INVITE" then
		-- Siempre reabrimos/actualizamos el modal durante INVITE
		currentOtherId = payload.partnerId
		Invite:Show(payload.partnerId, payload.partnerName or "Jugador")
		-- (Opcional) mostrar estados dentro del modal:
		-- Invite.msg.Text = ("¿Quieres tradear con <b>%s</b>?\nTú: %s  |  Otro: %s")
		--   :format(payload.partnerName or "Jugador",
		--           payload.youAccepted and "ACEPTADO" or "PENDIENTE",
		--           payload.partnerAccepted and "ACEPTADO" or "PENDIENTE")

	elseif state == "PROPOSAL" then
		inviteActive = false
		Invite:Hide()
		-- Usa el nombre del otro (el server envía partnerA/partnerB si quieres)
		Proposal:Open(currentOtherId, payload.partnerB or payload.partnerA or "Jugador")

	elseif state == "SUMMARY" then
		Proposal:Close()
		Summary:Open(
			currentOtherId,
			payload.a.mps, payload.a.items,
			payload.b.mps, payload.b.items,
			payload.warning
		)

	elseif state == "PROMISED" then
		Summary:Close()
		Instr:Open()

	elseif state == "CANCELED" then
		Invite:Hide(); Proposal:Close(); Summary:Close()
		if payload.reason then
			Toast:Show(payload.reason, 1.6)
		end
	end
end)
