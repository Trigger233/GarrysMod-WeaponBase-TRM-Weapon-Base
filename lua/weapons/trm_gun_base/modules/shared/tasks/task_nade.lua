local task_pre = {}

task_pre.Name = "Nade_PreThrow"
function task_pre:OnSet(w)
    w:PlayAnimation("PreThrow",true)
end

function task_pre:Think(c,w)
    if not w:GetOwner():KeyDown(IN_ATTACK) then
        w:TrySetTask("Throw")
        return
    end
    
    w:SetNextPrimaryFire(CurTime() + FrameTime() )
end

SWEP:RegisterTask(task_pre)

local task_throw = {}

task_throw.Name = "Throw"

function task_throw:CanBeSet(w)
    return w:GetNextPrimaryFire() <= CurTime()
end

function task_throw:OnSet(w)
    w:SetNextAnimationTime(0)
    w:PlayAnimation("Throw",true)
end

function task_throw:Think(c,w)
    if c > math.Clamp(w.Primary.Delay,0,1) then
        w:TakePrimaryAmmo(1)
        w:Throw(w.Primary)

        if w:Ammo1() == 0 then
            w:Remove()
        end
        w:TrySetTask("Idle")

    end
end



SWEP:RegisterTask(task_throw)