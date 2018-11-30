local Plugin = script.Parent.Parent.Parent

local Libs = Plugin.Libs
local Cryo = require(Libs.Cryo)
local Rodux = require(Libs.Rodux)

local DebugFlags = require(Plugin.Core.Util.DebugFlags)
local Immutable = require(Plugin.Core.Util.Immutable)

local GetAssets = require(Plugin.Core.Actions.GetAssets)
local PostInsertAsset = require(Plugin.Core.Actions.PostInsertAsset)
local PostUnvote = require(Plugin.Core.Actions.PostUnvote)
local PostVote = require(Plugin.Core.Actions.PostVote)

local FFlagStudioLuaWidgetToolboxV2 = settings():GetFFlag("StudioLuaWidgetToolboxV2")

local function handleVoting(state, assetId, voteDirection)
	local userVote = nil
	if voteDirection then
		if voteDirection > 0 then
			userVote = true
		elseif voteDirection < 0 then
			userVote = false
		end
	end

	if FFlagStudioLuaWidgetToolboxV2 then
		return Cryo.Dictionary.join(state, {
			[assetId] = Cryo.Dictionary.join(state[assetId], {
				HasVoted = voteDirection ~= 0,
				UserVote = userVote,
			}),
		})
	else
		return Immutable.Set(state, assetId, Immutable.JoinDictionaries(state[assetId], {
			HasVoted = voteDirection ~= 0,
			UserVote = userVote
		}))
	end
end

local function setShowVoteButtons(state, assetId)
	if FFlagStudioLuaWidgetToolboxV2 then
		return Cryo.Dictionary.join(state, {
			[assetId] = Cryo.Dictionary.join(state[assetId], {
				showVoteButtons = true,
				CanVote = true,
			}),
		})
	else
		return Immutable.Set(state, assetId, Immutable.JoinDictionaries(state[assetId], {
			showVoteButtons = true,
			CanVote = true,
		}))
	end
end

if FFlagStudioLuaWidgetToolboxV2 then
	return Rodux.createReducer({
	}, {
		[GetAssets.name] = function(state, action)
			local newVoting = {}
			for _, asset in ipairs(action.assets) do
				newVoting[asset.Asset.Id] = asset.Voting
			end
			return Cryo.Dictionary.join(state, newVoting)
		end,

		[PostInsertAsset.name] = function(state, action)
			if action.insertResponse == "true" then
				return setShowVoteButtons(state, action.assetId)
			else
				-- TODO CLIDEVSRVS-1595: Error handling
				if DebugFlags.shouldDebugWarnings() then
					warn("Got false response from PostInsertAsset")
				end
			end
		end,

		[PostVote.name] = function(state, action)
			if action.voteResponse.Success then
				return handleVoting(state, action.assetId, action.userVote and 1 or -1)
			else
				-- TODO CLIDEVSRVS-1595: Error handling
				if DebugFlags.shouldDebugWarnings() then
					warn("Voting unsucessful")
				end
			end
		end,

		[PostUnvote.name] = function(state, action)
			if action.unvoteResponse.Success then
				return handleVoting(state, action.assetId, 0)
			else
				-- TODO CLIDEVSRVS-1595: Error handling
				if DebugFlags.shouldDebugWarnings() then
					warn("Unvoting unsucessful")
				end
			end
		end,
	})
else
	return function(state, action)
		state = state or {}

		if action.type == GetAssets.name then
			local newVoting = {}
			for _, asset in ipairs(action.assets) do
				newVoting[asset.Asset.Id] = asset.Voting
			end
			return Immutable.JoinDictionaries(state, newVoting)

		elseif action.type == PostInsertAsset.name then
			if action.insertResponse == "true" then
				return setShowVoteButtons(state, action.assetId)
			else
				-- TODO CLIDEVSRVS-1595: Error handling
				if DebugFlags.shouldDebugWarnings() then
					warn("Got false response from PostInsertAsset")
				end
			end

		elseif action.type == PostVote.name then
			if action.voteResponse.Success then
				return handleVoting(state, action.assetId, action.userVote and 1 or -1)
			else
				-- TODO CLIDEVSRVS-1595: Error handling
				if DebugFlags.shouldDebugWarnings() then
					warn("Voting unsucessful")
				end
			end

		elseif action.type == PostUnvote.name then
			if action.unvoteResponse.Success then
				return handleVoting(state, action.assetId, 0)
			else
				-- TODO CLIDEVSRVS-1595: Error handling
				if DebugFlags.shouldDebugWarnings() then
					warn("Unvoting unsucessful")
				end
			end
		end

		return state
	end
end
