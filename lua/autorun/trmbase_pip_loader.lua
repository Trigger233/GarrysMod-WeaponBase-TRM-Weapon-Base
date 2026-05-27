if SERVER then
    AddCSLuaFile()
end
TRM_ScopePiP = TRM_ScopePiP or {}
local files = {
    "trmbase/trmbase_scope/client/cl_pip_config.lua",
    "trmbase/trmbase_scope/client/cl_pip_core.lua",
    "trmbase/trmbase_scope/client/cl_pip_scope.lua",
    "trmbase/trmbase_scope/client/cl_pip_debug.lua",
    "trmbase/trmbase_scope/client/cl_pip_cleanup.lua"
}

for _, path in ipairs(files) do
    AddCSLuaFile(path)
    include(path)
end
 