--[[
	Prompts the user to select a FBX Animation to import, then
	imports to a KeyframeSequence from the FBX animation.
]]

local Plugin = script.Parent.Parent.Parent.Parent
local Constants = require(Plugin.SrcDeprecated.Util.Constants)
local RigUtils = require(Plugin.SrcDeprecated.Util.RigUtils)
local LoadAnimationData = require(Plugin.SrcDeprecated.Thunks.LoadAnimationData)
local SetIsDirty = require(Plugin.SrcDeprecated.Actions.SetIsDirty)

local UseCustomFPS = require(Plugin.LuaFlags.GetFFlagAnimEditorUseCustomFPS)

return function(plugin)
	return function(store)
		local state = store:getState()
		local rootInstance = state.Status.RootInstance
		if not rootInstance then
			return
		end

		local success, result = pcall(function()
			return plugin:ImportFbxAnimation(rootInstance)
		end)

		if success then
			local newData
			if UseCustomFPS() then
				local frameRate = RigUtils.calculateFrameRate(result)
				newData = RigUtils.fromRigAnimation(result, frameRate)
			else
				newData = RigUtils.fromRigAnimation(result, Constants.DEFAULT_FRAMERATE)
			end
			newData.Metadata.Name = Constants.DEFAULT_IMPORTED_NAME
			store:dispatch(LoadAnimationData(newData))
			store:dispatch(SetIsDirty(false))

			if result then
				result:Destroy()
			end

			state.Analytics:onImportFbxAnimation()
		else
			warn(result)
		end
	end
end