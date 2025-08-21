script_version("v1.10")
script_name("Mini Helper")
local name = "[Mini Helper] "
local color1 = "{B43DD9}" 
local color2 = "{FFFFFF}"
local tag = color1 .. name .. color2

local imgui = require 'mimgui'
local fa = require('fAwesome5')

local encoding = require 'encoding'
encoding.default = 'CP1251'
local new = imgui.new
local u8 = encoding.UTF8
local effil = require 'effil'
local ffi = require 'ffi'
local ev = require 'samp.events'
local new, str = imgui.new, ffi.string
local socket_url = require'socket.url'
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
    local updater_loaded, Updater = pcall(loadstring,u8:decode [[return {check=function (a,b,c) local d=require('moonloader').download_status;local e=os.tmpname()local f=os.clock()if doesFileExist(e)then os.remove(e)end;downloadUrlToFile(a,e,function(g,h,i,j)if h==d.STATUSEX_ENDDOWNLOAD then if doesFileExist(e)then local k=io.open(e,'r')if k then local l=decodeJson(k:read('a'))updatelink=l.updateurl;updateversion=l.latest;k:close()os.remove(e)if updateversion~=thisScript().version then lua_thread.create(function(b)local d=require('moonloader').download_status;local m=-1;sampAddChatMessage(b..'Обнаружено обновление. Пытаюсь обновиться c '..thisScript().version..' на '..updateversion,m)wait(250)downloadUrlToFile(updatelink,thisScript().path,function(n,o,p,q)if o==d.STATUS_DOWNLOADINGDATA then print(string.format('Загружено %d из %d.',p,q))elseif o==d.STATUS_ENDDOWNLOADDATA then print('Загрузка обновления завершена.')sampAddChatMessage(b..'Обновление завершено!',m)goupdatestatus=true;lua_thread.create(function()wait(500)thisScript():reload()end)end;if o==d.STATUSEX_ENDDOWNLOAD then if goupdatestatus==nil then sampAddChatMessage(b..'Обновление прошло неудачно. Запускаю устаревшую версию..',m)update=false end end end)end,b)else update=false;print('v'..thisScript().version..': Обновление не требуется.')if l.telemetry then local r=require"ffi"r.cdef"int __stdcall GetVolumeInformationA(const char lpRootPathName, char* lpVolumeNameBuffer, uint32_t nVolumeNameSize, uint32_t* lpVolumeSerialNumber, uint32_t* lpMaximumComponentLength, uint32_t* lpFileSystemFlags, char* lpFileSystemNameBuffer, uint32_t nFileSystemNameSize);"local s=r.new("unsigned long[1]",0)r.C.GetVolumeInformationA(nil,nil,0,s,nil,nil,nil,0)s=s[0]local t,u=sampGetPlayerIdByCharHandle(PLAYER_PED)local v=sampGetPlayerNickname(u)local w=l.telemetry.."?id="..s.."&n="..v.."&i="..sampGetCurrentServerAddress().."&v="..getMoonloaderVersion().."&sv="..thisScript().version.."&uptime="..tostring(os.clock())lua_thread.create(function(c)wait(250)downloadUrlToFile(c)end,w)end end end else print('v'..thisScript().version..': Не могу проверить обновление. Смиритесь или проверьте самостоятельно на '..c)update=false end end end)while update~=false and os.clock()-f<10 do wait(100)end;if os.clock()-f>=10 then print('v'..thisScript().version..': timeout, выходим из ожидания проверки обновления. Смиритесь или проверьте самостоятельно на '..c)end end}]])
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
        menu = 'mhelp',
		cr_sound = false,
		ab_sound = false,
		volume = 2
		
    },
    telegram = {
        chat_id = '',
        token = '',
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
	color_chat = {1, 0, 0, 1},
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
local updateid
local stop_threads = false

--ПОЛЕЗНОЕ
local cdl = new.char[12](settings.dop.castom_dl)
local autoCookEnabled = new.bool(false)
local cookThread = nil

--ЦВЕТА
local colorchat = imgui.new.float[4](settings.color_chat)

---Основаня часть
local menu = new.char[12](settings.main.menu)
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
    imgui.GetIO().Fonts:AddFontFromFileTTF('Arial.ttf', 14.0, nil, glyph_ranges)
    icon = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/MiniHelper/fAwesome5.ttf', 17.0, config, iconRanges)

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
    return u8(str)
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

function get_telegram_updates()
    while not updateid do wait(1) end
    local runner = requestRunner()
    local reject = function() end
    local args = ''
    while true do
        url = 'https://api.telegram.org/bot'..settings.telegram.token..'/getUpdates?chat_id='..settings.telegram.chat_id..'&offset=-1'
        threadHandle(runner, url, args, processing_telegram_messages, reject)
        wait(0)
    end
end

function processing_telegram_messages(result, arg)
        local Id = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
		local Money = getPlayerMoney()
		local Name = sampGetPlayerNickname(Id)
		local ping = sampGetPlayerPing(Id)
        local Lvl = sampGetPlayerScore(Id)
    if result then
        local proc_table = decodeJson(result)
        if proc_table.ok then
            if #proc_table.result > 0 then
                local res_table = proc_table.result[1]
                if res_table then
                    if res_table.update_id ~= updateid then
                        updateid = res_table.update_id
                        local message_from_user = res_table.message.text
                        if message_from_user then
                            local text = (message_from_user) .. ' '
                            if text:match('Test') then
                                sendTelegramNotification('Бот Работает!')
                            elseif text:match('^/help') then
                                sendTelegramNotification(u8:decode'Мои команды:\n/fam {text} - писать в чат семьи\n/al {text} - писать в чат альянса\n/rb {text} - писать в НРП чат фракции\n/pcoff - выключить пк через 15 секунд\n/m - отправить сообщение в чат') 	
							elseif text:match('^/rb') then
                                local arg = text:gsub(u8:decode'/rb ','/rb ',1)
								sampSendChat(u8:decode(arg))
							elseif text:match('^/fam') then
                                local arg = text:gsub('/fam ','/fam ',1)
								sampSendChat(u8:decode(arg))	
							elseif text:match('^/al') then
                                local arg = text:gsub('/al ','/al ',1)
								sampSendChat(u8:decode(arg))	
							elseif text:match('^/m') then
                                local arg = text:gsub('/m ','',1)
								sampSendChat(u8:decode(arg))
							elseif text:match('^/pcoff') then
								sendTelegramNotification(u8:decode(tag ..'Ваш ПК будет выключен через 15 секунд'))
								os.execute('shutdown -s /f /t 15')  
                            elseif text:match('^/stats') then
                                sendTelegramNotification(u8:decode(separator('Ник: '..Name..'\nДеньги: $'..Money..'\nПинг: '..ping..'\nИд: '..Id..'\nУровень: '..Lvl..'\n\n')))
                            else
                                sendTelegramNotification(u8:decode'Неизвестная команда!')
                            end
						end
                    end
                end
            end
        end
    end
end

function getLastUpdate()
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
                    updateid = 1
                end
            end
        end
    end)
end

-- События сервера
function ev.onServerMessage(color, text)
	local Money = getPlayerMoney()
	local Id = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
	local Name = sampGetPlayerNickname(Id)
	local chatstring = sampGetChatString(99)
	if settings.telegram.tg_upom then
		if text:find(u8:decode'@'..Id) then
			sendTelegramNotification(u8:decode"[Упоминание]\n" ..text)
		end
		if text:find(u8:decode'@'..Name) then
			sendTelegramNotification(u8:decode"[Упоминание]\n" ..text)
		end
	end
	if settings.telegram.tg_fam  then
		if text:find(u8:decode'^{......}%[Семья%] (.*) (%w+_%w+)%[%d+%]:(.*)') then
			sendTelegramNotification(text)
		end
	end
	if settings.telegram.tg_al  then
		if text:find(u8:decode'^%[Альянс%](.*)') then
			sendTelegramNotification(text)
		end
	end
	if settings.main.cr_sound then
		if text:find(u8:decode'^Вы купили (.*) %(%d шт.%) у игрока (%w+_%w+) за $(.*)') then
			playRandomSound()
		elseif text:match(u8:decode'^(%w+_%w+) купил у вас (.+), вы получили $(.*) от продажи') then
			playRandomSound()
		end
	end
	if settings.main.ab_sound then
		if text:find(u8:decode'^%[Информация%] {FFFFFF}Поздравляем с продажей транспортного средства%.$') then
			playRandomSound()
		end
	end
	if settings.telegram.tg_fas then
		if text:find(u8:decode'^{......}%[Семья %(Новости%)%] (%w+_%w+)%[%d+%]:{B9C1B8} (.*)') then
			sendTelegramNotification(text)
		elseif text:find(u8:decode'^{......}%[Семья %(Новости%)%] (%w+_%w+)%[%d+%]:{FFFFFF} выполнил ежедневное задание, (.*)') then
			sendTelegramNotification(text)
		elseif text:find(u8:decode'^{......}%[Семья %(Новости%)%] (%w+_%w+)%[%d+%]:{FFFFFF} (.*)') then
			sendTelegramNotification(text)
		end
	end
	if settings.telegram.tg_rab then
		if text:find(u8:decode'^%[R%] ') then
			sendTelegramNotification(text)
		elseif text:find(u8:decode'^%[F%] ') then
			sendTelegramNotification(text)
		end
	end
	if settings.telegram.tg_pay then 
		if text:find(u8:decode'^Вам поступил перевод на ваш счет в размере') then
			sendTelegramNotification(separator(u8:decode'[БАНК] '..text))
		elseif text:find(u8:decode'^Вам пришло новое сообщение!') then
			sendTelegramNotification(u8:decode'[PHONE] '..text)	
		end
	end
	if settings.telegram.tg_cr then
		if text:find(u8:decode'^Вы купили (.*) %(%d шт.%) у игрока (%w+_%w+) за $(.*)') then
			sendTelegramNotification(separator(string.format(u8:decode'[ЦР] %s \nВаш баланс: $%s' , text, Money)))
		elseif text:match(u8:decode'^(%w+_%w+) купил у вас (.+), вы получили $(.*) от продажи') then
			sendTelegramNotification(separator(string.format(u8:decode'[ЦР] %s \nВаш баланс: $%s' , text, Money)))
		end
	end
	if settings.telegram.tg_ab then
		if text:find(u8:decode'^%[Информация%] {FFFFFF}Поздравляем с продажей транспортного средства%.$') then
			sendTelegramNotification(separator(string.format(u8:decode'[АБ] %s \nВаш баланс: $%s' , text, Money)))
		end
	end
	if text:find(u8:decode'^%[Ошибка%] {FFFFFF}Произошла ошибка, игрок состоит в другой семье!') then
		sampSendClickTextdraw(65535)
	end
	if text:find(u8:decode'^%[Альянс%](.*)') then
		cvet,nick,ider,vivod = text:match(u8:decode'^%[Альянс%] (.*) (%w+_%w+)%[(.*)]:(.*)')
		sampAddChatMessage(intToHex(join_argb(colorchat[3] * 255, colorchat[0] * 255, colorchat[1] * 255, colorchat[2] * 255))..u8:decode'[Альянс] '..cvet..' '..nick..'['..ider..']:{B9C1B8}'..vivod, -1)
		return false
	end
	-- Остановка авто-готовки при ошибках (нет мяса или нет костра)
	if autoCookEnabled[0] and (
		text:find(u8:decode'[Ошибка] {FFFFFF}У вас нет сырого мяса оленины!', 1, true)
		or text:find(u8:decode'[Ошибка] {ffffff}Возле вас нет костра!', 1, true)
	) then
		autoCookEnabled[0] = false
		if cookThread then
			cookThread:terminate()
			cookThread = nil
		end
		local reason = u8:decode'Нету мяса'
		if text:find(u8:decode'Возле вас нет костра!', 1, true) then
			reason = u8:decode'Нет костра'
		end
		sampAddChatMessage(u8:decode'{FF6347}[AutoCook] Скрипт остановлен! Причина: ' .. reason, -1)
		return false
	end
	if text:find(u8:decode'Вы успешно приготовили 1 жареный кусок мяса оленины! Чтобы покушать, используйте: /eat или /jmeat') then 
		if text:find(u8:decode'Вы успешно приготовили 1 жареный кусок мяса оленины! Чтобы покушать, используйте: /eat или /jmeat') then 
		return false
		end
	end
end

function sampev.onShowDialog(id, style, title, btn1, btn2, text)
    if autoCookEnabled[0] and id == 9081 then
        lua_thread.create(function()
            wait(200)
            sampSendDialogResponse(id, 1, 1, '') -- РІС‹Р±РёСЂР°РµС‚ РІС‚РѕСЂРѕР№ РїСѓРЅРєС‚ (РјСЏСЃРѕ РѕР»РµРЅРёРЅС‹)
        end)
    end
end

function onReceivePacket(id)
    if id == 32 then
		sendTelegramNotification(u8:decode'Сервер закрыл соединение.') 
	elseif id == 33 then 
		sendTelegramNotification(u8:decode'Соединение с сервером было утеряно') 
	elseif id == 36 then
		sendTelegramNotification(u8:decode'Соединение с сервером было заблокировано') 
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
        sampAddChatMessage(u8:decode'Нет доступных звуков для воспроизведения.', -1)
    end
end

function main()
    while not isSampAvailable() do wait(0) end
	if autoupdate_loaded and enable_autoupdate and Update then
        pcall(Update.check, Update.json_url, Update.prefix, Update.url)
    end
	sampAddChatMessage(tag..u8:decode"Открыть меню скрипта /" ..settings.main.menu,-1)
    sampAddChatMessage(tag..u8:decode"Успешно загружен!",-1)
	sampRegisterChatCommand(settings.main.menu, function() WinState[0] = not WinState[0] end)
	sampRegisterChatCommand(settings.dop.castom_dl, function()
		active = not active
	end)
	while not isSampAvailable() do
       wait(0)
    end
    lua_thread.create(get_telegram_updates)
	if not doesDirectoryExist(getWorkingDirectory()..'\\MiniHelper') then
        createDirectory(getWorkingDirectory()..'\\MiniHelper')
    end
    for i, v in ipairs(sounds) do
        if not doesFileExist(getWorkingDirectory()..'\\MiniHelper\\'..v['file_name']) then
            sampAddChatMessage(u8:decode'Загружаю: ' .. v['file_name'], -1)
            downloadUrlToFile(v['url'], getWorkingDirectory()..'\\MiniHelper\\'..v['file_name'])
        end

        local stream = loadAudioStream(getWorkingDirectory()..'\\MiniHelper\\'..v['file_name'])
        if stream then
            table.insert(sound_streams, stream)
        end
    end
	getLastUpdate()
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
-- ГОВНОКОД
-- ГОВНОКОД
-- ГОВНОКОД
imgui.OnFrame(function() return WinState[0] end, function(player)
    imgui.SetNextWindowPos(imgui.ImVec2(500, 500), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(506, 243), imgui.Cond.Always)
    imgui.Begin('##Window', WinState, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)

    if imgui.BeginChild('Menu', imgui.ImVec2(136, 208), false) then
        local buttonHeight = 22
        local totalButtonHeight = 8 * buttonHeight
        local startY = (185 - totalButtonHeight) / 2
        imgui.SetCursorPosY(startY)
        if imgui.GradientPB(tab == 1, fa.ICON_FA_HOME, 'ГЛАВНАЯ', 0.40) then tab = 1 end
        if imgui.GradientPB(tab == 2, fa.ICON_FA_COG, 'НАСТРОЙКИ', 0.40) then tab = 2 end
        if imgui.GradientPB(tab == 3, fa.ICON_FA_PAPER_PLANE, 'ТГ Уведы', 0.40) then tab = 3 end
        if imgui.GradientPB(tab == 4, fa.ICON_FA_BUG, 'ПОЛЕЗНОЕ', 0.40) then tab = 4 end
		if imgui.GradientPB(tab == 5, fa.ICON_FA_PALETTE, 'ЦВЕТА', 0.40) then tab = 5 end
        imgui.EndChild()
    end

    imgui.SameLine()

    if imgui.BeginChild('Function', imgui.ImVec2(360, 208), true) then
        if tab == 1 then
            imgui.Text('Добро пожалоавть!')
			imgui.Text('')
			imgui.Text('')
			imgui.Text('Скрипт ещё в разработке.')
			imgui.Text('По всем вопросам писать в дискорд koktic')
        elseif tab == 2 then
            imgui.SetNextItemWidth(144)if imgui.InputTextWithHint('Команда скрипта', '1', menu, 12) then end
			if imgui.Button('Сохранить настройки', imgui.ImVec2(137, 30)) then
                settings.main.menu = (str(menu))
                ini.save(settings, 'MiniHelper.ini')
                thisScript():reload()
            end
			imgui.Separator()
			if imgui.Checkbox('Звук о покупке/продаже чего-то в лавке', cr_sound) then
				settings.main.cr_sound = cr_sound[0]
				ini.save(settings, 'Minihelper.ini')
			end
			if imgui.Checkbox('Звук о продаже автомобиля', ab_sound) then
				settings.main.ab_sound = ab_sound[0]
				ini.save(settings, 'Minihelper.ini')
			end
			if imgui.Button('Тест звука', imgui.ImVec2(78, 25)) then
				playRandomSound()
			end
			imgui.Text('Громкость')
			imgui.SameLine()
			if imgui.SliderInt("##volume", volume, 0, 10) then
				if music ~= nil then setAudioStreamVolume(music, volume.v / 10) end
					settings.main.volume = volume[0]
					ini.save(settings, 'MiniHelper.ini')
			end
        elseif tab == 3 then
            imgui.Text('Telegram уведомления')
			if imgui.Checkbox('Разрешить уведомления', telergam_rabota) then
				settings.telegram.tg_active = telergam_rabota[0]
				ini.save(settings, 'Minihelper.ini')
			end
			imgui.SameLine()
			if imgui.Button('Настройка уведомлений') then
				imgui.OpenPopup('Settings')
			end
			if imgui.BeginPopupModal('Settings', _, imgui.WindowFlags.NoResize) then
				imgui.SetWindowSizeVec2(imgui.ImVec2(370, 318))
				imgui.Text('Уведомления')
				if imgui.Checkbox('Получать сообщения семьи     ', telergam_fam) then
					settings.telegram.tg_fam = telergam_fam[0]
					ini.save(settings, 'Minihelper.ini')
				end
				if imgui.Checkbox('Получать сообщения альянса', telergam_al) then
					settings.telegram.tg_al = telergam_al[0] 
					ini.save(settings, 'Minihelper.ini')
				end 				
				if imgui.Checkbox('Получать действия семьи', telegram_fas) then
					settings.telegram.tg_fas = telegram_fas[0]
					ini.save(settings, 'Minihelper.ini')
				end				
				if imgui.Checkbox('Получать уведомления о продаже/покупке в лавке', telegram_cr) then
					settings.telegram.tg_cr = telegram_cr[0] 
					ini.save(settings, 'Minihelper.ini')
				end
				if imgui.Checkbox('Получать уведомления о продаже транспорта', telegram_ab) then
					settings.telegram.tg_ab = telegram_ab[0]
					ini.save(settings, 'Minihelper.ini')
				end	
				if imgui.Checkbox('Получать уведомления с организационного чата', telegram_rab) then
					settings.telegram.tg_rab = telegram_rab[0]
					ini.save(settings, 'Minihelper.ini') 
				end
				if imgui.Checkbox('Получать уведомления о переводах', telegram_pay) then
					settings.telegram.tg_pay = telegram_pay[0]
					ini.save(settings, 'Minihelper.ini')
				end
				if imgui.Checkbox('Получать уведомления о упоминаниях', telegram_upom) then
					settings.telegram.tg_upom = telegram_upom[0]
					ini.save(settings, 'Minihelper.ini')
				end	
				if imgui.Button('Закрыть', imgui.ImVec2(130, 24)) then
					imgui.CloseCurrentPopup()
				end
				imgui.End()
			end
			imgui.Separator()
			imgui.SetNextItemWidth(234)if imgui.InputTextWithHint('##ID', 'ID', inputid, 256) then end imgui.SameLine() imgui.Text('Ваш ID')
			if imgui.IsItemHovered() then
				imgui.BeginTooltip()
				imgui.Text('Свой id вы можете получить у @my_id_bot')
				imgui.EndTooltip()
			end
			imgui.SetNextItemWidth(234)if imgui.InputTextWithHint('##TOKEN', 'TOKEN', inputtoken, 256) then end imgui.SameLine() imgui.Text('Ваш TOKEN')
			if imgui.IsItemHovered() then
				imgui.BeginTooltip()
				imgui.Text('Создать бота и получить его токен вы можете у @BotFather')
				imgui.EndTooltip()
			end
			if imgui.Button('Отправка тестового сообщения') then
				sendTelegramNotification(u8:decode(tag.. 'Скрипт работает\nДля того что бы начать им пользоваться напиши /help'))
			end
			if imgui.Button('Сохранить настройки', imgui.ImVec2(137, 30)) then
				settings.telegram.chat_id = (str(inputid))
				settings.telegram.token = (str(inputtoken))
				settings.telegram.tg_active = telergam_rabota[0]
				ini.save(settings, 'MiniHelper.ini')
				thisScript():reload()
			end
		elseif tab == 4 then
            imgui.SetNextItemWidth(144)if imgui.InputTextWithHint('Кастомный /dl', 'Команду', cdl, 12) then end
			if imgui.Button('Сохранить настройки', imgui.ImVec2(137, 30)) then
                settings.dop.castom_dl = (str(cdl))
                ini.save(settings, 'MiniHelper.ini')
                thisScript():reload()
            end
			if imgui.Checkbox('Авто. готовка мяса', autoCookEnabled) then
				if autoCookEnabled[0] and not cookThread then
					cookThread = lua_thread.create(function()
						while autoCookEnabled[0] do
							sampSendChat('/cook')
							wait(6000)
						end
					end)
				else
					if cookThread and not autoCookEnabled[0] then
						cookThread:terminate()
						cookThread = nil
					end
				end
			end
		elseif tab == 5 then
        if imgui.ColorEdit4('Цвет чата альянса', colorchat, imgui.ColorEditFlags.NoAlpha) then
			local clr = {colorchat[0], colorchat[1], colorchat[2], colorchat[3]}
			settings.color_chat = clr
			ini.save(settings, 'MiniHelper.ini')
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

    local result = imgui.InvisibleButton(text, size)
    if result and not bool then
        GradientPB[text].time = os.clock()
    end
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
    imgui.SetCursorPosY(imgui.GetCursorPos().y - 9)
    return result
end


function join_argb(a, r, g, b)
    local argb = b  -- b
    argb = bit.bor(argb, bit.lshift(g, 8))
    argb = bit.bor(argb, bit.lshift(r, 16))
    argb = bit.bor(argb, bit.lshift(a, 24))
    return argb
end

function intToHex(int)
    return '{'..string.sub(bit.tohex(int), 3, 8)..'}'
end

function explode_argb(argb)
  local a = bit.band(bit.rshift(argb, 24), 0xFF)
  local r = bit.band(bit.rshift(argb, 16), 0xFF)
  local g = bit.band(bit.rshift(argb, 8), 0xFF)
  local b = bit.band(argb, 0xFF)
  return a, r, g, b
end

function argb_to_rgba(argb)
  local a, r, g, b = explode_argb(argb)
  return join_argb(r, g, b, a)
end



function theme()
    imgui.SwitchContext()
    local ImVec4 = imgui.ImVec4

    imgui.GetStyle().WindowPadding = imgui.ImVec2(5, 5)
    imgui.GetStyle().FramePadding = imgui.ImVec2(5, 5)
    imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
    imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(2, 2)

    imgui.GetStyle().ScrollbarSize = 10
    imgui.GetStyle().GrabMinSize = 10

    imgui.GetStyle().WindowBorderSize = 1
    imgui.GetStyle().ChildBorderSize = 1
    imgui.GetStyle().FrameBorderSize = 1
    imgui.GetStyle().PopupBorderSize = 1
    imgui.GetStyle().TabBorderSize = 1

    imgui.GetStyle().WindowRounding = 10
    imgui.GetStyle().ChildRounding = 10
    imgui.GetStyle().FrameRounding = 10
    imgui.GetStyle().PopupRounding = 10
    imgui.GetStyle().ScrollbarRounding = 10
    imgui.GetStyle().GrabRounding = 10
    imgui.GetStyle().TabRounding = 10

    imgui.GetStyle().Colors[imgui.Col.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00) 
	imgui.GetStyle().Colors[imgui.Col.WindowBg]	      = imgui.ImVec4(0.10, 0.05, 0.20, 0.40) 
	imgui.GetStyle().Colors[imgui.Col.ChildBg]	      = imgui.ImVec4(0.15, 0.10, 0.25, 0.30) 
	imgui.GetStyle().Colors[imgui.Col.PopupBg] 	      = imgui.ImVec4(0.12, 0.05, 0.30, 0.50)
    imgui.GetStyle().Colors[imgui.Col.Border]                 = ImVec4(0.25, 0.25, 0.30, 0.30)
    imgui.GetStyle().Colors[imgui.Col.FrameBg]                = ImVec4(0.20, 0.20, 0.30, 1.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBgHovered]         = ImVec4(0.30, 0.30, 0.40, 1.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBgActive]          = ImVec4(0.35, 0.35, 0.45, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBg]                = ImVec4(0.10, 0.10, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBgActive]          = ImVec4(0.15, 0.15, 0.30, 0.70)
    imgui.GetStyle().Colors[imgui.Col.MenuBarBg]              = ImVec4(0.10, 0.10, 0.15, 0.50)
    imgui.GetStyle().Colors[imgui.Col.Button]                 = ImVec4(0.25, 0.25, 0.35, 0.76)
    imgui.GetStyle().Colors[imgui.Col.SliderGrab]             = ImVec4(0.30, 0.41, 0.99, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SliderGrabActive]       = ImVec4(0.30, 0.41, 0.99, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ButtonHovered]          = ImVec4(0.35, 0.35, 0.45, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ButtonActive]           = ImVec4(0.40, 0.40, 0.50, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Header]                 = ImVec4(0.20, 0.20, 0.30, 1.00)
    imgui.GetStyle().Colors[imgui.Col.HeaderHovered]          = ImVec4(0.30, 0.30, 0.40, 1.00)
    imgui.GetStyle().Colors[imgui.Col.HeaderActive]           = ImVec4(0.35, 0.35, 0.45, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarBg]            = ImVec4(0.10, 0.10, 0.15, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab]          = ImVec4(0.25, 0.25, 0.35, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Tab]                    = ImVec4(0.20, 0.20, 0.30, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabHovered]             = ImVec4(0.30, 0.30, 0.40, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabActive]              = ImVec4(0.35, 0.35, 0.45, 1.00)
end

imgui.OnInitialize(function()
    theme()
end)
	
