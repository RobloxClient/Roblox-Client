local Root = script.Parent
local Packages = Root.Parent
local Types = require(Packages.MessageBus)

export type LaunchParams = {
	placeId: string | number | nil,
	userId: string | number | nil,
}

export type GameProtocol = {
	GAME_LAUNCH_DESCRIPTOR: Types.MessageDescriptor,

	launchGame: (GameProtocol, LaunchParams, string?, (string) -> () | nil) -> (),

	subscriber: Types.Subscriber,
}

return nil
