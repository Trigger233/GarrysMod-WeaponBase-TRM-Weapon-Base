function SWEP:RefreshAttTable()
    for slot, entry in pairs(self.CurrentAttachments) do
        if not entry or not entry.Class then continue end
        if not self:CanEquip(slot, entry.Class) then
            self:UnEquipAttachment(slot)
        end
    end
end

function SWEP:IsPlyCarry()
    local owner = self:GetOwner()
    return owner:IsPlayer() and owner:GetActiveWeapon() == self and true or false
end
--- 检查指定配件能否安装到指定槽位
--- 思路：以配件为中心，默认配件永远可装，真实配件才参与排斥
--- 返回 false 表示被排除（不可用），true 表示可用
function SWEP:CanEquip(slotIndex, attClass)
    if not self.Attachments or not self.Attachments[slotIndex] then return true end
    local slot = self.Attachments[slotIndex]

    -- 默认配件或空配件永远可装
    if slot.Default and attClass == slot.Default then return true end
    if not attClass then return true end

    local attData = BASE_TRM_ATTS[attClass]
    if not attData then return true end

    -- 没有 Category 的配件不参与排斥
    local attCats = attData.Category
    if not attCats then return true end
    if not istable(attCats) then attCats = { attCats } end

    -- 方向 A：其他已装备配件排斥本配件
    for _, entry in pairs(self.CurrentAttachments or {}) do
        if not entry or not entry.Class or entry.Class == attClass then continue end
        local otherData = BASE_TRM_ATTS[entry.Class]
        if otherData and otherData.Excluded then
            local excluded = istable(otherData.Excluded) and otherData.Excluded or { otherData.Excluded }
            for _, excludeCat in ipairs(excluded) do
                for _, attCat in ipairs(attCats) do
                    if attCat == excludeCat then return false end
                end
            end
        end
    end

    -- 方向 B：本槽位排斥其他已装备配件
    if slot.Exclude and #slot.Exclude > 0 then
        for _, entry in pairs(self.CurrentAttachments or {}) do
            if not entry or not entry.Class or entry.Class == attClass then continue end
            local otherData = BASE_TRM_ATTS[entry.Class]
            if otherData and otherData.Category then
                for _, excludeCat in ipairs(slot.Exclude) do
                    if otherData.Category == excludeCat then return false end
                end
            end
        end
    end

    return true
end

-- 兼容旧接口
function SWEP:CanAttach(slotIndex)
    local entry = self.CurrentAttachments[tostring(slotIndex)]
    return self:CanEquip(slotIndex, entry and entry.Class or nil)
end

--self:GetViewModel():SetWeaponModel("models/weapons/c_smg1.mdl",self)

function SWEP:PrecacheViewModel()
    self.m_ViewmodelCache = nil
    self.m_SkinCache = 0
    self.m_BodyGroupCache = {}
    self.m_PoseParameter = self.GripPoseParameters.Left or {}
    self.m_PoseParameter2 = self.GripPoseParameters.Right or {}

    for _, entry in pairs(self.CurrentAttachments or {}) do
        if not entry or not entry.Class then continue end
        if not BASE_TRM_ATTS[entry.Class] then continue end
        local _att = BASE_TRM_ATTS[entry.Class]
        if _att.ViewModel then
            self.m_ViewmodelCache = _att.ViewModel
        elseif _att.Skin then
            self.m_SkinCache = _att.Skin
        elseif _att.BodyGroup then
            for _model, _submodel in pairs(_att.BodyGroup) do
                self.m_BodyGroupCache[_model] = _submodel
            end
        elseif _att.poseParameter then
            self.m_PoseParameter = _att.poseParameter
        elseif _att.poseParameter2 then
            self.m_PoseParameter2 = _att.poseParameter2
        end
    end
end

function SWEP:PrepareViewModel()
    local vm = self:GetViewModel(0)

    if (not IsValid(vm) or not vm) then
        return false
    end

    vm:SetSkin(0)

    for b = 0, vm:GetNumBodyGroups() do
        vm:SetBodygroup(b, 0)
    end

    self:SetSkin(0)


    if self:IsPlyCarry() then
        for b = 0, self:GetNumBodyGroups() do
            self:SetBodygroup(b, 0)
        end
    end
    -- vm:SetWeaponModel(self.ViewModel, self)

    for _group, _sub in pairs(self.BodyGroups or {}) do
        if self:IsPlyCarry() then
            changeBodyGroup(vm, _group, _sub)
        end
        -- 武器实体本身的 bodygroup 也要应用（影响世界模型）
        changeBodyGroup(self, _group, _sub)
        for _, entry in pairs(self.CurrentAttachments or {}) do
            if IsValid(entry.m_Model) then
                changeBodyGroup(entry.m_Model, _group, _sub)
            end
        end
    end
end

function changeBodyGroup(model, submodel, sub)
    if not IsValid(model) then return end
    local _modelId = model:FindBodygroupByName(submodel)
    if _modelId and _modelId > -1 then
        model:SetBodygroup(_modelId, sub)
    end
    --print("change")
end

function SWEP:ApplyWeaponModelChange()
    local vm = self:GetViewModel()
    if not IsValid(vm) or not self:IsPlyCarry() then return false end
    local viewmodel = self.m_ViewmodelCache or self.ViewModel

    if CLIENT then
        vm:SetModel(viewmodel)
    elseif not game.SinglePlayer() then
        vm:SetModel(viewmodel)
    end
    self.m_BodyGroupCache = self.m_BodyGroupCache or {}
    vm:SetSkin(self.m_SkinCache || 0)
    vm:ClearPoseParameters()
    for bodygroup, sub in pairs(self.m_BodyGroupCache) do
        if self:IsPlyCarry() then
            changeBodyGroup(vm, bodygroup, sub)
            changeBodyGroup(self, bodygroup, sub)
            -- print( "change bodygroup", bodygroup, sub)
        end
        for _, entry in pairs(self.CurrentAttachments or {}) do
            if IsValid(entry.m_Model) then
                local _att = BASE_TRM_ATTS[entry.Class]

                changeBodyGroup(entry.m_Model, bodygroup, sub)
                if _att.AttBodyGroup then
                    for groupName, pose in pairs(_att.AttBodyGroup) do
                        changeBodyGroup(entry.m_Model, groupName, pose)
                    end
                end
            end
            if IsValid(entry.m_TpModel) then
                local _att = BASE_TRM_ATTS[entry.Class]

                changeBodyGroup(entry.m_TpModel, bodygroup, sub)
                if _att.AttBodyGroup then
                    for groupName, pose in pairs(_att.AttBodyGroup) do
                        changeBodyGroup(entry.m_TpModel, groupName, pose)
                    end
                end
            end
        end
    end
end

function SWEP:ChangeWeaponStats()
    self:CallOnClient("ChangeWeaponStats")
    self:DeepObjectCopy(weapons.Get(self:GetClass()), self)

    for name, injector in pairs(BASE_TRM_INJECTOR) do
        if type(injector) == "table" and injector.Inject then -- 只处理有 Inject 方法的
            if injector.SWEP and injector.SWEP ~= self:GetClass() then
                continue
            end
            injector:Inject(self)
        end
    end

    self:FireModeStat(self:GetFiremodeIndex())
    self.m_Anim = table.Copy(self.Animations)
    --init anim data

    for Class, Anim in pairs(self.Animations) do
        Anim.Speed = Anim.Speed or 1
    end

    for _, entry in pairs(self.CurrentAttachments or {}) do
        if not entry or not entry.Class then continue end
        if BASE_TRM_ATTS[entry.Class].ChangeWeaponStats then
            BASE_TRM_ATTS[entry.Class]:ChangeWeaponStats(self)
        end
        if BASE_TRM_ATTS[entry.Class].Stats then
            BASE_TRM_ATTS[entry.Class]:Stats(self)
        end
    end

    --Animation Protect
    for Class, Data in pairs(self.m_Anim) do
        if self.Animations[Class] == nil then
            self.Animations[Class] = Data
        end
    end

    -- self:FireModeStat(self:GetFiremodeIndex())

    if SERVER then
        if self:Clip1() > (self.Primary.ClipSize + self.Primary.Chamber) then
            self:Unload()
            self:MagzineLoaded()
        end
        if self:Clip2() > self.Secondary.ClipSize then
            self:SetClip2(self.Secondary.ClipSize)
            self:MagzineLoaded2()
        end
        --self:MagzineLoaded()
        self:SetSpread(self.Spread.Base)
        self:SetSpreadVertical(self.Spread.Vertical)
        self:SetSpreadHorizonal(self.Spread.Horizontal)
    end
end

function SWEP:DeepObjectCopy(original, holder)
    for index, value in pairs(original) do
        if index == "ModelBodyGroup" then continue end -- 跳过
        if istable(value) then
            holder[index] = {}
            self:DeepObjectCopy(value, holder[index])
        elseif isvector(value) then
            holder[index] = Vector(value.x, value.y, value.z)
        elseif isangle(value) then
            holder[index] = Angle(value.p, value.y, value.r)
        else
            holder[index] = value
        end
    end
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

require("trm_utils")








---CustomizeSystem
function SWEP:OnAttachmentChanged(shouldntsave)
    self:BuildCustomizedGun()
    if not shouldntsave then
        self:SaveAttachmentPreset()
    end
end

-- 统一移除配件模型，调用 attData:Remove 扩展钩子
function SWEP:RemoveAttachmentModel(entry, isTp)
    local model = isTp and entry.m_TpModel or entry.m_Model
    if not IsValid(model) then return end
    local attData = entry.Class and BASE_TRM_ATTS[entry.Class]

    if attData and attData.Remove then
        attData:Remove(self, model)
    end

    if isTp then
        entry.m_TpModel = nil
    else
        entry.m_Model = nil
    end
end

function SWEP:EquipAttachment(slot, attClass)
    local slotIndex = tonumber(slot)
    if slotIndex and not self:CanEquip(slotIndex, attClass) then
        print("[TRMBase] Slot", slot, "is excluded, cannot equip", attClass)
        return
    end

    local attData = BASE_TRM_ATTS[attClass]
    if attData then
        self.CurrentAttachments[slot] = { Class = attClass }

        -- 装完后检查其他槽是否因此被排除，如有则自动卸掉
        local removedSlots = {}
        for i = 1, #(self.Attachments or {}) do
            local key = tostring(i)
            if key ~= slot and self.CurrentAttachments[key] and self.CurrentAttachments[key].Class and not self:CanEquip(i, self.CurrentAttachments[key].Class) then
                self:RemoveAttachmentModel(self.CurrentAttachments[key])
                removedSlots[#removedSlots + 1] = key
                self.CurrentAttachments[key] = nil
            end
        end

        -- 被清空的槽位：先装默认配件，再发送同步
        for _, removedKey in ipairs(removedSlots) do
            local slotData = self.Attachments and self.Attachments[tonumber(removedKey)]
            if slotData and slotData.Default and BASE_TRM_ATTS[slotData.Default] and self:CanEquip(tonumber(removedKey), slotData.Default) then
                self.CurrentAttachments[removedKey] = { Class = slotData.Default }
                net.Start("TRMBase_SyncAttachment")
                net.WriteEntity(self)
                net.WriteString(removedKey)
                net.WriteString(slotData.Default)
                net.Broadcast()
            else
                self.CurrentAttachments[removedKey] = nil
                net.Start("TRMBase_SyncAttachment")
                net.WriteEntity(self)
                net.WriteString(removedKey)
                net.WriteString("None")
                net.Broadcast()
            end
        end

        -- 发送主配件的同步消息
        net.Start("TRMBase_SyncAttachment")
        net.WriteEntity(self)
        net.WriteString(slot)
        net.WriteString(attClass)
        net.Broadcast()
    end
    self:RefreshAttTable()

    self:OnAttachmentChanged()

    --print("Equipped:", slot, attClass)
end

function SWEP:UnEquipAttachment(slot)
    local slotIndex = tonumber(slot)

    -- 清理模型
    local entry = self.CurrentAttachments[slot]
    if entry and IsValid(entry.m_Model) then
        BASE_TRM_ATTS[entry.Class]:Remove(self, entry.m_Model)
    end

    self.CurrentAttachments[slot] = nil

    -- 注：不再自动装默认配件，让用户从列表中自行选择"无"或默认配件

    -- 发一次同步
    net.Start("TRMBase_SyncAttachment")
    net.WriteEntity(self)
    net.WriteString(slot)
    net.WriteString("None")
    net.Broadcast()

    self:OnAttachmentChanged()

    -- 恢复被排他配件清空的槽位默认配件（跳过刚卸掉的槽位本身）
    timer.Simple(FrameTime() * 5, function()
        if SERVER then
            for i, slotData in ipairs(self.Attachments or {}) do
                local key = tostring(i)
                if key ~= slot and not self.CurrentAttachments[key] and slotData.Default and self:CanEquip(i, slotData.Default) then
                    self:EquipAttachment(key, slotData.Default)
                end
            end
        end
    end)


    --print("Unequipped:", slot, self.CurrentAttachments[slot] or "None")
end

function SWEP:ApplyCustomizationModels()
    if SERVER then return end
    local vm = self:GetViewModel()
    for slot, entry in pairs(self.CurrentAttachments) do
        if not entry or not entry.Class then continue end
        local AttachmentData = BASE_TRM_ATTS[entry.Class]
        local WeaponData = self.Attachments and self.Attachments[tonumber(slot)]
        if not AttachmentData.Model then continue end
        local model = entry.m_Model
        local Tpmodel = entry.m_TpModel

        if AttachmentData.Bonemerge then
            if IsValid(model) then
                model:SetParent(vm)
                model:AddEffects(EF_BONEMERGE)
                model:AddEffects(EF_BONEMERGE_FASTCULL)
                model:SetLocalPos(Vector(0, 0, 0))
                model:SetLocalAngles(Angle(0, 0, 0))
            end
            -- TP 模型（bonemerge）
            if IsValid(Tpmodel) then
                Tpmodel:SetParent(self)
                Tpmodel:AddEffects(EF_BONEMERGE)
                Tpmodel:AddEffects(EF_BONEMERGE_FASTCULL)
                Tpmodel:SetLocalPos(Vector(0, 0, 0))
                Tpmodel:SetLocalAngles(Angle(0, 0, 0))
            end
        else
            if not WeaponData.Bone then continue end
            local bone = self:FindBone(WeaponData.Bone, false)
            if not bone then continue end
            if IsValid(model) then
                model:FollowBone(bone.Parent, bone.Id)
                model:SetLocalPos(Vector(0, 0, 0))
                model:SetLocalAngles(Angle(0, 0, 0))
            end
            -- TP 模型（骨骼跟随）
            if IsValid(Tpmodel) then
                local boneselect = WeaponData.Bone
                if WeaponData.WorldBone then
                    boneselect = WeaponData.WorldBone
                end

                local tpbone = self:FindTpBone(boneselect)
                if tpbone then
                    Tpmodel:FollowBone(tpbone.Parent, tpbone.Id)
                    Tpmodel:SetLocalPos(Vector(0, 0, 0))
                    Tpmodel:SetLocalAngles(Angle(0, 0, 0))
                else
                    Tpmodel:Remove()
                    Tpmodel = nil
                end
            end

            -- 组合偏移：槽位偏移 + 配件自身偏移
            local finalPos = WeaponData.Pos and Vector(WeaponData.Pos) or Vector(0, 0, 0)
            local finalAng = WeaponData.Ang and Angle(WeaponData.Ang) or Angle(0, 0, 0)
            if AttachmentData.Pos and isvector(AttachmentData.Pos) then finalPos:Add(AttachmentData.Pos) end
            if AttachmentData.Angles and isangle(AttachmentData.Angles) then finalAng:Add(AttachmentData.Angles) end
            if IsValid(model) then
                model:SetLocalPos(finalPos)
                model:SetLocalAngles(finalAng)
            end
            if IsValid(Tpmodel) then
                Tpmodel:SetLocalPos(finalPos)
                Tpmodel:SetLocalAngles(finalAng)
            end

            if AttachmentData.Scale then
                if IsValid(model) then
                    model:SetModelScale(AttachmentData.Scale)
                end
                if IsValid(Tpmodel) then
                    Tpmodel:SetModelScale(AttachmentData.Scale)
                end
            end
        end
    end
end

function SWEP:GetSight()
    return self.sight or false
end

function SWEP:GenerateAimOffset()
    if (SERVER) then
        return
    end

    for slot, entry in pairs(self.CurrentAttachments or {}) do
        if not entry or not entry.Class then continue end
        local AttachmentData = BASE_TRM_ATTS[entry.Class]
        if not AttachmentData or AttachmentData.Model == nil then continue end

        if AttachmentData.Sight then
            local align = self.Attachments[tonumber(slot)]
            if not align then continue end

            local localPos = Vector(0, 0, 0)
            if AttachmentData.Sight.Pos then
                localPos:Add(AttachmentData.Sight.Pos)
            end
            if align.SightPos then
                localPos:Add(align.SightPos)
            end
            local AimPos = Vector(localPos.x, localPos.y, localPos.z)
            local AimAng = align.SightAng or Angle(0, 0, 0)

            self.sight = {
                AimPos = AimPos,
                AimAng = AimAng,
            }
        end

        if AttachmentData.Scope then
            self.sight.zoom = AttachmentData.Scope.Zoom

            self.sight.MaxZoom = AttachmentData.Scope.Max or self.sight.zoom
            self.sight.MinZoom = AttachmentData.Scope.Min or self.sight.zoom
        end
    end
end


--- 服务端：把全部配件同步给客户端（Deploy 时调用）
function SWEP:SyncAllAttachments()
    if not SERVER then return end

    -- 地面武器没有 owner 也能同步（用于第三人称模型）
    net.Start("TRMBase_SyncAllAttachments")
    net.WriteEntity(self)
    local count = 0
    for _ in pairs(self.CurrentAttachments or {}) do
        count = count + 1
    end
    net.WriteUInt(count, 8)
    for slot, entry in pairs(self.CurrentAttachments or {}) do
        if not entry.Class then continue end
        net.WriteString(slot)
        net.WriteString(entry.Class)
    end
    net.Broadcast()
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


function SWEP:GetAllAttachmentsInUse()
    return self.CurrentAttachments
end

local function buildSingleModelBone(ent)
    if not ent or not IsValid(ent) then
        return
    end
    local boneCount = ent:GetBoneCount()
    local bones = {}
    for i = 0, boneCount - 1 do
        local name = ent:GetBoneName(i)
        if name and name ~= "" then
            bones[name] = {
                Parent = ent,
                Id = i,
                Name = name
            }
        end
    end
    return bones
end

function SWEP:CreateAttachmentModel(entry, slot)
    if SERVER then return end

    local Att = BASE_TRM_ATTS[entry.Class]
    if not Att or not Att.Model then return end

    local function CreateModel(att)
        local model = ClientsideModel(att.Model, RENDERGROUP_OPAQUE)
        if not IsValid(model) then return end
        model:SetOwner(self)
        model:SetNotSolid(true)
        model:SetNoDraw(true)
        model:AddEffects(EF_PARENT_ANIMATES)

        model:InvalidateBoneCache()
        model:SetupBones()

        model._IsAttachment = true

        -- 立即缓存骨骼并返回
        local bones         = buildSingleModelBone(model)
        return model, bones
    end

    local model, vBones = CreateModel(Att)
    entry.m_Model = model
    local tpModel, tpBones = CreateModel(Att)
    entry.m_TpModel = tpModel
    if Att.Bonemerge then
        if vBones then
            table.Merge(self.m_Bone, vBones)
        end
        if tpBones then
            table.Merge(self.wm_Bone, tpBones)
        end
    end
end

local function removeChildrenModel(ent, owner)
    if not ent then return end
    local children = ent:GetChildren()
    if not children then return end
    for _, child in ipairs(children) do
        if IsValid(child) and child:GetClass() == "class C_BaseFlex" and child:GetOwner() == owner then
            removeChildrenModel(child)
            child:Remove()
        end
    end
end

function SWEP:RemoveAllAttachementModels()
    if SERVER then return end
    removeChildrenModel(self:GetViewModel(), self)
    removeChildrenModel(self, self)
end

function SWEP:ResetWeaponModelData()
    self.m_Bone = {}
    self.wm_Bone = {}
end

------------------------------------------------------
function SWEP:BuildCustomizedGun()
    if CLIENT then
        self:CallOnClient("BuildCustomizedGun")
    end

    self:SyncAllAttachments()

    local vm = self:GetViewModel()
    local hasVM = IsValid(vm)
    local owner = self:GetOwner()
    local isActive = hasVM and owner and owner:GetActiveWeapon() == self

    self.sight = nil
    self.underbarrel = nil

    self.flashlight = false

    if CLIENT then
        self:CleanupFlashLights()
    end

    self:ChangeWeaponStats()

    self:InvalidateAttachments(vm)
    self:InvalidateAttachments(self)

    self:ResetWeaponModelData()
    if IsValid(vm) then
        self.m_Bone = buildSingleModelBone(vm)
    end
    self.wm_Bone = buildSingleModelBone(self)


    self:RemoveAllAttachementModels()

    for slot, att in pairs(self:GetAllAttachmentsInUse()) do
        self:CreateAttachmentModel(att, slot)
    end

    -- VM 相关操作只在 vm 有效时执行
    if hasVM and vm and owner and isActive then
        -- 确保骨骼数据已刷新
        if CLIENT then
            vm:InvalidateBoneCache()
            vm:SetupBones()
        end
        local sequence = vm:GetSequenceName(vm:GetSequence())
        self:PrecacheViewModel()
        self:PrepareViewModel()
        self:ApplyWeaponModelChange()
        vm:ResetSequence(sequence)
        --self:SetupViewmodel(vm)
    end


    self:ApplyCustomizationModels()
    self:GenerateAimOffset()

    if not self.underbarrel then
        self:SetUnderbarrel(false)
    end

    if owner.Flashlight and self.flashlight and owner:FlashlightIsOn() then
        owner:Flashlight(false)
    end

    self.m_Customized = true
    --self:SetupViewmodel()
    self:TrySetTask("Idle", true)
end

function SWEP:FindBone(name, isTp)
    return (self.m_Bone[name])
end

function SWEP:FindTpBone(name)
    return self.wm_Bone[name]
end

function SWEP:InvalidateAttachments(ent)
    if not IsValid(ent) then return end -- 关键：实体无效直接返回

    trm_utils.InvalidateCache(ent)

    local children = ent:GetChildren()
    if not children then return end -- 关键：没子实体也返回

    for _, c in pairs(children) do
        if c:GetClass() != "class BaseFlex" then
            continue
        end
        self:InvalidateAttachments(c)
    end
end

function SWEP:SetupViewmodel()
    local vm = self:GetViewModel()
    if not (vm and IsValid(vm)) then return end

    vm.RenderOverride = function(v)
        if not self or not util.IsTRMBase(self) then
            v.RenderOverride = nil
        end
        local wep = self:GetOwner():GetActiveWeapon()
        if not wep or not util.IsTRMBase(wep) then
            v.RenderOverride = nil
        end

        self:BuildViewmodelAttachmentsData(v)

        v:DrawModel()

        for _, att in pairs(self:GetAllAttachmentsInUse()) do
            local tbl = BASE_TRM_ATTS[att.Class]
            if att.m_Model and tbl.Render then
                tbl:Render(self, att.m_Model)
            end
        end
    end
end
