ATTACHMENT.Base = "att_base"
ATTACHMENT.Name = "Explosion Ammo"
ATTACHMENT.Category = "att_ammo"
function ATTACHMENT:Stats(weapon)
    self:ScaleTableValue(weapon.Recoil.Vertical, 5)
    self:ScaleTableValue(weapon.Recoil.Horizonal, 5)
    weapon.Primary.Damage = weapon.Primary.Damage * 0.2
    weapon.Spread.Base = weapon.Spread.Base * 1.8
    weapon.Primary.ClipSize = math.Round(weapon.Primary.ClipSize * 0.43,0)
    weapon.PrintName = weapon.PrintName .. "Explosion-Bullets"
    weapon.Recoil.Shake = weapon.Recoil.Shake * 3
    self:ScaleTableValue(weapon.VisualRecoil.Backward, 3)
    weapon.HUDElement.Bullet = Color(255, 37, 37, 255)
    weapon.Spread.Base = weapon.Spread.Base * 3
    weapon.Spread.Increase = weapon.Spread.Increase * 3
    weapon.Spread.Max = weapon.Spread.Max * 2
    weapon.Recoil.AdsMultiplier = weapon.Recoil.AdsMultiplier *1.5
end

function ATTACHMENT:BulletCallback(attacker, tr, dmginfo)
    dmginfo:SetDamageType(DMG_BLAST)
    if tr.Entity  then
        local explosion = ents.Create("env_explosion")
        if IsValid(explosion) then
            explosion:SetPos(tr.HitPos)
            explosion:SetOwner(attacker)
            explosion:Spawn()
            explosion:SetKeyValue("iMagnitude", "40")
            explosion:SetKeyValue("Render Mode", "5")
            explosion:SetKeyValue("Radius Override", "200")
            explosion:Fire("Explode", 0, 0)
        end
    end
end
