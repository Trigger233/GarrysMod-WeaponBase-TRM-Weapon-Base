SWEP.Tasks = {}

function SWEP:TaskTick()
    local vm = self:GetViewModel()
    if not IsValid(vm) or (game.SinglePlayer() and CLIENT)  then return end


    local task = self.Tasks[self:GetCurrentTask()]


    if (task.Think != nil) then
        task:Think(vm:GetCycle(), self)
    end

    if not task then
        self:TrySetTask("Idle")
        return
    end

end

function SWEP:RegisterTask(task)
    self.Tasks = self.Tasks or {}
    for t, registeredTask in pairs(self.Tasks) do
        if (registeredTask.Name == task.Name) then
            self.Tasks[t] = table.Copy(task)
            return
        end
    end
    local index = #self.Tasks + 1
    self.Tasks[index] = table.Copy(task)
    --print("Task")
end

function SWEP:TrySetTask(taskName , forceSet)
    local Index = 0

    for i , task in ipairs(self.Tasks) do
        if task.Name == taskName then 
            Index = i 
            break
        end
    end

    local task = self.Tasks[Index]
    if not task then return end

    local currentTask = self.Tasks[self:GetCurrentTask()]

    -- if currentTask.Priority and task.Priority then
    --     if currentTask.Priority > task.Priority then
    --         return
    --     end
    -- end

    if task.CanBeSet and task:CanBeSet(self) == false and not forceSet then
        return false
    end



    --print(Index)
    self:SetCurrentTask(Index)

    if task.OnSet then
        self.m_NextTaskThink = 0
        task:OnSet(self)
    end
end

function SWEP:GetTaskByName(name)
    if not self.m_TaskNameIndexCache then
        self.m_TaskNameIndexCache = {}
    end
    if self.m_TaskNameIndexCache[name] then
        return self.m_TaskNameIndexCache[name]
    end

    for Index, task in pairs(self.Tasks) do
        if (task.Name == name) then
            self.m_TaskNameIndexCache[name] = Index
            return Index
        end
    end
    return nil
end

function SWEP:GetCurrentTaskName()
    local task = self.Tasks[self:GetCurrentTask()]
    --print(task.Name)
    return task and task.Name or nil
end

function SWEP:IsCurrentTask(name)
    return self:GetCurrentTaskName() == name
end

concommand.Add("trmbase_debug_task", function(ply, cmd, args)
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and util.IsTRMBase(wep) then
        wep:TrySetTask(args[1] or "Idle")
    end
end)
