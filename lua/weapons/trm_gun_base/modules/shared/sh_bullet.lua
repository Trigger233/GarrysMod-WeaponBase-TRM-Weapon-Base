local cvar_damage = CreateConVar("trmbase_sv_mod_damage", 1, FCVAR_ARCHIVE, "", 0, 10)


function SWEP:BulletCallback(attacker, tr, dmginfo)
    local ent = tr.Entity




    -- 只对玩家生效
    if  ent.TakeDamageInfo then
        local baseMulti = cvar_damage:GetFloat()

        -- 获取击中部位
        local group = tr.HitGroup

        local scale = 1
        if attacker:IsPlayer() then
            if group == HITGROUP_HEAD then
                scale = self.DamageScale.Head or 4
            elseif group == HITGROUP_CHEST or group == HITGROUP_STOMACH then
                scale = self.DamageScale.Body or 1
            elseif group == HITGROUP_LEFTARM or group == HITGROUP_RIGHTARM then
                scale = self.DamageScale.Arms or 0.8
            elseif group == HITGROUP_LEFTLEG or group == HITGROUP_RIGHTLEG then
                scale = self.DamageScale.Legs or 0.6
            end
        end


        dmginfo:ScaleDamage(scale * baseMulti)


        for _, entry in pairs(self:GetAllAttachmentsInUse()) do
            if entry and entry.Class and BASE_TRM_ATTS[entry.Class].BulletCallback then
                BASE_TRM_ATTS[entry.Class]:BulletCallback(attacker, tr, dmginfo)
            end
        end
    end
    self:BulletInterval(attacker, tr, dmginfo)
end

function SWEP:BulletInterval(attacker, tr, dmginfo)
    if tr.HitNoDraw or tr.HitSky then
        return
    end

    local output = {}
    local dir = tr.Normal
    local start = tr.HitPos

    local pen = self.Bullet.Penetration
    if not pen then return end

    local current = self:GetPenetrationCount()

    if current <= 0 then return end

    local damage = dmginfo:GetDamage() * pen.DamageMultiplier


    if (IsFirstTimePredicted()) then
        --debugoverlay.Axis(tr.HitPos, tr.HitNormal:Angle(), 5, 5, true)

        util.TraceLine({
            start = tr.HitPos + tr.Normal,
            endpos = tr.HitPos + tr.Normal * 30000,
            mask = MASK_SHOT,
            filter = { tr.Entity },
            ignoreworld = false,
            output = output
        })

        util.TraceLine({
            start = output.HitPos,
            endpos = tr.HitPos,
            mask = MASK_SHOT,
            output = output
        })

        --PrintTable(output)

        --debugoverlay.Line(tr.HitPos, output.HitPos, 5, Color(255, 0, 0, 255), true)
    end

    if (output != nil) then
        self:SetPenetrationCount(current - 1)

        --fire back to the wall to make hole
        self:GetOwner():FireBullets({
            Attacker = self:GetOwner(),
            Src = output.StartPos,
            Dir = -tr.Normal,
            Num = 1,
            Tracer = 0,
            Damage = 0
        })

        --fire forward
        self:GetOwner():FireBullets({
            Attacker = self:GetOwner(),
            Src = output.HitPos,
            Dir = tr.Normal,
            Num = 1,
            Tracer = 0,
            Damage = damage,
            Callback = function(attacker, tr, dmgInfo)
                self:BulletCallback(attacker, tr, dmgInfo)
            end
        })
    end
end
