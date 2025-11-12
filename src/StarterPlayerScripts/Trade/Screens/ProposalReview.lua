local Components = require(script.Parent.Parent.Components)
local BrainrotDatabase = require(game:GetService("ReplicatedStorage"):WaitForChild("BrainrotDatabase"))

local ProposalReview = {}
ProposalReview.__index = ProposalReview

local PLACEHOLDER_IMAGE_ID = "512833360"
local UNITS = {"K/s", "M/s", "B/s"}

-- Dropdown actualmente abierto (frame de opciones)
local currentOpenOptions = nil

-- Función auxiliar para añadir borde negro al texto
local function addTextStroke(guiObject)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Transparency = 0.4
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
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
	rowFrame.ZIndex = 1
	rowFrame.ClipsDescendants = false
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
	local imageId = (itemData.Image and "rbxassetid://"..itemData.Image) or ("rbxassetid://"..PLACEHOLDER_IMAGE_ID)
	image.Image = imageId
	image.ScaleType = Enum.ScaleType.Fit
	image.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	image.LayoutOrder = 1
	image.Parent = rowFrame
	image.ZIndex = rowFrame.ZIndex
	Instance.new("UICorner", image).CornerRadius = UDim.new(0, 6)

	-- 2. Nombre
	local nameLabel = Components.MakeLabel(itemData.Name, 20)
	nameLabel.Size = UDim2.new(0.35, 0, 0.8, 0)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	addTextStroke(nameLabel)
	nameLabel.LayoutOrder = 2
	nameLabel.Parent = rowFrame
	nameLabel.ZIndex = rowFrame.ZIndex

	-- 3. Campo de Texto
	local valueBox = Components.MakeInput("0", 22)
	valueBox.Size = UDim2.new(0.3, 0, 0.7, 0)
	valueBox.Text = ""
	valueBox.PlaceholderText = "$/s"
	addTextStroke(valueBox)
	valueBox.LayoutOrder = 3
	valueBox.Parent = rowFrame
	valueBox.ZIndex = rowFrame.ZIndex
	
	-- FILTRO NÚMERICO
	valueBox:GetPropertyChangedSignal("Text"):Connect(function()
		local text = valueBox.Text
		local filtered = text:gsub("[^%d.]", "")
		local firstDot = filtered:find(".", 1, true)
		if firstDot then
			local pre = filtered:sub(1, firstDot)
			local post = filtered:sub(firstDot + 1)
			post = post:gsub("%.", "")
			if #post > 1 then
				post = post:sub(1, 1)
			end
			filtered = pre .. post
		end
		if #filtered > 5 then
			filtered = filtered:sub(1, 5)
			local dotPos = filtered:find(".", 1, true)
			if dotPos and (#filtered - dotPos) > 1 then
				filtered = filtered:sub(1, dotPos + 1)
			end
			if filtered:sub(-1) == "." then
				filtered = filtered:sub(1, 4)
			end
		end
		local num = tonumber(filtered)
		if num and num > 999.9 then
			filtered = "999.9"
		end
		if valueBox.Text ~= filtered then
			valueBox.Text = filtered
		end
	end)

	-- 4. Lista Desplegable
	local dropdownFrame = Instance.new("Frame")
	dropdownFrame.Size = UDim2.new(0.2, 0, 0.7, 0)
	dropdownFrame.BackgroundTransparency = 1
	dropdownFrame.LayoutOrder = 4
	dropdownFrame.Parent = rowFrame
	dropdownFrame.ZIndex = rowFrame.ZIndex
	dropdownFrame.ClipsDescendants = false

	local dropdownBtn = Components.MakeButton(UNITS[1])
	dropdownBtn.Size = UDim2.fromScale(1, 1)
	addTextStroke(dropdownBtn)
	dropdownBtn.Parent = dropdownFrame
	dropdownBtn.ZIndex = rowFrame.ZIndex + 1

	local optionsFrame = Instance.new("Frame")
	optionsFrame.Name = "Options"
	optionsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	optionsFrame.BorderSizePixel = 0
	optionsFrame.Position = UDim2.fromScale(0, 1)
	optionsFrame.Size = UDim2.new(1, 0, 0, 0)
	optionsFrame.AutomaticSize = Enum.AutomaticSize.Y
	optionsFrame.Visible = false
	optionsFrame.Parent = dropdownBtn
	optionsFrame.ClipsDescendants = false

	-- ZIndex alto para estar delante de todo
	optionsFrame.ZIndex = 50
	Instance.new("UICorner", optionsFrame).CornerRadius = UDim.new(0, 6)

	local optionsLayout = Instance.new("UIListLayout")
	optionsLayout.Padding = UDim.new(0, 4)
	optionsLayout.Parent = optionsFrame

	-- helper para abrir/cerrar asegurando solo uno abierto
	local function setOptionsVisible(visible)
		if visible then
			if currentOpenOptions and currentOpenOptions ~= optionsFrame then
				currentOpenOptions.Visible = false
			end
			currentOpenOptions = optionsFrame
			optionsFrame.Visible = true
		else
			if currentOpenOptions == optionsFrame then
				currentOpenOptions = nil
			end
			optionsFrame.Visible = false
		end
	end

	for _, unit in ipairs(UNITS) do
		local optionBtn = Components.MakeButton(unit)
		optionBtn.Size = UDim2.new(1, 0, 0, 30)
		optionBtn.Parent = optionsFrame
		optionBtn.ZIndex = optionsFrame.ZIndex + 1

		optionBtn.MouseButton1Click:Connect(function()
			dropdownBtn.Text = unit
			setOptionsVisible(false)
		end)
	end

	dropdownBtn.MouseButton1Click:Connect(function()
		setOptionsVisible(not optionsFrame.Visible)
	end)

	return rowFrame, valueBox, dropdownBtn
end

function ProposalReview.new(parent)
	local self = setmetatable({}, ProposalReview)
	
	local modal = Components.MakeModal(parent, "ProposalReview", 0.6, 0.7)
	modal.Visible = false
	modal.ClipsDescendants = false

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
	scrollFrame.ClipsDescendants = false

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
		local category = itemObject.rarity or "Secret" -- Usa la rareza que guardamos

		if BrainrotDatabase[category] then
			for _, item in ipairs(BrainrotDatabase[category]) do
				if item.ID == itemObject.id then
					item.Rarity = category -- Asegurarse de que esté en el objeto
					return item
				end
			end
		end
		-- Fallback si no se encuentra en esa categoría (raro)
		for categoryFallback, items in pairs(BrainrotDatabase) do
			for _, item in ipairs(items) do
				if item.ID == itemObject.id then
					item.Rarity = categoryFallback
					return item
				end
			end
		end

	elseif itemObject.type == "Custom" then
		return {
			Name = itemObject.name,
			ID = itemObject.name,
			Image = nil,
			Rarity = itemObject.rarity
		}
	end
	return {Name = "Error", ID = "error", Image = nil}
end

function ProposalReview:Open(otherId, otherDisplay, stagedItems)
	self.otherId = otherId
	self.title.Text = ("Revisa tu oferta para <b>%s</b>"):format(otherDisplay or "Jugador")
	
	for _, child in ipairs(self.scrollFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	table.clear(self.itemInputs)
	currentOpenOptions = nil
	
	for _, itemObject in ipairs(stagedItems) do
		local itemData = getItemData(itemObject)
		local row, valueBox, unitBtn = makeReviewRow(self.scrollFrame, itemData)
		table.insert(self.itemInputs, {
			data = itemData,
			valueBox = valueBox,
			unitBtn = unitBtn
		})
	end
	
	self.modal.Visible = true
end

function ProposalReview:Close()
	self.modal.Visible = false
	self.otherId = nil
	currentOpenOptions = nil
	
	for _, child in ipairs(self.scrollFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	table.clear(self.itemInputs)
end

function ProposalReview:GetProposalData()
	local proposal = {}
	for _, input in ipairs(self.itemInputs) do
		local value = tonumber(input.valueBox.Text) or 0
		local unit = input.unitBtn.Text
		
		table.insert(proposal, {
	id = input.data.ID,
	name = input.data.Name,
	rarity = input.data.Rarity or "Unknown", -- ¡Añadido!
	value = value,
	unit = unit
})
	end
	return proposal
end

return ProposalReview
