AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Ammunition Pile Small"
ENT.Category = "TRMWEAPONS_ENTS"
ENT.Editable = true
ENT.Spawnable = true
ENT.AdminOnly = false

-- 配置参数
ENT.UseRange = 100  -- 使用距离
ENT.CheckInterval = 0.5  -- 检测间隔（秒）
ENT.Lifetime = 30  -- 生命周期（秒），30秒后自动消失

function ENT:Draw()
    self:DrawModel()

end

function ENT:Initialize()
    if SERVER then
        self:SetModel("models/props_junk/cardboard_box004a.mdl")
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_WEAPON)  -- 改为武器碰撞组，避免玩家碰撞
        self:DrawShadow(true)
        
        local phys = self:GetPhysicsObject()
        if phys and phys:IsValid() then
            phys:Wake()
        end
        -- 启动距离检测定时器
        self:StartCheckingDistance()
        
        end
        self:AddEffects(EF_ITEM_BLINK)

end


-- 启动距离检测
function ENT:StartCheckingDistance()
    timer.Create("AmmoCheck_" .. self:EntIndex(), self.CheckInterval, 0, function()
        if not IsValid(self) then return end
        self:CheckPlayersInRange()
    end)
end

-- 检测范围内玩家
function ENT:CheckPlayersInRange()
    local pos = self:GetPos()
    
    for _, ply in pairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() then
            local dist = pos:Distance(ply:GetPos())
            
            if dist <= self.UseRange then
                self:GiveAmmoToPlayer(ply)
                return  -- 只给第一个进入范围的玩家
            end
        end
    end
end

local Ammo = {
    "SniperRound",
    "SniperPenetratedRound",
}
-- 给玩家补充弹药
function ENT:GiveAmmoToPlayer(ply)
    local _UseAble = false
    for _, ammoType in pairs(Ammo) do
        local ammoId = game.GetAmmoID(ammoType)
        local reserve = ply:GetAmmoCount(ammoId)
        if reserve >= game.GetAmmoMax(ammoId) then continue end  -- 已满则跳过
        _UseAble = true
        ply:GiveAmmo(10, ammoType, false)  -- 每种弹药补充10发
    end
    if _UseAble then
        self:Remove()  -- 给完弹药后移除实体
    end
end



-- 移除原来的触碰和碰撞函数
function ENT:PhysicsCollide(data, phys)
end

function ENT:Touch(activator)
    -- 不再使用触碰触发
end