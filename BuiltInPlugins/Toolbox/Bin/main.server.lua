if not plugin then
	return
end

-- Fast flags
require(script.Parent.defineLuaFlags)
local FFlagEnableOverrideAssetCursorFix = game:GetFastFlag("EnableOverrideAssetCursorFix")
local FFlagStudioToolboxEnabledDevFramework = game:GetFastFlag("StudioToolboxEnabledDevFramework")
local FFlagEnablePurchasePluginFromLua2 = settings():GetFFlag("EnablePurchasePluginFromLua2")
local FFlagAssetManagerLuaPlugin = game:GetFastFlag("AssetManagerLuaPlugin")
local FFlagEnableAudioPreview = settings():GetFFlag("EnableAudioPreview")
local FFlagStudioUseNewAnimationImportExportFlow = settings():GetFFlag("StudioUseNewAnimationImportExportFlow")

local Plugin = script.Parent.Parent
local Libs = Plugin.Libs
local Roact = require(Libs.Roact)
local Rodux = require(Libs.Rodux)

local Util = Plugin.Core.Util
local Analytics = require(Util.Analytics.Analytics)
local DebugFlags = require(Util.DebugFlags)
local Settings = require(Util.Settings)
local ToolboxTheme = require(Util.ToolboxTheme)
local Localization = require(Util.Localization)
local AssetConfigTheme = require(Util.AssetConfigTheme)
local AssetConfigConstants = require(Util.AssetConfigConstants)
local AssetConfigUtil = require(Util.AssetConfigUtil)

local Background = require(Plugin.Core.Types.Background)
local Suggestion = require(Plugin.Core.Types.Suggestion)
local ConfigTypes = require(Plugin.Core.Types.ConfigTypes)

local ToolboxPlugin = require(Plugin.Core.Components.ToolboxPlugin)

local ToolboxReducer = require(Plugin.Core.Reducers.ToolboxReducer)
local AssetConfigReducer = require(Plugin.Core.Reducers.AssetConfigReducer)

local NetworkInterface = require(Plugin.Core.Networking.NetworkInterface)

local AssetConfigWrapper = require(Plugin.Core.Components.AssetConfiguration.AssetConfigWrapper)
local ToolboxServiceWrapper =  require(Plugin.Core.Components.ToolboxServiceWrapper)

local GetRolesRequest = require(Plugin.Core.Networking.Requests.GetRolesRequest)

local ContextServices = require(Libs.Framework.ContextServices)
local SettingsContext = require(Plugin.Core.ContextServices.Settings)

local TranslationStringsTable = Plugin.LocalizationSource.ToolboxTranslationReferenceTable
local makeTheme = require(Util.makeTheme)

local HttpService = game:GetService("HttpService")
local MemStorageService = game:GetService("MemStorageService")
local RobloxPluginGuiService = game:GetService("RobloxPluginGuiService")
local StudioService = game:GetService("StudioService")

local localization2
if FFlagStudioToolboxEnabledDevFramework then
	localization2 = ContextServices.Localization.new({
		stringResourceTable = TranslationStringsTable,
		translationResourceTable = TranslationStringsTable,
		pluginName = "Toolbox",
	})
end

local function createTheme()
	return ToolboxTheme.new({
		getTheme = function()
			return settings().Studio.Theme
		end,
		isDarkerTheme = function(theme)
			-- Assume "darker" theme if the average main background colour is darker
			local mainColour = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
			return (mainColour.r + mainColour.g + mainColour.b) / 3 < 0.5
		end,
		themeChanged = settings().Studio.ThemeChanged,
	})
end

local function createAssetConfigTheme()
	return AssetConfigTheme.new({
		-- Get the theme object, used to calculate color.
		getTheme = function()
			return settings().Studio.Theme
		end,
		-- Get the theme value
		getUITheme = function()
			return settings().Studio["UI Theme"]
		end,
		themeChanged = settings().Studio.ThemeChanged,
	})
end

local function createLocalization()
	local localizationTable = Plugin.LocalizationSource.ToolboxTranslationReferenceTable

	-- Check if we should use a fake locale
	if DebugFlags.shouldUseTestCustomLocale() then
		print("Toolbox using test custom locale")
		return Localization.createTestCustomLocaleLocalization(DebugFlags.getOrCreateTestCustomLocale())
	end

	if DebugFlags.shouldUseTestRealLocale() then
		print("Toolbox using test real locale")
		return Localization.createTestRealLocaleLocalization(localizationTable, DebugFlags.getOrCreateTestRealLocale())
	end

    return Localization.new({
        getLocaleId = function()
            return StudioService["StudioLocaleId"]
        end,
        getTranslator = function(localeId)
            return localizationTable:GetTranslator(localeId)
        end,
        localeIdChanged = StudioService:GetPropertyChangedSignal("StudioLocaleId")
    })
end

local toolboxStore = nil

-- flowType AssetConfigConstants.FLOW_TYPE, will be used to determine what screens are
--				going to be shown on AssetConfig start up and what's next screen.
-- assetId number, will be used by Marketplace to request detail assetData.
--				default to nil, then will not request anything.
-- assetTypeEnum Enum.AssetType, some asset like places, need to use the parameter to
--				set the assetType of the Asset, and skip the assetTypeSelection.
--				default to nil
-- instances instances, Will be used in publishing new assets. Instances are userdata,
--				we can't check the assetType using that, using AssetType instead.
-- toolboxStore storeObejct, is used to fetch some catalog data from the Toolbox.
local assetConfigHandle = nil
local function createAssetConfig(assetId, flowType, instances, assetTypeEnum)
	if assetConfigHandle then
		return
	end

	local assetTypesForRelease = {}
	local assetTypesForUpload = {}
	local packagePermissions = {}

	local isItemTagsFeatureEnabled = false
	local enabledAssetTypesForItemTags = {}
	local maximumItemTagsPerItem = 0

	if toolboxStore then
		assetTypesForRelease = toolboxStore:getState().roles.allowedAssetTypesForRelease
		assetTypesForUpload = toolboxStore:getState().roles.allowedAssetTypesForUpload
		packagePermissions = toolboxStore:getState().packages.permissionsTable
		isItemTagsFeatureEnabled = toolboxStore:getState().itemTags.isItemTagsFeatureEnabled
		enabledAssetTypesForItemTags = toolboxStore:getState().itemTags.enabledAssetTypesForItemTags
		maximumItemTagsPerItem = toolboxStore:getState().itemTags.maximumItemTagsPerItem
	end

	local startScreen = AssetConfigUtil.getFlowStartScreen(flowType)

	local defaultTab = ConfigTypes:getDefualtTab()
	if FFlagStudioUseNewAnimationImportExportFlow then
		if flowType == AssetConfigConstants.FLOW_TYPE.DOWNLOAD_FLOW then
			defaultTab = ConfigTypes:getOverrideTab()
		end
	end

	-- If we don't have asset id, we will be publish an new asset.
	-- Otherwise, we will be editing an asset.
	local assetConfigStore = Rodux.Store.new(AssetConfigReducer, {
			assetId = assetId,
			screenFlowType = flowType,
			currentScreen = startScreen,
			instances = instances,
			allowedAssetTypesForRelease = assetTypesForRelease,
			allowedAssetTypesForUpload = assetTypesForUpload,
			isItemTagsFeatureEnabled = isItemTagsFeatureEnabled,
			enabledAssetTypesForItemTags = enabledAssetTypesForItemTags,
			maximumItemTagsPerItem = maximumItemTagsPerItem,
			assetTypeEnum = assetTypeEnum,
			currentTab = defaultTab,
			packagePermissions = packagePermissions,
			overrideCursor = FFlagEnableOverrideAssetCursorFix and {} or nil,
		}, {
			Rodux.thunkMiddleware
		}
	)

	local theme = createAssetConfigTheme()
	local networkInterface = NetworkInterface.new()
	-- We are using the same localization table for Toolbox and AssetConfig for now.
	local localization = createLocalization()

	local function onAssetConfigDestroy()
		if assetConfigHandle then
			local function fireTabRefreshEvent()
				local EventName = "tabRefresh"
				local toolboxPlugin = RobloxPluginGuiService:FindFirstChild("Toolbox")
				local theEvent = toolboxPlugin and toolboxPlugin:FindFirstChild(EventName)
				if theEvent then
					theEvent:Fire()
				end
			end
			fireTabRefreshEvent()
			Roact.unmount(assetConfigHandle)
			assetConfigHandle = nil
			if FFlagStudioUseNewAnimationImportExportFlow then
				-- this should no-opt if user already selected an animation id in download flow
				StudioService:AnimationIdSelected(0)
			end
		end
	end

	local assetConfigComponent = Roact.createElement(AssetConfigWrapper, {
		assetId = assetId,
		assetTypeEnum = assetTypeEnum,

		plugin = plugin,
		store = assetConfigStore,
		theme = theme,
		networkInterface = networkInterface,
		localization = localization,

		onAssetConfigDestroy = onAssetConfigDestroy
	})
	if FFlagStudioToolboxEnabledDevFramework then
		local assetConfigWithServices
		if FFlagEnableAudioPreview then
			assetConfigWithServices = Roact.createElement(ToolboxServiceWrapper, {
				localization = localization2,
				plugin = plugin,
				theme = theme,
				store = assetConfigStore,
				settings = settings,
			}, {
				assetConfigComponent
			})
		else
			assetConfigWithServices = ContextServices.provide({
				ContextServices.Plugin.new(plugin),
				localization2,
				makeTheme(theme:getUILibraryTheme()),
				ContextServices.Store.new(assetConfigStore),
				SettingsContext.new(settings),
			}, {
				assetConfigComponent
			})
		end
		assetConfigHandle = Roact.mount(assetConfigWithServices)
	else
		assetConfigHandle = Roact.mount(assetConfigComponent)
	end

	return assetConfigHandle
end

local function main()
	toolboxStore = Rodux.Store.new(ToolboxReducer, nil, {
		Rodux.thunkMiddleware
	})

	local settings = Settings.new(plugin)
	local theme = createTheme()
	local networkInterface = NetworkInterface.new()
	local localization = createLocalization()

	local backgrounds = Background.BACKGROUNDS
	local suggestions = Suggestion.SUGGESTIONS

	local toolboxHandle

	local function onPluginWillDestroy()
		if toolboxHandle then
			Analytics.sendReports(plugin)
			Roact.unmount(toolboxHandle)
		end
	end

	local toolboxComponent = Roact.createElement(ToolboxPlugin, {
		plugin = plugin,
		store = toolboxStore,
		settings = settings,
		theme = theme,
		networkInterface = networkInterface,
		localization = localization,

		backgrounds = backgrounds,
		suggestions = suggestions,

		onPluginWillDestroy = onPluginWillDestroy,
		tryOpenAssetConfig = function(assetId, flowType, instances, assetTypeEnum)
			local function proceedToEdit()
				createAssetConfig(assetId, flowType, instances, assetTypeEnum)
			end
			toolboxStore:dispatch(GetRolesRequest(networkInterface)):andThen(proceedToEdit, proceedToEdit)
		end,
	})
	if FFlagStudioToolboxEnabledDevFramework then
		local toolboxWithServices
		if FFlagEnableAudioPreview then
			toolboxWithServices = Roact.createElement(ToolboxServiceWrapper, {
				localization = localization2,
				plugin = plugin,
				theme = theme,
				store = toolboxStore,
				settings = settings,
			}, {
				toolboxComponent
			})
		else
			toolboxWithServices = ContextServices.provide({
				ContextServices.Plugin.new(plugin),
				localization2,
				makeTheme(theme:getUILibraryTheme()),
				ContextServices.Store.new(toolboxStore),
				SettingsContext.new(settings),
			}, {
				toolboxComponent
			})
		end
		toolboxHandle = Roact.mount(toolboxWithServices)
	else
		toolboxHandle = Roact.mount(toolboxComponent)
	end

	-- Create publish new asset page.
	StudioService.OnSaveToRoblox:connect(function(instances)
		local function proceedToUpload()
			local clonedInstances = AssetConfigUtil.getClonedInstances(instances)
			if FFlagStudioUseNewAnimationImportExportFlow and #clonedInstances == 1 and clonedInstances[1]:IsA("KeyframeSequence") then
				createAssetConfig(nil, AssetConfigConstants.FLOW_TYPE.UPLOAD_FLOW, clonedInstances, Enum.AssetType.Animation)
			else
				createAssetConfig(nil, AssetConfigConstants.FLOW_TYPE.UPLOAD_FLOW, clonedInstances)
			end
		end
		toolboxStore:dispatch(GetRolesRequest(networkInterface)):andThen(proceedToUpload, proceedToUpload)
	end)

	if FFlagStudioUseNewAnimationImportExportFlow then
		StudioService.OnImportFromRoblox:connect(function(callback)
			createAssetConfig(nil, AssetConfigConstants.FLOW_TYPE.DOWNLOAD_FLOW, nil, Enum.AssetType.Animation)
		end)
	end

	StudioService.OnOpenManagePackagePlugin:connect(function(userId, assetId)
		createAssetConfig(assetId, AssetConfigConstants.FLOW_TYPE.EDIT_FLOW, nil, Enum.AssetType.Model)
	end)

	-- Create publish new plugin page.
	StudioService.OnPublishAsPlugin:connect(function(instances)
		if FFlagEnablePurchasePluginFromLua2 then
			createAssetConfig(
				nil,
				AssetConfigConstants.FLOW_TYPE.UPLOAD_FLOW,
				AssetConfigUtil.getClonedInstances(instances),
				Enum.AssetType.Plugin
			)
		end
	end)

	if FFlagAssetManagerLuaPlugin then
	-- Listen to MemStorageService
		local EVENT_ID_OPENASSETCONFIG = "OpenAssetConfiguration"
		MemStorageService:Bind(EVENT_ID_OPENASSETCONFIG,
			function(params)
				local asset = HttpService:JSONDecode(params)
				if asset.assetType == Enum.AssetType.Image then
					createAssetConfig(
						asset.id,
						AssetConfigConstants.FLOW_TYPE.EDIT_FLOW,
						nil,
						Enum.AssetType.Image)
				else
					createAssetConfig(
						asset.id,
						AssetConfigConstants.FLOW_TYPE.EDIT_FLOW,
						nil,
						Enum.AssetType.MeshPart)
				end
			end)
	end
end

main()