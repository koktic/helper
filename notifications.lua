--[[
    Оригинальная библиотека уведомлений для moonloader
    Автор: Andergr0ynd
    Версия: 2.0
]]

local imgui = require 'mimgui'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8
local faicons = require("fAwesome6")
local inicfg = require 'inicfg'

-- Список уведомлений
local notifications_list = {}

-- Загружаем сохраненные позиции
local saved_positions = inicfg.load({
    positions = {}
}, 'notification_positions.ini')

-- Очищаем старые позиции при запуске (чтобы избежать проблем с индексами)
if next(saved_positions.positions) then
    saved_positions.positions = {}
    inicfg.save(saved_positions, 'notification_positions.ini')
end

-- Настройки по умолчанию
local settings = {
    max_notifications = 5,
    default_duration = 4000,
    fade_in_time = 300,
    fade_out_time = 300,
    position = "bottom_left",
    movable = false,  -- По умолчанию отключено перетаскивание
    font_scale = 1.1  -- Масштаб текста (1.0 = стандартный, 1.2 = крупнее, 0.8 = мельче)
}

-- Цвета для разных типов
local colors = {
    success = {r = 0.2, g = 0.8, b = 0.2, a = 0.9},
    error = {r = 0.8, g = 0.2, b = 0.2, a = 0.9},
    warning = {r = 0.9, g = 0.6, b = 0.2, a = 0.9},
    info = {r = 0.10, g = 0.05, b = 0.20, a = 0.70},
    debug = {r = 0.5, g = 0.5, b = 0.5, a = 0.9}
}

-- Иконки для разных типов (FontAwesome 6)
local icons = {
    success = "check",
    error = "xmark", 
    warning = "exclamation",
    info = "info",
    debug = "gear"
}

-- Переменные для перетаскивания
local dragging_notification = nil
local drag_offset = {x = 0, y = 0}
local last_save_time = 0
local save_delay = 0.5 -- Задержка между сохранениями в секундах

-- Функция для сохранения позиций
local function save_positions()
    local positions_to_save = {}
    for i, notification in ipairs(notifications_list) do
        if notification.custom_x and notification.custom_y then
            positions_to_save[tostring(i)] = {
                x = notification.custom_x,
                y = notification.custom_y
            }
        end
    end
    saved_positions.positions = positions_to_save
    inicfg.save(saved_positions, 'notification_positions.ini')
end

-- Функция для создания нового уведомления
local function create_notification(text, type, duration, custom_colors)
    local notification = {
        id = os.clock() + math.random(),
        text = text,
        type = type or "info",
        duration = duration or settings.default_duration,
        start_time = os.clock(),
        alpha = 0,
        colors = custom_colors or colors[type or "info"],
        icon = icons[type or "info"],
        custom_x = 800,  -- базовая позиция; в отрисовке добавляется смещение по индексу
        custom_y = 950,
        is_dragging = false
    }
    
    table.insert(notifications_list, notification)
    
    -- Загружаем сохраненную позицию только если пользователь ранее перетаскивал уведомление с этим индексом
    local current_index = #notifications_list
    local saved_pos = saved_positions.positions[tostring(current_index)]
    if saved_pos then
        notification.custom_x = saved_pos.x
        notification.custom_y = saved_pos.y
    end
    
    -- Ограничить количество уведомлений
    if #notifications_list > settings.max_notifications then
        table.remove(notifications_list, 1)
    end
    
    -- Убираем вызов SetMouseCursor отсюда - он должен быть только в ImGui контексте
    
    return notification
end

-- Функция для анимации прозрачности
local function animate_alpha(notification, current_time)
    local elapsed = current_time - notification.start_time
    local fade_in_duration = settings.fade_in_time / 1000
    local fade_out_duration = settings.fade_out_time / 1000
    local total_duration = notification.duration / 1000
    
    -- Появление
    if elapsed < fade_in_duration then
        notification.alpha = elapsed / fade_in_duration
    -- Исчезновение
    elseif elapsed > total_duration - fade_out_duration then
        notification.alpha = (total_duration - elapsed) / fade_out_duration
    -- Полная видимость
    else
        notification.alpha = 1.0
    end
    
    return notification.alpha
end

-- Функция для отрисовки уведомления
local function render_notification(notification, index, screen_w, screen_h)
    local x, y = 0, 0
    
    -- Кастомная позиция: базовая точка + смещение по индексу, чтобы несколько уведомлений не налезали
    local offset_per_item = 80
    if notification.custom_x and notification.custom_y then
        x = notification.custom_x
        y = notification.custom_y - (index - 1) * offset_per_item  -- стопка вверх от базы
    else
        -- Позиционирование по умолчанию
        if settings.position == "top_right" then
            x = screen_w - 320
            y = 20 + (index - 1) * 80
        elseif settings.position == "top_left" then
            x = 20
            y = 20 + (index - 1) * 80
        elseif settings.position == "bottom_right" then
            x = screen_w - 320
            y = screen_h - 100 - (index - 1) * 80
        elseif settings.position == "bottom_left" then
            x = 20
            y = screen_h - 100 - (index - 1) * 80
        elseif settings.position == "center" then
            x = screen_w / 2 - 160
            y = screen_h / 2 - 30 + (index - 1) * 80
        end
    end
    
    -- Окно уведомления
    -- === ДИНАМИЧЕСКАЯ ВЫСОТА ===
    local text_width = 240 -- ширина области для текста (300 - 45 - 15)
    local text_size = imgui.CalcTextSize(notification.text, nil, true, text_width)
    local text_height = text_size.y
    local window_height = math.max(60, text_height + 20 + 20 + 4 + 6) -- отступы сверху/снизу + прогресс-бар + запас
    imgui.SetNextWindowPos(imgui.ImVec2(x, y), imgui.Cond.Always, imgui.ImVec2(0, 0))
    imgui.SetNextWindowSize(imgui.ImVec2(300, window_height), imgui.Cond.Always)
    
    -- Стили
    imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, notification.alpha)
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 8)
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 0)
    
    -- Цвета
    local bg_color = imgui.ImVec4(
        notification.colors.r, 
        notification.colors.g, 
        notification.colors.b, 
        notification.colors.a
    )
    imgui.PushStyleColor(imgui.Col.WindowBg, bg_color)
    
    -- Флаги окна (неинтерактивные уведомления)
    local window_flags = imgui.WindowFlags.NoTitleBar + 
                        imgui.WindowFlags.NoResize + 
                        imgui.WindowFlags.NoScrollbar +
                        imgui.WindowFlags.NoInputs +
                        imgui.WindowFlags.NoFocusOnAppearing +
                        imgui.WindowFlags.NoBringToFrontOnFocus +
                        imgui.WindowFlags.NoMove
    
    -- Если включено перетаскивание, убираем флаги NoInputs и NoMove
    if settings.movable then
        window_flags = window_flags - imgui.WindowFlags.NoInputs
        window_flags = window_flags - imgui.WindowFlags.NoMove
        window_flags = window_flags + imgui.WindowFlags.NoCollapse
    end
    
    -- Окно
    imgui.Begin("Notification" .. notification.id, nil, window_flags)
    
    -- Убираем вызов SetMouseCursor отсюда - он может вызывать проблемы
    
    -- Обработка перетаскивания
    if settings.movable then
        if imgui.IsWindowHovered() and imgui.IsMouseDown(0) then
            if not notification.is_dragging then
                notification.is_dragging = true
                local mouse_pos = imgui.GetMousePos()
                local window_pos = imgui.GetWindowPos()
                drag_offset.x = mouse_pos.x - window_pos.x
                drag_offset.y = mouse_pos.y - window_pos.y
            end
            
            if notification.is_dragging then
                local mouse_pos = imgui.GetMousePos()
                local new_x = mouse_pos.x - drag_offset.x
                local new_y = mouse_pos.y - drag_offset.y
                
                -- Ограничиваем позицию экраном
                if new_x < 0 then new_x = 0 end
                if new_y < 0 then new_y = 0 end
                if new_x > screen_w - 300 then new_x = screen_w - 300 end
                if new_y > screen_h - 60 then new_y = screen_h - 60 end
                
                -- Обновляем позицию только если она изменилась
                if notification.custom_x ~= new_x or notification.custom_y ~= new_y then
                    notification.custom_x = new_x
                    notification.custom_y = new_y
                    -- Сохраняем позиции с ограничением частоты
                    local current_time = os.clock()
                    if current_time - last_save_time > save_delay then
                        save_positions()
                        last_save_time = current_time
                    end
                end
            end
        else
            if notification.is_dragging then
                notification.is_dragging = false
                -- Сохраняем финальную позицию
                save_positions()
                last_save_time = os.clock()
            end
        end
    end
    
    -- Иконка (FontAwesome)
    imgui.SetCursorPos(imgui.ImVec2(15, 20))
    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 1, 1, notification.alpha))
    imgui.Text(faicons(notification.icon))
    imgui.PopStyleColor()
    
    -- Текст (размер через font_scale в settings)
    imgui.SetCursorPos(imgui.ImVec2(45, 20))
    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 1, 1, notification.alpha))
    imgui.SetWindowFontScale(settings.font_scale or 1.0)
    imgui.PushTextWrapPos(285) -- ограничиваем ширину текста
    imgui.TextWrapped(notification.text)
    imgui.PopTextWrapPos()
    imgui.SetWindowFontScale(1.0) -- сброс масштаба
    imgui.PopStyleColor()
    
    -- Прогресс-бар
    local elapsed = os.clock() - notification.start_time
    local progress = 1 - (elapsed / (notification.duration / 1000))
    if progress < 0 then progress = 0 end
    -- Прогресс-бар всегда внизу окна
    imgui.SetCursorPos(imgui.ImVec2(15, window_height - 14))
    imgui.PushStyleColor(imgui.Col.PlotHistogram, imgui.ImVec4(1, 1, 1, notification.alpha * 0.7))
    imgui.ProgressBar(progress, imgui.ImVec2(270, 4))
    imgui.PopStyleColor()
    
    imgui.End()
    
    -- Восстановление стилей
    imgui.PopStyleColor()
    imgui.PopStyleVar(3)
end

-- Основные функции библиотеки
local notifications = {
    -- Показать уведомление
    show = function(text, type, duration, custom_colors)
        return create_notification(text, type, duration, custom_colors)
    end,
    
    -- Успех
    success = function(text, duration, custom_colors)
        return create_notification(text, "success", duration, custom_colors)
    end,
    
    -- Ошибка
    error = function(text, duration, custom_colors)
        return create_notification(text, "error", duration, custom_colors)
    end,
    
    -- Предупреждение
    warning = function(text, duration, custom_colors)
        return create_notification(text, "warning", duration, custom_colors)
    end,
    
    -- Информация
    info = function(text, duration, custom_colors)
        return create_notification(text, "info", duration, custom_colors)
    end,
    
    -- Отладка
    debug = function(text, duration, custom_colors)
        return create_notification(text, "debug", duration, custom_colors)
    end,
    
    -- Очистить все уведомления
    clear = function()
        notifications_list = {}
    end,
    
    -- Получить количество активных уведомлений
    count = function()
        return #notifications_list
    end,
    
    -- Сбросить все сохраненные позиции
    reset_positions = function()
        saved_positions.positions = {}
        inicfg.save(saved_positions, 'notification_positions.ini')
        -- Сбрасываем позиции у текущих уведомлений
        for _, notification in ipairs(notifications_list) do
            notification.custom_x = nil
            notification.custom_y = nil
        end
        -- Перезагружаем сохраненные позиции
        saved_positions = inicfg.load({
            positions = {}
        }, 'notification_positions.ini')
    end,
    
    -- Сохранить текущие позиции
    save_positions = function()
        save_positions()
    end,
    
    -- Настроить библиотеку
    configure = function(new_settings)
        for key, value in pairs(new_settings) do
            settings[key] = value
        end
        
        -- Если изменили настройку movable, перезагружаем позиции
        if new_settings.movable ~= nil then
            -- Перезагружаем сохраненные позиции
            saved_positions = inicfg.load({
                positions = {}
            }, 'notification_positions.ini')
        end
    end,
    
    -- Быстрое переключение интерактивности
    set_interactive = function(interactive)
        settings.movable = interactive
    end,
    
    -- Получить текущее состояние интерактивности
    is_interactive = function()
        return settings.movable
    end
}

-- Инициализация FontAwesome шрифта
imgui.OnInitialize(function()
    local imgui_io = imgui.GetIO()
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
    local iconRanges = imgui.new.ImWchar[3](faicons.min_range, faicons.max_range, 0)
    imgui_io.Fonts:AddFontFromMemoryCompressedBase85TTF(faicons.get_font_data_base85('solid'), 16, config, iconRanges)
end)

-- Обработчик ImGui для отрисовки
imgui.OnFrame(
    function() return #notifications_list > 0 end,
    function()
        local screen_w, screen_h = getScreenResolution()
        local current_time = os.clock()
        
        -- Скрываем курсор когда есть уведомления
        if #notifications_list > 0 then
            imgui.SetMouseCursor(imgui.MouseCursor.None)
        end
        
        for i = #notifications_list, 1, -1 do
            local notification = notifications_list[i]
            
            -- Обновить прозрачность
            animate_alpha(notification, current_time)
            
            -- Удалить устаревшие уведомления
            local elapsed = current_time - notification.start_time
            if elapsed > notification.duration / 1000 then
                table.remove(notifications_list, i)
            else
                -- Отрисовать уведомление
                render_notification(notification, i, screen_w, screen_h)
            end
        end
    end
).HideCursor = true

return notifications 