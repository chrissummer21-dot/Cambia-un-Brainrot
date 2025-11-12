-- Ruta: src/StarterPlayerScripts/Trade/Screens/ItemSelector.lua
local Components = require(script.Parent.Parent.Components)
local BrainrotDatabase = require(game:GetService("ReplicatedStorage"):WaitForChild("BrainrotDatabase"))

local ItemSelector = {}
ItemSelector.__index = ItemSelector

local PLACEHOLDER_IMAGE_ID = "512833360"
-- Orden: God, Secret, OG
local CUSTOM_RARITIES = { "God", "Secret", "OG" }

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

-- Función auxiliar para crear el dropdown de rareza
local function makeRarityDropdown(parent)
	local dropdownFrame = Instance.new("Frame")
	dropdownFrame.Size = UDim2.new(0.3, 0, 1, 0)
	dropdownFrame.BackgroundTransparency = 1
	dropdownFrame.Parent = parent

	local dropdownBtn = Components.MakeButton(CUSTOM_RARITIES[1])
	dropdownBtn.Size = UDim2.fromScale(1, 1)
	addTextStroke(dropdownBtn)
	dropdownBtn.Parent = dropdownFrame

	local optionsFrame = Instance.new("Frame")
	optionsFrame.Name = "Options"
	optionsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	optionsFrame.BorderSizePixel = 0
	-- anclado abajo del botón y crece hacia arriba
	optionsFrame.AnchorPoint = Vector2.new(0, 1)
	optionsFrame.Position = UDim2.new(0, 0, 0, -4)
	optionsFrame.Size = UDim2.new(1, 0, 0, 0)
	optionsFrame.AutomaticSize = Enum.AutomaticSize.Y
	optionsFrame.Visible = false
	optionsFrame.ZIndex = 3
	optionsFrame.Parent = dropdownBtn

	Instance.new("UICorner", optionsFrame).CornerRadius = UDim.new(0, 6)

	local optLayout = Instance.new("UIListLayout")
	optLayout.FillDirection = Enum.FillDirection.Vertical
	optLayout.Padding = UDim.new(0, 4)
	optLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	optLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	optLayout.Parent = optionsFrame

	for _, rarity in ipairs(CUSTOM_RARITIES) do
		local optionBtn = Components.MakeButton(rarity)
		optionBtn.Size = UDim2.new(1, 0, 0, 30)
		optionBtn.Parent = optionsFrame

		optionBtn.MouseButton1Click:Connect(function()
			dropdownBtn.Text = rarity
			optionsFrame.Visible = false
		end)
	end

	dropdownBtn.MouseButton1Click:Connect(function()
		optionsFrame.Visible = not optionsFrame.Visible
	end)

	return dropdownFrame, dropdownBtn
end

-- Función auxiliar para crear cada ítem en la cuadrícula
local function makeGridItem(parent, itemData)
	local item = Instance.new("ImageButton")
	item.Name = itemData.Name
	item.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	item.AutoButtonColor = true
	item.Size = UDim2.fromScale(1, 0) -- tamaño lo controla el UIGridLayout
	item.Image = "rbxassetid://" .. (itemData.Image or PLACEHOLDER_IMAGE_ID)
	item.ScaleType = Enum.ScaleType.Fit
	item.Parent = parent

	Instance.new("UICorner", item).CornerRadius = UDim.new(0, 10)

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 170, 255)
	stroke.Thickness = 3
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Enabled = false
	stroke.Parent = item

	-- etiqueta con nombre (bold, blanco, contorno negro)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -8, 0.25, 0)
	label.Position = UDim2.fromScale(0, 0.75)
	label.AnchorPoint = Vector2.new(0, 0)
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.TextWrapped = true
	label.Text = itemData.Name
	label.Parent = item
	addTextStroke(label)

	return item, stroke
end

function ItemSelector.new(parent)
	local self = setmetatable({}, ItemSelector)

	-- Modal centrado y 100% relativo (sin tamaños mínimos fijos)
	local modal = Components.MakeModal(parent, "ItemSelector", 0.9, 0.9)
	modal.Visible = false

	local modalPadding = Instance.new("UIPadding")
	modalPadding.PaddingTop = UDim.new(0, 10)
	modalPadding.PaddingBottom = UDim.new(0, 10)
	modalPadding.PaddingLeft = UDim.new(0, 14)
	modalPadding.PaddingRight = UDim.new(0, 14)
	modalPadding.Parent = modal

	local modalLayout = modal:FindFirstChildOfClass("UIListLayout")
	if not modalLayout then
		modalLayout = Instance.new("UIListLayout")
		modalLayout.Parent = modal
	end
	modalLayout.Padding = UDim.new(0, 6)
	modalLayout.SortOrder = Enum.SortOrder.LayoutOrder
	modalLayout.FillDirection = Enum.FillDirection.Vertical
	modalLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	modalLayout.VerticalAlignment = Enum.VerticalAlignment.Top

	-- Título (12% de alto del modal)
	local title = Components.MakeLabel("Selecciona los Brainrots a ofrecer", 30)
	title.Font = Enum.Font.GothamBold
	title.Size = UDim2.new(1, 0, 0.12, 0)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.TextYAlignment = Enum.TextYAlignment.Center
	title.TextWrapped = true
	title.LayoutOrder = 1
	title.Parent = modal
	addTextStroke(title)

	-- Frame principal [Filtros | Grid] (55% del alto)
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.BackgroundTransparency = 1
	mainFrame.Size = UDim2.new(1, 0, 0.55, 0)
	mainFrame.LayoutOrder = 2
	mainFrame.Parent = modal

	local mainLayout = Instance.new("UIListLayout")
	mainLayout.FillDirection = Enum.FillDirection.Horizontal
	mainLayout.Padding = UDim.new(0, 10)
	mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	mainLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	mainLayout.Parent = mainFrame

	local mainPadding = Instance.new("UIPadding")
	mainPadding.PaddingTop = UDim.new(0, 2)
	mainPadding.PaddingBottom = UDim.new(0, 2)
	mainPadding.PaddingLeft = UDim.new(0, 2)
	mainPadding.PaddingRight = UDim.new(0, 2)
	mainPadding.Parent = mainFrame

	-- Panel de filtros (columna izquierda)
	local filterPanel = Instance.new("Frame")
	filterPanel.Name = "FilterPanel"
	filterPanel.BackgroundTransparency = 1
	filterPanel.Size = UDim2.new(0.24, 0, 1, 0)
	filterPanel.Parent = mainFrame

	local filterPadding = Instance.new("UIPadding")
	filterPadding.PaddingTop = UDim.new(0, 4)
	filterPadding.PaddingBottom = UDim.new(0, 4)
	filterPadding.PaddingLeft = UDim.new(0, 2)
	filterPadding.PaddingRight = UDim.new(0, 2)
	filterPadding.Parent = filterPanel

	local filterLayout = Instance.new("UIListLayout")
	filterLayout.FillDirection = Enum.FillDirection.Vertical
	filterLayout.Padding = UDim.new(0, 6)
	filterLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	filterLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	filterLayout.Parent = filterPanel

	local filterTitle = Components.MakeLabel("Filtrar por rareza", 18)
	filterTitle.Size = UDim2.new(1, 0, 0, 22)
	filterTitle.TextXAlignment = Enum.TextXAlignment.Left
	filterTitle.TextYAlignment = Enum.TextYAlignment.Center
	filterTitle.TextTransparency = 0.05
	addTextStroke(filterTitle)
	filterTitle.Parent = filterPanel

	self.filterButtons = {}
	for _, rarity in ipairs(CUSTOM_RARITIES) do
		local btn = Components.MakeButton(rarity)
		btn.Size = UDim2.new(1, 0, 0, 30)
		addTextStroke(btn)
		btn.Parent = filterPanel
		self.filterButtons[rarity] = btn
	end

	-- Panel de cuadrícula (derecha)
	local gridPanel = Instance.new("Frame")
	gridPanel.Name = "GridPanel"
	gridPanel.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	gridPanel.BackgroundTransparency = 0.2
	gridPanel.Size = UDim2.new(0.74, 0, 1, 0)
	gridPanel.Parent = mainFrame

	Instance.new("UICorner", gridPanel).CornerRadius = UDim.new(0, 10)

	local gridStroke = Instance.new("UIStroke")
	gridStroke.Color = Color3.fromRGB(60, 60, 60)
	gridStroke.Thickness = 1
	gridStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	gridStroke.Parent = gridPanel

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "GridContainer"
	scrollFrame.Size = UDim2.fromScale(1, 1)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.Parent = gridPanel

	local gridPadding = Instance.new("UIPadding")
	gridPadding.PaddingTop = UDim.new(0, 10)
	gridPadding.PaddingBottom = UDim.new(0, 10)
	gridPadding.PaddingLeft = UDim.new(0, 10)
	gridPadding.PaddingRight = UDim.new(0, 10)
	gridPadding.Parent = scrollFrame

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.3, -8, 0, 140) -- alto fijo cómodo, scroll para el resto
	grid.CellPadding = UDim2.fromOffset(8, 8)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.VerticalAlignment = Enum.VerticalAlignment.Top
	grid.Parent = scrollFrame

	-- Sección para ítems custom (8% del alto)
	local customTitle = Components.MakeLabel("<i>O añade uno que no esté en la lista:</i>", 20)
	customTitle.Size = UDim2.new(1, 0, 0.08, 0)
	customTitle.TextXAlignment = Enum.TextXAlignment.Left
	customTitle.TextYAlignment = Enum.TextYAlignment.Center
	customTitle.TextWrapped = true
	customTitle.LayoutOrder = 3
	customTitle.Parent = modal

	local customFrame = Instance.new("Frame")
	customFrame.Name = "CustomFrame"
	customFrame.BackgroundTransparency = 1
	customFrame.Size = UDim2.new(1, 0, 0.1, 0)
	customFrame.LayoutOrder = 4
	customFrame.Parent = modal

	local customPadding = Instance.new("UIPadding")
	customPadding.PaddingTop = UDim.new(0, 2)
	customPadding.PaddingBottom = UDim.new(0, 2)
	customPadding.PaddingLeft = UDim.new(0, 4)
	customPadding.PaddingRight = UDim.new(0, 4)
	customPadding.Parent = customFrame

	local customLayout = Instance.new("UIListLayout")
	customLayout.FillDirection = Enum.FillDirection.Horizontal
	customLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	customLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	customLayout.Padding = UDim.new(0, 10)
	customLayout.SortOrder = Enum.SortOrder.LayoutOrder
	customLayout.Parent = customFrame

	self.customNameInput = Components.MakeInput("Nombre del Brainrot")
	self.customNameInput.Size = UDim2.new(0.6, 0, 1, 0)
	self.customNameInput.LayoutOrder = 1
	self.customNameInput.Parent = customFrame

	local rarityFrame, rarityBtn = makeRarityDropdown(customFrame)
	rarityFrame.LayoutOrder = 2
	self.customRarityBtn = rarityBtn

	-- Barra inferior (15% del alto)
	local bottomBar = Instance.new("Frame")
	bottomBar.Name = "BottomBar"
	bottomBar.BackgroundTransparency = 1
	bottomBar.Size = UDim2.new(1, 0, 0.15, 0)
	bottomBar.LayoutOrder = 5
	bottomBar.Parent = modal

	local bottomPadding = Instance.new("UIPadding")
	bottomPadding.PaddingLeft = UDim.new(0, 4)
	bottomPadding.PaddingRight = UDim.new(0, 4)
	bottomPadding.Parent = bottomBar

	local bottomLayout = Instance.new("UIListLayout")
	bottomLayout.FillDirection = Enum.FillDirection.Horizontal
	bottomLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	bottomLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	bottomLayout.Padding = UDim.new(0, 10)
	bottomLayout.SortOrder = Enum.SortOrder.LayoutOrder
	bottomLayout.Parent = bottomBar

	self.counterLabel = Components.MakeLabel("Añadidos: 0", 24)
	self.counterLabel.Size = UDim2.new(0.2, 0, 1, 0)
	self.counterLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.counterLabel.TextYAlignment = Enum.TextYAlignment.Center
	self.counterLabel.TextWrapped = true
	addTextStroke(self.counterLabel)
	self.counterLabel.LayoutOrder = 1
	self.counterLabel.Parent = bottomBar

	self.clearBtn = Components.MakeButton("Borrar selección")
	self.clearBtn.Size = UDim2.new(0.25, 0, 1, 0)
	self.clearBtn.BackgroundColor3 = Color3.fromRGB(160, 40, 40) -- rojo
	addTextStroke(self.clearBtn)
	self.clearBtn.LayoutOrder = 2
	self.clearBtn.Parent = bottomBar

	self.addBtn = Components.MakeButton("Añadir")
	self.addBtn.Size = UDim2.new(0.25, 0, 1, 0)
	self.addBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 70) -- verde
	addTextStroke(self.addBtn)
	self.addBtn.LayoutOrder = 3
	self.addBtn.Parent = bottomBar

	self.acceptBtn = Components.MakeButton("¡Listo!")
	self.acceptBtn.Size = UDim2.new(0.25, 0, 1, 0)
	self.acceptBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 70) -- verde
	addTextStroke(self.acceptBtn)
	self.acceptBtn.LayoutOrder = 4
	self.acceptBtn.Parent = bottomBar

	self.modal = modal
	self.title = title
	self.scrollFrame = scrollFrame
	self.grid = grid
	self.currentRarityCategory = "God" -- Añadir esto (default al abrir)
	self.otherId = nil

	self.stagedItems = {}
	self.currentItem = nil
	self.itemInstances = {}
	self.itemConnections = {}

	self.addBtn.MouseButton1Click:Connect(function()
		self:OnAdd()
	end)
	self.clearBtn.MouseButton1Click:Connect(function()
		self:OnClear()
	end)

	self.filterButtons["God"].MouseButton1Click:Connect(function()
		self:PopulateGrid("God")
	end)
	self.filterButtons["Secret"].MouseButton1Click:Connect(function()
		self:PopulateGrid("Secret")
	end)
	self.filterButtons["OG"].MouseButton1Click:Connect(function()
		self:PopulateGrid("OG")
	end)

	return self
end

-- Limpia y rellena la cuadrícula con ítems de una categoría
function ItemSelector:PopulateGrid(category)
	self.currentRarityCategory = category -- Añadir esta línea
	for _, child in ipairs(self.scrollFrame:GetChildren()) do
		if child:IsA("ImageButton") then
			child:Destroy()
		end
	end

	for _, conn in pairs(self.itemConnections) do
		conn:Disconnect()
	end
	table.clear(self.itemInstances)
	table.clear(self.itemConnections)
	self.currentItem = nil

	local itemsToShow = BrainrotDatabase[category] or {}

	for _, itemData in ipairs(itemsToShow) do
		local itemBtn, itemStroke = makeGridItem(self.scrollFrame, itemData)
		self.itemInstances[itemData.ID] = { btn = itemBtn, stroke = itemStroke }

		local conn = itemBtn.MouseButton1Click:Connect(function()
			self:OnItemClick(itemData.ID)
		end)
		table.insert(self.itemConnections, conn)
	end
end

function ItemSelector:OnItemClick(itemID)
	if self.currentItem and self.itemInstances[self.currentItem] then
		self.itemInstances[self.currentItem].stroke.Enabled = false
	end
	self.currentItem = itemID
	if self.itemInstances[self.currentItem] then
		self.itemInstances[self.currentItem].stroke.Enabled = true
	end
	self.customNameInput.Text = ""
end

function ItemSelector:OnAdd()
	local customName = self.customNameInput.Text

	if self.currentItem then
		table.insert(self.stagedItems, {
			type = "Database",
			id = self.currentItem,
			rarity = self.currentRarityCategory -- ¡Añadido!
		})
		if self.itemInstances[self.currentItem] then
			self.itemInstances[self.currentItem].stroke.Enabled = false
		end
		self.currentItem = nil
	elseif customName and #customName > 2 then
		local rarity = self.customRarityBtn.Text
		table.insert(self.stagedItems, {
			type = "Custom",
			name = customName,
			rarity = rarity,
		})
		self.customNameInput.Text = ""
		self.customRarityBtn.Text = CUSTOM_RARITIES[1]
	else
		return
	end

	self.counterLabel.Text = "Añadidos: " .. #self.stagedItems
end

function ItemSelector:OnClear()
	table.clear(self.stagedItems)
	self.counterLabel.Text = "Añadidos: 0"

	if self.currentItem and self.itemInstances[self.currentItem] then
		self.itemInstances[self.currentItem].stroke.Enabled = false
	end
	self.currentItem = nil

	self.customNameInput.Text = ""
	self.customRarityBtn.Text = CUSTOM_RARITIES[1]
end

function ItemSelector:Open(otherId, otherDisplay)
	self.otherId = otherId
	self.title.Text = ("Ofrecer a <b>%s</b>"):format(otherDisplay or "Jugador")

	self:OnClear()
	self:PopulateGrid("God")

	self.modal.Visible = true
end

function ItemSelector:Close()
	self.modal.Visible = false
	self.otherId = nil
	self:OnClear()

	for _, child in ipairs(self.scrollFrame:GetChildren()) do
		if child:IsA("ImageButton") then
			child:Destroy()
		end
	end

	for _, conn in pairs(self.itemConnections) do
		conn:Disconnect()
	end
	table.clear(self.itemInstances)
	table.clear(self.itemConnections)
end

function ItemSelector:GetStagedItems()
	return self.stagedItems
end

return ItemSelector
