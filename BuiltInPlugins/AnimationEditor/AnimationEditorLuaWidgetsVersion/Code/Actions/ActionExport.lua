-- singleton (can't be undone/redone)

local FastFlags = require(script.Parent.Parent.FastFlags)

local Export = {}

function Export:execute(Paths)
	-- Update the model to start positions
	local motorOrig = {}
	for part,elem in pairs(Paths.DataModelRig.partList) do
		if (elem.Motor6D ~= nil) then
			elem.Motor6D.C1 = elem.OriginC1
			if not FastFlags:isScrubbingPlayingMatchFlagOn() then
				Paths.DataModelRig:nudgeView()
			end
		end
	end

	local kfsp = game:GetService('KeyframeSequenceProvider')

	local kfs = Paths.DataModelClip:createAnimationFromCurrentData()
	local animID = kfsp:RegisterKeyframeSequence(kfs)
	local dummy = Paths.DataModelRig:getItem().Item.Parent

	local AnimationBlock = dummy:FindFirstChild("AnimSaves")
	if AnimationBlock == nil then
		AnimationBlock = Instance.new('Model')
		AnimationBlock.Name = "AnimSaves"
		AnimationBlock.Parent = dummy
	end

	local Animation = AnimationBlock:FindFirstChild("ExportAnim")
	if Animation == nil then
		Animation = Instance.new('Animation')
		Animation.Name = "ExportAnim"
		Animation.Parent = AnimationBlock
	end
	Animation.AnimationId = animID

	local OldKeyframeSqeuence = Animation:FindFirstChild("Test")
	if OldKeyframeSqeuence ~= nil then
		OldKeyframeSqeuence.Parent = nil
	end

	kfs.Parent = Animation

	local selectionSet = {}
	table.insert(selectionSet, kfs)

	game.Selection:Set(selectionSet)
	wait()
	Paths.Globals.Plugin:SaveSelectedToRoblox()
end

return Export