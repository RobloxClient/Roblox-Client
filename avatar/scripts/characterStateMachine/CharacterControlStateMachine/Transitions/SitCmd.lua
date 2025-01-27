--[[ SitCmd Transition ]]--
local baseTransition = require(script.Parent.Parent.Parent:WaitForChild("BaseStateMachine"):WaitForChild("BaseTransitionModule"))

local SitCmd = baseTransition:extend()
SitCmd.name = script.Name
SitCmd.destinationName = "Seated"
SitCmd.sourceName = "Climbing, FreeFall, FallingDown, GettingUp, Landed, Running, Jumping, Swimming"
SitCmd.priority = 3

function SitCmd:Test(stateMachine)
	local humanoid = stateMachine.context.humanoid
	local seated = humanoid.Sit and humanoid.SeatPart ~= nil
	return seated
end

return SitCmd
