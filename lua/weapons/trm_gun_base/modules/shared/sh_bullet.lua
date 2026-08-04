local cvar_damage = CreateConVar("trmbase_sv_mod_damage", 1, FCVAR_ARCHIVE, "", 0, 10)
local cvar_penetration = CreateConVar("trmbase_sv_penetration",1,FCVAR_ARCHIVE, "", 0, 1)
function SWEP:BulletCallback(attacker, tr, dmginfo)
    local ent = tr.Entity



    local tbl = self.Bullet
    -- 只对玩家生效
    if  ent.TakeDamageInfo then
        local baseMulti = cvar_damage:GetFloat()

        -- 获取击中部位
        local group = tr.HitGroup

        local scale = 1
        if attacker:IsPlayer() then
            if group == HITGROUP_HEAD then
                scale = tbl.HeadShotMultiplier 
            end
        end


        dmginfo:ScaleDamage(scale * baseMulti)


        for _, entry in pairs(self:GetAllAttachmentsInUse()) do
            if entry and entry.Class and BASE_TRM_ATTS[entry.Class] and BASE_TRM_ATTS[entry.Class].BulletCallback then
                BASE_TRM_ATTS[entry.Class]:BulletCallback(attacker, tr, dmginfo)
            end
        end

        if ent:IsPlayer() and ent:Armor() >0 then
            local dmg = dmginfo:GetDamage() * tbl.Penetration.ArmorPenetrateDamage
            ent:SetArmor(math.max(0,ent:Armor() - dmg))
        end

    end
    self:BulletInterval(attacker, tr, dmginfo)
end

function SWEP:BulletInterval(attacker, tr, dmginfo)
    if tr.HitNoDraw or tr.HitSky or not cvar_penetration:GetBool() then
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



        --fire forward
        self:GetOwner():FireBullets({
            Attacker = self:GetOwner(),
            Inflictor =  self,
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

--for our Alarm mod
function SWEP:HandlePenetrating(ent,dmginfo)
    dmginfo:ScaleDamage(self.Bullet.Penetration.ArmorPenetrateDamage)

    local damage = dmginfo:GetDamage()
    if AlarmSys != nil then
        AlarmSys:StunNPC(ent, damage / 20)
    end

    return dmginfo
end






-- hook.Add("Alarm.ArmorPenetratingDamage", "TRMBase", function(ent,dmginfo)
--     local weapon = dmginfo:GetInflictor()
--     return weapon.HandlePenetrating and weapon:HandlePenetrating(ent,dmginfo)   
-- end)
