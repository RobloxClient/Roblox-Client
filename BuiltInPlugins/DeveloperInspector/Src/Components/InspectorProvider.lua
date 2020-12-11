local main = script.Parent.Parent.Parent
local Roact = require(main.Packages.Roact)
local RoactRodux = require(main.Packages.RoactRodux)
local Framework = require(main.Packages.Framework)
local ContextServices = Framework.ContextServices

local InspectorContext = require(main.Src.Util.InspectorContext)

local DeveloperTools = require(main.Packages.DeveloperTools)

local Actions = main.Src.Actions
local AddTargets = require(Actions.AddTargets)
local ClearTargets = require(Actions.ClearTargets)
local PickInstance = require(Actions.RoactInspector.PickInstance)
local UpdateInstances = require(Actions.RoactInspector.UpdateInstances)
local UpdateBranch = require(Actions.RoactInspector.UpdateBranch)
local UpdateFields = require(Actions.RoactInspector.UpdateFields)

local InspectorProvider = Roact.PureComponent:extend("InspectorProvider")

function InspectorProvider:init()
	self.inspector = DeveloperTools.forInspector({
		onAddTargets = self.props.addTargets,
		RoactInspector = {
			onUpdateInstances = self.props.updateInstances,
			onUpdateBranch = self.props.updateBranch,
			onUpdateFields = self.props.updateFields,
			onPickInstance = self.props.pickInstance
		}
	})
	self.inspectorContext = InspectorContext.new(self.inspector)
end

function InspectorProvider:didMount()
	self.inspector:getTargets()
	-- TODO RIDE-2832: Allow the public to use the DeveloperTools library by placing it in ReplicatedStorage
	-- replicateTools()
end

function InspectorProvider:willUnmount()
	if self.inspector then
		self.inspector:destroy()
	end
end

function InspectorProvider:didUpdate(prevProps)
	-- Trigger an update of the targets whenever the plugin is re-opened
	if prevProps.Active == false and self.props.Active == true then
		self.props.clearTargets()
		self.inspector:getTargets()
	end
end

function InspectorProvider:render()
	return ContextServices.provide({
		self.inspectorContext
	}, self.props[Roact.Children])
end

return RoactRodux.connect(
	function(state, props)
		return {}
	end,
	function(dispatch)
		return {
			clearTargets = function()
				dispatch(ClearTargets())
			end,
			addTargets = function(message)
				dispatch(AddTargets(message))
			end,
			updateInstances = function(path, children, updatedIndexes)
				dispatch(UpdateInstances(path, children, updatedIndexes))
			end,
			updateBranch = function(path, nodes)
				dispatch(UpdateBranch(path, nodes))
			end,
			updateFields = function(path, nodeIndex, props, state)
				dispatch(UpdateFields(path, nodeIndex, props, state))
			end,
			pickInstance = function(instancePath)
				dispatch(PickInstance(instancePath))
			end,
		}
	end
)(InspectorProvider)