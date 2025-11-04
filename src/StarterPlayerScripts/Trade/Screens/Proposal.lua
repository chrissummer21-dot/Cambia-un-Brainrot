local Components = require(script.Parent.Parent.Components)

local Proposal = {}
Proposal.__index = Proposal

function Proposal.new(parent)
	local self = setmetatable({}, Proposal)
	local modal = Components.MakeModal(parent, "Proposal", 0.48, 0.56)

	local title = Components.MakeLabel("Propuesta para ...", 30)
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = modal

	local items = Components.MakeInput("Brainrots que ofreces (texto, sin links)")
	items.Parent = modal

	-- MPS solo enteros
	local mps = Components.MakeInput("Millones por segundo (solo enteros: 1, 2, 3, ...)")
	mps.Parent = modal

	local hint = Components.MakeLabel("<i>Ejemplo: 3 significa 3 MPS de ese brainrot.</i>", 20)
	hint.TextXAlignment = Enum.TextXAlignment.Center
	hint.Parent = modal

	-- Estado de envío/espera
	local stateLabel = Components.MakeLabel("")
	stateLabel.TextXAlignment = Enum.TextXAlignment.Center
	stateLabel.Parent = modal

	local send = Components.MakeButton("Enviar propuesta"); send.Parent = modal
	local cancel = Components.MakeButton("Cancelar");      cancel.Parent = modal

	self.modal = modal
	self.title = title
	self.items = items
	self.mps = mps
	self.hint = hint
	self.stateLabel = stateLabel
	self.sendBtn = send
	self.cancelBtn = cancel
	self.otherId = nil

	return self
end

function Proposal:Open(otherId, otherDisplay)
	self.otherId = otherId
	self.title.Text = ("Propuesta para <b>%s</b>"):format(otherDisplay or "Jugador")
	self.items.Text = ""
	self.mps.Text = ""
	self.stateLabel.Text = ""
	self.sendBtn.Text = "Enviar propuesta"
	self.sendBtn.Active = true
	self.sendBtn.AutoButtonColor = true
	self.items.Active = true
	self.mps.Active = true
	self.modal.Visible = true
end

function Proposal:SetWaiting()
	self.stateLabel.Text = "Propuesta enviada, esperando propuesta del otro jugador…"
	self.sendBtn.Text = "Enviada"
	self.sendBtn.Active = false
	self.sendBtn.AutoButtonColor = false
	self.items.Active = false
	self.mps.Active = false
end

function Proposal:Close()
	self.modal.Visible = false
	self.otherId = nil
end

return Proposal
