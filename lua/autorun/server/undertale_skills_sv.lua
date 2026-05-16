util.AddNetworkString("UpdateActSkills")
util.AddNetworkString("UseActSkill")
util.AddNetworkString("ActSkill_ChatMsg")

net.Receive("UseActSkill", function(len, ply)
    if not IsValid(ply) then return end
    
    local id = net.ReadString()
    local bypassedRhythm = net.ReadBool() -- Принимаем флаг моментального каста от клиента

    local skillName = "Скилл"
    local skillCost = 0

    if ply.ActSkillsList and ply.ActSkillsList[id] then
        skillName = ply.ActSkillsList[id].name or "Скилл"
        skillCost = tonumber(ply.ActSkillsList[id].cost) or 0
    else
        skillName = ply:GetInfo("act_skill_name") or "Скилл"
        skillCost = tonumber(ply:GetInfo("act_skill_cost")) or 0
    end

    -- Синхронизация с act_character.lua из твоего репозитория delta2
    local characterName = ply:GetNWString("act_char_name", "")
    if characterName == "" or characterName == "name" then characterName = ply:Nick() end

    local charColor = Color(255, 255, 255)
    local colVec = ply:GetNWVector("act_char_color", Vector(-1, -1, -1))
    if colVec.x >= 0 then charColor = Color(colVec.x, colVec.y, colVec.z) else charColor = team.GetColor(ply:Team()) or Color(255, 255, 255) end

    -------------------------------------------------------------------------
    -- СТЕК ЭФФЕКТОВ ТВОЕГО СЕРВЕРА (sv_rhythm.lua)
    -------------------------------------------------------------------------
    -- Если у тебя в sv_rhythm.lua прописана логика вычета поинтов "Потока", 
    -- мы триггерим её глобальную функцию, передавая игрока и стоимость скилла
    if RhythmSystemServer and RhythmSystemServer.DeductFlow then
        RhythmSystemServer.DeductFlow(ply, skillCost)
    end

    -- Рассылка сообщений в чат в радиусе 600
    local radius = 600
    local pos = ply:GetPos()
    
    for _, v in ipairs(player.GetAll()) do
        if IsValid(v) and v:GetPos():Distance(pos) <= radius then
            net.Start("ActSkill_ChatMsg")
                net.WriteEntity(ply)
                net.WriteString(characterName)
                net.WriteString(skillName)
                net.WriteInt(math.Round(skillCost), 16)
                net.WriteColor(charColor)
            net.Send(v)
        end
    end
end)

net.Receive("UpdateActSkills", function(len, ply) end)