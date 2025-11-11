-- Ruta: src/StarterPlayerScripts/Trade/Screens/ProposalReview.lua
local Components = require(script.Parent.Parent.Components)
local BrainrotDatabase = require(game:GetService("ReplicatedStorage"):WaitForChild("BrainrotDatabase"))

local ProposalReview = {}
ProposalReview.__index = ProposalReview

local PLACEHOLDER_IMAGE_ID = "512833360"
local UNITS = {"K/s", "M/s", "B/s"}

-- Función auxiliar para añadir borde negro al texto
local function addTextStroke(guiObject)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5; stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Transparency = 0.4; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = guiObject
	return stroke
end

-- Función auxiliar para crear CADA FILA en la lista de revisión
local function makeReviewRow(parent, itemData)
	local rowFrame = Instance.new("Frame")
	rowFrame.Name = itemData.ID
	rowFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	rowFrame.Size = UDim2.new(1, 0, 0, 60)
	rowFrame.Parent = parent
	Instance.new("UICorner", rowFrame).CornerRadius = UDim.new(0, 8)

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = rowFrame
	
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = rowFrame

	-- 1. Foto
	local image = Instance.new("ImageLabel")
	image.Size = UDim2.fromOffset(50, 50)
	-- [CAMBIO] Usa el 'Image' del itemData (que puede ser nil para custom)
	local imageId = (itemData.Image and "rbxassetid://"..itemData.Image) or ("rbxassetid://"..PLACEHOLDER_IMAGE_ID)
	image.Image = imageId
	image.ScaleType = Enum.ScaleType.Fit
	image.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	image.LayoutOrder = 1
	image.Parent = rowFrame
	Instance.new("UICorner", image).CornerRadius = UDim.new(0, 6)

	-- 2. Nombre
	-- [CAMBIO] Usa el 'Name' del itemData (custom o db)
	local nameLabel = Components.MakeLabel(itemData.Name, 20)
	nameLabel.Size = UDim2.new(0.35, 0, 0.8, 0)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	addTextStroke(nameLabel)
	nameLabel.LayoutOrder = 2
	nameLabel.Parent = rowFrame

	-- 3. Campo de Texto
	local valueBox = Components.MakeInput("0", 22)
	valueBox.Size = UDim2.new(0.3, 0, 0.7, 0)
	valueBox.Text = ""
	valueBox.PlaceholderText = "$/s"
	addTextStroke(valueBox)
	valueBox.LayoutOrder = 3
	valueBox.Parent = rowFrame
	
	valueBox:GetPropertyChangedSignal("Text"):Connect(function()
		local newText = valueBox.Text:gsub("[^%d]", "")
		if valueBox.Text ~= newText then
			valueBox.Text = newText
		end
	end)

	-- 4. Lista Desplegable
	local dropdownFrame = Instance.new("Frame")
	dropdownFrame.Size = UDim2.new(0.2, 0, 0.7, 0)
	dropdownFrame.BackgroundTransparency = 1
	dropdownFrame.LayoutOrder = 4
	dropdownFrame.Parent = rowFrame

	local dropdownBtn = Components.MakeButton(UNITS[1])
	dropdownBtn.Size = UDim2.fromScale(1, 1)
	addTextStroke(dropdownBtn)
	dropdownBtn.Parent = dropdownFrame
	
	local optionsFrame = Instance.new("Frame")
	optionsFrame.Name = "Options"
	optionsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	optionsFrame.BorderSizePixel = 0
	optionsFrame.Position = UDim2.fromScale(0, 1) 
	optionsFrame.Size = UDim2.new(1, 0, 0, 0) 
	optionsFrame.AutomaticSize = Enum.AutomaticSize.Y
	optionsFrame.Visible = false
	optionsFrame.Parent = dropdownBtn
	optionsFrame.ZIndex = 2
	Instance.new("UICorner", optionsFrame).CornerRadius = UDim.new(0, 6)
	Instance.new("UIListLayout", optionsFrame).Padding = UDim.new(0, 4)
	
	for _, unit in ipairs(UNITS) do
		local optionBtn = Components.MakeButton(unit)
		optionBtn.Size = UDim2.new(1, 0, 0, 30)
		optionBtn.Parent = optionsFrame
		
		optionBtn.MouseButton1Click:Connect(function()
			dropdownBtn.Text = unit 
			optionsFrame.Visible = false 
		end)
	end

	dropdownBtn.MouseButton1Click:Connect(function()
		optionsFrame.Visible = not optionsFrame.Visible
	end)

	return rowFrame, valueBox, dropdownBtn
end

function ProposalReview.new(parent)
	local self = setmetatable({}, ProposalReview)
	
	local modal = Components.MakeModal(parent, "ProposalReview", 0.6, 0.7)
	modal.Visible = false
	
	local modalLayout = modal:FindFirstChildOfClass("UIListLayout")
	modalLayout.Padding = UDim.new(0, 12)

	local title = Components.MakeLabel("Revisa tu Propuesta", 30)
	title.Font = Enum.Font.GothamBold
	title.Size = UDim2.new(1, 0, 0.08, 0)
	addTextStroke(title)
	title.Parent = modal

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ReviewContainer"
	scrollFrame.Size = UDim2.new(1, 0, 0.65, 0)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.Parent = modal
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 8)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = scrollFrame

	local buttonRow = Instance.new("Frame")
	buttonRow.Name = "ButtonRow"
	buttonRow.BackgroundTransparency = 1
	buttonRow.Size = UDim2.new(1, 0, 0.1, 0)
	buttonRow.Parent = modal
	
	local btnLayout = Instance.new("UIListLayout")
	btnLayout.FillDirection = Enum.FillDirection.Horizontal
	btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	btnLayout.Padding = UDim.new(0, 20)
	btnLayout.Parent = buttonRow

	self.acceptBtn = Components.MakeButton("Aceptar")
	self.acceptBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 70) 
	self.acceptBtn.Size = UDim2.new(0.4, 0, 1, 0)
	addTextStroke(self.acceptBtn)
	self.acceptBtn.Parent = buttonRow
	
	self.backBtn = Components.MakeButton("Regresar")
	self.backBtn.Size = UDim2.new(0.4, 0, 1, 0)
	addTextStroke(self.backBtn)
	self.backBtn.Parent = buttonRow

	self.modal = modal
	self.title = title
	self.scrollFrame = scrollFrame
	self.listLayout = listLayout
	self.otherId = nil
	
	self.itemInputs = {} 
	
	return self
end

-- ===================================================
-- [¡CAMBIO!] Esta función ahora maneja objetos DB y Custom
-- ===================================================
local function getItemData(itemObject)
	if itemObject.type == "Database" then
		-- Es un ítem de la DB, buscarlo
		for category, items in pairs(BrainrotDatabase) do
			for _, item in ipairs(items) do
				if item.ID == itemObject.id then
					return item -- Devuelve la tabla completa de la DB
				end
			end
		end
	elseif itemObject.type == "Custom" then
		-- Es un ítem custom, construir una tabla compatible
		return {
			Name = itemObject.name,
			ID = itemObject.name, -- Usar el nombre como ID único
			Image = nil, -- No tiene imagen
			Rarity = itemObject.rarity
		}
	end
	
	-- Fallback por si algo sale mal
	return {Name = "Error", ID = "error", Image = nil}
end

function ProposalReview:Open(otherId, otherDisplay, stagedItems)
	self.otherId = otherId
	self.title.Text = ("Revisa tu oferta para <b>%s</b>"):format(otherDisplay or "Jugador")
	
	for _, child in ipairs(self.scrollFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	table.clear(self.itemInputs)
	
	-- Poblar la lista con los ítems (objetos)
	for _, itemObject in ipairs(stagedItems) do
		local itemData = getItemData(itemObject)
		
		local row, valueBox, unitBtn = makeReviewRow(self.scrollFrame, itemData)
		table.insert(self.itemInputs, {
			-- [CAMBIO] Guardar los datos del ítem para el envío
			data = itemData, 
			valueBox = valueBox,
			unitBtn = unitBtn
		})
	end
	
	self.modal.Visible = true
end
-- ===================================================

function ProposalReview:Close()
	self.modal.Visible = false
	self.otherId = nil
	
	for _, child in ipairs(self.scrollFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	table.clear(self.itemInputs)
end

-- ===================================================
-- [¡CAMBIO!] Recolectar datos actualizados
-- ===================================================
function ProposalReview:GetProposalData()
	local proposal = {}
	for _, input in ipairs(self.itemInputs) do
		local value = tonumber(input.valueBox.Text) or 0
		local unit = input.unitBtn.Text
		
		table.insert(proposal, {
			id = input.data.ID,
			name = input.data.Name,
			value = value,
			unit = unit
		})
	end
	return proposal
end
-- ===================================================

return ProposalReview