-- init.client.lua (cliente orquestador + SyncState autoritativo)
-- Ruta: StarterPlayerScripts/Trade/init.client.lua

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Módulos locales
local RemotesMod     = require(script.Remotes)
local Components     = require(script.Components)
local ToastClass     = require(script.Toast)

local InviteScreen   = require(script.Screens.Invite)
local ProposalScreen = require(script.Screens.Proposal)
local SummaryScreen  = require(script.Screens.Summary)
local InstrScreen    = require(script.Screens.Instructions)
local LoadingScreen  = require(script.Screens.Loading)

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
local Loading  = LoadingScreen.new(gui)

-- ===== Estado local =====
local currentOtherId = nil
local inviteActive   = false

-- ===== Clicks =====
Invite.okBtn.MouseButton1Click:Connect(function()
	if Invite.otherId then
		RESP:FireServer({ accept = true, otherId = Invite.otherId })
		Invite:LockWaiting()
		Invite:SetStatuses(true, false)
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
	-- Leer como ENTERO (sin multiplicar)
	local units = tonumber(Proposal.mps.Text or "0") or 0
	units = math.max(0, math.floor(units))

	SUBMIT:FireServer({
		otherId = Proposal.otherId,
		items   = Proposal.items.Text or "",
		mps     = units
	})

	-- Cambiar interfaz a "Propuesta enviada..."
	Proposal:SetWaiting()
end)

Proposal.cancelBtn.MouseButton1Click:Connect(function()
	if Proposal.otherId then
		CANCEL:FireServer(Proposal.otherId)
		Proposal:Close()
	end
end)

-- ===================================================
-- Click de Aceptar Resumen MODIFICADO (¡ARREGLADO!)
-- ===================================================
Summary.acceptBtn.MouseButton1Click:Connect(function()
	-- Lee el otherId ANTES de que cualquier función lo borre
	local otherId = Summary.otherId 
	
	if otherId then
		-- 1. Deshabilita el botón localmente para evitar doble clic
		Summary:LockWaiting()
		
		-- 2. Ya NO cerramos el resumen ni mostramos la carga aquí.
		--    El servidor nos dirá cuándo hacerlo (con SYNC).

		-- 3. Envía la confirmación al servidor con el ID guardado
		CONFIRM:FireServer({ otherId = otherId, accept = true })
	end
end)
-- ===================================================

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
-- (Se mantienen por si acaso, pero el flujo principal usa SYNC)
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
		-- Este es el flujo "legacy", el nuevo flujo usa SYNC
		Loading:Hide()
		Summary:Close()
		Instr:Open()
	end
end)

-- ===== Sync autoritativo del servidor =====
-- El servidor envía { state = "INVITE"/"PROPOSAL"/"SUMMARY"/"LOADING"/"PROMISED"/"CANCELED", ... }
SYNC.OnClientEvent:Connect(function(payload)
	if not payload or type(payload) ~= "table" then return end
	local state = payload.state

	if state == "INVITE" then
		currentOtherId = payload.partnerId
		Invite:Show(payload.partnerId, payload.partnerName or "Jugador")

        Invite:SetStatuses(payload.youAccepted, payload.partnerAccepted)

		-- Si el otro ya aceptó, muéstralo en la nota
		if payload.partnerAccepted then
			Invite:SetPartnerAcceptedNote(payload.partnerName or "El jugador")
		end

		-- ACTUALIZA estados y lock/unlock según lo que sabe el servidor
		Invite:SetStatuses(payload.youAccepted, payload.partnerAccepted)

		if payload.youAccepted and not payload.partnerAccepted then
			-- tú ya aceptaste => bloquea y muestra “esperando…”
			Invite:LockWaiting()
		elseif not payload.youAccepted then
			-- tú no has aceptado => deja habilitado
			Invite:Unlock()
		end

	elseif state == "PROPOSAL" then
		inviteActive = false
		Invite:Hide()
		Proposal:Open(currentOtherId, payload.partnerB or payload.partnerA or "Jugador")

   elseif state == "SUMMARY" then
    Loading:Hide() -- << [ARREGLO] Oculta la carga
    Proposal:Close()
    Summary:Open(
        currentOtherId,
        payload.a.mps, payload.a.items,
        payload.b.mps, payload.b.items,
        payload.warning,
        payload.youAccepted,
        payload.partnerAccepted,
        payload.partnerName
    )
	
	-- ===================================================
	-- ¡NUEVO ESTADO DE CARGA SINCRONIZADO!
	-- ===================================================
	elseif state == "LOADING" then
		-- Asegúrate de ocultar todas las pantallas anteriores
		Invite:Hide()
		Proposal:Close()
		Summary:Close()
		-- Muestra la carga
		Loading:Show("Confirmando trade...\nEsperando al servidor.")

	-- ===================================================
	-- Estado PROMISED MODIFICADO
	-- ===================================================
	elseif state == "PROMISED" then
		Loading:Hide() -- Oculta la pantalla de carga
		Summary:Close()
		
		Instr:Open() -- Muestra las instrucciones
		
		if payload.proofCode then
			-- Muestra un toast con el código
			Toast:Show("Trade confirmado! Proof: "..payload.proofCode, 3)
		end
	-- ===================================================

	-- ===================================================
	-- Estado CANCELED MODIFICADO
	-- ===================================================
	elseif state == "CANCELED" then
		-- Asegúrate de ocultar todas las pantallas
		Invite:Hide(); Proposal:Close(); Summary:Close(); Loading:Hide()
		
		if payload.reason then
			Toast:Show(payload.reason, 1.6)
		end
	-- ===================================================
	end
end)