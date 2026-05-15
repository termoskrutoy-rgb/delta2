local MySkills = {}

-- Получение данных от сервера
net.Receive("UpdateActSkills", function()
    MySkills = net.ReadTable()
end)

-- Создаем единый шрифт для всего меню
surface.CreateFont("ActCardFont", { 
    font = "Determination Mono(RUS BY LYAJK", 
    size = 32, 
    extended = true, 
    weight = 500, 
    antialias = false 
})

local function OpenSkillDetails(id, data, parentFrame)
    local detailPnl = vgui.Create("DPanel", parentFrame)
    detailPnl:SetSize(parentFrame:GetWide() - 8, parentFrame:GetTall() - 8)
    detailPnl:SetPos(4, 4)
    
    -- Исходный текст
    local rawDesc = "* " .. (data.desc or "Нет описания")
    
    -- Таблица замен (Твои теги -> Markup формат)
    local colorTable = {
        ["&o"] = "<color=255,160,0>",   -- Оранжевый
        ["&y"] = "<color=255,255,0>",   -- Желтый
        ["&b"] = "<color=0,0,255>",     -- Синий
        ["&r"] = "<color=255,0,0>",     -- Красный
        ["&g"] = "<color=0,255,0>",     -- Зеленый
        ["&p"] = "<color=128,0,128>",   -- Фиолетовый
        ["&pn"] = "<color=255,192,203>",-- Розовый
        ["&cy"] = "<color=0,255,255>",  -- Голубой (Циановый)
        ["&w"] = "<color=255,255,255>",  -- Белый (Обычный)
        ["&q"] = "<color=255,255,255>",  -- Сброс
    }

    local formattedDesc = rawDesc
    for tag, markupTag in pairs(colorTable) do
        formattedDesc = formattedDesc:gsub(tag, markupTag)
    end
    
    -- Создаем markup-объект. Он сам сделает перенос строк по ширине.
    local parsedText = markup.Parse("<font=ActCardFont>" .. formattedDesc .. "</font>", detailPnl:GetWide() - 90)

    detailPnl.Paint = function(s, w, h)
        surface.SetDrawColor(0, 0, 0)
        surface.DrawRect(0, 0, w, h)
        
        -- Название скилла
        draw.SimpleText(data.name, "ActCardFont", w/2, 40, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        
        -- Линии
        surface.SetDrawColor(255, 255, 255)
        surface.DrawLine(40, 80, w - 40, 80)
        surface.DrawLine(40, h - 110, w - 40, h - 110)

        -- Отрисовка текста с цветами
        parsedText:Draw(45, 110, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        -- Стоимость
        draw.SimpleText(data.cost .. "% Поток", "ActCardFont", 50, h - 150, Color(255, 160, 0))
    end

    -- Кнопка назад
    local backBtn = vgui.Create("DButton", detailPnl)
    backBtn:SetSize(40, 40)
    backBtn:SetPos(15, 15)
    backBtn:SetText("<")
    backBtn:SetFont("ActCardFont")
    backBtn:SetTextColor(Color(255, 255, 255))
    backBtn.Paint = nil
    backBtn.DoClick = function() detailPnl:Remove() end

    -- Кнопка КАСТОВАТЬ (оранжевая рамка, текст оранжевый)
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

-- Команда открытия главного списка
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
        surface.SetDrawColor(255, 255, 255)
        surface.DrawLine(100, 95, w - 100, 95)
    end

    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetSize(50, 50)
    closeBtn:SetPos(frame:GetWide() - 60, 10)
    closeBtn:SetText("X")
    closeBtn:SetFont("ActCardFont")
    closeBtn:SetTextColor(Color(255, 255, 255))
    closeBtn.Paint = function(s, w, h)
        surface.SetDrawColor(255, 255, 255)
        surface.DrawOutlinedRect(4, 4, w-8, h-8, 3)
    end
    closeBtn.DoClick = function() frame:Close() end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    -- ИЗМЕНЕНО: выставил 96, чтобы расстояние от палочки до первой буквы было таким же, 
    -- как межстрочный интервал или отступ от линии заголовка.
    scroll:DockMargin(40, 96, 40, 40)

    if not MySkills or table.Count(MySkills) == 0 then
        local lbl = vgui.Create("DLabel", scroll)
        lbl:SetText("* Пусто...")
        lbl:SetFont("ActCardFont")
        lbl:Dock(TOP)
        lbl:SetContentAlignment(5)
    else
        for id, data in pairs(MySkills) do
            local btn = vgui.Create("DButton", scroll)
            btn:SetTall(50)
            btn:Dock(TOP)
            btn:SetText("")
            
            btn.Paint = function(s, w, h)
                local col = Color(255, 255, 255)
                local prefix = "* "
                if s:IsHovered() then
                    col = Color(255, 255, 0)
                    prefix = "♥ "
                end
                -- Отрисовка текста
                draw.SimpleText(prefix .. data.name, "ActCardFont", 0, h/2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            
            btn.DoClick = function()
                OpenSkillDetails(id, data, frame)
            end
        end
    end
end)