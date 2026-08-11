INJECTOR.Name = "injector_base"
INJECTOR.SWEP = nil

INJECTOR.Attachments = {}
INJECTOR.AttachmentSlot = nil
INJECTOR.AttachmentType = nil

INJECTOR.Slot = nil
INJECTOR.SlotCategory = {}

INJECTOR.Anim = {}


local function findAttInjectSlot(injector, weapon)
    if ! injector.Attachments then return end
    --find by name
    if injector.AttachmentType and injector.AttachmentType == "Name" and injector.AttachmentSlot then
        for slot, att in pairs(weapon.Attachments) do
            if att and att.Name and att.Name == injector.AttachmentSlot then
                return slot
            end
        end
    end

    --find by category
    if injector.AttachmentType and injector.AttachmentType == "Category" and injector.AttachmentSlot then
        for slot, att in pairs(weapon.Attachments) do
            if att and att.Category then
                if table.HasValue(att.Category, injector.AttachmentSlot) then
                    return slot
                end
            end
        end
    end

    return false
end
function INJECTOR:Inject(weapon)
    if self.Attachments then
        self:AttachmentsInject(weapon)
    end

    if self.Slot then
        self:SlotInject(weapon)
    end

    if self.Anim then
        self:Animation(weapon)
    end

    self:Stats(weapon)
end

function INJECTOR:AttachmentsInject(weapon)
    local slot = findAttInjectSlot(self, weapon)
    if not slot then return end
    weapon.Attachments[slot] = weapon.Attachments[slot] or {
        Name = self.Name or self.ClassName,
    }

    weapon.Attachments[slot].Category = weapon.Attachments[slot].Category or {}

    for _, className in pairs(self.Attachments) do
        table.insert(weapon.Attachments[slot].Category, className)
    end
end

function INJECTOR:SlotInject(weapon)
    local _table = {
        Name = self.Slot,
        Category = self.SlotCategory,
    }

    table.insert(weapon.Attachments, _table)
end

function INJECTOR:Stats(weapon)
end

function INJECTOR:Animation(weapon)
    for newAnimName, animData in pairs(self.Anim or {}) do
        -- 如果有 base，先复制 base 的数据
        if animData.base and weapon.Animations[animData.base] then
            weapon.Animations[newAnimName] = table.Copy(weapon.Animations[animData.base])
        else
            weapon.Animations[newAnimName] = {}
        end

        if not weapon.Animations[newAnimName] then
            weapon.Animations[newAnimName] = {}
        end
        --Init
        -- 合并 events
        if animData.events then
            weapon.Animations[newAnimName].events = weapon.Animations[newAnimName].events or {}
            for _, event in ipairs(animData.events) do
                table.insert(weapon.Animations[newAnimName].events, event)
            end
        end

        -- 覆盖其他属性
        if animData.sequence then
            weapon.Animations[newAnimName].sequence = animData.sequence
        end
        if animData.Speed then
            weapon.Animations[newAnimName].Speed = animData.Speed
        end
        if animData.Length then
            weapon.Animations[newAnimName].Length = animData.Length
        end
        --PrintTable(weapon.Animations[newAnimName])
    end
end

-- INJECTOR.Anim = {
-- ["new_anim_class"] = {
--      base = "which_anim_u_base_on" ,
--
--      events = {
--      --White all event u want to insert in this anim
--      {time = 0.5 , callback = function(weapon) end},
--      {time = 0.1 , callback = function(weapon) end},
--      },
-- }
-- }
