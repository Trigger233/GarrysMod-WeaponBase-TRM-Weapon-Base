-- =============================================
-- 空间混响检测（移植自 Modern Bentleyfare Base）
-- 静默多方向射线检测室内/室外，用于枪声混响
-- =============================================

local REVERB_RESOLUTION = 0.25
local REVERB_ROOMSIZE = 2048
local REVERB_TINYROOMSIZE = 320
local REVERB_REFRESH_TIME = 0.3

local reverbHull = Vector(4, 4, 4)
local reverbCoroutines = {}

local function CheckRoomScale(dist)
    return dist > (REVERB_ROOMSIZE * REVERB_ROOMSIZE)
end

-- 为指定武器启动混响检测协程
local function StartReverbCoroutine(wep)
    if not IsValid(wep) then return end
    local owner = wep:GetOwner()
    if not IsValid(owner) or not owner:IsPlayer() then return end

    local id = wep:EntIndex()

    -- 已存在协程则不重复启动
    if reverbCoroutines[id] then return end

    reverbCoroutines[id] = coroutine.create(function()
        while IsValid(wep) and IsValid(owner) do
            local dist = 0
            local start = owner:EyePos()
            local roomScale = wep.Reverb and wep.Reverb.RoomScale or 50000
            local len = math.pow(roomScale, 1 / 3) * 100
            local resolution = 1

            for r = 0.5, 0.1, (REVERB_RESOLUTION / resolution) * -0.5 do
                local hCos = math.sin(r * math.pi)
                for i = -1, 1, (REVERB_RESOLUTION / resolution) do
                    if not IsValid(wep) or not IsValid(owner) then break end

                    local sin = math.sin(i * math.pi) * hCos
                    local cos = math.cos(i * math.pi) * hCos
                    local dir = Vector(sin, cos, math.cos(r * math.pi))
                    local tr = util.TraceHull({
                        start = start,
                        endpos = start + dir * 32768,
                        mask = MASK_SHOT,
                        mins = -reverbHull,
                        maxs = reverbHull,
                        filter = owner
                    })

                    local distToHitPos = start:DistToSqr(tr.HitPos)
                    local acceptableClose = REVERB_TINYROOMSIZE * REVERB_TINYROOMSIZE

                    if tr.HitSky or CheckRoomScale(distToHitPos) then
                        dist = dist + (REVERB_ROOMSIZE * REVERB_ROOMSIZE) * 0.3
                    else
                        if distToHitPos <= acceptableClose then
                            dist = dist - (REVERB_ROOMSIZE * REVERB_ROOMSIZE) * 0.15
                        else
                            dist = dist - (distToHitPos * 0.4)
                        end
                    end

                    if CheckRoomScale(dist) then break end
                end
                coroutine.yield(0)
            end

            local isOutside = CheckRoomScale(dist)
            wep.m_ReverbOutside = isOutside

            -- 等待下一次检测
            coroutine.wait(REVERB_REFRESH_TIME)
        end

        reverbCoroutines[id] = nil
    end)
end

-- 每帧驱动协程
-- local cv_debug_reverb = CreateConVar("trmbase_debug_reverb", 0, FCVAR_ARCHIVE)
-- hook.Add("Think", "TRMBase_ReverbThink", function()
--     for id, co in pairs(reverbCoroutines) do
--         local ok, err = coroutine.resume(co)
--         if not ok then
--             reverbCoroutines[id] = nil
--         end
--     end
-- end)

function SWEP:HandleReverb(tbl)
    tbl = tbl or self.Reverb
    if not tbl or not tbl.Sounds then return end
    if not IsValid(self:GetOwner()) or not IsFirstTimePredicted() then return end

    -- 启动或更新混响检测
    StartReverbCoroutine(self)

    local isOutside = self.m_ReverbOutside
    if isOutside == nil then
        local trace = util.TraceLine({
            start = self:GetOwner():GetShootPos(),
            endpos = self:GetOwner():GetShootPos() + self:GetOwner():GetAimVector() * 100,
            filter = self:GetOwner()
        })
        local distance = trace.StartPos:Distance(trace.HitPos)
        isOutside = math.pow(distance, 2) > (tbl.RoomScale or 50000)
    end

    -- 消音器检测：优先使用 Suppressed 音效
    local isSup = self.Slienced
    local sounds = isOutside and tbl.Sounds.Outside or tbl.Sounds.Inside
    local layer = isSup and sounds.LayerSup or sounds.Layer
    local reflection = isSup and sounds.ReflectionSup or sounds.Reflection

    if layer and layer ~= "" then
        self:GetOwner():EmitSound(layer)
    end
    if reflection and reflection ~= "" then
        self:GetOwner():EmitSound(reflection)
    end
end
