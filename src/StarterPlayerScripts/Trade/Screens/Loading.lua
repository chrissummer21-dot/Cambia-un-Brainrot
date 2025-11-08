-- Ruta: src/StarterPlayerScripts/Trade/Screens/Loading.lua
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Components = require(script.Parent.Parent.Components)

local Loading = {}
Loading.__index = Loading

function Loading.new(parent)
	local self = setmetatable({}, Loading)

	-- Modal de fondo
	local modal = Components.MakeModal(parent, "Loading", 0.3, 0.2)
	modal.BackgroundTransparency = 0.15
	modal.BackgroundColor3 = Color3.fromRGB(10, 10, 15)

	-- Bordes redondeados
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = modal

	-- Contorno suave
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = modal

	-- Degradado de fondo
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 40)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 5, 15)),
	})
	gradient.Rotation = 45
	gradient.Parent = modal

	-- Layout vertical centrado
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 6)
	list.Parent = modal

	-- Título
	local title = Components.MakeLabel("Procesando...", 30)
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.TextYAlignment = Enum.TextYAlignment.Center
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.LayoutOrder = 1
	title.Parent = modal

	-- Mensaje
	local msg = Components.MakeLabel("Esperando confirmación del servidor...")
	msg.TextXAlignment = Enum.TextXAlignment.Center
	msg.TextYAlignment = Enum.TextYAlignment.Center
	msg.TextColor3 = Color3.fromRGB(220, 220, 220)
	msg.LayoutOrder = 2
	msg.Parent = modal

	-- Línea de progreso / spinner de texto
	local spinner = Components.MakeLabel("...", 24)
	spinner.Font = Enum.Font.GothamMedium
	spinner.TextXAlignment = Enum.TextXAlignment.Center
	spinner.TextYAlignment = Enum.TextYAlignment.Center
	spinner.TextColor3 = Color3.fromRGB(150, 200, 255)
	spinner.LayoutOrder = 3
	spinner.Parent = modal

	-- Pequeño subtítulo opcional
	local hint = Components.MakeLabel("No cierres esta ventana, estamos verificando tu trade.")
	hint.TextXAlignment = Enum.TextXAlignment.Center
	hint.TextYAlignment = Enum.TextYAlignment.Center
	hint.TextColor3 = Color3.fromRGB(180, 180, 180)
	hint.TextSize = 14
	hint.LayoutOrder = 4
	hint.Parent = modal

	self.modal = modal
	self.title = title
	self.msg = msg
	self.spinner = spinner

	self._spinnerConn = nil
	self._spinnerAccum = 0
	self._pulseTween = nil

	modal.Visible = false

	return self
end

-- Animación del texto del spinner ("." -> ".." -> "..." -> "....")
function Loading:_startSpinnerAnim()
	if self._spinnerConn then
		self._spinnerConn:Disconnect()
	end

	self._spinnerAccum = 0
	local dots = {".", "..", "...", "...."}
	local index = 1

	self._spinnerConn = RunService.Heartbeat:Connect(function(dt)
		if not self.modal or not self.modal.Visible then
			return
		end

		self._spinnerAccum = self._spinnerAccum + dt
		if self._spinnerAccum >= 0.25 then
			self._spinnerAccum = 0
			self.spinner.Text = dots[index]
			index += 1
			if index > #dots then
				index = 1
			end
		end
	end)
end

-- Pulso suave del modal (respiración)
function Loading:_startPulse()
	if self._pulseTween then
		self._pulseTween:Cancel()
	end

	local info = TweenInfo.new(
		0.8,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.InOut,
		-1,       -- repeatCount (infinito)
		true      -- reverses
	)

	self._pulseTween = TweenService:Create(
		self.modal,
		info,
		{ BackgroundTransparency = 0.25 }
	)

	self._pulseTween:Play()
end

function Loading:_stopAnimations()
	if self._spinnerConn then
		self._spinnerConn:Disconnect()
		self._spinnerConn = nil
	end

	if self._pulseTween then
		self._pulseTween:Cancel()
		self._pulseTween = nil
	end
end

function Loading:Show(message)
	self.msg.Text = message or "Esperando confirmación..."
	self.modal.Visible = true

	-- Animaciones
	self:_startSpinnerAnim()
	self:_startPulse()
end

function Loading:Hide()
	self.modal.Visible = false
	self:_stopAnimations()
end

return Loading
