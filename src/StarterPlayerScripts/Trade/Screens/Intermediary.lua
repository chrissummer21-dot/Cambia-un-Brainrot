-- Ruta: src/StarterPlayerScripts/Trade/Screens/Intermediary.lua
local Components = require(script.Parent.Parent.Components)

local Intermediary = {}
Intermediary.__index = Intermediary

function Intermediary.new(parent)
	local self = setmetatable({}, Intermediary)
	
	-- Un modal de tamaño mediano
	local modal = Components.MakeModal(parent, "Intermediary", 0.45, 0.4)
	modal.Visible = false

	local title = Components.MakeLabel("¿Te gustaría tener un intermediario para tu trade?", 26)
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = modal

	-- Fila de botones
	local buttonRow = Instance.new("Frame")
	buttonRow.Name = "ButtonRow"
	buttonRow.BackgroundTransparency = 1
	buttonRow.Size = UDim2.new(1, 0, 0, 45) -- Alto fijo para la fila
	buttonRow.Parent = modal
	
	local btnLayout = Instance.new("UIListLayout")
	btnLayout.FillDirection = Enum.FillDirection.Horizontal
	btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	btnLayout.Padding = UDim.new(0, 20)
	btnLayout.Parent = buttonRow

	local siBtn = Components.MakeButton("Si")
	siBtn.Size = UDim2.new(0.4, 0, 1, 0)
	siBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 70) -- Verde
	siBtn.Parent = buttonRow
	
	local noBtn = Components.MakeButton("No")
	noBtn.Size = UDim2.new(0.4, 0, 1, 0)
	noBtn.BackgroundColor3 = Color3.fromRGB(160, 40, 40) -- Rojo
	noBtn.Parent = buttonRow

	-- Texto descriptivo
	local desc = Components.MakeLabel(
		"El intermediario va a la base de cada uno de los jugadores y recoge los brainrots, después los intercambia, todo el proceso será grabado por los intermediarios también",
		18
	)
	desc.TextColor3 = Color3.fromRGB(255, 255, 255)
	desc.TextXAlignment = Enum.TextXAlignment.Center
	desc.Parent = modal

	self.modal = modal
	self.siBtn = siBtn
	self.noBtn = noBtn
	
	-- Almacenamiento temporal de datos
	self.otherId = nil
	self.proposalData = nil
	self.totalValue = nil

	return self
end

function Intermediary:Open(otherId, proposalData, totalValue)
	-- Guardamos los datos para cuando el jugador presione 'Si' o 'No'
	self.otherId = otherId
	self.proposalData = proposalData
	self.totalValue = totalValue
	self.modal.Visible = true
end

function Intermediary:Close()
	self.modal.Visible = false
	self.otherId = nil
	self.proposalData = nil
	self.totalValue = nil
end

return Intermediary