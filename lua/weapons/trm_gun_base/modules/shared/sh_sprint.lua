function SWEP:CanSprint()
    local vm = self:GetViewModel(self)
    if not vm then return end
    local owner = self:GetOwner()
    local seq = self:GetPlayingSequence() 
    local cycle = vm:GetCycle()
    local task = self:GetCurrentTask()
    
    -- if trm_weapon_base_util.IsDucking(owner) then
    --     return false
    -- end

    if  string.find(seq,"Reload") or string.find(task,"Reload")  or string.find(task,"Deploy") then
        return false
    end

    if string.find( seq,"Sprint") or string.find(seq,"Inspect")  or string.find(seq,"Melee") or string.find(seq,"Draw") or string.find(seq,"Holster") then return false end 

    -- if cycle < self.Animations[seq].Length then return false end
    return true
end 

function SWEP:Task_SprintIn(cycle)
    self:SetNextAnimationTime(0)
    if self:IsEmpty() and self.Animations.SprintIn_Empty then
        self:PlayAnimation("SprintIn_Empty" , true )
    elseif self.Animations.SprintIn then
        self:PlayAnimation("SprintIn" ,true )
    end
    
    self:SetCurrentTask("Sprint")
end

function SWEP:Task_Sprint(cycle) 
    
    if self.Animations.Sprint_Empty and self:IsEmpty() then
        self:PlayAnimation("Sprint_Empty",true)
    elseif self.Animations.Sprint then
        self:PlayAnimation("Sprint",true)
    elseif self:IsEmpty() and self.Animations.Idle_Empty then 
        self:PlayAnimation("Idle_Empty" ,true)
    else
        self:PlayAnimation("Idle" ,true)
    end
    
    if self:GetOwner():KeyDown(IN_SPEED) == false then
        self:SetCurrentTask("SprintOut")
    end
    

end



function SWEP:Task_SprintOut(cycle)
    self:SetNextAnimationTime(0)
    if self:IsEmpty() and self.Animations.SprintOut_Empty then
        self:PlayAnimation("SprintOut_Empty" ,true)
    elseif self.Animations.SprintOut then
        self:PlayAnimation("SprintOut",true)
    else
        self:Task_Idle()
        self:SetNextFireTime(0.25)
    end
    self:SetCurrentTask("Finished")
    
end

function SWEP:Sprint()
    local currentTask = self:GetCurrentTask()
    local speed =   self:GetOwner():GetVelocity():Length2D()
    local runSpeed = self:GetOwner():GetRunSpeed()
    local radio = speed / runSpeed
    local sequence = self:GetPlayingSequence()
    -- 已经在冲刺相关状态中，不要干扰
    if currentTask == "SprintIn" or currentTask == "Sprint" or currentTask == "SprintOut"  then
        return
    end
    
    if self:GetOwner():KeyDown(IN_SPEED) and self:CanSprint() and radio > 0.8  then 
        self:SetCurrentTask("SprintIn")
    end
end
