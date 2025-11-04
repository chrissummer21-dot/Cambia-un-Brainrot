local Components = require(script.Parent.Parent.Components)

local Summary = {}
Summary.__index = Summary

function Summary.new(parent)
	local self = setmetatable({}, Summary)
	local modal = Components.MakeModal(parent, "Summary", 0.52, 0.56)

	local title = Components.MakeLabel("Resumen del trade", 30)
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = modal

	local a = Components.MakeLabel("Tú: MPS — | Brainrots —")
	a.TextXAlignment = Enum.TextXAlignment.Left
	a.Parent = modal

	local b = Components.MakeLabel("Otro: MPS — | Brainrots —")
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.Parent = modal

	-- Estado/nota (esperas y aceptación del otro)
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
	self.lineA = a
	self.lineB = b
	self.note  = note
	self.warn  = warn
	self.acceptBtn = accept
	self.backBtn   = back
	self.otherId   = nil

	return self
end

function Summary:Open(otherId, aUnits, aItems, bUnits, bItems, warning, youAccepted, partnerAccepted, partnerName)
	self.otherId = otherId
	self.title.Text = "Resumen del trade"

	self.lineA.Text = ("Tú: MPS: %d  |  Brainrots: %s"):format(tonumber(aUnits) or 0, aItems or "")
	self.lineB.Text = ("Otro: MPS: %d  |  Brainrots: %s"):format(tonumber(bUnits) or 0, bItems or "")
	self.warn.Text  = warning or "Confirma solo si estás de acuerdo. Los MPS son enteros."

	-- pinta estado
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
end

return Summary
