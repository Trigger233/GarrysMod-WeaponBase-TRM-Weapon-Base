


function SWEP:SetupDataTables()
    self:NetworkVar("Int" , "WeaponTag")

    self:NetworkVar("Float", "AimDelta")
    self:NetworkVar("Int", "ChamberAmmo")
    self:NetworkVar("Int", "SecondaryChamberAmmo")
    self:NetworkVar("Float", "SprintDelta")
    self:NetworkVar("Float", "NextAnimationTime")
    self:NetworkVar("Float", "NextReadyTime")
    self:NetworkVar("Entity", "NextWeapon")
    self:NetworkVar("Bool", "Grip1")
    self:NetworkVar("Bool", "Grip2")
    self:NetworkVar("Bool", "FirstDeployed")
    self:NetworkVar("Bool", "Underbarrel")
    self:NetworkVar("Int", "CurrentTask")
    self:NetworkVar("String", "PlayingSequence")
    self:NetworkVar("Bool", "CanSwitch")
    self:NetworkVar("Float", "LastFireTime")
    self:NetworkVar("Float", "Spread")
    self:NetworkVar("Float", "SpreadVertical")
    self:NetworkVar("Float", "SpreadHorizonal")
    self:NetworkVar("Angle", "Recoil")
    self:NetworkVar("Float", "RecoilProgress") -- for custom recoil
    self:NetworkVar("Float", "NextRecoil")
    self:NetworkVar("Angle", "VisualRecoil")
    self:NetworkVar("Float", "VisualRecoilProgress") -- for custom recoil
    self:NetworkVar("Float", "VisualRecoilBackward")

    self:NetworkVar("Int","FiremodeIndex")

    self:NetworkVar("Bool", "TacSight")
    self:NetworkVar("Bool", "OnLadder")
    self:NetworkVar("Bool", "FlashLightOn")
    for _ , task in pairs(self.Tasks) do
        if task.SetupDataTables then
            task:SetupDataTables(self)
        end
    end
end


-- 调试指令：打印当前武器的所有 Tag 状态
concommand.Add("trm_debug_tags", function(ply)
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or not wep.Tags then
        print("[TRM] No active weapon or weapon has no Tags table")
        return
    end
    PrintTable(wep.Tags)

    local flags = wep:GetWeaponTag() or 0
    print("===== TRM Weapon Tags =====")
    print("Weapon:", wep:GetClass())
    print("WeaponFlags value:", flags)
    print("Active tags:")

    local hasAny = false
    for name, bit in pairs(wep.Tags) do
        local active = bit.band(flags, bit) == bit
        if active then
            print("  ✓ " .. name .. " (bit: " .. bit .. ")")
            hasAny = true
        end
    end

    if not hasAny then
        print("  (none)")
    end
    print("===========================")
end)

-- 快捷指令：查看某个特定 Tag
concommand.Add("trm_has_tag", function(ply, cmd, args)
    local tagName = args[1]
    if not tagName then
        print("Usage: trm_has_tag <tagname>")
        return
    end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or not wep.Tags then
        print("[TRM] No active weapon")
        return
    end

    if wep:HasTag(tagName) then
        print("[TRM] Weapon has tag: " .. tagName)
    else
        print("[TRM] Weapon does NOT have tag: " .. tagName)
    end
end)

-- 手动切换 Tag（测试用）
concommand.Add("trm_toggle_tag", function(ply, cmd, args)
    local tagName = args[1]
    if not tagName then
        print("Usage: trm_toggle_tag <tagname>")
        return
    end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then
        print("[TRM] No active weapon")
        return
    end

    wep:ToggleTag(tagName)
    
    print("[TRM] Toggled tag: " .. tagName)
    print("[TRM] New value:", wep:HasTag(tagName))
end)
