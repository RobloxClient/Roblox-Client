--[[
	Package link auto-generated by manage_libraries and Rotriever
]]
local FFlagPivotEditorDeduplicatePackages = game:GetFastFlag("PivotEditorDeduplicatePackages")
if FFlagPivotEditorDeduplicatePackages then
	local PackageIndex = script.Parent.Parent.Parent._Index
	local Package = require(PackageIndex["roblox_t"]["t"])
	return Package
else
	local PackageIndex = script.Parent.Parent.Parent._IndexOld
	return require(PackageIndex["roblox_t"]["t"])
end

