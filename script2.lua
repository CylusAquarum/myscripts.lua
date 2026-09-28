-- Khởi tạo giao diện menu đơn giản
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local ToggleButton = Instance.new("TextButton")

ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.Name = "KingLegacy_AutoHop"

MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Position = UDim2.new(0.5, -100, 0.4, -75)
MainFrame.Size = UDim2.new(0, 200, 0, 120)
MainFrame.Active = true
MainFrame.Draggable = true -- Cho phép kéo thả menu trên màn hình điện thoại

Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "King Legacy Auto Hop"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14

ToggleButton.Parent = MainFrame
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
ToggleButton.Position = UDim2.new(0.1, 0, 0.45, 0)
ToggleButton.Size = UDim2.new(0.8, 0, 0, 45)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "Trạng thái: TẮT"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 16

-- Biến kiểm soát trạng thái Bật/Tắt
local _G.AutoHopRunning = false

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Hàm đổi Server
local function HopServer()
    local success, serverList = pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    
    if success and serverList and serverList.data then
        for _, server in ipairs(serverList.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                break
            end
        end
    end
end

-- Hàm kiểm tra Sea King hoặc Hydra trong map
local function CheckBoss()
    for _, obj in ipairs(workspace:GetDescendants()) do
        local name = obj.Name:lower()
        if name:find("seaking") or name:find("hydra") then
            return true
        end
    end
    return false
end

-- Xử lý nút bấm Bật/Tắt
ToggleButton.MouseButton1Click:Connect(function()
    _G.AutoHopRunning = not _G.AutoHopRunning
    if _G.AutoHopRunning then
        ToggleButton.Text = "Trạng thái: BẬT"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
    else
        ToggleButton.Text = "Trạng thái: TẮT"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
    end
end)

-- Vòng lặp chạy ngầm tính năng
task.spawn(function()
    while true do
        task.wait(3)
        if _G.AutoHopRunning then
            local found = CheckBoss()
            if not found then
                -- Nếu không thấy boss, tiến hành đổi server
                HopServer()
                task.wait(10)
            else
                -- Đã thấy boss, dừng lại để xử lý
                print("Đã phát hiện Boss trong server này!")
                task.wait(10)
            end
        end
    end
end)
