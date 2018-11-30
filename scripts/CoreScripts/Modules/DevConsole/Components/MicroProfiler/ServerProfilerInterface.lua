local CorePackages = game:GetService("CorePackages")
local Settings = UserSettings()
local GameSettings = Settings.GameSettings

local getClientReplicator = require(script.Parent.Parent.Parent.Util.getClientReplicator)

local Roact = require(CorePackages.Roact)
local RoactRodux = require(CorePackages.RoactRodux)

local Components = script.Parent.Parent.Parent.Components
local ServerJobsChart = require(Components.ServerJobs.ServerJobsChart)
local UtilAndTab = require(Components.UtilAndTab)

local Constants = require(script.Parent.Parent.Parent.Constants)
local PADDING = Constants.GeneralFormatting.MainRowPadding
local BUTTON_WIDTH = Constants.MicroProfilerFormatting.ButtonWidth
local TEXT_SIZE = Constants.MicroProfilerFormatting.ButtonTextSize
local FONT = Constants.Font.MainWindow
local HEADER_FONT = Constants.Font.MainWindowHeader
local BUTTON_UNSELECTED = Constants.Color.UnselectedGray
local BUTTON_SELECTED = Constants.Color.SelectedBlue

local BUTTON_COLOR = Constants.Color.UnselectedGray

local ROW_HEIGHT = 30
local OFFSET = .10
local ROW_VALUE_WIDTH = .8

local ServerProfilerInteraface = Roact.Component:extend("ServerProfilerInteraface")

function ServerProfilerInteraface:init()
	self.onUtilTabHeightChanged = function(utilTabHeight)
		self:setState({
			utilTabHeight = utilTabHeight
		})
	end

	self.onFocusLostFrameRate = function(rbx, enterPressed, inputThatCausedFocusLoss)
		if enterPressed then
			GameSettings.RCCProfilerRecordFrameRate = rbx.Text
		end

		rbx.Text = GameSettings.RCCProfilerRecordFrameRate
	end

	self.onFocusLostTimeFrame = function(rbx, enterPressed, inputThatCausedFocusLoss)
		if enterPressed then
			GameSettings.RCCProfilerRecordTimeFrame = rbx.Text
		end

		rbx.Text = GameSettings.RCCProfilerRecordTimeFrame
	end

	self.requestRCCProfilerData = function(rbx)
		local clientReplicator = getClientReplicator()
		if clientReplicator then
			clientReplicator:RequestRCCProfilerData(
				GameSettings.RCCProfilerRecordFrameRate,
				GameSettings.RCCProfilerRecordTimeFrame
			)

			self:setState({
				waitingForData = true
			})
		end
	end

	self.changeProfilerState = function(screenProfilerEnabled)
		return function()
			GameSettings.OnScreenProfilerEnabled = screenProfilerEnabled
			self:setState({
				clientProfilerEnabled = screenProfilerEnabled
			})
		end
	end

	self.state = {
		waitingForData = false,
		frameRate = GameSettings.RCCProfilerRecordFrameRate,
		timeFrame = GameSettings.RCCProfilerRecordTimeFrame,
	}
end

function ServerProfilerInteraface:didMount()
	local clientReplicator = getClientReplicator()
	if clientReplicator then
		self.completeSignal = clientReplicator.RCCProfilerDataComplete:connect(function(success, message)
			if self.state.waitingForData then
				if not success then
					warn(message)
					self:setState({
						waitingForData = false
					})
				else
					self:setState({
						waitingForData = false,
						outputPath = message,
					})
				end
			end
		end)
	end
end

function ServerProfilerInteraface:willUnmount()
	if self.completeSignal then
		self.completeSignal:Disconnect()
		self.completeSignal = nil
	end
end

function ServerProfilerInteraface:render()
	local size = self.props.size
	local formFactor = self.props.formFactor
	local tabList = self.props.tabList

	local utilTabHeight = self.state.utilTabHeight

	local frameRate = self.state.frameRate
	local timeFrame = self.state.timeFrame
	local waitingForData = self.state.waitingForData
	local clientProfilerEnabled = self.state.clientProfilerEnabled
	local outputPath = self.state.outputPath

	local textbox_size = UDim2.new(ROW_VALUE_WIDTH, -BUTTON_WIDTH, 0, ROW_HEIGHT)
	local textbox_pos = UDim2.new(1 - ROW_VALUE_WIDTH / 2, BUTTON_WIDTH, 0, 0)

	return Roact.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT * 4.5),
		BackgroundTransparency = 1,
		LayoutOrder = 4,
	}, {
		Label = Roact.createElement("TextLabel", {
			Size = UDim2.new(0, BUTTON_WIDTH, 0, ROW_HEIGHT),
			Position = UDim2.new(OFFSET, 0, 0, 0),
			Text = "ServerProfiler",
			Font = HEADER_FONT,
			TextSize = TEXT_SIZE,
			TextColor3 = Constants.Color.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			BackgroundColor3 = BUTTON_COLOR,
			BackgroundTransparency = 1,
		}),

		HorizontalLine = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 0, ROW_HEIGHT),
		}),

		LabelFPS = Roact.createElement("TextLabel", {
			Size = UDim2.new(0, BUTTON_WIDTH, 0, ROW_HEIGHT),
			Position = UDim2.new(OFFSET, 0, 0, ROW_HEIGHT * 1.25),
			Text = "Frames Per Second",
			Font = FONT,
			TextSize = TEXT_SIZE,
			TextColor3 = Constants.Color.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			BackgroundColor3 = BUTTON_COLOR,
			BackgroundTransparency = 1,
		}),

		FPSTextBox = Roact.createElement("TextBox", {
			Size = textbox_size,
			Position = UDim2.new((1 - ROW_VALUE_WIDTH)/2, BUTTON_WIDTH, 0, ROW_HEIGHT * 1.25),
			Text = frameRate,
			Font = FONT,
			TextSize = TEXT_SIZE,
			TextColor3 = Constants.Color.Text,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			BackgroundColor3 = BUTTON_COLOR,
			BackgroundTransparency = 0,

			[Roact.Event.FocusLost] = self.onFocusLostFrameRate,
		}),


		LabelTimeFrame = Roact.createElement("TextLabel", {
			Size = UDim2.new(0, BUTTON_WIDTH, 0, ROW_HEIGHT),
			Position = UDim2.new(OFFSET, 0, 0, ROW_HEIGHT * 2.25),
			Text = "Seconds to Record",
			Font = FONT,
			TextSize = TEXT_SIZE,
			TextColor3 = Constants.Color.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			BackgroundTransparency = 1,
		}),

		TimeFrameTextBox = Roact.createElement("TextBox", {
			Size = textbox_size,
			Position = UDim2.new((1 - ROW_VALUE_WIDTH)/2, BUTTON_WIDTH, 0, ROW_HEIGHT * 2.25),
			Text = timeFrame,
			Font = FONT,
			TextSize = TEXT_SIZE,
			TextColor3 = Constants.Color.Text,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			BackgroundColor3 = BUTTON_COLOR,
			BackgroundTransparency = 0,

			[Roact.Event.FocusLost] = self.onFocusLostTimeFrame,
		},{
			-- placed here to better position this element
			GetDumpButton = Roact.createElement("TextButton", {
				Size = UDim2.new(0, BUTTON_WIDTH * .7, 0, ROW_HEIGHT),
				Position = UDim2.new(1, -BUTTON_WIDTH * .7, 1, ROW_HEIGHT),
				Text = waitingForData and "Recording" or "Start Recording",
				Font = FONT,
				TextSize = TEXT_SIZE,
				TextColor3 = Constants.Color.Text,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				BackgroundColor3 = waitingForData and BUTTON_UNSELECTED or BUTTON_SELECTED,
				BackgroundTransparency = waitingForData and .3 or 0,
				AutoButtonColor = not waitingForData,
				Active = not waitingForData,

				[Roact.Event.Activated] = self.requestRCCProfilerData,
			})
		}),

		OutputPath = ((not waitingForData) and outputPath) and Roact.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
			Position = UDim2.new(0, 0, 0, ROW_HEIGHT * 3.25),
			Text = outputPath,
			Font = FONT,
			TextSize = TEXT_SIZE,
			TextColor3 = Constants.Color.Text,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		})
	})
end

return ServerProfilerInteraface