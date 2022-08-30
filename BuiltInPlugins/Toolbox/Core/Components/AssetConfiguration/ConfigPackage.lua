--[[
	This component is responsible for configuring asset's make Package field

	Props:
	ToggleCallback, function, will return current selected statue if toggled.
]]
-- added with FFlagUnifyModelPackagePublish2
local Plugin = script.Parent.Parent.Parent.Parent

local Packages = Plugin.Packages
local Roact = require(Packages.Roact)
local Framework = require(Packages.Framework)

local ContextServices = require(Packages.Framework).ContextServices
local withContext = ContextServices.withContext

local Util = Plugin.Core.Util
local Constants = require(Util.Constants)
local AssetConfigConstants = require(Util.AssetConfigConstants)

local ToggleButton = Framework.UI.ToggleButton
local TextLabel = Framework.UI.Decoration.TextLabel
local StyleModifier = Framework.Util.StyleModifier

local ConfigPackage = Roact.PureComponent:extend("ConfigPackage")

local TOGGLE_BUTTON_WIDTH = 40
local TOGGLE_BUTTON_HEIGHT = 24

function ConfigPackage:init(props)
	self.toggleCallback = function()
		local props = self.props
		props.ToggleCallback(not props.PackageOn)
	end
end

function ConfigPackage:render()
	return self:renderContent()
end

function ConfigPackage:renderContent()
	local props = self.props

	local Title = props.Title
	local LayoutOrder = props.LayoutOrder
	local TotalHeight = props.TotalHeight
	local PackageOn = props.PackageOn
	local PackageEnabled = props.PackageEnabled

	local ToggleCallback = props.ToggleCallback

	local theme = self.props.Stylizer
	local publishAssetTheme = theme.publishAsset

	local localization = props.Localization
	local informationText = localization:getText("AssetConfigPackage", "HelpText")

	return Roact.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, TotalHeight),

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		LayoutOrder = LayoutOrder
	}, {
		UIListLayout = Roact.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 0),
		}),

		Title = Roact.createElement(TextLabel, {
			Size = UDim2.new(0, AssetConfigConstants.TITLE_GUTTER_WIDTH, 1, 0),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			Text = Title,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextSize = Constants.FONT_SIZE_TITLE,
			TextColor3 = publishAssetTheme.titleTextColor,
			Font = Constants.FONT,

			LayoutOrder = 1,
		}),

		RightFrame = Roact.createElement("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, -AssetConfigConstants.TITLE_GUTTER_WIDTH, 0, 0),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			LayoutOrder = 2,
		}, {
			UIListLayout = Roact.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				Padding = UDim.new(0, 5),
			}),

			ToggleButton = Roact.createElement(ToggleButton, {
				Disabled = not PackageEnabled,
				LayoutOrder = 2,
				OnClick = self.toggleCallback,
				Selected = PackageOn,
				Size = UDim2.new(0, TOGGLE_BUTTON_WIDTH, 0, TOGGLE_BUTTON_HEIGHT),
			}),

			TipsLabel = Roact.createElement(TextLabel, {
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				BorderSizePixel = 0,
				LayoutOrder = 3,

				Text = informationText,
				StyleModifier = StyleModifier.Disabled,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextSize = Constants.FONT_SIZE_LARGE,

			}),
		}),
	})
end


ConfigPackage = withContext({
	Localization = ContextServices.Localization,
	Stylizer = ContextServices.Stylizer,
})(ConfigPackage)


return ConfigPackage