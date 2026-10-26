-- VOID UI | EVADE & MOBILE EDITION (WITH LOCKED TOGGLE)
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local VoidUI = {}

local Theme = {
    Background = Color3.fromRGB(15, 13, 26),
    Sidebar = Color3.fromRGB(20, 17, 34),
    Card = Color3.fromRGB(30, 26, 48),
    Hover = Color3.fromRGB(45, 38, 71),
    Accent = Color3.fromRGB(235, 75, 75),       
    AccentGlow = Color3.fromRGB(255, 140, 0), 
    Text = Color3.fromRGB(250, 248, 255),
    Muted = Color3.fromRGB(145, 138, 175),
    Border = Color3.fromRGB(65, 52, 95),
    Red = Color3.fromRGB(240, 100, 100),
    Green = Color3.fromRGB(100, 235, 130),
}

local function create(class, props, parent)
    local obj = Instance.new(class)
    for key, value in pairs(props or {}) do
        obj[key] = value
    end
    if parent then obj.Parent = parent end
    return obj
end

local function corner(parent, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 14) }, parent)
end

local function stroke(parent, color, transparency, thickness)
    return create("UIStroke", { Color = color or Theme.Border, Transparency = transparency or 0, Thickness = thickness or 1.2 }, parent)
end

local function tween(obj, duration, props, style, direction)
    if not obj or not obj.Parent then return end
    pcall(function()
        local tw = TweenService:Create(obj, TweenInfo.new(duration or 0.25, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out), props)
        tw:Play()
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
        TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 24),
    }, parent)
end

-- เอฟเฟกต์วงกลมเวลาคลิกปุ่ม (Ripple Effect)
local function createRipple(parent)
    if not parent or not parent.AbsoluteSize then return end
    task.spawn(function()
        local ripple = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(0, 0),
            BackgroundColor3 = Theme.AccentGlow,
            BackgroundTransparency = 0.4,
            BorderSizePixel = 0,
            ZIndex = 50,
        }, parent)
        corner(ripple, 100)

        local maxSize = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 1.8
        local tw = TweenService:Create(ripple, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(maxSize, maxSize),
            BackgroundTransparency = 1
        })
        
        tw:Play()
        tw.Completed:Connect(function()
            if ripple and ripple.Parent then ripple:Destroy() end
        end)
    end)
end

function VoidUI:CreateWindow(options)
    options = options or {}
    local title = options.Title or "VOID UI"
    local subtitle = options.Subtitle or "EVADE SCRIPT 🏃"

    local localPlayer = Players.LocalPlayer
    local targetContainer = localPlayer and localPlayer:FindFirstChild("PlayerGui") or CoreGui

    local gui = create("ScreenGui", {
        Name = "VoidUIEvade",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 100,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, targetContainer)

    create("UIScale", { Scale = 1 }, gui)

    local window = {}
    local mainUIBuilt = false
    local mainFrame = nil
    local sidebar = nil
    local content = nil
    local floatingLogo = nil
    local mobileToggleBtn = nil
    local tabs = {}
    local activeTab = nil
    local pendingTabs = {}
    local isVisible = true

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
            ClipsDescendants = true,
        }, gui)

        corner(mainFrame, 18)
        stroke(mainFrame, Theme.AccentGlow, 0.4, 2)

        -- Floating Logo (ปุ่มวงกลมตอนปิด UI)
        floatingLogo = create("TextButton", {
            Name = "FloatingLogo",
            Position = UDim2.new(0, 20, 0, 20),
            Size = UDim2.fromOffset(50, 50),
            BackgroundColor3 = Theme.Card,
            Text = "",
            AutoButtonColor = false,
            Visible = false,
            ZIndex = 100,
            ClipsDescendants = true,
        }, gui)
        corner(floatingLogo, 25)
        stroke(floatingLogo, Theme.AccentGlow, 0.2, 2)

        create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "🏃",
            TextColor3 = Theme.Text,
            Font = Enum.Font.GothamBlack,
            TextSize = 22,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 101,
        }, floatingLogo)

        -- Mobile Toggle Button (ปุ่มเปิด-ปิด UI มุมซ้าย)
        mobileToggleBtn = create("TextButton", {
            Name = "MobileToggle",
            Position = UDim2.new(0, 20, 0, 100),
            Size = UDim2.fromOffset(52, 52),
            BackgroundColor3 = Theme.Card,
            Text = "เมนู",
            TextSize = 14,
            TextColor3 = Theme.Text,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = false,
            ZIndex = 100,
            ClipsDescendants = true,
        }, gui)
        corner(mobileToggleBtn, 26)
        stroke(mobileToggleBtn, Theme.AccentGlow, 0.3, 2)

        local function toggleUI()
            isVisible = not isVisible
            if mainFrame then mainFrame.Visible = isVisible end
            if floatingLogo then floatingLogo.Visible = not isVisible end
        end

        floatingLogo.Activated:Connect(function() createRipple(floatingLogo) toggleUI() end)
        mobileToggleBtn.Activated:Connect(function() createRipple(mobileToggleBtn) toggleUI() end)

        -- Top Bar
        local top = create("Frame", {
            Size = UDim2.new(1, 0, 0, 68),
            BackgroundColor3 = Theme.Sidebar,
            BorderSizePixel = 0,
            ZIndex = 2,
        }, mainFrame)
        corner(top, 18)

        label(top, title, 16, Theme.Text, Enum.Font.GothamBold).Position = UDim2.fromOffset(20, 14)
        label(top, subtitle, 10, Theme.AccentGlow, Enum.Font.GothamBold).Position = UDim2.fromOffset(21, 38)

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
            ZIndex = 3,
            ClipsDescendants = true,
        }, top)
        corner(close, 16)
        stroke(close, Theme.Border, 0.4)

        close.Activated:Connect(function()
            createRipple(close)
            if floatingLogo then floatingLogo:Destroy() end
            if mobileToggleBtn then mobileToggleBtn:Destroy() end
            gui:Destroy()
        end)

        -- ลากหน้าต่าง UI
        local dragging, dragStart, startPosition = false, Vector2.zero, UDim2.new()
        top.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPosition = mainFrame.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                mainFrame.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)

        sidebar = create("Frame", {
            Position = UDim2.fromOffset(0, 68),
            Size = UDim2.new(0, 155, 1, -68),
            BackgroundColor3 = Theme.Sidebar,
            BorderSizePixel = 0,
            ZIndex = 2,
        }, mainFrame)

        create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, sidebar)
        create("UIPadding", { PaddingTop = UDim.new(0, 16), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, sidebar)

        content = create("Frame", {
            Position = UDim2.new(0, 155, 0, 68),
            Size = UDim2.new(1, -155, 1, -68),
            BackgroundTransparency = 1,
            ZIndex = 2,
        }, mainFrame)

        for _, pTab in ipairs(pendingTabs) do
            window:_RealCreateTab(pTab.TabName, pTab.IconText, pTab.TabObj)
        end
        pendingTabs = {}
    end

    function window:_RealCreateTab(tabName, iconText, tabObj)
        local nav = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = Theme.Sidebar,
            Text = "",
            AutoButtonColor = false,
            ClipsDescendants = true,
        }, sidebar)
        corner(nav, 10)

        local navText = label(nav, (iconText or "📌") .. "   " .. tabName, 12, Theme.Muted, Enum.Font.GothamMedium)
        navText.Position = UDim2.fromOffset(12, 0)
        navText.Size = UDim2.new(1, -15, 1, 0)
        navText.TextYAlignment = Enum.TextYAlignment.Center

        local page = create("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.AccentGlow,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
        }, content)

        create("UIPadding", { PaddingTop = UDim.new(0, 16), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }, page)
        create("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, page)

        local function activate()
            createRipple(nav)
            for _, item in ipairs(tabs) do
                item.page.Visible = false
                tween(item.nav, 0.2, { BackgroundColor3 = Theme.Sidebar })
                item.text.TextColor3 = Theme.Muted
            end
            page.Visible = true
            tween(nav, 0.2, { BackgroundColor3 = Theme.Card })
            navText.TextColor3 = Theme.Text
            activeTab = tabObj
        end

        nav.Activated:Connect(activate)
        table.insert(tabs, { page = page, nav = nav, text = navText })
        if #tabs == 1 then activate() end
        tabObj._Page = page
    end

    function window:CreateTab(tabName, iconText)
        local tabObj = {}

        -- ฟังก์ชันสร้างปุ่มกด (Button)
        function tabObj:CreateButton(options)
            options = options or {}
            task.spawn(function()
                while not tabObj._Page do task.wait() end
                local button = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 48),
                    BackgroundColor3 = Theme.Card,
                    Text = "",
                    AutoButtonColor = false,
                    ClipsDescendants = true,
                }, tabObj._Page)
                corner(button, 14)
                stroke(button, Theme.AccentGlow, 0.5, 1.2)

                label(button, options.Name or "Button", 13, Theme.Text, Enum.Font.GothamMedium).Position = UDim2.fromOffset(14, 0)

                button.Activated:Connect(function()
                    createRipple(button)
                    if options.Callback then pcall(options.Callback) end
                end)
            end)
        end

        -- ฟังก์ชันสร้างปุ่มเปิด-ปิด (Toggle) พร้อมรองรับการล็อกสถานะ (Locked)
        function tabObj:CreateToggle(options)
            options = options or {}
            local value = options.Default == true
            local isLocked = options.Locked == true
            local toggleMethods = {}

            task.spawn(function()
                while not tabObj._Page do task.wait() end
                local row = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 52),
                    BackgroundColor3 = Theme.Card,
                    Text = "",
                    AutoButtonColor = false,
                    ClipsDescendants = true,
                }, tabObj._Page)
                corner(row, 14)
                stroke(row, isLocked and Theme.Red or Theme.AccentGlow, 0.5, 1.2)

                local displayName = options.Name or "Toggle"
                if isLocked then
                    displayName = displayName .. " 🔒"
                end
                label(row, displayName, 13, isLocked and Theme.Muted or Theme.Text, Enum.Font.GothamMedium).Position = UDim2.fromOffset(14, 0)

                local track = create("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -14, 0.5, 0),
                    Size = UDim2.fromOffset(42, 24),
                    BackgroundColor3 = isLocked and Theme.Border or (value and Theme.Green or Theme.Border),
                    BorderSizePixel = 0,
                }, row)
                corner(track, 12)

                local knob = create("Frame", {
                    Position = value and UDim2.new(1, -21, 0, 3) or UDim2.fromOffset(3, 3),
                    Size = UDim2.fromOffset(18, 18),
                    BackgroundColor3 = isLocked and Theme.Muted or Theme.Text,
                    BorderSizePixel = 0,
                }, track)
                corner(knob, 10)

                local function setValue(newValue)
                    if isLocked then return end -- หากถูกล็อก จะไม่ยอมให้เปลี่ยนค่า
                    value = newValue == true
                    createRipple(row)
                    tween(track, 0.25, { BackgroundColor3 = value and Theme.Green or Theme.Border })
                    tween(knob, 0.25, { Position = value and UDim2.new(1, -21, 0, 3) or UDim2.fromOffset(3, 3) })
                    if options.Callback then pcall(options.Callback, value) end
                end

                toggleMethods.Set = setValue
                toggleMethods.Get = function() return value end
                
                row.Activated:Connect(function()
                    if not isLocked then
                        setValue(not value)
                    end
                end)
            end)

            return toggleMethods
        end

        if mainUIBuilt then window:_RealCreateTab(tabName, iconText, tabObj) else table.insert(pendingTabs, { TabName = tabName, IconText = iconText, TabObj = tabObj }) end
        return tabObj
    end

    buildMainUI()
    return window
end

return VoidUI
