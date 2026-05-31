INJECTOR.Name = "injector_base"
INJECTOR.Description = "Just Base"
INJECTOR.Filter = true 
INJECTOR.SWEP = nil
INJECTOR.Type = "" -- "Name" , "Category"
INJECTOR.Key = ""
INJECTOR.Write = {}
local function FindAttSlot(injector,type, weapon)
    if type == "Name" then
        for slot, data in pairs(weapon.Attachments) do
            if data.Name and data.Name == injector.Key then
                return slot
            end
        end
    elseif type == "Category" then
        for slot , data in pairs(weapon.Attachments) do
            if data.Category and data.Category == injector.Key then
                return slot
            end
        end
    end
    return false
end

function INJECTOR:DoInjector(swep,class)
    if self.Filter and not self.SWEP == class then
        return
    end   
    
    
end


function INJECTOR:InsertAttachmentCategory(swep,class)
    local slot = FindAttSlot(self.Type, swep)
    if not slot then return end
    for _ ,str in pairs(self.Write) do
        table.insert(swep.Attachments[slot], str)
    end

end
