-- VOID UI | PRETTY EDITION
-- ฟีเจอร์ใหม่: เงา, ไล่สี, hover, แถบ active ของแท็บ, หัวข้อ section, แจ้งเตือน (Notify), เปิดหน้าต่างแบบ animation, ปรับขนาดอัตโนมัติบนมือถือ
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

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
    local root, mainFrame, sidebar, content, floatingLogo, mobileToggleBtn, openScale
    local tabs = {}
    local isVisible = true

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
                grad.Enabled = value
                tween(trackF, 0.25, { BackgroundColor3 = value and Color3.new(1, 1, 1) or Theme.Border })
                tween(knob, 0.25, { Position = value and UDim2.new(1, -22, 0, 3) or UDim2.fromOffset(3, 3) }, Enum.EasingStyle.Back)
                if not silent and opts.Callback then task.spawn(pcall, opts.Callback, value) end
            end

            methods.Set = function(_, v) setValue(v) end
            methods.Get = function() return value end
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

            methods.Set = function(_, name) choose(name) end
            methods.Get = function() return selected end
            return methods
        end

        -- Input
        function tabObj:CreateInput(opts)
            opts = opts or {}
            local methods = {}

            local card = makeCard(page, 66, false)
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
                if opts.Callback then task.spawn(pcall, opts.Callback, textBox.Text) end
            end)

            methods.Set = function(_, text) textBox.Text = tostring(text) end
            methods.Get = function() return textBox.Text end
            return methods
        end

        -- Text
        function tabObj:CreateText(textString)
            local lbl = label(page, textString or "Text Info", 12, Theme.Muted, Enum.Font.Gotham)
            lbl.AutomaticSize = Enum.AutomaticSize.Y
            lbl.Size = UDim2.new(1, 0, 0, 24)
            return { Set = function(_, t) lbl.Text = tostring(t) end }
        end

        return tabObj
    end

    buildMainUI()
    return window
end

return VoidUI
