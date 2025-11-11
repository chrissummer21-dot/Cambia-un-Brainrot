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
local currentTradeState = "NONE" -- Usaremos "NONE", "LOADING", "PROMISED"
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
		currentTradeState = "INVITE" -- Actualiza el estado
		currentOtherId = payload.partnerId
		Invite:Show(payload.partnerId, payload.partnerName or "Jugador")
		
		-- ... (el resto de tu código de INVITE) ...
		Invite:SetStatuses(payload.youAccepted, payload.partnerAccepted)
		if payload.partnerAccepted then
			Invite:SetPartnerAcceptedNote(payload.partnerName or "El jugador")
		end
		Invite:SetStatuses(payload.youAccepted, payload.partnerAccepted)
		if payload.youAccepted and not payload.partnerAccepted then
			Invite:LockWaiting()
		elseif not payload.youAccepted then
			Invite:Unlock()
		end

	elseif state == "PROPOSAL" then
		currentTradeState = "PROPOSAL" -- Actualiza el estado
		inviteActive = false
		Invite:Hide()
		Proposal:Open(currentOtherId, payload.partnerB or payload.partnerA or "Jugador")

   elseif state == "SUMMARY" then
		currentTradeState = "SUMMARY" -- Actualiza el estado
		Loading:Hide() 
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
	-- ESTADO DE CARGA SINCRONIZADO (¡ARREGLADO!)
	-- ===================================================
	elseif state == "LOADING" then
		-- [ARREGLO] Solo muestra la carga si no hemos llegado ya a PROMISED
		if currentTradeState ~= "PROMISED" then
			currentTradeState = "LOADING" -- Actualiza el estado
			
			-- Asegúrate de ocultar todas las pantallas anteriores
			Invite:Hide()
			Proposal:Close()
			Summary:Close()
			-- Muestra la carga
			Loading:Show("Confirmando trade...\nEsperando al servidor.")
		end
		-- Si 'currentTradeState' YA es 'PROMISED', este paquete 'LOADING'
		-- llegó tarde y lo ignoraremos por completo.

	-- ===================================================
	-- ESTADO PROMISED (¡ARREGLADO!)
	-- ===================================================
	elseif state == "PROMISED" then
		currentTradeState = "PROMISED" -- Súper importante: marca el estado final
		
		Loading:Hide() -- Oculta la pantalla de carga (seguro)
		Summary:Close()
		
		Instr:Open() -- Muestra las instrucciones
		
		if payload.proofCode then
			Toast:Show("Trade confirmado! Proof: "..payload.proofCode, 3)
		end
	-- ===================================================

	-- ===================================================
	-- ESTADO CANCELED (¡ARREGLADO!)
	-- ===================================================
	elseif state == "CANCELED" then
		currentTradeState = "NONE" -- Resetea el estado para un futuro trade
		
		-- Asegúrate de ocultar todas las pantallas
		Invite:Hide(); Proposal:Close(); Summary:Close(); Loading:Hide()
		
		if payload.reason then
			Toast:Show(payload.reason, 1.6)
		end
	-- ===================================================
	end
end)