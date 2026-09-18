AddCSLuaFile()
module("trm_math", package.seeall)
trm_math.ZeroVector = Vector(0, 0, 0)
trm_math.ZeroAngle = Angle(0, 0, 0)
local clamp = math.Clamp
local Lerp = Lerp
--add and mul
function trm_math.Clamp(value , min , max)
    return clamp(value, min or 0, max or 1)
end

function trm_math.VectorAddAndMul(current, add, mul)
    current.x = current.x + (add.x * mul)
    current.y = current.y + (add.y * mul)
    current.z = current.z + (add.z * mul)
end

function trm_math.AngleAddAndMul(current, add, mul)
    current.p = current.p + (add.p * mul)
    current.y = current.y + (add.y * mul)
    current.r = current.r + (add.r * mul)
end
--Rotate Axis
function trm_math.RotateAxis(ang,add)
    ang:RotateAroundAxis(ang:Forward(), add.r)
    ang:RotateAroundAxis(ang:Right(), add.y)
    ang:RotateAroundAxis(ang:Up(), add.p)
end

function trm_math.SafeLerp(fraction , origin ,  target )
    return Lerp(clamp(fraction ,0 , 1), origin, target)
end

function trm_math.SafeLerpAngle(fraction , origin , target)
    return LerpAngle(trm_math.Clamp(fraction), origin, target)
end

function trm_math.SafeLerpVector( t , a , b)
    return LerpVector(trm_math.Clamp(t), a, b)
end