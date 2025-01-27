return function()
	local Promise = require(game.ReplicatedStorage.Packages.Promise)

	describe("Promise.new", function()
		it("should instantiate with a callback", function()
			local promise = Promise.new(function() end)

			expect(promise).to.be.ok()
		end)

		it("should invoke the given callback with resolve and reject", function()
			local callCount = 0
			local resolveArg
			local rejectArg

			local promise = Promise.new(function(resolve, reject)
				callCount = callCount + 1
				resolveArg = resolve
				rejectArg = reject
			end)

			expect(promise).to.be.ok()

			expect(callCount).to.equal(1)
			expect(resolveArg).to.be.a("function")
			expect(rejectArg).to.be.a("function")
			expect(promise._status).to.equal(Promise.Status.Started)
		end)

		it("should resolve promises on resolve()", function()
			local callCount = 0

			local promise = Promise.new(function(resolve)
				callCount = callCount + 1
				resolve()
			end)

			expect(promise).to.be.ok()
			expect(callCount).to.equal(1)
			expect(promise._status).to.equal(Promise.Status.Resolved)
		end)

		it("should reject promises on reject()", function()
			local callCount = 0

			local promise = Promise.new(function(resolve, reject)
				callCount = callCount + 1
				reject()
			end)

			expect(promise).to.be.ok()
			expect(callCount).to.equal(1)
			expect(promise._status).to.equal(Promise.Status.Rejected)
		end)

		it("should reject on error in callback", function()
			local callCount = 0

			local promise = Promise.new(function()
				callCount = callCount + 1
				error("hahah")
			end)

			expect(promise).to.be.ok()
			expect(callCount).to.equal(1)
			expect(promise._status).to.equal(Promise.Status.Rejected)
			expect((promise._value[1]:find("hahah"))).to.be.ok()
		end)
	end)

	describe("Promise.resolve", function()
		it("should immediately resolve with a value", function()
			local promise = Promise.resolve(5)

			expect(promise).to.be.ok()
			expect(promise._status).to.equal(Promise.Status.Resolved)
			expect(promise._value[1]).to.equal(5)
		end)

		it("should chain onto passed promises", function()
			local promise = Promise.resolve(Promise.new(function(_, reject)
				reject(7)
			end))

			expect(promise).to.be.ok()
			expect(promise._status).to.equal(Promise.Status.Rejected)
			expect(promise._value[1]).to.equal(7)
		end)
	end)

	describe("Promise.reject", function()
		it("should immediately reject with a value", function()
			local promise = Promise.reject(6)

			expect(promise).to.be.ok()
			expect(promise._status).to.equal(Promise.Status.Rejected)
			expect(promise._value[1]).to.equal(6)
		end)

		it("should pass a promise as-is as an error", function()
			local innerPromise = Promise.new(function(resolve)
				resolve(6)
			end)

			local promise = Promise.reject(innerPromise)

			expect(promise).to.be.ok()
			expect(promise._status).to.equal(Promise.Status.Rejected)
			expect(promise._value[1]).to.equal(innerPromise)
		end)
	end)

	describe("Promise:andThen", function()
		it("should chain onto resolved promises", function()
			local args
			local argsLength
			local callCount = 0
			local badCallCount = 0

			local promise = Promise.resolve(5)

			local chained = promise
				:andThen(function(...)
					args = {...}
					argsLength = select("#", ...)
					callCount = callCount + 1
				end, function()
					badCallCount = badCallCount + 1
				end)

			expect(badCallCount).to.equal(0)

			expect(callCount).to.equal(1)
			expect(argsLength).to.equal(1)
			expect(args[1]).to.equal(5)

			expect(promise).to.be.ok()
			expect(promise._status).to.equal(Promise.Status.Resolved)
			expect(promise._value[1]).to.equal(5)

			expect(chained).to.be.ok()
			expect(chained).never.to.equal(promise)
			expect(chained._status).to.equal(Promise.Status.Resolved)
			expect(#chained._value).to.equal(0)
		end)

		it("should chain onto rejected promises", function()
			local args
			local argsLength
			local callCount = 0
			local badCallCount = 0

			local promise = Promise.reject(5)

			local chained = promise
				:andThen(function(...)
					badCallCount = badCallCount + 1
				end, function(...)
					args = {...}
					argsLength = select("#", ...)
					callCount = callCount + 1
				end)

			expect(badCallCount).to.equal(0)

			expect(callCount).to.equal(1)
			expect(argsLength).to.equal(1)
			expect(args[1]).to.equal(5)

			expect(promise).to.be.ok()
			expect(promise._status).to.equal(Promise.Status.Rejected)
			expect(promise._value[1]).to.equal(5)

			expect(chained).to.be.ok()
			expect(chained).never.to.equal(promise)
			expect(chained._status).to.equal(Promise.Status.Resolved)
			expect(#chained._value).to.equal(0)
		end)

		it("should chain onto asynchronously resolved promises", function()
			local args
			local argsLength
			local callCount = 0
			local badCallCount = 0

			local startResolution
			local promise = Promise.new(function(resolve)
				startResolution = resolve
			end)

			local chained = promise
				:andThen(function(...)
					args = {...}
					argsLength = select("#", ...)
					callCount = callCount + 1
				end, function()
					badCallCount = badCallCount + 1
				end)

			expect(callCount).to.equal(0)
			expect(badCallCount).to.equal(0)

			startResolution(6)

			expect(badCallCount).to.equal(0)

			expect(callCount).to.equal(1)
			expect(argsLength).to.equal(1)
			expect(args[1]).to.equal(6)

			expect(promise).to.be.ok()
			expect(promise._status).to.equal(Promise.Status.Resolved)
			expect(promise._value[1]).to.equal(6)

			expect(chained).to.be.ok()
			expect(chained).never.to.equal(promise)
			expect(chained._status).to.equal(Promise.Status.Resolved)
			expect(#chained._value).to.equal(0)
		end)

		it("should chain onto asynchronously rejected promises", function()
			local args
			local argsLength
			local callCount = 0
			local badCallCount = 0

			local startResolution
			local promise = Promise.new(function(_, reject)
				startResolution = reject
			end)

			local chained = promise
				:andThen(function()
					badCallCount = badCallCount + 1
				end, function(...)
					args = {...}
					argsLength = select("#", ...)
					callCount = callCount + 1
				end)

			expect(callCount).to.equal(0)
			expect(badCallCount).to.equal(0)

			startResolution(6)

			expect(badCallCount).to.equal(0)

			expect(callCount).to.equal(1)
			expect(argsLength).to.equal(1)
			expect(args[1]).to.equal(6)

			expect(promise).to.be.ok()
			expect(promise._status).to.equal(Promise.Status.Rejected)
			expect(promise._value[1]).to.equal(6)

			expect(chained).to.be.ok()
			expect(chained).never.to.equal(promise)
			expect(chained._status).to.equal(Promise.Status.Resolved)
			expect(#chained._value).to.equal(0)
		end)
	end)

	describe("Promise.all", function()
		it("should resolve immediately with an empty table argument", function()
			local promise = Promise.all({})

			expect(promise).to.be.ok()
			expect(promise._status).to.equal(Promise.Status.Resolved)

			local result = unpack(promise._value)
			expect(type(result)).to.equal("table")
			expect(#result).to.equal(0)
		end)

		it("should resolve immediately with no arguments", function()
			local promise = Promise.all()

			expect(promise).to.be.ok()
			expect(promise._status).to.equal(Promise.Status.Resolved)

			local result = unpack(promise._value)
			expect(type(result)).to.equal("table")
			expect(#result).to.equal(0)
		end)

		it("should resolve with one result with one resolved argument", function()
			local promise = Promise.all(Promise.resolve(7))

			expect(promise).to.be.ok()
			expect(promise._status).to.equal(Promise.Status.Resolved)

			local result = unpack(promise._value)
			expect(type(result)).to.equal("table")
			expect(#result).to.equal(1)
			expect(result[1]).to.equal(7)
		end)

		it("should resolve with multiple resolved arguments", function()
			local promise = Promise.all(Promise.resolve(7), Promise.resolve(4))

			expect(promise).to.be.ok()
			expect(promise._status).to.equal(Promise.Status.Resolved)

			local result = unpack(promise._value)
			expect(type(result)).to.equal("table")
			expect(#result).to.equal(2)
			expect(result[1]).to.equal(7)
			expect(result[2]).to.equal(4)
		end)

		it("should reject with one rejected argument", function()
			local promise = Promise.all(Promise.reject(5))

			expect(promise).to.be.ok()
			expect(promise._status).to.equal(Promise.Status.Rejected)

			local result = unpack(promise._value)
			expect(result).to.equal(5)
		end)

		it("should reject with one success followed by one rejected argument", function()
			local promise = Promise.all(Promise.resolve(7), Promise.reject(4))

			expect(promise).to.be.ok()
			expect(promise._status).to.equal(Promise.Status.Rejected)

			local result = unpack(promise._value)
			expect(result).to.equal(4)
		end)


		it("should accept a table of named promises", function()
			local promise = Promise.all({
				testValue1 = Promise.resolve(7),
				testValue2 = Promise.resolve(3),
			})

			expect(promise).to.be.ok()
			expect(promise._status).to.equal(Promise.Status.Resolved)

			local result = unpack(promise._value)
			expect(type(result)).to.equal("table")
			expect(result.testValue1).to.equal(7)
			expect(result.testValue2).to.equal(3)
		end)
	end)
end
