-- Инициализация системы ACT
if SERVER then
    AddCSLuaFile("act_system/cl_init.lua")
    include("act_system/sv_init.lua")
else
    include("act_system/cl_init.lua")
end