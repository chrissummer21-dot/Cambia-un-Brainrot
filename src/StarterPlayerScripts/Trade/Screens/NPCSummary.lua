-- Ruta: src/StarterPlayerScripts/Trade/Screens/NPCSummary.lua
local Components = require(script.Parent.Parent.Components)
local BrainrotDatabase = require(game:GetService("ReplicatedStorage"):WaitForChild("BrainrotDatabase"))

local NPCSummary = {}
NPCSummary.__index = NPCSummary
local PLACEHOLDER_IMAGE_ID = "512833360"

-- Copia de 'makeSummaryRow' de Summary.lua
local function addTextStroke(guiObject)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5; stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Transparency = 0.4; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = guiObject
	return stroke
end
local function makeSummaryRow(parent, itemData)
	local rowFrame = Instance.new("Frame")
	rowFrame.Name = itemData.id; rowFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	rowFrame.Size = UDim2.new(1, 0, 0, 50); rowFrame.Parent = parent
	Instance.new("UICorner", rowFrame).CornerRadius = UDim.new(0, 8)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal; layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 8); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = rowFrame
	local padding = Instance.new("UIPadding"); padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8); padding.Parent = rowFrame
	local image = Instance.new("ImageLabel"); image.Size = UDim2.fromOffset(40, 40)
	local dbEntry = nil; local imageId = nil; local category = itemData.rarity
	if category and BrainrotDatabase[category] then
		for _, item in ipairs(BrainrotDatabase[category]) do
			if item.ID == itemData.id then dbEntry = item; break end
		end
	end
	if not dbEntry then
		for cat, items in pairs(BrainrotDatabase) do
			if dbEntry then break end
			for _, item in ipairs(items) do
				if item.ID == itemData.id then dbEntry = item; break end
			end
		end
	end
	if dbEntry then imageId = dbEntry.Image end
	image.Image = "rbxassetid://" .. (imageId or PLACEHOLDER_IMAGE_ID)
	image.ScaleType = Enum.ScaleType.Fit; image.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	image.LayoutOrder = 1; image.Parent = rowFrame; Instance.new("UICorner", image).CornerRadius = UDim.new(0, 6)
	local nameLabel = Components.MakeLabel(itemData.name, 18); nameLabel.Size = UDim2.new(0.4, 0, 0.8, 0)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left; addTextStroke(nameLabel); nameLabel.LayoutOrder = 2
	nameLabel.Parent = rowFrame
	local valueString; if itemData.value == math.floor(itemData.value) then valueString = tostring(itemData.value) else valueString = string.format("%.1f", itemData.value) end
	local valueText = string.format("%s %s", valueString, itemData.unit)
	local valueLabel = Components.MakeLabel(valueText, 20); valueLabel.Size = UDim2.new(0.35, 0, 0.8, 0)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right; addTextStroke(valueLabel); valueLabel.LayoutOrder = 3
	valueLabel.Parent = rowFrame
	return rowFrame
end
-- Fin de la copia

function NPCSummary.new(parent)
	local self = setmetatable({}, NPCSummary)
	local modal = Components.MakeModal(parent, "NPCSummary", 0.5, 0.6)
	modal.Visible = false

	local title = Components.MakeLabel("Revisa tu oferta", 30)
	title.Font = Enum.Font.GothamBold; title.Parent = modal

	local aScroll = Instance.new("ScrollingFrame")
	aScroll.Name = "A_Scroll"; aScroll.Size = UDim2.new(1, 0, 0.6, 0)
	aScroll.BackgroundColor3 = Color3.fromRGB(10, 10, 10); aScroll.BackgroundTransparency = 0.5
	aScroll.BorderSizePixel = 0; aScroll.ScrollBarThickness = 6; aScroll.Parent = modal
	
	local aScrollLayout = Instance.new("UIListLayout")
	-- ===================================================
	-- [¡CORRECCIÓN!] (Línea 70 aprox)
	-- Se cambió UDim2.new por UDim.new
	-- ===================================================
	aScrollLayout.Padding = UDim.new(0, 6)
	
	aScrollLayout.Parent = aScroll; Instance.new("UICorner", aScroll).CornerRadius = UDim.new(0, 8)
	local aPadding = Instance.new("UIPadding", aScroll); aPadding.PaddingTop = UDim.new(0, 6)
	aPadding.PaddingBottom = UDim.new(0, 6); aPadding.PaddingLeft = UDim.new(0, 6)
	aPadding.PaddingRight = UDim.new(0, 6)

	local acceptBtn = Components.MakeButton("Enviar Oferta"); acceptBtn.Parent = modal
	local backBtn   = Components.MakeButton("Regresar"); backBtn.Parent   = modal
	
	self.modal = modal
	self.acceptBtn = acceptBtn
	self.backBtn = backBtn
	self.listContainer = aScroll
	return self
end

function NPCSummary:Open(itemsList)
	for _, child in ipairs(self.listContainer:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	if itemsList and type(itemsList) == "table" then
		for _, itemData in ipairs(itemsList) do
			makeSummaryRow(self.listContainer, itemData)
		end
	end
	self.modal.Visible = true
end
function NPCSummary:Close() self.modal.Visible = false end
return NPCSummary