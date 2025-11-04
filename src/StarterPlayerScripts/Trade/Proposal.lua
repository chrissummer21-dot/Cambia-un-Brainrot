local Components = require(script.Parent.Parent.Components)

local Proposal = {}
Proposal.__index = Proposal

function Proposal.new(parent)
	local self = setmetatable({}, Proposal)
	local modal = Components.MakeModal(parent, "Proposal", 0.48, 0.5)

	local title = Components.MakeLabel("Propuesta para ...", 30)
	title.Font = Enum.Font.GothamBold
	title.Parent = modal

	local items = Components.MakeInput("Brainrots que ofreces (texto, sin links)")
	items.Parent = modal

	local mps = Components.MakeInput("Millones por segundo (mín. 1,000,000)")
	mps.Parent = modal

	local send = Components.MakeButton("Enviar propuesta"); send.Parent = modal
	local cancel = Components.MakeButton("Cancelar"); cancel.Parent = modal

	self.modal = modal
	self.title = title
	self.items = items
	self.mps = mps
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
	self.modal.Visible = true
end

function Proposal:Close()
	self.modal.Visible = false
	self.otherId = nil
end

return Proposal
