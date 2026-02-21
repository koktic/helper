script_version("v1.17")
script_name("Mini Helper")
local tag = "[Mini Helper] "

local imgui = require 'mimgui'
local fa = require('fAwesome5')

local encoding = require 'encoding'
encoding.default = 'CP1251'
local new = imgui.new
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
if pcall(function()
    local ntf = require("notifications")
    if ntf and ntf.info then
        notifications = ntf
        ntf_loaded = true
    end
end) and ntf_loaded then
    print('NTF good')
end
if not ntf_loaded then
    local NTF = getWorkingDirectory().."/lib/notifications.lua"
    downloadUrlToFile('https://raw.githubusercontent.com/koktic/helper/refs/heads/main/notifications.lua', NTF)
end

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
		tg_arenda = false,
		tg_fam = false,
		tg_al = false,
		tg_fas = false,
		tg_cr = false,
		tg_ab = false,
		tg_rent = false,
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
		vk_rent = false,
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
    settings.vkontakte = { vk_chat_id = '', vk_group_id = '', vk_token = '', vk_active = false, vk_fam = false, vk_al = false, vk_fas = false, vk_cr = false, vk_ab = false, vk_rent = false, vk_rab = false, vk_pay = false, vk_upom = false, vk_arenda = false }
end
if not settings.telegram then
    settings.telegram = { chat_id = '', token = '', tg_active = false, tg_fam = false, tg_al = false, tg_fas = false, tg_cr = false, tg_ab = false, tg_rent = false, tg_rab = false, tg_pay = false, tg_upom = false, tg_arenda = false }
end
if not settings.main then
    settings.main = { menu = 'mhelp', cr_sound = false, ab_sound = false, volume = 2 }
end
if not settings.color_chat or type(settings.color_chat) ~= 'table' or #settings.color_chat ~= 4 then
    settings.color_chat = { 1, 0, 0, 1 }
end

---ТГ ЛОКАЛ
local inputid = new.char[256](u8(settings.telegram.chat_id))
local inputtoken = new.char[256](u8(settings.telegram.token))
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
local telegram_rent = new.bool(settings.telegram.tg_rent)
local updateid
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
local vkontakte_rent = new.bool(settings.vkontakte.vk_rent)
local vk_server, vk_key, vk_ts
local vk_bot_state = "main"
local vk_pending_messages = {}
--ПОЛЕЗНОЕ
local cdl = new.char[12](settings.dop and settings.dop.castom_dl or 'dl')
local autoCookEnabled = new.bool(false)
local cookThread = nil

-- АВТОЗАТОЧКА (из autozatochka.lua)
local az_WinState, az_playSound = new.bool(), new.bool()
local az_status = false
local az_max_toch = 0
local az_button_id = 0
local az_tochi, az_workshop_check, az_stone_check = false, false, false
local az_lost_stone_onLVL, az_all_lost = 0, 0
local az_stone = {}
local az_lost_stone = {}
local az_enchantSlotsData = {index = -1, left = -1, right = -1, color = -1}
local Whetstone_ITEM_ID = 1187
local az_whetstone_detected = false
local az_whetstone_last_check = 0
local Whetstone_CHECK_INTERVAL_MS = 2000

local function attemptsWord(n)
    n = tonumber(n) or 0
    if n == 1 then return "1 попытка"
    elseif n >= 2 and n <= 4 then return n .. " попытки"
    else return n .. " попыток" end
end

-- CEF автозаточки
function evalanon(code)
    evalcef(("(() => {%s})()"):format(code))
end

function evalcef(code, encoded)
    encoded = encoded or 0
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 17)
    raknetBitStreamWriteInt32(bs, 0)
    raknetBitStreamWriteInt16(bs, #code)
    raknetBitStreamWriteInt8(bs, encoded)
    raknetBitStreamWriteString(bs, code)
    raknetEmulPacketReceiveBitStream(220, bs)
    raknetDeleteBitStream(bs)
end

function sendCEFEvent(eventName, params)
    local code = string.format("window.executeEvent('%s', `%s`);", eventName, params)
    evalcef(code, 0)
end

function sendCEF(str)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 220)
    raknetBitStreamWriteInt8(bs, 18)
    raknetBitStreamWriteInt16(bs, #str)
    raknetBitStreamWriteString(bs, str)
    raknetBitStreamWriteInt32(bs, 0)
    raknetSendBitStream(bs)
    raknetDeleteBitStream(bs)
end

function rightClickOnBlock(slot, type)
    local json = string.format('{"slot": %d, "type": %d}', slot, type or 1)
    sendCEF('rightClickOnBlock|'..json)
end

function leftClickOnBlock(slot, type)
    local json = string.format('{"slot": %d, "type": %d}', slot, type or 1)
    sendCEF('leftClickOnBlock|'..json)
end

function clickOnBlock(slot, type)
    local json = string.format('{"slot": %d, "type": %d}', slot, type or 1)
    sendCEF('clickOnBlock|'..json)
end

function clickOnButton(type, slot, action)
    local json = string.format('{"type": %d, "slot": %d, "action": %d}', type or 1, slot, action or 16)
    sendCEF('clickOnButton|'..json)
end

function moveItem(fromSlot, fromType, toSlot, toType, amount)
    amount = amount or 1
    fromType = fromType or 1
    toType = toType or 1
    local json = string.format('{"from":{"slot":%d,"type":%d,"amount":%d},"to":{"slot":%d,"type":%d}}', fromSlot, fromType, amount, toSlot, toType)
    sendCEF('inventory.moveItem|'..json)
end

local Whetstone_KEYWORDS = { "Точильный камень", "точильный камень", "Заточка", "заточка" }

function getWhetstoneCount()
    local keywordsEsc = {}
    for _, kw in ipairs(Whetstone_KEYWORDS) do
        keywordsEsc[#keywordsEsc + 1] = (kw):gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\r", ""):gsub("\n", "\\n")
    end
    local kwList = table.concat(keywordsEsc, '","')
    local result = evalanon(string.format([[
        (function() {
            try {
                var count = 0;
                var keywords = ["%s"];
                var containers = document.querySelectorAll('.inventory-main__grid, .inventory-grid__grid, .warehouse .inventory-grid__grid, [class*="inventory-grid"], [class*="inventory-main"], .inventory-container, [class*="inventory"]');
                for (var c = 0; c < containers.length; c++) {
                    var items = containers[c].querySelectorAll('.inventory-item-hoc, .inventory-grid__item-bg, [class*="inventory-item"], [class*="item"]');
                    for (var i = 0; i < items.length; i++) {
                        var item = items[i];
                        var img = item.querySelector('.inventory-item__image, img');
                        var alt = img ? (img.getAttribute('alt') || '') : '';
                        var title = img ? (img.getAttribute('title') || '') : '';
                        var src = img ? (img.getAttribute('src') || '') : '';
                        var text = (item.innerText || item.textContent || '').toString();
                        var combined = alt + ' ' + title + ' ' + text;
                        var m = alt.match(/\d+/); var m2 = src.match(/\d+/);
                        var id = parseInt(m ? m[0] : 0) || parseInt(m2 ? m2[0] : 0) || 0;
                        var byName = false;
                        for (var k = 0; k < keywords.length; k++) {
                            if (combined.indexOf(keywords[k]) !== -1) { byName = true; break; }
                        }
                        if (id === 1187 || byName) count++;
                    }
                }
                var byAttr = document.querySelectorAll('[data-item-id="1187"], [data-model="1187"], [data-id="1187"], img[alt*="1187"]');
                if (byAttr.length > 0 && count === 0) count = byAttr.length;
                if (count > 0) return count;
                var allImgs = document.querySelectorAll('img[alt], [class*="item"] img, [class*="inventory"] img');
                for (var j = 0; j < allImgs.length; j++) {
                    var a = (allImgs[j].getAttribute('alt') || '') + (allImgs[j].getAttribute('title') || '');
                    var par = allImgs[j].parentElement;
                    if (par && (par.innerText || par.textContent)) a += (par.innerText || par.textContent).toString();
                    for (var k = 0; k < keywords.length; k++) {
                        if (a.indexOf(keywords[k]) !== -1) { count++; break; }
                    }
                }
                return count;
            } catch(e) { return 0; }
        })();
    ]], kwList))
    local n = tonumber(result)
    return (n and n >= 0) and n or 0
end

function findStoneSlotNumber()
    local kwEsc = (Whetstone_KEYWORDS[1]):gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\r", ""):gsub("\n", "\\n")
    evalanon(string.format([[
        try {
            var stoneSlotNumber = -1;
            var keywords = ["%s", "Заточка", "заточка"];
            var containerSelectors = ['.inventory-main__grid', '.inventory-grid__grid', '.warehouse .inventory-grid__grid', '[class*="inventory-grid"]', '[class*="inventory-main"]', '.inventory-container', '[class*="inventory"]'];
            for (var cs = 0; cs < containerSelectors.length; cs++) {
                var containers = document.querySelectorAll(containerSelectors[cs]);
                for (var c = 0; c < containers.length; c++) {
                    var items = containers[c].querySelectorAll('.inventory-item-hoc, .inventory-grid__item-bg, [class*="item"]');
                    for (var i = 0; i < items.length; i++) {
                        var item = items[i];
                        var img = item.querySelector('.inventory-item__image, img');
                        if (!img) continue;
                        var alt = img.getAttribute('alt') || '';
                        var src = img.getAttribute('src') || '';
                        var text = (item.innerText || item.textContent || '').toString();
                        var combined = alt + ' ' + text;
                        var m = alt.match(/\d+/); var m2 = src.match(/\d+/);
                        var id = parseInt(m ? m[0] : 0) || parseInt(m2 ? m2[0] : 0) || 0;
                        var byName = false;
                        for (var k = 0; k < keywords.length; k++) { if (combined.indexOf(keywords[k]) !== -1) { byName = true; break; } }
                        if (id !== 1187 && !byName) continue;
                        var slotNum = -1;
                        var slotAttr = item.getAttribute('data-slot');
                        if (slotAttr) slotNum = parseInt(slotAttr);
                        if (slotNum < 0) { var p = item.closest('[data-slot]'); if (p) slotNum = parseInt(p.getAttribute('data-slot')); }
                        if (slotNum < 0) { var ia = item.getAttribute('data-index'); if (ia) slotNum = parseInt(ia); }
                        if (slotNum < 0) { var s2 = item.getAttribute('slot'); if (s2) slotNum = parseInt(s2); }
                        if (slotNum < 0) slotNum = i;
                        if (slotNum >= 0) { window.stoneSlotNumber = slotNum; return slotNum; }
                    }
                }
            }
            return -1;
        } catch(e) { return -1; }
    ]], kwEsc))
    wait(150)
    local slotNum = evalanon([[ return (typeof window.stoneSlotNumber !== 'undefined' && window.stoneSlotNumber >= 0) ? window.stoneSlotNumber : -1; ]])
    return (type(slotNum) == 'number' and slotNum >= 0) and slotNum or (tonumber(slotNum) or -1)
end

function findEnchantSlotNumber()
    evalanon([[
        try {
            const leftSlotSelectors = [
                '[class*="left-slot"]', '[class*="leftSlot"]', '[class*="left_slot"]', '[data-slot="left"]', '[data-slot-type="left"]',
                '[class*="enchant-slot"]:first-child', '[class*="enchantSlot"]:first-child', '.enchant-main__slot-item:first-child',
                '[class*="enchant-slot"]', '[class*="enchantSlot"]'
            ];
            let enchantSlotNumber = -1;
            for (let selector of leftSlotSelectors) {
                const slots = document.querySelectorAll(selector);
                for (let slot of slots) {
                    const rect = slot.getBoundingClientRect();
                    if (rect.width > 0 && rect.height > 0) {
                        const hasItem = slot.querySelector('.inventory-item-hoc, .inventory-item__image, img[alt*="1187"]');
                        if (!hasItem) {
                            let slotNum = -1;
                            const slotAttr = slot.getAttribute('data-slot');
                            if (slotAttr && slotAttr ~= 'left') slotNum = parseInt(slotAttr);
                            if (slotNum < 0) { const indexAttr = slot.getAttribute('data-index'); if (indexAttr) slotNum = parseInt(indexAttr); }
                            if (slotNum < 0 && window.enchantSlotIndex !== undefined) slotNum = window.enchantSlotIndex;
                            if (slotNum >= 0) { window.enchantSlotNumber = slotNum; return slotNum; }
                            window.enchantSlotNumber = 0; return 0;
                        }
                    }
                }
            }
            return enchantSlotNumber;
        } catch(e) { return -1; }
    ]])
    wait(100)
    local slotNum = evalanon([[ return window.enchantSlotNumber !== undefined ? window.enchantSlotNumber : -1; ]])
    return slotNum or -1
end

function findAndClickStone()
    local stoneSlotNum = findStoneSlotNumber()
    if stoneSlotNum >= 0 then
        if az_enchantSlotsData.left == -1 then
            local enchantSlot = az_enchantSlotsData.index >= 0 and az_enchantSlotsData.index or findEnchantSlotNumber()
            if enchantSlot >= 0 then
                moveItem(stoneSlotNum, 1, enchantSlot, 1, 1)
                wait(500)
            end
            if enchantSlot >= 0 then
                clickOnBlock(stoneSlotNum, 1)
                wait(350)
                clickOnBlock(enchantSlot, 1)
                wait(400)
            end
            local enchantSlotNum = (enchantSlot >= 0) and enchantSlot or findEnchantSlotNumber()
            if enchantSlotNum >= 0 and enchantSlotNum ~= az_enchantSlotsData.index then
                for _, toType in ipairs({1, 2, 3, 4, 5}) do
                    moveItem(stoneSlotNum, 1, enchantSlotNum, toType, 1)
                    wait(400)
                end
            end
            for _, specialSlot in ipairs({-1, -2, -3, 0, 1, 2, 100, 200, 1000, 2000}) do
                for _, toType in ipairs({1, 2, 3}) do
                    moveItem(stoneSlotNum, 1, specialSlot, toType, 1)
                    wait(200)
                end
            end
            rightClickOnBlock(stoneSlotNum, 1)
            wait(800)
            if az_enchantSlotsData.index >= 0 then
                for _, toType in ipairs({1, 2, 3, 4, 5}) do
                    moveItem(stoneSlotNum, 1, az_enchantSlotsData.index, toType, 1)
                    wait(400)
                end
            end
            if enchantSlotNum >= 0 and enchantSlotNum ~= az_enchantSlotsData.index then
                for _, toType in ipairs({1, 2, 3, 4, 5}) do
                    moveItem(stoneSlotNum, 1, enchantSlotNum, toType, 1)
                    wait(400)
                end
            end
            for _, specialSlot in ipairs({-1, -2, -3, 0, 1, 2, 100, 200, 1000, 2000}) do
                for _, toType in ipairs({1, 2, 3}) do
                    moveItem(stoneSlotNum, 1, specialSlot, toType, 1)
                    wait(200)
                end
            end
            if az_enchantSlotsData.index >= 0 then
                moveItem(stoneSlotNum, 1, az_enchantSlotsData.index, 1, 1)
                wait(600)
            end
            if az_enchantSlotsData.index >= 0 then
                leftClickOnBlock(az_enchantSlotsData.index, 1)
                wait(400)
            end
            if enchantSlotNum >= 0 and enchantSlotNum ~= az_enchantSlotsData.index then
                leftClickOnBlock(enchantSlotNum, 1)
                wait(400)
            end
            if az_enchantSlotsData.index >= 0 then
                clickOnButton(1, az_enchantSlotsData.index, 16)
                wait(400)
            end
            evalanon([[
                try {
                    const leftSlotSelectors = ['[class*="left-slot"]','[class*="leftSlot"]','[class*="enchant-slot"]:first-child','[class*="enchantSlot"]','[class*="slot"][class*="enchant"]'];
                    let foundSlot = null;
                    for (let selector of leftSlotSelectors) {
                        const slots = document.querySelectorAll(selector);
                        for (let slot of slots) {
                            const rect = slot.getBoundingClientRect();
                            if (rect.width > 0 && rect.height > 0) {
                                const hasItem = slot.querySelector('.inventory-item-hoc, .inventory-item__image, img[alt*="1187"]');
                                if (!hasItem) { foundSlot = slot; break; }
                            }
                        }
                        if (foundSlot) break;
                    }
                    if (foundSlot) {
                        const rect = foundSlot.getBoundingClientRect();
                        const centerX = rect.left + rect.width / 2, centerY = rect.top + rect.height / 2;
                        if (typeof foundSlot.click === 'function') foundSlot.click();
                        foundSlot.dispatchEvent(new MouseEvent('mousedown', {bubbles:true,cancelable:true,button:0,clientX:centerX,clientY:centerY,view:window}));
                        setTimeout(() => {
                            foundSlot.dispatchEvent(new MouseEvent('mouseup', {bubbles:true,cancelable:true,button:0,clientX:centerX,clientY:centerY,view:window}));
                            foundSlot.dispatchEvent(new MouseEvent('click', {bubbles:true,cancelable:true,button:0,clientX:centerX,clientY:centerY,view:window}));
                            if (typeof foundSlot.click === 'function') foundSlot.click();
                        }, 50);
                        return true;
                    }
                } catch(e) {}
                return false;
            ]])
            wait(1000)
        end
        return true
    else
        evalanon([[
            try {
                const containers = document.querySelectorAll('.inventory-main__grid, .inventory-grid__grid, [class*="inventory-grid"]');
                let stoneItem = null;
                containers.forEach((container) => {
                    const items = container.querySelectorAll('.inventory-item-hoc, .inventory-grid__item-bg');
                    items.forEach((item) => {
                        const img = item.querySelector('.inventory-item__image, img');
                        if (img) {
                            const alt = img.getAttribute('alt') || '';
                            const itemId = parseInt(alt.match(/\d+/)?.[0]) || 0;
                            if (itemId === 1187) { stoneItem = item; return; }
                        }
                    });
                    if (stoneItem) return;
                });
                if (stoneItem) { stoneItem.click(); return true; }
            } catch(e) {}
            return false;
        ]])
    end
    return false
end

function findAndClickEnchantButton()
    evalanon([[
        try {
            const buttonTexts = ['ENCHANT', 'ЗАТОЧКА', 'Заточить', 'Улучшить', 'ENHANCE', 'Заточка', 'заточка', 'ЗАТОЧИТЬ', 'START', 'НАЧАТЬ'];
            const selectors = ['button', '[role="button"]', '.btn', '[class*="button"]', '[class*="btn"]', '[class*="enchant"]', '[class*="start"]', 'div[onclick]', '*[onclick]'];
            for (let selector of selectors) {
                const buttons = document.querySelectorAll(selector);
                for (let btn of buttons) {
                    const rect = btn.getBoundingClientRect();
                    if (rect.width === 0 || rect.height === 0) continue;
                    const text = (btn.textContent || btn.innerText || '').toUpperCase();
                    const className = (btn.className || '').toUpperCase();
                    for (let searchText of buttonTexts) {
                        if (text.includes(searchText.toUpperCase()) || className.includes(searchText.toUpperCase())) {
                            btn.dispatchEvent(new MouseEvent('mousedown', {bubbles:true,cancelable:true,button:0}));
                            btn.dispatchEvent(new MouseEvent('mouseup', {bubbles:true,cancelable:true,button:0}));
                            btn.dispatchEvent(new MouseEvent('click', {bubbles:true,cancelable:true,button:0}));
                            if (typeof btn.click === 'function') btn.click();
                            return true;
                        }
                    }
                }
            }
        } catch(e) {}
        return false;
    ]])
end

function startEnchant()
    sendCEF('startEnchant')
    evalanon([[ try { if (typeof window.executeEvent === 'function') window.executeEvent('startEnchant', ''); } catch(e) {} ]])
end

function az_click_onStone()
    if not az_workshop_check then
        az_checkWorkshopStatus()
        evalanon([[ if (window.workshopDetected === true) window.workshopCheckResult = 1; ]])
    end
    if #az_stone == 0 then
        if az_workshop_check then
            findAndClickStone()
            az_tochi = az_workshop_check
        else
            az_checkWorkshopStatus()
            evalanon([[
                const bodyText = (document.body.innerText || '').toUpperCase();
                if (bodyText.includes('WORKSHOP') || bodyText.includes('ВЕРСТАК') || bodyText.includes('ENCHANT') || bodyText.includes('ЗАТОЧКА') || document.querySelectorAll('[data-item-id="1187"], [data-model="1187"]').length > 0 || window.workshopDetected === true) window.forceWorkshopOpen = true;
            ]])
            az_workshop_check = true
            findAndClickStone()
            az_tochi = true
        end
    else
        for k,v in pairs(az_stone) do
            sampSendClickTextdraw(v[1])
            az_tochi = (az_workshop_check and true or false)
            break
        end
    end
end

function az_checkWorkshopStatus()
    evalanon([[
        try {
            const bodyText = (document.body.innerText || document.body.textContent || '').toUpperCase();
            const hasKeywords = bodyText.includes('WORKSHOP') || bodyText.includes('ВЕРСТАК') || bodyText.includes('МАСТЕРСКАЯ') || bodyText.includes('ENCHANT') || bodyText.includes('ЗАТОЧКА');
            const hasEnchantElements = document.querySelectorAll('[class*="enchant"], [class*="Enchant"], [id*="enchant"]').length > 0;
            const hasWorkshopElements = document.querySelectorAll('[class*="workshop"], [class*="Workshop"], [id*="workshop"]').length > 0;
            let hasStoneElements = document.querySelectorAll('[data-item-id="1187"], [data-model="1187"], [data-id="1187"]').length > 0;
            if (!hasStoneElements) {
                const inventoryItems = document.querySelectorAll('.inventory-item-hoc');
                for (let item of inventoryItems) {
                    const img = item.querySelector('.inventory-item__image');
                    if (img) {
                        const alt = img.getAttribute('alt') || '';
                        const itemId = parseInt(alt.match(/\d+/)?.[0]) || 0;
                        if (itemId === 1187) { hasStoneElements = true; break; }
                    }
                }
            }
            if (hasKeywords || hasEnchantElements || hasWorkshopElements || hasStoneElements || window.enchantInterfaceOpen === true || window.workshopOpen === true) window.workshopDetected = true;
            else window.workshopDetected = false;
        } catch(e) { window.workshopDetected = false; }
    ]])
end

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

function encodeUrl(str, alreadyUtf8)
    str = str:gsub(' ', '%+')
    str = str:gsub('\n', '%%0A')
    return alreadyUtf8 and str or u8(str)
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

    msg = u8(msg)
    msg = replaceItemCodes(msg)
    msg = msg:gsub('{......}', '')
    msg = encodeUrl(msg, true)
    
    local reply_markup = keyboard or '{"keyboard": [["👤 Статистика"], ["💬 | Семейный чат", "📝 Команды"]] , "resize_keyboard": true}'
    
    async_http_request('https://api.telegram.org/bot' .. settings.telegram.token .. '/sendMessage?chat_id=' .. settings.telegram.chat_id .. '&reply_markup=' .. reply_markup .. '&text='..msg, '', function(result)
    end)
end

function get_telegram_updates()
    while not updateid do wait(1) end
    local runner = requestRunner()
    local reject = function() end
    local args = ''
    while true do
        local offset = (updateid and (updateid + 1)) or 1
        local url = 'https://api.telegram.org/bot'..settings.telegram.token..'/getUpdates?offset='..tostring(offset)..'&timeout=25'
        threadHandle(runner, url, args, processing_telegram_messages, reject)
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
            local chat_id_ok = (msg.chat and tostring(msg.chat.id) == tostring(settings.telegram.chat_id))
            if not chat_id_ok then goto continue end
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
    async_http_request('https://api.telegram.org/bot'..settings.telegram.token..'/getUpdates?offset=-1&limit=1', '', function(result)
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
    elseif err then
        reject(err)
    elseif status == 'canceled' then
        reject(status)
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
            local txt = table.remove(vk_pending_messages, 1)
            if txt and txt ~= '' then
                pcall(processing_vkontakte_messages, txt)
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

function processing_vkontakte_messages(text)
    if not text or text == '' then return end
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
                if etype == 4 or etype == '4' then
                    msg_text = tostring(update[7] or update["7"] or update[6] or update["6"] or ''):gsub('^%s+', ''):gsub('%s+$', '')
                else
                    local obj = update.object
                    if obj then
                        local msg = obj.message or obj
                        msg_text = (msg and (msg.text or msg.body)) or ''
                    end
                end
                if msg_text and msg_text ~= '' then
                    table.insert(vk_pending_messages, msg_text)
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
	if settings.telegram.tg_rent then
		if text:find(u8:decode'^{8A2BE2}%[Arizona Rent%] {FFFFFF}Вы успешно сдали комнату в доме №(%d) в аренду игроку (%w+_%w+), на (%d) ч. за $(.+)!') then
			sendTelegramNotification(text)
		end
	end
	if settings.vkontakte.vk_rent then
		if text:find(u8:decode'^{8A2BE2}%[Arizona Rent%] {FFFFFF}Вы успешно сдали комнату в доме №(%d) в аренду игроку (%w+_%w+), на (%d) ч. за $(.+)!') then
			sendVkontakteNotification(text)
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
		end
	end
	if settings.vkontakte.vk_arenda then
		if text:find(u8:decode'^%[Аренда авто%] (%w+_%w+) %[ID: (%d+)%] арендовал у вас (.*) на (%d+)ч за (.*)$') then
		local nick,id,item,hours,summa = text:match(u8:decode'%[Аренда авто%] (%w+_%w+) %[ID: (%d+)%] арендовал у вас (.*) на (%d+)ч за (.*)$ %(в час(.*)%)')
			if nick and id and item and hours and summa then
			sendVkontakteNotification(separator(string.format(u8:decode'[Аренда] %s[%s] арендовал %s на %sч за %s', nick,id,item,hours,summa)))
			end
		end
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
	if text:find(u8:decode'^%[Альянс%](.*)') then
		local cvet, nick, ider, vivod = text:match(u8:decode'^%[Альянс%] (.*) (%w+_%w+)%[(.*)]:(.*)')
		if cvet and nick and ider and vivod and colorchat then
			sampAddChatMessage(intToHex(join_argb(colorchat[3] * 255, colorchat[0] * 255, colorchat[1] * 255, colorchat[2] * 255))..u8:decode'[Альянс] '..cvet..' '..nick..'['..ider..']:{B9C1B8}'..vivod, -1)
		end
		return false
	end
	if text:find(u8:decode'^{......}%[Семья%]') then
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
	-- Автозаточка: обработка сообщений заточки
	if az_max_toch > 0 and text and #text > 0 then
		local t = text:gsub("%{%x%x%x%x%x%x%}", "")
		local PATTERN_FAIL_AZ = u8:decode("Увы, вам не удалось улучшить предмет .* . %+%d+ на %+%d+")
		local PATTERN_SUCCESS_AZ = u8:decode("Успех! Вам удалось улучшить предмет .* . %+%d+ на %+(%d+)")
		local PATTERN_OLD_AZ = u8:decode("Отлично! Вы смогли заточить оружие .+ с %+%d+ до %+(%d+)")
		local PATTERN_FAIL_U8_AZ = "Увы, вам не удалось улучшить предмет .* . %+%d+ на %+%d+"
		local PATTERN_SUCCESS_U8_AZ = "Успех! Вам удалось улучшить предмет .* . %+%d+ на %+(%d+)"
		if t:find(PATTERN_FAIL_AZ) or t:find(PATTERN_FAIL_U8_AZ) then
			az_tochi = true
			az_all_lost = az_all_lost + 1
			az_lost_stone_onLVL = az_lost_stone_onLVL + 1
		end
		local tochLVL = t:match(PATTERN_SUCCESS_AZ) or t:match(PATTERN_SUCCESS_U8_AZ)
		if not tochLVL then tochLVL = t:match(PATTERN_OLD_AZ) end
		if tochLVL then
			if az_playSound[0] then addOneOffSound(0.0, 0.0, 0.0, 1139) end
			az_lost_stone_onLVL = az_lost_stone_onLVL + 1
			tochLVL = tonumber(tochLVL)
			az_all_lost = az_all_lost + 1
			table.insert(az_lost_stone, {az_lost_stone_onLVL, tochLVL})
			az_lost_stone_onLVL = 0
			if tochLVL < tonumber(az_max_toch) then
				az_tochi = true
			elseif tochLVL == tonumber(az_max_toch) then
				az_tochi = false
				az_max_toch = 0
				az_stone_check = false
				az_status = false
			end
		end
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

function sampev.onShowTextDraw(id, data)
    if data.text and (data.text:find('WORKSHOP') or data.text:find('МАСТЕРСКАЯ') or data.text:find('Мастерская') or data.text:find('ВЕРСТАК') or data.text:find('Верстак') or data.text:find('верстак')) then
        az_stone = {}
        az_workshop_check = true
    end
    if data.text and (data.text:find('ENCHANT') or data.text:find('ЗАТОЧКА') or data.text:find('Заточка')) then
        az_button_id = id - 1
    end
    if data.letterColor == -10398017 and data.lineWidth == 44 and data.lineHeight == 16 and data.position.x < 200 then
        az_button_id = id
    end
    if az_workshop_check then
        if az_stone_check then
            if data.lineWidth >= 1 then
                az_stone_check = false
            end
        end
        if data.modelId == Whetstone_ITEM_ID and data.selectable == 1 then
            table.insert(az_stone, {id})
        end
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
        if not doesFileExist(getWorkingDirectory()..'\\MiniHelper\\'..v['file_name']) then
            notifications.debug(u8:decode'Загружаю: ' .. v['file_name'], 7000)
            downloadUrlToFile(v['url'], getWorkingDirectory()..'\\MiniHelper\\'..v['file_name'])
        end

        local stream = loadAudioStream(getWorkingDirectory()..'\\MiniHelper\\'..v['file_name'])
        if stream then
            table.insert(sound_streams, stream)
        end
    end
	getLastUpdate()
	if settings.vkontakte.vk_active and settings.vkontakte.vk_token and settings.vkontakte.vk_token ~= '' and settings.vkontakte.vk_group_id and settings.vkontakte.vk_group_id ~= '' then
		initVK()
	end
	-- Автозаточка: обработчик CEF пакетов
	addEventHandler('onReceivePacket', function(id, bs)
		if id ~= 220 then return end
		raknetBitStreamIgnoreBits(bs, 8)
		local packetType = raknetBitStreamReadInt8(bs)
		if packetType == 17 then
			raknetBitStreamIgnoreBits(bs, 32)
			local length = raknetBitStreamReadInt16(bs)
			local encoded = raknetBitStreamReadInt8(bs)
			if length > 0 then
				local str = (encoded ~= 0) and raknetBitStreamDecodeString(bs, length + encoded) or raknetBitStreamReadString(bs, length)
				if not str then return end
				if str:find('updateEnchantSlots') then
					az_workshop_check = true
					local jsonData = str:match('updateEnchantSlots|(.+)')
					if jsonData then
						local index = jsonData:match('"index":(%d+)') or jsonData:match('"index":(%-?%d+)')
						local left = jsonData:match('"left":(%d+)') or jsonData:match('"left":(%-?%d+)')
						local right = jsonData:match('"right":(%d+)') or jsonData:match('"right":(%-?%d+)')
						local color = jsonData:match('"color":(%d+)') or jsonData:match('"color":(%-?%d+)')
						if index then az_enchantSlotsData.index = tonumber(index) end
						if left then az_enchantSlotsData.left = tonumber(left) end
						if right then az_enchantSlotsData.right = tonumber(right) end
						if color then az_enchantSlotsData.color = tonumber(color) end
						if az_enchantSlotsData.left == -1 and az_status and az_max_toch > 0 and not az_tochi then
							lua_thread.create(function()
								wait(300)
								az_click_onStone()
							end)
						end
					end
				end
			end
		end
		if packetType == 18 then
			local dataLength = raknetBitStreamReadInt16(bs)
			local encoded = raknetBitStreamReadInt8(bs)
			if dataLength > 0 then
				local data = (encoded ~= 0) and raknetBitStreamDecodeString(bs, dataLength + encoded) or raknetBitStreamReadString(bs, dataLength)
				if data and data:find('updateEnchantSlots') then
					az_workshop_check = true
				end
			end
		end
	end)
	-- Фоновое обновление наличия точильного камня
	lua_thread.create(function()
		while true do
			wait(Whetstone_CHECK_INTERVAL_MS)
			az_whetstone_detected = (getWhetstoneCount() > 0)
		end
	end)
	-- Цикл автозаточки
	lua_thread.create(function()
		evalanon([[
			window.enchantInterfaceOpen = false;
			window.workshopOpen = false;
			setInterval(function() {
				var bodyText = (document.body.innerText || document.body.textContent || '').toUpperCase();
				if (bodyText.includes('WORKSHOP') || bodyText.includes('ВЕРСТАК') || bodyText.includes('ENCHANT') || bodyText.includes('ЗАТОЧКА')) window.workshopOpen = true;
				if (document.querySelectorAll('[data-item-id="1187"], [data-model="1187"]').length > 0) window.workshopOpen = true;
			}, 1000);
		]])
		while true do
			wait(0)
			if az_status then
				if (az_workshop_check and az_tochi) then
					wait(1500)
					az_stone_check = true
					findAndClickEnchantButton()
					wait(200)
					startEnchant()
					if az_button_id > 0 then
						wait(200)
						sampSendClickTextdraw(az_button_id)
					end
					az_tochi = false
					wait(1500)
					if az_stone_check then
						if #az_stone > 0 then
							table.remove(az_stone, 1)
						end
						az_stone_check = false
						az_tochi = false
						wait(500)
						az_click_onStone()
					end
				elseif az_workshop_check and az_status and az_max_toch > 0 and not az_tochi then
					wait(1000)
					if #az_stone == 0 then
						findAndClickStone()
					else
						az_click_onStone()
					end
				elseif az_status and az_max_toch > 0 and not az_workshop_check then
					wait(2000)
					az_checkWorkshopStatus()
					evalanon([[
						var bodyText = (document.body.innerText || '').toUpperCase();
						if (bodyText.includes('WORKSHOP') || bodyText.includes('ВЕРСТАК') || bodyText.includes('ENCHANT') || bodyText.includes('ЗАТОЧКА') || document.querySelectorAll('[data-item-id="1187"], [data-model="1187"]').length > 0 || window.workshopDetected === true || window.workshopOpen === true || window.enchantInterfaceOpen === true) window.workshopShouldBeOpen = true;
					]])
					az_workshop_check = true
					wait(500)
					az_click_onStone()
				end
			end
		end
	end)
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
        if imgui.GradientPB(tab == 3, fa.ICON_FA_PAPER_PLANE, 'УВЕДОМЛЕНИЯ', 0.40) then tab = 3 end
        if imgui.GradientPB(tab == 4, fa.ICON_FA_BUG, 'ПОЛЕЗНОЕ', 0.40) then tab = 4 end
		if imgui.GradientPB(tab == 5, fa.ICON_FA_HAMMER, 'АВТОЗАТОЧКА', 0.40) then tab = 5 end
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
						imgui.SetWindowSizeVec2(imgui.ImVec2(370, 355))
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
						if imgui.Checkbox('Получать уведомления о сдачи команты', telegram_rent) then
							settings.telegram.tg_rent = telegram_rent[0]
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
						imgui.SetWindowSizeVec2(imgui.ImVec2(370, 355))
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
						if imgui.Checkbox('Получать уведомления о сдачи команты', vkontakte_rent) then
							settings.vkontakte.vk_rent = vkontakte_rent[0]
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
						imgui.Text('Настройки → Аккаунт и внешний вид → Адрес страницы')
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
			-- Количество попыток (всего)
			imgui.Text('Количество попыток: ' .. tostring(az_all_lost))
			imgui.SameLine()
			if imgui.Button('Сбросить попытки', imgui.ImVec2(140, 24)) then
				az_lost_stone = {}
				az_all_lost = 0
				az_lost_stone_onLVL = 0
				az_max_toch = 0
				az_stone_check = false
				az_status = false
				az_tochi = false
				az_workshop_check = false
			end
			imgui.Separator()
			imgui.Text('Начать заточку (точить до уровня):')
			imgui.Separator()
			for i = 1, 12 do
				if imgui.ColoredButton('+'..tostring(i), imgui.ImVec2(30, 20), (i==az_max_toch and '32CD32' or 'F94242'), 50) then
					if az_max_toch ~= i then
						az_status = true
						az_max_toch = i
						lua_thread.create(function()
							wait(100)
							az_click_onStone()
						end)
					else
						az_status = false
						az_max_toch = 0
						az_tochi = false
						az_stone_check = false
						az_workshop_check = false
					end
				end
				if (i % 6) ~= 0 then imgui.SameLine() end
			end
        end

        imgui.EndChild()
    end
    imgui.End()
end)






---ХУЙНЯ
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

-- Кнопка с цветом (для автозаточки)
function imgui.ColoredButton(text, size, hex, trans)
    local r,g,b = tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))
    local a = 60
    if tonumber(trans) ~= nil and tonumber(trans) < 101 and tonumber(trans) > 0 then a = trans end
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(r/255, g/255, b/255, a/100))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(r/255, g/255, b/255, a/100))
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(r/255, g/255, b/255, a/100))
    local button = imgui.Button(text, size)
    imgui.PopStyleColor(3)
    return button
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
	

