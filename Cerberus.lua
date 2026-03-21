script_version("v1.20")
script_name("Mini Helper")
local tag = "[Mini Helper] "

-- Адреса зашиты в скрипт (не редактируются в меню)
local TG_RELAY_URL = 'https://api.wh28240.web4.maze-tech.ru/tg-relay.php'

local imgui = require 'mimgui'
local fa = require('fAwesome5')

local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8
-- UTF-8 helpers: detect valid UTF-8 and convert from CP1251 only when needed
local function is_valid_utf8(s)
    if type(s) ~= 'string' then return false end
    local i = 1
    local n = #s
    while i <= n do
        local b = s:byte(i)
        if not b then return false end
        if b < 0x80 then
            i = i + 1
        elseif b >= 0xC2 and b <= 0xDF then
            if i + 1 > n then return false end
            local b2 = s:byte(i + 1)
            if not b2 or b2 < 0x80 or b2 > 0xBF then return false end
            i = i + 2
        elseif b >= 0xE0 and b <= 0xEF then
            if i + 2 > n then return false end
            local b2, b3 = s:byte(i + 1, i + 2)
            if not b2 or not b3 or b2 < 0x80 or b2 > 0xBF or b3 < 0x80 or b3 > 0xBF then return false end
            i = i + 3
        elseif b >= 0xF0 and b <= 0xF4 then
            if i + 3 > n then return false end
            local b2, b3, b4 = s:byte(i + 1, i + 3)
            if not b2 or not b3 or not b4 or b2 < 0x80 or b2 > 0xBF or b3 < 0x80 or b3 > 0xBF or b4 < 0x80 or b4 > 0xBF then return false end
            i = i + 4
        else
            return false
        end
    end
    return true
end

local function ensure_utf8(s)
    if type(s) ~= 'string' then return s end
    if is_valid_utf8(s) then return s end
    local ok, converted = pcall(u8, s)
    return (ok and converted) or s
end
local effil = require 'effil'
local ffi = require 'ffi'
local ev = require 'samp.events'
local new, str = imgui.new, ffi.string

-- Fallback: пока библиотека не загружена — выводим в чат через sampAddChatMessage
local notifications = {
    info = function(text, duration)
        sampAddChatMessage(u8:decode(text), -1)
    end
}
local ntf_loaded = false
pcall(function()
    local ntf = require("notifications")
    if ntf and ntf.info then
        notifications = ntf
        ntf_loaded = true
    end
end)

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
        tg_proxy_host = '',
        tg_proxy_port = '',
        tg_proxy_login = '',
        tg_proxy_password = '',
        tg_proxy = '',
        tg_use_server_config = false,
        tg_use_proxy = false,
        tg_active = false,
		tg_arenda = false,
		tg_fam = false,
		tg_al = false,
		tg_fas = false,
		tg_cr = false,
		tg_ab = false,
		tg_rab = false,
		tg_pay = false,
		tg_upom = false,
    },
	vkontakte = {
        vk_chat_id = '',
		vk_group_id = '',
        vk_token = '',
        vk_active = false,
		vk_arenda = false,
		vk_fam = false,
		vk_al = false,
		vk_fas = false,
		vk_cr = false,
		vk_ab = false,
		vk_rab = false,
		vk_pay = false,
		vk_upom = false,
    },
	color_chat = {1, 0, 0, 1},
	color_chat_fam = {0.32, 0.53, 0.94, 1},
    dop = {
        castom_dl = 'dl',
    },
}, 'MiniHelper.ini')

-- Защита от краша при старом INI без секций
if not settings.dop or not settings.dop.castom_dl then
    settings.dop = settings.dop or {}
    settings.dop.castom_dl = settings.dop.castom_dl or 'dl'
end
if not settings.vkontakte then
    settings.vkontakte = { vk_chat_id = '', vk_group_id = '', vk_token = '', vk_active = false, vk_fam = false, vk_al = false, vk_fas = false, vk_cr = false, vk_ab = false, vk_rab = false, vk_pay = false, vk_upom = false, vk_arenda = false }
end
if not settings.telegram then
    settings.telegram = { chat_id = '', token = '', tg_proxy_host = '', tg_proxy_port = '', tg_proxy_login = '', tg_proxy_password = '', tg_proxy = '', tg_use_server_config = false, tg_use_proxy = false, tg_active = false, tg_fam = false, tg_al = false, tg_fas = false, tg_cr = false, tg_ab = false, tg_rab = false, tg_pay = false, tg_upom = false, tg_arenda = false }
end
if settings.telegram and settings.telegram.tg_proxy_host == nil then
    settings.telegram.tg_proxy_host = ''
end
if settings.telegram and settings.telegram.tg_proxy_port == nil then
    settings.telegram.tg_proxy_port = ''
end
if settings.telegram and settings.telegram.tg_proxy_login == nil then
    settings.telegram.tg_proxy_login = ''
end
if settings.telegram and settings.telegram.tg_proxy_password == nil then
    settings.telegram.tg_proxy_password = ''
end
if settings.telegram and settings.telegram.tg_proxy == nil then
    settings.telegram.tg_proxy = ''
end
if settings.telegram and settings.telegram.tg_use_proxy == nil then
    settings.telegram.tg_use_proxy = false
end
if settings.telegram and settings.telegram.tg_use_server_config == nil then
    settings.telegram.tg_use_server_config = false
end
if not settings.main then
    settings.main = { menu = 'mhelp', cr_sound = false, ab_sound = false, volume = 2 }
end
if not settings.color_chat or type(settings.color_chat) ~= 'table' or #settings.color_chat ~= 4 then
    settings.color_chat = { 1, 0, 0, 1 }
end

--- Прокси TG: http://user:pass@host:port для ssl.https (строка tg_proxy — только совместимость со старым INI)
--- Режим «Сервер» (релей) и кастомный прокси не смешиваем — при включённом сервере локальный прокси для TG не используется.
local function getTelegramProxyUrl()
    local tg = settings.telegram
    if not tg then
        return ''
    end
    if tg.tg_use_server_config then
        return ''
    end
    if not tg.tg_use_proxy then
        return ''
    end
    local host = (tg.tg_proxy_host or ''):gsub('^%s+', ''):gsub('%s+$', '')
    local port_str = tostring(tg.tg_proxy_port or ''):gsub('^%s+', ''):gsub('%s+$', '')
    local port = tonumber(port_str)
    if host ~= '' and port and port >= 1 and port <= 65535 then
        local login = (tg.tg_proxy_login or ''):gsub('^%s+', ''):gsub('%s+$', '')
        local pass = (tg.tg_proxy_password or ''):gsub('^%s+', ''):gsub('%s+$', '')
        local function enc(s)
            return (tostring(s):gsub('[^%w%-._~]', function(c)
                return string.format('%%%02X', c:byte())
            end))
        end
        if login ~= '' and pass ~= '' then
            return string.format('http://%s:%s@%s:%d', enc(login), enc(pass), host, port)
        elseif login ~= '' then
            return string.format('http://%s@%s:%d', enc(login), host, port)
        else
            return string.format('http://%s:%d', host, port)
        end
    end
    local legacy = tg.tg_proxy or ''
    if type(legacy) == 'string' then
        legacy = legacy:gsub('^%s+', ''):gsub('%s+$', '')
        if legacy ~= '' then
            return legacy
        end
    end
    return ''
end

---ТГ ЛОКАЛ
local inputid = new.char[256](u8(settings.telegram.chat_id))
local inputtoken = new.char[256](u8(settings.telegram.token))
local inputproxyhost = new.char[256](u8(settings.telegram.tg_proxy_host or ''))
local inputproxyport = new.char[16](u8(tostring(settings.telegram.tg_proxy_port or '')))
local inputproxylogin = new.char[256](u8(settings.telegram.tg_proxy_login or ''))
local inputproxypass = new.char[256](u8(settings.telegram.tg_proxy_password or ''))
local telegram_rabota = new.bool(settings.telegram.tg_active)
local telegram_fam = new.bool(settings.telegram.tg_fam)
local telegram_arenda = new.bool(settings.telegram.tg_arenda)
local telegram_al = new.bool(settings.telegram.tg_al)
local telegram_fas = new.bool(settings.telegram.tg_fas)
local telegram_cr = new.bool(settings.telegram.tg_cr)
local telegram_ab = new.bool(settings.telegram.tg_ab)
local telegram_rab = new.bool(settings.telegram.tg_rab)
local telegram_pay = new.bool(settings.telegram.tg_pay)
local telegram_upom = new.bool(settings.telegram.tg_upom)
local telegram_use_proxy = new.bool(settings.telegram.tg_use_proxy == true)
local telegram_use_server = new.bool(settings.telegram.tg_use_server_config == true)
local updateid

local function fill_imgui_char_buf(buf, maxlen, text)
    text = tostring(text or '')
    ffi.fill(buf, maxlen, 0)
    if #text == 0 then return end
    local n = math.min(#text, maxlen - 1)
    ffi.copy(buf, text, n)
    local bytes = ffi.cast('uint8_t*', buf)
    bytes[n] = 0
end

---ВК ЛОКАЛ
local vkinputid = new.char[256](u8(settings.vkontakte.vk_chat_id))
local vkgroupid = new.char[256](u8(settings.vkontakte.vk_group_id))
local vkinputtoken = new.char[256](u8(settings.vkontakte.vk_token))
local vkontakte_rabota = new.bool(settings.vkontakte.vk_active)
local vkontakte_fam = new.bool(settings.vkontakte.vk_fam)
local vkontakte_arenda = new.bool(settings.vkontakte.vk_arenda)
local vkontakte_al = new.bool(settings.vkontakte.vk_al)
local vkontakte_fas = new.bool(settings.vkontakte.vk_fas)
local vkontakte_cr = new.bool(settings.vkontakte.vk_cr)
local vkontakte_ab = new.bool(settings.vkontakte.vk_ab)
local vkontakte_rab = new.bool(settings.vkontakte.vk_rab)
local vkontakte_pay = new.bool(settings.vkontakte.vk_pay)
local vkontakte_upom = new.bool(settings.vkontakte.vk_upom)
local vk_server, vk_key, vk_ts
local vk_bot_state = "main"
local vk_pending_messages = {}
--ПОЛЕЗНОЕ
local autoCookEnabled = new.bool(false)
local cookThread = nil

--ЦВЕТА
local colorchat = imgui.new.float[4](settings.color_chat)
local colorchat_fam = imgui.new.float[4](settings.color_chat_fam)

---Основаня часть
local menu = new.char[12](settings.main.menu)
local cr_sound = new.bool(settings.main.cr_sound == true)
local ab_sound = new.bool(settings.main.ab_sound == true)
local volume = imgui.new.int(settings.main.volume)

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
        url = 'https://raw.githubusercontent.com/koktic/helper/refs/heads/main/items_num.lua',
        file_name = 'items_num.lua',
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
    imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/MiniHelper/fAwesome5.ttf', 17.0, config, iconRanges)

end)


---ДЛЯ РАБОТЫ С ТГ
local function telegramLog(msg, is_error)
    local text = tag .. '[TG] ' .. tostring(msg)
    print(text)
    if isSampAvailable() then
        pcall(function()
            sampAddChatMessage(u8:decode(text), -1)
        end)
    end
    if is_error and notifications and notifications.error then
        pcall(function()
            notifications.error(u8:decode(text), 7000)
        end)
    end
end

function requestRunner()
    return effil.thread(function(u, a, proxy)
        local https = require 'ssl.https'
        local ltn12 = require 'ltn12'
        local socket = require 'socket'
        local ok, result = pcall(function()
            -- LuaSec ssl.https явно запрещает url.proxy — только прямой HTTPS.
            -- Через HTTP-прокси: CONNECT → TLS → HTTP (RFC 7231).
            local function https_via_http_proxy(proxy_url, target_url, body_str)
                local socket = require('socket')
                local ssl = require('ssl')
                local surl = require('socket.url')
                local mime = require('mime')

                local tu = surl.parse(target_url, { scheme = 'https', port = 443 })
                if not tu.host or tu.host == '' then
                    error('invalid HTTPS URL')
                end
                local thost = tu.host
                local tport = tonumber(tu.port) or 443
                local path = tu.path or '/'
                if tu.query and tu.query ~= '' then
                    path = path .. '?' .. tu.query
                end
                if path:sub(1, 1) ~= '/' then
                    path = '/' .. path
                end

                local pu = surl.parse(proxy_url)
                if not pu.host or pu.host == '' then
                    error('invalid proxy URL')
                end
                local phost = pu.host
                local pport = tonumber(pu.port) or 80
                local puser, ppass = pu.user, pu.password

                local tcp = socket.tcp()
                tcp:settimeout(90)
                local cok, cerr = tcp:connect(phost, pport)
                if not cok then
                    error('прокси connect: ' .. tostring(cerr))
                end

                local auth_line = ''
                if puser and puser ~= '' then
                    auth_line = 'Proxy-Authorization: Basic ' .. mime.b64(puser .. ':' .. (ppass or '')) .. '\r\n'
                end
                local conn_req = string.format(
                    'CONNECT %s:%d HTTP/1.1\r\nHost: %s:%d\r\n%s\r\n',
                    thost, tport, thost, tport, auth_line
                )
                local sok, serr = tcp:send(conn_req)
                if not sok then
                    tcp:close()
                    error('CONNECT send: ' .. tostring(serr))
                end

                local line = tcp:receive('*l')
                if not line then
                    tcp:close()
                    error('CONNECT: нет ответа')
                end
                if not line:find('200') then
                    local buf = line
                    repeat
                        line = tcp:receive('*l')
                        if not line then break end
                        buf = buf .. '\n' .. line
                    until line == ''
                    tcp:close()
                    error('CONNECT: ' .. buf)
                end
                repeat
                    line = tcp:receive('*l')
                    if line == nil then break end
                until line == ''

                local ssl_params = {
                    mode = 'client',
                    protocol = 'any',
                    options = { 'all', 'no_sslv2', 'no_sslv3' },
                    verify = 'none',
                }
                local ssock = ssl.wrap(tcp, ssl_params)
                ssock:sni(thost)
                local dh_ok, dh_err = ssock:dohandshake()
                if not dh_ok then
                    ssock:close()
                    error('TLS: ' .. tostring(dh_err))
                end

                local post_body = body_str and body_str ~= ''
                local method = post_body and 'POST' or 'GET'
                local hdr = method .. ' ' .. path .. ' HTTP/1.1\r\n'
                hdr = hdr .. 'Host: ' .. thost .. '\r\n'
                hdr = hdr .. 'Connection: close\r\n'
                hdr = hdr .. 'User-Agent: MoonLoader\r\n'
                if post_body then
                    local ct = 'application/x-www-form-urlencoded'
                    if body_str:sub(1, 1) == '{' then
                        ct = 'application/json; charset=utf-8'
                    end
                    hdr = hdr .. 'Content-Type: ' .. ct .. '\r\n'
                    hdr = hdr .. 'Content-Length: ' .. tostring(#body_str) .. '\r\n'
                end
                hdr = hdr .. '\r\n'
                local payload = hdr .. (post_body and body_str or '')
                local send_ok, send_err = ssock:send(payload)
                if not send_ok then
                    ssock:close()
                    error('HTTP send: ' .. tostring(send_err))
                end

                local status_line = ssock:receive('*l')
                if not status_line then
                    ssock:close()
                    error('HTTP: нет статуса')
                end
                local http_code = tonumber(status_line:match('^HTTP/%d*%.%d* (%d%d%d)'))
                local content_length
                repeat
                    line = ssock:receive('*l')
                    if line == nil then break end
                    if line == '' then break end
                    local clow = line:lower()
                    if clow:find('^content%-length:') then
                        content_length = tonumber(line:match(':%s*(%d+)'))
                    end
                until line == ''

                local body
                if content_length and content_length > 0 then
                    body = ssock:receive(content_length)
                else
                    body = ssock:receive('*a')
                end
                ssock:close()
                if not body then
                    body = ''
                end
                if http_code and http_code >= 400 then
                    error('HTTP ' .. tostring(http_code) .. ' ' .. tostring(status_line))
                end
                return body
            end

            local function apply_telegram_api_check(body)
                if body ~= '' and body:sub(1, 1) == '{' then
                    local ok_j, data = pcall(decodeJson, body)
                    if ok_j and type(data) == 'table' and data.ok == false then
                        error(tostring(data.description or data.error or data.error_code or 'Telegram API: ok=false'))
                    elseif not ok_j and (body:find('"ok"%s*:%s*false') or body:find('"ok":false')) then
                        local desc = body:match('"description"%s*:%s*"([^"]*)"')
                        error(desc or 'Telegram API: ok=false')
                    end
                end
                return body
            end

            local p = proxy
            if type(p) == 'string' then
                p = p:gsub('^%s+', ''):gsub('%s+$', '')
            end

            local body
            if p and p ~= '' then
                body = https_via_http_proxy(p, u, a or '')
                apply_telegram_api_check(body)
                return body
            end

            local max_https = 4
            for attempt = 1, max_https do
                local chunks = {}
                local req = {
                    url = u,
                    sink = ltn12.sink.table(chunks),
                }
                if a and a ~= '' then
                    req.method = 'POST'
                    req.source = ltn12.source.string(a)
                    req.headers = req.headers or {}
                    if a:sub(1, 1) == '{' then
                        req.headers['content-type'] = 'application/json; charset=utf-8'
                    else
                        req.headers['content-type'] = 'application/x-www-form-urlencoded'
                    end
                    req.headers['content-length'] = tostring(#a)
                end
                local res, code, headers, status = https.request(req)
                body = table.concat(chunks)
                if res then
                    if type(code) == 'number' and code >= 400 then
                        local tail = (body ~= '' and body:sub(1, 500)) or ''
                        if tail ~= '' then
                            tail = ' | ' .. tail
                        end
                        error('HTTP ' .. tostring(code) .. ' ' .. tostring(status or '') .. tail)
                    end
                    apply_telegram_api_check(body)
                    return body
                end
                local err = tostring(code or 'https.request failed')
                local el = err:lower()
                local transient = el:find('closed', 1, true) or el:find('timeout', 1, true)
                    or el:find('reset', 1, true) or el:find('broken pipe', 1, true)
                    or el:find('want read', 1, true) or el:find('want write', 1, true)
                if not transient or attempt == max_https then
                    error(err .. (body ~= '' and (' | ' .. body:sub(1, 400)) or ''))
                end
                socket.sleep(0.2 * attempt)
            end
        end)
        if ok then
            return {true, result}
        else
            return {false, result}
        end
    end)
end

function threadHandle(runner, url, args, resolve, reject, proxy)
	local t = runner(url, args, proxy)
	local r = t:get(0)
	while not r do
		r = t:get(0)
		wait(0)
	end
    local status = t:status()
    if status == 'completed' then
        local ok, result = r[1], r[2]
        if ok then resolve(result) else reject(result) end
    elseif status == 'canceled' then
        reject(status)
    else
        reject(tostring(status or 'effil thread'))
    end
    t:cancel(0)
end

function async_http_request(url, args, resolve, reject)
    local runner = requestRunner()
    if not reject then
        reject = function(err)
            print(tag .. '[TG] ' .. tostring(err))
        end
    end
    local req_url, req_args = apply_telegram_site_relay(url, args)
    local proxy = getTelegramProxyUrl()
    if get_telegram_site_relay_url() ~= '' then
        proxy = ''
    end
    lua_thread.create(function()
        threadHandle(runner, req_url, req_args, resolve, reject, proxy)
    end)
end

function encodeUrl(str, alreadyUtf8)
    str = str:gsub(' ', '%+')
    str = str:gsub('\n', '%%0A')
    return alreadyUtf8 and str or u8(str)
end

--- Релей: запросы на api.telegram.org идут POST на ваш tg-relay.php (сервер сам ходит в Telegram).
function url_encode_form_component(s)
    s = tostring(s or '')
    return (s:gsub('([^%w%-%.%_~])', function(c)
        return string.format('%%%02X', string.byte(c, 1))
    end))
end

function get_telegram_site_relay_url()
    if settings.telegram and settings.telegram.tg_use_server_config then
        return TG_RELAY_URL
    end
    return ''
end

--- Только ASCII hex — PHP hex2bin, без поломки UTF-8/кавычек в JSON
local function hex_encode_url_for_relay(s)
    s = tostring(s)
    local t = {}
    for i = 1, #s do
        t[#t + 1] = string.format('%02X', s:byte(i))
    end
    return table.concat(t)
end

function apply_telegram_site_relay(direct_url, orig_args)
    if type(direct_url) ~= 'string' or not direct_url:find('^https://api%.telegram%.org/') then
        return direct_url, orig_args
    end
    if get_telegram_site_relay_url() == '' then return direct_url, orig_args end
    return get_telegram_site_relay_url(), '{"hex":"' .. hex_encode_url_for_relay(direct_url) .. '"}'
end

local items_names = {}
local function loadItemsData()
    local path = getWorkingDirectory() .. "\\MiniHelper\\items_num.lua"
    if doesFileExist(path) then
        local chunk, err = loadfile(path)
        if chunk then
            local ok, data = pcall(chunk)
            if ok and data and type(data) == "table" then
                items_names = data
                return
            end
        end
    end
end

local function replaceItemCodes(text)
    if not text or type(text) ~= "string" then return text end
    return text:gsub(":item(%d+):", function(id)
        local num = tonumber(id)
        local name = (num and items_names[num]) or items_names[id] or (":item" .. id .. ":")
        -- convert only the replacement (item name) to UTF-8 if possible to avoid breaking the rest of the message
        return ensure_utf8(tostring(name))
    end)
end

function sendTelegramNotification(msg, keyboard)
    if not settings.telegram.tg_active then
        return
    end
    local tok = tostring(settings.telegram.token or ''):gsub('%s+', '')
    local cid = tostring(settings.telegram.chat_id or ''):gsub('%s+', '')
    if tok == '' or cid == '' then
        telegramLog('Заполните TOKEN и ID (chat_id), сохраните настройки.', true)
        return
    end

    msg = u8(msg)
    msg = replaceItemCodes(msg)
    msg = msg:gsub('{......}', '')
    msg = encodeUrl(msg, true)
    
    local reply_markup = keyboard or '{"keyboard": [["👤 Статистика"], ["💬 | Семейный чат", "📝 Команды"]] , "resize_keyboard": true}'
    
    async_http_request('https://api.telegram.org/bot' .. tok .. '/sendMessage?chat_id=' .. cid .. '&reply_markup=' .. reply_markup .. '&text='..msg, '', function(result)
    end, function(err)
        telegramLog(tostring(err), true)
    end)
end

local function sendTelegramMessageTo(chat_id, msg, keyboard)
    if not settings.telegram.tg_active then
        return
    end
    if not chat_id or tostring(chat_id) == '' then
        return
    end

    msg = u8(msg)
    msg = replaceItemCodes(msg)
    msg = msg:gsub('{......}', '')
    msg = encodeUrl(msg, true)

    local reply_markup = keyboard or '{"remove_keyboard": true}'
    local tok2 = tostring(settings.telegram.token or ''):gsub('%s+', '')
    async_http_request('https://api.telegram.org/bot' .. tok2 .. '/sendMessage?chat_id=' .. tostring(chat_id) .. '&reply_markup=' .. reply_markup .. '&text=' .. msg, '', function(result)
    end, function(err)
        telegramLog(tostring(err), true)
    end)
end

-- TG: как в Cerberus (1) — только чат из настроек (chat_id = id ЛС с ботом)
local function isAuthorizedTelegramUser(msg)
    if not msg or not msg.chat then
        return false
    end
    local cid = msg.chat and tostring(msg.chat.id):gsub('%s+', '') or ''
    local want = tostring(settings.telegram.chat_id or ''):gsub('%s+', '')
    if cid == '' or want == '' or cid ~= want then
        return false
    end
    return true
end

function get_telegram_updates()
    while not updateid do wait(1) end
    local runner = requestRunner()
    local reject = function(err)
        print(tag .. '[TG] getUpdates: ' .. tostring(err))
    end
    local args = ''
    while true do
        local offset = (updateid and (updateid + 1)) or 1
        local tok_gu = tostring(settings.telegram.token or ''):gsub('%s+', '')
        local url = 'https://api.telegram.org/bot'..tok_gu..'/getUpdates?offset='..tostring(offset)..'&timeout=25'
        local req_url, req_args = apply_telegram_site_relay(url, args)
        local proxy = getTelegramProxyUrl()
        if get_telegram_site_relay_url() ~= '' then
            proxy = ''
        end
        threadHandle(runner, req_url, req_args, processing_telegram_messages, reject, proxy)
        wait(0)
    end
end

local bot_state = "main"

function processing_telegram_messages(result, arg)
    if not result or result == '' then return end
    local ok_decode, proc_table = pcall(decodeJson, result)
    if not ok_decode or not proc_table or not proc_table.ok or not proc_table.result then return end
    local Id = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
    local Money = getPlayerMoney()
    local Name = sampGetPlayerNickname(Id)
    local ping = sampGetPlayerPing(Id)
    local Lvl = sampGetPlayerScore(Id)
    local connect = sampGetGamestate()
    for i = 1, #proc_table.result do
        local res_table = proc_table.result[i]
        if res_table and res_table.update_id then
            updateid = res_table.update_id
            local msg = res_table.message
            if not msg or not msg.text then goto continue end
            if not isAuthorizedTelegramUser(msg) then
                goto continue
            end
            local message_from_user = msg.text
            local text = (message_from_user) .. ' '
							if bot_state == "main" then
								if text:match('Test') then
									sendTelegramNotification('Бот Работает!')
								elseif text:match('^/help') or text:match('^📝 Команды') then
									sendTelegramNotification(u8:decode'Мои команды:\n/fam {text} - писать в чат семьи\n/al {text} - писать в чат альянса\n/rb {text} - писать в НРП чат фракции\n/pcoff - выключить пк через 15 секунд\n/m - отправить сообщение в чат') 	
								elseif text:match('^/rb') then
									local arg = text:gsub(u8:decode'/rb ','/rb ',1)
									sampSendChat(u8:decode(arg))
								elseif text:match('^/fam') then
									local arg = text:gsub('/fam ','/fam ',1)
									sampSendChat(u8:decode(arg))
								elseif text:match('^💬 | Семейный чат') then
									bot_state = "fam"
									sendTelegramNotification(u8:decode"Введите сообщение:", '{"keyboard": [["❌Отмена"]], "resize_keyboard": true}')
								elseif text:match('^/al') then
									local arg = text:gsub('/al ','/al ',1)
									sampSendChat(u8:decode(arg))	
								elseif text:match('^/m') then
									local arg = text:gsub('/m ','',1)
									sampSendChat(u8:decode(arg))
								elseif text:match('^/pcoff') then
									sendTelegramNotification(u8:decode(tag ..'Ваш ПК будет выключен через 15 секунд'))
									os.execute('shutdown -s /f /t 15')  
								elseif text:match('^/stats') or text:match('^👤 Статистика') then
								    local stateText = "Неизвестно"
                                    if connect == 0 then stateText = "🔴Нет состояния"
                                    elseif connect == 1 then stateText = "🔄Ожидание подключения"
                                    elseif connect == 2 then stateText = "🔄Ожидание присоединения"
                                    elseif connect == 3 then stateText = "🟢В игре"
                                    elseif connect == 4 then stateText = "🔄Переподключение"
                                    elseif connect == 5 then stateText = "🔴Отключен" end
									sendTelegramNotification(u8:decode(separator('Ник: '..Name..'\nДеньги: $'..Money..'\nПинг: '..ping..'\nИд: '..Id..'\nУровень: '..Lvl..'\n\nСтатус игры: '..stateText..'\n')))
                                else
                                    sendTelegramNotification(u8:decode'Неизвестная команда!')
                                end
                            elseif bot_state == "fam" then
                                if text:match('^❌Отмена') then
                                    bot_state = "main"
                                    sendTelegramNotification(u8:decode'Возврат в главное меню')
                                else
                                    sampSendChat(u8:decode('/fam ' .. text))
                                    sendTelegramNotification(u8:decode'Сообщение отправлено!')
                                    bot_state = "main"
                                end
                            end
            ::continue::
        end
    end
end

function getLastUpdate()
    local tok_gl = tostring(settings.telegram.token or ''):gsub('%s+', '')
    async_http_request('https://api.telegram.org/bot'..tok_gl..'/getUpdates?offset=-1&limit=1', '', function(result)
        if result then
            local ok_j, proc_table = pcall(decodeJson, result)
            if ok_j and proc_table and proc_table.ok then
                if proc_table.result and #proc_table.result > 0 then
                    updateid = proc_table.result[#proc_table.result].update_id
                else
                    updateid = 1
                end
            else
                updateid = 1
            end
        else
            updateid = 1
        end
    end, function(err)
        print(tag .. '[TG] getLastUpdate: ' .. tostring(err))
        updateid = 1
    end)
end
-- ДЛЯ РАБОТЫ С ВК
function requestRunner1()
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

function threadHandle1(runner, url, args, resolve, reject)
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
    elseif status == 'canceled' then
        reject(status)
    else
        reject(tostring(status or 'effil thread'))
    end
    t:cancel(0)
end

function async_http_request1(url, args, resolve, reject)
    local runner = requestRunner1()
    if not reject then reject = function() end end
    lua_thread.create(function()
        threadHandle1(runner, url, args, resolve, reject)
    end)
end

function encodeUrl1(str)
    if not str or str == '' then return '' end
    str = tostring(str)
    -- helper: check if string is valid UTF-8
    local function is_valid_utf8(s)
        local i = 1
        local n = #s
        while i <= n do
            local b = s:byte(i)
            if not b then return false end
            if b < 0x80 then
                i = i + 1
            elseif b >= 0xC2 and b <= 0xDF then
                -- 2-byte sequence
                if i + 1 > n then return false end
                local b2 = s:byte(i + 1)
                if not b2 or b2 < 0x80 or b2 > 0xBF then return false end
                i = i + 2
            elseif b >= 0xE0 and b <= 0xEF then
                -- 3-byte sequence
                if i + 2 > n then return false end
                local b2, b3 = s:byte(i + 1, i + 2)
                if not b2 or not b3 or b2 < 0x80 or b2 > 0xBF or b3 < 0x80 or b3 > 0xBF then return false end
                i = i + 3
            elseif b >= 0xF0 and b <= 0xF4 then
                -- 4-byte sequence
                if i + 3 > n then return false end
                local b2, b3, b4 = s:byte(i + 1, i + 3)
                if not b2 or not b3 or not b4 or b2 < 0x80 or b2 > 0xBF or b3 < 0x80 or b3 > 0xBF or b4 < 0x80 or b4 > 0xBF then return false end
                i = i + 4
            else
                return false
            end
        end
        return true
    end

    -- ensure string is UTF-8 (convert from CP1251 using u8 if it's not valid UTF-8)
    local function ensure_utf8(s)
        if type(s) ~= 'string' then return s end
        if is_valid_utf8(s) then return s end
        local ok, converted = pcall(u8, s)
        return (ok and converted) or s
    end

    str = ensure_utf8(str)
    local result = {}
    for i = 1, #str do
        local b = str:byte(i)
        if (b >= 48 and b <= 57) or (b >= 65 and b <= 90) or (b >= 97 and b <= 122) or b == 45 or b == 95 or b == 46 or b == 126 then
            result[#result + 1] = string.char(b)
        elseif b == 32 then
            result[#result + 1] = '+'
        else
            result[#result + 1] = string.format('%%%02X', b)
        end
    end
    return table.concat(result)
end

function sendVkontakteNotification(msg, keyboard)
    if not settings.vkontakte or not settings.vkontakte.vk_active then
        return
    end
    if not settings.vkontakte.vk_token or settings.vkontakte.vk_token == '' then return end
    if not settings.vkontakte.vk_chat_id or settings.vkontakte.vk_chat_id == '' then return end

    msg = tostring(msg)
    msg = ensure_utf8(msg)
    local ok, replaced = pcall(replaceItemCodes, msg)
    msg = (ok and replaced) or msg
    msg = msg:gsub('{......}', '')
    local encoded_msg = encodeUrl1(msg)

    local random_id = math.floor(os.clock() * 1000) + math.random(1, 99999)
    local url = 'https://api.vk.com/method/messages.send?peer_id=' .. encodeUrl1(settings.vkontakte.vk_chat_id) ..
        '&random_id=' .. random_id ..
        '&message=' .. encoded_msg ..
        '&access_token=' .. encodeUrl1(settings.vkontakte.vk_token) ..
        '&v=5.199'
    async_http_request1(url, '', function(result)
        if result and result:find('"error"') then
            local ok, err_data = pcall(decodeJson, result)
            if ok and err_data and err_data.error then
                local code = err_data.error.error_code or 0
                local msg_err = err_data.error.error_msg or ''
                if code == 901 then
                    notifications.error(u8:decode'[VK] Нельзя писать пользователю: он ещё не писал сообществу. Напиши боту в ЛС группы любое сообщение (например Test), затем попробуй снова.', 7000)
                elseif code == 902 then
                    notifications.error(u8:decode'[VK] В чат группы писать нельзя — укажи в настройках свой ID (куда слать в личку).', 7000)
                elseif code == 15 then
                    notifications.error(u8:decode'[VK] Нет доступа: проверь токен сообщества и права (Сообщения сообщества).', 7000)
                else
                    notifications.error(u8:decode('[VK] Ошибка ' .. tostring(code) .. ': ' .. tostring(msg_err):sub(1, 60)), 7000)
                end
            else
                notifications.error(u8:decode'[VK] Ошибка отправки. Проверь токен и ID получателя.', 7000)
            end
        end
    end)
end

local function sendVkontakteMessageTo(peer_id, msg)
    if not settings.vkontakte or not settings.vkontakte.vk_active then
        return
    end
    if not settings.vkontakte.vk_token or settings.vkontakte.vk_token == '' then return end
    if not peer_id or tostring(peer_id) == '' then return end

    msg = tostring(msg)
    msg = ensure_utf8(msg)
    local ok, replaced = pcall(replaceItemCodes, msg)
    msg = (ok and replaced) or msg
    msg = msg:gsub('{......}', '')
    local encoded_msg = encodeUrl1(msg)

    local random_id = math.floor(os.clock() * 1000) + math.random(1, 99999)
    local url = 'https://api.vk.com/method/messages.send?peer_id=' .. encodeUrl1(peer_id) ..
        '&random_id=' .. random_id ..
        '&message=' .. encoded_msg ..
        '&access_token=' .. encodeUrl1(settings.vkontakte.vk_token) ..
        '&v=5.199'
    async_http_request1(url, '', function(result)
    end)
end

-- VK: как в Cerberus (1) — при непустом vk_chat_id: peer_id или from_id должен совпадать
local function isAuthorizedVkontakteUser(message)
    if type(message) ~= 'table' then
        return false
    end
    local want = tostring(settings.vkontakte.vk_chat_id or ''):gsub('%s+', '')
    if want == '' then
        return true
    end
    local p = tostring(message.peer_id or ''):gsub('%s+', '')
    local f = tostring(message.from_id or ''):gsub('%s+', '')
    return p == want or f == want
end

function getLongPollServerVK()
    if not settings.vkontakte.vk_group_id or not settings.vkontakte.vk_token then return end
    local url = 'https://api.vk.com/method/groups.getLongPollServer?group_id=' .. encodeUrl1(settings.vkontakte.vk_group_id) ..
        '&access_token=' .. encodeUrl1(settings.vkontakte.vk_token) .. '&lp_version=3&v=5.199'
    async_http_request1(url, '', function(result)
        if not result then return end
        local ok, data = pcall(decodeJson, result)
        if ok and data and data.response then
            vk_server = data.response.server
            vk_key = data.response.key
            vk_ts = tostring(data.response.ts)
        elseif data and data.error then
            sampAddChatMessage('[VK] Ошибка LongPoll: ' .. tostring(data.error.error_msg or data.error), -1)
        end
    end)
end

function initVK()
    if not settings.vkontakte.vk_group_id or not settings.vkontakte.vk_token then return end
    local url = 'https://api.vk.com/method/groups.getLongPollServer?group_id=' .. encodeUrl1(settings.vkontakte.vk_group_id) ..
        '&access_token=' .. encodeUrl1(settings.vkontakte.vk_token) .. '&lp_version=3&v=5.199'
    async_http_request1(url, '', function(result)
        if not result then
            sampAddChatMessage(u8:decode'[VK] Нет ответа от сервера при инициализации.', -1)
            return
        end
        local ok, data = pcall(decodeJson, result)
        if ok and data and data.response then
            vk_server = data.response.server
            vk_key = data.response.key
            vk_ts = tostring(data.response.ts)
            lua_thread.create(get_vkontakte_updates)
            lua_thread.create(vk_process_pending_messages)
        else
            if data and data.error then
                local errmsg = data.error.error_msg or tostring(data.error)
                sampAddChatMessage(u8:decode'[VK] Ошибка: ' .. tostring(errmsg), -1)
            else
                sampAddChatMessage(u8:decode'[VK] Ошибка инициализации (проверь ID группы и токен).', -1)
            end
        end
    end)
end

function vk_process_pending_messages()
    while true do
        if #vk_pending_messages > 0 then
            local item = table.remove(vk_pending_messages, 1)
            if item then
                if type(item) == 'string' then
                    pcall(processing_vkontakte_messages, { text = item })
                else
                    pcall(processing_vkontakte_messages, item)
                end
            end
        end
        wait(0)
    end
end

-- Проверка кнопки ВК: текст из ВК в UTF-8, литерал в скрипте в CP1251 -> u8() даёт UTF-8 для сравнения
local function vk_btn(text, btn)
    local ok, utf8_btn = pcall(u8, btn)
    if not ok or not utf8_btn then return false end
    local t = text:gsub('^%s+', ''):gsub('%s+$', '')
    return t == utf8_btn or t:sub(1, #utf8_btn) == utf8_btn or t:find(utf8_btn, 1, true) == 1
end

function processing_vkontakte_messages(message)
    if not message then return end
    if type(message) == 'string' then
        message = { text = message }
    end

    local text = message.text
    if not text or text == '' then return end
    if not isAuthorizedVkontakteUser(message) then
        return
    end
    -- Убираем префикс кнопки ВК (например "| Семейный чат" или " | Команды")
    text = text:gsub('^%s*|%s*', ''):gsub('^%s+', ''):gsub('%s+$', '')
    text = text .. ' '
    if not isSampAvailable() then return end
    local _, Id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    if not Id then return end
    local Money = getPlayerMoney()
    local Name = sampGetPlayerNickname(Id)
    local ping = sampGetPlayerPing(Id)
    local Lvl = sampGetPlayerScore(Id)
    local connect = sampGetGamestate()
    if vk_bot_state == "main" then
        if text:match('Test') or text:match('^/test') then
            sendVkontakteNotification('Бот Работает!')
        elseif text:match('^/help') or text:match('^📝 Команды') or text:match('^%s*Команды') or vk_btn(text, 'Команды') then
            sendVkontakteNotification(u8:decode'Мои команды:\n/stats или Статистика - статистика\n/fam или Семейный чат - в чат семьи\n/help или Команды - этот список\n/al {text} - в чат альянса\n/rb {text} - НРП чат фракции\n/pcoff - выключить ПК\n/m {text} - в чат')
        elseif text:match('^/rb') then
            local arg = text:gsub(u8:decode'/rb ', '/rb ', 1)
            sampSendChat(u8:decode(arg))
        elseif vk_btn(text, 'Семейный чат') or text:match('^%s*Семейный') or text:match('^💬') then
            vk_bot_state = "fam"
            sendVkontakteNotification(u8:decode"Введите сообщение (или напиши Отмена):")
        elseif text:match('^/fam') then
            local arg = text:gsub('/fam ', '/fam ', 1)
            sampSendChat(u8:decode(arg))
        elseif text:match('^/al') then
            local arg = text:gsub('/al ', '/al ', 1)
            sampSendChat(u8:decode(arg))
        elseif text:match('^/m') then
            local arg = text:gsub('/m ', '', 1)
            sampSendChat(u8:decode(arg))
        elseif text:match('^/pcoff') then
            sendVkontakteNotification(u8:decode(tag .. 'Ваш ПК будет выключен через 15 секунд'))
            os.execute('shutdown -s /f /t 15')
        elseif text:match('^/stats') or text:match('^👤 Статистика') or text:match('^%s*Статистика') or vk_btn(text, 'Статистика') then
            local stateText = "Неизвестно"
            if connect == 0 then stateText = "🔴Нет состояния"
            elseif connect == 1 then stateText = "🔄Ожидание подключения"
            elseif connect == 2 then stateText = "🔄Ожидание присоединения"
            elseif connect == 3 then stateText = "🟢В игре"
            elseif connect == 4 then stateText = "🔄Переподключение"
            elseif connect == 5 then stateText = "🔴Отключен" end
            sendVkontakteNotification(u8:decode(separator('Ник: '..Name..'\nДеньги: $'..Money..'\nПинг: '..ping..'\nИд: '..Id..'\nУровень: '..Lvl..'\n\nСтатус игры: '..stateText..'\n')))
        else
            sendVkontakteNotification(u8:decode'Неизвестная команда!')
        end
    elseif vk_bot_state == "fam" then
        if text:match('^❌Отмена') or text:match('^%s*Отмена') or vk_btn(text, 'Отмена') then
            vk_bot_state = "main"
            sendVkontakteNotification(u8:decode'Возврат в главное меню')
        else
            sampSendChat(u8:decode('/fam ' .. text))
            sendVkontakteNotification(u8:decode'Сообщение отправлено!')
            vk_bot_state = "main"
        end
    end
end

function get_vkontakte_updates()
    while not vk_server or not vk_key or not vk_ts do wait(1) end
    local runner = requestRunner1()

    while true do
        local host = (vk_server and vk_server:match('^https?://')) and vk_server or ('https://' .. tostring(vk_server))
        local url = host .. (host:find('?') and '&' or '?') .. 'act=a_check&key=' .. vk_key .. '&ts=' .. vk_ts .. '&wait=3'
        threadHandle1(runner, url, '', function(result)
            if not result or result == '' then return end
            local ok, data = pcall(decodeJson, result)
            if not ok or not data then return end
            if data.failed then
                if data.failed == 2 or data.failed == 3 then
                    getLongPollServerVK()
                elseif data.failed == 1 and data.ts then
                    vk_ts = tostring(data.ts)
                end
                return
            end
            if data.ts then
                vk_ts = tostring(data.ts)
            end
            if not data.updates or #data.updates == 0 then return end
            for _, update in ipairs(data.updates) do
                local etype = (type(update.type) == 'string' and update.type:lower()) or update[1] or update["1"]
                -- Обрабатываем только входящие сообщения (message_new или событие 4), не ответы бота и не прочитано/набор
                if etype ~= 'message_new' and etype ~= 4 and etype ~= '4' then
                    goto skip_update
                end
                local msg_text = ''
                local peer_id, from_id
                if etype == 4 or etype == '4' then
                    msg_text = tostring(update[7] or update["7"] or update[6] or update["6"] or ''):gsub('^%s+', ''):gsub('%s+$', '')
                    -- Long Poll: [1]=type, [2]=msg_id, [3]=flags, [4]=peer_id (часто)
                    peer_id = tonumber(update[4] or update["4"] or update[3] or update["3"] or 0) or 0
                    from_id = peer_id
                else
                    local obj = update.object
                    if obj then
                        local msg = obj.message or obj
                        msg_text = (msg and (msg.text or msg.body)) or ''
                        peer_id = msg and msg.peer_id
                        from_id = msg and msg.from_id
                    end
                end
                if msg_text and msg_text ~= '' then
                    table.insert(vk_pending_messages, {
                        text = msg_text,
                        from_id = from_id,
                        peer_id = peer_id,
                    })
                end
                ::skip_update::
            end
        end, function() end)
        wait(0)
    end
end

-- События сервера
function ev.onServerMessage(color, text)
	local Money = getPlayerMoney()
	local Id = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
	local Name = sampGetPlayerNickname(Id)
	if settings.telegram.tg_upom then
		if text:find(u8:decode'@'..Id..' ') then
			sendTelegramNotification(u8:decode"[Упоминание]\n" ..text)
		end
		if text:find(u8:decode'@'..Name..' ') then
			sendTelegramNotification(u8:decode"[Упоминание]\n" ..text)
		end
	end
	if settings.vkontakte.vk_upom then
		if text:find(u8:decode'@'..Id..' ') then
			sendVkontakteNotification(u8:decode"[Упоминание]\n" ..text)
		end
		if text:find(u8:decode'@'..Name..' ') then
			sendVkontakteNotification(u8:decode"[Упоминание]\n" ..text)
		end
	end
	if settings.telegram.tg_fam  then
		if text:find(u8:decode'^{......}%[Семья%] (.*) (%w+_%w+)%[%d+%]:(.*)') then
			sendTelegramNotification(text)
		end
	end
	if settings.vkontakte.vk_fam then
		if text:find(u8:decode'^{......}%[Семья%] (.*) (%w+_%w+)%[%d+%]:(.*)') then
			sendVkontakteNotification(text)
		end
	end
	if settings.telegram.tg_al  then
		if text:find(u8:decode'^%[Альянс%](.*)') then
			sendTelegramNotification(text)
		end
	end
	if settings.vkontakte.vk_al then
		if text:find(u8:decode'^%[Альянс%](.*)') then
			sendVkontakteNotification(text)
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
	if settings.vkontakte.vk_fas then
		if text:find(u8:decode'^{......}%[Семья %(Новости%)%] (%w+_%w+)%[%d+%]:{B9C1B8} (.*)') then
			sendVkontakteNotification(text)
		elseif text:find(u8:decode'^{......}%[Семья %(Новости%)%] (%w+_%w+)%[%d+%]:{FFFFFF} выполнил ежедневное задание, (.*)') then
			sendVkontakteNotification(text)
		elseif text:find(u8:decode'^{......}%[Семья %(Новости%)%] (%w+_%w+)%[%d+%]:{FFFFFF} (.*)') then
			sendVkontakteNotification(text)
		end
	end
	if settings.telegram.tg_arenda then
		if text:find(u8:decode'^%[Аренда авто%] (%w+_%w+) %[ID: (%d+)%] арендовал у вас (.*) на (%d+)ч за (.*)$') then
		    local nick,id,item,hours,summa = text:match(u8:decode'%[Аренда авто%] (%w+_%w+) %[ID: (%d+)%] арендовал у вас (.*) на (%d+)ч за (.*)$ %(в час(.*)%)')
			if nick and id and item and hours and summa then
			sendTelegramNotification(separator(string.format(u8:decode'[Аренда] %s[%s] арендовал %s на %sч за %s', nick,id,item,hours,summa)))
			end
        elseif text:find('^%[Arizona Rent%] {FFFFFF}Вы успешно сдали комнату в доме №(%d+) в аренду игроку (%w+_%w+), на (%d+) ч%. за %$([%d%.]+)!') then
            sendVkontakteNotification(text)
        end 
	end
	if settings.vkontakte.vk_arenda then
		if text:find(u8:decode'^%[Аренда авто%] (%w+_%w+) %[ID: (%d+)%] арендовал у вас (.*) на (%d+)ч за (.*)$') then
		local nick,id,item,hours,summa = text:match(u8:decode'%[Аренда авто%] (%w+_%w+) %[ID: (%d+)%] арендовал у вас (.*) на (%d+)ч за (.*)$ %(в час(.*)%)')
			if nick and id and item and hours and summa then
			sendVkontakteNotification(separator(string.format(u8:decode'[Аренда] %s[%s] арендовал %s на %sч за %s', nick,id,item,hours,summa)))
			end
		end
        elseif text:find('^%[Arizona Rent%] {FFFFFF}Вы успешно сдали комнату в доме №(%d+) в аренду игроку (%w+_%w+), на (%d+) ч%. за %$([%d%.]+)!') then
            sendVkontakteNotification(text)
	end
	if settings.telegram.tg_rab then
		if text:find(u8:decode'^%[R%] ') then
			sendTelegramNotification(text)
		elseif text:find(u8:decode'^%[F%] ') then
			sendTelegramNotification(text)
		end
	end
	if settings.vkontakte.vk_rab then
		if text:find(u8:decode'^%[R%] ') then
			sendVkontakteNotification(text)
		elseif text:find(u8:decode'^%[F%] ') then
			sendVkontakteNotification(text)
		end
	end
	if settings.telegram.tg_pay then
		if text:find(u8:decode'^Вам поступил перевод на ваш счет в размере') then
			sendTelegramNotification(separator(u8:decode'[БАНК] '..text))
		elseif text:find(u8:decode'^Вам пришло сообщение! Текст: (.*)') then
			sendTelegramNotification(u8:decode'[PHONE] '..text)
		end
	end
	if settings.vkontakte.vk_pay then
		if text:find(u8:decode'^Вам поступил перевод на ваш счет в размере') then
			sendVkontakteNotification(separator(u8:decode'[БАНК] '..text))
		elseif text:find(u8:decode'^Вам пришло сообщение! Текст: (.*)') then
			sendVkontakteNotification(u8:decode'[PHONE] '..text)
		end
	end
	if settings.telegram.tg_cr then
		if text:find(u8:decode'^Вы купили (.*) %((%d+) шт.%) у игрока (%w+_%w+) за $(.*)') then
		local item,kolvo,nick,summa = text:match(u8:decode'Вы купили (.*) %((%d+) шт.%) у игрока (%w+_%w+) за $(.*)')
			if item and kolvo and nick and summa then
				sendTelegramNotification(separator(string.format(u8:decode'[ЦР] %s продал %s (%s шт.) за $%s \nВаш баланс: $%s' , nick, item, kolvo, summa, Money)))
			end	
		elseif text:match(u8:decode'^(%w+_%w+) купил у вас (.+), вы получили $(.*) от продажи') then
		local nick,item,summa = text:match(u8:decode'(%w+_%w+) купил у вас (.+), вы получили $(.*) от продажи')
			if nick and item and summa then
				sendTelegramNotification(separator(string.format(u8:decode'[ЦР] %s купил %s за $%s \nВаш баланс: $%s' , nick, item, summa, Money)))
			end
		end
	end
	if settings.vkontakte.vk_cr then
		if text:find(u8:decode'^Вы купили (.*) %((%d+) шт.%) у игрока (%w+_%w+) за $(.*)') then
		local item,kolvo,nick,summa = text:match(u8:decode'Вы купили (.*) %((%d+) шт.%) у игрока (%w+_%w+) за $(.*)')
			if item and kolvo and nick and summa then
				sendVkontakteNotification(separator(string.format(u8:decode'[ЦР] %s продал %s (%s шт.) за $%s \nВаш баланс: $%s' , nick, item, kolvo, summa, Money)))
			end
		elseif text:match(u8:decode'^(%w+_%w+) купил у вас (.+), вы получили $(.*) от продажи') then
		local nick,item,summa = text:match(u8:decode'(%w+_%w+) купил у вас (.+), вы получили $(.*) от продажи')
			if nick and item and summa then
				sendVkontakteNotification(separator(string.format(u8:decode'[ЦР] %s купил %s за $%s \nВаш баланс: $%s' , nick, item, summa, Money)))
			end
		end
	end
	if settings.telegram.tg_ab then
		if text:find(u8:decode'^%[Информация%] {FFFFFF}Поздравляем с продажей транспортного средства%.$') then
			sendTelegramNotification(separator(string.format(u8:decode'[АБ] %s \nВаш баланс: $%s' , text, Money)))
		end
	end
	if settings.vkontakte.vk_ab then
		if text:find(u8:decode'^%[Информация%] {FFFFFF}Поздравляем с продажей транспортного средства%.$') then
			sendVkontakteNotification(separator(string.format(u8:decode'[АБ] %s \nВаш баланс: $%s' , text, Money)))
		end
	end
	if text:find(u8:decode'^%[Альянс%](.*)') and not text:find(u8:decode':item(.*):') then
		local cvet, nick, ider, vivod = text:match(u8:decode'^%[Альянс%] (.*) (%w+_%w+)%[(.*)]:(.*)')
		if cvet and nick and ider and vivod and colorchat then
			sampAddChatMessage(intToHex(join_argb(colorchat[3] * 255, colorchat[0] * 255, colorchat[1] * 255, colorchat[2] * 255))..u8:decode'[Альянс] '..cvet..' '..nick..'['..ider..']:{B9C1B8}'..vivod, -1)
		end
		return false
	end
	if text:find(u8:decode'^{......}%[Семья%]') and not text:find(u8:decode':item(.*):') then
        local cvet, nick, ider, vivod = text:match(u8:decode'^{......}%[Семья%] (.*) (%w+_%w+)%[(.*)]:(.*)')
        if cvet and nick and ider and vivod and colorchat_fam then
            sampAddChatMessage(intToHex(join_argb(colorchat_fam[3] * 255, colorchat_fam[0] * 255, colorchat_fam[1] * 255, colorchat_fam[2] * 255))..u8:decode'[Семья] '..cvet..' '..nick..'['..ider..']:{B9C1B8}'..vivod, -1)
        end
        return false
    end
	if autoCookEnabled[0] and (
		text:find(u8:decode'[Ошибка] {ffffff}У вас нет сырого мяса оленины!', 1, true)
		or text:find(u8:decode'[Ошибка] {ffffff}Возле вас нет костра!', 1, true)
	) then
		autoCookEnabled[0] = false
		if cookThread then
			cookThread:terminate()
			cookThread = nil
		end
		local reason = 'Нету мяса'
		if text:find(u8:decode'Возле вас нет костра!', 1, true) then
			reason = 'Нет костра'
		end
		notifications.error(tag..'Автоготовка остановлена! Причина: ' .. reason, 7000)
		return false
	end
	if text:find(u8:decode'Вы успешно приготовили 1 жареный кусок мяса оленины! Чтобы покушать, используйте: /eat или /jmeat') then
		return false
	end
end

function sampev.onShowDialog(id, style, title, btn1, btn2, text)
    if autoCookEnabled[0] and id == 9081 then
        lua_thread.create(function()
            wait(200)
            sampSendDialogResponse(id, 1, 1, '')
        end)
    end
end

function onReceivePacket(id)
    if id == 32 then
		sendTelegramNotification(u8:decode'Сервер закрыл соединение.')
		sendVkontakteNotification(u8:decode'Сервер закрыл соединение.')
	elseif id == 33 then
		sendTelegramNotification(u8:decode'Соединение с сервером было утеряно')
		sendVkontakteNotification(u8:decode'Соединение с сервером было утеряно')
	elseif id == 36 then
		sendTelegramNotification(u8:decode'Соединение с сервером было заблокировано')
		sendVkontakteNotification(u8:decode'Соединение с сервером было заблокировано')
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
        notifications.error(u8:decode'Нет доступных звуков для воспроизведения.', 7000)
    end
end

function main()
    while not isSampAvailable() do wait(0) end
	loadItemsData()
	if autoupdate_loaded and enable_autoupdate and Update then
        pcall(Update.check, Update.json_url, Update.prefix, Update.url)
    end
	notifications.info(tag.. "Успешно загружен!\nОткрыть меню скрипта /" ..settings.main.menu, 8000)
	sampRegisterChatCommand(settings.main.menu, function() WinState[0] = not WinState[0] end)
	while not isSampAvailable() do
       wait(0)
    end
    lua_thread.create(get_telegram_updates)
	if not doesDirectoryExist(getWorkingDirectory()..'\\MiniHelper') then
        createDirectory(getWorkingDirectory()..'\\MiniHelper')
    end
    for i, v in ipairs(sounds) do
        local path = getWorkingDirectory() .. '\\MiniHelper\\' .. v['file_name']
        if doesFileExist(path) then
            local stream = loadAudioStream(path)
            if stream then
                table.insert(sound_streams, stream)
            end
        end
    end
	getLastUpdate()
	if settings.vkontakte.vk_active and settings.vkontakte.vk_token and settings.vkontakte.vk_token ~= '' and settings.vkontakte.vk_group_id and settings.vkontakte.vk_group_id ~= '' then
		initVK()
	end
end

imgui.OnFrame(function() return WinState[0] end, function(player)
    imgui.SetNextWindowPos(imgui.ImVec2(500, 500), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(509, 243), imgui.Cond.Always)
    imgui.Begin('##Window', WinState, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)

    if imgui.BeginChild('Menu', imgui.ImVec2(136, 208), false) then
        if imgui.GradientPB(tab == 1, fa.ICON_FA_HOME, 'ГЛАВНАЯ', 0.40) then tab = 1 end
        if imgui.GradientPB(tab == 2, fa.ICON_FA_COG, 'НАСТРОЙКИ', 0.40) then tab = 2 end
        if imgui.GradientPB(tab == 3, fa.ICON_FA_PAPER_PLANE, 'УВЕДОМЛЕНИЯ', 0.40) then tab = 3 end
        if imgui.GradientPB(tab == 4, fa.ICON_FA_BUG, 'ПОЛЕЗНОЕ', 0.40) then tab = 4 end
        if imgui.GradientPB(tab == 5, fa.ICON_FA_NETWORK_WIRED, 'ПРОКСИ', 0.40) then tab = 5 end
        imgui.EndChild()
    end

    imgui.SameLine()

    if imgui.BeginChild('Function', imgui.ImVec2(360, 208), true) then
        if tab == 1 then
            imgui.Text('Добро пожаловать!\n\n\n\n')
			imgui.Text('Есть идеи для скрипта?\nЖду их здесь:')
			if imgui.Button('ВК', imgui.ImVec2(35, 25) ) then
				os.execute("start https://vk.com/koktic")
			end
			imgui.SameLine()
			if imgui.Button('ТГ', imgui.ImVec2(35, 25) ) then
				os.execute("start https://t.me/koktic")
			end
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
				settings.main.volume = volume[0]
				ini.save(settings, 'MiniHelper.ini')
			end
        elseif tab == 3 then
            if imgui.BeginTabBar('Tabs') then -- задаём начало вкладок
				if imgui.BeginTabItem('TG Уведомления') then -- первая вкладка
					if imgui.Checkbox('Разрешить уведомления', telegram_rabota) then
						settings.telegram.tg_active = telegram_rabota[0]
						ini.save(settings, 'Minihelper.ini')
					end
					imgui.SameLine()
					if imgui.Button('Настройка TG уведомлений') then
						imgui.OpenPopup('Настройка TG уведомлений')
					end
					if imgui.BeginPopupModal('Настройка TG уведомлений', _, imgui.WindowFlags.NoResize) then
						imgui.SetWindowSizeVec2(imgui.ImVec2(370, 400))
						if imgui.Checkbox('Получать сообщения семьи     ', telegram_fam) then
							settings.telegram.tg_fam = telegram_fam[0]
							ini.save(settings, 'Minihelper.ini')
						end
						if imgui.Checkbox('Получать сообщения альянса', telegram_al) then
							settings.telegram.tg_al = telegram_al[0] 
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
						if imgui.Checkbox('Информация о сдаче в аренду', telegram_arenda) then
							settings.telegram.tg_arenda = telegram_arenda[0]
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
						imgui.Text('chat_id: куда слать уведомления и откуда принимать команды.\nВ ЛС с ботом это твой user id (@my_id_bot).\nЧужие сообщения боту не обрабатываются — id чата другой.')
						imgui.EndTooltip()
					end
					imgui.SetNextItemWidth(234)if imgui.InputTextWithHint('##TOKEN', 'TOKEN', inputtoken, 256) then end imgui.SameLine() imgui.Text('Ваш TOKEN')
					if imgui.IsItemHovered() then
						imgui.BeginTooltip()
						imgui.Text('Создать бота и получить его токен вы можете у @BotFather')
						imgui.EndTooltip()
					end
					if imgui.Button('Отправка тестового сообщения') then
						if not telegram_rabota[0] then
							telegramLog('Включите «Разрешить уведомления» и нажмите «Сохранить настройки».', true)
						else
							sendTelegramNotification(u8:decode(tag.. 'Скрипт работает\nДля того что бы начать им пользоваться напиши /help'))
						end
					end
					if imgui.Button('Сохранить настройки', imgui.ImVec2(137, 30)) then
						settings.telegram.chat_id = (str(inputid))
						settings.telegram.token = (str(inputtoken))
						settings.telegram.tg_proxy_host = (str(inputproxyhost))
						settings.telegram.tg_proxy_port = (str(inputproxyport))
						settings.telegram.tg_proxy_login = (str(inputproxylogin))
						settings.telegram.tg_proxy_password = (str(inputproxypass))
						settings.telegram.tg_proxy = ''
						settings.telegram.tg_use_server_config = telegram_use_server[0]
						settings.telegram.tg_use_proxy = telegram_use_proxy[0]
						settings.telegram.tg_active = telegram_rabota[0]
						ini.save(settings, 'MiniHelper.ini')
						thisScript():reload()
					end
				imgui.EndTabItem() -- конец вкладки
				end
				if imgui.BeginTabItem('VK Уведомления') then -- вторая вкладка
					if imgui.Checkbox('Разрешить уведомления', vkontakte_rabota) then
						settings.vkontakte.vk_active = vkontakte_rabota[0]
						ini.save(settings, 'Minihelper.ini')
					end
					imgui.SameLine()
					if imgui.Button('Настройка VK уведомлений') then
						imgui.OpenPopup('Настройка VK уведомлений')
					end
					if imgui.BeginPopupModal('Настройка VK уведомлений', _, imgui.WindowFlags.NoResize) then
						imgui.SetWindowSizeVec2(imgui.ImVec2(370, 325))
						if imgui.Checkbox('Получать сообщения семьи     ', vkontakte_fam) then
							settings.vkontakte.vk_fam = vkontakte_fam[0]
							ini.save(settings, 'Minihelper.ini')
						end
						if imgui.Checkbox('Получать сообщения альянса', vkontakte_al) then
							settings.vkontakte.vk_al = vkontakte_al[0]
							ini.save(settings, 'Minihelper.ini')
						end
						if imgui.Checkbox('Получать действия семьи', vkontakte_fas) then
							settings.vkontakte.vk_fas = vkontakte_fas[0]
							ini.save(settings, 'Minihelper.ini')
						end
						if imgui.Checkbox('Получать уведомления о продаже/покупке в лавке', vkontakte_cr) then
							settings.vkontakte.vk_cr = vkontakte_cr[0]
							ini.save(settings, 'Minihelper.ini')
						end
						if imgui.Checkbox('Информация о сдаче в аренду', vkontakte_arenda) then
							settings.vkontakte.vk_arenda = vkontakte_arenda[0]
							ini.save(settings, 'Minihelper.ini')
						end
						if imgui.Checkbox('Получать уведомления о продаже транспорта', vkontakte_ab) then
							settings.vkontakte.vk_ab = vkontakte_ab[0]
							ini.save(settings, 'Minihelper.ini')
						end
						if imgui.Checkbox('Получать уведомления с организационного чата', vkontakte_rab) then
							settings.vkontakte.vk_rab = vkontakte_rab[0]
							ini.save(settings, 'Minihelper.ini')
						end
						if imgui.Checkbox('Получать уведомления о переводах', vkontakte_pay) then
							settings.vkontakte.vk_pay = vkontakte_pay[0]
							ini.save(settings, 'Minihelper.ini')
						end
						if imgui.Checkbox('Получать уведомления о упоминаниях', vkontakte_upom) then
							settings.vkontakte.vk_upom = vkontakte_upom[0]
							ini.save(settings, 'Minihelper.ini')
						end	
						if imgui.Button('Закрыть', imgui.ImVec2(130, 24)) then
							imgui.CloseCurrentPopup()
						end
						imgui.End()
					end
					imgui.Separator()
					imgui.SetNextItemWidth(234)if imgui.InputTextWithHint('##ID', 'ID', vkinputid, 256) then end imgui.SameLine() imgui.Text('Ваш ID')
					if imgui.IsItemHovered() then
						imgui.BeginTooltip()
						imgui.Text('peer_id: куда слать уведомления. Должен совпадать с твоим id ВК в ЛС с сообществом — тогда команды обрабатываются только от тебя.')
						imgui.EndTooltip()
					end
					imgui.SetNextItemWidth(234)if imgui.InputTextWithHint('##TOKEN', 'TOKEN', vkinputtoken, 256) then end imgui.SameLine() imgui.Text('Token сообщества')
					if imgui.IsItemHovered() then
						imgui.BeginTooltip()
						imgui.Text('Группа → Управление → Дополнительно → Работа с API → Ключи (права: доступ к сообщениям)')
						imgui.EndTooltip()
					end
					imgui.SetNextItemWidth(234)if imgui.InputTextWithHint('##IdGROUP', 'ID Group', vkgroupid, 256) then end imgui.SameLine() imgui.Text('ID группы')
					if imgui.IsItemHovered() then
						imgui.BeginTooltip()
						imgui.Text('Группа → Управление → Адрес')
						imgui.EndTooltip()
					end
					if imgui.Button('Отправка тестового сообщения') then
						sendVkontakteNotification(u8:decode(tag.. 'Скрипт работает\nДля того что бы начать им пользоваться напиши /help'))
					end
					if imgui.Button('Сохранить настройки', imgui.ImVec2(137, 30)) then
						settings.vkontakte.vk_chat_id = (str(vkinputid))
						settings.vkontakte.vk_token = (str(vkinputtoken))
						settings.vkontakte.vk_group_id = (str(vkgroupid))
						settings.vkontakte.vk_active = vkontakte_rabota[0]
						ini.save(settings, 'MiniHelper.ini')
						thisScript():reload()
					end
				imgui.EndTabItem() -- конец вкладки
				end
			imgui.EndTabBar() -- конец всех вкладок
		end
		elseif tab == 4 then
			if imgui.CollapsingHeader('Вспомогательные') then
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
			end
			if imgui.CollapsingHeader('Изменить цвет чата') then
				if imgui.ColorEdit4('Цвет чата альянса', colorchat, imgui.ColorEditFlags.NoAlpha) then
					local clr = {colorchat[0], colorchat[1], colorchat[2], colorchat[3]}
					settings.color_chat = clr
					ini.save(settings, 'MiniHelper.ini')
				end
				if imgui.ColorEdit4('Цвет чата семьи', colorchat_fam, imgui.ColorEditFlags.NoAlpha) then
                    local clr = {colorchat_fam[0], colorchat_fam[1], colorchat_fam[2], colorchat_fam[3]}
                    settings.color_chat_fam = clr
                    ini.save(settings, 'MiniHelper.ini')
                end
			end
        elseif tab == 5 then
            imgui.Text('Сервер')
			if imgui.Checkbox('Включить | Сервер', telegram_use_server) then
				settings.telegram.tg_use_server_config = telegram_use_server[0]
				ini.save(settings, 'MiniHelper.ini')
			end
            if imgui.IsItemHovered() then
                imgui.BeginTooltip()
                imgui.Text('Включите данную функцию, если у вас не работают уведомления в телеграме.')
                imgui.EndTooltip()
            end
			if imgui.Button('Отправить тестовое сообщение', imgui.ImVec2(260, 28)) then
				if not telegram_rabota[0] then
					telegramLog('Включите «Разрешить уведомления» и сохраните настройки.', true)
				else
					sendTelegramNotification(u8:decode(tag.. 'Скрипт работает\nДля того что бы начать им пользоваться напиши /help'))
				end
			end
			imgui.Separator()
			imgui.Text('Кастомный прокси')
			imgui.TextWrapped('Только для прямого доступа к Telegram с этого ПК.')
			if imgui.Checkbox('Использовать прокси', telegram_use_proxy) then
				settings.telegram.tg_use_proxy = telegram_use_proxy[0]
				ini.save(settings, 'MiniHelper.ini')
			end
            if imgui.IsItemHovered() then
                imgui.BeginTooltip()
                imgui.Text('Сюда можно ввести свои IP, PORT, LOGIN, PASSWORD для прокси.')
                imgui.EndTooltip()
            end
			imgui.SetNextItemWidth(234)if imgui.InputTextWithHint('##PROXYIP', 'IP', inputproxyhost, 256) then end imgui.SameLine() imgui.Text('IP')
			imgui.SetNextItemWidth(234)if imgui.InputTextWithHint('##PROXYPORT', 'PORT', inputproxyport, 16) then end imgui.SameLine() imgui.Text('PORT')
			imgui.SetNextItemWidth(234)if imgui.InputTextWithHint('##PROXYLOGIN', 'LOGIN', inputproxylogin, 256) then end imgui.SameLine() imgui.Text('LOGIN')
			imgui.SetNextItemWidth(234)if imgui.InputTextWithHint('##PROXYPASS', 'PASSWORD', inputproxypass, 256, imgui.InputTextFlags.Password) then end imgui.SameLine() imgui.Text('PASSWORD')
			if imgui.Button('Сохранить', imgui.ImVec2(137, 30)) then
				settings.telegram.tg_proxy_host = (str(inputproxyhost))
				settings.telegram.tg_proxy_port = (str(inputproxyport))
				settings.telegram.tg_proxy_login = (str(inputproxylogin))
				settings.telegram.tg_proxy_password = (str(inputproxypass))
				settings.telegram.tg_proxy = ''
				settings.telegram.tg_use_server_config = telegram_use_server[0]
				settings.telegram.tg_use_proxy = telegram_use_proxy[0]
				ini.save(settings, 'MiniHelper.ini')
				thisScript():reload()
			end
        end

        imgui.EndChild()
    end
    imgui.End()
end)






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
        imgui.Text((' '):rep(1) .. icon)
        imgui.SameLine(40)
        imgui.Text(text)
    else
        imgui.TextColored(imgui.ImVec4(0.60, 0.60, 0.60, 1.00), (' '):rep(1) .. icon)
        imgui.SameLine(40)
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
