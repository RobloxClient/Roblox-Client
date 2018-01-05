return function()
    local Modules = game:GetService("CoreGui"):FindFirstChild("RobloxGui").Modules
    local SelectCategoryTab = require(Modules.LuaApp.Actions.SelectCategoryTab)

    describe("Action SelectCategoryTab", function()
        it("should return a correct action name", function()
            expect(SelectCategoryTab.name).to.equal("SelectCategoryTab")
        end)
        it("should return a correct action type name", function()
            local action = SelectCategoryTab(1, 2, Vector2.new(0,0))
            expect(action.type).to.equal(SelectCategoryTab.name)
        end)
        it("should return a SelectCategoryTab action with the correct status", function()
            local action = SelectCategoryTab(1, 2, Vector2.new(0,0))

            expect(action).to.be.a("table")
            expect(action.categoryIndex).to.be.a("number")
            expect(action.categoryIndex).to.equal(1)
            expect(action.tabIndex).to.be.a("number")
            expect(action.tabIndex).to.equal(2)
            expect(action.position).to.be.a("userdata")
            expect(action.position).to.equal(Vector2.new(0,0))
        end)
    end)
end