
local cvar_firebreakreload = CreateConVar("trmbase_fire_interupt_reload", 0, FCVAR_ARCHIVE)

function SWEP:MagzineReload()
	self:SetNextAnimationTime(0)
	self:PlayAnimation(self:ChooseAnim("Reload"), true)
	self:TrySetTask("Idle")
	
	if cvar_firebreakreload:GetInt() >= 1 then
		self:SetNextFireTime(60 / self.Primary.RPM)
		self:SetNextAnimationTime(0)
	end
end

function SWEP:SingleReload()
	local Empty = self:Clip1() == 0 and true or false
	self:SetNextAnimationTime(0)
	if Empty and self.Animations.Reload_Empty then
		self:PlayAnimation("Reload_Empty", true)
	elseif self.Animations.Reload_Start then
		self:PlayAnimation("Reload_Start", true)
	end
	self:TrySetTask("ReloadLoop")
end

local cvar_infinite_reserve = CreateConVar("trmbase_infinite_ammo", 0, { FCVAR_ARCHIVE }, "Enable Infinite Reserve Ammo",
	0, 1)

function SWEP:Task_ReloadLoop(cycle)
	local reserve = self:GetOwner():GetAmmoCount(self:GetPrimaryAmmoType())
	local max = self:GetMaxClip1() + self:GetChamberAmmo()
	if (self:Clip1() < max and (reserve > 0 or cvar_infinite_reserve:GetBool())) then
		self:PlayAnimation("Reload", true)
	elseif cycle >= 0.9 then
		self:SetCurrentTask("ReloadEnd")
	end
end

function SWEP:Task_ReloadEnd(cycle)
	self:SetNextAnimationTime(0)
	local animTable = self.Animations
	if self:GetChamberAmmo() <= 0 and animTable.Reload_End_Empty then
		self:PlayAnimation("Reload_End_Empty", true)
	elseif animTable.Reload_End then
		self:PlayAnimation("Reload_End", true)
	end
	self:SetCurrentTask("Finished")
end

local cvar_debug_reload = CreateConVar("trmbase_debug_reload", 0, FCVAR_ARCHIVE, "Force reload for 2 round", 0, 1)

function SWEP:CanReload()
	local reserveAmmo = self:GetOwner():GetAmmoCount(self:GetPrimaryAmmoType())
	local seq = self:GetPlayingSequence()


	local max = cvar_debug_reload:GetBool() and 2 or (self.Primary.ClipSize +
		(self.Primary.BoltAction and self:GetChamberAmmo() or self.Primary.Chamber))
	if string.find(seq, "Reload") then return false end
	if not GetConVar("trmbase_allow_sprintreload"):GetBool() and string.find(seq, "Sprint") and not string.find(seq, "SprintOut") then return false end
	if (cvar_infinite_reserve:GetBool()) then
		return self:Clip1() < max
	else
		return reserveAmmo > 0 && self:Clip1() < max
	end
end

function SWEP:MagzineLoaded()
	local owner = self:GetOwner()
	if not owner or not owner:IsPlayer() then
		self:SetClip1(self.Primary.Clipsize)
	end
	local reserveAmmo = owner:GetAmmoCount(self:GetPrimaryAmmoType())
	local max = self:GetMaxClip1()
	if not self:IsEmpty() then
		max = max + (self.Primary.BoltAction and self:GetChamberAmmo() or self.Primary.Chamber)
	end
	if cvar_debug_reload:GetBool() then
		max = 2
	end
	local FinalClip1 = 0

	if game.SinglePlayer() && CLIENT then
		return
	end

	if owner:GetActiveWeapon() ~= self then
		return
	end

	if (cvar_infinite_reserve:GetBool()) then
		FinalClip1 = max
	else
		local delta = max - self:Clip1()
		if reserveAmmo >= delta then
			FinalClip1 = self:Clip1() + delta
			owner:SetAmmo(reserveAmmo - delta, self:GetPrimaryAmmoType())
		else
			FinalClip1 = self:Clip1() + reserveAmmo
			owner:SetAmmo(0, self:GetPrimaryAmmoType())
		end
	end

	self:SetClip1(math.Clamp(FinalClip1, 0, max))
end

function SWEP:SingleLoaded(number)
	local owner = self:GetOwner()
	local reserveAmmo = owner:GetAmmoCount(self:GetPrimaryAmmoType())

	if not number then
		number = 1
	end
	if game.SinglePlayer() && CLIENT then
		return
	end

	if owner:GetActiveWeapon() ~= self then
		return
	end
	local max = self:GetMaxClip1() + self:GetChamberAmmo()
	if (cvar_infinite_reserve:GetBool()) then
		self:SetClip1(math.min(self:Clip1() + number, max))
	elseif reserveAmmo > 0 then
		owner:SetAmmo(reserveAmmo - math.min(number, max - self:Clip1()), self:GetPrimaryAmmoType())
		self:SetClip1(self:Clip1() + math.min(number, max - self:Clip1()))
	end
end

function SWEP:IsReloading()
	local seq = self:GetPlayingSequence()
	if string.find(seq, "Reload") then
		return true
	end
	return false
end

function SWEP:GetMaxClipSize()
	local max = self.Primary.ClipSize or 0
	if self.Primary.BoltAction then
		max = max + self:GetChamberAmmo()
	else
		max = max + self.Primary.Chamber
	end
end


function SWEP:Unload()
	local owner = self:GetOwner()
	if not SERVER then return end
	if owner:IsPlayer() then
		owner:GiveAmmo(self:Clip1(), self:GetPrimaryAmmoType())
		self:SetClip1(0)
	end
end