local Components = require(script.Parent.Parent.Components)

local Instructions = {}
Instructions.__index = Instructions

function Instructions.new(parent)
	local self = setmetatable({}, Instructions)
	local modal = Components.MakeModal(parent, "Instructions", 0.5, 0.42)

	local lbl = Components.MakeLabel(
		"Instrucciones:\n1) Graba el trade completo.\n2) Que se vean ambos nombres.\n3) Luego verás un ProofCode (cuando conectemos backend).\n4) Si hay problema, abre ticket."
	)
	lbl.Parent = modal

	local ok = Components.MakeButton("Entendido"); ok.Parent = modal

	self.modal = modal
	self.okBtn = ok

	return self
end

function Instructions:Open()
	self.modal.Visible = true
end

function Instructions:Close()
	self.modal.Visible = false
end

return Instructions
