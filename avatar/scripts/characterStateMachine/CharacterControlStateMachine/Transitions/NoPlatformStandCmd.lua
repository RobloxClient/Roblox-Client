--[[ NoPlatformStandCmd Transition ]]--
local baseTransition = require(script.Parent.Parent.Parent:WaitForChild("BaseStateMachine"):WaitForChild("BaseTransitionModule"))

local NoPlatformStandCmd = baseTransition:extend()
NoPlatformStandCmd.name = script.Name
NoPlatformStandCmd.destinationName = "Running"
NoPlatformStandCmd.sourceName = "PlatformStanding"
NoPlatformStandCmd.priority = 3

function NoPlatformStandCmd:Test(stateMachine)
	local jumped = stateMachine.context.humanoid.Jump
	return jumped
end

return NoPlatformStandCmd