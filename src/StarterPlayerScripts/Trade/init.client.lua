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

-- ===== Remotos =====
local R = RemotesMod.Get()
local REQ, RESP, SUBMIT, CONFIRM, CANCEL, SYNC =
	R.REQ, R.RESP, R.SUBMIT, R.CONFIRM, R.CANCEL, R.SYNC

-- ===== UI raíz + pantallas =====
local gui    = Components.MakeScreenGui()
local Toast  = ToastClass.new(gui)

local Invite   = InviteScreen.new(gui)
local Summary  = SummaryScreen.new(gui)
local Instr    = InstrScreen.new(gui)
local Loading  = LoadingScreen.new(gui)
local Selector = ItemSelector.new(gui)
local Review   = ProposalReview.new(gui)

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
	
	-- 1. Abre la nueva pantalla CON la lista
	Review:Open(Selector.otherId, otherDisplayName, stagedItems)
	-- 2. CIERRA la pantalla anterior DESPUÉS (para no borrar la lista)
	Selector:Close()
end)

-- ===================================================
-- [¡ARREGLO!] Botón "Regresar" corregido
-- ===================================================
Review.backBtn.MouseButton1Click:Connect(function()
	if not Review.otherId then return end
	
	-- 1. Guardar los datos en variables locales ANTES de cerrar
	local otherId = Review.otherId
	local otherDisplayName = Review.title.Text:gsub("Revisa tu oferta para <b>", ""):gsub("</b>", "")

	-- 2. Ahora sí, cerrar la pantalla (esto borra Review.otherId)
	Review:Close()
	
	-- 3. Abrir la pantalla anterior usando las variables guardadas
	Selector:Open(otherId, otherDisplayName)
end)
-- ===================================================

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

	-- Convertir a los datos que el servidor espera (string de ítems, número de 'mps')
	local itemsStringList = {}
	local totalUnits = 0 
	
	for _, item in ipairs(proposalData) do
		local itemStr = string.format("%s (%d %s)", item.name, item.value, item.unit)
		table.insert(itemsStringList, itemStr)
		
		-- (NOTA: Por ahora, 'totalUnits' es solo la suma de los valores,
		-- ignorando si son K, M, o B. El servidor necesita ser actualizado
		-- para entender esto si quieres que los valores se sumen correctamente)
		totalUnits = totalUnits + item.value
	end
	
	local finalItemsString = table.concat(itemsStringList, ", ")
	
	-- ¡AQUÍ ENVIAMOS AL SERVIDOR!
	SUBMIT:FireServer({
		otherId = Review.otherId,
		items   = finalItemsString, -- String "Alessio (500 K/s), Godly 1 (10 M/s)"
		mps     = totalUnits -- Número total (ej: 510)
	})

	Review:Close()
	-- (El servidor responderá con SYNC "SUMMARY" si el otro jugador también envió)
end)


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
		Selector:Open(payload.otherId, payload.otherName or "Jugador")
	end
end)

CONFIRM.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	if payload.kind == "openSummary" then
		Selector:Close() 
		Review:Close() 
		Summary:Open(
			currentOtherId,
			payload.a.mps, payload.a.items,
			payload.b.mps, payload.b.items,
			payload.warning
		)
	elseif payload.kind == "peerConfirmed" then
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

   elseif state == "SUMMARY" then
		currentTradeState = "SUMMARY" 
		Loading:Hide() 
		Selector:Close() 
		Review:Close()
		Summary:Open(
			currentOtherId,
			payload.a.mps, payload.a.items,
			payload.b.mps, payload.b.items,
			payload.warning,
			payload.youAccepted,
			payload.partnerAccepted,
			payload.partnerName
		)
	
	elseif state == "LOADING" then
		if currentTradeState ~= "PROMISED" then
			currentTradeState = "LOADING" 
			Invite:Hide()
			Selector:Close()
			Review:Close() 
			Summary:Close()
			Loading:Show("Confirmando trade...\nEsperando al servidor.")
		end

	elseif state == "PROMISED" then
		currentTradeState = "PROMISED" 
		Loading:Hide() 
		Summary:Close()
		Instr:Open() 
		
		if payload.proofCode then
			Toast:Show("Trade confirmado! Proof: "..payload.proofCode, 3)
		end

	elseif state == "CANCELED" then
		currentTradeState = "NONE" 
		
		Invite:Hide(); Selector:Close(); Review:Close(); Summary:Close(); Loading:Hide()
		
		if payload.reason then
			Toast:Show(payload.reason, 1.6)
		end
	end
end)