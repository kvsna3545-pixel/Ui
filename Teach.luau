-- VOID UI | PRETTY EDITION
-- ฟีเจอร์ใหม่: เงา, ไล่สี, hover, แถบ active ของแท็บ, หัวข้อ section, แจ้งเตือน (Notify), เปิดหน้าต่างแบบ animation, ปรับขนาดอัตโนมัติบนมือถือ
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local VoidUI = {}

local Theme = {
    Background = Color3.fromRGB(13, 11, 24),
    Sidebar = Color3.fromRGB(19, 16, 33),
    Card = Color3.fromRGB(30, 26, 48),
    Hover = Color3.fromRGB(46, 39, 74),
    Accent = Color3.fromRGB(235, 75, 95),
    AccentGlow = Color3.fromRGB(255, 150, 60),
    Text = Color3.fromRGB(250, 248, 255),
    Muted = Color3.fromRGB(145, 138, 175),
    Border = Color3.fromRGB(65, 52, 95),
    Red = Color3.fromRGB(240, 90, 100),
    Green = Color3.fromRGB(100, 235, 130),
}

local ACCENT_SEQ = ColorSequence.new(Theme.Accent, Theme.AccentGlow)

---------------------------------------------------------------- helpers
local function create(class, props, parent)
    local obj = Instance.new(class)
    for key, value in pairs(props or {}) do obj[key] = value end
    if parent then obj.Parent = parent end
    return obj
end

local function corner(parent, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 14) }, parent)
end

local function stroke(parent, color, transparency, thickness)
    return create("UIStroke", {
        Color = color or Theme.Border,
        Transparency = transparency or 0,
        Thickness = thickness or 1.2,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function gradient(parent, seq, rotation)
    return create("UIGradient", { Color = seq or ACCENT_SEQ, Rotation = rotation or 0 }, parent)
end

local function tween(obj, duration, props, style, direction)
    if not obj or not obj.Parent then return end
    pcall(function()
        TweenService:Create(
            obj,
            TweenInfo.new(duration or 0.25, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out),
            props
        ):Play()
    end)
end

local function label(parent, text, size, color, font)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Text = text,
        TextSize = size or 14,
        TextColor3 = color or Theme.Text,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 24),
    }, parent)
end

local function createRipple(parent)
    if not parent or not parent.Parent then return end
    task.spawn(function()
        local ripple = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(0, 0),
            BackgroundColor3 = Theme.AccentGlow,
            BackgroundTransparency = 0.6,
            BorderSizePixel = 0,
            ZIndex = 50,
        }, parent)
        corner(ripple, 100)
        local maxSize = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 1.8
        local tw = TweenService:Create(ripple, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(maxSize, maxSize),
            BackgroundTransparency = 1,
        })
        tw.Completed:Connect(function()
            if ripple and ripple.Parent then ripple:Destroy() end
        end)
        tw:Play()
    end)
end

local function isPointer(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
end

-- การ์ดมาตรฐาน: มุมโค้ง ขอบ ไล่สีบาง ๆ และ hover
local function makeCard(parent, height, interactive)
    local f = create(interactive and "TextButton" or "Frame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, parent)
    if interactive then
        f.Text = ""
        f.AutoButtonColor = false
    end
    corner(f, 14)
    local st = stroke(f, Theme.Border, 0.2, 1.2)
    create("UIGradient", {
        Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 195, 232)),
        Rotation = 90,
    }, f)

    f.MouseEnter:Connect(function()
        tween(f, 0.15, { BackgroundColor3 = Theme.Hover })
        tween(st, 0.15, { Color = Theme.AccentGlow, Transparency = 0.25 })
    end)
    f.MouseLeave:Connect(function()
        tween(f, 0.2, { BackgroundColor3 = Theme.Card })
        tween(st, 0.2, { Color = Theme.Border, Transparency = 0.2 })
    end)
    return f, st
end

---------------------------------------------------------------- themes
-- เปลี่ยนธีมตอนรัน: VoidUI:SetTheme("Ocean") หรือส่งตารางสีเองก็ได้
VoidUI.Themes = {
    Crimson = {
        Background = Color3.fromRGB(13, 11, 24), Sidebar = Color3.fromRGB(19, 16, 33),
        Card = Color3.fromRGB(30, 26, 48), Hover = Color3.fromRGB(46, 39, 74),
        Border = Color3.fromRGB(65, 52, 95), Muted = Color3.fromRGB(145, 138, 175),
        Accent = Color3.fromRGB(235, 75, 95), AccentGlow = Color3.fromRGB(255, 150, 60),
    },
    Ocean = {
        Background = Color3.fromRGB(9, 16, 28), Sidebar = Color3.fromRGB(12, 22, 38),
        Card = Color3.fromRGB(18, 32, 54), Hover = Color3.fromRGB(28, 48, 78),
        Border = Color3.fromRGB(40, 68, 105), Muted = Color3.fromRGB(128, 150, 185),
        Accent = Color3.fromRGB(45, 140, 255), AccentGlow = Color3.fromRGB(0, 220, 230),
    },
    Emerald = {
        Background = Color3.fromRGB(10, 22, 18), Sidebar = Color3.fromRGB(13, 28, 23),
        Card = Color3.fromRGB(20, 40, 33), Hover = Color3.fromRGB(30, 60, 50),
        Border = Color3.fromRGB(45, 85, 70), Muted = Color3.fromRGB(130, 170, 155),
        Accent = Color3.fromRGB(30, 200, 120), AccentGlow = Color3.fromRGB(170, 235, 70),
    },
    Violet = {
        Background = Color3.fromRGB(16, 12, 30), Sidebar = Color3.fromRGB(22, 16, 40),
        Card = Color3.fromRGB(34, 26, 58), Hover = Color3.fromRGB(50, 38, 84),
        Border = Color3.fromRGB(80, 60, 125), Muted = Color3.fromRGB(150, 138, 185),
        Accent = Color3.fromRGB(150, 80, 255), AccentGlow = Color3.fromRGB(240, 100, 220),
    },
    Sunset = {
        Background = Color3.fromRGB(24, 12, 16), Sidebar = Color3.fromRGB(32, 16, 20),
        Card = Color3.fromRGB(46, 24, 30), Hover = Color3.fromRGB(68, 36, 44),
        Border = Color3.fromRGB(105, 55, 62), Muted = Color3.fromRGB(185, 140, 140),
        Accent = Color3.fromRGB(255, 95, 70), AccentGlow = Color3.fromRGB(255, 190, 50),
    },
    Mono = {
        Background = Color3.fromRGB(14, 14, 16), Sidebar = Color3.fromRGB(20, 20, 23),
        Card = Color3.fromRGB(30, 30, 34), Hover = Color3.fromRGB(46, 46, 52),
        Border = Color3.fromRGB(70, 70, 78), Muted = Color3.fromRGB(150, 150, 160),
        Accent = Color3.fromRGB(190, 190, 205), AccentGlow = Color3.fromRGB(255, 255, 255),
    },
}
VoidUI.ThemeOrder = { "Crimson", "Ocean", "Emerald", "Violet", "Sunset", "Mono" }
VoidUI.CurrentTheme = "Crimson"

local THEME_KEYS = { "Background", "Sidebar", "Card", "Hover", "Border", "Muted", "Accent", "AccentGlow" }
local COLOR_PROPS = { "BackgroundColor3", "TextColor3", "PlaceholderColor3", "ImageColor3", "ScrollBarImageColor3", "Color" }

local activeGuis = {}
local function trackGui(gui)
    table.insert(activeGuis, gui)
    gui.Destroying:Connect(function()
        for i, g in ipairs(activeGuis) do
            if g == gui then
                table.remove(activeGuis, i)
                break
            end
        end
    end)
end

function VoidUI:SetTheme(nameOrTable)
    local def = type(nameOrTable) == "string" and VoidUI.Themes[nameOrTable] or nameOrTable
    if type(def) ~= "table" then return false end

    -- map: สีเก่า -> สีใหม่
    local map = {}
    for _, k in ipairs(THEME_KEYS) do
        local new = def[k]
        if typeof(new) == "Color3" and Theme[k] ~= new then
            map[tostring(Theme[k])] = new
        end
    end
    for _, k in ipairs(THEME_KEYS) do
        if typeof(def[k]) == "Color3" then Theme[k] = def[k] end
    end
    ACCENT_SEQ = ColorSequence.new(Theme.Accent, Theme.AccentGlow)
    if type(nameOrTable) == "string" then VoidUI.CurrentTheme = nameOrTable end

    for _, gui in ipairs(activeGuis) do
        for _, inst in ipairs(gui:GetDescendants()) do
            if inst:IsA("UIGradient") then
                local changed = false
                local kps = {}
                for _, kp in ipairs(inst.Color.Keypoints) do
                    local nc = map[tostring(kp.Value)]
                    if nc then changed = true end
                    table.insert(kps, ColorSequenceKeypoint.new(kp.Time, nc or kp.Value))
                end
                if changed then inst.Color = ColorSequence.new(kps) end
            else
                for _, prop in ipairs(COLOR_PROPS) do
                    local ok, val = pcall(function() return inst[prop] end)
                    if ok and typeof(val) == "Color3" then
                        local nc = map[tostring(val)]
                        if nc then pcall(function() inst[prop] = nc end) end
                    end
                end
            end
        end
    end
    return true
end

---------------------------------------------------------------- window
function VoidUI:CreateWindow(options)
    options = options or {}
    local title = options.Title or "VOID UI"
    local subtitle = options.Subtitle or "PRETTY EDITION"

    local targetContainer
    local localPlayer = Players.LocalPlayer
    if localPlayer then
        targetContainer = localPlayer:FindFirstChildOfClass("PlayerGui")
    end
    targetContainer = targetContainer or CoreGui

    local gui = create("ScreenGui", {
        Name = "VoidUIPretty",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 100,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, targetContainer)

    trackGui(gui)
    local connections = {}
    local function track(conn)
        table.insert(connections, conn)
        return conn
    end
    gui.Destroying:Connect(function()
        for _, c in ipairs(connections) do
            pcall(function() c:Disconnect() end)
        end
        table.clear(connections)
    end)

    -- ปรับขนาดให้พอดีจอ (มือถือ)
    local guiScale = create("UIScale", { Scale = 1 }, gui)
    local function updateScale()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local vp = cam.ViewportSize
        guiScale.Scale = math.clamp(math.min(vp.X / 780, vp.Y / 540), 0.55, 1)
    end
    updateScale()
    pcall(function()
        track(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale))
    end)

    local window = {}
    local root, mainFrame, sidebar, content, floatingLogo, mobileToggleBtn, openScale, searchBox
    local applySearch
    local tabs = {}
    local isVisible = true

    ---------------------------------------------------------------- flags / config
    -- ทุก element ใส่ Flag = "ชื่อ" ได้ ค่าจะไปอยู่ใน window.Flags และถูกเซฟ/โหลดผ่าน SaveConfig / LoadConfig
    window.Flags = {}
    local setters = {}
    local toggleKey = options.ToggleKey or Enum.KeyCode.RightShift
    local listeningKeybind = false

    local function setFlag(flag, v)
        if flag then window.Flags[flag] = v end
    end
    local function register(flag, setter, initial)
        if not flag then return end
        window.Flags[flag] = initial
        setters[flag] = setter
    end

    local function encode(v)
        local t = typeof(v)
        if t == "Color3" then
            return { __c = { v.R, v.G, v.B } }
        elseif t == "EnumItem" then
            return { __k = v.Name }
        elseif t == "table" then
            local out = {}
            for i, x in ipairs(v) do out[i] = x end
            return out
        end
        return v
    end

    local function decode(v)
        if type(v) == "table" then
            if v.__c then return Color3.new(v.__c[1], v.__c[2], v.__c[3]) end
            if v.__k then return Enum.KeyCode[v.__k] end
        end
        return v
    end

    local CONFIG_ROOT, CONFIG_DIR = "VoidUI", "VoidUI/configs"
    local canFS = type(writefile) == "function" and type(readfile) == "function"
    local memStore = {} -- ถ้าไม่มี writefile จะเก็บไว้ในหน่วยความจำ (หายเมื่อปิดเกม)

    local function cleanName(name)
        name = tostring(name or ""):gsub("[^%w%-%_ ]", "")
        if name == "" then name = "default" end
        return name
    end

    local function ensureFolders()
        if type(makefolder) ~= "function" or type(isfolder) ~= "function" then return end
        pcall(function()
            if not isfolder(CONFIG_ROOT) then makefolder(CONFIG_ROOT) end
            if not isfolder(CONFIG_DIR) then makefolder(CONFIG_DIR) end
        end)
    end

    function window:SaveConfig(name)
        name = cleanName(name)
        local data = {}
        for flag, v in pairs(window.Flags) do data[flag] = encode(v) end
        local okEnc, json = pcall(HttpService.JSONEncode, HttpService, data)
        if not okEnc then return false, "encode failed" end
        if canFS then
            ensureFolders()
            local ok, err = pcall(writefile, CONFIG_DIR .. "/" .. name .. ".json", json)
            return ok, err
        end
        memStore[name] = json
        return true
    end

    function window:LoadConfig(name)
        name = cleanName(name)
        local json
        if canFS then
            local ok, res = pcall(readfile, CONFIG_DIR .. "/" .. name .. ".json")
            if not ok then return false, "config not found" end
            json = res
        else
            json = memStore[name]
            if not json then return false, "config not found" end
        end
        local ok, data = pcall(HttpService.JSONDecode, HttpService, json)
        if not ok or type(data) ~= "table" then return false, "invalid config" end
        for flag, v in pairs(data) do
            local setter = setters[flag]
            if setter then pcall(setter, decode(v)) end
        end
        return true
    end

    function window:ListConfigs()
        local out = {}
        if canFS and type(listfiles) == "function" then
            pcall(function()
                for _, path in ipairs(listfiles(CONFIG_DIR)) do
                    local n = path:match("([^/\\]+)%.json$")
                    if n then table.insert(out, n) end
                end
            end)
        else
            for n in pairs(memStore) do table.insert(out, n) end
        end
        table.sort(out)
        return out
    end

    function window:DeleteConfig(name)
        name = cleanName(name)
        if canFS and type(delfile) == "function" then
            return pcall(delfile, CONFIG_DIR .. "/" .. name .. ".json")
        end
        memStore[name] = nil
        return true
    end

    function window:SetToggleKey(key)
        toggleKey = key
    end

    function window:Destroy()
        gui:Destroy()
    end

    function window:SetTheme(nameOrTable)
        return VoidUI:SetTheme(nameOrTable)
    end

    ---------------------------------------------------------------- dialog
    function window:Dialog(opts)
        opts = opts or {}
        local buttons = opts.Buttons or { { Name = "OK" } }

        local dim = create("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Active = true,
            ZIndex = 300,
        }, gui)
        tween(dim, 0.25, { BackgroundTransparency = 0.5 })

        local box = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(330, 170),
            BackgroundColor3 = Theme.Card,
            BorderSizePixel = 0,
        }, dim)
        corner(box, 16)
        stroke(box, Theme.AccentGlow, 0.3, 1.5)
        local sc = create("UIScale", { Scale = 0.88 }, box)
        tween(sc, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)

        local t = label(box, opts.Title or "Confirm", 15, Theme.Text, Enum.Font.GothamBold)
        t.Position = UDim2.fromOffset(20, 16)
        t.Size = UDim2.new(1, -40, 0, 24)
        local d = label(box, opts.Text or "", 12, Theme.Muted, Enum.Font.Gotham)
        d.Position = UDim2.fromOffset(20, 46)
        d.Size = UDim2.new(1, -40, 0, 62)
        d.TextYAlignment = Enum.TextYAlignment.Top

        local n = #buttons
        local gap = 8
        local totalW = 330 - 40
        local bw = (totalW - (n - 1) * gap) / n
        local function closeDialog()
            tween(dim, 0.2, { BackgroundTransparency = 1 })
            tween(sc, 0.2, { Scale = 0.9 }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            task.delay(0.22, function() if dim and dim.Parent then dim:Destroy() end end)
        end

        for i, b in ipairs(buttons) do
            local primary = (i == 1)
            local btn = create("TextButton", {
                Position = UDim2.new(0, 20 + (i - 1) * (bw + gap), 1, -56),
                Size = UDim2.new(0, bw, 0, 40),
                BackgroundColor3 = primary and Color3.new(1, 1, 1) or Theme.Background,
                Text = b.Name or "OK",
                TextSize = 12,
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamBold,
                AutoButtonColor = false,
                ClipsDescendants = true,
            }, box)
            corner(btn, 10)
            if primary then
                gradient(btn, ACCENT_SEQ, 0)
            else
                stroke(btn, Theme.Border, 0.3, 1)
            end
            btn.Activated:Connect(function()
                createRipple(btn)
                closeDialog()
                if b.Callback then task.spawn(pcall, b.Callback) end
            end)
        end
    end

    local function playOpen()
        openScale.Scale = 0.9
        tween(openScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
    end

    local function buildMainUI()
        -- root = ตัวที่ถูกลาก มีเงาอยู่ด้านหลัง mainFrame
        root = create("Frame", {
            Name = "Root",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(720, 480),
            BackgroundTransparency = 1,
        }, gui)
        openScale = create("UIScale", { Scale = 1 }, root)

        create("ImageLabel", {
            Name = "Shadow",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, 50, 1, 50),
            Image = "rbxassetid://6014261993",
            ImageColor3 = Color3.new(0, 0, 0),
            ImageTransparency = 0.45,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(49, 49, 450, 450),
            ZIndex = 0,
        }, root)

        mainFrame = create("Frame", {
            Name = "Main",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Theme.Background,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 1,
        }, root)
        corner(mainFrame, 18)
        local mainStroke = stroke(mainFrame, Color3.new(1, 1, 1), 0.2, 2)
        local g = gradient(mainStroke, ACCENT_SEQ, 45)
        -- ขอบหมุนสีเบา ๆ
        task.spawn(function()
            while gui.Parent do
                g.Rotation = (g.Rotation + 1) % 360
                task.wait(0.03)
            end
        end)

        -- ปุ่มลอย (ตอนซ่อนเมนู)
        floatingLogo = create("TextButton", {
            Name = "FloatingLogo",
            Position = UDim2.new(0, 20, 0, 20),
            Size = UDim2.fromOffset(50, 50),
            BackgroundColor3 = Color3.new(1, 1, 1),
            Text = "⚡",
            TextSize = 22,
            TextColor3 = Theme.Text,
            Font = Enum.Font.GothamBlack,
            AutoButtonColor = false,
            Visible = false,
            ZIndex = 100,
            ClipsDescendants = true,
        }, gui)
        corner(floatingLogo, 25)
        gradient(floatingLogo, ACCENT_SEQ, 45)
        stroke(floatingLogo, Theme.Text, 0.7, 1.5)

        mobileToggleBtn = create("TextButton", {
            Name = "MobileToggle",
            Position = UDim2.new(0, 20, 0, 90),
            Size = UDim2.fromOffset(52, 52),
            BackgroundColor3 = Theme.Card,
            Text = "MENU",
            TextSize = 11,
            TextColor3 = Theme.Text,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = false,
            ZIndex = 100,
            ClipsDescendants = true,
        }, gui)
        corner(mobileToggleBtn, 26)
        local mts = stroke(mobileToggleBtn, Color3.new(1, 1, 1), 0.2, 2)
        gradient(mts, ACCENT_SEQ, 45)

        local function toggleUI()
            isVisible = not isVisible
            root.Visible = isVisible
            floatingLogo.Visible = not isVisible
            if isVisible then playOpen() end
        end
        track(floatingLogo.Activated:Connect(function() createRipple(floatingLogo) toggleUI() end))
        track(mobileToggleBtn.Activated:Connect(function() createRipple(mobileToggleBtn) toggleUI() end))

        -- ปุ่มลัดซ่อน/แสดงเมนู (ค่าเริ่มต้น RightShift เปลี่ยนด้วย ToggleKey หรือ window:SetToggleKey)
        track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or listeningKeybind then return end
            if input.KeyCode == toggleKey then toggleUI() end
        end))

        -- แถบหัว
        local top = create("Frame", {
            Size = UDim2.new(1, 0, 0, 68),
            BackgroundColor3 = Theme.Sidebar,
            BorderSizePixel = 0,
            ZIndex = 2,
        }, mainFrame)
        corner(top, 18)
        create("Frame", { -- ปิดมุมโค้งด้านล่างของแถบหัว
            Position = UDim2.new(0, 0, 1, -18),
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundColor3 = Theme.Sidebar,
            BorderSizePixel = 0,
            ZIndex = 2,
        }, top)
        local line = create("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(1, 0, 0, 2),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 3,
        }, top)
        create("UIGradient", {
            Color = ACCENT_SEQ,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0.6, 0.3),
                NumberSequenceKeypoint.new(1, 1),
            }),
        }, line)

        local logo = create("Frame", {
            Position = UDim2.fromOffset(16, 14),
            Size = UDim2.fromOffset(40, 40),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 3,
        }, top)
        corner(logo, 12)
        gradient(logo, ACCENT_SEQ, 45)
        local logoText = label(logo, "⚡", 20, Theme.Text, Enum.Font.GothamBlack)
        logoText.Size = UDim2.fromScale(1, 1)
        logoText.TextXAlignment = Enum.TextXAlignment.Center
        logoText.ZIndex = 4

        local t1 = label(top, title, 16, Theme.Text, Enum.Font.GothamBold)
        t1.Position = UDim2.fromOffset(68, 14)
        t1.ZIndex = 3
        local t2 = label(top, subtitle, 10, Theme.AccentGlow, Enum.Font.GothamBold)
        t2.Position = UDim2.fromOffset(69, 36)
        t2.ZIndex = 3

        local close = create("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -16, 0.5, 0),
            Size = UDim2.fromOffset(32, 32),
            BackgroundColor3 = Theme.Card,
            Text = "×",
            TextSize = 22,
            TextColor3 = Theme.Text,
            Font = Enum.Font.Gotham,
            AutoButtonColor = false,
            ZIndex = 4,
            ClipsDescendants = true,
        }, top)
        corner(close, 16)
        stroke(close, Theme.Border, 0.4)
        close.MouseEnter:Connect(function() tween(close, 0.15, { BackgroundColor3 = Theme.Red }) end)
        close.MouseLeave:Connect(function() tween(close, 0.2, { BackgroundColor3 = Theme.Card }) end)
        close.Activated:Connect(function() gui:Destroy() end)

        -- ลากหน้าต่าง
        local dragging, dragStart, startPosition = false, Vector2.zero, UDim2.new()
        track(top.InputBegan:Connect(function(input)
            if isPointer(input) then
                dragging = true
                dragStart = input.Position
                startPosition = root.Position
            end
        end))
        track(UserInputService.InputChanged:Connect(function(input)
            if dragging and isMove(input) then
                local delta = (input.Position - dragStart) / guiScale.Scale
                root.Position = UDim2.new(
                    startPosition.X.Scale, startPosition.X.Offset + delta.X,
                    startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
                )
            end
        end))
        track(UserInputService.InputEnded:Connect(function(input)
            if isPointer(input) then dragging = false end
        end))

        -- แถบข้าง
        sidebar = create("Frame", {
            Position = UDim2.fromOffset(0, 68),
            Size = UDim2.new(0, 160, 1, -68),
            BackgroundColor3 = Theme.Sidebar,
            BorderSizePixel = 0,
            ZIndex = 2,
        }, mainFrame)
        create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, sidebar)
        create("UIPadding", {
            PaddingTop = UDim.new(0, 14),
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
        }, sidebar)

        -- ช่องค้นหาฟีเจอร์ (กรอง element ในทุกแท็บ)
        local searchBg = create("Frame", {
            LayoutOrder = -1,
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = Theme.Card,
            BorderSizePixel = 0,
            ZIndex = 3,
        }, sidebar)
        corner(searchBg, 10)
        local searchStroke = stroke(searchBg, Theme.Border, 0.3, 1)
        searchBox = create("TextBox", {
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.new(1, -20, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            PlaceholderText = "Search...",
            PlaceholderColor3 = Theme.Muted,
            TextColor3 = Theme.Text,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
            ZIndex = 4,
        }, searchBg)
        searchBox.Focused:Connect(function()
            tween(searchStroke, 0.2, { Color = Theme.AccentGlow, Transparency = 0 })
        end)
        searchBox.FocusLost:Connect(function()
            tween(searchStroke, 0.2, { Color = Theme.Border, Transparency = 0.3 })
        end)
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            if applySearch then applySearch(searchBox.Text) end
        end)

        create("Frame", { -- เส้นแบ่ง sidebar
            Position = UDim2.new(0, 160, 0, 68),
            Size = UDim2.new(0, 1, 1, -68),
            BackgroundColor3 = Theme.Border,
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            ZIndex = 3,
        }, mainFrame)

        local footer = label(mainFrame, "VOID UI  •  v2.0", 10, Theme.Muted, Enum.Font.GothamMedium)
        footer.Position = UDim2.new(0, 16, 1, -28)
        footer.Size = UDim2.fromOffset(130, 20)
        footer.ZIndex = 4

        content = create("Frame", {
            Position = UDim2.new(0, 161, 0, 68),
            Size = UDim2.new(1, -161, 1, -68),
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            ZIndex = 2,
        }, mainFrame)

        playOpen()
    end

    ---------------------------------------------------------------- notify
    local notifyHolder
    function window:Notify(opts)
        opts = opts or {}
        if not notifyHolder then
            notifyHolder = create("Frame", {
                AnchorPoint = Vector2.new(1, 1),
                Position = UDim2.new(1, -16, 1, -16),
                Size = UDim2.fromOffset(270, 400),
                BackgroundTransparency = 1,
                ZIndex = 200,
            }, gui)
            create("UIListLayout", {
                Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Bottom,
            }, notifyHolder)
        end

        local wrap = create("Frame", {
            Size = UDim2.new(1, 0, 0, 58),
            BackgroundTransparency = 1,
        }, notifyHolder)
        local toast = create("Frame", {
            Position = UDim2.new(1.3, 0, 0, 0),
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Theme.Card,
            BorderSizePixel = 0,
            ClipsDescendants = true,
        }, wrap)
        corner(toast, 12)
        stroke(toast, Theme.AccentGlow, 0.4, 1.2)
        local bar = create("Frame", {
            Size = UDim2.new(0, 4, 1, 0),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
        }, toast)
        gradient(bar, ACCENT_SEQ, 90)
        local tl = label(toast, opts.Title or "Notice", 13, Theme.Text, Enum.Font.GothamBold)
        tl.Position = UDim2.fromOffset(16, 6)
        tl.Size = UDim2.new(1, -24, 0, 22)
        local dl = label(toast, opts.Text or "", 11, Theme.Muted, Enum.Font.Gotham)
        dl.Position = UDim2.fromOffset(16, 28)
        dl.Size = UDim2.new(1, -24, 0, 24)
        dl.TextYAlignment = Enum.TextYAlignment.Top

        tween(toast, 0.4, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Back)
        task.delay(opts.Duration or 3, function()
            if toast and toast.Parent then
                tween(toast, 0.3, { Position = UDim2.new(1.3, 0, 0, 0) }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
                task.wait(0.35)
            end
            if wrap and wrap.Parent then wrap:Destroy() end
        end)
    end

    ---------------------------------------------------------------- tabs
    local activeNav

    -- ระบบค้นหา: ซ่อน element ที่ไม่ตรง และซ่อนแท็บที่ไม่มีผลลัพธ์ (section/ข้อความจะถูกซ่อนตอนค้นหา)
    local searchables = {}
    local function addSearchable(entry, frame, name, static)
        table.insert(searchables, {
            entry = entry,
            frame = frame,
            name = string.lower(tostring(name or "")),
            static = static == true,
        })
    end

    applySearch = function(q)
        q = string.lower((tostring(q or ""):gsub("^%s+", ""):gsub("%s+$", "")))
        local counts = {}
        for _, s in ipairs(searchables) do
            local show
            if q == "" then
                show = true
            elseif s.static then
                show = false
            else
                show = string.find(s.name, q, 1, true) ~= nil
            end
            s.frame.Visible = show
            if show and q ~= "" then counts[s.entry] = (counts[s.entry] or 0) + 1 end
        end

        local firstMatch, currentHas = nil, false
        for _, t in ipairs(tabs) do
            local has = q == "" or (counts[t] or 0) > 0
            t.nav.Visible = has
            if q ~= "" and has then
                firstMatch = firstMatch or t
                if t.nav == activeNav then currentHas = true end
            end
        end
        if q ~= "" and firstMatch and not currentHas and firstMatch.activate then
            firstMatch.activate()
        end
    end

    function window:CreateTab(tabName, iconText)
        local tabObj = {}

        local nav = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = Theme.Sidebar,
            Text = "",
            AutoButtonColor = false,
            ClipsDescendants = true,
            ZIndex = 3,
        }, sidebar)
        corner(nav, 10)
        local indicator = create("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.fromOffset(3, 0),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 4,
        }, nav)
        corner(indicator, 2)
        gradient(indicator, ACCENT_SEQ, 90)

        local navText = label(nav, (iconText or "•") .. "   " .. tabName, 12, Theme.Muted, Enum.Font.GothamMedium)
        navText.Position = UDim2.fromOffset(14, 0)
        navText.Size = UDim2.new(1, -18, 1, 0)
        navText.ZIndex = 4

        local page = create("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.AccentGlow,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
        }, content)
        create("UIPadding", {
            PaddingTop = UDim.new(0, 16),
            PaddingLeft = UDim.new(0, 16),
            PaddingRight = UDim.new(0, 16),
            PaddingBottom = UDim.new(0, 16),
        }, page)
        create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, page)

        local entry = { page = page, nav = nav, text = navText, indicator = indicator }

        local function setActive(e, state)
            tween(e.nav, 0.2, { BackgroundColor3 = state and Theme.Card or Theme.Sidebar })
            tween(e.indicator, 0.25, { Size = UDim2.fromOffset(3, state and 20 or 0) })
            e.text.TextColor3 = state and Theme.Text or Theme.Muted
        end

        local function activate()
            createRipple(nav)
            for _, item in ipairs(tabs) do
                item.page.Visible = false
                setActive(item, false)
            end
            activeNav = nav
            page.Position = UDim2.fromOffset(0, 12)
            page.Visible = true
            tween(page, 0.3, { Position = UDim2.fromOffset(0, 0) })
            setActive(entry, true)
        end

        nav.MouseEnter:Connect(function()
            if activeNav ~= nav then tween(nav, 0.15, { BackgroundColor3 = Theme.Hover }) end
        end)
        nav.MouseLeave:Connect(function()
            if activeNav ~= nav then tween(nav, 0.2, { BackgroundColor3 = Theme.Sidebar }) end
        end)
        nav.Activated:Connect(activate)
        entry.activate = activate

        table.insert(tabs, entry)
        if #tabs == 1 then
            activeNav = nav
            page.Visible = true
            nav.BackgroundColor3 = Theme.Card
            indicator.Size = UDim2.fromOffset(3, 20)
            navText.TextColor3 = Theme.Text
        end

        -- Section header
        function tabObj:CreateSection(name)
            local f = create("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1 }, page)
            f:SetAttribute("IsSection", true)
            addSearchable(entry, f, "", true)
            local l = label(f, string.upper(name or "SECTION"), 10, Theme.AccentGlow, Enum.Font.GothamBold)
            l.Size = UDim2.new(1, 0, 0, 20)
            local ln = create("Frame", {
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, 0, 1, 0),
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
            }, f)
            create("UIGradient", {
                Color = ACCENT_SEQ,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.2),
                    NumberSequenceKeypoint.new(1, 1),
                }),
            }, ln)
        end

        -- Button
        function tabObj:CreateButton(opts)
            opts = opts or {}
            local button = makeCard(page, 48, true)
            addSearchable(entry, button, opts.Name or "Button")
            local dot = create("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 14, 0.5, 0),
                Size = UDim2.fromOffset(6, 6),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
            }, button)
            corner(dot, 3)
            gradient(dot, ACCENT_SEQ, 45)
            local lbl = label(button, opts.Name or "Button", 13, Theme.Text, Enum.Font.GothamMedium)
            lbl.Position = UDim2.fromOffset(30, 0)
            lbl.Size = UDim2.new(1, -44, 1, 0)
            button.Activated:Connect(function()
                createRipple(button)
                if opts.Callback then task.spawn(pcall, opts.Callback) end
            end)
        end

        -- Toggle
        function tabObj:CreateToggle(opts)
            opts = opts or {}
            local value = opts.Default == true
            local methods = {}

            local row = makeCard(page, 52, true)
            addSearchable(entry, row, opts.Name or "Toggle")
            local lbl = label(row, opts.Name or "Toggle", 13, Theme.Text, Enum.Font.GothamMedium)
            lbl.Position = UDim2.fromOffset(14, 0)
            lbl.Size = UDim2.new(1, -80, 1, 0)

            local trackF = create("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -14, 0.5, 0),
                Size = UDim2.fromOffset(44, 24),
                BackgroundColor3 = value and Color3.new(1, 1, 1) or Theme.Border,
                BorderSizePixel = 0,
            }, row)
            corner(trackF, 12)
            local grad = gradient(trackF, ACCENT_SEQ, 0)
            grad.Enabled = value
            local knob = create("Frame", {
                Position = value and UDim2.new(1, -22, 0, 3) or UDim2.fromOffset(3, 3),
                Size = UDim2.fromOffset(18, 18),
                BackgroundColor3 = Theme.Text,
                BorderSizePixel = 0,
            }, trackF)
            corner(knob, 9)

            local function setValue(v, silent)
                value = v == true
                setFlag(opts.Flag, value)
                grad.Enabled = value
                tween(trackF, 0.25, { BackgroundColor3 = value and Color3.new(1, 1, 1) or Theme.Border })
                tween(knob, 0.25, { Position = value and UDim2.new(1, -22, 0, 3) or UDim2.fromOffset(3, 3) }, Enum.EasingStyle.Back)
                if not silent and opts.Callback then task.spawn(pcall, opts.Callback, value) end
            end

            methods.Set = function(_, v) setValue(v) end
            methods.Get = function() return value end
            register(opts.Flag, function(v) setValue(v) end, value)
            row.Activated:Connect(function()
                createRipple(row)
                setValue(not value)
            end)
            return methods
        end

        -- Slider
        function tabObj:CreateSlider(opts)
            opts = opts or {}
            local min = opts.Min or 0
            local max = opts.Max or 100
            if max <= min then max = min + 1 end
            local increment = opts.Increment or 1
            local value = math.clamp(opts.Default or min, min, max)
            local methods = {}

            local card = makeCard(page, 70, false)
            addSearchable(entry, card, opts.Name or "Slider")
            local nameLbl = label(card, opts.Name or "Slider", 13, Theme.Text, Enum.Font.GothamMedium)
            nameLbl.Position = UDim2.fromOffset(14, 8)
            nameLbl.Size = UDim2.new(1, -90, 0, 24)

            local valLabel = label(card, tostring(value), 13, Theme.AccentGlow, Enum.Font.GothamBold)
            valLabel.AnchorPoint = Vector2.new(1, 0)
            valLabel.Position = UDim2.new(1, -14, 0, 8)
            valLabel.Size = UDim2.fromOffset(70, 24)
            valLabel.TextXAlignment = Enum.TextXAlignment.Right

            local hit = create("TextButton", {
                Position = UDim2.new(0, 14, 0, 38),
                Size = UDim2.new(1, -28, 0, 24),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
            }, card)
            local bar = create("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.new(1, 0, 0, 8),
                BackgroundColor3 = Theme.Border,
                BorderSizePixel = 0,
            }, hit)
            corner(bar, 4)
            local fill = create("Frame", {
                Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
            }, bar)
            corner(fill, 4)
            gradient(fill, ACCENT_SEQ, 0)
            local knob = create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.fromOffset(16, 16),
                BackgroundColor3 = Theme.Text,
                BorderSizePixel = 0,
                ZIndex = 3,
            }, fill)
            corner(knob, 8)
            stroke(knob, Theme.AccentGlow, 0.2, 2)

            local function render()
                valLabel.Text = tostring(value)
                tween(fill, 0.08, { Size = UDim2.new((value - min) / (max - min), 0, 1, 0) })
            end

            local function setValue(v, silent)
                v = math.clamp(math.floor(v / increment + 0.5) * increment, min, max)
                if v == value then return end
                value = v
                setFlag(opts.Flag, value)
                render()
                if not silent and opts.Callback then task.spawn(pcall, opts.Callback, value) end
            end

            local dragging = false
            local function updateFromX(x)
                local rel = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
                setValue(min + (max - min) * rel)
            end

            hit.InputBegan:Connect(function(input)
                if isPointer(input) then
                    dragging = true
                    page.ScrollingEnabled = false
                    tween(knob, 0.15, { Size = UDim2.fromOffset(20, 20) })
                    updateFromX(input.Position.X)
                end
            end)
            track(UserInputService.InputChanged:Connect(function(input)
                if dragging and isMove(input) then updateFromX(input.Position.X) end
            end))
            track(UserInputService.InputEnded:Connect(function(input)
                if dragging and isPointer(input) then
                    dragging = false
                    page.ScrollingEnabled = true
                    tween(knob, 0.15, { Size = UDim2.fromOffset(16, 16) })
                end
            end))

            register(opts.Flag, function(v) setValue(v) end, value)
            methods.Set = function(_, v) setValue(v) end
            methods.Get = function() return value end
            return methods
        end

        -- Dropdown
        function tabObj:CreateDropdown(opts)
            opts = opts or {}
            local items = opts.Items or {}
            local selected = opts.Default or items[1] or ""
            local isOpen = false
            local methods = {}
            local ITEM_H, GAP = 34, 4

            local dropFrame = makeCard(page, 48, false)
            addSearchable(entry, dropFrame, opts.Name or "Dropdown")

            local titleLbl = label(dropFrame, "", 13, Theme.Text, Enum.Font.GothamMedium)
            titleLbl.Position = UDim2.fromOffset(14, 12)
            titleLbl.Size = UDim2.new(1, -50, 0, 24)

            local arrow = label(dropFrame, "v", 12, Theme.AccentGlow, Enum.Font.GothamBold)
            arrow.AnchorPoint = Vector2.new(1, 0)
            arrow.Position = UDim2.new(1, -16, 0, 12)
            arrow.Size = UDim2.fromOffset(16, 24)
            arrow.TextXAlignment = Enum.TextXAlignment.Center

            local function refreshTitle()
                titleLbl.Text = (opts.Name or "Dropdown") .. ":  " .. tostring(selected)
            end
            refreshTitle()

            local dropBtn = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 48),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 3,
            }, dropFrame)

            local list = create("Frame", {
                Position = UDim2.fromOffset(8, 52),
                Size = UDim2.new(1, -16, 0, 0),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
            }, dropFrame)
            create("UIListLayout", { Padding = UDim.new(0, GAP), SortOrder = Enum.SortOrder.LayoutOrder }, list)

            local function setOpen(state)
                isOpen = state
                local h = isOpen and (52 + #items * (ITEM_H + GAP) + 4) or 48
                tween(dropFrame, 0.28, { Size = UDim2.new(1, 0, 0, h) })
                tween(arrow, 0.2, { Rotation = isOpen and 180 or 0 })
            end

            local itemButtons = {}
            local function highlight()
                for name, btn in pairs(itemButtons) do
                    local on = (name == selected)
                    tween(btn, 0.15, { BackgroundColor3 = on and Theme.Hover or Theme.Background })
                    btn.TextColor3 = on and Theme.AccentGlow or Theme.Text
                end
            end

            local function choose(name, silent)
                selected = name
                setFlag(opts.Flag, name)
                refreshTitle()
                highlight()
                if not silent and opts.Callback then task.spawn(pcall, opts.Callback, selected) end
            end

            for i, name in ipairs(items) do
                local btn = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, ITEM_H),
                    BackgroundColor3 = Theme.Background,
                    Text = tostring(name),
                    TextSize = 12,
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.GothamMedium,
                    AutoButtonColor = false,
                    LayoutOrder = i,
                    ClipsDescendants = true,
                }, list)
                corner(btn, 8)
                itemButtons[name] = btn
                btn.MouseEnter:Connect(function()
                    if name ~= selected then tween(btn, 0.12, { BackgroundColor3 = Theme.Card }) end
                end)
                btn.MouseLeave:Connect(function()
                    if name ~= selected then tween(btn, 0.15, { BackgroundColor3 = Theme.Background }) end
                end)
                btn.Activated:Connect(function()
                    createRipple(btn)
                    choose(name)
                    setOpen(false)
                end)
            end
            highlight()

            dropBtn.Activated:Connect(function()
                createRipple(dropFrame)
                setOpen(not isOpen)
            end)

            register(opts.Flag, function(n) choose(n) end, selected)
            methods.Set = function(_, name) choose(name) end
            methods.Get = function() return selected end
            return methods
        end

        -- Input
        function tabObj:CreateInput(opts)
            opts = opts or {}
            local methods = {}

            local card = makeCard(page, 66, false)
            addSearchable(entry, card, opts.Name or "Input")
            local nl = label(card, opts.Name or "Input", 13, Theme.Text, Enum.Font.GothamMedium)
            nl.Position = UDim2.fromOffset(14, 6)

            local boxBg = create("Frame", {
                Position = UDim2.new(0, 14, 0, 33),
                Size = UDim2.new(1, -28, 0, 26),
                BackgroundColor3 = Theme.Background,
                BorderSizePixel = 0,
            }, card)
            corner(boxBg, 8)
            local boxStroke = stroke(boxBg, Theme.Border, 0.3, 1)

            local textBox = create("TextBox", {
                Size = UDim2.new(1, -16, 1, 0),
                Position = UDim2.fromOffset(8, 0),
                BackgroundTransparency = 1,
                Text = opts.Default or "",
                PlaceholderText = opts.Placeholder or "Type here...",
                PlaceholderColor3 = Theme.Muted,
                TextColor3 = Theme.Text,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
            }, boxBg)

            textBox.Focused:Connect(function()
                tween(boxStroke, 0.2, { Color = Theme.AccentGlow, Transparency = 0 })
            end)
            textBox.FocusLost:Connect(function()
                tween(boxStroke, 0.2, { Color = Theme.Border, Transparency = 0.3 })
                setFlag(opts.Flag, textBox.Text)
                if opts.Callback then task.spawn(pcall, opts.Callback, textBox.Text) end
            end)

            register(opts.Flag, function(t)
                textBox.Text = tostring(t)
                setFlag(opts.Flag, textBox.Text)
                if opts.Callback then task.spawn(pcall, opts.Callback, textBox.Text) end
            end, textBox.Text)
            methods.Set = function(_, text) textBox.Text = tostring(text) end
            methods.Get = function() return textBox.Text end
            return methods
        end

        -- Keybind: กดปุ่มทางขวาแล้วกดคีย์ที่ต้องการ (Esc = ล้างค่า)
        function tabObj:CreateKeybind(opts)
            opts = opts or {}
            local value = opts.Default
            local methods = {}

            local row = makeCard(page, 52, false)
            addSearchable(entry, row, opts.Name or "Keybind")
            local lbl = label(row, opts.Name or "Keybind", 13, Theme.Text, Enum.Font.GothamMedium)
            lbl.Position = UDim2.fromOffset(14, 0)
            lbl.Size = UDim2.new(1, -125, 1, 0)

            local keyBtn = create("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -14, 0.5, 0),
                Size = UDim2.fromOffset(94, 28),
                BackgroundColor3 = Theme.Background,
                Text = value and value.Name or "None",
                TextSize = 11,
                TextColor3 = Theme.AccentGlow,
                Font = Enum.Font.GothamBold,
                TextTruncate = Enum.TextTruncate.AtEnd,
                AutoButtonColor = false,
                ClipsDescendants = true,
            }, row)
            corner(keyBtn, 8)
            local ks = stroke(keyBtn, Theme.Border, 0.3, 1)

            local function setKey(k, silent)
                value = k or nil
                keyBtn.Text = value and value.Name or "None"
                setFlag(opts.Flag, value or false)
                if not silent and opts.OnChanged then task.spawn(pcall, opts.OnChanged, value) end
            end

            keyBtn.Activated:Connect(function()
                if listeningKeybind then return end
                createRipple(keyBtn)
                listeningKeybind = true
                keyBtn.Text = "..."
                tween(ks, 0.15, { Color = Theme.AccentGlow, Transparency = 0 })
                local conn
                conn = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        conn:Disconnect()
                        if input.KeyCode == Enum.KeyCode.Escape then setKey(nil) else setKey(input.KeyCode) end
                        tween(ks, 0.2, { Color = Theme.Border, Transparency = 0.3 })
                        task.defer(function() listeningKeybind = false end)
                    end
                end)
            end)

            -- เมื่อกดคีย์ที่ตั้งไว้ จะเรียก Callback
            track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed or listeningKeybind or not value then return end
                if input.KeyCode == value and opts.Callback then task.spawn(pcall, opts.Callback) end
            end))

            register(opts.Flag, function(k)
                if k == false or k == nil then setKey(nil, true) else setKey(k, true) end
            end, value or false)
            methods.Set = function(_, k) setKey(k) end
            methods.Get = function() return value end
            return methods
        end

        -- ColorPicker: แถบ Hue / Saturation / Value
        function tabObj:CreateColorPicker(opts)
            opts = opts or {}
            local h, s, v = Color3.toHSV(opts.Default or Color3.fromRGB(255, 90, 90))
            local isOpen = false
            local methods = {}

            local card = makeCard(page, 48, false)
            addSearchable(entry, card, opts.Name or "Color")
            local lbl = label(card, opts.Name or "Color", 13, Theme.Text, Enum.Font.GothamMedium)
            lbl.Position = UDim2.fromOffset(14, 12)
            lbl.Size = UDim2.new(1, -90, 0, 24)

            local swatch = create("Frame", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -14, 0, 13),
                Size = UDim2.fromOffset(40, 22),
                BackgroundColor3 = Color3.fromHSV(h, s, v),
                BorderSizePixel = 0,
            }, card)
            corner(swatch, 7)
            stroke(swatch, Theme.Text, 0.6, 1)

            local header = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 48),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 3,
            }, card)

            local refresh -- ประกาศก่อน เพราะแถบด้านล่างเรียกใช้

            local function mkRow(y, apply)
                local hit = create("TextButton", {
                    Position = UDim2.new(0, 14, 0, y),
                    Size = UDim2.new(1, -28, 0, 24),
                    BackgroundTransparency = 1,
                    Text = "",
                    AutoButtonColor = false,
                }, card)
                local bar = create("Frame", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.fromScale(0, 0.5),
                    Size = UDim2.new(1, 0, 0, 10),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                }, hit)
                corner(bar, 5)
                local g = create("UIGradient", {}, bar)
                local knob = create("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0, 0.5),
                    Size = UDim2.fromOffset(16, 16),
                    BackgroundColor3 = Theme.Text,
                    BorderSizePixel = 0,
                    ZIndex = 2,
                }, bar)
                corner(knob, 8)
                stroke(knob, Theme.Background, 0, 2)

                local dragging = false
                local function upd(x)
                    local rel = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
                    apply(rel)
                end
                hit.InputBegan:Connect(function(input)
                    if isPointer(input) then
                        dragging = true
                        page.ScrollingEnabled = false
                        upd(input.Position.X)
                    end
                end)
                track(UserInputService.InputChanged:Connect(function(input)
                    if dragging and isMove(input) then upd(input.Position.X) end
                end))
                track(UserInputService.InputEnded:Connect(function(input)
                    if dragging and isPointer(input) then
                        dragging = false
                        page.ScrollingEnabled = true
                    end
                end))
                return g, knob
            end

            local hueG, hueKnob = mkRow(56, function(r) h = r; refresh(true) end)
            local satG, satKnob = mkRow(88, function(r) s = r; refresh(true) end)
            local valG, valKnob = mkRow(120, function(r) v = r; refresh(true) end)

            hueG.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                ColorSequenceKeypoint.new(1 / 6, Color3.fromHSV(1 / 6, 1, 1)),
                ColorSequenceKeypoint.new(2 / 6, Color3.fromHSV(2 / 6, 1, 1)),
                ColorSequenceKeypoint.new(3 / 6, Color3.fromHSV(3 / 6, 1, 1)),
                ColorSequenceKeypoint.new(4 / 6, Color3.fromHSV(4 / 6, 1, 1)),
                ColorSequenceKeypoint.new(5 / 6, Color3.fromHSV(5 / 6, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(0, 1, 1)),
            })

            refresh = function(fire)
                local c = Color3.fromHSV(h, s, v)
                swatch.BackgroundColor3 = c
                satG.Color = ColorSequence.new(Color3.fromHSV(h, 0, v), Color3.fromHSV(h, 1, v))
                valG.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.fromHSV(h, s, 1))
                hueKnob.Position = UDim2.fromScale(h, 0.5)
                satKnob.Position = UDim2.fromScale(s, 0.5)
                valKnob.Position = UDim2.fromScale(v, 0.5)
                setFlag(opts.Flag, c)
                if fire and opts.Callback then task.spawn(pcall, opts.Callback, c) end
            end

            header.Activated:Connect(function()
                isOpen = not isOpen
                createRipple(card)
                tween(card, 0.28, { Size = UDim2.new(1, 0, 0, isOpen and 160 or 48) })
            end)

            refresh(false)
            register(opts.Flag, function(c)
                h, s, v = Color3.toHSV(c)
                refresh(true)
            end, Color3.fromHSV(h, s, v))
            methods.Set = function(_, c) h, s, v = Color3.toHSV(c) refresh(true) end
            methods.Get = function() return Color3.fromHSV(h, s, v) end
            return methods
        end

        -- MultiDropdown: เลือกได้หลายตัว Callback ได้ตารางรายการที่เลือก
        function tabObj:CreateMultiDropdown(opts)
            opts = opts or {}
            local items = opts.Items or {}
            local chosen = {}
            for _, n in ipairs(opts.Default or {}) do chosen[n] = true end
            local isOpen = false
            local methods = {}
            local ITEM_H, GAP = 34, 4

            local dropFrame = makeCard(page, 48, false)
            local titleLbl = label(dropFrame, "", 13, Theme.Text, Enum.Font.GothamMedium)
            titleLbl.Position = UDim2.fromOffset(14, 12)
            titleLbl.Size = UDim2.new(1, -50, 0, 24)
            titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
            addSearchable(entry, dropFrame, opts.Name or "Multi Dropdown")

            local arrow = label(dropFrame, "v", 12, Theme.AccentGlow, Enum.Font.GothamBold)
            arrow.AnchorPoint = Vector2.new(1, 0)
            arrow.Position = UDim2.new(1, -16, 0, 12)
            arrow.Size = UDim2.fromOffset(16, 24)
            arrow.TextXAlignment = Enum.TextXAlignment.Center

            local function selectedList()
                local out = {}
                for _, n in ipairs(items) do
                    if chosen[n] then table.insert(out, n) end
                end
                return out
            end

            local dropBtn = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 48),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 3,
            }, dropFrame)

            local list = create("Frame", {
                Position = UDim2.fromOffset(8, 52),
                Size = UDim2.new(1, -16, 0, 0),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
            }, dropFrame)
            create("UIListLayout", { Padding = UDim.new(0, GAP), SortOrder = Enum.SortOrder.LayoutOrder }, list)

            local buttons = {}
            local function paint()
                for name, b in pairs(buttons) do
                    local on = chosen[name] == true
                    tween(b.btn, 0.15, { BackgroundColor3 = on and Theme.Hover or Theme.Background })
                    b.btn.TextColor3 = on and Theme.AccentGlow or Theme.Text
                    b.dot.Visible = on
                end
            end

            local function commit(silent)
                local l = selectedList()
                local txt = (#l == 0) and "None" or (#l <= 2 and table.concat(l, ", ") or (#l .. " selected"))
                titleLbl.Text = (opts.Name or "Multi Dropdown") .. ":  " .. txt
                paint()
                setFlag(opts.Flag, l)
                if not silent and opts.Callback then task.spawn(pcall, opts.Callback, l) end
            end

            for i, name in ipairs(items) do
                local btn = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, ITEM_H),
                    BackgroundColor3 = Theme.Background,
                    Text = tostring(name),
                    TextSize = 12,
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutoButtonColor = false,
                    LayoutOrder = i,
                    ClipsDescendants = true,
                }, list)
                corner(btn, 8)
                create("UIPadding", { PaddingLeft = UDim.new(0, 28) }, btn)
                local dot = create("Frame", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, -18, 0.5, 0),
                    Size = UDim2.fromOffset(8, 8),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                    Visible = false,
                }, btn)
                corner(dot, 4)
                gradient(dot, ACCENT_SEQ, 45)
                buttons[name] = { btn = btn, dot = dot }
                btn.Activated:Connect(function()
                    createRipple(btn)
                    chosen[name] = (not chosen[name]) or nil
                    commit()
                end)
            end

            dropBtn.Activated:Connect(function()
                isOpen = not isOpen
                createRipple(dropFrame)
                local h = isOpen and (52 + #items * (ITEM_H + GAP) + 4) or 48
                tween(dropFrame, 0.28, { Size = UDim2.new(1, 0, 0, h) })
                tween(arrow, 0.2, { Rotation = isOpen and 180 or 0 })
            end)

            commit(true)
            register(opts.Flag, function(l)
                chosen = {}
                for _, n in ipairs(l or {}) do chosen[n] = true end
                commit()
            end, selectedList())
            methods.Set = function(_, l)
                chosen = {}
                for _, n in ipairs(l or {}) do chosen[n] = true end
                commit()
            end
            methods.Get = selectedList
            return methods
        end

        -- ตัวจัดการ Config (เซฟ / โหลด / ลบ / ดูรายชื่อ)
        function tabObj:CreateConfigManager()
            tabObj:CreateSection("Config")
            local nameInput = tabObj:CreateInput({ Name = "Config name", Default = "default", Placeholder = "default" })
            tabObj:CreateButton({
                Name = "Save config",
                Callback = function()
                    local ok, err = window:SaveConfig(nameInput:Get())
                    window:Notify({
                        Title = ok and "Config saved" or "Save failed",
                        Text = ok and nameInput:Get() or tostring(err),
                    })
                end,
            })
            tabObj:CreateButton({
                Name = "Load config",
                Callback = function()
                    local ok, err = window:LoadConfig(nameInput:Get())
                    window:Notify({
                        Title = ok and "Config loaded" or "Load failed",
                        Text = ok and nameInput:Get() or tostring(err),
                    })
                end,
            })
            tabObj:CreateButton({
                Name = "Delete config",
                Callback = function()
                    local n = nameInput:Get()
                    window:Dialog({
                        Title = "Delete config?",
                        Text = "Config \"" .. n .. "\" will be permanently deleted.",
                        Buttons = {
                            { Name = "Delete", Callback = function()
                                window:DeleteConfig(n)
                                window:Notify({ Title = "Config deleted", Text = n })
                            end },
                            { Name = "Cancel" },
                        },
                    })
                end,
            })
            tabObj:CreateButton({
                Name = "List configs",
                Callback = function()
                    local l = window:ListConfigs()
                    window:Notify({
                        Title = "Configs (" .. #l .. ")",
                        Text = #l > 0 and table.concat(l, ", ") or "No saved configs",
                        Duration = 4,
                    })
                end,
            })
        end

        -- ตัวเลือกธีม (Dropdown เปลี่ยนสีทั้ง UI ทันที และเซฟลง config ได้)
        function tabObj:CreateThemePicker()
            tabObj:CreateSection("Theme")
            return tabObj:CreateDropdown({
                Name = "Theme",
                Items = VoidUI.ThemeOrder,
                Default = VoidUI.CurrentTheme,
                Flag = "theme",
                Callback = function(name) VoidUI:SetTheme(name) end,
            })
        end

        -- Text
        function tabObj:CreateText(textString)
            local lbl = label(page, textString or "Text Info", 12, Theme.Muted, Enum.Font.Gotham)
            addSearchable(entry, lbl, "", true)
            lbl.AutomaticSize = Enum.AutomaticSize.Y
            lbl.Size = UDim2.new(1, 0, 0, 24)
            return { Set = function(_, t) lbl.Text = tostring(t) end }
        end

        return tabObj
    end

    buildMainUI()
    return window
end

---------------------------------------------------------------- key window
-- หน้ากรอกคีย์ก่อนเข้าเมนู
-- VoidUI:CreateKeyWindow({
--     Title = "VOID UI", Subtitle = "KEY SYSTEM",
--     Keys = { "VOID-1234", "VOID-5678" },   -- หรือ Key = "VOID-1234"
--     KeyLink = "https://...",               -- (ไม่บังคับ) ปุ่ม Get Key จะคัดลอกลิงก์ให้
--     MaxAttempts = 5,                       -- (ไม่บังคับ) ผิดเกินนี้จะล็อกช่องกรอก
--     Callback = function() ... end,         -- เรียกเมื่อคีย์ถูกต้อง (สร้างเมนูหลักตรงนี้)
-- })
function VoidUI:CreateKeyWindow(options)
    options = options or {}
    local title = options.Title or "VOID UI"
    local subtitle = options.Subtitle or "KEY SYSTEM"

    local valid = {}
    if options.Key then valid[tostring(options.Key)] = true end
    for _, k in ipairs(options.Keys or {}) do valid[tostring(k)] = true end

    local targetContainer
    local localPlayer = Players.LocalPlayer
    if localPlayer then
        targetContainer = localPlayer:FindFirstChildOfClass("PlayerGui")
    end
    targetContainer = targetContainer or CoreGui

    local gui = create("ScreenGui", {
        Name = "VoidUIKey",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 110,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, targetContainer)

    local guiScale = create("UIScale", { Scale = 1 }, gui)
    local function updateScale()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local vp = cam.ViewportSize
        guiScale.Scale = math.clamp(math.min(vp.X / 460, vp.Y / 340), 0.6, 1)
    end
    updateScale()
    local scaleConn
    pcall(function()
        scaleConn = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
    end)
    gui.Destroying:Connect(function()
        if scaleConn then scaleConn:Disconnect() end
    end)

    trackGui(gui)
    -- พื้นหลังมืดทั้งจอ
    local dim = create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = true, -- กันคลิกทะลุ
    }, gui)
    tween(dim, 0.4, { BackgroundTransparency = 0.45 })

    local root = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(400, 270),
        BackgroundTransparency = 1,
    }, dim)
    local openScale = create("UIScale", { Scale = 0.85 }, root)
    tween(openScale, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)

    create("ImageLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 50, 1, 50),
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.45,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
    }, root)

    local card = create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, root)
    corner(card, 18)
    local cardStroke = stroke(card, Color3.new(1, 1, 1), 0.2, 2)
    local sg = gradient(cardStroke, ACCENT_SEQ, 45)
    task.spawn(function()
        while gui.Parent do
            sg.Rotation = (sg.Rotation + 1) % 360
            task.wait(0.03)
        end
    end)

    -- หัว
    local logo = create("Frame", {
        Position = UDim2.fromOffset(20, 18),
        Size = UDim2.fromOffset(40, 40),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
    }, card)
    corner(logo, 12)
    gradient(logo, ACCENT_SEQ, 45)
    local lt = label(logo, "⚡", 20, Theme.Text, Enum.Font.GothamBlack)
    lt.Size = UDim2.fromScale(1, 1)
    lt.TextXAlignment = Enum.TextXAlignment.Center

    local t1 = label(card, title, 16, Theme.Text, Enum.Font.GothamBold)
    t1.Position = UDim2.fromOffset(72, 18)
    local t2 = label(card, subtitle, 10, Theme.AccentGlow, Enum.Font.GothamBold)
    t2.Position = UDim2.fromOffset(73, 40)

    local close = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 0, 20),
        Size = UDim2.fromOffset(32, 32),
        BackgroundColor3 = Theme.Card,
        Text = "×",
        TextSize = 22,
        TextColor3 = Theme.Text,
        Font = Enum.Font.Gotham,
        AutoButtonColor = false,
        ClipsDescendants = true,
    }, card)
    corner(close, 16)
    stroke(close, Theme.Border, 0.4)
    close.MouseEnter:Connect(function() tween(close, 0.15, { BackgroundColor3 = Theme.Red }) end)
    close.MouseLeave:Connect(function() tween(close, 0.2, { BackgroundColor3 = Theme.Card }) end)
    close.Activated:Connect(function() gui:Destroy() end)

    local hint = label(card, "Enter your key to continue", 12, Theme.Muted, Enum.Font.Gotham)
    hint.Position = UDim2.fromOffset(20, 76)
    hint.Size = UDim2.new(1, -40, 0, 20)

    -- ช่องกรอกคีย์
    local boxBg = create("Frame", {
        Position = UDim2.fromOffset(20, 102),
        Size = UDim2.new(1, -40, 0, 42),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
    }, card)
    corner(boxBg, 10)
    local boxStroke = stroke(boxBg, Theme.Border, 0.2, 1.4)

    local textBox = create("TextBox", {
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -28, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "XXXX-XXXX",
        PlaceholderColor3 = Theme.Muted,
        TextColor3 = Theme.Text,
        TextSize = 14,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
    }, boxBg)
    textBox.Focused:Connect(function()
        tween(boxStroke, 0.2, { Color = Theme.AccentGlow, Transparency = 0 })
    end)
    textBox.FocusLost:Connect(function()
        tween(boxStroke, 0.2, { Color = Theme.Border, Transparency = 0.2 })
    end)

    local status = label(card, "", 11, Theme.Muted, Enum.Font.GothamMedium)
    status.Position = UDim2.fromOffset(22, 150)
    status.Size = UDim2.new(1, -44, 0, 20)

    -- ปุ่ม
    local hasLink = options.KeyLink ~= nil and options.KeyLink ~= ""
    local submit = create("TextButton", {
        Position = UDim2.fromOffset(20, 182),
        Size = hasLink and UDim2.new(0.5, -26, 0, 44) or UDim2.new(1, -40, 0, 44),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Text = "VERIFY",
        TextSize = 13,
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        ClipsDescendants = true,
    }, card)
    corner(submit, 12)
    gradient(submit, ACCENT_SEQ, 0)

    if hasLink then
        local getKey = create("TextButton", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -20, 0, 182),
            Size = UDim2.new(0.5, -26, 0, 44),
            BackgroundColor3 = Theme.Card,
            Text = "GET KEY",
            TextSize = 13,
            TextColor3 = Theme.Text,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = false,
            ClipsDescendants = true,
        }, card)
        corner(getKey, 12)
        stroke(getKey, Theme.AccentGlow, 0.5, 1.2)
        getKey.MouseEnter:Connect(function() tween(getKey, 0.15, { BackgroundColor3 = Theme.Hover }) end)
        getKey.MouseLeave:Connect(function() tween(getKey, 0.2, { BackgroundColor3 = Theme.Card }) end)
        getKey.Activated:Connect(function()
            createRipple(getKey)
            local copied = false
            if setclipboard then
                copied = pcall(setclipboard, options.KeyLink)
            end
            status.TextColor3 = Theme.AccentGlow
            status.Text = copied and "Link copied to clipboard" or ("Link: " .. options.KeyLink)
        end)
    end

    local footer = label(card, "VOID UI  •  Key System", 10, Theme.Muted, Enum.Font.GothamMedium)
    footer.Position = UDim2.fromOffset(20, 238)
    footer.Size = UDim2.new(1, -40, 0, 20)

    -- ตรวจคีย์
    local attempts, locked, done = 0, false, false
    local basePos = root.Position

    local function shake()
        for _, dx in ipairs({ -10, 10, -7, 7, -3, 3, 0 }) do
            tween(root, 0.05, { Position = basePos + UDim2.fromOffset(dx, 0) }, Enum.EasingStyle.Linear)
            task.wait(0.05)
        end
    end

    local function verify()
        if locked or done then return end
        local text = (textBox.Text:gsub("^%s+", ""):gsub("%s+$", ""))
        if text == "" then
            status.TextColor3 = Theme.Red
            status.Text = "Please enter a key"
            return
        end

        if valid[text] then
            done = true
            status.TextColor3 = Theme.Green
            status.Text = "Key accepted!"
            tween(boxStroke, 0.2, { Color = Theme.Green, Transparency = 0 })
            task.wait(0.6)
            tween(openScale, 0.25, { Scale = 0.9 }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            tween(dim, 0.25, { BackgroundTransparency = 1 })
            task.wait(0.28)
            gui:Destroy()
            if options.Callback then task.spawn(options.Callback) end
        else
            attempts += 1
            status.TextColor3 = Theme.Red
            tween(boxStroke, 0.15, { Color = Theme.Red, Transparency = 0 })
            if options.MaxAttempts and attempts >= options.MaxAttempts then
                locked = true
                textBox.TextEditable = false
                status.Text = "Too many attempts. Input locked."
            else
                status.Text = "Invalid key"
                    .. (options.MaxAttempts and (" (" .. attempts .. "/" .. options.MaxAttempts .. ")") or "")
            end
            shake()
            task.delay(0.6, function()
                if not done then tween(boxStroke, 0.3, { Color = Theme.Border, Transparency = 0.2 }) end
            end)
        end
    end

    submit.MouseEnter:Connect(function() tween(submit, 0.15, { BackgroundTransparency = 0.15 }) end)
    submit.MouseLeave:Connect(function() tween(submit, 0.2, { BackgroundTransparency = 0 }) end)
    submit.Activated:Connect(function()
        createRipple(submit)
        verify()
    end)
    textBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then verify() end
    end)

    return { Destroy = function() gui:Destroy() end }
end

return VoidUI
