AddCSLuaFile()
module("trm_utils", package.seeall)

local cachedBones = {}
--------缓存返回指定骨骼的Id

function trm_utils.LookupBoneCached(ent, boneName)
    local model = ent:GetModel()

    if (model == nil) then
        return nil
    end

    cachedBones[model] = cachedBones[model] || {}
    cachedBones[model][boneName] = cachedBones[model][boneName] || ent:LookupBone(boneName)

    return cachedBones[model][boneName]
end

local cachedAttachments = {}
--------缓存返回指定附件的Id
function trm_utils.LookupAttachmentCached(ent, attName)
    local model = ent:GetModel()
    if (model == nil) then
        return nil
    end

    cachedAttachments[model] = cachedAttachments[model] || {}
    cachedAttachments[model][attName] = cachedAttachments[model][attName] || ent:LookupAttachment(attName)

    return cachedAttachments[model][attName] > 0 && cachedAttachments[model][attName] || nil
end

local function requireAttachment(ent, attName)
    ent.m_AttachmentRequests = ent.m_AttachmentRequests || {}
    ent.m_AttachmentDeliveries = ent.m_AttachmentDeliveries || {}

    local attId = trm_utils.LookupAttachmentCached(ent, attName)
    if (ent.m_AttachmentRequests[attId] == nil) then
        ent.m_AttachmentRequests[attId] = Matrix()

        timer.Simple(0, function()
            if (! IsValid(ent)) then
                return
            end

            local attData = ent:GetAttachment(attId)

            local computeMatrix = Matrix()
            computeMatrix:SetTranslation(attData.Pos)
            computeMatrix:SetAngles(attData.Ang)

            local worldMatrix = ent:GetBoneMatrix(0)

            computeMatrix = worldMatrix:GetInverse() * computeMatrix
            ent.m_AttachmentRequests[attId] = computeMatrix
        end)

        ent.m_AttachmentDeliveries[attId] = { Pos = Vector(), Ang = Angle() }
    end

    if (! ent.m_bFastAttachment) then
        if (ent.OnBuildFastAttachments == nil) then
            ent.OnBuildFastAttachments = function() end --to avoid if
        end

        ent._BoneCallBack = ent:AddCallback("BuildBonePositions", function(ent, numbones)
            if not ent.m_AttachmentRequests then return end -- 加这行

            local matrix = ent:GetBoneMatrix(0)
            if not matrix then return end

            for attId, localMat in pairs(ent.m_AttachmentRequests) do
                local newMatrix = matrix * localMat
                ent.m_AttachmentDeliveries[attId].Pos = newMatrix:GetTranslation()
                ent.m_AttachmentDeliveries[attId].Ang = newMatrix:GetAngles()
                ent:OnBuildFastAttachments()
            end
        end)
        ent.m_bFastAttachment = true
    end
end

--获取附件
function trm_utils.GetFastAttachment(ent, attName)
    requireAttachment(ent, attName)
    return ent.m_AttachmentDeliveries[trm_utils.LookupAttachmentCached(ent, attName)]
end

-- 清空缓存（模型变化时调用）
function trm_utils.InvalidateCache(ent)
    local model = ent:GetModel()
    if model then
        cachedBones[model] = nil
        cachedAttachments[model] = nil
    end
    ent.m_AttachmentRequests = nil
    ent.m_AttachmentDeliveries = nil
    ent.m_bFastAttachment = nil
    if ent._BoneCallBack != nil then
        ent:RemoveCallback("BuildBonePositions", ent._BoneCallBack)
    end
end
