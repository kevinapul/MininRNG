--// =========================================================
--// RAINE MINING HUB
--// =========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")


--// =========================================================
--// SETTINGS
--// =========================================================

local BOULDER_REFRESH_TIME = 3
local BOULDER_HEIGHT_OFFSET = 10

local FLY_SPEED = 70

local MINING_INTERVAL = 0.12
local FORWARD_DISTANCE = 7

-- Brutal Farm: tidak ada delay antar arah dalam satu burst.
-- BRUTAL_INTERVAL adalah jeda antar burst supaya client/server tidak langsung freeze.
local BRUTAL_INTERVAL = 0.06
local BRUTAL_RADIUS = 8
local BRUTAL_VERTICAL = 6

local WALK_SPEED = 16

local MINING_DIRECTIONS = {
	["Atas"] = 2,
	["Tengah"] = 0,
	["Bawah"] = -2
}


--// =========================================================
--// STATES
--// =========================================================

local flyEnabled = false
local autoMiningEnabled = false
local brutalFarmEnabled = false

local miningDirection = "Tengah"

local savedPosition = nil

local flyConnection = nil
local bodyVelocity = nil
local bodyGyro = nil

local minimized = false


--// =========================================================
--// REMOTES
--// =========================================================

local requestSell = ReplicatedStorage
	:WaitForChild("GemRemotes")
	:WaitForChild("RequestSell")

local digRequest = ReplicatedStorage
	:WaitForChild("DigRemotes")
	:WaitForChild("DigRequest")


--// =========================================================
--// REMOVE OLD GUI
--// =========================================================

local oldGUI = playerGui:FindFirstChild("RaineMiningHub")

if oldGUI then
	oldGUI:Destroy()
end


--// =========================================================
--// COLORS
--// =========================================================

local COLORS = {

	Main = Color3.fromRGB(14, 15, 20),

	Sidebar = Color3.fromRGB(18, 19, 25),

	Card = Color3.fromRGB(23, 25, 32),
