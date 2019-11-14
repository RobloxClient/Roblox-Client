return function()
	local LoadingRoot = script.Parent
	local UIBloxRoot = LoadingRoot.Parent
	local Roact = require(UIBloxRoot.Parent.Roact)
	local mockStyleComponent = require(UIBloxRoot.Utility.mockStyleComponent)
	local ShimmerPanel = require(LoadingRoot.ShimmerPanel)

	it("should create and destroy without errors", function()
		local element = mockStyleComponent({
			ShimmerPanel = Roact.createElement(ShimmerPanel, {
				Size = UDim2.new(0, 100, 0, 100),
			})
		})

		local instance = Roact.mount(element)
		Roact.unmount(instance)
	end)
end