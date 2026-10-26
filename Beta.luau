-- VOID UI | NEBULA EDITION (REDESIGNED & BEAUTIFIED)
-- Original Roblox UI Library

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local VoidUI = {}

local Theme = {
    Background = Color3.fromRGB(15, 13, 26),      -- ม่วงเข้มลึกขึ้น
    Sidebar = Color3.fromRGB(20, 17, 34),       -- สีแถบเมนูด้านข้าง
    Card = Color3.fromRGB(30, 26, 48),          -- สีพื้นหลังของการ์ด/ปุ่ม
    Hover = Color3.fromRGB(45, 38, 71),          -- สีเวลาเอาเมาส์ชี้
    Accent = Color3.fromRGB(175, 110, 255),     -- สีม่วงนีออนหลัก (สว่างขึ้น)
    AccentGlow = Color3.fromRGB(130, 70, 220),  -- สีเงา
    Text = Color3.fromRGB(250, 248, 255),       -- สีข้อความหลัก
    Muted = Color3.fromRGB(145, 138, 175),      -- สีข้อความรอง
    Border = Color3.fromRGB(65, 52, 95),        -- สีขอบ
    Red = Color3.fromRGB(240, 100, 100),
}

local function create(class, props, parent)
    local obj = Instance.new(class)
    for key, value in pairs(props or {}) do
        obj[key] = value
    end
    if parent then
        obj.Parent = parent
    end
    return obj
end

local function corner(parent, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 14)
    }, parent)
end

local function stroke(parent, color, transparency, thickness)
    return create("UIStroke", {
        Color = color or Theme.Border,
        Transparency = transparency or 0,
        Thickness = thickness or 1.2
    }, parent)
end

local function tween(obj, duration, props)
    local success, result = pcall(function()
        return TweenService:Create(
            obj,
            TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            props
        )
    end)
    if success and result then
        result:Play()
        return result
    end
    return nil
end

local function label(parent, text, size, color, font)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Text = text,
        TextSize = size or 14,
        TextColor3 = color or Theme.Text,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 24),
    }, parent)
end

local function safeReadfile(fileName)
    if typeof(readfile) == "function" then
        local success, result = pcall(readfile, fileName)
        if success then return result end
    end
    return nil
end

local function safeWritefile(fileName, content)
    if typeof(writefile) == "function" then
        pcall(writefile, fileName, content)
    end
end

local function safeSetClipboard(text)
    if typeof(setclipboard) == "function" then
        pcall(setclipboard, text)
        return true
    elseif typeof(tostring) == "function" then
        print("[VoidUI] Clipboard Link: " .. tostring(text))
        return false
    end
    return false
end

function VoidUI:CreateWindow(options)
    options = options or {}

    local title = options.Title or "VOID UI"
    local subtitle = options.Subtitle or "NEBULA EDITION"
    local keySystem = options.KeySystem or false
    local keySettings = options.KeySettings or {}

    local localPlayer = Players.LocalPlayer
    local targetContainer = localPlayer and localPlayer:FindFirstChild("PlayerGui")
    if not targetContainer then
        targetContainer = CoreGui
    end

    local gui = create("ScreenGui", {
        Name = "VoidUINebula",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 100,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, targetContainer)

    create("UIScale", { Scale = 1 }, gui)

    local function notify(titleText, message, duration)
        if not gui or not gui.Parent then return end

        local toast = create("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 280, 0, 16),
            Size = UDim2.fromOffset(270, 78),
            BackgroundColor3 = Theme.Card,
            BorderSizePixel = 0,
            ZIndex = 20,
        }, gui)

        corner(toast, 14)
        stroke(toast, Theme.Accent, 0.3, 1.5)

        -- เงาเรืองแสงเบาๆ
        create("UIStroke", {
            Color = Theme.AccentGlow,
            Transparency = 0.7,
            Thickness = 4,
        }, toast)

        local t = label(toast, titleText or "Notification", 14, Theme.Accent, Enum.Font.GothamBold)
        t.Position = UDim2.fromOffset(14, 10)
        t.Size = UDim2.new(1, -28, 0, 22)
        t.ZIndex = 21

        local m = label(toast, message or "", 12, Theme.Text, Enum.Font.Gotham)
        m.Position = UDim2.fromOffset(14, 34)
        m.Size = UDim2.new(1, -28, 0, 35)
        m.ZIndex = 21

        tween(toast, 0.4, { Position = UDim2.new(1, -16, 0, 16) })

        task.delay(duration or 3, function()
            if toast and toast.Parent then
                tween(toast, 0.3, { Position = UDim2.new(1, 280, 0, 16) })
                task.wait(0.35)
                if toast and toast.Parent then
                    toast:Destroy()
                end
            end
        end)
    end

    local window = {}
    local mainUIBuilt = false
    local mainFrame = nil
    local sidebar = nil
    local content = nil
    local tabs = {}
    local activeTab = nil
    local viewportConn = nil
    local pendingTabs = {}

    local function buildMainUI()
        if mainUIBuilt then return end
        mainUIBuilt = true

        mainFrame = create("Frame", {
            Name = "Main",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(680, 440),
            BackgroundColor3 = Theme.Background,
            BorderSizePixel = 0,
            ClipsDescendants = false,
        }, gui)

        corner(mainFrame, 18)
        stroke(mainFrame, Theme.Border, 0.2, 1.2)

        -- เพิ่ม Glow Effect รอบกรอบหน้าต่างหลัก
        create("UIStroke", {
            Color = Theme.Accent,
            Transparency = 0.6,
            Thickness = 3,
        }, mainFrame)

        create("UISizeConstraint", {
            MinSize = Vector2.new(300, 320),
            MaxSize = Vector2.new(880, 680),
        }, mainFrame)

        local camera = workspace.CurrentCamera
        local function resize()
            if not camera or not mainFrame then return end
            local viewport = camera.ViewportSize
            mainFrame.Size = UDim2.fromOffset(
                math.max(300, math.min(680, viewport.X - 24)),
                math.max(320, math.min(440, viewport.Y - 50))
            )
        end

        resize()
        if camera then
            viewportConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
        end

        -- Top Bar (ส่วนหัว)
        local top = create("Frame", {
            Size = UDim2.new(1, 0, 0, 68),
            BackgroundColor3 = Theme.Sidebar,
            BorderSizePixel = 0,
        }, mainFrame)
        corner(top, 18)

        -- ตัดมุมล่างของ Top bar ให้ตรง
        local fixTop = create("Frame", {
            Position = UDim2.new(0, 0, 1, -10),
            Size = UDim2.new(1, 0, 0, 10),
            BackgroundColor3 = Theme.Sidebar,
            BorderSizePixel = 0,
        }, top)

        local logo = create("Frame", {
            Position = UDim2.fromOffset(16, 15),
            Size = UDim2.fromOffset(38, 38),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
        }, top)
        corner(logo, 12)

        create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "V",
            TextColor3 = Theme.Text,
            Font = Enum.Font.GothamBlack,
            TextSize = 22,
            TextXAlignment = Enum.TextXAlignment.Center,
        }, logo)

        local titleLabel = label(top, title, 16, Theme.Text, Enum.Font.GothamBold)
        titleLabel.Position = UDim2.fromOffset(66, 14)
        titleLabel.Size = UDim2.new(1, -130, 0, 22)

        local subLabel = label(top, subtitle, 10, Theme.Accent, Enum.Font.GothamBold)
        subLabel.Position = UDim2.fromOffset(67, 38)
        subLabel.Size = UDim2.new(1, -130, 0, 15)

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
        }, top)
        corner(close, 10)
        stroke(close, Theme.Border, 0.4)

        close.MouseEnter:Connect(function()
            tween(close, 0.2, { BackgroundColor3 = Theme.Red })
        end)
        close.MouseLeave:Connect(function()
            tween(close, 0.2, { BackgroundColor3 = Theme.Card })
        end)

        close.Activated:Connect(function()
            if viewportConn then viewportConn:Disconnect() end
            gui:Destroy()
        end)

        -- ระบบลากหน้าต่าง
        local dragging = false
        local dragStart = Vector2.zero
        local startPosition = UDim2.new()

        top.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPosition = mainFrame.Position
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement 
            or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                mainFrame.Position = UDim2.new(
                    startPosition.X.Scale,
                    startPosition.X.Offset + delta.X,
                    startPosition.Y.Scale,
                    startPosition.Y.Offset + delta.Y
                )
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        -- Sidebar (เมนูด้านข้าง)
        sidebar = create("Frame", {
            Position = UDim2.fromOffset(0, 68),
            Size = UDim2.new(0, 155, 1, -68),
            BackgroundColor3 = Theme.Sidebar,
            BorderSizePixel = 0,
        }, mainFrame)

        create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, sidebar)

        create("UIPadding", {
            PaddingTop = UDim.new(0, 16),
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
        }, sidebar)

        -- Content Area (พื้นที่แสดงเนื้อหา)
        content = create("Frame", {
            Position = UDim2.new(0, 155, 0, 68),
            Size = UDim2.new(1, -155, 1, -68),
            BackgroundTransparency = 1,
        }, mainFrame)

        for _, pTab in ipairs(pendingTabs) do
            window:_RealCreateTab(pTab.TabName, pTab.IconText, pTab.TabObj)
        end
        pendingTabs = {}
    end

    function window:Notify(titleText, message, duration)
        notify(titleText, message, duration)
    end

    function window:_RealCreateTab(tabName, iconText, tabObj)
        local nav = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = Theme.Sidebar,
            Text = "",
            AutoButtonColor = false,
        }, sidebar)
        corner(nav, 10)

        local navText = label(nav, (iconText or "◆") .. "   " .. tabName, 12, Theme.Muted, Enum.Font.GothamMedium)
        navText.Position = UDim2.fromOffset(12, 0)
        navText.Size = UDim2.new(1, -15, 1, 0)
        navText.TextYAlignment = Enum.TextYAlignment.Center

        -- แถบสว่างเล็กๆ ด้านข้างเวลาเลือก Tab
        local indicator = create("Frame", {
            Position = UDim2.new(0, 0, 0.2, 0),
            Size = UDim2.new(0, 3, 0.6, 0),
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, nav)
        corner(indicator, 2)

        local page = create("ScrollingFrame", {
            Name = tabName .. "Page",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Accent,
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

        create("UIListLayout", {
            Padding = UDim.new(0, 12),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, page)

        local function activate()
            for _, item in ipairs(tabs) do
                item.page.Visible = false
                tween(item.nav, 0.25, { BackgroundColor3 = Theme.Sidebar })
                tween(item.indicator, 0.25, { BackgroundTransparency = 1 })
                item.text.TextColor3 = Theme.Muted
            end

            page.Visible = true
            tween(nav, 0.25, { BackgroundColor3 = Theme.Card })
            tween(indicator, 0.25, { BackgroundTransparency = 0 })
            navText.TextColor3 = Theme.Text
            activeTab = tabObj
        end

        nav.MouseEnter:Connect(function()
            if activeTab ~= tabObj then
                tween(nav, 0.2, { BackgroundColor3 = Theme.Hover })
            end
        end)
        nav.MouseLeave:Connect(function()
            if activeTab ~= tabObj then
                tween(nav, 0.2, { BackgroundColor3 = Theme.Sidebar })
            end
        end)

        nav.Activated:Connect(activate)

        table.insert(tabs, {
            page = page,
            nav = nav,
            text = navText,
            indicator = indicator,
        })

        if #tabs == 1 then
            activate()
        end

        tabObj._Page = page
    end

    function window:CreateTab(tabName, iconText)
        local tabObj = {}

        function tabObj:CreateSection(sectionName)
            task.spawn(function()
                while not tabObj._Page do task.wait() end
                local section = label(tabObj._Page, sectionName, 11, Theme.Accent, Enum.Font.GothamBold)
                section.Size = UDim2.new(1, 0, 0, 24)
                section.TextYAlignment = Enum.TextYAlignment.Center
            end)
        end

        function tabObj:CreateButton(options)
            options = options or {}
            task.spawn(function()
                while not tabObj._Page do task.wait() end
                local button = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 48),
                    BackgroundColor3 = Theme.Card,
                    Text = "",
                    AutoButtonColor = false,
                }, tabObj._Page)

                corner(button, 12)
                stroke(button, Theme.Border, 0.4)

                local txt = label(button, options.Name or "Button", 13, Theme.Text, Enum.Font.GothamMedium)
                txt.Position = UDim2.fromOffset(14, 0)
                txt.Size = UDim2.new(1, -28, 1, 0)
                txt.TextYAlignment = Enum.TextYAlignment.Center

                button.MouseEnter:Connect(function()
                    tween(button, 0.2, { BackgroundColor3 = Theme.Hover })
                end)
                button.MouseLeave:Connect(function()
                    tween(button, 0.2, { BackgroundColor3 = Theme.Card })
                end)

                button.Activated:Connect(function()
                    tween(button, 0.1, { BackgroundColor3 = Theme.Accent })
                    task.delay(0.15, function()
                        if button and button.Parent then
                            tween(button, 0.2, { BackgroundColor3 = Theme.Card })
                        end
                    end)

                    if options.Callback then
                        local ok, err = pcall(options.Callback)
                        if not ok then warn("[VoidUI] Button error:", err) end
                    end
                end)
            end)
        end

        function tabObj:CreateToggle(options)
            options = options or {}
            local value = options.Default == true
            local toggleMethods = {}

            task.spawn(function()
                while not tabObj._Page do task.wait() end
                local row = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 52),
                    BackgroundColor3 = Theme.Card,
                    Text = "",
                    AutoButtonColor = false,
                }, tabObj._Page)
                corner(row, 12)
                stroke(row, Theme.Border, 0.4)

                local txt = label(row, options.Name or "Toggle", 13, Theme.Text, Enum.Font.GothamMedium)
                txt.Position = UDim2.fromOffset(14, 0)
                txt.Size = UDim2.new(1, -80, 1, 0)
                txt.TextYAlignment = Enum.TextYAlignment.Center

                local track = create("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -14, 0.5, 0),
                    Size = UDim2.fromOffset(42, 24),
                    BackgroundColor3 = value and Theme.Accent or Theme.Border,
                    BorderSizePixel = 0,
                }, row)
                corner(track, 12)

                local knob = create("Frame", {
                    Position = value and UDim2.new(1, -21, 0, 3) or UDim2.fromOffset(3, 3),
                    Size = UDim2.fromOffset(18, 18),
                    BackgroundColor3 = Theme.Text,
                    BorderSizePixel = 0,
                }, track)
                corner(knob, 10)

                local function setValue(newValue)
                    value = newValue == true
                    tween(track, 0.2, { BackgroundColor3 = value and Theme.Accent or Theme.Border })
                    tween(knob, 0.2, { Position = value and UDim2.new(1, -21, 0, 3) or UDim2.fromOffset(3, 3) })

                    if options.Callback then
                        local ok, err = pcall(options.Callback, value)
                        if not ok then warn("[VoidUI] Toggle error:", err) end
                    end
                end

                toggleMethods.Set = setValue
                toggleMethods.Get = function() return value end

                row.MouseEnter:Connect(function()
                    tween(row, 0.2, { BackgroundColor3 = Theme.Hover })
                end)
                row.MouseLeave:Connect(function()
                    tween(row, 0.2, { BackgroundColor3 = Theme.Card })
                end)

                row.Activated:Connect(function()
                    setValue(not value)
                end)
            end)

            return toggleMethods
        end

        function tabObj:CreateSlider(options)
            options = options or {}
            local min = options.Min or 0
            local max = options.Max or 100
            local value = math.clamp(options.Default or min, min, max)
            local sliderMethods = {}

            task.spawn(function()
                while not tabObj._Page do task.wait() end
                local card = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 72),
                    BackgroundColor3 = Theme.Card,
                    BorderSizePixel = 0,
                }, tabObj._Page)
                corner(card, 12)
                stroke(card, Theme.Border, 0.4)

                local name = label(card, options.Name or "Slider", 12, Theme.Text, Enum.Font.GothamMedium)
                name.Position = UDim2.fromOffset(14, 10)
                name.Size = UDim2.new(1, -70, 0, 22)

                local number = label(card, tostring(value), 12, Theme.Accent, Enum.Font.GothamBold)
                number.Position = UDim2.new(1, -60, 0, 10)
                number.Size = UDim2.fromOffset(46, 22)
                number.TextXAlignment = Enum.TextXAlignment.Right

                local bar = create("Frame", {
                    Position = UDim2.new(0, 14, 0, 46),
                    Size = UDim2.new(1, -28, 0, 8),
                    BackgroundColor3 = Theme.Border,
                    BorderSizePixel = 0,
                }, card)
                corner(bar, 4)

                local ratio = (value - min) / math.max(1, max - min)
                local fill = create("Frame", {
                    Size = UDim2.new(ratio, 0, 1, 0),
                    BackgroundColor3 = Theme.Accent,
                    BorderSizePixel = 0,
                }, bar)
                corner(fill, 4)

                local knob = create("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(ratio, 0, 0.5, 0),
                    Size = UDim2.fromOffset(16, 16),
                    BackgroundColor3 = Theme.Text,
                    BorderSizePixel = 0,
                }, bar)
                corner(knob, 8)

                local draggingSlider = false

                local function setValue(newValue)
                    value = math.clamp(newValue, min, max)
                    local r = (value - min) / math.max(1, max - min)
                    number.Text = tostring(math.floor(value + 0.5))

                    tween(fill, 0.08, { Size = UDim2.new(r, 0, 1, 0) })
                    tween(knob, 0.08, { Position = UDim2.new(r, 0, 0.5, 0) })

                    if options.Callback then
                        local ok, err = pcall(options.Callback, value)
                        if not ok then warn("[VoidUI] Slider error:", err) end
                    end
                end

                sliderMethods.Set = setValue
                sliderMethods.Get = function() return value end

                local function updateFromInput(input)
                    if not bar or not bar.Parent then return end
                    local absPos = bar.AbsolutePosition
                    local absSize = bar.AbsoluteSize
                    local ratioNow = math.clamp((input.Position.X - absPos.X) / math.max(1, absSize.X), 0, 1)
                    setValue(min + (max - min) * ratioNow)
                end

                bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch
                    or input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingSlider = true
                        updateFromInput(input)
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if draggingSlider and (
                        input.UserInputType == Enum.UserInputType.Touch
                        or input.UserInputType == Enum.UserInputType.MouseMovement
                    ) then
                        updateFromInput(input)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch
                    or input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingSlider = false
                    end
                end)
            end)

            return sliderMethods
        end

        if mainUIBuilt then
            window:_RealCreateTab(tabName, iconText, tabObj)
        else
            table.insert(pendingTabs, { TabName = tabName, IconText = iconText, TabObj = tabObj })
        end

        return tabObj
    end

    function window:Destroy()
        if viewportConn then viewportConn:Disconnect() end
        if gui and gui.Parent then
            gui:Destroy()
        end
    end

    -- Key System
    if keySystem then
        local kTitle = keySettings.Title or "Authentication Required"
        local kSubtitle = keySettings.Subtitle or "Please enter your key to continue"
        local kNote = keySettings.Note or ""
        local validKeys = keySettings.Key or {}
        if type(validKeys) == "string" then
            validKeys = {validKeys}
        end
        local saveKey = keySettings.SaveKey or false
        local getLink = keySettings.GetLink or ""
        local webKeyUrl = keySettings.WebKeyUrl or ""

        local fileName = "VoidUI_Key.txt"
        local savedKeyValid = false

        if saveKey then
            local content = safeReadfile(fileName)
            if content then
                for _, k in ipairs(validKeys) do
                    if content == k then
                        savedKeyValid = true
                        break
                    end
                end
            end
        end

        if savedKeyValid then
            buildMainUI()
            return window
        end

        local keyMain = create("Frame", {
            Name = "KeySystem",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(440, 270),
            BackgroundColor3 = Theme.Background,
            BorderSizePixel = 0,
            ClipsDescendants = false,
        }, gui)

        corner(keyMain, 18)
        stroke(keyMain, Theme.Border, 0.3, 1.2)

        create("UIStroke", {
            Color = Theme.Accent,
            Transparency = 0.5,
            Thickness = 3,
        }, keyMain)

        local top = create("Frame", {
            Size = UDim2.new(1, 0, 0, 55),
            BackgroundColor3 = Theme.Sidebar,
            BorderSizePixel = 0,
        }, keyMain)
        corner(top, 18)

        local fixTop = create("Frame", {
            Position = UDim2.new(0, 0, 1, -10),
            Size = UDim2.new(1, 0, 0, 10),
            BackgroundColor3 = Theme.Sidebar,
            BorderSizePixel = 0,
        }, top)

        local titleLabel = label(top, kTitle, 14, Theme.Text, Enum.Font.GothamBold)
        titleLabel.Position = UDim2.fromOffset(18, 0)
        titleLabel.Size = UDim2.new(1, -60, 1, 0)
        titleLabel.TextYAlignment = Enum.TextYAlignment.Center

        local close = create("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -16, 0.5, 0),
            Size = UDim2.fromOffset(30, 30),
            BackgroundColor3 = Theme.Card,
            Text = "×",
            TextSize = 20,
            TextColor3 = Theme.Text,
            Font = Enum.Font.Gotham,
            AutoButtonColor = false,
        }, top)
        corner(close, 8)
        stroke(close, Theme.Border, 0.4)

        close.MouseEnter:Connect(function()
            tween(close, 0.2, { BackgroundColor3 = Theme.Red })
        end)
        close.MouseLeave:Connect(function()
            tween(close, 0.2, { BackgroundColor3 = Theme.Card })
        end)

        close.Activated:Connect(function()
            if gui and gui.Parent then
                gui:Destroy()
            end
        end)

        label(keyMain, kSubtitle, 12, Theme.Muted, Enum.Font.Gotham).Position = UDim2.fromOffset(24, 70)

        local textBoxBg = create("Frame", {
            Position = UDim2.fromOffset(24, 102),
            Size = UDim2.new(1, -48, 0, 46),
            BackgroundColor3 = Theme.Card,
            BorderSizePixel = 0,
        }, keyMain)
        corner(textBoxBg, 12)
        stroke(textBoxBg, Theme.Border, 0.4)

        local textBox = create("TextBox", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(14, 0),
            Size = UDim2.new(1, -28, 1, 0),
            PlaceholderText = "Enter your key here...",
            Text = "",
            TextColor3 = Theme.Text,
            PlaceholderColor3 = Theme.Muted,
            TextSize = 13,
            Font = Enum.Font.GothamMedium,
            ClearTextOnFocus = false,
        }, textBoxBg)

        local submitBtn = create("TextButton", {
            Position = UDim2.fromOffset(24, 160),
            Size = UDim2.new(1, -48, 0, 44),
            BackgroundColor3 = Theme.Accent,
            Text = "Confirm Key",
            TextSize = 13,
            TextColor3 = Theme.Text,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = false,
        }, keyMain)
        corner(submitBtn, 12)

        submitBtn.MouseEnter:Connect(function()
            tween(submitBtn, 0.2, { BackgroundColor3 = Theme.Hover })
        end)
        submitBtn.MouseLeave:Connect(function()
            tween(submitBtn, 0.2, { BackgroundColor3 = Theme.Accent })
        end)

        if getLink ~= "" then
            submitBtn.Size = UDim2.new(0.5, -28, 0, 44)
            submitBtn.Position = UDim2.new(0.5, 4, 0, 160)

            local getKeyBtn = create("TextButton", {
                Position = UDim2.fromOffset(24, 160),
                Size = UDim2.new(0.5, -28, 0, 44),
                BackgroundColor3 = Theme.Card,
                Text = "Get Key",
                TextSize = 13,
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamBold,
                AutoButtonColor = false,
            }, keyMain)
            corner(getKeyBtn, 12)
            stroke(getKeyBtn, Theme.Border, 0.4)

            getKeyBtn.MouseEnter:Connect(function()
                tween(getKeyBtn, 0.2, { BackgroundColor3 = Theme.Hover })
            end)
            getKeyBtn.MouseLeave:Connect(function()
                tween(getKeyBtn, 0.2, { BackgroundColor3 = Theme.Card })
            end)

            getKeyBtn.Activated:Connect(function()
                local success = safeSetClipboard(getLink)
                if success then
                    notify("Clipboard", "Get Key link copied to clipboard!", 3)
                else
                    notify("Get Key", "Check output/console for link.", 4)
                end
            end)
        end

        local noteLab = label(keyMain, kNote, 11, Theme.Muted, Enum.Font.Gotham)
        noteLab.Position = UDim2.fromOffset(24, 220)
        noteLab.Size = UDim2.new(1, -48, 0, 20)
        noteLab.TextXAlignment = Enum.TextXAlignment.Center

        submitBtn.Activated:Connect(function()
            local enteredKey = textBox.Text
            if enteredKey == "" then
                notify("Error", "Please enter a key first.", 3)
                return
            end

            local isKeyValid = false
            for _, k in ipairs(validKeys) do
                if enteredKey == k then
                    isKeyValid = true
                    break
                end
            end

            if not isKeyValid and webKeyUrl ~= "" then
                local success, response = pcall(function()
                    return game:HttpGet(webKeyUrl)
                end)
                if success and response then
                    if string.find(response, enteredKey) then
                        isKeyValid = true
                    end
                end
            end

            if isKeyValid then
                if saveKey then
                    safeWritefile(fileName, enteredKey)
                end
                notify("Success", "Key accepted! Loading UI...", 2)
                tween(keyMain, 0.3, { Size = UDim2.fromOffset(440, 0) })
                task.wait(0.3)
                if keyMain and keyMain.Parent then
                    keyMain:Destroy()
                end
                buildMainUI()
            else
                notify("Error", "Invalid key, please try again.", 3)
                stroke(textBoxBg, Theme.Red, 0)
                task.delay(1, function()
                    if textBoxBg and textBoxBg.Parent then
                        stroke(textBoxBg, Theme.Border, 0.4)
                    end
                end)
            end
        end)

        return window
    else
        buildMainUI()
        return window
    end
end

return VoidUI
