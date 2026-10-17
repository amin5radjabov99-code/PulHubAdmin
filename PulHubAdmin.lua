--[[
    PulHubAdmin
    Purple Neon Edition
    Version 2.0

    Client-side admin interface for your own Roblox game.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Replace with your Roblox UserId.
local ADMINS = {
    [123456789] = true
}

if not ADMINS[LocalPlayer.UserId] then
    return
end

local Theme = {
    Background = Color3.fromRGB(12, 10, 21),
    Panel = Color3.fromRGB(22, 17, 36),
    Card = Color3.fromRGB(30, 23, 48),
    Accent = Color3.fromRGB(151, 76, 255),
    AccentDark = Color3.fromRGB(91, 43, 160),
    Text = Color3.fromRGB(246, 241, 255),
    Muted = Color3.fromRGB(165, 151, 192),
    Green = Color3.fromRGB(53, 224, 150),
    Red = Color3.fromRGB(255, 77, 105),
    Blue = Color3.fromRGB(75, 145, 255)
}

local State = {
    SelectedPlayer = nil,
    CurrentTab = "Dashboard",
    Spectating = false,
    Toggles = {
        RoleViewer = true,
        SpeedMonitor = true,
        AntiCheat = true,
        Notifications = true,
        AimDetection = true
    }
}

local Connections = {}
local Destroyed = false

local function track(connection)
    table.insert(Connections, connection)
    return connection
end

local function create(className, properties, parent)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    object.Parent = parent
    return object
end

local function corner(object, radius)
    create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8)
    }, object)
end

local function stroke(object, color, thickness)
    return create("UIStroke", {
        Color = color or Theme.Accent,
        Thickness = thickness or 1
    }, object)
end

local function label(parent, text, size, position, fontSize, color)
    return create("TextLabel", {
        Size = size,
        Position = position,
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = fontSize or 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center
    }, parent)
end

local function button(parent, text, position, size)
    local item = create("TextButton", {
        Size = size,
        Position = position,
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        AutoButtonColor = false
    }, parent)

    corner(item, 8)

    item.MouseEnter:Connect(function()
        if not Destroyed then
            TweenService:Create(item, TweenInfo.new(0.12), {
                BackgroundColor3 = Theme.AccentDark
            }):Play()
        end
    end)

    item.MouseLeave:Connect(function()
        if not Destroyed then
            TweenService:Create(item, TweenInfo.new(0.12), {
                BackgroundColor3 = Theme.Card
            }):Play()
        end
    end)

    return item
end

local GUI = create("ScreenGui", {
    Name = "PulHubAdmin",
    ResetOnSpawn = false,
    DisplayOrder = 100,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, PlayerGui)

local Main = create("Frame", {
    Name = "Main",
    Size = UDim2.new(0.92, 0, 0.82, 0),
    Position = UDim2.new(0.04, 0, 0.09, 0),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0,
    ClipsDescendants = true
}, GUI)

create("UISizeConstraint", {
    MinSize = Vector2.new(320, 350),
    MaxSize = Vector2.new(1000, 700)
}, Main)

corner(Main, 14)
stroke(Main, Theme.Accent, 2)

local Header = create("Frame", {
    Size = UDim2.new(1, 0, 0, 54),
    BackgroundColor3 = Theme.Panel,
    BorderSizePixel = 0
}, Main)

local Title = label(
    Header,
    "PulHubAdmin",
    UDim2.new(0.7, 0, 1, 0),
    UDim2.fromOffset(16, 0),
    21,
    Theme.Accent
)

Title.Font = Enum.Font.GothamBold

local Status = label(
    Header,
    "ADMIN",
    UDim2.new(0, 65, 1, 0),
    UDim2.new(1, -105, 0, 0),
    12,
    Theme.Green
)

Status.Font = Enum.Font.GothamBold

local Close = button(
    Header,
    "X",
    UDim2.new(1, -43, 0, 9),
    UDim2.fromOffset(32, 32)
)

local Sidebar = create("Frame", {
    Position = UDim2.fromOffset(10, 64),
    Size = UDim2.new(0, 132, 1, -74),
    BackgroundColor3 = Theme.Panel,
    BorderSizePixel = 0
}, Main)

corner(Sidebar, 10)

local Content = create("Frame", {
    Position = UDim2.fromOffset(151, 64),
    Size = UDim2.new(1, -161, 1, -74),
    BackgroundTransparency = 1,
    ClipsDescendants = true
}, Main)

local function clearContent()
    for _, item in ipairs(Content:GetChildren()) do
        item:Destroy()
    end
end

local function heading(text)
    local result = label(
        Content,
        text,
        UDim2.new(1, -8, 0, 34),
        UDim2.fromOffset(4, 0),
        16,
        Theme.Text
    )

    result.Font = Enum.Font.GothamBold
    return result
end

local function card(parent, position, size)
    local item = create("Frame", {
        Position = position,
        Size = size,
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0
    }, parent)

    corner(item, 10)
    stroke(item, Theme.AccentDark, 1)

    return item
end

local function getCharacterInfo(player)
    local character = player.Character

    if not character then
        return nil, nil, nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    return humanoid, root, character
end

local function getRole(player)
    -- Connect this function to your server's role system.
    -- This fallback reads a replicated attribute if available.

    local role = player:GetAttribute("Role")

    if typeof(role) == "string" then
        return role
    end

    return "Unknown"
end

local function getSpeed(player)
    local humanoid = getCharacterInfo(player)

    if humanoid then
        return math.floor(humanoid.WalkSpeed * 10) / 10
    end

    return 0
end

local function showDashboard()
    State.CurrentTab = "Dashboard"
    clearContent()

    heading("DASHBOARD")

    local stats = card(
        Content,
        UDim2.fromOffset(4, 43),
        UDim2.new(1, -12, 0, 100)
    )

    label(
        stats,
        "PLAYERS ONLINE",
        UDim2.new(1, -20, 0, 25),
        UDim2.fromOffset(12, 8),
        12,
        Theme.Muted
    )

    local count = label(
        stats,
        tostring(#Players:GetPlayers()),
        UDim2.new(1, -20, 0, 38),
        UDim2.fromOffset(12, 35),
        25,
        Theme.Accent
    )

    count.Font = Enum.Font.GothamBold

    label(
        Content,
        "SERVER STATUS",
        UDim2.new(1, -10, 0, 25),
        UDim2.fromOffset(5, 157),
        13,
        Theme.Muted
    )

    local server = card(
        Content,
        UDim2.fromOffset(4, 186),
        UDim2.new(1, -12, 0, 75)
    )

    label(
        server,
        "PulHubAdmin initialized",
        UDim2.new(1, -20, 0, 28),
        UDim2.fromOffset(12, 8),
        14,
        Theme.Green
    )

    label(
        server,
        "Client interface active",
        UDim2.new(1, -20, 0, 24),
        UDim2.fromOffset(12, 38),
        12,
        Theme.Muted
    )
end

local function showPlayers()
    State.CurrentTab = "Players"
    clearContent()

    heading("PLAYER MANAGEMENT")

    local search = create("TextBox", {
        Position = UDim2.fromOffset(4, 40),
        Size = UDim2.new(1, -12, 0, 35),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Text = "",
        PlaceholderText = "Search players...",
        PlaceholderColor3 = Theme.Muted,
        TextColor3 = Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        ClearTextOnFocus = false
    }, Content)

    corner(search, 8)

    local list = create("ScrollingFrame", {
        Position = UDim2.fromOffset(4, 83),
        Size = UDim2.new(1, -12, 1, -88),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new()
    }, Content)

    corner(list, 8)

    create("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, list)

    create("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6)
    }, list)

    local function refresh()
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        local query = search.Text:lower()

        for _, player in ipairs(Players:GetPlayers()) do
            local match =
                player.Name:lower():find(query, 1, true)
                or player.DisplayName:lower():find(query, 1, true)

            if match then
                local row = button(
                    list,
                    player.DisplayName .. "  @" .. player.Name,
                    UDim2.new(),
                    UDim2.new(1, -4, 0, 39)
                )

                row.LayoutOrder = player.UserId

                if State.SelectedPlayer == player then
                    row.BackgroundColor3 = Theme.AccentDark
                end

                row.MouseButton1Click:Connect(function()
                    State.SelectedPlayer = player
                    showInspector()
                end)
            end
        end
    end

    track(search:GetPropertyChangedSignal("Text"):Connect(refresh))
    track(Players.PlayerAdded:Connect(refresh))
    track(Players.PlayerRemoving:Connect(refresh))

    refresh()
end

function showInspector()
    State.CurrentTab = "Inspector"
    clearContent()

    local player = State.SelectedPlayer

    heading("PLAYER INSPECTOR")

    if not player or player.Parent ~= Players then
        label(
            Content,
            "Select a player first.",
            UDim2.new(1, -10, 0, 35),
            UDim2.fromOffset(5, 45),
            14,
            Theme.Muted
        )
        return
    end

    local info = card(
        Content,
        UDim2.fromOffset(4, 42),
        UDim2.new(1, -12, 0, 170)
    )

    label(
        info,
        player.DisplayName,
        UDim2.new(1, -20, 0, 28),
        UDim2.fromOffset(12, 8),
        18,
        Theme.Accent
    )

    label(
        info,
        "Username: " .. player.Name,
        UDim2.new(1, -20, 0, 24),
        UDim2.fromOffset(12, 42),
        12,
        Theme.Text
    )

    label(
        info,
        "User ID: " .. player.UserId,
        UDim2.new(1, -20, 0, 24),
        UDim2.fromOffset(12, 68),
        12,
        Theme.Text
    )

    label(
        info,
        "Role: " .. getRole(player),
        UDim2.new(1, -20, 0, 24),
        UDim2.fromOffset(12, 94),
        12,
        Theme.Text
    )

    label(
        info,
        "WalkSpeed: " .. getSpeed(player),
        UDim2.new(1, -20, 0, 24),
        UDim2.fromOffset(12, 120),
        12,
        Theme.Text
    )

    local spectate = button(
        Content,
        "Spectate",
        UDim2.fromOffset(4, 225),
        UDim2.fromOffset(130, 38)
    )

    spectate.BackgroundColor3 = Theme.Accent

    spectate.MouseButton1Click:Connect(function()
        local humanoid = getCharacterInfo(player)

        if humanoid then
            workspace.CurrentCamera.CameraSubject = humanoid
            State.Spectating = true
        end
    end)

    local stop = button(
        Content,
        "Stop Spectating",
        UDim2.fromOffset(142, 225),
        UDim2.fromOffset(145, 38)
    )

    stop.MouseButton1Click:Connect(function()
        local humanoid = getCharacterInfo(LocalPlayer)

        if humanoid then
            workspace.CurrentCamera.CameraSubject = humanoid
        end

        State.Spectating = false
    end)
end

local function showToggles()
    State.CurrentTab = "Settings"
    clearContent()

    heading("FEATURE SETTINGS")

    local names = {
        RoleViewer = "Role Viewer",
        SpeedMonitor = "Speed Monitor",
        AntiCheat = "Anti-Cheat",
        Notifications = "Notifications",
        AimDetection = "Aim Detection"
    }

    local index = 0

    for key, title in pairs(names) do
        index += 1

        local row = card(
            Content,
            UDim2.fromOffset(4, 42 + (index - 1) * 48),
            UDim2.new(1, -12, 0, 41)
        )

        label(
            row,
            title,
            UDim2.new(0.65, 0, 1, 0),
            UDim2.fromOffset(10, 0),
            13,
            Theme.Text
        )

        local toggle = button(
            row,
            State.Toggles[key] and "ON" or "OFF",
            UDim2.new(1, -72, 0, 5),
            UDim2.fromOffset(62, 30)
        )

        if State.Toggles[key] then
            toggle.BackgroundColor3 = Theme.AccentDark
        end

        toggle.MouseButton1Click:Connect(function()
            State.Toggles[key] = not State.Toggles[key]

            toggle.Text = State.Toggles[key] and "ON" or "OFF"
            toggle.BackgroundColor3 = State.Toggles[key]
                and Theme.AccentDark or Theme.Card
        end)
    end
end

local function showDetection()
    State.CurrentTab = "Detection"
    clearContent()

    heading("DETECTION TOOLS")

    local description = card(
        Content,
        UDim2.fromOffset(4, 42),
        UDim2.new(1, -12, 0, 145)
    )

    label(
        description,
        "Aim Detection",
        UDim2.new(1, -20, 0, 26),
        UDim2.fromOffset(12, 8),
        15,
        Theme.Accent
    )

    label(
        description,
        "Detection requires server-side telemetry. " ..
        "Client observations alone cannot reliably prove cheating.",
        UDim2.new(1, -24, 0, 75),
        UDim2.fromOffset(12, 38),
        13,
        Theme.Muted
    ).TextWrapped = true

    local speed = card(
        Content,
        UDim2.fromOffset(4, 200),
        UDim2.new(1, -12, 0, 75)
    )

    label(
        speed,
        "Speed Monitor",
        UDim2.new(1, -20, 0, 25),
        UDim2.fromOffset(12, 7),
        14,
        Theme.Accent
    )

    label(
        speed,
        "Selected player speed: " ..
        (State.SelectedPlayer and getSpeed(State.SelectedPlayer) or "N/A"),
        UDim2.new(1, -20, 0, 25),
        UDim2.fromOffset(12, 37),
        12,
        Theme.Text
    )
end

local function showModeration()
    State.CurrentTab = "Moderation"
    clearContent()

    heading("MODERATION")

    local player = State.SelectedPlayer

    label(
        Content,
        player and ("Selected: " .. player.Name)
            or "Select a player from the Players tab.",
        UDim2.new(1, -10, 0, 35),
        UDim2.fromOffset(4, 42),
        13,
        Theme.Muted
    )

    local kick = button(
        Content,
        "Kick Selected Player",
        UDim2.fromOffset(4, 88),
        UDim2.fromOffset(190, 40)
    )

    kick.BackgroundColor3 = Theme.Red

    kick.MouseButton1Click:Connect(function()
        warn(
            "Kick is not connected. " ..
            "Implement server-side permission validation first."
        )
    end)

    label(
        Content,
        "Kick requires a trusted server RemoteEvent.",
        UDim2.new(1, -10, 0, 40),
        UDim2.fromOffset(4, 140),
        12,
        Theme.Muted
    )
end

local tabs = {
    {"Dashboard", showDashboard},
    {"Players", showPlayers},
    {"Inspector", showInspector},
    {"Detection", showDetection},
    {"Moderation", showModeration},
    {"Settings", showToggles}
}

for index, item in ipairs(tabs) do
    local tabButton = button(
        Sidebar,
        item[1],
        UDim2.fromOffset(7, 10 + (index - 1) * 43),
        UDim2.new(1, -14, 0, 35)
    )

    tabButton.MouseButton1Click:Connect(item[2])
end

-- Window dragging
local dragging = false
local dragStart
local startPosition

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
    end
end)

track(UserInputService.InputChanged:Connect(function(input)
    if not dragging then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end))

track(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = false
    end
end))

Close.MouseButton1Click:Connect(function()
    Destroyed = true

    for _, connection in ipairs(Connections) do
        connection:Disconnect()
    end

    GUI:Destroy()
end)

showDashboard()

print("PulHubAdmin initialized")
