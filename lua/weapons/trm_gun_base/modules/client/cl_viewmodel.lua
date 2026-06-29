if SERVER then return end

function SWEP:ShouldDrawViewModel()
    local owner = self:GetOwner()
    if owner:InVehicle() then return false end
    return true
end

require("trm_utils")
function SWEP:ViewModelDrawn(vm, flag)
    if not IsValid(vm) then return end
    vm:SetupBones()
    self:BuildViewmodelAttachmentsData(vm)

    for _, att in pairs(self:GetAllAttachmentsInUse()) do
        local attData = BASE_TRM_ATTS[att.Class]

        if IsValid(att.m_Model) and self:IsFirstPerson() then
            if attData.Render then
                attData:Render(self, att.m_Model)
            end
        end
    end
end

local NextUpdate = 0
function SWEP:BuildViewmodelAttachmentsData(vm)
    if not IsValid(vm) then return end
    if CurTime() - NextUpdate > 0 then
        self.m_Attachment = self.m_Attachment or {}
        local stats = self.Effects
        if not stats then return end

        for _, element in pairs(stats) do
            if not element or not element.attachment then
                continue
            end
            local attName =element.attachment

            local ent, attId = self:FindAttachment(vm,attName )
            if not IsValid(ent) or not attId or attId == -1 then
                -- 可选：用默认值或跳过
                self.m_Attachment[element.attachment] = false
                continue
            end

            local att = ent:GetAttachment(attId)
            if not att then
                self.m_Attachment[element.attachment] = false
                continue
            end

            self.m_Attachment[element.attachment] = att
        end
        NextUpdate = CurTime() + RealFrameTime()
    end
end

function SWEP:GetAttachmentData(name)
    return self.m_Attachment[name] or false
end

function SWEP:PostDrawViewModel(vm, weappon, ply, flag)
end

function SWEP:PreDrawViewModel(vm)
    if GetConVar("trmbase_cl_cheapscope"):GetBool() then
        self:RenderScopeView()
    end

end

concommand.Add("trm_clear_test_model", function(ply)
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end

    if wep.test and IsValid(wep.test.m_model) then
        wep.test.m_model:Remove()
        wep.test.m_model = nil
        print("测试模型已清除")
    else
        print("没有找到测试模型")
    end
end)

-- 调试 ConVar
CreateClientConVar("trmbase_freeze_vm", 0)

-- =============================================
-- 调试：冻结 viewmodel 位置/角度
-- =============================================

concommand.Add("trmbase_freeze_vm", function(ply, cmd, args)
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or not util.IsTRMBase(wep) then
        print("[TRMBase] 当前武器不是 TRM Base 武器")
        return
    end

    local cv = GetConVar("trmbase_freeze_vm")
    local newVal = cv:GetInt() == 0 and 1 or 0
    cv:SetInt(newVal)

    if newVal == 1 then
        local vm = wep:GetViewModel(0)
        if IsValid(vm) then
            wep.m_VMFreezePos = vm:GetPos()
            wep.m_VMFreezeAng = vm:GetAngles()
        end
        print("[TRMBase] Viewmodel 已冻结")
        print("  位置:", tostring(wep.m_VMFreezePos))
        print("  角度:", tostring(wep.m_VMFreezeAng))
        print("  再次执行 trmbase_freeze_vm 解冻")
    else
        wep.m_VMFreezePos = nil
        wep.m_VMFreezeAng = nil
        print("[TRMBase] Viewmodel 已解冻")
    end
end)

concommand.Add("trm_test_ents", function()
    local count = 0
    for _, e in ents.Iterator() do
        count = count + 1
        print(e, e:GetParent(), e:GetModel(), e:GetOwner())
    end
    print(count)
end)
