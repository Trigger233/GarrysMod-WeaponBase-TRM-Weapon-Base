local utilf = util.Effect
require("trm_utils") 
function SWEP:DoShell()
    if not CLIENT then
        self:CallOnClient("DoShell")
    return end


end

