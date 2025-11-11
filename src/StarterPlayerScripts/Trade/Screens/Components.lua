-- Ruta: src/StarterPlayerScripts/Trade/Screens/ItemSelector.lua
local Components = require(script.Parent.Parent.Components)
local BrainrotDatabase = require(game:GetService("ReplicatedStorage"):WaitForChild("BrainrotDatabase"))

local ItemSelector = {}
ItemSelector.__index = ItemSelector

local PLACEHOLDER_IMAGE_ID = "512833360" 
local CUSTOM_RARITIES = {"God", "OG", "Secret"} 

-- Función auxiliar para añadir borde negro al texto
local function addTextStroke(guiObject)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5; stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Transparency = 0.4; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = guiObject
	return stroke
end

-- Función auxiliar para crear el dropdown de rareza
local function makeRarityDropdown(parent)
	local dropdownFrame = Instance.new("Frame")
	dropdownFrame.Size = UDim2.new(0.4, 0, 1, 0)
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
	optionsFrame.Position = UDim2.fromScale(0, 1) 
	optionsFrame.Size = UDim2.new(1, 0, 0, 0) 
	optionsFrame.AutomaticSize = Enum.AutomaticSize.Y
	optionsFrame.Visible = false
	optionsFrame.ZIndex = 3
	optionsFrame.Parent = dropdownBtn
	Instance.new("UICorner", optionsFrame).CornerRadius = UDim.new(0, 6)
	Instance.new("UIListLayout", optionsFrame).Padding = UDim.new(0, 4)
	
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
	item.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	item.Size = UDim2.fromOffset(100, 115)
	
	local imageId = itemData.Image or PLACEHOLDER_IMAGE_ID
	item.Image = "rbxassetid://" .. imageId
	item.ScaleType = Enum.ScaleType.Fit
	item.Parent = parent

	Instance.new("UICorner", item).CornerRadius = UDim.new(0, 8)
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 170, 255)
	stroke.Thickness = 3
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Enabled = false
	stroke.Parent = item

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0.25, 0)
	label.Position = UDim2.fromScale(0, 0.75)
	label.Font = Enum.Font.GothamMedium
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Text = itemData.Name
	label.Parent = item
	addTextStroke(label)
	
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(Color3.new(0,0,0), Color3.new(0,0,0))
	grad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 0) })
	grad.Rotation = 90
	grad.Parent = label

	return item, stroke
end


function ItemSelector.new(parent)
	local self = setmetatable({}, ItemSelector)
	
	-- [ARREGLO] Usamos los valores de escala que queremos (70% ancho, 75% alto)
	local modal = Components.MakeModal(parent, "ItemSelector", 0.7, 0.75)
	modal.Visible = false
	
	local modalLayout = modal:FindFirstChildOfClass("UIListLayout")
	modalLayout.Padding = UDim.new(0, 8)
	modalLayout.SortOrder = Enum.SortOrder.LayoutOrder -- Ya estaba en Components, pero lo re-aseguramos

	-- [ARREGLO] Título con LayoutOrder = 1
	local title = Components.MakeLabel("Selecciona los Brainrots a ofrecer", 30)
	title.Font = Enum.Font.GothamBold
	title.AutomaticSize = Enum.AutomaticSize.None
	title.Size = UDim2.new(1, 0, 0, 30) -- Tamaño fijo para el título
	title.LayoutOrder = 1 -- 1ro
	title.Parent = modal
	addTextStroke(title)

	-- Frame principal para layout [Filtros | Cuadrícula]
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.BackgroundTransparency = 1
	-- [ARREGLO] Usar escala y dejar que el layout vertical lo posicione
	mainFrame.Size = UDim2.new(1, 0, 0.5, 0) 
	mainFrame.LayoutOrder = 2 -- 2do
	mainFrame.Parent = modal
	
	local mainLayout = Instance.new("UIListLayout")
	mainLayout.FillDirection = Enum.FillDirection.Horizontal
	mainLayout.Padding = UDim.new(0, 10)
	mainLayout.Parent = mainFrame
	
	-- Panel de Filtros (Izquierda)
	local filterPanel = Instance.new("Frame")
	filterPanel.Name = "FilterPanel"
	filterPanel.BackgroundTransparency = 1
	filterPanel.Size = UDim2.new(0.2, 0, 1, 0)
	filterPanel.Parent = mainFrame
	
	local filterLayout = Instance.new("UIListLayout")
	filterLayout.FillDirection = Enum.FillDirection.Vertical
	filterLayout.Padding = UDim.new(0, 8)
	filterLayout.Parent = filterPanel
	
	self.filterButtons = {
		God = Components.MakeButton("God"),
		OG = Components.MakeButton("OG"),
		Secret = Components.MakeButton("Secret"),
	}
	
	for _, btn in pairs(self.filterButtons) do
		addTextStroke(btn)
		btn.Parent = filterPanel
	end
	
	-- Panel de Cuadrícula (Derecha)
	local gridPanel = Instance.new("Frame")
	gridPanel.Name = "GridPanel"
	gridPanel.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	gridPanel.BackgroundTransparency = 0.5
	gridPanel.Size = UDim2.new(0.78, 0, 1, 0)
	gridPanel.Parent = mainFrame
	Instance.new("UICorner", gridPanel).CornerRadius = UDim.new(0, 8)

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "GridContainer"
	scrollFrame.Size = UDim2.fromScale(1, 1)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.Parent = gridPanel
	
	local gridPadding = Instance.new("UIPadding", scrollFrame)
	gridPadding.PaddingTop = UDim.new(0, 10)
	gridPadding.PaddingBottom = UDim.new(0, 10)
	gridPadding.PaddingLeft = UDim.new(0, 10)
	gridPadding.PaddingRight = UDim.new(0, 10)

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(100, 115)
	grid.CellPadding = UDim2.fromOffset(8, 8)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.Parent = scrollFrame

	-- Sección para Ítems Custom
	local customTitle = Components.MakeLabel("<i>O añade uno que no esté en la lista:</i>", 20)
	-- [ARREGLO] Quitar tamaño fijo
	customTitle.LayoutOrder = 3 -- 3ro
	customTitle.Parent = modal
	
	local customFrame = Instance.new("Frame")
	customFrame.Name = "CustomFrame"
	customFrame.BackgroundTransparency = 1
	customFrame.Size = UDim2.new(1, 0, 0, 40) -- Tamaño fijo para la fila custom
	customFrame.LayoutOrder = 4 -- 4to
	customFrame.Parent = modal

	local customLayout = Instance.new("UIListLayout")
	customLayout.FillDirection = Enum.FillDirection.Horizontal
	customLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	customLayout.Padding = UDim.new(0, 10)
	customLayout.SortOrder = Enum.SortOrder.LayoutOrder
	customLayout.Parent = customFrame

	-- [ARREGLO] Campo para el nombre (1ro)
	self.customNameInput = Components.MakeInput("Nombre del Brainrot")
	self.customNameInput.Size = UDim2.new(0.55, 0, 1, 0)
	self.customNameInput.LayoutOrder = 1
	self.customNameInput.Parent = customFrame

	-- [ARREGLO] Dropdown para la rareza (2do)
	local rarityFrame, rarityBtn = makeRarityDropdown(customFrame)
	rarityFrame.LayoutOrder = 2
	self.customRarityBtn = rarityBtn 

	-- Barra de botones inferior
	local bottomBar = Instance.new("Frame")
	bottomBar.Name = "BottomBar"
	bottomBar.BackgroundTransparency = 1
	bottomBar.Size = UDim2.new(1, 0, 0, 40) -- Tamaño fijo
	bottomBar.LayoutOrder = 5 -- 5to
	bottomBar.Parent = modal
	
	local bottomLayout = Instance.new("UIListLayout")
	bottomLayout.FillDirection = Enum.FillDirection.Horizontal
	bottomLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	bottomLayout.Padding = UDim.new(0, 10)
	bottomLayout.SortOrder = Enum.SortOrder.LayoutOrder 
	bottomLayout.Parent = bottomBar
	
	self.counterLabel = Components.MakeLabel("Añadidos: 0", 24)
	self.counterLabel.Size = UDim2.new(0.2, 0, 1, 0)
	self.counterLabel.TextXAlignment = Enum.TextXAlignment.Left
	addTextStroke(self.counterLabel)
	self.counterLabel.LayoutOrder = 1
	self.counterLabel.Parent = bottomBar 
	
	self.clearBtn = Components.MakeButton("Borrar Selección")
	self.clearBtn.Size = UDim2.new(0.4, 0, 1, 0)
	addTextStroke(self.clearBtn)
	self.clearBtn.LayoutOrder = 2
	self.clearBtn.Parent = bottomBar 
	
	self.addBtn = Components.MakeButton("Añadir")
	self.addBtn.Size = UDim2.new(0.3, 0, 1, 0)
	self.addBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 70) 
	addTextStroke(self.addBtn)
	self.addBtn.LayoutOrder = 3
	self.addBtn.Parent = bottomBar 
	
	self.acceptBtn = Components.MakeButton("Listo!")
	self.acceptBtn.Size = UDim2.new(1, 0, 0, 40) -- Tamaño fijo
	self.acceptBtn.LayoutOrder = 6 -- 6to (Último)
	addTextStroke(self.acceptBtn)
	self.acceptBtn.Parent = modal

	-- [ARREGLO] Asignar el título al objeto 'self' para que init.client.lua pueda leerlo
	self.modal = modal
	self.title = title 
	self.scrollFrame = scrollFrame
	self.grid = grid
	self.otherId = nil
	
	self.stagedItems = {} 
	self.currentItem = nil 
	self.itemInstances = {} 
	self.itemConnections = {} 
	
	self.addBtn.MouseButton1Click:Connect(function() self:OnAdd() end)
	self.clearBtn.MouseButton1Click:Connect(function() self:OnClear() end)
	self.filterButtons.God.MouseButton1Click:Connect(function() self:PopulateGrid("God") end)
	self.filterButtons.OG.MouseButton1Click:Connect(function() self:PopulateGrid("OG") end)
	self.filterButtons.Secret.MouseButton1Click:Connect(function() self:PopulateGrid("Secret") end)

	return self
end

-- Limpia y rellena la cuadrícula con ítems de una categoría
function ItemSelector:PopulateGrid(category)
	for _, child in ipairs(self.scrollFrame:GetChildren()) do
		if child:IsA("ImageButton") then child:Destroy() end
	end
	
	for _, conn in pairs(self.itemConnections) do conn:Disconnect() end
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

-- Lógica al hacer clic en un ítem de la cuadrícula
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

-- Lógica del botón "Añadir"
function ItemSelector:OnAdd()
	local customName = self.customNameInput.Text
	
	if self.currentItem then
		table.insert(self.stagedItems, {
			type = "Database",
			id = self.currentItem
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
			rarity = rarity
		})
		self.customNameInput.Text = ""
		self.customRarityBtn.Text = CUSTOM_RARITIES[1]
		
	else
		return 
	end
	
	self.counterLabel.Text = "Añadidos: " .. #self.stagedItems
end

-- Lógica del botón "Borrar Selección"
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
	
	for _, conn in pairs(self.itemConnections) do conn:Disconnect() end
	table.clear(self.itemInstances)
	table.clear(self.itemConnections)
end

function ItemSelector:GetStagedItems()
	return self.stagedItems
end

return ItemSelector