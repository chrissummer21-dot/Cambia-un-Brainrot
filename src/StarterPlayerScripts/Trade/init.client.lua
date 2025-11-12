-- init.client.lua (cliente orquestador + SyncState autoritativo)
-- Ruta: StarterPlayerScripts/Trade/init.client.lua

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Módulos locales
local RemotesMod     = require(script.Remotes)
local Components     = require(script.Components)
local ToastClass     = require(script.Toast)

local InviteScreen   = require(script.Screens.Invite)
local SummaryScreen  = require(script.Screens.Summary)
local InstrScreen    = require(script.Screens.Instructions)
local LoadingScreen  = require(script.Screens.Loading)
local ItemSelector   = require(script.Screens.ItemSelector)
local ProposalReview = require(script.Screens.ProposalReview)
local IntermediaryScreen = require(script.Screens.Intermediary) -- [¡AÑADIDO!]
local WaitingScreen  = require(script.Screens.Waiting)

-- ===== Remotos =====
local R = RemotesMod.Get()
local REQ, RESP, SUBMIT, CONFIRM, CANCEL, SYNC =
	R.REQ, R.RESP, R.SUBMIT, R.CONFIRM, R.CANCEL, R.SYNC

-- ===== UI raíz + pantallas =====
local gui    = Components.MakeScreenGui()
local Toast  = ToastClass.new(gui)

local Invite   = InviteScreen.new(gui)
local Summary  = SummaryScreen.new(gui)
local Instr    = InstrScreen.new(gui, Toast)
local Loading  = LoadingScreen.new(gui)
local Selector = ItemSelector.new(gui)
local Review   = ProposalReview.new(gui, Toast) -- [¡CORREGIDO!] Pasa el Toast
local Intermediary = IntermediaryScreen.new(gui) -- [¡AÑADIDO!]
local Waiting  = WaitingScreen.new(gui)

-- ===== Estado local =====
local currentOtherId = nil
local inviteActive   = false
local currentTradeState = "NONE"

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

Selector.acceptBtn.MouseButton1Click:Connect(function()
	if not Selector.otherId then return end
	
	local stagedItems = Selector:GetStagedItems()
	
	if #stagedItems == 0 then
		Toast:Show("Debes 'Añadir' al menos un ítem primero.", 1.5)
		return
	end
	
	local otherDisplayName = Selector.title.Text:gsub("Ofrecer a <b>", ""):gsub("</b>", "")
	
	Review:Open(Selector.otherId, otherDisplayName, stagedItems)
	Selector:Close()
end)


Review.backBtn.MouseButton1Click:Connect(function()
	if not Review.otherId then return end
	
	local otherId = Review.otherId
	local otherDisplayName = Review.title.Text:gsub("Revisa tu oferta para <b>", ""):gsub("</b>", "")

	Review:Close()
	Selector:Open(otherId, otherDisplayName)
end)

-- [¡ACTUALIZADO!] Este botón ahora abre la pantalla de Intermediario
Review.acceptBtn.MouseButton1Click:Connect(function()
	if not Review.otherId then return end
	
	local proposalData = Review:GetProposalData() 
	local totalValue = 0
	for _, item in ipairs(proposalData) do
		totalValue = totalValue + item.value
	end
	
	if totalValue <= 0 then
		Toast:Show("Debes ingresar un valor mayor a 0.", 1.5)
		return
	end

	-- Abre la nueva pantalla
	Intermediary:Open(Review.otherId, proposalData, totalValue)

	Review:Close()
end)

-- [¡NUEVO!] Clics para la pantalla de Intermediario
local function SendProposal(wantsIntermediary)
	if not Intermediary.otherId then return end
	
	SUBMIT:FireServer({
		otherId = Intermediary.otherId,
		itemsList   = Intermediary.proposalData, 
		totalValue  = Intermediary.totalValue,
		wantsIntermediary = wantsIntermediary -- El nuevo dato
	})
	
	Intermediary:Close()
	Waiting:Show()
end

Intermediary.siBtn.MouseButton1Click:Connect(function()
	SendProposal(true)
end)

Intermediary.noBtn.MouseButton1Click:Connect(function()
	SendProposal(false)
end)
-- (Fin del bloque nuevo)


Summary.acceptBtn.MouseButton1Click:Connect(function()
	local otherId = Summary.otherId 
	if otherId then
		Summary:LockWaiting()
		CONFIRM:FireServer({ otherId = otherId, accept = true })
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

-- ===== Eventos “legacy” =====
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
		Selector:Open(payload.otherId, payload.otherName or "Jugador")
	end
end)

-- [¡CORREGIDO!] Eliminado el "openSummary" obsoleto
CONFIRM.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	
	if payload.kind == "peerConfirmed" then
		Toast:Show("El otro jugador confirmó el resumen.", 1.4)
	elseif payload.kind == "promised" then
		Loading:Hide()
		Summary:Close()
		Instr:Open()
	end
end)

-- ===== Sync autoritativo del servidor =====
SYNC.OnClientEvent:Connect(function(payload)
	if not payload or type(payload) ~= "table" then return end
	local state = payload.state

	if state == "INVITE" then
		currentTradeState = "INVITE"
		currentOtherId = payload.partnerId
		Invite:Show(payload.partnerId, payload.partnerName or "Jugador")
		
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
		currentTradeState = "PROPOSAL"
		inviteActive = false
		Invite:Hide()
		Selector:Open(currentOtherId, payload.partnerB or payload.partnerA or "Jugador")

   -- [¡CORREGIDO!] Lee las listas de ítems
  elseif state == "SUMMARY" then
		currentTradeState = "SUMMARY" 
		Loading:Hide() 
		Selector:Close() 
		Review:Close()
		Waiting:Hide() 
		Summary:Open(
			currentOtherId,
			payload.aItems, -- Tu lista
			payload.bItems, -- Su lista
			payload.warning,
			payload.youAccepted,
			payload.partnerAccepted,
			payload.partnerName,
			-- [¡NUEVO!]
			payload.aWantsIntermediary,
			payload.bWantsIntermediary
		)
	
	elseif state == "LOADING" then
		if currentTradeState ~= "PROMISED" then
			currentTradeState = "LOADING" 
			Invite:Hide()
			Selector:Close()
			Review:Close() 
			Summary:Close()
			Waiting:Hide() 
			Loading:Show("Confirmando trade...\nEsperando al servidor.")
		end

	-- NUEVO CÓDIGO (DESPUÉS) --
	elseif state == "PROMISED" then
		currentTradeState = "PROMISED" 
		Loading:Hide() 
		Summary:Close()
		
		-- [CAMBIO] Pasa el proofCode a la pantalla
		Instr:Open(payload.proofCode) 
		
		if payload.proofCode then
			Toast:Show("Trade confirmado! Proof: "..payload.proofCode, 3)
		end

	elseif state == "CANCELED" then
		currentTradeState = "NONE" 
		
		-- Ocultar TODAS las pantallas (incluyendo Intermediary)
		Invite:Hide(); Selector:Close(); Review:Close(); Summary:Close(); Loading:Hide(); Waiting:Hide(); Intermediary:Close()
		
		if payload.reason then
			Toast:Show(payload.reason, 1.6)
		end
	end
end)