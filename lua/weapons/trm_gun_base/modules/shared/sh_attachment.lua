
function SWEP:RefreshAttTable()
    
end

--- 检查指定槽位是否被已装备的配件排除
--- 如果槽位的 Exclude 列表中有任何一个 Category 匹配已装备的配件，则此槽位不可用
function SWEP:IsSlotExcluded(slotIndex)
    if not self.Attachments or not self.Attachments[slotIndex] then return false end
    local slot = self.Attachments[slotIndex]
    if not slot.Exclude or #slot.Exclude == 0 then return false end

    -- 遍历当前已装备的配件，检查它们的 Category 是否匹配排除列表
    for _, attClass in pairs(self.CurrentAttachments or {}) do
        local attData = BASE_TRM_ATTS[attClass]
        if attData and attData.Category then
            for _, excludeCat in ipairs(slot.Exclude) do
                if attData.Category == excludeCat then
                    return true
                end
            end
        end
    end
    return false
end
 
function SWEP:PrepareViewModel(vm)
    if SERVER then self:CallOnClient("PrepareViewModel") return end 
    if (not vm) then
        vm = self:GetViewModel()
    end

    if (not IsValid(vm)) then
        return false
    end

    vm:SetSkin(0) 

    for b = 0, vm:GetNumBodyGroups() do
        vm:SetBodygroup(b, 0)
    end

    self:SetSkin(0)

    for b = 0, self:GetNumBodyGroups() do
        self:SetBodygroup(b, 0)
    end

    for _ , att in pairs(self.CurrentAttachments) do
        data = BASE_TRM_ATTS[att]
        if data.PostProcess then
            data:PostProcess(self)
        end
    end

    self:SetModel(self.WorldModel) 
    vm:SetWeaponModel(self.ViewModel,self)
    print(tostring(self.ViewModel))
end

function SWEP:ApplyModelChanged()
    self:PrepareViewModel() 
end
  


function SWEP:ChangeWeaponStats()
    if CLIENT  then return end
    -- 只重置属性表，不重置 m_Spread
    self:DeepObjectCopy(self.m_OriginalStat, self)
    
    for slot, attClass in pairs(self.CurrentAttachments or {}) do
        if BASE_TRM_ATTS[attClass].ChangeWeaponStats then 
            BASE_TRM_ATTS[attClass]:ChangeWeaponStats(self)
        end
    end
    
    self:ApplyModelChanged()

    self:SetClip1(self.Primary.ClipSize)
    self:SetClip2(self.Secondary.ClipSize)

    self:SetSpread(self.Spread.Base)
    self:SetSpreadVertical(self.Spread.Vertical)
    self:SetSpreadHorizonal(self.Spread.Horizontal)
end

function SWEP:DeepObjectCopy(original, holder)
    for index, value in pairs(original) do 
        if istable(value) then
            holder[index] = {}
            
            self:DeepObjectCopy(value, holder[index])
        elseif isvector(value) then
            holder[index] = Vector(0, 0, 0)
            holder[index]:Set(value)
        elseif (isangle(value)) then
            holder[index] = Angle(0, 0, 0)
            holder[index].p = value.p
            holder[index].y = value.y
            holder[index].r = value.r
        else
            if index == "LoadSpawnPreset" then
                continue
            end

            holder[index] = value
        end
    end
end 

function SWEP:GetOriginStat()
    local template = weapons.Get(self:GetClass())
    self.m_OriginalStat = {}
    self:DeepObjectCopy(template, self.m_OriginalStat)
end

function SWEP:SpreadInit()
    local val = self.Spread
    if not val then return end
    self:SetSpread(val.Base)
    self:SetSpreadVertical(val.Vertical)
    self:SetSpreadHorizonal(val.Horizontal)
    self:SetRecoilProgress(0)
    self:SetVisualRecoilProgress(0)
end

function SWEP:BulletCallback(attacker, tr, dmginfo)
    local ent = tr.Entity
    if not IsValid(ent) then return end
    
    -- 只对玩家生效
    if not ent.TakeDamageInfo then return end
    
    -- 获取击中部位
    local group = tr.HitGroup
    
    local scale = 1
    if group == HITGROUP_HEAD then
        scale = self.DamageScale.Head or 4
    elseif group == HITGROUP_CHEST or group == HITGROUP_STOMACH then
        scale = self.DamageScale.Body or 1
    elseif group == HITGROUP_LEFTARM or group == HITGROUP_RIGHTARM then
        scale = self.DamageScale.Arms or 0.8
    elseif group == HITGROUP_LEFTLEG or group == HITGROUP_RIGHTLEG then
        scale = self.DamageScale.Legs or 0.6
    end
    
    dmginfo:ScaleDamage(scale)

    if not self.CurrentAttachments then
        self.CurrentAttachments = {}
    end
    for slot , attClass in pairs(self.CurrentAttachments) do 
        if BASE_TRM_ATTS[attClass].BulletCallback then
             BASE_TRM_ATTS[attClass]:BulletCallback(attacker, tr, dmginfo)    
        end    
    end
end

function SWEP:BuildViewModelData()
    local vm = self:GetViewModel(0)
    if not IsValid(vm) then return end
    
    -- Attachment 数据
    if not self.m_Attachment then
        self.m_Attachment = {}
    end
    
    local Stat = vm:GetAttachments()
    for _, Modelattachment in pairs(Stat) do
        local data = vm:GetAttachment(Modelattachment.id)
        if data then
            self.m_Attachment[Modelattachment.name] = data
            self.m_Attachment[Modelattachment.name].id = Modelattachment.id
        end
    end
    
    -- Bone 数据
    if not self.m_Bone then
        self.m_Bone = {}
    end
    
    local count = vm:GetBoneCount()
    if count and count > 0 then
        for i = 0, count - 1 do
            local name = vm:GetBoneName(i)
            local matrix = vm:GetBoneMatrix(i)
            if matrix and name then
                -- ✅ 先确保表存在
                if not self.m_Bone[name] then
                    self.m_Bone[name] = {}
                end
                self.m_Bone[name].Pos = matrix:GetTranslation()
                self.m_Bone[name].Ang = matrix:GetAngles()
                self.m_Bone[name].Id = i
            end
        end
    end
end

function SWEP:GetAttachmentData(name)
    return self.m_Attachment[name]
end

function SWEP:GetBoneData(name)
    return self.m_Bone[name]
end

---CustomizeSystem
function SWEP:EquipAttachment(slot, attClass)
    -- 检查此槽位是否被排除（防止绕过 VGUI 直接发 net 消息）
    local slotIndex = tonumber(slot)
    if slotIndex and self:IsSlotExcluded(slotIndex) then
        print("[TRMBase] Slot", slot, "is excluded, cannot equip", attClass)
        return
    end

    local attData = BASE_TRM_ATTS[attClass]
    if attData then
        self.CurrentAttachments[slot] = attClass

        -- 装完后检查其他槽是否因此被排除，如有则自动卸掉
        local removedSlots = {}
        for i = 1, #(self.Attachments or {}) do
            local key = tostring(i)
            if key ~= slot and self.CurrentAttachments[key] and self:IsSlotExcluded(i) then
                removedSlots[#removedSlots + 1] = key
                self.CurrentAttachments[key] = nil
            end
        end

        -- 发送主配件的同步消息
        net.Start("TRMBase_SyncAttachment")
            net.WriteEntity(self)
            net.WriteString(slot)
            net.WriteString(attClass)
        net.SendPVS(self:GetPos())

        -- 同时发送被自动卸载的槽位同步（告诉客户端这些槽已清空）
        for _, removedKey in ipairs(removedSlots) do
            net.Start("TRMBase_SyncAttachment")
                net.WriteEntity(self)
                net.WriteString(removedKey)
                net.WriteString("None")
            net.SendPVS(self:GetPos())
        end
    end
    self:ChangeWeaponStats()
    -- 广播给所有玩家（告诉客户端这个武器装了什么）
    -- 注：上面已发送，此处不再重复
    
    -- 保存配置
    self:SaveAttachmentPreset()

    print("Equipped:", slot, attClass)
end

function SWEP:UnEquipAttachment(slot)
    local slotIndex = tonumber(slot)
    self.CurrentAttachments[slot] = nil
    self:ChangeWeaponStats()

    -- 注：不再自动装默认配件，让用户从列表中自行选择"无"或默认配件

    -- 发一次同步
    net.Start("TRMBase_SyncAttachment")
        net.WriteEntity(self)
        net.WriteString(slot)
        net.WriteString("None")
    net.SendPVS(self:GetPos())

    -- 保存配置
    self:SaveAttachmentPreset()

    print("Unequipped:", slot, self.CurrentAttachments[slot] or "None")
end

--- 创建 / 更新所有配件的客户端模型
--- TFA 风格：RENDERGROUP_OTHER + SetNoDraw(true)，在 ViewModelDrawn 里手动 DrawModel
function SWEP:BuildCustomizedGun()
    if SERVER then return end

    local vm = self:GetViewModel()
    if not IsValid(vm) then return end

    self.m_Sight = nil 

    -- 初始化模型缓存表
    if not self.AttachmentModels then
        self.AttachmentModels = {}
    end

    -- 第三人称配件模型表（挂在武器实体上，引擎自动渲染）
    if not self.TpAttachmentModels then
        self.TpAttachmentModels = {}
    end

    local currentSlotKeys = {}

    for slotKey, attID in pairs(self.CurrentAttachments or {}) do
        currentSlotKeys[slotKey] = true

        local attData = BASE_TRM_ATTS[attID]
        if not attData or not attData.Model then continue end

        -- ========== 第一人称模型（挂 ViewModel） ==========
        -- 如果已有模型且装备相同，跳过
        if IsValid(self.AttachmentModels[slotKey])
            and self.AttachmentModels[slotKey]._attID == attID then
            -- 跳过 VM 模型创建，但 TP 模型仍需检查
        else
            -- 移除旧模型
            if IsValid(self.AttachmentModels[slotKey]) then
                self.AttachmentModels[slotKey]:Remove()
            end

            -- TFA 方式创建：SetNoDraw(true)，在 ViewModelDrawn 手动 DrawModel
            local model = ClientsideModel(attData.Model, RENDERGROUP_VIEWMODEL)
            model._attID = attID
            model._slotKey = slotKey

            model:SetNoDraw(true)
            model:SetNotSolid(true)
            model:SetMoveType(MOVETYPE_NONE)
            model:SetOwner(vm)

            local slotData = self.Attachments and self.Attachments[tonumber(slotKey)]

            if attData.Bonemerge == true then
                model:SetParent(vm)
                model:AddEffects(EF_BONEMERGE)
                model:AddEffects(EF_BONEMERGE_FASTCULL)
                model:SetLocalPos(Vector(0, 0, 0))
                model:SetLocalAngles(Angle(0, 0, 0))
            else
                local useBone = slotData and slotData.Bone or "ValveBiped.Bip01_R_Hand"
                local usePos = slotData and Vector(slotData.Pos) or Vector(0, 0, 0)
                local useAng = slotData and Angle(slotData.Ang) or Angle(0, 0, 0)

                if attData.Pos and isvector(attData.Pos) then usePos:Add(attData.Pos) end
                if attData.Angles and isangle(attData.Angles) then useAng:Add(attData.Angles) end

                local boneIdx = vm:LookupBone(useBone)
                if boneIdx and boneIdx > 0 then
                    model:FollowBone(vm, boneIdx)
                    model.m_Bone = boneIdx
                end
                model:SetParent(vm)
                model:SetLocalPos(usePos)
                model:SetLocalAngles(useAng)
            end

            self.AttachmentModels[slotKey] = model
        end

        -- ========== 第三人称模型（挂武器实体，引擎自动渲染） ==========
        -- 用 EF_BONEMERGE 挂在武器实体上，世界模型自动显示配件
        -- 只有显式 Bonemerge == true 的配件才有 TP 模型
        if attData.Bonemerge ~= true then
            -- 非骨骼合并的配件：不显示 TP 模型，清理已有的
            if IsValid(self.TpAttachmentModels[slotKey]) then
                self.TpAttachmentModels[slotKey]:Remove()
                self.TpAttachmentModels[slotKey] = nil
            end
        elseif IsValid(self.TpAttachmentModels[slotKey])
            and self.TpAttachmentModels[slotKey]._attID == attID then
            -- TP 模型已是最新，跳过
        else
            -- 移除旧 TP 模型
            if IsValid(self.TpAttachmentModels[slotKey]) then
                self.TpAttachmentModels[slotKey]:Remove()
            end

            local tpModel = ClientsideModel(attData.Model, RENDERGROUP_OPAQUE)
            tpModel._attID = attID
            tpModel._slotKey = slotKey
            tpModel:SetNotSolid(true)
            tpModel:SetMoveType(MOVETYPE_NONE)

            -- 带偏移挂在武器实体上，让引擎自动渲染
            tpModel:SetParent(self)
            tpModel:AddEffects(EF_BONEMERGE)
            tpModel:AddEffects(EF_BONEMERGE_FASTCULL)

            -- 计算偏移（与 VM 模型一致的逻辑，但基于武器自身坐标空间）
            local slotData = self.Attachments and self.Attachments[tonumber(slotKey)]
            local tpPos = slotData and Vector(slotData.Pos) or Vector(0, 0, 0)
            local tpAng = slotData and Angle(slotData.Ang) or Angle(0, 0, 0)
            if attData.Pos and isvector(attData.Pos) then tpPos:Add(attData.Pos) end
            if attData.Angles and isangle(attData.Angles) then tpAng:Add(attData.Angles) end

            tpModel:SetLocalPos(tpPos)
            tpModel:SetLocalAngles(tpAng)

            self.TpAttachmentModels[slotKey] = tpModel
        end
    end

    -- 必须在模型创建完后才计算瞄具偏移（否则模型还不存在）
    self:GenerateAimOffset()

    -- 清除已卸载配件的模型（VM + TP）
    for key, model in pairs(self.AttachmentModels) do
        if not currentSlotKeys[key] and IsValid(model) then
            model:Remove()
            self.AttachmentModels[key] = nil
        end
    end
    for key, model in pairs(self.TpAttachmentModels) do
        if not currentSlotKeys[key] and IsValid(model) then
            model:Remove()
            self.TpAttachmentModels[key] = nil
        end
    end
end

function SWEP:GetSight()
    return self.m_Sight or false
end



function SWEP:GenerateAimOffset()
    if SERVER then return end
    for slot , attachment in pairs(self.CurrentAttachments) do
        local AttachmentData = BASE_TRM_ATTS[attachment]
        if AttachmentData.Model == nil then  continue end

        if AttachmentData.Sight != nil then
            self:GetViewModel():InvalidateBoneCache()
            self:GetViewModel():SetupBones()
            
            local align = self.Attachments[tonumber(slot)] --Bone
            
            
            local AlignAttachment = self:GetBoneData(align.Bone)

            

            if AlignAttachment then
                local model = self.AttachmentModels[slot]
                --print("1")

                if not IsValid(model) then continue end

                model:InvalidateBoneCache()
                model:SetupBones() --shaky otherwise
                model:GetParent():InvalidateBoneCache()
                model:GetParent():SetupBones()

                local Data = AlignAttachment
                local sightData = model:GetAttachment( model:LookupAttachment( AttachmentData.Sight.Align  ) )
                if not sightData then continue end
                
                local localPos , localAng = WorldToLocal( sightData.Pos , Data.Ang , Data.Pos , Data.Ang )
                localPos.x = 0
                localPos.y = 0
                if AttachmentData.Pos then
                    localPos:Add(AttachmentData.Sight.Pos)
                end
                if align.SightPos then
                    localPos:Add(align.SightPos)
                end
                -- if align.SightAng  then
                --     localAng:Add(align.SightAng)
                -- end
                --print(localPos)
                model.AimPos = Vector( localPos.x  , align.SightPos.y  , localPos.z  ) 
                model.AimAng = align.SightAng or Angle(0,0,0)
                --model.AimAng = 
                debugoverlay.Axis(sightData.Pos , Data.Ang , 10 , 0 ,false  )
                debugoverlay.Axis(Data.Pos , Data.Ang , 10 , 0 ,false  )
                if not self.m_Sight then
                    self.m_Sight = {
                        AimPos = model.AimPos ,
                        AimAng = model.AimAng ,
                        AimBoneAng = Angle(Data.Ang),  -- 骨骼朝向，用于把偏移转换回世界空间
                    }
                end
                -- self.m_Sight_Pos = Vector(0,0,1.3)
                
                self.AttachmentModels[slot] = model 
                model = nil

            end
        end

    end
end

--- 服务端：把全部配件同步给客户端（Deploy 时调用）
function SWEP:SyncAllAttachments()
    if not SERVER then return end

    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:IsPlayer() then return end

    net.Start("TRMBase_SyncAllAttachments")
        net.WriteEntity(self)
        local count = 0
        for _ in pairs(self.CurrentAttachments or {}) do
            count = count + 1
        end
        net.WriteUInt(count, 8)
        for slot, attClass in pairs(self.CurrentAttachments or {}) do
            net.WriteString(slot)
            net.WriteString(attClass)
        end
    net.Send(owner)
end

net.Receive("TRMBase_Attachment", function()
    local weapon = net.ReadEntity()
    local slot = net.ReadString()
    local attClass = net.ReadString()
    if attClass == "None" then
        weapon:UnEquipAttachment(slot)
    else
        weapon:EquipAttachment(slot, attClass)
    end
end)


  
---concommad
-- 查看当前武器装备的所有配件

concommand.Add("trm_debug_spread", function(ply)
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end
    
    print("=== Spread Debug ===")
    print("SWEP.Spread.Base:", wep.Spread.Base)
    print("GetSpread():", wep:GetSpread())
    print("CurrentAttachments:", wep.CurrentAttachments)
    
    -- 强制刷新一次
    wep:ChangeWeaponStats()
    print("After ChangeWeaponStats - GetSpread():", wep:GetSpread())
end)
