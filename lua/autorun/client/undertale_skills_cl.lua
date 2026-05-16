local MySkills = {}

net.Receive("UpdateActSkills", function()
    MySkills = net.ReadTable()
end)

surface.CreateFont("ActCardFont", { 
    font = "Determination Mono(RUS BY LYAJK", 
    size = 32, 
    extended = true, 
    weight = 500, 
    antialias = false 
})

local function ParseUTText(text, width)
    local colorTable = {
        ["&o"] = "<color=255,160,0>", ["&y"] = "<color=255,255,0>", 
        ["&b"] = "<color=0,0,255>", ["&r"] = "<color=255,0,0>", 
        ["&g"] = "<color=0,255,0>", ["&p"] = "<color=128,0,128>", 
        ["&pn"] = "<color=255,192,203>", ["&cy"] = "<color=0,255,255>", 
        ["&w"] = "<color=255,255,255>", ["&q"] = "<color=255,255,255>", 
    }
    local formatted = text
    for tag, markupTag in pairs(colorTable) do formatted = formatted:gsub(tag, markupTag) end
    return markup.Parse("<font=ActCardFont>" .. formatted .. "</font>", width)
end

local function OpenSkillDetails(id, data, parentFrame)
    local detailPnl = vgui.Create("DPanel", parentFrame)
    detailPnl:SetSize(parentFrame:GetWide() - 8, parentFrame:GetTall() - 8)
    detailPnl:SetPos(4, 4)
    
    local parsedDesc = ParseUTText("* " .. (data.desc or ""), detailPnl:GetWide() - 90)

    detailPnl.Paint = function(s, w, h)
        surface.SetDrawColor(0, 0, 0)
        surface.DrawRect(0, 0, w, h)
        draw.SimpleText(data.name, "ActCardFont", w/2, 40, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        surface.SetDrawColor(255, 255, 255)
        surface.DrawLine(40, 80, w - 40, 80)
        surface.DrawLine(40, h - 110, w - 40, h - 110)
        parsedDesc:Draw(45, 110, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(data.cost .. "% Поток", "ActCardFont", 50, h - 150, Color(255, 160, 0))
    end

    local backBtn = vgui.Create("DButton", detailPnl)
    backBtn:SetSize(40, 40)
    backBtn:SetPos(15, 15)
    backBtn:SetText("<")
    backBtn:SetFont("ActCardFont")
    backBtn:SetTextColor(Color(255, 255, 255))
    backBtn.Paint = nil
    backBtn.DoClick = function() detailPnl:Remove() end

    local castBtn = vgui.Create("DButton", detailPnl)
    castBtn:SetSize(300, 65)
    castBtn:SetPos(detailPnl:GetWide()/2 - 150, detailPnl:GetTall() - 95)
    castBtn:SetText("КАСТОВАТЬ")
    castBtn:SetFont("ActCardFont")
    
    castBtn.Paint = function(s, w, h)
        local orangeCol = Color(255, 160, 0)
        if s:IsHovered() then
            draw.SimpleText("♥", "ActCardFont", 15, h/2 - 2, Color(255, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        surface.SetDrawColor(orangeCol)
        surface.DrawOutlinedRect(0, 0, w, h, 2) 
        s:SetTextColor(orangeCol)
    end
    
    castBtn.DoClick = function()
        surface.PlaySound("ui/buttonclick.wav")
        net.Start("UseActSkill")
            net.WriteString(id)
        net.SendToServer()
        parentFrame:Close()
    end
end

concommand.Add("act_skills_menu", function()
    if IsValid(UndertaleMenuFrame) then UndertaleMenuFrame:Close() end
    local frame = vgui.Create("DFrame")
    UndertaleMenuFrame = frame
    frame:SetSize(550, 600)
    frame:Center()
    frame:SetTitle("")
    frame:MakePopup()
    frame:ShowCloseButton(false)

    frame.Paint = function(s, w, h)
        surface.SetDrawColor(255, 255, 255)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(0, 0, 0)
        surface.DrawRect(4, 4, w - 8, h - 8)
        draw.SimpleText("Скиллы", "ActCardFont", w/2, 50, Color(255, 255, 255), TEXT_ALIGN_CENTER)
    end

    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetSize(40, 40)
    closeBtn:SetPos(frame:GetWide() - 50, 10)
    closeBtn:SetText("X")
    closeBtn:SetFont("ActCardFont")
    closeBtn:SetTextColor(Color(255, 255, 255))
    closeBtn.Paint = nil
    closeBtn.DoClick = function() frame:Close() end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(40, 80, 40, 40)

    if not MySkills or table.Count(MySkills) == 0 then
        local btn = vgui.Create("DButton", scroll)
        btn:SetTall(50)
        btn:Dock(TOP)
        btn:SetText("")
        local name = GetConVar("act_skill_name"):GetString() or "Heal Prayer"
        btn.Paint = function(s, w, h)
            local col = s:IsHovered() and Color(255, 255, 0) or Color(255, 255, 255)
            draw.SimpleText("* " .. name, "ActCardFont", 0, h/2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        btn.DoClick = function() 
            OpenSkillDetails("heal", {
                name = name, 
                cost = GetConVar("act_skill_cost"):GetString(), 
                desc = GetConVar("act_skill_desc"):GetString()
            }, frame) 
        end
    else
        for id, data in pairs(MySkills) do
            local btn = vgui.Create("DButton", scroll)
            btn:SetTall(50)
            btn:Dock(TOP)
            btn:SetText("")
            btn.Paint = function(s, w, h)
                local col = s:IsHovered() and Color(255, 255, 0) or Color(255, 255, 255)
                draw.SimpleText("* " .. data.name, "ActCardFont", 0, h/2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            btn.DoClick = function() OpenSkillDetails(id, data, frame) end
        end
    end
end)

-- Прием сообщения в чат (Красит Имя Персонажа и Скилл в цвет act_char_color)
net.Receive("ActSkill_ChatMsg", function()
    local caster = net.ReadEntity()
    local charName = net.ReadString() -- Получаем act_char_name из сети
    local skillName = net.ReadString()
    local cost = net.ReadInt(16)
    local charColor = net.ReadColor() -- Получаем цвет из act_char_color
    
    local orange = Color(255, 160, 0)
    local white = Color(255, 255, 255)

    chat.AddText(
        charColor, charName, 
        white, " кастует ", 
        charColor, skillName, 
        white, " за ", 
        orange, tostring(cost) .. "% потока!"
    )
end)