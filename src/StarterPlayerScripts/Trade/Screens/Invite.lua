local Components = require(script.Parent.Parent.Components)

local Invite = {}
Invite.__index = Invite

local function makeBadge(text, color)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = color or Color3.fromRGB(60, 60, 60)
	f.BackgroundTransparency = 0.1
	f.Size = UDim2.fromScale(0, 0)
	f.AutomaticSize = Enum.AutomaticSize.XY
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

	local pad = Instance.new("UIPadding", f)
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)

	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text or "PENDIENTE"
	l.TextScaled = true
	l.Font = Enum.Font.GothamMedium
	l.TextColor3 = Color3.fromRGB(255,255,255)
	l.Parent = f
	local c = Instance.new("UITextSizeConstraint", l)
	c.MaxTextSize = 22
	l.Size = UDim2.fromScale(1,1)

	return f, l
end

function Invite.new(parent)
	local self = setmetatable({}, Invite)

	local modal = Components.MakeModal(parent, "Invite", 0.42, 0.38)

	local title = Components.MakeLabel("Confirmar trade", 30)
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = modal

	local msg   = Components.MakeLabel("¿Quieres tradear con ...?")
	msg.TextXAlignment = Enum.TextXAlignment.Center
	msg.Parent = modal

	-- Row de badges
	local statusRow = Instance.new("Frame")
	statusRow.BackgroundTransparency = 1
	statusRow.Size = UDim2.fromScale(1, 0)
	statusRow.AutomaticSize = Enum.AutomaticSize.Y
	statusRow.Parent = modal

	local statusLayout = Instance.new("UIListLayout", statusRow)
	statusLayout.FillDirection = Enum.FillDirection.Horizontal
	statusLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	statusLayout.Padding = UDim.new(0, 10)

	local youBadge, youLabel     = makeBadge("Tú: PENDIENTE")
	youBadge.Parent = statusRow
	local otherBadge, otherLabel = makeBadge("Otro: PENDIENTE")
	otherBadge.Parent = statusRow

	-- Nota dinámica (aquí ponemos "X aceptó tradear contigo")
	local note = Components.MakeLabel("")
	note.TextXAlignment = Enum.TextXAlignment.Center
	note.Parent = modal

	local ok    = Components.MakeButton("Aceptar");   ok.Parent = modal
	local no    = Components.MakeButton("Rechazar");  no.Parent = modal

	self.modal      = modal
	self.title      = title
	self.msg        = msg
	self.note       = note
	self.okBtn      = ok
	self.noBtn      = no
	self.youBadge   = youBadge
	self.youLabel   = youLabel
	self.otherBadge = otherBadge
	self.otherLabel = otherLabel
	self.otherId    = nil

	return self
end

function Invite:Show(otherId, otherDisplay)
	self.otherId = otherId
	self.title.Text = "Confirmar trade"
	self.msg.Text = ("¿Quieres tradear con <b>%s</b>?"):format(otherDisplay or "Jugador")
	self.note.Text = "" -- limpia la nota
	self.modal.Visible = true
end

function Invite:Hide()
	self.modal.Visible = false
	self.otherId = nil
	self.note.Text = ""
end

local GREEN = Color3.fromRGB(60,170,60)
local GRAY  = Color3.fromRGB(60,60,60)

function Invite:SetStatuses(youAccepted, partnerAccepted)
	self.youLabel.Text   = youAccepted     and "Tú: ACEPTADO"   or "Tú: PENDIENTE"
	self.otherLabel.Text = partnerAccepted and "Otro: ACEPTADO" or "Otro: PENDIENTE"
	self.youBadge.BackgroundColor3   = youAccepted     and GREEN or GRAY
	self.otherBadge.BackgroundColor3 = partnerAccepted and GREEN or GRAY
end

function Invite:SetPartnerAcceptedNote(partnerPrettyName)
	self.note.Text = string.format("<b>%s</b> aceptó tradear contigo.", partnerPrettyName or "El jugador")
end

function Invite:LockWaiting()
	self.okBtn.Text = "Esperando al otro jugador…"
	self.okBtn.Active = false
	self.okBtn.AutoButtonColor = false
	self.noBtn.Active = false
	self.noBtn.AutoButtonColor = false
end

function Invite:Unlock()
	self.okBtn.Text = "Aceptar"
	self.okBtn.Active = true
	self.okBtn.AutoButtonColor = true
	self.noBtn.Active = true
	self.noBtn.AutoButtonColor = true
end

return Invite
