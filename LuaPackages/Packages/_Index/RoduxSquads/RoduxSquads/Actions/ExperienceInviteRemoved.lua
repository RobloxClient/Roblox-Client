local RoduxSquad = script:FindFirstAncestor("RoduxSquads")
local Packages = RoduxSquad.Parent
local Rodux = require(Packages.Rodux)

return Rodux.makeActionCreator(script.Name, function(inviteId: number)
	return {
		payload = {
			inviteId = inviteId,
		},
	}
end)
