util.AddNetworkString("UpdateActSkills")
util.AddNetworkString("UseActSkill")
util.AddNetworkString("ActSkill_ChatMsg")

net.Receive("UseActSkill", function(len, ply)
    if not IsValid(ply) then return end
    
    local id = net.ReadString()

    -- Вытаскиваем данные скилла. Если таблица в памяти сбросилась при сохранении файла,
    -- берем значения напрямую из ConVar игрока, чтобы каст не ломался
    local skillName = "Скилл"
    local skillCost = 0

    if ply.ActSkillsList and ply.ActSkillsList[id] then
        skillName = ply.ActSkillsList[id].name or "Скилл"
        skillCost = tonumber(ply.ActSkillsList[id].cost) or 0
    else
        skillName = ply:GetInfo("act_skill_name") or "Скилл"
        skillCost = tonumber(ply:GetInfo("act_skill_cost")) or 0
    end

    -------------------------------------------------------------------------
    -- СТРОГО ПО РЕПОЗИТОРИЮ DELTA2 (act_character.lua)
    -------------------------------------------------------------------------
    -- В твоем туле имя пишется в NWString "act_char_name"
    local characterName = ply:GetNWString("act_char_name", "")
    if characterName == "" or characterName == "name" then
        characterName = ply:Nick() -- Если тул персонажа еще не применяли
    end

    -- В твоем туле цвет пишется в NWVector "act_char_color"
    local charColor = Color(255, 255, 255)
    local colVec = ply:GetNWVector("act_char_color", Vector(-1, -1, -1))
    
    if colVec.x >= 0 then
        charColor = Color(colVec.x, colVec.y, colVec.z)
    else
        -- Если вектор не найден, берем цвет команды фракции
        charColor = team.GetColor(ply:Team()) or Color(255, 255, 255)
    end

    -------------------------------------------------------------------------
    -- ОТПРАВКА В ЧАТ В РАДИУСЕ 600
    -------------------------------------------------------------------------
    local radius = 600
    local pos = ply:GetPos()
    
    for _, v in ipairs(player.GetAll()) do
        if IsValid(v) and v:GetPos():Distance(pos) <= radius then
            net.Start("ActSkill_ChatMsg")
                net.WriteEntity(ply)
                net.WriteString(characterName) -- Отправляем act_char_name
                net.WriteString(skillName)
                net.WriteInt(math.Round(skillCost), 16)
                net.WriteColor(charColor)      -- Отправляем act_char_color
            net.Send(v)
        end
    end
end)

net.Receive("UpdateActSkills", function(len, ply)
    -- Оставляем открытым для синхронизации таблиц
end)