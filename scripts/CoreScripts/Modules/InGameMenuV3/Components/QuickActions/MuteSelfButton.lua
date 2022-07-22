local CorePackages = game:GetService("CorePackages")
local Players = game:GetService("Players")

local t = require(CorePackages.Packages.t)
local UIBlox = require(CorePackages.UIBlox)
local IconButton = UIBlox.App.Button.IconButton
local CoreGui = game:GetService("CoreGui")
local RobloxGui = CoreGui:WaitForChild("RobloxGui")

local InGameMenuDependencies = require(CorePackages.InGameMenuDependencies)
local Roact = InGameMenuDependencies.Roact
local RoactRodux = InGameMenuDependencies.RoactRodux

local InGameMenu = script.Parent.Parent.Parent
local SetQuickActionsTooltip = require(InGameMenu.Actions.SetQuickActionsTooltip)
local withLocalization = require(InGameMenu.Localization.withLocalization)
local Constants = require(InGameMenu.Resources.Constants)
local SendAnalytics = require(InGameMenu.Utility.SendAnalytics)
local ExperienceMenuABTestManager = require(InGameMenu.ExperienceMenuABTestManager)

local VoiceChatServiceManager = require(RobloxGui.Modules.VoiceChat.VoiceChatServiceManager).default
local VoiceConstants = require(CorePackages.AppTempCommon.VoiceChat.Constants)
local VoiceIndicator = require(RobloxGui.Modules.VoiceChat.Components.VoiceIndicator)
local GetFFlagEnableVoiceChatManualReconnect = require(RobloxGui.Modules.Flags.GetFFlagEnableVoiceChatManualReconnect)
local IsMenuCsatEnabled = require(InGameMenu.Flags.IsMenuCsatEnabled)

local MuteSelfButton = Roact.PureComponent:extend("MuteSelfButton")

MuteSelfButton.validateProps = t.interface({
	layoutOrder = t.integer,
	backgroundColor = t.optional(t.string),
	backgroundTransparency = t.optional(t.number),
})

function MuteSelfButton:init()
	self:setState({
		selfMuted = VoiceChatServiceManager.localMuted or true,
	})
	VoiceChatServiceManager.muteChanged.Event:Connect(function(muted)
		self:setState({
			selfMuted = muted,
		})
	end)

	self.onActivated = function()
		if GetFFlagEnableVoiceChatManualReconnect() and self.props.voiceState == VoiceConstants.VOICE_STATE.ERROR then
			VoiceChatServiceManager:RejoinPreviousChannel()
		else
			VoiceChatServiceManager:ToggleMic()
			if self.state.selfMuted then
				self.props.setQuickActionsTooltip(self.unmuteSelf or "Unmute Self")
			else
				self.props.setQuickActionsTooltip(self.muteSelf or "Mute Self")
			end

			SendAnalytics(
				Constants.AnalyticsMenuActionName,
				self.state.selfMuted and Constants.AnalyticsUnmuteSelf or Constants.AnalyticsMuteSelf,
				{ source = Constants.AnalyticsQuickActionsMenuSource }
			)

			self:setState({
				selfMuted = not self.state.selfMuted,
			})
		end

		if IsMenuCsatEnabled() then
			ExperienceMenuABTestManager.default:setCSATQualification()
		end
	end
end

function MuteSelfButton:render()
	return withLocalization({
		muteSelf = "CoreScripts.InGameMenu.QuickActions.MuteSelf",
		unmuteSelf = "CoreScripts.InGameMenu.QuickActions.UnmuteSelf",
	})(function(localized)
		self.muteSelf = localized.muteSelf
		self.unmuteSelf = localized.unmuteSelf
		return Roact.createElement(IconButton, {
			backgroundTransparency = self.props.backgroundTransparency,
			backgroundColor = self.props.backgroundColor,
			showBackground = true,
			layoutOrder = self.props.layoutOrder,
			onActivated = self.onActivated,
		}, {
			VoiceIndicator = Roact.createElement(VoiceIndicator, {
				userId = tostring(Players.LocalPlayer.UserId),
				hideOnError = false,
				iconStyle = "MicLight",
				size = UDim2.fromOffset(36, 36),
				onClicked = self.onActivated,
				iconTransparency = self.props.backgroundTransparency,
			}),
		})
	end)
end

local function mapDispatchToProps(dispatch)
	return {
		setQuickActionsTooltip = function(text)
			dispatch(SetQuickActionsTooltip(text))
		end,
	}
end

return RoactRodux.connect(nil, mapDispatchToProps)(MuteSelfButton)
