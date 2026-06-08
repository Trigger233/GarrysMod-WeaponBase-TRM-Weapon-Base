if not CLIENT then return end
local tracerName = "Tracer"
local Tracerscale = 5000
local tracerStart

local utilf = util.Effect


net.Receive("TRMBase_TracerEffect", function(len)
    local weapon = net.ReadEntity()
    local startPos = net.ReadVector()
    local endPos = net.ReadVector()
    if IsValid(weapon ) then
        --weapon:DoTracer(startPos,endPos)
    end
end)


function SWEP:MuzzleEffects()

end
