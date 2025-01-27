--[[
	Utility function for fast fowarding all the particles on the character some
    number of frames.
]]
local module = {}

-- API specifies 16.7 ms per frame, so jump fwd 4 seconds.
local NUM_FRAMES_TO_FFWD =  4*60

module.InstanceIsAParticleEffect = function(instance)
	return instance:IsA("ParticleEmitter") or
		instance:IsA("Fire") or
		instance:IsA("Smoke") or
		instance:IsA("Sparkles")
end

local function recurFastForwardParticles(instance)
    if module.InstanceIsAParticleEffect(instance) then
        instance:FastForward(NUM_FRAMES_TO_FFWD)
    end
    local children = instance:GetChildren()
    for _, child in children do
        recurFastForwardParticles(child)
    end
end

module.FastForwardParticles = function(character)
    recurFastForwardParticles(character)
end

return module
