local Components = require(script.Parent.Parent.Components)

local Invite = {}
Invite.__index = Invite

function Invite.new(parent)
	local self = setmetatable({}, Invite)

	local modal = Components.MakeModal(parent, "Invite", 0.42, 0.34)
	local title = Components.MakeLabel("Confirmar trade", 30)
	title.Font = Enum.Font.GothamBold
	title.Parent = modal

	local msg   = Components.MakeLabel("¿Quieres tradear con ...?")
	msg.Parent = modal

	-- NUEVO: línea de estatus “Tú / Otro”
	local status = Components.MakeLabel("Tú: PENDIENTE | Otro: PENDIENTE", 24)
	status.Parent = modal

	local ok    = Components.MakeButton("Aceptar");   ok.Parent = modal
	local no    = Components.MakeButton("Rechazar");  no.Parent = modal

	self.modal   = modal
	self.title   = title
	self.msg     = msg
	self.status  = status
	self.okBtn   = ok
	self.noBtn   = no
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

-- NUEVO: pinta el estado de ambos
function Invite:SetStatuses(youAccepted, partnerAccepted)
	local function badge(ok)
		return ok and "<font color=\"#7CFC00\">ACEPTADO</font>" or "PENDIENTE"
	end
	self.status.Text = ("Tú: %s  |  Otro: %s"):format(badge(youAccepted), badge(partnerAccepted))
end

-- NUEVO: bloquea botones y cambia texto del aceptar
function Invite:LockWaiting()
	self.okBtn.Text = "Esperando al otro jugador…"
	self.okBtn.Active = false
	self.okBtn.AutoButtonColor = false
	self.noBtn.Active = false
	self.noBtn.AutoButtonColor = false
end

-- NUEVO: vuelve a habilitar botones (si aún no aceptaste)
function Invite:Unlock()
	self.okBtn.Text = "Aceptar"
	self.okBtn.Active = true
	self.okBtn.AutoButtonColor = true
	self.noBtn.Active = true
	self.noBtn.AutoButtonColor = true
end

return Invite
