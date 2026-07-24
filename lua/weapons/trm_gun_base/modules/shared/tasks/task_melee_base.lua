local task = {}

task.Name = "Melee_Attack"

function task:OnSet(weapon)
    weapon:RemoveFlag("MeleeTriggered")
    local tbl = weapon.Primary.Attack[weapon:GetBrustCount()]
    if not tbl then return  end
    weapon:PlayAnimation(tbl.Animation, true)
end

function task:Think(cycle, weapon)
    local tbl = weapon.Primary.Attack[weapon:GetBrustCount()]

    if tbl and ! weapon:HasFlag("MeleeTriggered") and cycle > ( tbl and tbl.Cycle or 0.2) then
        weapon:DoMeleeAttackDamage(tbl)
        weapon:AddFlag("MeleeTriggered")

        if tbl.Sound then
            weapon:EmitSound(tbl.Sound)
        end

        weapon:CycleComboIndex()


    end


    if weapon:GetNextPrimaryFire() < CurTime() then
        weapon:TrySetTask("Idle")
    end
end

SWEP:RegisterTask(task)
