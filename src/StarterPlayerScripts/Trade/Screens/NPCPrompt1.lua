-- Ruta: src/StarterPlayerScripts/Trade/Screens/NPCPrompt1.lua
local Components = require(script.Parent.Parent.Components)
local Intermediary = {}
Intermediary.__index = Intermediary

function Intermediary.new(parent)
	local self = setmetatable({}, Intermediary)
	local modal = Components.MakeModal(parent, "NPCPrompt1", 0.45, 0.3)
	modal.Visible = false

	local title = Components.MakeLabel("¿Quieres tradear con uno de los miembros fundadores?", 26)
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = modal

	local buttonRow = Instance.new("Frame")
	buttonRow.Name = "ButtonRow"; buttonRow.BackgroundTransparency = 1
	buttonRow.Size = UDim2.new(1, 0, 0, 45)
	buttonRow.Parent = modal
	
	local btnLayout = Instance.new("UIListLayout")
	btnLayout.FillDirection = Enum.FillDirection.Horizontal
	btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	
	-- ===================================================
	-- [¡CORRECCIÓN!] (Línea 25)
	-- Se cambió UDim2.new por UDim.new
	-- ===================================================
	btnLayout.Padding = UDim.new(0, 20)
	
	btnLayout.Parent = buttonRow

	local siBtn = Components.MakeButton("Si")
	siBtn.Size = UDim2.new(0.4, 0, 1, 0)
	siBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 70)
	siBtn.Parent = buttonRow
	
	local noBtn = Components.MakeButton("No")
	noBtn.Size = UDim2.new(0.4, 0, 1, 0)
	noBtn.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
	noBtn.Parent = buttonRow

	self.modal = modal
	self.siBtn = siBtn
	self.noBtn = noBtn
	return self
end
function Intermediary:Open() self.modal.Visible = true end
function Intermediary:Close() self.modal.Visible = false end
return Intermediary