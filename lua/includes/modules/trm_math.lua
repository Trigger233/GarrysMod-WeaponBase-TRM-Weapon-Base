AddCSLuaFile()
module("trm_math", package.seeall)
trm_math.ZeroVector = Vector(0, 0, 0)
trm_math.ZeroAngle = Angle(0, 0, 0)

--add and mul
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
