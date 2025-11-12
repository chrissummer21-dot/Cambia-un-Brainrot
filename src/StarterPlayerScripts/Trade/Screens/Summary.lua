-- Ruta: src/StarterPlayerScripts/Trade/Screens/Summary.lua
local Components = require(script.Parent.Parent.Components)
local BrainrotDatabase = require(game:GetService("ReplicatedStorage"):WaitForChild("BrainrotDatabase"))

local Summary = {}
Summary.__index = Summary

local PLACEHOLDER_IMAGE_ID = "512833360"
local GREEN = Color3.fromRGB(70, 220, 70)
local RED = Color3.fromRGB(220, 70, 70)

-- Función auxiliar para crear filas de resumen
local function addTextStroke(guiObject)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5; stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Transparency = 0.4; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = guiObject
	return stroke
end

local function makeSummaryRow(parent, itemData)
	local rowFrame = Instance.new("Frame")
	rowFrame.Name = itemData.id
	rowFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	rowFrame.Size = UDim2.new(1, 0, 0, 50) -- Fila más delgada
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
	image.Size = UDim2.fromOffset(40, 40)
	local dbEntry = nil
	local imageId = nil
	local category = itemData.rarity
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
	image.ScaleType = Enum.ScaleType.Fit
	image.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	image.LayoutOrder = 1
	image.Parent = rowFrame
	Instance.new("UICorner", image).CornerRadius = UDim.new(0, 6)

	-- 2. Nombre
	local nameLabel = Components.MakeLabel(itemData.name, 18)
	nameLabel.Size = UDim2.new(0.4, 0, 0.8, 0)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	addTextStroke(nameLabel)
	nameLabel.LayoutOrder = 2
	nameLabel.Parent = rowFrame

	-- 3. Dinero y Múltiplo
	local valueString
	if itemData.value == math.floor(itemData.value) then
		valueString = tostring(itemData.value)
	else
		valueString = string.format("%.1f", itemData.value)
	end
	local valueText = string.format("%s %s", valueString, itemData.unit)
	local valueLabel = Components.MakeLabel(valueText, 20)
	valueLabel.Size = UDim2.new(0.35, 0, 0.8, 0)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	addTextStroke(valueLabel)
	valueLabel.LayoutOrder = 3
	valueLabel.Parent = rowFrame

	return rowFrame
end


-- ===================================================
-- [¡ACTUALIZADO!] Nueva estructura de 'new'
-- ===================================================
function Summary.new(parent)
	local self = setmetatable({}, Summary)
	local modal = Components.MakeModal(parent, "Summary", 0.6, 0.7)

	local title = Components.MakeLabel("Resumen del trade", 30)
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = modal

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "ListsFrame"
	mainFrame.BackgroundTransparency = 1
	mainFrame.Size = UDim2.new(1, 0, 0.5, 0)
	mainFrame.Parent = modal
	
	local mainLayout = Instance.new("UIListLayout")
	mainLayout.FillDirection = Enum.FillDirection.Horizontal
	mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	mainLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	mainLayout.Padding = UDim.new(0, 10)
	mainLayout.Parent = mainFrame

	-- Columna "TÚ"
	local aFrame = Instance.new("Frame")
	aFrame.Name = "TuOferta"
	aFrame.BackgroundTransparency = 1
	aFrame.Size = UDim2.new(0.48, 0, 1, 0)
	aFrame.Parent = mainFrame
	local aLayout = Instance.new("UIListLayout")
	aLayout.FillDirection = Enum.FillDirection.Vertical
	aLayout.Padding = UDim.new(0, 6)
	aLayout.Parent = aFrame
	
	local aTitle = Components.MakeLabel("Tu Oferta", 24)
	aTitle.TextXAlignment = Enum.TextXAlignment.Left
	addTextStroke(aTitle)
	aTitle.Parent = aFrame
	
	-- [¡NUEVO!] Etiqueta de Intermediario (Tú)
	local aIntermediaryLabel = Components.MakeLabel("Intermediario Solicitado: No", 18)
	aIntermediaryLabel.TextColor3 = RED
	aIntermediaryLabel.TextXAlignment = Enum.TextXAlignment.Left
	aIntermediaryLabel.Parent = aFrame
	
	local aScroll = Instance.new("ScrollingFrame")
	aScroll.Name = "A_Scroll"
	aScroll.Size = UDim2.new(1, 0, 0.8, 0)
	aScroll.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	aScroll.BackgroundTransparency = 0.5
	aScroll.BorderSizePixel = 0
	aScroll.ScrollBarThickness = 6
	aScroll.Parent = aFrame
	local aScrollLayout = Instance.new("UIListLayout")
	aScrollLayout.Padding = UDim.new(0, 6)
	aScrollLayout.Parent = aScroll
	Instance.new("UICorner", aScroll).CornerRadius = UDim.new(0, 8)
	local aPadding = Instance.new("UIPadding", aScroll)
	aPadding.PaddingTop = UDim.new(0, 6); aPadding.PaddingBottom = UDim.new(0, 6)
	aPadding.PaddingLeft = UDim.new(0, 6); aPadding.PaddingRight = UDim.new(0, 6)

	-- Columna "OTRO"
	local bFrame = Instance.new("Frame")
	bFrame.Name = "OtraOferta"
	bFrame.BackgroundTransparency = 1
	bFrame.Size = UDim2.new(0.48, 0, 1, 0)
	bFrame.Parent = mainFrame
	local bLayout = Instance.new("UIListLayout")
	bLayout.FillDirection = Enum.FillDirection.Vertical
	bLayout.Padding = UDim.new(0, 6)
	bLayout.Parent = bFrame
	
	local bTitle = Components.MakeLabel("Su Oferta", 24)
	bTitle.TextXAlignment = Enum.TextXAlignment.Left
	addTextStroke(bTitle)
	bTitle.Parent = bFrame
	
	-- [¡NUEVO!] Etiqueta de Intermediario (Otro)
	local bIntermediaryLabel = Components.MakeLabel("Intermediario Solicitado: No", 18)
	bIntermediaryLabel.TextColor3 = RED
	bIntermediaryLabel.TextXAlignment = Enum.TextXAlignment.Left
	bIntermediaryLabel.Parent = bFrame
	
	local bScroll = Instance.new("ScrollingFrame")
	bScroll.Name = "B_Scroll"
	bScroll.Size = UDim2.new(1, 0, 0.8, 0)
	bScroll.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	bScroll.BackgroundTransparency = 0.5
	bScroll.BorderSizePixel = 0
	bScroll.ScrollBarThickness = 6
	bScroll.Parent = bFrame
	local bScrollLayout = Instance.new("UIListLayout")
	bScrollLayout.Padding = UDim.new(0, 6)
	bScrollLayout.Parent = bScroll
	Instance.new("UICorner", bScroll).CornerRadius = UDim.new(0, 8)
	local bPadding = Instance.new("UIPadding", bScroll)
	bPadding.PaddingTop = UDim.new(0, 6); bPadding.PaddingBottom = UDim.new(0, 6)
	bPadding.PaddingLeft = UDim.new(0, 6); bPadding.PaddingRight = UDim.new(0, 6)

	-- (Resto de los elementos)
	local note = Components.MakeLabel("")
	note.TextXAlignment = Enum.TextXAlignment.Center
	note.Parent = modal

	local warn = Components.MakeLabel("Advertencia…")
	warn.TextColor3 = Color3.fromRGB(255,220,120)
	warn.TextXAlignment = Enum.TextXAlignment.Left
	warn.Parent = modal

	local accept = Components.MakeButton("Aceptar resumen"); accept.Parent = modal
	local back   = Components.MakeButton("Cancelar");        back.Parent   = modal

	self.modal = modal
	self.title = title
	self.note  = note
	self.warn  = warn
	self.acceptBtn = accept
	self.backBtn   = back
	self.otherId   = nil
	
	self.aListContainer = aScroll
	self.bListContainer = bScroll
	-- [¡NUEVO!] Guardar referencias a las etiquetas
	self.aIntermediaryLabel = aIntermediaryLabel
	self.bIntermediaryLabel = bIntermediaryLabel

	return self
end

-- ===================================================
-- [¡ACTUALIZADO!] 'Open' ahora acepta los booleanos
-- ===================================================
function Summary:Open(otherId, aItemsList, bItemsList, warning, youAccepted, partnerAccepted, partnerName, aWantsIntermediary, bWantsIntermediary)
	self.otherId = otherId
	self.title.Text = "Resumen del trade"
	self.warn.Text  = warning or "Confirma solo si estás de acuerdo."

	-- Limpiar listas
	for _, child in ipairs(self.aListContainer:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	for _, child in ipairs(self.bListContainer:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	
	-- Llenar tu lista (aItemsList)
	if aItemsList and type(aItemsList) == "table" then
		for _, itemData in ipairs(aItemsList) do
			makeSummaryRow(self.aListContainer, itemData)
		end
	end
	
	-- Llenar la lista del otro (bItemsList)
	if bItemsList and type(bItemsList) == "table" then
		for _, itemData in ipairs(bItemsList) do
			makeSummaryRow(self.bListContainer, itemData)
		end
	end
	
	-- [¡NUEVO!] Actualizar las etiquetas de intermediario
	self.aIntermediaryLabel.Text = aWantsIntermediary and "Intermediario Solicitado: Si" or "Intermediario Solicitado: No"
	self.aIntermediaryLabel.TextColor3 = aWantsIntermediary and GREEN or RED
	
	self.bIntermediaryLabel.Text = bWantsIntermediary and "Intermediario Solicitado: Si" or "Intermediario Solicitado: No"
	self.bIntermediaryLabel.TextColor3 = bWantsIntermediary and GREEN or RED

	-- Pinta el estado de los botones
	self:PaintStatus(youAccepted, partnerAccepted, partnerName)

	self.modal.Visible = true
end

function Summary:PaintStatus(youAccepted, partnerAccepted, partnerName)
	if youAccepted and not partnerAccepted then
		self.acceptBtn.Text = "Esperando al otro jugador…"
		self.acceptBtn.Active = false
		self.acceptBtn.AutoButtonColor = false
		self.note.Text = string.format("%s aún no confirma el resumen.", partnerName or "El otro jugador")
	elseif partnerAccepted and not youAccepted then
		self.acceptBtn.Text = "Aceptar resumen"
		self.acceptBtn.Active = true
		self.acceptBtn.AutoButtonColor = true
		self.note.Text = string.format("%s ya aceptó el resumen.", partnerName or "El otro jugador")
	elseif youAccepted and partnerAccepted then
		self.note.Text = "Ambos aceptaron. Finalizando…"
	else
		self.acceptBtn.Text = "Aceptar resumen"
		self.acceptBtn.Active = true
		self.acceptBtn.AutoButtonColor = true
		self.note.Text = ""
	end
end

function Summary:LockWaiting()
	self.acceptBtn.Text = "Esperando al otro jugador…"
	self.acceptBtn.Active = false
	self.acceptBtn.AutoButtonColor = false
end

function Summary:Close()
	self.modal.Visible = false
	self.otherId = nil
	self.note.Text = ""
	
	-- Limpiar listas al cerrar
	for _, child in ipairs(self.aListContainer:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	for _, child in ipairs(self.bListContainer:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	
	-- Resetear etiquetas
	self.aIntermediaryLabel.Text = ""
	self.bIntermediaryLabel.Text = ""
end

return Summary