util.AddNetworkString("UpdateActSkills")
util.AddNetworkString("UseActSkill")

-- Хук отслеживания команды в чате
hook.Add("PlayerSay", "UndertaleSkillsChatCommand", function(ply, text, teamOnly)
    if string.lower(string.trim(text)) == "/skills" then
        ply:ConCommand("act_skills_menu")
        return "" -- Полностью стирает команду из чата, чтоб не спамить
    end
end)

-- Обработка клика по скиллу из меню
net.Receive("UseActSkill", function(len, ply)
    local skillID = net.ReadString()
    ply.ActSkillsList = ply.ActSkillsList or {}
    
    local skill = ply.ActSkillsList[skillID]
    if skill then
        ply:ChatPrint("[ACT] Вы использовали: " .. skill.name .. " (Потрачено " .. skill.cost .. " TP)")
        
        -- Пример базовой логики для "heal"
        if skillID == "heal" then
            ply:SetHealth(math.min(ply:GetMaxHealth(), ply:Health() + 30))
            ply:EmitSound("items/medshot4.wav", 60, 100) -- Звук лечения
        end
    else
        ply:ChatPrint("[ACT] Навык не найден или не доступен.")
    end
end)