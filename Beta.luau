-- VOID UI | NEBULA EDITION (COMPLETE REFACTORED VERSION)
-- Original Roblox UI Library
-- Use in your own Roblox experience
-- Place inside a ModuleScript named VoidUI

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local VoidUI = {}

local Theme = {
    Background = Color3.fromRGB(13, 12, 22),
    Sidebar = Color3.fromRGB(18, 16, 30),
    Card = Color3.fromRGB(26, 23, 42),
    Hover = Color3.fromRGB(39, 33, 59),
    Accent = Color3.fromRGB(165, 100, 255),
    Text = Color3.fromRGB(245, 242, 255),
    Muted = Color3.fromRGB(155, 148, 180),
    Border = Color3.fromRGB(54, 45, 75),
    Green = Color3.fromRGB(100, 235, 170),
    Red = Color3.fromRGB(235, 100, 100),
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
        CornerRadius = UDim.new(0, radius or 12)
    }, parent)
end

local function stroke(parent, color, transparency)
    return create("UIStroke", {
        Color = color or Theme.Border,
        Transparency = transparency or 0,
        Thickness = 1
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

-- ป้องกันการใช้ฟังก์ชัน Executor นอกรันไทม์โดยตรง (Safe Wrapper)
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
        -- กรณีรันใน Roblox Studio ธรรมดา แจ้งเตือนผู้ใช้ผ่าน Output หรือพิมพ์ลิงก์แทน
        print("[VoidUI] Clipboard API not available. Link: " .. tostring(text))
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
    
    -- เผื่อกรณีรันสคริปต์แบบ Client แต่ PlayerGui ยังไม่โหลด
    if not targetContainer then
        targetContainer = CoreGui
    end

    local gui = create("ScreenGui", {
        Name = "VoidUINebula",
        ResetOnSpawn = false,
        IgnoreGuiInset = false,
        DisplayOrder = 100,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, targetContainer)

    create("UIScale", { Scale = 1 }, gui)

    -- ระบบแจ้งเตือน (Notify) พร้อมเคลียร์ Event และ Connection ป้องกันค้าง
    local function notify(titleText, message, duration)
        if not gui or not gui.Parent then return end

        local toast = create("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 280, 0, 12),
            Size = UDim2.fromOffset(260, 78),
            BackgroundColor3 = Theme.Card,
            BorderSizePixel = 0,
            ZIndex = 20,
        }, gui)

        corner(toast, 12)
        stroke(toast, Theme.Accent, 0.25)

        local t = label(toast, titleText or "Notification", 14, Theme.Accent, Enum.Font.GothamBold)
        t.Position = UDim2.fromOffset(12, 9)
        t.Size = UDim2.new(1, -24, 0, 22)
        t.ZIndex = 21

        local m = label(toast, message or "", 12, Theme.Text, Enum.Font.Gotham)
        m.Position = UDim2.fromOffset(12, 34)
        m.Size = UDim2.new(1, -24, 0, 35)
        m.ZIndex = 21

        tween(toast, 0.35, { Position = UDim2.new(1, -12, 0, 12) })

        task.delay(duration or 3, function()
            if toast and toast.Parent then
                tween(toast, 0.25, { Position = UDim2.new(1, 280, 0, 12) })
                task.wait(0.3)
                if toast and toast.Parent then
                    toast:Destroy()
                end
            end
        end)
    end

    -- ฟังก์ชันสร้าง Main UI หลัก
    local function buildMainUI()
        local main = create("Frame", {
            Name = "Main",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(660, 430),
            BackgroundColor3 = Theme.Background,
            BorderSizePixel = 0,
            ClipsDescendants = true,
        }, gui)

        corner(main, 18)
        stroke(main, Theme.Accent, 0.45)

        create("UISizeConstraint", {
            MinSize = Vector2.new(290, 300),
            MaxSize = Vector2.new(850, 650),
        }, main)

        local camera = workspace.CurrentCamera
        local viewportConn = nil

        local function resize()
            if not camera or not main then return end
            local viewport = camera.ViewportSize
            main.Size = UDim2.fromOffset(
                math.max(290, math.min(660, viewport.X - 24)),
                math.max(300, math.min(430, viewport.Y - 50))
            )
        end

        resize()
        if camera then
            viewportConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
        end

        local top = create("Frame", {
            Size = UDim2.new(1, 0, 0, 65),
            BackgroundColor3 = Theme.Sidebar,
            BorderSizePixel = 0,
        }, main)

        local logo = create("Frame", {
            Position = UDim2.fromOffset(15, 13),
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
            TextSize = 23,
        }, logo)

        local titleLabel = label(top, title, 16, Theme.Text, Enum.Font.GothamBold)
        titleLabel.Position = UDim2.fromOffset(63, 13)
        titleLabel.Size = UDim2.new(1, -130, 0, 22)

        local subLabel = label(top, subtitle, 10, Theme.Accent, Enum.Font.GothamBold)
        subLabel.Position = UDim2.fromOffset(64, 36)
        subLabel.Size = UDim2.new(1, -130, 0, 15)

        local close = create("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -15, 0.5, 0),
            Size = UDim2.fromOffset(32, 32),
            BackgroundColor3 = Theme.Card,
            Text = "×",
            TextSize = 24,
            TextColor3 = Theme.Text,
            Font = Enum.Font.Gotham,
            AutoButtonColor = false,
        }, top)
        corner(close, 10)

        -- จัดการการลบ Connection เมื่อปิด UI
        close.Activated:Connect(function()
            if viewportConn then
                viewportConn:Disconnect()
            end
            gui:Destroy()
        end)

        -- ระบบลากหน้าต่างรองรับ Mouse และ Touch พร้อมป้องกัน Event รั่วไหล
        local dragging = false
        local dragStart = Vector2.zero
        local startPosition = UDim2.new()

        local inputBeganConn
        local inputChangedConn
        local inputEndedConn

        inputBeganConn = top.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPosition = main.Position
            end
        end)

        inputChangedConn = UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement 
            or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                main.Position = UDim2.new(
                    startPosition.X.Scale,
                    startPosition.X.Offset + delta.X,
                    startPosition.Y.Scale,
                    startPosition.Y.Offset + delta.Y
                )
            end
        end)

        inputEndedConn = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        gui.AncestryChanged:Connect(function(_, parent)
            if not parent then
                if inputBeganConn then inputBeganConn:Disconnect() end
                if inputChangedConn then inputChangedConn:Disconnect() end
                if inputEndedConn then inputEndedConn:Disconnect() end
                if viewportConn then viewportConn:Disconnect() end
            end
        end)

        local sidebar = create("Frame", {
            Position = UDim2.fromOffset(0, 65),
            Size = UDim2.new(0, 145, 1, -65),
            BackgroundColor3 = Theme.Sidebar,
            BorderSizePixel = 0,
        }, main)

        create("UIListLayout", {
            Padding = UDim.new(0, 7),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, sidebar)

        create("UIPadding", {
            PaddingTop = UDim.new(0, 15),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
        }, sidebar)

        local content = create("Frame", {
            Position = UDim2.new(0, 145, 0, 65),
            Size = UDim2.new(1, -145, 1, -65),
            BackgroundTransparency = 1,
        }, main)

        local tabs = {}
        local activeTab = nil
        local window = {}

        function window:Notify(titleText, message, duration)
            notify(titleText, message, duration)
        end

        function window:CreateTab(tabName, iconText)
            local nav = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = Theme.Sidebar,
                Text = "",
                AutoButtonColor = false,
            }, sidebar)
            corner(nav, 10)

            local navText = label(nav, (iconText or "◆") .. "   " .. tabName, 12, Theme.Muted, Enum.Font.GothamMedium)
            navText.Position = UDim2.fromOffset(10, 0)
            navText.Size = UDim2.new(1, -15, 1, 0)
            navText.TextYAlignment = Enum.TextYAlignment.Center

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
                PaddingTop = UDim.new(0, 15),
                PaddingLeft = UDim.new(0, 14),
                PaddingRight = UDim.new(0, 14),
                PaddingBottom = UDim.new(0, 15),
            }, page)

            create("UIListLayout", {
                Padding = UDim.new(0, 10),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, page)

            local tab = {}

            local function activate()
                for _, item in ipairs(tabs) do
                    item.page.Visible = false
                    tween(item.nav, 0.2, { BackgroundColor3 = Theme.Sidebar })
                    item.text.TextColor3 = Theme.Muted
                end

                page.Visible = true
                tween(nav, 0.2, { BackgroundColor3 = Theme.Card })
                navText.TextColor3 = Theme.Accent
                activeTab = tab
            end

            nav.Activated:Connect(activate)

            table.insert(tabs, {
                page = page,
                nav = nav,
                text = navText,
            })

            if #tabs == 1 then
                activate()
            end

            function tab:CreateSection(sectionName)
                local section = label(page, sectionName, 11, Theme.Accent, Enum.Font.GothamBold)
                section.Size = UDim2.new(1, 0, 0, 24)
                section.TextYAlignment = Enum.TextYAlignment.Center
                return section
            end

            function tab:CreateButton(options)
                options = options or {}

                local button = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 46),
                    BackgroundColor3 = Theme.Card,
                    Text = "",
                    AutoButtonColor = false,
                }, page)

                corner(button, 11)
                stroke(button, Theme.Border, 0.3)

                local txt = label(button, options.Name or "Button", 13, Theme.Text, Enum.Font.GothamMedium)
                txt.Position = UDim2.fromOffset(13, 0)
                txt.Size = UDim2.new(1, -26, 1, 0)
                txt.TextYAlignment = Enum.TextYAlignment.Center

                button.Activated:Connect(function()
                    tween(button, 0.12, { BackgroundColor3 = Theme.Hover })
                    task.delay(0.15, function()
                        if button and button.Parent then
                            tween(button, 0.15, { BackgroundColor3 = Theme.Card })
                        end
                    end)

                    if options.Callback then
                        local ok, err = pcall(options.Callback)
                        if not ok then
                            warn("[VoidUI] Button callback error:", err)
                        end
                    end
                end)

                return button
            end

            function tab:CreateToggle(options)
                options = options or {}
                local value = options.Default == true

                local row = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 50),
                    BackgroundColor3 = Theme.Card,
                    Text = "",
                    AutoButtonColor = false,
                }, page)
                corner(row, 11)
                stroke(row, Theme.Border, 0.3)

                local txt = label(row, options.Name or "Toggle", 13, Theme.Text, Enum.Font.GothamMedium)
                txt.Position = UDim2.fromOffset(13, 0)
                txt.Size = UDim2.new(1, -75, 1, 0)
                txt.TextYAlignment = Enum.TextYAlignment.Center

                local track = create("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -12, 0.5, 0),
                    Size = UDim2.fromOffset(39, 22),
                    BackgroundColor3 = value and Theme.Accent or Theme.Border,
                    BorderSizePixel = 0,
                }, row)
                corner(track, 20)

                local knob = create("Frame", {
                    Position = value and UDim2.new(1, -19, 0, 3) or UDim2.fromOffset(3, 3),
                    Size = UDim2.fromOffset(16, 16),
                    BackgroundColor3 = Theme.Text,
                    BorderSizePixel = 0,
                }, track)
                corner(knob, 20)

                local function setValue(newValue)
                    value = newValue == true
                    tween(track, 0.18, { BackgroundColor3 = value and Theme.Accent or Theme.Border })
                    tween(knob, 0.18, { Position = value and UDim2.new(1, -19, 0, 3) or UDim2.fromOffset(3, 3) })

                    if options.Callback then
                        local ok, err = pcall(options.Callback, value)
                        if not ok then
                            warn("[VoidUI] Toggle callback error:", err)
                        end
                    end
                end

                row.Activated:Connect(function()
                    setValue(not value)
                end)

                return {
                    Set = setValue,
                    Get = function() return value end,
                }
            end

            function tab:CreateSlider(options)
                options = options or {}

                local min = options.Min or 0
                local max = options.Max or 100
                local value = math.clamp(options.Default or min, min, max)

                local card = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 67),
                    BackgroundColor3 = Theme.Card,
                    BorderSizePixel = 0,
                }, page)
                corner(card, 11)
                stroke(card, Theme.Border, 0.3)

                local name = label(card, options.Name or "Slider", 12, Theme.Text, Enum.Font.GothamMedium)
                name.Position = UDim2.fromOffset(12, 8)
                name.Size = UDim2.new(1, -70, 0, 22)

                local number = label(card, tostring(value), 12, Theme.Accent, Enum.Font.GothamBold)
                number.Position = UDim2.new(1, -55, 0, 8)
                number.Size = UDim2.fromOffset(43, 22)
                number.TextXAlignment = Enum.TextXAlignment.Right

                local bar = create("Frame", {
                    Position = UDim2.new(0, 12, 0, 43),
                    Size = UDim2.new(1, -24, 0, 6),
                    BackgroundColor3 = Theme.Border,
                    BorderSizePixel = 0,
                }, card)
                corner(bar, 8)

                local ratio = (value - min) / math.max(1, max - min)

                local fill = create("Frame", {
                    Size = UDim2.new(ratio, 0, 1, 0),
                    BackgroundColor3 = Theme.Accent,
                    BorderSizePixel = 0,
                }, bar)
                corner(fill, 8)

                local knob = create("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(ratio, 0, 0.5, 0),
                    Size = UDim2.fromOffset(14, 14),
                    BackgroundColor3 = Theme.Text,
                    BorderSizePixel = 0,
                }, bar)
                corner(knob, 20)

                local draggingSlider = false

                local function setValue(newValue)
                    value = math.clamp(newValue, min, max)
                    local r = (value - min) / math.max(1, max - min)
                    number.Text = tostring(math.floor(value + 0.5))

                    tween(fill, 0.08, { Size = UDim2.new(r, 0, 1, 0) })
                    tween(knob, 0.08, { Position = UDim2.new(r, 0, 0.5, 0) })

                    if options.Callback then
                        local ok, err = pcall(options.Callback, value)
                        if not ok then
                            warn("[VoidUI] Slider callback error:", err)
                        end
                    end
                end

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

                local sliderChangedConn
                local sliderEndedConn

                sliderChangedConn = UserInputService.InputChanged:Connect(function(input)
                    if draggingSlider and (
                        input.UserInputType == Enum.UserInputType.Touch
                        or input.UserInputType == Enum.UserInputType.MouseMovement
                    ) then
                        updateFromInput(input)
                    end
                end)

                sliderEndedConn = UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch
                    or input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingSlider = false
                    end
                end)

                card.AncestryChanged:Connect(function(_, parent)
                    if not parent then
                        if sliderChangedConn then sliderChangedConn:Disconnect() end
                        if sliderEndedConn then sliderEndedConn:Disconnect() end
                    end
                end)

                return {
                    Set = setValue,
                    Get = function() return value end,
                }
            end

            return tab
        end

        function window:Destroy()
            if viewportConn then viewportConn:Disconnect() end
            if gui and gui.Parent then
                gui:Destroy()
            end
        end

        return window
    end

    -- ระบบตรวจสอบ Key System อย่างสมบูรณ์และปลอดภัย
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
            return buildMainUI()
        end

        local keyMain = create("Frame", {
            Name = "KeySystem",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(420, 260),
            BackgroundColor3 = Theme.Background,
            BorderSizePixel = 0,
            ClipsDescendants = true,
        }, gui)

        corner(keyMain, 18)
        stroke(keyMain, Theme.Accent, 0.45)

        local top = create("Frame", {
            Size = UDim2.new(1, 0, 0, 50),
            BackgroundColor3 = Theme.Sidebar,
            BorderSizePixel = 0,
        }, keyMain)

        local titleLabel = label(top, kTitle, 14, Theme.Text, Enum.Font.GothamBold)
        titleLabel.Position = UDim2.fromOffset(15, 0)
        titleLabel.Size = UDim2.new(1, -60, 1, 0)
        titleLabel.TextYAlignment = Enum.TextYAlignment.Center

        local close = create("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -15, 0.5, 0),
            Size = UDim2.fromOffset(28, 28),
            BackgroundColor3 = Theme.Card,
            Text = "×",
            TextSize = 20,
            TextColor3 = Theme.Text,
            Font = Enum.Font.Gotham,
            AutoButtonColor = false,
        }, top)
        corner(close, 8)

        close.Activated:Connect(function()
            if gui and gui.Parent then
                gui:Destroy()
            end
        end)

        label(keyMain, kSubtitle, 12, Theme.Muted, Enum.Font.Gotham).Position = UDim2.fromOffset(20, 62)

        local textBoxBg = create("Frame", {
            Position = UDim2.fromOffset(20, 92),
            Size = UDim2.new(1, -40, 0, 42),
            BackgroundColor3 = Theme.Card,
            BorderSizePixel = 0,
        }, keyMain)
        corner(textBoxBg, 10)
        stroke(textBoxBg, Theme.Border, 0.3)

        local textBox = create("TextBox", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, 0),
            Size = UDim2.new(1, -24, 1, 0),
            PlaceholderText = "Enter your key here...",
            Text = "",
            TextColor3 = Theme.Text,
            PlaceholderColor3 = Theme.Muted,
            TextSize = 13,
            Font = Enum.Font.GothamMedium,
            ClearTextOnFocus = false,
        }, textBoxBg)

        local submitBtn = create("TextButton", {
            Position = UDim2.fromOffset(20, 146),
            Size = UDim2.new(1, -40, 0, 40),
            BackgroundColor3 = Theme.Accent,
            Text = "Confirm Key",
            TextSize = 13,
            TextColor3 = Theme.Text,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = false,
        }, keyMain)
        corner(submitBtn, 10)

        if getLink ~= "" then
            submitBtn.Size = UDim2.new(0.5, -25, 0, 40)
            submitBtn.Position = UDim2.new(0.5, 5, 0, 146)

            local getKeyBtn = create("TextButton", {
                Position = UDim2.fromOffset(20, 146),
                Size = UDim2.new(0.5, -25, 0, 40),
                BackgroundColor3 = Theme.Card,
                Text = "Get Key",
                TextSize = 13,
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamBold,
                AutoButtonColor = false,
            }, keyMain)
            corner(getKeyBtn, 10)
            stroke(getKeyBtn, Theme.Border, 0.3)

            getKeyBtn.Activated:Connect(function()
                local success = safeSetClipboard(getLink)
                if success then
                    notify("Clipboard", "Get Key link copied to clipboard!", 3)
                else
                    notify("Get Key", "Check console or output for link.", 4)
                end
            end)
        end

        local noteLab = label(keyMain, kNote, 11, Theme.Muted, Enum.Font.Gotham)
        noteLab.Position = UDim2.fromOffset(20, 200)
        noteLab.Size = UDim2.new(1, -40, 0, 20)
        noteLab.TextXAlignment = Enum.TextXAlignment.Center

        submitBtn.Activated:Connect(function()
            local enteredKey = textBox.Text
            
            -- ป้องกันกรณีผู้เล่นเว้นว่าง
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
                tween(keyMain, 0.3, { Size = UDim2.fromOffset(420, 0) })
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
                        stroke(textBoxBg, Theme.Border, 0.3)
                    end
                end)
            end
        end)

        return {}
    else
        return buildMainUI()
    end
end

return VoidUI
