-- Ruta: src/StarterPlayerScripts/Trade/Screens/Instructions.lua
local Components = require(script.Parent.Parent.Components)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Instructions = {}
Instructions.__index = Instructions

-- [CAMBIO 1] Acepta 'toastNotifier' (el objeto Toast) como argumento
function Instructions.new(parent, toastNotifier)
	local self = setmetatable({}, Instructions)
	local modal = Components.MakeModal(parent, "Instructions", 0.5, 0.48)

	-- [CAMBIO 2] Texto de instrucciones actualizado
	local lbl = Components.MakeLabel(
		"Instrucciones:\n1) Graba el trade completo.\n2) Que se vean ambos nombres.\n3) El ProofCode sirve como prueba única de tu trade.\n4) Si hay problema, abre ticket usando este código."
	)
	lbl.Parent = modal

	-- Contenedor para el ProofCode y el botón de Copiar
	local proofFrame = Instance.new("Frame")
	proofFrame.Name = "ProofFrame"
	proofFrame.BackgroundTransparency = 1
	proofFrame.Size = UDim2.new(1, 0, 0, 45)
	proofFrame.Parent = modal
	
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 10)
	layout.Parent = proofFrame

	-- Caja de texto (no editable) para el ProofCode
	local proofBox = Components.MakeInput("P2025-XXXX-XXXX")
	proofBox.Name = "ProofCodeBox"
	proofBox.Size = UDim2.new(0.65, 0, 1, 0)
	
	-- [CAMBIO 3] Propiedades para hacerla NO editable
	proofBox.Active = false
	proofBox.TextEditable = false
	proofBox.ClearTextOnFocus = false
	
	proofBox.Parent = proofFrame
	
	-- Botón para Copiar
	local copyBtn = Components.MakeButton("Copiar")
	copyBtn.Name = "CopyButton"
	copyBtn.Size = UDim2.new(0.25, 0, 1, 0)
	copyBtn.Parent = proofFrame

	-- Botón "Entendido"
	local ok = Components.MakeButton("Entendido"); ok.Parent = modal

	self.modal = modal
	self.okBtn = ok
	self.proofBox = proofBox
	self.copyBtn = copyBtn
	
	-- [CAMBIO 4] Asigna el objeto Toast (en lugar de buscar el Frame)
	self.toastNotifier = toastNotifier
	
	-- Lógica de copiado
	copyBtn.MouseButton1Click:Connect(function()
		local code = self.proofBox.Text
		if code and code ~= "" then
			local success, err = pcall(function()
				game:GetService("UserInputService"):SetClipboardAsync(code)
			end)
			
			-- Esta lógica ahora funcionará porque self.toastNotifier es el objeto correcto
			if success and self.toastNotifier then
				self.toastNotifier:Show("¡ProofCode copiado!", 1.5)
			elseif self.toastNotifier then
				self.toastNotifier:Show("No se pudo copiar (error)", 1.5)
			end
		end
	end)

	return self
end

-- Open ahora acepta el proofCode
function Instructions:Open(proofCode)
	self.proofBox.Text = proofCode or "Error: Sin código"
	self.modal.Visible = true
end

function Instructions:Close()
	self.proofBox.Text = "" -- Limpiar al cerrar
	self.modal.Visible = false
end

return Instructions