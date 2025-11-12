-- Ruta: src/StarterPlayerScripts/NPCOfferController.client.lua
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local LocalPlayer = Players.LocalPlayer

-- Esperar por el RemoteEvent
local SUBMIT_OFFER = RS:WaitForChild("NPCOfferRemotes"):WaitForChild("SubmitNPCOffer")

-- Módulos de UI (Reutilizados y Nuevos)
local tradeFolder = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Trade")
local Components     = require(tradeFolder.Components)
local ToastClass     = require(tradeFolder.Toast)
local ItemSelector   = require(tradeFolder.Screens.ItemSelector)
local ProposalReview = require(tradeFolder.Screens.ProposalReview)

local NPCPrompt1     = require(tradeFolder.Screens.NPCPrompt1)
local NPCPrompt2     = require(tradeFolder.Screens.NPCPrompt2)
local NPCSummary     = require(tradeFolder.Screens.NPCSummary)
local NPCFinal       = require(tradeFolder.Screens.NPCFinal)

-- ===== Setup de UI =====
local gui    = Components.MakeScreenGui()
gui.Name = "NPCOfferUI"
gui.ResetOnSpawn = true -- ¡Importante!
local Toast  = ToastClass.new(gui)

-- Instanciar todas las pantallas
local Prompt1  = NPCPrompt1.new(gui)
local Prompt2  = NPCPrompt2.new(gui)
local Selector = ItemSelector.new(gui)
local Review   = ProposalReview.new(gui, Toast)
local Summary  = NPCSummary.new(gui)
local Final    = NPCFinal.new(gui)

-- ===== Estado y Datos =====
local currentOfferData = {}
local TAG_NAME = "FOUNDER_NPC" -- La etiqueta que buscaremos

-- ===================================================
-- [¡CAMBIO!] Setup del Trigger usando CollectionService
-- ===================================================

-- Esta función conecta el flujo de UI a CUALQUIER prompt que le pasemos
local function SetupNPCPrompt(npcModel)
	if not npcModel:IsA("Model") then
		warn("El objeto con tag '"..TAG_NAME.."' no es un Modelo. Omitiendo.")
		return
	end
	
	local prompt = npcModel:FindFirstChildOfClass("ProximityPrompt")
	
	if prompt then
		-- Conecta el prompt que creaste manualmente
		prompt.Triggered:Connect(function()
			-- Solo abre si no estamos ya en medio de una oferta
			if not Prompt1.modal.Visible and not Prompt2.modal.Visible and not Selector.modal.Visible then
				Prompt1:Open()
			end
		end)
	else
		warn("ADVERTENCIA: El NPC '"..npcModel.Name.."' tiene el tag '"..TAG_NAME.."', pero le falta un ProximityPrompt manual.")
	end
end

-- 1. Conectar la función a cualquier NPC que se AÑADA al juego con el tag
CollectionService:GetInstanceAddedSignal(TAG_NAME):Connect(SetupNPCPrompt)

-- 2. Conectar la función a todos los NPCs que YA ESTÁN en el juego
for _, npcModel in pairs(CollectionService:GetTagged(TAG_NAME)) do
	SetupNPCPrompt(npcModel)
end

-- =Game-Setup del Trigger (ProximityPrompt) =====

-- ===== Flujo de UI =====

-- 1. Prompt 1 (Si/No)
Prompt1.siBtn.MouseButton1Click:Connect(function()
	Prompt1:Close()
	Prompt2:Open()
end)
Prompt1.noBtn.MouseButton1Click:Connect(function()
	Prompt1:Close()
end)

-- 2. Prompt 2 (OK)
Prompt2.okBtn.MouseButton1Click:Connect(function()
	Prompt2:Close()
	-- Abre el selector (el 'otherDisplay' es solo texto, "Fundadores" funciona)
	Selector:Open(LocalPlayer.UserId, "Fundadores") 
end)

-- 3. ItemSelector (Reutilizado)
Selector.acceptBtn.MouseButton1Click:Connect(function()
	local stagedItems = Selector:GetStagedItems()
	if #stagedItems == 0 then
		Toast:Show("Debes 'Añadir' al menos un ítem primero.", 1.5)
		return
	end
	
	currentOfferData.stagedItems = stagedItems
	Review:Open(LocalPlayer.UserId, "Fundadores", stagedItems)
	Selector:Close()
end)

-- 4. ProposalReview (Reutilizado)
Review.acceptBtn.MouseButton1Click:Connect(function()
	local proposalData = Review:GetProposalData()
	local totalValue = 0
	for _, item in ipairs(proposalData) do
		totalValue = totalValue + item.value
	end
	
	if totalValue <= 0 then
		Toast:Show("Debes ingresar un valor mayor a 0.", 1.5)
		return
	end

	currentOfferData.proposal = proposalData
	Summary:Open(proposalData)
	Review:Close()
end)
Review.backBtn.MouseButton1Click:Connect(function()
	Review:Close()
	Selector:Open(LocalPlayer.UserId, "Fundadores")
end)

-- 5. Summary (Nuevo)
Summary.acceptBtn.MouseButton1Click:Connect(function()
	if currentOfferData.proposal then
		SUBMIT_OFFER:FireServer(currentOfferData.proposal)
	end
	
	Summary:Close()
	Final:Open()
end)
Summary.backBtn.MouseButton1Click:Connect(function()
	Summary:Close()
	Review:Open(LocalPlayer.UserId, "Fundadores", currentOfferData.stagedItems)
end)

-- 6. Final (Nuevo)
Final.okBtn.MouseButton1Click:Connect(function()
	Final:Close()
	currentOfferData = {} 
end)