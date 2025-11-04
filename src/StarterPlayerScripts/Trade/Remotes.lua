local RS = game:GetService("ReplicatedStorage")

local Remotes = {}

function Remotes.Get()
	local folder = RS:WaitForChild("TradeRemotes", 10)
	assert(folder, "TradeRemotes no apareció")

	local function wait(name)
		local re = folder:WaitForChild(name, 10)
		assert(re, name .. " no apareció")
		return re
	end

	return {
		REQ     = wait("RequestTrade"),
		RESP    = wait("RespondTrade"),
		SUBMIT  = wait("SubmitProposal"),
		CONFIRM = wait("ConfirmSummary"),
		CANCEL  = wait("CancelTrade"),
        SYNC    = wait("SyncState"), 
	}
end

return Remotes
