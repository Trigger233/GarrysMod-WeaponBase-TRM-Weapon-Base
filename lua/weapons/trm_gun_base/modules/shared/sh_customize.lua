require("trm_utils")
require("trm_math")
function SWEP:RefreshAttTable()
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

    if slot.Category and ! table.HasValue(slot.Category, attData.Category) then
        return false
    end

    if ! attData.Selectable then return false end

    -- 没有 Category 的配件不参与排斥
    local attCats = attData.Category
    if not attCats then return true end
    if not istable(attCats) then attCats = { attCats } end

    -- 方向 A：其他已装备配件排斥本配件
    for _, entry in pairs(self:GetAllAttachmentsInUse()) do
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

function SWEP:Attach(slot, attClass, NoSave)
    local Weapon = self.Attachments[tonumber(slot)]
    if attClass and self:CanEquip(slot, attClass) then
        self.CurrentAttachments[slot] = { Class = attClass }
    elseif Weapon != nil and Weapon.Default then
        self.CurrentAttachments[slot] = { Class = Weapon.Default }
    else
        self.CurrentAttachments[slot] = nil
    end
    self:OnAttachmentChanged(NoSave)
end

function SWEP:OnAttachmentChanged(shouldntsave)
    self:BuildCustomizedGun()
    if not shouldntsave then
        self:SaveAttachmentPreset()
    end
end

function SWEP:PrecacheViewModel()
    self.m_ViewmodelCache = nil
    self.m_WorldModelCache = nil
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
        end

        if _att.WorldModel then
            self.m_WorldModelCache = _att.WorldModel
        end
        if _att.Skin then
            self.m_SkinCache = _att.Skin
        end
        if _att.BodyGroup then
            for _model, _submodel in pairs(_att.BodyGroup) do
                self.m_BodyGroupCache[_model] = _submodel
            end
        end
        if _att.poseParameter then
            self.m_PoseParameter = _att.poseParameter
        end
        if _att.poseParameter2 then
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
    local wm = self.m_WorldModelCache or self.WorldModel
    self:SetModel(wm)
    local vm = self:GetViewModel()
    if not IsValid(vm) or not self:IsPlyCarry() then return false end
    local viewmodel = self.m_ViewmodelCache or self.ViewModel

    vm:SetModel(viewmodel)
-----------
    --------
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
        if not entry or not entry.Class or not BASE_TRM_ATTS[entry.Class] then continue end
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



---CustomizeSystem


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

function SWEP:ApplyCustomizationModels()
    if SERVER then return end
    local vm = self:GetViewModel()
    self:InvalidateBoneCache()
    self:SetupBones()





    for slot, entry in pairs(self:GetAllAttachmentsInUse()) do
        if not entry or not entry.Class then continue end
        local AttachmentData = BASE_TRM_ATTS[entry.Class]
        if ! AttachmentData then
            -- print(entry.Class or "Nil")
            -- PrintTable(BASE_TRM_ATTS["att_ammo_ap"])
            continue
        end
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
            local bone = self:FindBone(WeaponData.Bone)
            if IsValid(model) and bone then
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
            local finalAng = Angle()

            local addAng = Angle()
            if WeaponData.Ang then
                addAng:Add(WeaponData.Ang)
            end

            if AttachmentData.Angles then
                addAng:Add(AttachmentData.Angles)
            end
            trm_math.RotateAxis(finalAng, addAng)

            local addPos = Vector(0, 0, 0)

            if WeaponData.Pos then
                addPos:Add(WeaponData.Pos)
            end

            if AttachmentData.Pos then
                addPos:Add(AttachmentData.Pos)
            end


            if IsValid(model) then
                model:SetLocalPos(addPos)
                model:SetLocalAngles(finalAng)
            end
            if IsValid(Tpmodel) then
                Tpmodel:SetLocalPos(addPos)
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

function SWEP:GenerateCustomizationStats()
    if (SERVER) then
        return
    end

    self.m_Foregrip = nil
    self.laser = false


    for slot, entry in pairs(self.CurrentAttachments or {}) do
        if not entry or not entry.Class then continue end
        local AttachmentData = BASE_TRM_ATTS[entry.Class]
        if not AttachmentData or AttachmentData.Model == nil then continue end

        if AttachmentData.Sight != nil then
            local align = self.Attachments[tonumber(slot)]
            if not align then continue end

            local localPos = Vector(0, 0, 0)
            if AttachmentData.Sight.Pos then
                localPos:Add(AttachmentData.Sight.Pos)
            end
            if align.SightPos then
                localPos:Add(align.SightPos)
            end
            local AimPos = Vector(localPos.x, localPos.y + 2, localPos.z)
            local AimAng = align.SightAng or Angle(0, 0, 0)

            self.sight = {
                AimPos = AimPos,
                AimAng = AimAng,
            }


            if AttachmentData.HybridSight != nil then
                self.sight = self.sight or {}

                local stats = AttachmentData.HybridSight
                local localPos2 = Vector(0, 2, 0)
                if stats.Pos then
                    localPos2:Add(stats.Pos)
                end
                if align.SightPos != nil then
                    localPos2:Add(align.SightPos)
                end
                self.sight.HybridSight = {
                    AimPos = localPos2,
                    AimAng = align.SightAng or Angle(0, 0, 0),
                }
            end
        end

        if AttachmentData.Scope then
            self.sight.zoom = AttachmentData.Scope.Zoom

            self.sight.MaxZoom = AttachmentData.Scope.Max or self.sight.zoom
            self.sight.MinZoom = AttachmentData.Scope.Min or self.sight.zoom
        end

        if AttachmentData.LHIK then
            self.m_Foregrip = {
                Viewmodel = entry.m_Model,
                Data = AttachmentData,
            }
        end

        if AttachmentData.Laser then
            self.laser = true
        end
    end

    if (! self.sight or ! self.sight.HybridSight) then
        self:SwitchHybrid(true)
    end

    -- if (self.sight and self.sight.HybridSight != nil or self:HasFlag("HybridOn")) then
    --     self:SwitchHybrid()
    -- end
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
    net.WriteUInt(count, 16)
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
    if ! attClass then
        weapon:Attach(slot)
    else
        weapon:Attach(slot, attClass)
    end
end)


function SWEP:GetAllAttachmentsInUse()
    return self.CurrentAttachments or {}
end

local function buildSingleModelBone(ent)
    if not CLIENT then return end
    if not ent or not IsValid(ent) then
        return
    end

    ent:SetupBones()
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
        local model = ClientsideModel(att.Model, RENDERGROUP_VIEWMODEL)
        if not IsValid(model) then return end
        model:SetRenderMode(RENDERMODE_ENVIROMENTAL)
        model:SetOwner(self)
        model:SetNotSolid(true)
        model:SetNoDraw(true)
        model:AddEffects(EF_PARENT_ANIMATES)
        model.TRMAttachmentModel = true
        model:InvalidateBoneCache()
        model:SetupBones()

        model.m_CustomDelta = self.CurrentAttachments[slot].CustomDelta
        self.CurrentAttachments[slot].CustomDelta = 0
        model._IsAttachment = true

        if att.Init then
            att:Init(self, model)
        end
        trm_weapon_base_util.DealWithFullUpdate(model)
        -- 立即缓存骨骼并返回
        local bones = buildSingleModelBone(model)



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
    if self:GetNoDraw() then return end
    self:SyncAllAttachments()


    local vm = self:GetViewModel()
    local hasVM = IsValid(vm)
    local owner = self:GetOwner()
    local isActive = hasVM and owner and owner:GetActiveWeapon() == self
    self.sight = nil
    self.underbarrel = nil
    self.flashlight = nil
    self.bipod = nil

    if CLIENT then
        self:CleanupFlashLights()
        self:InvalidateBoneCache()
        self:SetupBones()
    end

    self:ChangeWeaponStats()
    self:FireModeStat(self:GetFiremodeIndex())

    self:InvalidateAttachments(vm)
    self:InvalidateAttachments(self)

    self:ResetWeaponModelData()
    if IsValid(vm) then
        self.m_Bone = buildSingleModelBone(vm)
    end
    self.wm_Bone = buildSingleModelBone(self)


    for slot, att in pairs(self:GetAllAttachmentsInUse()) do
        self:CreateAttachmentModel(att, slot)
    end


    -- VM 相关操作只在 vm 有效时执行
    if hasVM and vm and owner and isActive then
        local sequence = vm:GetSequence()
        -- 确保骨骼数据已刷新
        if CLIENT then
            vm:InvalidateBoneCache()
            vm:SetupBones()
            vm:ClearPoseParameters()
        end

        self:PrecacheViewModel()
        self:PrepareViewModel()
        self:ApplyWeaponModelChange()
        self:SetupViewmodel()
        vm:ResetSequence(sequence)
    end
    self:RemoveAllAttachementModels()


    self:ApplyCustomizationModels()
    self:GenerateCustomizationStats()

    if not self.underbarrel then
        self:SetUnderbarrel(false)
    end


    --self:RemoveFlag("HybridOn")

    if owner.Flashlight and self.flashlight and owner:FlashlightIsOn() then
        owner:Flashlight(false)
    end

    if IsValid(TRM_AttachMenu_Instance) then
        TRM_AttachMenu_Instance:RefreshAll()
    end



    self.m_Customized = true
    --self:SetupViewmodel()
    if isActive then
        self:TrySetTask("Idle", true)
    end
end

function SWEP:FindBone(name)
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

local cvar_highlight = CreateClientConVar("trmbase_cl_alwaysdrawhighlight", 0, true, true, "", 0, 1)

local def_customcolor = color_white
local function DrawCustomHighlight(model, att, weapon)
    model.m_CustomDelta = (model.m_CustomDelta or 1) -
        (math.min(FrameTime(), 0.1) * (weapon and weapon.IsCustomizing and weapon:IsCustomizing() and 3 or 1))
    if ! (weapon:IsCustomizing() or cvar_highlight:GetBool()) then return end
    if model.m_CustomDelta <= 0 then return end
    model:RemoveEFlags(EFL_USE_PARTITION_WHEN_NOT_SOLID)

    render.SetStencilWriteMask(0xFF)
    render.SetStencilTestMask(0xFF)
    render.SetStencilReferenceValue(0)

    render.SetStencilCompareFunction(STENCIL_ALWAYS)
    render.SetStencilPassOperation(STENCIL_REPLACE)
    render.SetStencilFailOperation(STENCIL_KEEP)
    render.SetStencilZFailOperation(STENCIL_KEEP)

    render.SetStencilEnable(true)
    render.SetStencilReferenceValue(64 + 1)
    model:RemoveEFlags(EFL_USE_PARTITION_WHEN_NOT_SOLID)

    model:DrawModel()
    render.SetStencilCompareFunction(STENCIL_EQUAL)
    cam.Start2D()
    local color = att and att.CustomColor or def_customcolor
    surface.SetDrawColor(color.r, color.g, color.b, model.m_CustomDelta * 255)
    surface.DrawRect(0, 0, ScrW(), ScrH())
    cam.End2D()

    render.SetStencilEnable(false)
end

function SWEP:SetupViewmodel()
    local vm = self:GetViewModel()
    if not (vm and IsValid(vm)) then return end

    vm.RenderOverride = function(v, flag)
        if not self or not util.IsTRMBase(self) then
            v.RenderOverride = nil
        end


        local wep = IsValid(self) and IsValid(self:GetOwner()) and self:GetOwner().GetActiveWeapon and
            self:GetOwner():GetActiveWeapon()
        if not wep or not util.IsTRMBase(wep) then
            v.RenderOverride = nil
            return
        end

        if ! wep.IsCustomizing then
        end

        if not IsValid(v) then
            v.RenderOverride = nil
            return
        end

        self.m_OverDraw = true
        v:DrawModel(flag)

        if CLIENT then
            DrawCustomHighlight(v, self, wep)
        end
        if self.GetAllAttachmentsInUse then
            for _, att in pairs(self:GetAllAttachmentsInUse()) do
                local tbl = BASE_TRM_ATTS[att.Class]
                if IsValid(att.m_Model) and tbl.Render then
                    att.m_Model:SetupBones()
                    tbl:Render(self, att.m_Model)
                    if CLIENT then
                        DrawCustomHighlight(att.m_Model, tbl, wep)
                    end
                elseif tbl and tbl.Model and ! v:GetNoDraw() then
                    self:BuildCustomizedGun()
                end
            end
        end
        self.m_OverDraw = false
    end
end
