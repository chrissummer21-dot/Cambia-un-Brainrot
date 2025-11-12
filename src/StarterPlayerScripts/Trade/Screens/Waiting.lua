-- Ruta: src/StarterPlayerScripts/Trade/Screens/Waiting.lua
local Components = require(script.Parent.Parent.Components)
local RunService = game:GetService("RunService")

local Waiting = {}
Waiting.__index = Waiting

-- Función auxiliar para añadir borde negro al texto
local function addTextStroke(guiObject)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5; stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Transparency = 0.4; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = guiObject
	return stroke
end

function Waiting.new(parent)
	local self = setmetatable({}, Waiting)

	local modal = Components.MakeModal(parent, "Waiting", 0.4, 0.25) -- Modal pequeño

	local title = Components.MakeLabel("Propuesta Enviada", 28)
	title.Font = Enum.Font.GothamBold
	addTextStroke(title)
	title.Parent = modal

	local msg = Components.MakeLabel("Esperando la oferta del otro jugador...", 22)
	addTextStroke(msg)
	msg.Parent = modal

	local spinner = Components.MakeLabel("...", 24)
	spinner.Font = Enum.Font.GothamMedium
	addTextStroke(spinner)
	spinner.Parent = modal

	self.modal = modal
	self.msg = msg
	self.spinner = spinner
	self._spinnerConn = nil
	self._spinnerAccum = 0

	modal.Visible = false
	return self
end

function Waiting:_startSpinnerAnim()
	if self._spinnerConn then self._spinnerConn:Disconnect() end
	self._spinnerAccum = 0
	local dots = {".", "..", "...", "...."}
	local index = 1

	self._spinnerConn = RunService.Heartbeat:Connect(function(dt)
		if not self.modal or not self.modal.Visible then return end
		self._spinnerAccum = self._spinnerAccum + dt
		if self._spinnerAccum >= 0.25 then
			self._spinnerAccum = 0
			self.spinner.Text = dots[index]
			index = (index % #dots) + 1
		end
	end)
end

function Waiting:Show(message)
	self.msg.Text = message or "Esperando la oferta del otro jugador..."
	self.modal.Visible = true
	self:_startSpinnerAnim()
end

function Waiting:Hide()
	self.modal.Visible = false
	if self._spinnerConn then
		self._spinnerConn:Disconnect()
		self._spinnerConn = nil
	end
end

return Waiting