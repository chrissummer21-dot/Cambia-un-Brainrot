local Components = require(script.Parent.Parent.Components)

local Summary = {}
Summary.__index = Summary

function Summary.new(parent)
	local self = setmetatable({}, Summary)
	local modal = Components.MakeModal(parent, "Summary", 0.52, 0.52)

	local title = Components.MakeLabel("Resumen del trade", 30)
	title.Font = Enum.Font.GothamBold
	title.Parent = modal

	local a = Components.MakeLabel("Tú: ...");   a.Parent = modal
	local b = Components.MakeLabel("Otro: ..."); b.Parent = modal

	local warn = Components.MakeLabel("Advertencia...")
	warn.TextColor3 = Color3.fromRGB(255,220,120)
	warn.Parent = modal

	local accept = Components.MakeButton("Aceptar resumen"); accept.Parent = modal
	local back   = Components.MakeButton("Cancelar");        back.Parent   = modal

	self.modal = modal
	self.title = title
	self.lineA = a
	self.lineB = b
	self.warn  = warn
	self.acceptBtn = accept
	self.backBtn   = back
	self.otherId   = nil

	return self
end

function Summary:Open(otherId, aUnits, aItems, bUnits, bItems, warning)
	self.otherId = otherId
	self.title.Text = "Resumen del trade"
	self.lineA.Text = ("Tú: %s | %s"):format(tostring(aUnits), aItems)
	self.lineB.Text = ("Otro: %s | %s"):format(tostring(bUnits), bItems)
	self.warn.Text  = warning or ""
	self.modal.Visible = true
end

function Summary:Close()
	self.modal.Visible = false
	self.otherId = nil
end

return Summary
