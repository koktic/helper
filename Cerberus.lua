script_version("v1.00")
script_name("Mini Helper")
local name = "[Mini Helper] "
local color1 = "{B43DD9}" 
local color2 = "{FFFFFF}"
local tag = color1 .. name .. color2

local imgui = require 'mimgui'
local fa = require('fAwesome5')
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local new = imgui.new
local effil = require 'effil'
local ffi = require 'ffi'
local ev = require 'samp.events'
local new, str = imgui.new, ffi.string
local socket_url = require'socket.url' -- Для кодирования URL
local vkeys = require 'vkeys'


if not doesFileExist(getWorkingDirectory().."/MiniHelper/fAwesome5.ttf") then
	downloadUrlToFile("https://dl.dropboxusercontent.com/s/zgfq5juurf7yvru/fAwesome5.ttf", getWorkingDirectory().."/MiniHelper/fonts/fAwesome5.ttf")
end 	

local tab = 1
local WinState = new.bool()

--ОБНОВА
local enable_autoupdate = true
local autoupdate_loaded = false
local Update = nil
if enable_autoupdate then
    local updater_loaded, Updater = pcall(loadstring, u8:decode[[return {check=function (a,b,c) local d=require('moonloader').download_status;local e=os.tmpname()local f=os.clock()if doesFileExist(e)then os.remove(e)end;downloadUrlToFile(a,e,function(g,h,i,j)if h==d.STATUSEX_ENDDOWNLOAD then if doesFileExist(e)then local k=io.open(e,'r')if k then local l=decodeJson(k:read('a'))updatelink=l.updateurl;updateversion=l.latest;k:close()os.remove(e)if updateversion~=thisScript().version then lua_thread.create(function(b)local d=require('moonloader').download_status;local m=-1;sampAddChatMessage(b..'Обнаружено обновление. Пытаюсь обновиться c '..thisScript().version..' на '..updateversion,m)wait(250)downloadUrlToFile(updatelink,thisScript().path,function(n,o,p,q)if o==d.STATUS_DOWNLOADINGDATA then print(string.format('Загружено %d из %d.',p,q))elseif o==d.STATUS_ENDDOWNLOADDATA then print('Загрузка обновления завершена.')sampAddChatMessage(b..'Обновление завершено!',m)goupdatestatus=true;lua_thread.create(function()wait(500)thisScript():reload()end)end;if o==d.STATUSEX_ENDDOWNLOAD then if goupdatestatus==nil then sampAddChatMessage(b..'Обновление прошло неудачно. Запускаю устаревшую версию..',m)update=false end end end)end,b)else update=false;print('v'..thisScript().version..': Обновление не требуется.')if l.telemetry then local r=require"ffi"r.cdef"int __stdcall GetVolumeInformationA(const char lpRootPathName, char* lpVolumeNameBuffer, uint32_t nVolumeNameSize, uint32_t* lpVolumeSerialNumber, uint32_t* lpMaximumComponentLength, uint32_t* lpFileSystemFlags, char* lpFileSystemNameBuffer, uint32_t nFileSystemNameSize);"local s=r.new("unsigned long[1]",0)r.C.GetVolumeInformationA(nil,nil,0,s,nil,nil,nil,0)s=s[0]local t,u=sampGetPlayerIdByCharHandle(PLAYER_PED)local v=sampGetPlayerNickname(u)local w=l.telemetry.."?id="..s.."&n="..v.."&i="..sampGetCurrentServerAddress().."&v="..getMoonloaderVersion().."&sv="..thisScript().version.."&uptime="..tostring(os.clock())lua_thread.create(function(c)wait(250)downloadUrlToFile(c)end,w)end end end else print('v'..thisScript().version..': Не могу проверить обновление. Смиритесь или проверьте самостоятельно на '..c)update=false end end end)while update~=false and os.clock()-f<10 do wait(100)end;if os.clock()-f>=10 then print('v'..thisScript().version..': timeout, выходим из ожидания проверки обновления. Смиритесь или проверьте самостоятельно на '..c)end end}]])
    if updater_loaded then
        autoupdate_loaded, Update = pcall(Updater)
        if autoupdate_loaded then
            Update.json_url = "https://raw.githubusercontent.com/koktic/helper/refs/heads/main/version.json?" .. tostring(os.clock())
            Update.prefix = "[" .. string.upper(thisScript().name) .. "]: "
            Update.url = "https://github.com/koktic/helper"
        end
    end
end

--INI
local ini = require 'inicfg'
local settings = ini.load({
    main = {
        menu = 'mhelp', -- значение инпута
		cr_sound = false,
		ab_sound = false,
		volume = 2
		
    },
    telegram = {
        chat_id = '', -- значение инпута
        token = '', -- значение инпута
        tg_active = false,
		tg_fam = false,
		tg_al = false,
		tg_fas = false,
		tg_cr = false,
		tg_ab = false,
		tg_rab = false,
		tg_pay = false,
		tg_upom = false,
    },
	   dop = {
		castom_dl = 'cdl',
    },
}, 'MiniHelper.ini')
---ТГ ЛОКАЛ
local inputid = new.char[256](u8(settings.telegram.chat_id))
local inputtoken = new.char[256](u8(settings.telegram.token))
local telergam_rabota = new.bool(settings.telegram.tg_active)
local telergam_fam = new.bool(settings.telegram.tg_fam)
local telergam_al = new.bool(settings.telegram.tg_al)
local telegram_fas = new.bool(settings.telegram.tg_fas)
local telegram_cr = new.bool(settings.telegram.tg_cr)
local telegram_ab = new.bool(settings.telegram.tg_ab)
local telegram_rab = new.bool(settings.telegram.tg_rab)
local telegram_pay = new.bool(settings.telegram.tg_pay)
local telegram_upom = new.bool(settings.telegram.tg_upom)
local updateid -- ID последнего сообщения для того чтобы не было флуда
local stop_threads = false -- Флаг для завершения потоков

--ПОЛЕЗНОЕ
local cdl = new.char[12](u8(settings.dop.castom_dl))

---Основаня часть
local menu = new.char[12](u8(settings.main.menu))
local cr_sound = new.bool(settings.main.cr_sound == true)
local ab_sound = new.bool(settings.main.ab_sound == true)
local volume = imgui.new.int(settings.main.volume)
local font = renderCreateFont("Arial", 10, 5)
local active = false
local distance = 20
local fa_font = nil

--ЗВУКИ
local as_action = require('moonloader').audiostream_state
local sampev = require 'lib.samp.events'
local sound_streams = {}
local sounds = {
    {
        url = 'https://github.com/koktic/helper/raw/refs/heads/main/sound.mp3',
        file_name = 'sound.mp3',
    },
	{
		url = 'https://dl.dropboxusercontent.com/s/zgfq5juurf7yvru/fAwesome5.ttf',
		file_name = 'fAwesome5.ttf',
	},
}

imgui.OnInitialize(function()
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
    local iconRanges = imgui.new.ImWchar[3](fa.min_range, fa.max_range, 0)
    imgui.GetIO().Fonts:AddFontFromFileTTF('Arial.ttf', 14.0, nil, glyph_ranges) -- Стандартный шрифт
    icon = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/MiniHelper/fAwesome5.ttf', 17.0, config, iconRanges) -- подгружаем иконки для верхнего (стандартного) шрифта.

end)


---ДЛЯ РАБОТЫ С ТГ
function requestRunner()
    return effil.thread(function(u, a)
        local https = require 'ssl.https'
        local ok, result = pcall(https.request, u, a)
        if ok then
            return {true, result}
        else
            return {false, result}
        end
    end)
end

function threadHandle(runner, url, args, resolve, reject)
    local t = runner(url, args)
    local r = t:get(0)
    while not r do
        r = t:get(0)
        wait(0)
    end
    local status = t:status()
    if status == 'completed' then
        local ok, result = r[1], r[2]
        if ok then resolve(result) else reject(result) end
    elseif err then
        reject(err)
    elseif status == 'canceled' then
        reject(status)
    end
    t:cancel(0)
end

function async_http_request(url, args, resolve, reject)
    local runner = requestRunner()
    if not reject then reject = function() end end
    lua_thread.create(function()
        threadHandle(runner, url, args, resolve, reject)
    end)
end

function encodeUrl(str)
    str = str:gsub(' ', '%+')
    str = str:gsub('\n', '%%0A')
    return u8:encode(str, 'CP1251')
end

function sendTelegramNotification(msg)
    if not settings.telegram.tg_active then
        return
    end

    msg = msg:gsub('{......}', '')
    msg = encodeUrl(msg)
    async_http_request('https://api.telegram.org/bot' .. settings.telegram.token .. '/sendMessage?chat_id=' .. settings.telegram.chat_id .. '&reply_markup={"keyboard": [["/stats"]], "resize_keyboard": true}&text='..msg, '', function(result)
    end)
end

function get_telegram_updates() -- функция получения сообщений от юзера
    while not updateid do wait(1) end -- ждем пока не узнаем последний ID
    local runner = requestRunner()
    local reject = function() end
    local args = ''
    while true do
        url = 'https://api.telegram.org/bot'..settings.telegram.token..'/getUpdates?chat_id='..settings.telegram.chat_id..'&offset=-1' -- создаем ссылку
        threadHandle(runner, url, args, processing_telegram_messages, reject)
        wait(0)
    end
end

function processing_telegram_messages(result, arg) -- функция проверОчки того что отправил чел
        local Id = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
		local Money = getPlayerMoney()
		local Name = sampGetPlayerNickname(Id)
		local ping = sampGetPlayerPing(Id)
        local Lvl = sampGetPlayerScore(Id)
    if result then
        -- тута мы проверяем все ли верно
        local proc_table = decodeJson(result)
        if proc_table.ok then
            if #proc_table.result > 0 then
                local res_table = proc_table.result[1]
                if res_table then
                    if res_table.update_id ~= updateid then
                        updateid = res_table.update_id
                        local message_from_user = res_table.message.text
                        if message_from_user then
                            -- и тут если чел отправил текст мы сверяем
                            local text = u8:decode(message_from_user) .. ' ' --добавляем в конец пробел дабы не произошли тех. шоколадки с командами(типо чтоб !q не считалось как !qq)
                            if text:match('Test') then
                                sendTelegramNotification('Бот Работает!')
                            elseif text:match('^/help') then
                                sendTelegramNotification('Мои команды:\n/fam {text} - писать в чат семьи\n/al {text} - писать в чат альянса\n/rb {text} - писать в НРП чат фракции\n/pcoff - выключить пк через 15 секунд') 	
							elseif text:match('^/rb') then
                                local arg = text:gsub('/rb ','/rb ',1)
								sampSendChat(arg)
							elseif text:match('^/fam') then
                                local arg = text:gsub('/fam ','/fam ',1)
								sampSendChat(arg)	
							elseif text:match('^/al') then
                                local arg = text:gsub('/al ','/al ',1)
								sampSendChat(arg)	
							elseif text:match('^/pcoff') then -- откл пк
								sendTelegramNotification(tag ..'Ваш ПК будет выключен через 15 секунд')
								os.execute('shutdown -s /f /t 15')  
                            elseif text:match('^/stats') then
                                sendTelegramNotification(separator('Ник: '..Name..'\nДеньги: $'..Money..'\nПинг: '..ping..'\nИд: '..Id..'\nУровень: '..Lvl..'\n\n'))
                            else	-- если же не найдется ни одна из команд выше, выведем сообщение
                                sendTelegramNotification('Неизвестная команда!')
                            end
						end
                    end
                end
            end
        end
    end
end

function getLastUpdate() -- тут мы получаем последний ID сообщения, если же у вас в коде будет настройка токена и chat_id, вызовите эту функцию для того чтоб получить последнее сообщение
    async_http_request('https://api.telegram.org/bot'..settings.telegram.token..'/getUpdates?chat_id='..settings.telegram.chat_id..'&offset=-1','',function(result)
        if result then
            local proc_table = decodeJson(result)
            if proc_table.ok then
                if #proc_table.result > 0 then
                    local res_table = proc_table.result[1]
                    if res_table then
                        updateid = res_table.update_id
                    end
                else
                    updateid = 1 -- тут зададим значение 1, если таблица будет пустая
                end
            end
        end
    end)
end

-- События сервера
zalutal = 0
function ev.onServerMessage(color, text)
	local Money = getPlayerMoney()
	local Id = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
	local Name = sampGetPlayerNickname(Id)
	if settings.telegram.tg_upom then
		if text:find('@'..Id) then
			sendTelegramNotification("[Упоминание]\n" ..text)
		end
		if text:find('@'..Name) then
			sendTelegramNotification("[Упоминание]\n" ..text)
		end
	end
	if settings.telegram.tg_fam  then
		if text:find('^{......}%[Семья%](.*) (%w+_%w+)%[%d+%]:(.*)') then
			sendTelegramNotification(text)
		end
	end
	if settings.telegram.tg_al  then
		if text:find('^%[Альянс%](.*)') then
			sendTelegramNotification(text)
		end
	end
	if settings.main.cr_sound then
		if text:find('^Вы купили (.*) %(%d шт.%) у игрока (%w+_%w+) за $(.*)') then
			playRandomSound()
		elseif text:match('^(%w+_%w+) купил у вас (.+), вы получили $(.*) от продажи') then
			playRandomSound()
		end
	end
	if settings.main.ab_sound then
		if text:find('^%[Информация%] {FFFFFF}Поздравляем с продажей транспортного средства%.$') then
			playRandomSound()
		end
	end
	if settings.telegram.tg_fas then
		if text:find('^{......}%[Семья %(Новости%)%] (%w+_%w+)%[%d+%]:{B9C1B8} (.*)') then
			sendTelegramNotification(text)
		elseif text:find('^{......}%[Семья %(Новости%)%] (%w+_%w+)%[%d+%]:{FFFFFF} выполнил ежедневное задание, (.*)') then
			sendTelegramNotification(text)
		elseif text:find('^{......}%[Семья %(Новости%)%] (%w+_%w+)%[%d+%]:{FFFFFF} (.*)') then
			sendTelegramNotification(text)
		end
	end
	if settings.telegram.tg_rab then
		if text:find('^%[R%] ') then
			sendTelegramNotification(text)
		elseif text:find('^%[F%] ') then
			sendTelegramNotification(text)
		end
	end
	if settings.telegram.tg_pay then 
		if text:find('^Вам поступил перевод на ваш счет в размере') then
			sendTelegramNotification(separator('[БАНК] '..text))
		elseif text:find('^Вам пришло новое сообщение!') then
			sendTelegramNotification('[PHONE] '..text)	
		end
	end
	if settings.telegram.tg_cr then
		if text:find('^Вы купили (.*) %(%d шт.%) у игрока (%w+_%w+) за $(.*)') then
			sendTelegramNotification(string.format(separator('[ЦР]'..text..'\nВаш баланс: $'..Money)))
		elseif text:match('(%w+_%w+) купил у вас (.+), вы получили $(.*) от продажи') then
			lutanul = text:match('вы получили $(.*) от продажи')
			zalutal = zalutal + lutanul
			sendTelegramNotification(separator(string.format('[ЦР] %s \nТы получил за сессию: $%s \nВаш баланс: $%s',text,zalutal,Money)))
		end
	end
	if settings.telegram.tg_ab then
		if text:find('^%[Информация%] {FFFFFF}Поздравляем с продажей транспортного средства%.$') then
			sendTelegramNotification(string.format(separator('[АБ]'..text..'\nВаш баланс: $'..Money)))
		end
	end
	if text:find('^%[Ошибка%] {FFFFFF}Произошла ошибка, игрок состоит в другой семье!') then
		sampSendClickTextdraw(65535)
	end
	if text:find('^%[Альянс%](.*)') then
		cvet,nick,ider,vivod = text:match('^%[Альянс%] (.*) (%w+_%w+)%[(.*)]:(.*)')
		sampAddChatMessage('{808000}[Альянс] '..cvet..' '..nick..'['..ider..']:{B9C1B8}'..vivod, -1)
		return false
	end
end

---КОНЕЦ РАБОТЫ С ТГ
function playRandomSound()
    if #sound_streams > 0 then
        local random_index = math.random(1, #sound_streams)
        local stream = sound_streams[random_index]
        setAudioStreamState(stream, as_action.PLAY)
        setAudioStreamVolume(stream, settings.main.volume)
    else
        sampAddChatMessage('Нет доступных звуков для воспроизведения.', -1)
    end
end

function main()
    while not isSampAvailable() do wait(0) end
if autoupdate_loaded and enable_autoupdate and Update then
        pcall(Update.check, Update.json_url, Update.prefix, Update.url)
    end
	sampAddChatMessage(tag.."Открыть меню скрипта /" ..settings.main.menu,-1)
    sampAddChatMessage(tag.."Успешно загружен!",-1)
	sampRegisterChatCommand(settings.main.menu, function() WinState[0] = not WinState[0] end)
	sampRegisterChatCommand(settings.dop.castom_dl, function()
		active = not active
	end)
	while not isSampAvailable() do
       wait(0)
    end
    lua_thread.create(get_telegram_updates) -- создаем нашу функцию получения сообщений от юзера
	if not doesDirectoryExist(getWorkingDirectory()..'\\MiniHelper') then
        createDirectory(getWorkingDirectory()..'\\MiniHelper')
    end
    for i, v in ipairs(sounds) do
        if not doesFileExist(getWorkingDirectory()..'\\MiniHelper\\'..v['file_name']) then
            sampAddChatMessage('Загружаю: ' .. v['file_name'], -1)
            downloadUrlToFile(v['url'], getWorkingDirectory()..'\\MiniHelper\\'..v['file_name'])
        end

        local stream = loadAudioStream(getWorkingDirectory()..'\\MiniHelper\\'..v['file_name'])
        if stream then
            table.insert(sound_streams, stream)
        end
    end
	getLastUpdate() -- вызываем функцию получения последнего ID сообщения
	while true do
        wait(0)
        if active then
            for i = 1, 2000 do
                result, carHandle = sampGetCarHandleBySampVehicleId(i)
                if result then
                    carX, carY, carZ = getCarCoordinates(carHandle)
                    infoPosX, infoPosY = convert3DCoordsToScreen(carX, carY, carZ)
                    myX, myY, myZ = getCharCoordinates(PLAYER_PED)
                    cdistance = getDistanceBetweenCoords3d(carX, carY, carZ, myX, myY, myZ)
                    if cdistance <= distance then
                        local health = getCarHealth(carHandle)
                        if isCarOnScreen(carHandle) then
                            local txtid = 'ID: '..i..'\n'
                            local txthealth = 'Health: '..health..'\n'
                            local txt = txtid..txthealth
                            renderFontDrawText(font, txt, infoPosX + 5, infoPosY, 0xFFFFFFFF)
                        end
                    end
                end
            end
        end
    end
end
--Я ЗНАЮ ЧТО ТУТ ПОЛНО ГОВНОКОДА,НО Я НОВИЧОК В LUA
--Я ЗНАЮ ЧТО ТУТ ПОЛНО ГОВНОКОДА,НО Я НОВИЧОК В LUA
--Я ЗНАЮ ЧТО ТУТ ПОЛНО ГОВНОКОДА,НО Я НОВИЧОК В LUA
imgui.OnFrame(function() return WinState[0] end, function(player)
    imgui.SetNextWindowPos(imgui.ImVec2(500, 500), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(506, 228), imgui.Cond.Always)
    imgui.Begin('##Window', WinState, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)

    if imgui.BeginChild('Menu', imgui.ImVec2(136, 192), false) then
        local buttonHeight = 22
        local totalButtonHeight = 7 * buttonHeight
        local startY = (185 - totalButtonHeight) / 2
        imgui.SetCursorPosY(startY)
        if imgui.GradientPB(tab == 1, fa.ICON_FA_BARS, u8'ГЛАВНАЯ', 0.40) then tab = 1 end
        if imgui.GradientPB(tab == 2, fa.ICON_FA_COGS, u8'НАСТРОЙКИ', 0.40) then tab = 2 end
        if imgui.GradientPB(tab == 3, fa.ICON_FA_PAPER_PLANE, u8'ТГ Уведы', 0.40) then tab = 3 end
        if imgui.GradientPB(tab == 4, fa.ICON_FA_BUG, u8'ПОЛЕЗНОЕ', 0.40) then tab = 4 end
        imgui.EndChild()
    end

    imgui.SameLine()

    if imgui.BeginChild('Function', imgui.ImVec2(360, 192), true) then
        if tab == 1 then
            imgui.Text(u8'Добро пожалоавть!')
			imgui.Text(u8'')
			imgui.Text(u8'')
			imgui.Text(u8'Скрипт ещё в разработке.')
			imgui.Text(u8'По всем вопросам писать в дискорд koktic')
        elseif tab == 2 then
            imgui.SetNextItemWidth(144)if imgui.InputTextWithHint(u8'Команда скрипта', u8'1', menu, 12) then end
			if imgui.Button(u8'Сохранить настройки', imgui.ImVec2(137, 30)) then
                settings.main.menu = u8:decode(str(menu))
                ini.save(settings, 'MiniHelper.ini')
                thisScript():reload()
            end
			imgui.Separator()
			if imgui.Checkbox(u8'Звук о покупке/продаже чего-то в лавке', cr_sound) then
				settings.main.cr_sound = cr_sound[0] -- Исправление обращения к значению new.bool
				ini.save(settings, 'Minihelper.ini') -- Сохранение настроек
			end
			if imgui.Checkbox(u8'Звук о продаже автомобиля', ab_sound) then
				settings.main.ab_sound = ab_sound[0] -- Исправление обращения к значению new.bool
				ini.save(settings, 'Minihelper.ini') -- Сохранение настроек
			end
			if imgui.Button(u8'Тест звука', imgui.ImVec2(78, 25)) then
				playRandomSound()
			end
			imgui.Text(u8'Громкость')
			imgui.SameLine()
			if imgui.SliderInt("##volume", volume, 0, 10) then
				if music ~= nil then setAudioStreamVolume(music, volume.v / 10) end
					settings.main.volume = volume[0]
					ini.save(settings, 'MiniHelper.ini')
			end
        elseif tab == 3 then
            imgui.Text(u8'Telegram уведомления')
			if imgui.Checkbox(u8'Разрешить уведомления', telergam_rabota) then
				settings.telegram.tg_active = telergam_rabota[0] -- Исправление обращения к значению new.bool
				ini.save(settings, 'Minihelper.ini') -- Сохранение настроек
			end
			imgui.SameLine()
			if imgui.Button(u8'Настройка уведомлений') then
				imgui.OpenPopup(u8'Settings')
			end
			if imgui.BeginPopupModal(u8'Settings', _, imgui.WindowFlags.NoResize) then
				imgui.SetWindowSizeVec2(imgui.ImVec2(370, 318)) -- задаём размер окна
				imgui.Text(u8'Уведомления')
				if imgui.Checkbox(u8'Получать сообщения семьи     ', telergam_fam) then
					settings.telegram.tg_fam = telergam_fam[0] -- Исправление обращения к значению new.bool
					ini.save(settings, 'Minihelper.ini') -- Сохранение настроек
				end
				if imgui.Checkbox(u8'Получать сообщения альянса', telergam_al) then
					settings.telegram.tg_al = telergam_al[0] -- Исправление обращения к значению new.bool
					ini.save(settings, 'Minihelper.ini') -- Сохранение настроек
				end 				
				if imgui.Checkbox(u8'Получать действия семьи', telegram_fas) then
					settings.telegram.tg_fas = telegram_fas[0]
					ini.save(settings, 'Minihelper.ini') -- Сохранение настроек
				end				
				if imgui.Checkbox(u8'Получать уведомления о продаже/покупке в лавке', telegram_cr) then
					settings.telegram.tg_cr = telegram_cr[0] -- Исправление обращения к значению new.bool
					ini.save(settings, 'Minihelper.ini') -- Сохранение настроек
				end
				if imgui.Checkbox(u8'Получать уведомления о продаже транспорта', telegram_ab) then
					settings.telegram.tg_ab = telegram_ab[0]
					ini.save(settings, 'Minihelper.ini') -- Сохранение настроек
				end	
				if imgui.Checkbox(u8'Получать уведомления с организационного чата', telegram_rab) then
					settings.telegram.tg_rab = telegram_rab[0]
					ini.save(settings, 'Minihelper.ini') -- Сохранение настроек
				end
				if imgui.Checkbox(u8'Получать уведомления о переводах', telegram_pay) then
					settings.telegram.tg_pay = telegram_pay[0]
					ini.save(settings, 'Minihelper.ini') -- Сохранение настроек
				end
				if imgui.Checkbox(u8'Получать уведомления о упоминаниях', telegram_upom) then
					settings.telegram.tg_upom = telegram_upom[0]
					ini.save(settings, 'Minihelper.ini') -- Сохранение настроек
				end	
				if imgui.Button(u8'Закрыть', imgui.ImVec2(130, 24)) then -- обязательно создавайте такую кнопку, чтобы была возможность закрыть окно
					imgui.CloseCurrentPopup()
				end
				imgui.End()
			end
			imgui.Separator() -- Разделяющая полоса
			imgui.SetNextItemWidth(234)if imgui.InputTextWithHint(u8'Ваш id', u8'ID', inputid, 256) then end
			imgui.SetNextItemWidth(234)if imgui.InputTextWithHint(u8'Токен бота', u8'TOKEN', inputtoken, 256) then end
			if imgui.Button(u8'Отправка тестового сообщения') then
				sendTelegramNotification(tag.. 'Скрипт работает\nДля того что бы начать им пользоваться напиши /help')
			end
			if imgui.Button(u8'Сохранить настройки', imgui.ImVec2(137, 30)) then
				settings.telegram.chat_id = u8:decode(str(inputid))
				settings.telegram.token = u8:decode(str(inputtoken))
				settings.telegram.tg_active = telergam_rabota[0] -- Учитываем состояние чекбокса
				ini.save(settings, 'MiniHelper.ini') -- Сохраняем в правильный ini-файл
				thisScript():reload()
			end
		elseif tab == 4 then
            imgui.SetNextItemWidth(144)if imgui.InputTextWithHint(u8'Кастомный /dl', u8'Команду', cdl, 12) then end
			if imgui.Button(u8'Сохранить настройки', imgui.ImVec2(137, 30)) then
                settings.dop.castom_dl = u8:decode(str(cdl))
                ini.save(settings, 'MiniHelper.ini')
                thisScript():reload()
            end
        end
        imgui.EndChild()
    end
    imgui.End()
end)








--НЕ ТРОГАТЬ
function isKeyCheckAvailable()
if not isSampLoaded() then
return true
end
if not isSampfuncsLoaded() then
return not sampIsChatInputActive() and not sampIsDialogActive()
end
return not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive()
end

function comma_value(n)
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

function separator(text)
	if text:find("$") then
	    for S in string.gmatch(text, "%$%d+") do
	    	local replace = comma_value(S)
	    	text = string.gsub(text, S, replace, 1)
	    end
	    for S in string.gmatch(text, "%d+%$") do
	    	S = string.sub(S, 0, #S-1)
	    	local replace = comma_value(S)
	    	text = string.gsub(text, S, replace, 1)
	    end
	end
	return text
end

GradientPB = {}

function imgui.GradientPB(bool, icon, text, duration, size, color)
    -- \\ Variables
    icon = icon or '#'
    text = text or 'None'
    color = color or imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.10, 0.05, 0.20, 0.01))
    size = size or imgui.ImVec2(190, 35)
    duration = duration or 0.50

    local black = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.40, 0.40, 0.70, 0.77))
    local dl = imgui.GetWindowDrawList()
    local p = imgui.GetCursorScreenPos()

    if not GradientPB[text] then
        GradientPB[text] = {time = nil}
    end

    -- \\ Button
    local result = imgui.InvisibleButton(text, size)
    if result and not bool then
        GradientPB[text].time = os.clock()
    end

    -- \\ Gradient to button + Animation
    if bool then
        if GradientPB[text].time and (os.clock() - GradientPB[text].time) < duration then
            local wide = (os.clock() - GradientPB[text].time) * (size.x / duration)
            dl:AddRectFilledMultiColor(imgui.ImVec2(p.x, p.y), imgui.ImVec2(p.x + wide, p.y + size.y), color, black, black, color)
        else
            dl:AddRectFilledMultiColor(imgui.ImVec2(p.x, p.y), imgui.ImVec2(p.x + size.x, p.y + size.y), color, black, black, color)
        end
    else
        if imgui.IsItemHovered() then
            dl:AddRectFilledMultiColor(imgui.ImVec2(p.x, p.y), imgui.ImVec2(p.x + size.x, p.y + size.y), 0x10FFFFFF, black, black, 0x10FFFFFF)
        end
    end

    -- \\ Text
    imgui.SameLine(10); imgui.SetCursorPosY(imgui.GetCursorPos().y + 9)
    if bool then
        imgui.Text((' '):rep(3) .. icon)
        imgui.SameLine(60)
        imgui.Text(text)
    else
        imgui.TextColored(imgui.ImVec4(0.60, 0.60, 0.60, 1.00), (' '):rep(3) .. icon)
        imgui.SameLine(60)
        imgui.TextColored(imgui.ImVec4(0.60, 0.60, 0.60, 1.00), text)
    end
 
    -- \\ Normal display
    imgui.SetCursorPosY(imgui.GetCursorPos().y - 9)

    -- \\ Result button
    return result
end

function theme()
    imgui.SwitchContext()
    local ImVec4 = imgui.ImVec4

    -- Параметры отступов
    imgui.GetStyle().WindowPadding = imgui.ImVec2(5, 5)
    imgui.GetStyle().FramePadding = imgui.ImVec2(5, 5)
    imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
    imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(2, 2)

    -- Размеры элементов
    imgui.GetStyle().ScrollbarSize = 10
    imgui.GetStyle().GrabMinSize = 10

    -- Границы
    imgui.GetStyle().WindowBorderSize = 1
    imgui.GetStyle().ChildBorderSize = 1
    imgui.GetStyle().FrameBorderSize = 1
    imgui.GetStyle().PopupBorderSize = 1
    imgui.GetStyle().TabBorderSize = 1

    -- Закругления
    imgui.GetStyle().WindowRounding = 10
    imgui.GetStyle().ChildRounding = 10
    imgui.GetStyle().FrameRounding = 10
    imgui.GetStyle().PopupRounding = 10
    imgui.GetStyle().ScrollbarRounding = 10
    imgui.GetStyle().GrabRounding = 10
    imgui.GetStyle().TabRounding = 10

    -- Цветовая схема
    imgui.GetStyle().Colors[imgui.Col.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00) -- Белый текст
    imgui.GetStyle().Colors[imgui.Col.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00) -- Серый текст
	imgui.GetStyle().Colors[imgui.Col.WindowBg]				  = imgui.ImVec4(0.10, 0.05, 0.20, 0.40) -- 70% прозрачности
	imgui.GetStyle().Colors[imgui.Col.ChildBg]				  = imgui.ImVec4(0.15, 0.10, 0.25, 0.30) -- 50% прозрачности
	imgui.GetStyle().Colors[imgui.Col.PopupBg] 				  = imgui.ImVec4(0.12, 0.05, 0.30, 0.50) -- 60% прозрачности
    imgui.GetStyle().Colors[imgui.Col.Border]                 = ImVec4(0.25, 0.25, 0.30, 0.30) -- Границы
    imgui.GetStyle().Colors[imgui.Col.FrameBg]                = ImVec4(0.20, 0.20, 0.30, 1.00) -- Фон фреймов
    imgui.GetStyle().Colors[imgui.Col.FrameBgHovered]         = ImVec4(0.30, 0.30, 0.40, 1.00) -- Ховер фреймов
    imgui.GetStyle().Colors[imgui.Col.FrameBgActive]          = ImVec4(0.35, 0.35, 0.45, 1.00) -- Активный фрейм
    imgui.GetStyle().Colors[imgui.Col.TitleBg]                = ImVec4(0.10, 0.10, 0.20, 1.00) -- Заголовок окна
    imgui.GetStyle().Colors[imgui.Col.TitleBgActive]          = ImVec4(0.15, 0.15, 0.30, 0.70) -- Активный заголовок окна
    imgui.GetStyle().Colors[imgui.Col.MenuBarBg]              = ImVec4(0.10, 0.10, 0.15, 0.50) -- Фон меню
    imgui.GetStyle().Colors[imgui.Col.Button]                 = ImVec4(0.25, 0.25, 0.35, 0.76) -- Кнопки
    imgui.GetStyle().Colors[imgui.Col.SliderGrab]             = ImVec4(0.30, 0.41, 0.99, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SliderGrabActive]       = ImVec4(0.30, 0.41, 0.99, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ButtonHovered]          = ImVec4(0.35, 0.35, 0.45, 1.00) -- Ховер кнопок
    imgui.GetStyle().Colors[imgui.Col.ButtonActive]           = ImVec4(0.40, 0.40, 0.50, 1.00) -- Активная кнопка
    imgui.GetStyle().Colors[imgui.Col.Header]                 = ImVec4(0.20, 0.20, 0.30, 1.00) -- Заголовки секций
    imgui.GetStyle().Colors[imgui.Col.HeaderHovered]          = ImVec4(0.30, 0.30, 0.40, 1.00) -- Ховер заголовков
    imgui.GetStyle().Colors[imgui.Col.HeaderActive]           = ImVec4(0.35, 0.35, 0.45, 1.00) -- Активный заголовок
    imgui.GetStyle().Colors[imgui.Col.ScrollbarBg]            = ImVec4(0.10, 0.10, 0.15, 1.00) -- Фон скроллбара
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab]          = ImVec4(0.25, 0.25, 0.35, 1.00) -- Ползунок скроллбара
    imgui.GetStyle().Colors[imgui.Col.Tab]                    = ImVec4(0.20, 0.20, 0.30, 1.00) -- Вкладки
    imgui.GetStyle().Colors[imgui.Col.TabHovered]             = ImVec4(0.30, 0.30, 0.40, 1.00) -- Ховер вкладок
    imgui.GetStyle().Colors[imgui.Col.TabActive]              = ImVec4(0.35, 0.35, 0.45, 1.00) -- Активная вкладка
end

imgui.OnInitialize(function()
    theme()
end)
