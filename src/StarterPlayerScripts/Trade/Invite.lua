local Components = require(script.Parent.Components)

local Invite = {}
Invite.__index = Invite

function Invite.new(parent)
	local self = setmetatable({}, Invite)

	local modal = Components.MakeModal(parent, "Invite", 0.42, 0.34)
	local title = Components.MakeLabel("Confirmar trade", 30); title.Font = Enum.Font.GothamBold; title.Parent = modal
	local msg   = Components.MakeLabel("¿Quieres tradear con ...?"); msg.Parent = modal
	local ok    = Components.MakeButton("Aceptar"); ok.Parent = modal
	local no    = Components.MakeButton("Rechazar"); no.Parent = modal

	self.modal = modal
	self.title = title
	self.msg = msg
	self.okBtn = ok
	self.noBtn = no
	self.otherId = nil

	return self
end

function Invite:Show(otherId, otherDisplay)
	self.otherId = otherId
	self.title.Text = "Confirmar trade"
	self.msg.Text = ("¿Quieres tradear con <b>%s</b>?"):format(otherDisplay or "Jugador")
	self.modal.Visible = true
end

function Invite:Hide()
	self.modal.Visible = false
	self.otherId = nil
end

return Invite
