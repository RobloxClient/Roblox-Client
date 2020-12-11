--[[
	Represents the top entry in a TrackList.

	Props:
		int LayoutOrder = The order this element displays in a UIListLayout.
		string Name = The name to display in this track.
		list<string> UnusedTracks = Tracks that are available to add but have not
			been added.

		function OnTrackAdded(track) = A callback for when the user clicks the
			add button and then selects a track to add to the TrackList.
]]

local Plugin = script.Parent.Parent.Parent.Parent
local Roact = require(Plugin.Roact)

local Theme = require(Plugin.SrcDeprecated.Context.Theme)
local withTheme = Theme.withTheme

local IKController = require(Plugin.SrcDeprecated.Components.IK.IKController)

local TrackListEntry = require(Plugin.SrcDeprecated.Components.TrackList.TrackListEntry)
local AddTrackButton = require(Plugin.SrcDeprecated.Components.TrackList.AddTrackButton)
local Constants = require(Plugin.SrcDeprecated.Util.Constants)
local isEmpty = require(Plugin.SrcDeprecated.Util.isEmpty)
local StringUtils = require(Plugin.SrcDeprecated.Util.StringUtils)

local SummaryTrack = Roact.PureComponent:extend("SummaryTrack")

local PADDING = 12

function SummaryTrack:init()
	self.onTrackAdded = function(instance, track)
		if self.props.OnTrackAdded then
			self.props.OnTrackAdded(instance, track)
		end
	end
end

function SummaryTrack:render()
	return withTheme(function(theme)
		local props = self.props
		local name = props.Name
		local layoutOrder = props.LayoutOrder
		local tracks = props.UnusedTracks

		local trackTheme = theme.trackTheme

		local textWidth = StringUtils.getTextWidth(name, trackTheme.textSize, theme.font)

		return Roact.createElement(TrackListEntry, {
			Height = Constants.SUMMARY_TRACK_HEIGHT,
			Indent = 1,
			LayoutOrder = layoutOrder,
			Primary = true,
		}, {
			NameLabel = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 1,

				Text = name,
				Font = theme.font,
				TextSize = trackTheme.textSize,
				TextColor3 = trackTheme.textColor,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			IKController = Roact.createElement(IKController, {
				Position = UDim2.new(0, textWidth + PADDING, 0.5, 0),
			}),

			AddTrackButton = tracks and not isEmpty(tracks) and Roact.createElement(AddTrackButton, {
				Size = UDim2.new(0, Constants.TRACKLIST_BUTTON_SIZE, 0, Constants.TRACKLIST_BUTTON_SIZE),
				Position = UDim2.new(1, -Constants.TRACKLIST_RIGHT_PADDING, 0.5, 0),
				Tracks = tracks,
				OnTrackSelected = self.onTrackAdded,
			}),
		})
	end)
end

return SummaryTrack