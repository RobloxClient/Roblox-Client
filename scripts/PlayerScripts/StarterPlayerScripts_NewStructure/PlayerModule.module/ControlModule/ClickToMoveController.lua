--[[
	-- Original By Kip Turner, Copyright Roblox 2014
	-- Updated by Garnold to utilize the new PathfindingService API, 2017
	-- 2018 PlayerScripts Update - AllYourBlox
--]]

--[[ Roblox Services ]]--
local UserInputService = game:GetService("UserInputService")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local DebrisService = game:GetService('Debris')
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")

--[[ Configuration ]]
local ShowPath = true
local PlayFailureAnimation = true
local UseDirectPath = false
local UseDirectPathForVehicle = true
local AgentSizeIncreaseFactor = 1.0
local UnreachableWaypointTimeout = 8

--[[ Constants ]]--
local movementKeys = {
	[Enum.KeyCode.W] = true;
	[Enum.KeyCode.A] = true;
	[Enum.KeyCode.S] = true;
	[Enum.KeyCode.D] = true;
	[Enum.KeyCode.Up] = true;
	[Enum.KeyCode.Down] = true;
}

local FFlagUserNavigationClickToMoveSkipPassedWaypointsSuccess, FFlagUserNavigationClickToMoveSkipPassedWaypointsResult = pcall(function() return UserSettings():IsUserFeatureEnabled("UserNavigationClickToMoveSkipPassedWaypoints") end)
local FFlagUserNavigationClickToMoveSkipPassedWaypoints = FFlagUserNavigationClickToMoveSkipPassedWaypointsSuccess and FFlagUserNavigationClickToMoveSkipPassedWaypointsResult
local FFlagUserClickToMoveFollowPathRefactorSuccess, FFlagUserClickToMoveFollowPathRefactorResult = pcall(function() return UserSettings():IsUserFeatureEnabled("UserClickToMoveFollowPathRefactor") end)
local FFlagUserClickToMoveFollowPathRefactor = FFlagUserClickToMoveFollowPathRefactorSuccess and FFlagUserClickToMoveFollowPathRefactorResult

local FFlagUserClickToMoveCancelOnMenuOpenedSuccess, FFlagUserClickToMoveCancelOnMenuOpenedResult = pcall(function()
	return UserSettings():IsUserFeatureEnabled("UserClickToMoveCancelOnMenuOpened")
end)
local FFlagUserClickToMoveCancelOnMenuOpened = FFlagUserClickToMoveCancelOnMenuOpenedSuccess and FFlagUserClickToMoveCancelOnMenuOpenedResult

local Player = Players.LocalPlayer

local ClickToMoveDisplay = require(script.Parent:WaitForChild("ClickToMoveDisplay"))

local ZERO_VECTOR3 = Vector3.new(0,0,0)
local ALMOST_ZERO = 0.000001


--------------------------UTIL LIBRARY-------------------------------
local Utility = {}
do
	local function FindCharacterAncestor(part)
		if part then
			local humanoid = part:FindFirstChildOfClass("Humanoid")
			if humanoid then
				return part, humanoid
			else
				return FindCharacterAncestor(part.Parent)
			end
		end
	end
	Utility.FindCharacterAncestor = FindCharacterAncestor

	local function Raycast(ray, ignoreNonCollidable, ignoreList)
		ignoreList = ignoreList or {}
		local hitPart, hitPos, hitNorm, hitMat = Workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
		if hitPart then
			if ignoreNonCollidable and hitPart.CanCollide == false then
				-- We always include character parts so a user can click on another character
				-- to walk to them.
				local _, humanoid = FindCharacterAncestor(hitPart)
				if humanoid == nil then
					table.insert(ignoreList, hitPart)
					return Raycast(ray, ignoreNonCollidable, ignoreList)
				end
			end
			return hitPart, hitPos, hitNorm, hitMat
		end
		return nil, nil
	end
	Utility.Raycast = Raycast
end

local humanoidCache = {}
local function findPlayerHumanoid(player)
	local character = player and player.Character
	if character then
		local resultHumanoid = humanoidCache[player]
		if resultHumanoid and resultHumanoid.Parent == character then
			return resultHumanoid
		else
			humanoidCache[player] = nil -- Bust Old Cache
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoidCache[player] = humanoid
			end
			return humanoid
		end
	end
end

--------------------------CHARACTER CONTROL-------------------------------
local CurrentIgnoreList
local CurrentIgnoreTag = nil

local TaggedInstanceAddedConnection = nil
local TaggedInstanceRemovedConnection = nil

local function GetCharacter()
	return Player and Player.Character
end

local function UpdateIgnoreTag(newIgnoreTag)
	if newIgnoreTag == CurrentIgnoreTag then
		return
	end
	if TaggedInstanceAddedConnection then
		TaggedInstanceAddedConnection:Disconnect()
		TaggedInstanceAddedConnection = nil
	end
	if TaggedInstanceRemovedConnection then
		TaggedInstanceRemovedConnection:Disconnect()
		TaggedInstanceRemovedConnection = nil
	end
	CurrentIgnoreTag = newIgnoreTag
	CurrentIgnoreList = {GetCharacter()}
	if CurrentIgnoreTag ~= nil then
		local ignoreParts = CollectionService:GetTagged(CurrentIgnoreTag)
		for _, ignorePart in ipairs(ignoreParts) do
			table.insert(CurrentIgnoreList, ignorePart)
		end
		TaggedInstanceAddedConnection = CollectionService:GetInstanceAddedSignal(
			CurrentIgnoreTag):Connect(function(ignorePart)
			table.insert(CurrentIgnoreList, ignorePart)
		end)
		TaggedInstanceRemovedConnection = CollectionService:GetInstanceRemovedSignal(
			CurrentIgnoreTag):Connect(function(ignorePart)
			for i = 1, #CurrentIgnoreList do
				if CurrentIgnoreList[i] == ignorePart then
					CurrentIgnoreList[i] = CurrentIgnoreList[#CurrentIgnoreList]
					table.remove(CurrentIgnoreList)
					break
				end
			end
		end)
	end
end

local function getIgnoreList()
	if CurrentIgnoreList then
		return CurrentIgnoreList
	end
	CurrentIgnoreList = {}
	table.insert(CurrentIgnoreList, GetCharacter())
	return CurrentIgnoreList
end

-----------------------------------PATHER--------------------------------------

local function Pather(endPoint, surfaceNormal, overrideUseDirectPath)
	local this = {}

	local directPathForHumanoid
	local directPathForVehicle
	if overrideUseDirectPath ~= nil then
		directPathForHumanoid = overrideUseDirectPath
		directPathForVehicle = overrideUseDirectPath
	else
		directPathForHumanoid = UseDirectPath
		directPathForVehicle = UseDirectPathForVehicle
	end

	this.Cancelled = false
	this.Started = false

	this.Finished = Instance.new("BindableEvent")
	this.PathFailed = Instance.new("BindableEvent")

	this.PathComputing = false
	this.PathComputed = false

	this.OriginalTargetPoint = endPoint
	this.TargetPoint = endPoint
	this.TargetSurfaceNormal = surfaceNormal

	this.DiedConn = nil
	this.SeatedConn = nil
	this.MoveToConn = nil	-- To be removd with FFlagUserClickToMoveFollowPathRefactor
	this.BlockedConn = nil
	this.TeleportedConn = nil

	this.CurrentPoint = 0

	this.HumanoidOffsetFromPath = ZERO_VECTOR3

	this.CurrentWaypointPosition = nil
	this.CurrentWaypointPlaneNormal = ZERO_VECTOR3
	this.CurrentWaypointPlaneDistance = 0
	this.CurrentWaypointNeedsJump = false;

	this.CurrentHumanoidPosition = ZERO_VECTOR3
	this.CurrentHumanoidVelocity = 0

	this.NextActionMoveDirection = ZERO_VECTOR3
	this.NextActionJump = false

	this.Timeout = 0

	this.Humanoid = findPlayerHumanoid(Player)
	this.OriginPoint = nil
	this.AgentCanFollowPath = false
	this.DirectPath = false
	this.DirectPathRiseFirst = false

	if FFlagUserClickToMoveFollowPathRefactor then
		local rootPart = this.Humanoid and this.Humanoid.RootPart
		if rootPart then
			-- Setup origin
			this.OriginPoint = rootPart.CFrame.p

			-- Setup agent
			local agentRadius = 2
			local agentHeight = 5
			local agentCanJump = true

			local seat = this.Humanoid.SeatPart
			if seat and seat:IsA("VehicleSeat") then
				-- Humanoid is seated on a vehicle
				local vehicle = seat:FindFirstAncestorOfClass("Model")
				if vehicle then
					-- Make sure the PrimaryPart is set to the vehicle seat while we compute the extends.
					local tempPrimaryPart = vehicle.PrimaryPart
					vehicle.PrimaryPart = seat

					-- For now, only direct path
					if directPathForVehicle then
						local extents = vehicle:GetExtentsSize()
						agentRadius = AgentSizeIncreaseFactor * 0.5 * math.sqrt(extents.X * extents.X + extents.Z * extents.Z)
						agentHeight = AgentSizeIncreaseFactor * extents.Y
						agentCanJump = false
						this.AgentCanFollowPath = true
						this.DirectPath = directPathForVehicle
					end

					-- Reset PrimaryPart
					vehicle.PrimaryPart = tempPrimaryPart
				end
			else
				local extents = GetCharacter():GetExtentsSize()
				agentRadius = AgentSizeIncreaseFactor * 0.5 * math.sqrt(extents.X * extents.X + extents.Z * extents.Z)
				agentHeight = AgentSizeIncreaseFactor * extents.Y
				agentCanJump = (this.Humanoid.JumpPower > 0)
				this.AgentCanFollowPath = true
				this.DirectPath = directPathForHumanoid
				this.DirectPathRiseFirst = this.Humanoid.Sit
			end

			-- Build path object
			this.pathResult = PathfindingService:CreatePath({AgentRadius = agentRadius, AgentHeight = agentHeight, AgentCanJump = agentCanJump})
		end
	else
		if this.Humanoid then
			local torso = this.Humanoid.Torso
			if torso then
				this.OriginPoint = torso.CFrame.p
				this.AgentCanFollowPath = true
				this.DirectPath = directPathForHumanoid
			end
		end
	end

	function this:Cleanup()
		if this.stopTraverseFunc then
			this.stopTraverseFunc()
			this.stopTraverseFunc = nil
		end

		if this.MoveToConn then
			this.MoveToConn:Disconnect()
			this.MoveToConn = nil
		end

		if this.BlockedConn then
			this.BlockedConn:Disconnect()
			this.BlockedConn = nil
		end

		if this.DiedConn then
			this.DiedConn:Disconnect()
			this.DiedConn = nil
		end

		if this.SeatedConn then
			this.SeatedConn:Disconnect()
			this.SeatedConn = nil
		end

		if this.TeleportedConn then
			this.TeleportedConn:Disconnect()
			this.TeleportedConn = nil
		end

		this.Started = false
	end

	function this:Cancel()
		this.Cancelled = true
		this:Cleanup()
	end

	function this:IsActive()
		return this.AgentCanFollowPath and this.Started and not this.Cancelled
	end

	function this:OnPathInterrupted()
		-- Stop moving
		this.Cancelled = true
		this:OnPointReached(false)
	end

	function this:ComputePath()
		if this.OriginPoint then
			if this.PathComputed or this.PathComputing then return end
			this.PathComputing = true
			if FFlagUserClickToMoveFollowPathRefactor then
				if this.AgentCanFollowPath then
					if this.DirectPath then
						this.pointList = {
							PathWaypoint.new(this.OriginPoint, Enum.PathWaypointAction.Walk),
							PathWaypoint.new(this.TargetPoint, this.DirectPathRiseFirst and Enum.PathWaypointAction.Jump or Enum.PathWaypointAction.Walk)
						}
						this.PathComputed = true
					else
						this.pathResult:ComputeAsync(this.OriginPoint, this.TargetPoint)
						this.pointList = this.pathResult:GetWaypoints()
						this.BlockedConn = this.pathResult.Blocked:Connect(function(blockedIdx) this:OnPathBlocked(blockedIdx) end)
						this.PathComputed = this.pathResult.Status == Enum.PathStatus.Success
					end
				end
			else
				pcall(function()
					this.pathResult = PathfindingService:FindPathAsync(this.OriginPoint, this.TargetPoint)
				end)
				this.pointList = this.pathResult and this.pathResult:GetWaypoints()
				if this.pathResult then
					this.BlockedConn = this.pathResult.Blocked:Connect(function(blockedIdx) this:OnPathBlocked(blockedIdx) end)
				end
				this.PathComputed = this.pathResult and this.pathResult.Status == Enum.PathStatus.Success or false
			end
			this.PathComputing = false
		end
	end

	function this:IsValidPath()
		if FFlagUserClickToMoveFollowPathRefactor then
			this:ComputePath()
			return this.PathComputed and this.AgentCanFollowPath
		else
			if not this.pathResult then
				this:ComputePath()
			end
			return this.pathResult.Status == Enum.PathStatus.Success
		end
	end

	this.Recomputing = false
	function this:OnPathBlocked(blockedWaypointIdx)
		local pathBlocked = blockedWaypointIdx >= this.CurrentPoint
		if not pathBlocked or this.Recomputing then
			return
		end

		this.Recomputing = true

		if this.stopTraverseFunc then
			this.stopTraverseFunc()
			this.stopTraverseFunc = nil
		end

		if FFlagUserClickToMoveFollowPathRefactor then
			this.OriginPoint = this.Humanoid.RootPart.CFrame.p
		else
			this.OriginPoint = this.Humanoid.Torso.CFrame.p
		end

		this.pathResult:ComputeAsync(this.OriginPoint, this.TargetPoint)
		this.pointList = this.pathResult:GetWaypoints()
		if #this.pointList > 0 then
			if FFlagUserClickToMoveFollowPathRefactor then
				this.HumanoidOffsetFromPath = this.pointList[1].Position - this.OriginPoint
			else
				-- Nothing to do : offset did not change
			end
		end
		this.PathComputed = this.pathResult.Status == Enum.PathStatus.Success

		if ShowPath then
			this.stopTraverseFunc, this.setPointFunc = ClickToMoveDisplay.CreatePathDisplay(this.pointList)
		end
		if this.PathComputed then
			this.CurrentPoint = 1 -- The first waypoint is always the start location. Skip it.
			this:OnPointReached(true) -- Move to first point
		else
			this.PathFailed:Fire()
			this:Cleanup()
		end

		this.Recomputing = false
	end

	function this:OnRenderStepped(dt)
		if this.Started and not this.Cancelled then
			-- Check for Timeout (if a waypoint is not reached within the delay, we fail)
			this.Timeout = this.Timeout + dt
			if this.Timeout > UnreachableWaypointTimeout then
				this:OnPointReached(false)
				return
			end

			-- Get Humanoid position and velocity
			this.CurrentHumanoidPosition = this.Humanoid.RootPart.Position + this.HumanoidOffsetFromPath
			this.CurrentHumanoidVelocity = this.Humanoid.RootPart.Velocity

			-- Check if it has reached some waypoints
			while this.Started and this:IsCurrentWaypointReached() do
				this:OnPointReached(true)
			end

			-- If still started, update actions
			if this.Started then
				-- Move action
				this.NextActionMoveDirection = this.CurrentWaypointPosition - this.CurrentHumanoidPosition
				if this.NextActionMoveDirection.Magnitude > ALMOST_ZERO then
					this.NextActionMoveDirection = this.NextActionMoveDirection.Unit
				else
					this.NextActionMoveDirection = ZERO_VECTOR3
				end
				-- Jump action
				if this.CurrentWaypointNeedsJump then
					this.NextActionJump = true
					this.CurrentWaypointNeedsJump = false	-- Request jump only once
				else
					this.NextActionJump = false
				end
			end
		end
	end

	function this:IsCurrentWaypointReached()
		local reached = false

		-- Check we do have a plane, if not, we consider the waypoint reached
		if this.CurrentWaypointPlaneNormal ~= ZERO_VECTOR3 then
			-- Compute distance of Humanoid from destination plane
			local dist = this.CurrentWaypointPlaneNormal:Dot(this.CurrentHumanoidPosition) - this.CurrentWaypointPlaneDistance
			-- Compute the component of the Humanoid velocity that is towards the plane
			local velocity = -this.CurrentWaypointPlaneNormal:Dot(this.CurrentHumanoidVelocity)
			-- Compute the threshold from the destination plane based on Humanoid velocity
			local threshold = math.max(1.0, 0.0625 * velocity)
			-- If we are less then threshold in front of the plane (between 0 and threshold) or if we are behing the plane (less then 0), we consider we reached it
			reached = dist < threshold
		else
			reached = true
		end

		if reached then
			this.CurrentWaypointPosition = nil
			this.CurrentWaypointPlaneNormal	= ZERO_VECTOR3
			this.CurrentWaypointPlaneDistance = 0
		end

		return reached
	end

	function this:OnPointReached(reached)

		if reached and not this.Cancelled then

			if FFlagUserClickToMoveFollowPathRefactor then
				-- First, destroyed the current displayed waypoint
				if this.setPointFunc then
					this.setPointFunc(this.CurrentPoint)
				end
			end

			local nextWaypointIdx = this.CurrentPoint + 1

			if nextWaypointIdx > #this.pointList then
				-- End of path reached
				if this.stopTraverseFunc then
					this.stopTraverseFunc()
				end
				this.Finished:Fire()
				this:Cleanup()
			else
				local currentWaypoint = this.pointList[this.CurrentPoint]
				local nextWaypoint = this.pointList[nextWaypointIdx]

				-- If airborne, only allow to keep moving
				-- if nextWaypoint.Action ~= Jump, or path mantains a direction
				-- Otherwise, wait until the humanoid gets to the ground
				local currentState = this.Humanoid:GetState()
				local isInAir = currentState == Enum.HumanoidStateType.FallingDown
					or currentState == Enum.HumanoidStateType.Freefall
					or currentState == Enum.HumanoidStateType.Jumping

				if isInAir then
					local shouldWaitForGround = nextWaypoint.Action == Enum.PathWaypointAction.Jump
					if not shouldWaitForGround and this.CurrentPoint > 1 then
						local prevWaypoint = this.pointList[this.CurrentPoint - 1]

						local prevDir = currentWaypoint.Position - prevWaypoint.Position
						local currDir = nextWaypoint.Position - currentWaypoint.Position

						local prevDirXZ = Vector2.new(prevDir.x, prevDir.z).Unit
						local currDirXZ = Vector2.new(currDir.x, currDir.z).Unit

						local THRESHOLD_COS = 0.996 -- ~cos(5 degrees)
						shouldWaitForGround = prevDirXZ:Dot(currDirXZ) < THRESHOLD_COS
					end

					if shouldWaitForGround then
						this.Humanoid.FreeFalling:Wait()

						-- Give time to the humanoid's state to change
						-- Otherwise, the jump flag in Humanoid
						-- will be reset by the state change
						wait(0.1)
					end
				end

				-- Move to the next point
				if FFlagUserNavigationClickToMoveSkipPassedWaypoints then
					if FFlagUserClickToMoveFollowPathRefactor then
						this:MoveToNextWayPoint(currentWaypoint, nextWaypoint, nextWaypointIdx)
					else
						-- First, check if we already passed the next point
						local nextWaypointAlreadyReached
						-- 1) Build plane (normal is from next waypoint towards current one
						-- (provided the two waypoints are not at the same location); location is at next waypoint)
						local planeNormal = currentWaypoint.Position - nextWaypoint.Position
						if planeNormal.Magnitude > ALMOST_ZERO then
							planeNormal	= planeNormal.Unit
							local planeDistance	= planeNormal:Dot(nextWaypoint.Position)
							-- 2) Find current Humanoid position
							local humanoidPosition = this.Humanoid.RootPart.Position - Vector3.new(
								0, 0.5 * this.Humanoid.RootPart.Size.y + this.Humanoid.HipHeight, 0)
							-- 3) Compute distance from plane
							local dist = planeNormal:Dot(humanoidPosition) - planeDistance
							-- 4) If we are less then a stud in front of the plane or if we are behing the plane, we consider we reached it
							nextWaypointAlreadyReached = dist < 1.0
						else
							-- Next waypoint is the same as current waypoint so we reached it as well
							nextWaypointAlreadyReached = true
						end

						-- Prepare for next point
						if not FFlagUserClickToMoveFollowPathRefactor then
							if this.setPointFunc then
								this.setPointFunc(nextWaypointIdx)
							end
						end
						this.CurrentPoint = nextWaypointIdx

						-- Either callback here right away if next waypoint is already passed
						-- Otherwise, ask the Humanoid to MoveTo
						if nextWaypointAlreadyReached then
							this:OnPointReached(true)
						else
							if nextWaypoint.Action == Enum.PathWaypointAction.Jump then
								this.Humanoid.Jump = true
							end
							this.Humanoid:MoveTo(nextWaypoint.Position)
						end
					end
				else
					if this.setPointFunc then
						this.setPointFunc(nextWaypointIdx)
					end
					if nextWaypoint.Action == Enum.PathWaypointAction.Jump then
						this.Humanoid.Jump = true
					end
					this.Humanoid:MoveTo(nextWaypoint.Position)

					this.CurrentPoint = nextWaypointIdx
				end
			end
		else
			this.PathFailed:Fire()
			this:Cleanup()
		end
	end

	function this:MoveToNextWayPoint(currentWaypoint, nextWaypoint, nextWaypointIdx)
		-- Build next destination plane
		-- (plane normal is perpendicular to the y plane and is from next waypoint towards current one (provided the two waypoints are not at the same location))
		-- (plane location is at next waypoint)
		this.CurrentWaypointPlaneNormal = currentWaypoint.Position - nextWaypoint.Position
		this.CurrentWaypointPlaneNormal = Vector3.new(this.CurrentWaypointPlaneNormal.X, 0, this.CurrentWaypointPlaneNormal.Z)
		if this.CurrentWaypointPlaneNormal.Magnitude > ALMOST_ZERO then
			this.CurrentWaypointPlaneNormal	= this.CurrentWaypointPlaneNormal.Unit
			this.CurrentWaypointPlaneDistance = this.CurrentWaypointPlaneNormal:Dot(nextWaypoint.Position)
		else
			-- Next waypoint is the same as current waypoint so no plane
			this.CurrentWaypointPlaneNormal	= ZERO_VECTOR3
			this.CurrentWaypointPlaneDistance = 0
		end

		-- Should we jump
		this.CurrentWaypointNeedsJump = nextWaypoint.Action == Enum.PathWaypointAction.Jump;

		-- Remember next waypoint position
		this.CurrentWaypointPosition = nextWaypoint.Position

		-- Move to next point
		this.CurrentPoint = nextWaypointIdx

		-- Finally reset Timeout
		this.Timeout = 0
	end

	function this:Start(overrideShowPath)
		if not this.AgentCanFollowPath then
			this.PathFailed:Fire()
			return
		end

		if this.Started then return end
		this.Started = true

		ClickToMoveDisplay.CancelFailureAnimation()

		if ShowPath then
			if overrideShowPath == nil or overrideShowPath then
				this.stopTraverseFunc, this.setPointFunc = ClickToMoveDisplay.CreatePathDisplay(this.pointList, this.OriginalTargetPoint)
			end
		end

		if #this.pointList > 0 then
			-- Determine the humanoid offset from the path's first point
			if FFlagUserClickToMoveFollowPathRefactor then
				-- Offset of the first waypoint from the path's origin point
				this.HumanoidOffsetFromPath = Vector3.new(0, this.pointList[1].Position.Y - this.OriginPoint.Y, 0)
			else
				-- Humanoid height above ground
				this.HumanoidOffsetFromPath = Vector3.new(0, -(0.5 * this.Humanoid.RootPart.Size.y + this.Humanoid.HipHeight), 0)
			end

			-- As well as its current position and velocity
			this.CurrentHumanoidPosition = this.Humanoid.RootPart.Position + this.HumanoidOffsetFromPath
			this.CurrentHumanoidVelocity = this.Humanoid.RootPart.Velocity

			-- Connect to events
			this.SeatedConn = this.Humanoid.Seated:Connect(function(isSeated, seat) this:OnPathInterrupted() end)
			this.DiedConn = this.Humanoid.Died:Connect(function() this:OnPathInterrupted() end)
			if not FFlagUserClickToMoveFollowPathRefactor then
				this.MoveToConn = this.Humanoid.MoveToFinished:Connect(function(reached) this:OnPointReached(reached) end)
			end
			if FFlagUserClickToMoveFollowPathRefactor then
				this.TeleportedConn = this.Humanoid.RootPart:GetPropertyChangedSignal("CFrame"):Connect(function() this:OnPathInterrupted() end)
			end

			-- Actually start
			this.CurrentPoint = 1 -- The first waypoint is always the start location. Skip it.
			this:OnPointReached(true) -- Move to first point
		else
			this.PathFailed:Fire()
			if this.stopTraverseFunc then
				this.stopTraverseFunc()
			end
		end
	end

	--We always raycast to the ground in the case that the user clicked a wall.
	local offsetPoint = this.TargetPoint + this.TargetSurfaceNormal*1.5
	local ray = Ray.new(offsetPoint, Vector3.new(0,-1,0)*50)
	local newHitPart, newHitPos = Workspace:FindPartOnRayWithIgnoreList(ray, getIgnoreList())
	if newHitPart then
		this.TargetPoint = newHitPos
	end
	this:ComputePath()

	return this
end

-------------------------------------------------------------------------

local function CheckAlive()
	local humanoid = findPlayerHumanoid(Player)
	return humanoid ~= nil and humanoid.Health > 0
end

local function GetEquippedTool(character)
	if character ~= nil then
		for _, child in pairs(character:GetChildren()) do
			if child:IsA('Tool') then
				return child
			end
		end
	end
end

local ExistingPather = nil
local ExistingIndicator = nil
local PathCompleteListener = nil
local PathFailedListener = nil

local function CleanupPath()
	if ExistingPather then
		ExistingPather:Cancel()
		ExistingPather = nil
	end
	if PathCompleteListener then
		PathCompleteListener:Disconnect()
		PathCompleteListener = nil
	end
	if PathFailedListener then
		PathFailedListener:Disconnect()
		PathFailedListener = nil
	end
	if ExistingIndicator then
		ExistingIndicator:Destroy()
	end
end

-- Remove with FFlagUserClickToMoveFollowPathRefactor
local function HandleDirectMoveTo(hitPt, myHumanoid)
	if myHumanoid then
		if myHumanoid.Sit then
			myHumanoid.Jump = true
		end
		myHumanoid:MoveTo(hitPt)
	end

	local endWaypoint = ClickToMoveDisplay.CreateEndWaypoint(hitPt)
	ExistingIndicator = endWaypoint
	coroutine.wrap(function()
		myHumanoid.MoveToFinished:wait()
		endWaypoint:Destroy()
	end)()
end

local function HandleMoveTo(thisPather, hitPt, hitChar, character, overrideShowPath)
	if FFlagUserClickToMoveFollowPathRefactor then
		ExistingPather = thisPather
	end

	thisPather:Start(overrideShowPath)

	if not FFlagUserClickToMoveFollowPathRefactor then
		CleanupPath()
	end

	if not FFlagUserClickToMoveFollowPathRefactor then
		ExistingPather = thisPather
	end

	PathCompleteListener = thisPather.Finished.Event:Connect(function()
		if FFlagUserClickToMoveFollowPathRefactor then
			CleanupPath()
		end
		if hitChar then
			local currentWeapon = GetEquippedTool(character)
			if currentWeapon then
				currentWeapon:Activate()
			end
		end
	end)
	PathFailedListener = thisPather.PathFailed.Event:Connect(function()
		CleanupPath()
		if overrideShowPath == nil or overrideShowPath then
			local shouldPlayFailureAnim = PlayFailureAnimation and not (ExistingPather and ExistingPather:IsActive())
			if shouldPlayFailureAnim then
				ClickToMoveDisplay.PlayFailureAnimation()
			end
			ClickToMoveDisplay.DisplayFailureWaypoint(hitPt)
		end
	end)
end

local function ShowPathFailedFeedback(hitPt)
	if ExistingPather and ExistingPather:IsActive() then
		ExistingPather:Cancel()
	end
	if PlayFailureAnimation then
		ClickToMoveDisplay.PlayFailureAnimation()
	end
	ClickToMoveDisplay.DisplayFailureWaypoint(hitPt)
end

function OnTap(tapPositions, goToPoint, wasTouchTap)
	-- Good to remember if this is the latest tap event
	local camera = Workspace.CurrentCamera
	local character = Player.Character

	if not CheckAlive() then return end

	-- This is a path tap position
	if #tapPositions == 1 or goToPoint then
		if camera then
			local unitRay = camera:ScreenPointToRay(tapPositions[1].x, tapPositions[1].y)
			local ray = Ray.new(unitRay.Origin, unitRay.Direction*1000)

			local myHumanoid = findPlayerHumanoid(Player)
			local hitPart, hitPt, hitNormal = Utility.Raycast(ray, true, getIgnoreList())

			local hitChar, hitHumanoid = Utility.FindCharacterAncestor(hitPart)
			if wasTouchTap and hitHumanoid and StarterGui:GetCore("AvatarContextMenuEnabled") then
				local clickedPlayer = Players:GetPlayerFromCharacter(hitHumanoid.Parent)
				if clickedPlayer then
					CleanupPath()
					return
				end
			end
			if goToPoint then
				hitPt = goToPoint
				hitChar = nil
			end
			if FFlagUserClickToMoveFollowPathRefactor then
				if hitPt and character then
					-- Clean up current path
					CleanupPath()
					local thisPather = Pather(hitPt, hitNormal)
					if thisPather:IsValidPath() then
						HandleMoveTo(thisPather, hitPt, hitChar, character)
					else
						-- Clean up
						thisPather:Cleanup()
						-- Feedback here for when we don't have a good path
						ShowPathFailedFeedback(hitPt)
					end
				end
			else
				if UseDirectPath and hitPt and character then
					HandleDirectMoveTo(hitPt, myHumanoid)
				elseif hitPt and character then
					local thisPather = Pather(hitPt, hitNormal)
					if thisPather:IsValidPath() then
						HandleMoveTo(thisPather, hitPt, hitChar, character)
					else
						if hitPt then
							-- Feedback here for when we don't have a good path
							ShowPathFailedFeedback(hitPt)
						end
					end
				end
			end
		end
	elseif #tapPositions >= 2 then
		if camera then
			-- Do shoot
			local currentWeapon = GetEquippedTool(character)
			if currentWeapon then
				currentWeapon:Activate()
			end
		end
	end
end

local function DisconnectEvent(event)
	if event then
		event:Disconnect()
	end
end

--[[ The ClickToMove Controller Class ]]--
local KeyboardController = require(script.Parent:WaitForChild("Keyboard"))
local ClickToMove = setmetatable({}, KeyboardController)
ClickToMove.__index = ClickToMove

function ClickToMove.new(CONTROL_ACTION_PRIORITY)
	local self = setmetatable(KeyboardController.new(CONTROL_ACTION_PRIORITY), ClickToMove)

	self.fingerTouches = {}
	self.numUnsunkTouches = 0
	-- PC simulation
	self.mouse1Down = tick()
	self.mouse1DownPos = Vector2.new()
	self.mouse2DownTime = tick()
	self.mouse2DownPos = Vector2.new()
	self.mouse2UpTime = tick()

	self.keyboardMoveVector = ZERO_VECTOR3

	self.tapConn = nil
	self.inputBeganConn = nil
	self.inputChangedConn = nil
	self.inputEndedConn = nil
	self.humanoidDiedConn = nil
	self.characterChildAddedConn = nil
	self.onCharacterAddedConn = nil
	self.characterChildRemovedConn = nil
	self.renderSteppedConn = nil
	self.menuOpenedConnection = nil

	self.running = false

	self.wasdEnabled = false

	return self
end

function ClickToMove:DisconnectEvents()
	DisconnectEvent(self.tapConn)
	DisconnectEvent(self.inputBeganConn)
	DisconnectEvent(self.inputChangedConn)
	DisconnectEvent(self.inputEndedConn)
	DisconnectEvent(self.humanoidDiedConn)
	DisconnectEvent(self.characterChildAddedConn)
	DisconnectEvent(self.onCharacterAddedConn)
	DisconnectEvent(self.renderSteppedConn)
	DisconnectEvent(self.characterChildRemovedConn)
	if FFlagUserClickToMoveCancelOnMenuOpened then
		DisconnectEvent(self.menuOpenedConnection)
	end
end

function ClickToMove:OnTouchBegan(input, processed)
	if self.fingerTouches[input] == nil and not processed then
		self.numUnsunkTouches = self.numUnsunkTouches + 1
	end
	self.fingerTouches[input] = processed
end

function ClickToMove:OnTouchChanged(input, processed)
	if self.fingerTouches[input] == nil then
		self.fingerTouches[input] = processed
		if not processed then
			self.numUnsunkTouches = self.numUnsunkTouches + 1
		end
	end
end

function ClickToMove:OnTouchEnded(input, processed)
	if self.fingerTouches[input] ~= nil and self.fingerTouches[input] == false then
		self.numUnsunkTouches = self.numUnsunkTouches - 1
	end
	self.fingerTouches[input] = nil
end


function ClickToMove:OnCharacterAdded(character)
	self:DisconnectEvents()

	self.inputBeganConn = UserInputService.InputBegan:Connect(function(input, processed)
		if input.UserInputType == Enum.UserInputType.Touch then
			self:OnTouchBegan(input, processed)
		end

		-- Cancel path when you use the keyboard controls.
		if processed == false and input.UserInputType == Enum.UserInputType.Keyboard and movementKeys[input.KeyCode] then
			CleanupPath()
			if FFlagUserClickToMoveFollowPathRefactor then
				ClickToMoveDisplay.CancelFailureAnimation()
			end
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.mouse1DownTime = tick()
			self.mouse1DownPos = input.Position
		end
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			self.mouse2DownTime = tick()
			self.mouse2DownPos = input.Position
		end
	end)

	self.inputChangedConn = UserInputService.InputChanged:Connect(function(input, processed)
		if input.UserInputType == Enum.UserInputType.Touch then
			self:OnTouchChanged(input, processed)
		end
	end)

	self.inputEndedConn = UserInputService.InputEnded:Connect(function(input, processed)
		if input.UserInputType == Enum.UserInputType.Touch then
			self:OnTouchEnded(input, processed)
		end

		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			self.mouse2UpTime = tick()
			local currPos = input.Position
			-- We allow click to move during path following or if there is no keyboard movement
			local allowed
			if FFlagUserClickToMoveFollowPathRefactor then
				allowed = ExistingPather or self.keyboardMoveVector.Magnitude <= 0
			else
				allowed = self.moveVector.Magnitude <= 0
			end
			if self.mouse2UpTime - self.mouse2DownTime < 0.25 and (currPos - self.mouse2DownPos).magnitude < 5 and allowed then
				local positions = {currPos}
				OnTap(positions)
			end
		end
	end)

	self.tapConn = UserInputService.TouchTap:Connect(function(touchPositions, processed)
		if not processed then
			OnTap(touchPositions, nil, true)
		end
	end)

	if FFlagUserClickToMoveCancelOnMenuOpened then
		self.menuOpenedConnection = GuiService.MenuOpened:Connect(function()
			CleanupPath()
		end)
	end

	local function OnCharacterChildAdded(child)
		if UserInputService.TouchEnabled then
			if child:IsA('Tool') then
				child.ManualActivationOnly = true
			end
		end
		if child:IsA('Humanoid') then
			DisconnectEvent(self.humanoidDiedConn)
			self.humanoidDiedConn = child.Died:Connect(function()
				if ExistingIndicator then
					DebrisService:AddItem(ExistingIndicator.Model, 1)
				end
			end)
		end
	end

	self.characterChildAddedConn = character.ChildAdded:Connect(function(child)
		OnCharacterChildAdded(child)
	end)
	self.characterChildRemovedConn = character.ChildRemoved:Connect(function(child)
		if UserInputService.TouchEnabled then
			if child:IsA('Tool') then
				child.ManualActivationOnly = false
			end
		end
	end)
	for _, child in pairs(character:GetChildren()) do
		OnCharacterChildAdded(child)
	end
end

function ClickToMove:Start()
	self:Enable(true)
end

function ClickToMove:Stop()
	self:Enable(false)
end

function ClickToMove:Enable(enable, enableWASD, touchJumpController)
	if enable then
		if not self.running then
			if Player.Character then -- retro-listen
				self:OnCharacterAdded(Player.Character)
			end
			self.onCharacterAddedConn = Player.CharacterAdded:Connect(function(char)
				self:OnCharacterAdded(char)
			end)
			self.running = true
		end
		self.touchJumpController = touchJumpController
		if self.touchJumpController then
			self.touchJumpController:Enable(self.jumpEnabled)
		end
	else
		if self.running then
			self:DisconnectEvents()
			CleanupPath()
			-- Restore tool activation on shutdown
			if UserInputService.TouchEnabled then
				local character = Player.Character
				if character then
					for _, child in pairs(character:GetChildren()) do
						if child:IsA('Tool') then
							child.ManualActivationOnly = false
						end
					end
				end
			end
			self.running = false
		end
		if self.touchJumpController and not self.jumpEnabled then
			self.touchJumpController:Enable(true)
		end
		self.touchJumpController = nil
	end

	-- Extension for initializing Keyboard input as this class now derives from Keyboard
	if UserInputService.KeyboardEnabled and enable ~= self.enabled then

		self.forwardValue  = 0
		self.backwardValue = 0
		self.leftValue = 0
		self.rightValue = 0

		self.moveVector = ZERO_VECTOR3

		if enable then
			self:BindContextActions()
			self:ConnectFocusEventListeners()
		else
			self:UnbindContextActions()
			self:DisconnectFocusEventListeners()
		end
	end

	self.wasdEnabled = enable and enableWASD or false
	self.enabled = enable
end

function ClickToMove:OnRenderStepped(dt)
	if not FFlagUserClickToMoveFollowPathRefactor then
		return
	end

	-- Reset jump
	self.isJumping = false

	-- Handle Pather
	if ExistingPather then
		-- Let the Pather update
		ExistingPather:OnRenderStepped(dt)

		-- If we still have a Pather, set the resulting actions
		if ExistingPather then
			-- Setup move (NOT relative to camera)
			self.moveVector = ExistingPather.NextActionMoveDirection
			self.moveVectorIsCameraRelative = false

			-- Setup jump (but do NOT prevent the base Keayboard class from requesting jumps as well)
			if ExistingPather.NextActionJump then
				self.isJumping = true
			end
		else
			self.moveVector = self.keyboardMoveVector
			self.moveVectorIsCameraRelative = true
		end
	else
		self.moveVector = self.keyboardMoveVector
		self.moveVectorIsCameraRelative = true
	end

	-- Handle Keyboard's jump
	if self.jumpRequested then
		self.isJumping = true
	end
end

-- Overrides Keyboard:UpdateMovement(inputState) to conditionally consider self.wasdEnabled and let OnRenderStepped handle the movement
function ClickToMove:UpdateMovement(inputState)
	if FFlagUserClickToMoveFollowPathRefactor then
		if inputState == Enum.UserInputState.Cancel then
			self.keyboardMoveVector = ZERO_VECTOR3
		elseif self.wasdEnabled then
			self.keyboardMoveVector = Vector3.new(self.leftValue + self.rightValue, 0, self.forwardValue + self.backwardValue)
		end
	else
		if inputState == Enum.UserInputState.Cancel then
			self.moveVector = ZERO_VECTOR3
		elseif self.wasdEnabled then
			self.moveVector = Vector3.new(self.leftValue + self.rightValue, 0, self.forwardValue + self.backwardValue)
			if self.moveVector.magnitude > 0 then
				CleanupPath()
				ClickToMoveDisplay.CancelFailureAnimation()
			end
		end
	end
end

-- Overrides Keyboard:UpdateJump() because jump is handled in OnRenderStepped
function ClickToMove:UpdateJump()
	if FFlagUserClickToMoveFollowPathRefactor then
		-- Nothing to do (handled in OnRenderStepped)
	else
		self.isJumping = self.jumpRequested
	end
end

--Public developer facing functions
function ClickToMove:SetShowPath(value)
	ShowPath = value
end

function ClickToMove:GetShowPath()
	return ShowPath
end

function ClickToMove:SetWaypointTexture(texture)
	ClickToMoveDisplay.SetWaypointTexture(texture)
end

function ClickToMove:GetWaypointTexture()
	return ClickToMoveDisplay.GetWaypointTexture()
end

function ClickToMove:SetWaypointRadius(radius)
	ClickToMoveDisplay.SetWaypointRadius(radius)
end

function ClickToMove:GetWaypointRadius()
	return ClickToMoveDisplay.GetWaypointRadius()
end

function ClickToMove:SetEndWaypointTexture(texture)
	ClickToMoveDisplay.SetEndWaypointTexture(texture)
end

function ClickToMove:GetEndWaypointTexture()
	return ClickToMoveDisplay.GetEndWaypointTexture()
end

function ClickToMove:SetWaypointsAlwaysOnTop(alwaysOnTop)
	ClickToMoveDisplay.SetWaypointsAlwaysOnTop(alwaysOnTop)
end

function ClickToMove:GetWaypointsAlwaysOnTop()
	return ClickToMoveDisplay.GetWaypointsAlwaysOnTop()
end

function ClickToMove:SetFailureAnimationEnabled(enabled)
	PlayFailureAnimation = enabled
end

function ClickToMove:GetFailureAnimationEnabled()
	return PlayFailureAnimation
end

function ClickToMove:SetIgnoredPartsTag(tag)
	UpdateIgnoreTag(tag)
end

function ClickToMove:GetIgnoredPartsTag()
	return CurrentIgnoreTag
end

function ClickToMove:SetUseDirectPath(directPath)
	UseDirectPath = directPath
end

function ClickToMove:GetUseDirectPath()
	return UseDirectPath
end

function ClickToMove:SetAgentSizeIncreaseFactor(increaseFactorPercent)
	AgentSizeIncreaseFactor = 1.0 + (increaseFactorPercent / 100.0)
end

function ClickToMove:GetAgentSizeIncreaseFactor()
	return (AgentSizeIncreaseFactor - 1.0) * 100.0
end

function ClickToMove:SetUnreachableWaypointTimeout(timeoutInSec)
	UnreachableWaypointTimeout = timeoutInSec
end

function ClickToMove:GetUnreachableWaypointTimeout()
	return UnreachableWaypointTimeout
end

function ClickToMove:SetUserJumpEnabled(jumpEnabled)
	self.jumpEnabled = jumpEnabled
	if self.touchJumpController then
		self.touchJumpController:Enable(jumpEnabled)
	end
end

function ClickToMove:GetUserJumpEnabled()
	return self.jumpEnabled
end

function ClickToMove:MoveTo(position, showPath, useDirectPath)
	local character = Player.Character
	if character == nil then
		return false
	end
	local thisPather = Pather(position, Vector3.new(0, 1, 0), useDirectPath)
	if thisPather and thisPather:IsValidPath() then
		if FFlagUserClickToMoveFollowPathRefactor then
			-- Clean up previous path
			CleanupPath()
		end
		HandleMoveTo(thisPather, position, nil, character, showPath)
		return true
	end
	return false
end

return ClickToMove
