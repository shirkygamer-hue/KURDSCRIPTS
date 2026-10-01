--[[
  KURDO SCRIPTS - Key System (Auto-Redeem + Persistent)
  1. Publish the website, then put your site address in SITE_URL below.
  2. Put your real script inside the onUnlocked function.
]]

local SITE_URL = "https://project--4d6b2738-8407-40e3-8b99-d9e5eacfc1a6.lovable.app"
local KEY_URL  = "https://link-hub.net/9831936/xzc2mpJU9Gck"

-- Where to save the key so it survives executor restarts
local SAVE_FILE = "KURDO_KEY.txt"

local function onUnlocked()
    print("[KURDO] Access granted! Loading script...")
    loadstring(game:HttpGet("https://raw.githubusercontent.com/shirkygamer-hue/KURD-SCRIPTS/refs/heads/main/obf_fO2Zj14akiBPqRl5D9Pmky440GDpr99Qy3qaa1N7ms3Pbos7NtEdWUJLntoO65Z3.lua.txt"))()
end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

-- ===== Key storage (survives restarts) =====
local function saveKey(key)
    if getgenv then getgenv().KURDO_KEY = key end
    if writefile then pcall(writefile, SAVE_FILE, key) end
end

local function loadSavedKey()
    local k = getgenv and getgenv().KURDO_KEY
    if k and k ~= "" then return k end
    if isfile and isfile(SAVE_FILE) then
        local ok, data = pcall(readfile, SAVE_FILE)
        if ok and data and data ~= "" then
            if getgenv then getgenv().KURDO_KEY = data end
            return data
        end
    end
    return nil
end

local function clearSavedKey()
    if getgenv then getgenv().KURDO_KEY = nil end
    if isfile and isfile(SAVE_FILE) and delfile then pcall(delfile, SAVE_FILE) end
end

-- ===== Verification =====
-- Returns: "valid" | "expired" | "invalid" | "error"
local function checkKey(key)
    key = (key or ""):gsub("%s+", "")
    if key == "" then return "invalid" end
    local ok, res = pcall(function()
        return game:HttpGet(SITE_URL .. "/api/public/verify?key=" .. HttpService:UrlEncode(key))
    end)
    if not ok or not res then return "error" end
    res = tostring(res):lower()
    if res:find("^valid") then return "valid" end
    if res:find("expire") then return "expired" end
    if res:find("invalid") or res:find("not%s*found") then return "invalid" end
    return "invalid"
end

-- ===== Try saved key first (silent auto-redeem) =====
local savedKey = loadSavedKey()
if savedKey then
    local result = checkKey(savedKey)
    if result == "valid" then
        onUnlocked()
        return
    else
        -- Expired or invalid → wipe it so they must re-enter
        clearSavedKey()
    end
end

-- ===== GUI =====
local gui = Instance.new("ScreenGui")
gui.Name = "KurdoKeySystem"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = player:WaitForChild("PlayerGui") end

local CYAN = Color3.fromRGB(0, 240, 255)
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(340, 210)
frame.Position = UDim2.new(0.5, -170, 0.5, -105)
frame.BackgroundColor3 = Color3.fromRGB(18, 22, 33)
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)
local stroke = Instance.new("UIStroke", frame); stroke.Color = CYAN; stroke.Transparency = 0.7

local function label(text, y, size, color)
    local l = Instance.new("TextLabel", frame)
    l.BackgroundTransparency = 1
    l.Size = UDim2.new(1, -30, 0, size + 6)
    l.Position = UDim2.fromOffset(15, y)
    l.Font = Enum.Font.GothamBold
    l.TextSize = size
    l.TextColor3 = color
    l.Text = text
    return l
end
label("KURDØ SCRIPTS", 14, 20, Color3.new(1, 1, 1))
local status = label("Enter your key to continue", 44, 13, Color3.fromRGB(138, 147, 166))

local box = Instance.new("TextBox", frame)
box.Size = UDim2.new(1, -30, 0, 38)
box.Position = UDim2.fromOffset(15, 78)
box.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
box.TextColor3 = CYAN
box.PlaceholderText = "KURDO-xxxxxxxx-xxxxxxxx"
box.Text = ""
box.Font = Enum.Font.Code
box.TextSize = 14
box.ClearTextOnFocus = false
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)

local function button(text, x, color, txtColor)
    local b = Instance.new("TextButton", frame)
    b.Size = UDim2.new(0.5, -20, 0, 38)
    b.Position = UDim2.new(x, x == 0 and 15 or 5, 0, 130)
    b.BackgroundColor3 = color
    b.TextColor3 = txtColor
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.Text = text
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    return b
end
local getBtn = button("Get Key", 0, Color3.fromRGB(88, 101, 242), Color3.new(1, 1, 1))
local checkBtn = button("Redeem", 0.5, CYAN, Color3.fromRGB(7, 9, 14))

local close = Instance.new("TextButton", frame)
close.Size = UDim2.fromOffset(26, 26); close.Position = UDim2.new(1, -34, 0, 8)
close.BackgroundTransparency = 1; close.Text = "✕"; close.TextColor3 = Color3.fromRGB(138, 147, 166)
close.Font = Enum.Font.GothamBold; close.TextSize = 16
close.MouseButton1Click:Connect(function() gui:Destroy() end)

label("Keys reset every 12 hours", 180, 11, Color3.fromRGB(138, 147, 166))

-- Get Key → opens link-hub
getBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(KEY_URL)
        status.Text = "Link copied! Open it in your browser."
    else
        status.Text = KEY_URL
    end
    status.TextColor3 = CYAN
end)

-- Redeem / Check
local busy = false
local function redeem()
    if busy then return end
    busy = true
    status.Text = "Redeeming..."; status.TextColor3 = Color3.fromRGB(138, 147, 166)

    local result = checkKey(box.Text)

    if result == "valid" then
        status.Text = "Key valid! Loading..."; status.TextColor3 = Color3.fromRGB(0, 230, 118)
        saveKey((box.Text):gsub("%s+", ""))   -- auto-save for next time
        task.wait(0.6)
        gui:Destroy()
        onUnlocked()
    elseif result == "expired" then
        status.Text = "Key expired. Get a new one."; status.TextColor3 = Color3.fromRGB(255, 179, 0)
        clearSavedKey()
    elseif result == "error" then
        status.Text = "Server error. Try again."; status.TextColor3 = Color3.fromRGB(255, 179, 0)
    else
        status.Text = "Invalid key."; status.TextColor3 = Color3.fromRGB(255, 71, 87)
        clearSavedKey()
    end
    busy = false
end

checkBtn.MouseButton1Click:Connect(redeem)
box.FocusLost:Connect(function(enter) if enter then redeem() end end)  -- press Enter to redeem