local SocialLuaAnalytics = script.Parent.Parent.Parent
local dependencies = require(SocialLuaAnalytics.dependencies)
local enumerate = dependencies.enumerate

return enumerate(script.Name, {
	ContactImport = "contactImport",
	HomePage = "homepage",
	MorePage = "morepage",
	GameDetails = "gameDetails",
	PlayerSearch = "playerSearch",
	PlayerProfile = "playerProfile",
	SocialTab = "SocialTab",
	FriendsLanding = "friendsLanding",
	Chat = "chat",

	-- TODO SOCCONN-1976 these refer to the same page, we should standardise this
	AddFriends = "addUniversalFriends",
	FriendRequests = "friendRequestsPage",
})
