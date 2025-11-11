-- SessionManager.lua: Autoridad del estado y sync hacia clientes
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SYNC = RS:WaitForChild("TradeRemotes"):WaitForChild("SyncState")

local SessionManager = {}
SessionManager.__index = SessionManager

function SessionManager.new(zonePart, constants, storage)
	local self = setmetatable({}, SessionManager)
	self.Zone = zonePart
	self.Shared = constants
    self.Storage = storage  
	self.inZone = {}     -- [player] = true
	self.sessions = {}   -- [key] = {a, b, state, inviteAccepted = {}, proposals = {}, summaryAccepted = {}}
	self.engaged = {}    -- [player] = true si está en sesión viva
	return self
end

local function keyFor(aId, bId)
	return (aId < bId) and (("%d-%d"):format(aId, bId)) or (("%d-%d"):format(bId, aId))
end

local function pretty(p) return string.format("%s (@%s)", p.DisplayName, p.Name) end

function SessionManager:BothInZone(a, b)
	return self.inZone[a] and self.inZone[b]
end

function SessionManager:IsBusy(p) return self.engaged[p] == true end

function SessionManager:_syncInvite(s)
	-- Empuja a ambos el estado INVITE: así el modal permanece abierto
	local payloadA = {
		state = "INVITE",
		partnerId = s.b.UserId,
		partnerName = pretty(s.b),
		youAccepted = s.inviteAccepted[s.a] == true,
		partnerAccepted = s.inviteAccepted[s.b] == true,
	}
	local payloadB = {
		state = "INVITE",
		partnerId = s.a.UserId,
		partnerName = pretty(s.a),
		youAccepted = s.inviteAccepted[s.b] == true,
		partnerAccepted = s.inviteAccepted[s.a] == true,
	}
	SYNC:FireClient(s.a, payloadA)
	SYNC:FireClient(s.b, payloadB)
end

function SessionManager:_syncProposal(s)
	local payload = { state = "PROPOSAL", partnerA = pretty(s.a), partnerB = pretty(s.b) }
	SYNC:FireClient(s.a, payload)
	SYNC:FireClient(s.b, payload)
end

function SessionManager:_syncSummary(s)
	local sumA = s.proposals[s.a]; local sumB = s.proposals[s.b]
	local warning = ("Solo trades de mínimo %d unidad(es). Al confirmar, ambos se comprometen a cumplir."):format(self.Shared.MIN_UNITS)

	local youA = s.summaryAccepted[s.a] == true
	local youB = s.summaryAccepted[s.b] == true

	-- payload para A
	SYNC:FireClient(s.a, {
		state = "SUMMARY",
		a = { items = sumA.items, mps = sumA.mps },
		b = { items = sumB.items, mps = sumB.mps },
		warning = warning,
		youAccepted = youA,
		partnerAccepted = youB,
		partnerName = string.format("%s (@%s)", s.b.DisplayName, s.b.Name),
	})

	-- payload para B
	SYNC:FireClient(s.b, {
		state = "SUMMARY",
		a = { items = sumB.items, mps = sumB.mps }, -- invertido para B
		b = { items = sumA.items, mps = sumA.mps },
		warning = warning,
		youAccepted = youB,
		partnerAccepted = youA,
		partnerName = string.format("%s (@%s)", s.a.DisplayName, s.a.Name),
	})
end

function SessionManager:_syncLoading(s)
    local payload = { state = "LOADING" }
    SYNC:FireClient(s.a, payload)
    SYNC:FireClient(s.b, payload)
end

function SessionManager:_syncPromised(s, proofCode)
    local payload = { state = "PROMISED", proofCode = proofCode or s.proofCode }
    SYNC:FireClient(s.a, payload)
    SYNC:FireClient(s.b, payload)
end

function SessionManager:CreateSession(a, b)
	local k = keyFor(a.UserId, b.UserId)
	if self.sessions[k] then return end
	local s = {
		a = a, b = b,
		state = "INVITE",
		inviteAccepted = {},
		proposals = {},
		summaryAccepted = {},
	}
	self.sessions[k] = s
	self.engaged[a] = true; self.engaged[b] = true
	self:_syncInvite(s)
	return s
end

function SessionManager:TryMatch(plr)
	if not self.inZone[plr] or self:IsBusy(plr) then return end
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= plr and self.inZone[other] and not self:IsBusy(other) then
			return self:CreateSession(plr, other)
		end
	end
end

function SessionManager:OnInviteResponse(plr, other, accept)
	local k = keyFor(plr.UserId, other.UserId)
	local s = self.sessions[k]
	if not s or s.state ~= "INVITE" then return end
	if not self:BothInZone(plr, other) then
		self:CancelSession(s, "Alguien salió de la zona.")
		return
	end

	if not accept then
		self:CancelSession(s, pretty(plr).." rechazó el trade.")
		return
	end

	s.inviteAccepted[plr] = true
	if s.inviteAccepted[s.a] and s.inviteAccepted[s.b] then
		s.state = "PROPOSAL"
		self:_syncProposal(s)
	else
		self:_syncInvite(s) -- re-sincroniza para que ambos vean "youAccepted/partnerAccepted"
	end
end

function SessionManager:OnProposal(plr, other, items, mps)
	local k = keyFor(plr.UserId, other.UserId)
	local s = self.sessions[k]
	if not s or s.state ~= "PROPOSAL" then return end
	if not self:BothInZone(plr, other) then
		self:CancelSession(s, "Alguien salió de la zona.")
		return
	end

	s.proposals[plr] = { items = items, mps = mps }
	if s.proposals[s.a] and s.proposals[s.b] then
		s.state = "SUMMARY"
		self:_syncSummary(s)
	else
		-- podrías enviar un "peerProposed" si quieres feedback incremental
	end
end

function SessionManager:OnSummaryConfirm(plr, other, accept)
    local k = keyFor(plr.UserId, other.UserId)
    local s = self.sessions[k]
    if not s or s.state ~= "SUMMARY" then return end
    if not self:BothInZone(plr, other) then
        self:CancelSession(s, "Alguien salió de la zona.")
        return
    end
    if not accept then
        self:CancelSession(s, "Cancelado por un jugador.")
        return
    end

    s.summaryAccepted[plr] = true

    if s.summaryAccepted[s.a] and s.summaryAccepted[s.b] then
        -- [CAMBIO 1] Ambos aceptaron. Manda "LOADING" a los dos.
        s.state = "LOADING"
        self:_syncLoading(s)

        -- Da un respiro para que el remoto llegue a los clientes
        task.wait(0.2) 

        -- >>> CREA EL REGISTRO EN DATASTORE + WEBHOOKS <<<
        -- (Esta parte es lenta y ahora ocurre MIENTRAS ambos ven la carga)
        local okRec, proof = nil, nil
        if self.Storage then
            local rec, err = self.Storage:CreatePromised(s.a, s.proposals[s.a], s.b, s.proposals[s.b])
            if rec then
                s.proofCode = rec.proofCode
                proof = rec.proofCode
            else
                warn("CreatePromised failed: ", err)
                -- Si el guardado falla, cancela la sesión para todos
                self:CancelSession(s, "Error del servidor al guardar el trade.")
                return
            end
        end

        -- [CAMBIO 2] Ahora que terminó lo lento, manda el estado final.
        s.state = "PROMISED"
        self:_syncPromised(s, proof)
    else
        -- [CAMBIO 3] Solo uno aceptó. Re-sincroniza el resumen.
        -- Esto le mostrará al otro jugador que "Tú ya aceptaste".
        self:_syncSummary(s) 
    end
end

function SessionManager:CancelSession(s, reason)
	-- Libera y notifica via SYNC cancel
	local payload = { state = "CANCELED", reason = reason or "Cancelado." }
	SYNC:FireClient(s.a, payload); SYNC:FireClient(s.b, payload)
	self.engaged[s.a] = nil; self.engaged[s.b] = nil
	self.sessions[keyFor(s.a.UserId, s.b.UserId)] = nil
end

function SessionManager:OnTouched(plr)
	self.inZone[plr] = true
	self:TryMatch(plr)
end

function SessionManager:OnTouchEnded(plr)
	self.inZone[plr] = nil
	-- si sale, cancela sesiones no prometidas
	for k, s in pairs(self.sessions) do
		if s.a == plr or s.b == plr then
			if s.state ~= "PROMISED" then
				self:CancelSession(s, "Alguien salió de la zona.")
			end
		end
	end
end

function SessionManager:OnLeaving(plr)
	self.inZone[plr] = nil
	self.engaged[plr] = nil
	for k, s in pairs(self.sessions) do
		if s.a == plr or s.b == plr then
			self:CancelSession(s, "Jugador salió del juego.")
		end
	end
end

return SessionManager
