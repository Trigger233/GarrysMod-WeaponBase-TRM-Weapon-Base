AddCSLuaFile()
module("trm_input", package.seeall )
trm_input = trm_input or {}
local REGISTER_KEY = {}
    

trm_input.State = {}

function trm_input.RegisterBind(act,key,type,condition)
    local tab = {}
    tab.key = key 
    tab.type = type
    tab.condition = condition
    REGISTER_KEY[act] = tab
    tab = nil
    CreateClientConVar("trmbase_cl_bind_"..act,0,true,true,"")
end

function trm_input.Bind(ply,bind,pressed)
    for act , tab in pairs(REGISTER_KEY) do
       if input.WasKeyPressed(tab.key) and tab.key > 0 then
            RunConsoleCommand(act)
       end
    end
end
