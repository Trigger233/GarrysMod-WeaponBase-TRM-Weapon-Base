local function isReloadSeq(seq)
    return seq and (string.find(seq, "Reload") or string.find(seq, "reload"))
end

local task_reload = {}
task_reload.Name = "Reload"
task_reload.Priority = 200

function task_reload:CanBeSet(weapon)
    return weapon:CanReload()
end

function task_reload:OnSet(weapon)
    weapon:SetNextAnimationTime(0)
    local seq = weapon:GetPlayingSequence()
    if not isReloadSeq(seq) then
        if weapon.ReloadType == "Single" then
            if weapon:Clip1() == 0 and weapon.Animations.Reload_Empty then
                weapon:PlayAnimation("Reload_Empty", true)
            elseif weapon.Animations.Reload_Start then
                weapon:PlayAnimation("Reload_Start", true)
            end
        else
            if weapon:Clip1() == 0 and weapon.Animations.Reload_Empty then
                weapon:PlayAnimation("Reload_Empty", true)
            elseif weapon.Animations.Reload then
                weapon:PlayAnimation("Reload", true)
            end
        end
    end
end

function task_reload:Think(cycle, weapon)
    if weapon.ReloadType == "Single" then
        if cycle >= 0.98 then
            weapon:TrySetTask("ReloadLoop")
        end
    else
        if cycle >= 0.98 then
            weapon:TrySetTask("Idle")
        end
    end
end

SWEP:RegisterTask(task_reload)

local task_loop = {}
task_loop.Name = "ReloadLoop"
task_loop.Priority = 200

function task_loop:CanBeSet(weapon)
    return true
end

function task_loop:OnSet(weapon)

end

function task_loop:Think(cycle, weapon)
    local max = weapon:GetMaxClip1() + weapon:GetChamberAmmo()
    local reserve = weapon:GetOwner():GetAmmoCount(weapon:GetPrimaryAmmoType())
    if weapon:Clip1() < max and reserve > 0 then
        weapon:PlayAnimation("Reload", true)
    else
        weapon:TrySetTask("ReloadEnd")
    end
end

SWEP:RegisterTask(task_loop)

local task_end = {}
task_end.Name = "ReloadEnd"
task_end.Priority = 200

function task_end:CanBeSet(weapon)
    return true
end

function task_end:OnSet(weapon)
end

function task_end:Think(cycle, weapon)
    if weapon:IsAnimFinished() then
        weapon:PlayAnimation(weapon:ChooseAnim("Reload_End"), true)
        weapon:TrySetTask("Idle")
    end
end

SWEP:RegisterTask(task_end)
