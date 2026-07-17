if SERVER then return end

function SWEP:ShouldDrawViewModel()
    local owner = self:GetOwner()
    if owner:InVehicle() then return false end
    return true
end

require("trm_utils")
function SWEP:ViewModelDrawn(vm, flag)
    if not IsValid(vm) or self.m_OverDraw then return end
    self:BuildViewmodelAttachmentsData(vm)

    -- for _, att in pairs(self:GetAllAttachmentsInUse()) do
    --     local attData = BASE_TRM_ATTS[att.Class]

    --     if IsValid(att.m_Model) and self:IsFirstPerson() then
    --         if attData.Render then
    --             attData:Render(self, att.m_Model)
    --         end
    --     end
    -- end
end

local NextUpdate = 0
function SWEP:BuildViewmodelAttachmentsData(vm)
    if not IsValid(vm) then return end
    if SysTime() - NextUpdate > 0 then
        self.m_Attachment = self.m_Attachment or {}
        local stats = self.Effects
        if not stats then return end

        for _, element in pairs(stats) do
            if not element or not element.attachment then
                continue
            end
            local attName =element.attachment

            local ent, attId = self:FindAttachment(self:IsFirstPerson() and vm or self, attName)
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
        NextUpdate = SysTime() + 1 / 30 
    end
end

function SWEP:GetAttachmentData(name)
    return self.m_Attachment[name] or false
end

function SWEP:PostDrawViewModel(vm, weappon, ply, flag)
    if self.m_OverDraw then return end
    cam.End3D()


end

local cvar_blur = CreateClientConVar("trmbase_cl_blur", 1, true, true, "helptext", 0, 1)
local BlurMul = 0
function SWEP:PreDrawViewModel(vm)
    if self.m_OverDraw then return end
    
    BlurMul = Lerp(RealFrameTime() * 10 , BlurMul, (self:IsReloading() and self:GetAimDelta() < 0.2  or self:IsCustomizing()) and 1 or 0)
    if BlurMul > 0.1 and cvar_blur:GetBool() then
        DrawBokehDOF(BlurMul * 5, 1, 12)
    end

    cam.Start3D(EyePos(), EyeAngles(), self:GetViewmodelFov(), 0, 0, ScrW(), ScrH(), 1, 1024)
    render.DepthRange(0.0, 0.0)

    if GetConVar("trmbase_cl_cheapscope"):GetBool() then
        self:RenderScopeView()
    end
   self:DoLHIK()

end



-- 调试 ConVar
CreateClientConVar("trmbase_freeze_vm", 0)


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

