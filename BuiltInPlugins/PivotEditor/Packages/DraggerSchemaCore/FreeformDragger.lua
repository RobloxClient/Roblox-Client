
local Workspace = game:GetService("Workspace")

local DraggerSchemaCore = script.Parent
local Packages = DraggerSchemaCore.Parent
local DraggerFramework = Packages.DraggerFramework

local DragHelper = require(DraggerFramework.Utility.DragHelper)
local PartMover = require(DraggerFramework.Utility.PartMover)
local AttachmentMover = require(DraggerFramework.Utility.AttachmentMover)

local getFFlagEnablePhysicalFreeFormDragger = require(DraggerFramework.Flags.getFFlagEnablePhysicalFreeFormDragger)
local getFFlagDraggerMiscFixes = require(DraggerFramework.Flags.getFFlagDraggerMiscFixes)

local FreeformDragger = {}
FreeformDragger.__index = FreeformDragger

function FreeformDragger.new(draggerContext, draggerToolModel, dragInfo)
	local t = tick()
	local self = setmetatable({
		_draggerContext = draggerContext,
		_draggerToolModel = draggerToolModel,
		_dragInfo = dragInfo,

		_partMover = PartMover.new(),
		_attachmentMover = AttachmentMover.new(),
		_tiltRotate = CFrame.new(),
	}, FreeformDragger)
	self:_init()
	local timeToStartDrag = tick() - t
	self:_analyticsRecordFreeformDragBegin(timeToStartDrag)
	return self
end

function FreeformDragger:_init()
	self:_initIgnoreList(self._draggerToolModel._selectionInfo:getObjectsToTransform())
	self:_initMovers()
end

function FreeformDragger:_initMovers()
	local breakJointsToOutsiders = true -- TODO: Remove this line with FFlagEnablePhysicalFreeFormDragger
	if getFFlagEnablePhysicalFreeFormDragger() then
		breakJointsToOutsiders = not self._draggerToolModel._draggerContext:areConstraintsEnabled()
	end

	local partsToMove, attachmentsToMove =
		self._draggerToolModel._selectionInfo:getObjectsToTransform()
	self._partMover:setDragged(
		partsToMove,
		self._draggerToolModel._selectionInfo:getOriginalCFrameMap(),
		breakJointsToOutsiders,
		self._draggerToolModel._selectionInfo:getBoundingBox().Position,
		self._draggerToolModel:getSelectionWrapper():get())
	self._attachmentMover:setDragged(
		attachmentsToMove)
end

function FreeformDragger:_initIgnoreList(parts)
	local filter = table.create(#parts + 1)
	for i, part in ipairs(parts) do
		filter[i] = part
	end
	table.insert(filter, self._partMover:getIgnorePart())
	self._raycastFilter = filter
end

function FreeformDragger:render()
	if self._draggerToolModel._draggerContext:shouldJoinSurfaces() and self._jointPairs then
		local cframe, offset = self._draggerToolModel._selectionInfo:getBoundingBox()
		local focus = cframe * offset
		return self._jointPairs:renderJoints(self._draggerToolModel._draggerContext:getHandleScale(focus))
	end
end

function FreeformDragger:rotate(axis)
	if getFFlagEnablePhysicalFreeFormDragger() then
		if self._draggerToolModel._draggerContext:areConstraintsEnabled() then
			return
		end
	end

	if axis == Vector3.new(0, 1, 0) then
		self._dragAnalytics.dragRotates = self._dragAnalytics.dragRotates + 1
	else
		self._dragAnalytics.dragTilts = self._dragAnalytics.dragTilts + 1
	end

	local mainCFrame = self._draggerToolModel._selectionInfo:getLocalBoundingBox()
	local lastTargetMatrix
	if self._lastDragTarget then
		lastTargetMatrix = self._lastDragTarget.targetMatrix
	end

	self._tiltRotate = DragHelper.updateTiltRotate(
		self._draggerToolModel._draggerContext:getCameraCFrame(),
		self._draggerToolModel._draggerContext:getMouseRay(),
		self._raycastFilter, mainCFrame, lastTargetMatrix,
		self._tiltRotate, axis, self._draggerToolModel:shouldAlignDraggedObjects())
end

function FreeformDragger:_updateGeometric()
	assert(getFFlagEnablePhysicalFreeFormDragger())

	local lastTargetMatrix = nil
	if self._lastDragTarget then
		lastTargetMatrix = self._lastDragTarget.targetMatrix
	end

	local localBoundingBoxCFrame, localBoundingBoxOffset, localBoundingBoxSize =
		self._draggerToolModel._selectionInfo:getLocalBoundingBox()
	local dragTarget = DragHelper.getDragTarget(
		self._draggerToolModel._draggerContext:getMouseRay(),
		self._draggerToolModel._draggerContext:getGridSize(),
		self._dragInfo.clickPoint,
		self._raycastFilter,
		localBoundingBoxCFrame,
		self._dragInfo.basisPoint,
		localBoundingBoxSize,
		localBoundingBoxOffset,
		self._tiltRotate,
		lastTargetMatrix,
		self._draggerToolModel:shouldAlignDraggedObjects())

	self:_analyticsRecordFreeformDragUpdate(dragTarget)

	if dragTarget then
		self._lastDragTarget = dragTarget
		local originalCFrame = localBoundingBoxCFrame
		local newCFrame = dragTarget.mainCFrame
		local globalTransform = newCFrame * originalCFrame:Inverse()
		self._partMover:transformTo(globalTransform)
		self._attachmentMover:transformTo(globalTransform)
		if self._draggerToolModel._draggerContext:shouldJoinSurfaces() then
			self._jointPairs = self._partMover:computeJointPairs(globalTransform)
		end
	end
end

function FreeformDragger:_updatePhysical()
	assert(getFFlagEnablePhysicalFreeFormDragger())

	local localBoundingBoxCFrame, localBoundingBoxOffset, localBoundingBoxSize =
		self._draggerToolModel._selectionInfo:getLocalBoundingBox()

	if not self._dragInfo.clickPoint then
		return
	end

	local dragTarget = DragHelper.getCameraPlaneDragTarget(
		self._draggerToolModel._draggerContext:getMouseRay(),
		self._draggerToolModel._draggerContext:getCameraCFrame().LookVector,
		localBoundingBoxCFrame:pointToWorldSpace(self._dragInfo.clickPoint))

	self:_analyticsRecordFreeformDragUpdate(dragTarget)

	if dragTarget then
		local collisionsMode =
			self._draggerToolModel._draggerContext:areCollisionsEnabled() and
			Enum.IKCollisionsMode.IncludeContactedMechanisms or
			Enum.IKCollisionsMode.NoCollisions
		local actualGlobalTransformUsed =
			self._partMover:moveToWithIk(dragTarget.mainCFrame, collisionsMode)
		self._attachmentMover:transformTo(actualGlobalTransformUsed)
	end
end

function FreeformDragger:update()
	if getFFlagEnablePhysicalFreeFormDragger() then
		if self._draggerToolModel._draggerContext:areConstraintsEnabled() then
			self:_updatePhysical()
		else
			self:_updateGeometric()
		end
	else
		local lastTargetMatrix = nil
		if self._lastDragTarget then
			lastTargetMatrix = self._lastDragTarget.targetMatrix
		end

		local localBoundingBoxCFrame, localBoundingBoxOffset, localBoundingBoxSize =
			self._draggerToolModel._selectionInfo:getLocalBoundingBox()
		local dragTarget = DragHelper.getDragTarget(
			self._draggerToolModel._draggerContext:getMouseRay(),
			self._draggerToolModel._draggerContext:getGridSize(),
			self._dragInfo.clickPoint,
			self._raycastFilter,
			localBoundingBoxCFrame,
			self._dragInfo.basisPoint,
			localBoundingBoxSize,
			localBoundingBoxOffset,
			self._tiltRotate,
			lastTargetMatrix,
			self._draggerToolModel:shouldAlignDraggedObjects())

		self:_analyticsRecordFreeformDragUpdate(dragTarget)

		if dragTarget then
			self._lastDragTarget = dragTarget
			local originalCFrame = localBoundingBoxCFrame
			local newCFrame = dragTarget.mainCFrame
			local globalTransform = newCFrame * originalCFrame:Inverse()
			self._partMover:transformTo(globalTransform)
			self._attachmentMover:transformTo(globalTransform)
			if self._draggerToolModel._draggerContext:shouldJoinSurfaces() then
				self._jointPairs = self._partMover:computeJointPairs(globalTransform)
			end
		end
	end
end

function FreeformDragger:destroy()
	local attachment = self._dragInfo.attachmentBeingDragged
	if attachment then
		-- Single attachment being dragged case -- In that case we need to
		-- potentially reparent the attachment to the part it was dragged onto.
		local mouseRay = self._draggerToolModel._draggerContext:getMouseRay()
		local worldHit = Workspace:FindPartOnRay(mouseRay)
		if worldHit then
			local worldCFrame = attachment.WorldCFrame
			if attachment.Parent ~= worldHit then
				if getFFlagDraggerMiscFixes() then
					-- pcall as the dragged attachment may have been Destroyed.
					pcall(function()
						attachment.Parent = worldHit
					end)
				else
					attachment.Parent = worldHit
				end
				attachment.WorldCFrame = worldCFrame
			end
		else
			-- When there's no valid target, reset the AttachmentMover so we
			-- don't move the attachment.
			self._attachmentMover:transformTo(CFrame.new())
		end
	end

	if self._draggerToolModel._draggerContext:shouldJoinSurfaces() and self._jointPairs then
		self._jointPairs:createJoints()
	end
	self._jointPairs = nil
	self._partMover:commit()
	self._attachmentMover:commit()

	self:_analyticsSendFreeformDragged()
end

function FreeformDragger:_analyticsRecordFreeformDragBegin(timeToStartDrag)
	local parts, attachments = self._draggerToolModel._selectionInfo:getObjectsToTransform()
	self._dragAnalytics = {
		dragTilts = 0,
		dragRotates = 0,
		partCount = #parts,
		attachmentCount = #attachments,
		timeToStartDrag = timeToStartDrag,
	}
	self._dragStartLocation = nil
end

function FreeformDragger:_analyticsRecordFreeformDragUpdate(dragTarget)
	if dragTarget then
		self._dragAnalytics.dragTargetType = dragTarget.dragTargetType
		if self._dragStartLocation then
			self._dragAnalytics.dragDistance =
				(dragTarget.mainCFrame.Position - self._dragStartLocation).Magnitude
		else
			self._dragAnalytics.dragDistance = 0
			self._dragStartLocation = dragTarget.mainCFrame.Position
		end
		self._dragAnalytics.distanceToCamera =
			(self._draggerToolModel._draggerContext:getCameraCFrame().Position -
				dragTarget.mainCFrame.Position).Magnitude
	else
		self._dragAnalytics.dragTargetType = "Failed"
	end
end

function FreeformDragger:_analyticsSendFreeformDragged()
	self._dragAnalytics.gridSize = self._draggerContext:getGridSize()
	self._dragAnalytics.toolName = self._draggerToolModel:getAnalyticsName()
	self._dragAnalytics.wasAutoSelected = self._draggerToolModel:wasAutoSelected()
	self._dragAnalytics.joinSurfaces = self._draggerContext:shouldJoinSurfaces()
	self._dragAnalytics.useConstraints = self._draggerContext:areConstraintsEnabled()
	if getFFlagEnablePhysicalFreeFormDragger() then
		self._dragAnalytics.haveCollisions = self._draggerContext:areCollisionsEnabled()
	end
	self._draggerToolModel._draggerContext:getAnalytics():sendEvent(
		"freeformDragged", self._dragAnalytics)
end

return FreeformDragger