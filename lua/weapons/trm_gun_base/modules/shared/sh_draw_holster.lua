function SWEP:Task_Deploy(cycle)
    self:SetCanSwitch(false)
    self:SetNextAnimationTime(0)
    if self:GetFirstDeployed() and self.Animations.Draw_First then
        self:PlayAnimation( "Draw_First" , true )

        -- self:SetNextFireTime(0.5)
        -- self:SetNextAnimationTime(CurTime() + 0.5)

        self:SetFirstDeployed(false)
        
    else
        self:PlayAnimation("Draw" , true )
    end
    self:SetCurrentTask("Finished")
end

function SWEP:Holster(weapon)
    -- 收起武器时清理第三人称配件模型（否则换武器后模型仍显示）
    -- 设重建标记，下次 Deploy 时触发 BuildCustomizedGun
    if CLIENT then
        self.m_NeedsBuild = true
        if self.TpAttachmentModels then
            for _, model in pairs(self.TpAttachmentModels) do
                if IsValid(model) then
                    model:Remove()
                end
            end
            self.TpAttachmentModels = {}
        end
    end


    if (IsValid(weapon) && weapon != self && weapon != self:GetOwner()) then
        if (self:GetCurrentTask() == "Deploy") then
            return true
        end
        
        self:SetNextWeapon(weapon)
    else
        self:SetNextWeapon(NULL)
    end

    if not string.find(self:GetPlayingSequence(),"Holster")   then
        self:SetCurrentTask("Holster")
        self:SetNextAnimationTime(0)

    end

    return  self:GetCanSwitch() or not weapon:IsWeapon() or( weapon:GetOwner() == NULL) 
end

function SWEP:Task_Holster(cycle)


    self:PlayAnimation( "Holster" ,true)
    local vm = self:GetViewModel()
    local sequence = self:GetPlayingSequence()
    if string.find(sequence,"Holster") and cycle >= (self.Animations[sequence].Length or 0.90) or self.AltSwitch  then
        if IsValid(self:GetNextWeapon()) then
            self:SetCanSwitch(true)

            if (CLIENT && IsFirstTimePredicted()) then 
                input.SelectWeapon(self:GetNextWeapon()) 
            elseif SERVER then
                self:GetOwner():SendLua("input.SelectWeapon(Entity("..self:GetNextWeapon():EntIndex().."))")
            end

        end
        self:SetCurrentTask("Finished")

    end

end

concommand.Add("trmbase_debug_reset_firstdeployed",function(ply)
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and (wep.Base == "trm_gun_base" or wep:GetClass() == "trm_gun_base") then
        wep:SetFirstDeployed(true)
    end
end)