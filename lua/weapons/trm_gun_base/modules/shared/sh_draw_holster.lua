function SWEP:Holster(weapon)

    if CLIENT then
            if IsValid(TRM_AttachMenu_Instance) then
                TRM_AttachMenu_Instance:Close()
            end
            
        
        --self.m_NeedsBuild = true
        -- if self.CurrentAttachments then
        --     for _, entry in pairs(self.CurrentAttachments) do
        --         if entry then
        --             self:RemoveAttachmentModel(entry)
        --             self:RemoveAttachmentModel(entry, true)
        --         end
        --     end
        -- end
        
    end


    if (IsValid(weapon) && weapon != self && weapon != self:GetOwner()) then
        if (self:IsCurrentTask("Deploy")) then
            return true
        end
        
        self:SetNextWeapon(weapon)
    else
        self:SetNextWeapon(NULL)
    end

    if not string.find(self:GetPlayingSequence(),"Holster")   then
        self:TrySetTask("Holster")
        self:SetNextAnimationTime(0)

    end

    return  self:GetCanSwitch() or not weapon:IsWeapon() or( weapon:GetOwner() == NULL) 
end

concommand.Add("trmbase_debug_reset_firstdeployed",function(ply)
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and (wep.Base == "trm_gun_base" or wep:GetClass() == "trm_gun_base") then
        wep:SetFirstDeployed(true)
    end
end)

-- 调试：检查所有 TRM 武器 bodygroup
concommand.Add("trmbase_debug_bg", function(ply)
    local w = ply:GetActiveWeapon()
    if IsValid(w) and util.IsTRMBase(w) then
        print("=== 手上武器 ===")
        local bg = w.BodyGroups or {}
        for name, val in pairs(bg) do
            print(" ", name, "=", w:GetBodygroup(w:FindBodygroupByName(name)))
        end
    end
    print("=== 地面武器 ===")
    for _, e in ipairs(ents.FindByClass("trm_*")) do
        if e ~= w and util.IsTRMBase(e) then
            print(" ", e, e:GetClass())
            for name, _ in pairs(e.BodyGroups or {}) do
                local id = e:FindBodygroupByName(name)
                if id and id >= 0 then
                    print("   ", name, "=", e:GetBodygroup(id))
                end
            end
        end
    end
end)