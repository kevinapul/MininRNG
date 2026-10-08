--// =========================================================
--// RAINE MINING HUB
--// =========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = nil
pcall(function()
	VirtualInputManager = game:GetService("VirtualInputManager")
end)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")


--// =========================================================
--// SETTINGS
--// =========================================================

local BOULDER_REFRESH_TIME = 3
local BOULDER_HEIGHT_OFFSET = 10

local FLY_SPEED = 70
local movementSpeed = 70

local FORWARD_DISTANCE = 7

local AUTO_BUY_CHECK_INTERVAL = 1.0
local CATALOG_REFRESH_INTERVAL = 3.0
local DESTRUCTIVE_RADIUS = 7
local DESTRUCTIVE_SIDE = 6
local DESTRUCTIVE_VERTICAL = 6

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
local destructiveMiningEnabled = false
local autoBuyRadarEnabled = false
local autoBuyBombEnabled = false

local miningDirection = "Tengah"
local selectedRadars = {}
local selectedBombs = {}


local savedPosition = nil

local flyConnection = nil
local bodyVelocity = nil
local bodyGyro = nil

local minimized = false
local miniRadarFrame = nil


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

	CardHover = Color3.fromRGB(29, 31, 40),

	Input = Color3.fromRGB(28, 30, 38),

	Accent = Color3.fromRGB(125, 92, 255),

	AccentDark = Color3.fromRGB(85, 61, 190),

	Text = Color3.fromRGB(240, 240, 245),

	SubText = Color3.fromRGB(145, 148, 160),

	Green = Color3.fromRGB(62, 190, 115),

	Red = Color3.fromRGB(210, 70, 82),

	Border = Color3.fromRGB(42, 44, 55)

}


--// =========================================================
--// HELPERS
--// =========================================================

local function addCorner(object, radius)

	local corner = Instance.new("UICorner")

	corner.CornerRadius =
		UDim.new(0, radius or 8)

	corner.Parent = object

	return corner

end


local function addStroke(object, transparency)

	local stroke = Instance.new("UIStroke")

	stroke.Color = COLORS.Border

	stroke.Transparency =
		transparency or 0.4

	stroke.Thickness = 1

	stroke.Parent = object

	return stroke

end


local function tween(object, properties, duration)

	TweenService:Create(

		object,

		TweenInfo.new(
			duration or 0.15,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),

		properties

	):Play()

end


local function getCharacter()

	return player.Character

end


local function getRoot()

	local character = getCharacter()

	if not character then
		return nil
	end

	return character:FindFirstChild(
		"HumanoidRootPart"
	)

end


local function getHumanoid()

	local character = getCharacter()

	if not character then
		return nil
	end

	return character:FindFirstChildOfClass(
		"Humanoid"
	)

end


--// =========================================================
--// MAIN GUI
--// =========================================================

local gui = Instance.new("ScreenGui")

gui.Name = "RaineMiningHub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui


local main = Instance.new("Frame")

main.Name = "Main"

main.Size =
	UDim2.fromOffset(
		640,
		440
	)

main.Position =
	UDim2.new(
		0.5,
		-320,
		0.5,
		-220
	)

main.BackgroundColor3 = COLORS.Main
main.BorderSizePixel = 0

main.ClipsDescendants = true
main.Active = true

main.Parent = gui

addCorner(main, 13)
addStroke(main, 0.2)


--// =========================================================
--// TOP BAR
--// =========================================================

local topBar = Instance.new("Frame")

topBar.Size =
	UDim2.new(
		1,
		0,
		0,
		50
	)

topBar.BackgroundColor3 =
	Color3.fromRGB(
		17,
		18,
		24
	)

topBar.BorderSizePixel = 0

topBar.Active = true

topBar.Parent = main


local logo = Instance.new("TextLabel")

logo.Position =
	UDim2.fromOffset(
		18,
		0
	)

logo.Size =
	UDim2.fromOffset(
		40,
		50
	)

logo.BackgroundTransparency = 1

logo.Text = "R"

logo.TextColor3 = COLORS.Accent

logo.TextSize = 24

logo.Font =
	Enum.Font.GothamBlack

logo.Parent = topBar


local title = Instance.new("TextLabel")

title.Position =
	UDim2.fromOffset(
		54,
		5
	)

title.Size =
	UDim2.new(
		1,
		-130,
		0,
		25
	)

title.BackgroundTransparency = 1

title.Text =
	"RAINE HUB"

title.TextColor3 =
	COLORS.Text

title.TextSize = 15

title.Font =
	Enum.Font.GothamBold

title.TextXAlignment =
	Enum.TextXAlignment.Left

title.Parent = topBar


local subtitle = Instance.new("TextLabel")

subtitle.Position =
	UDim2.fromOffset(
		55,
		26
	)

subtitle.Size =
	UDim2.new(
		1,
		-130,
		0,
		16
	)

subtitle.BackgroundTransparency = 1

subtitle.Text =
	"Mining Utility"

subtitle.TextColor3 =
	COLORS.SubText

subtitle.TextSize = 10

subtitle.Font =
	Enum.Font.Gotham

subtitle.TextXAlignment =
	Enum.TextXAlignment.Left

subtitle.Parent = topBar


--// =========================================================
--// MINIMIZE
--// =========================================================

local minimizeButton =
	Instance.new("TextButton")

minimizeButton.AnchorPoint =
	Vector2.new(
		1,
		0.5
	)

minimizeButton.Position =
	UDim2.new(
		1,
		-14,
		0.5,
		0
	)

minimizeButton.Size =
	UDim2.fromOffset(
		32,
		30
	)

minimizeButton.BackgroundColor3 =
	COLORS.Card

minimizeButton.Text = "—"

minimizeButton.TextColor3 =
	COLORS.Text

minimizeButton.TextSize = 18

minimizeButton.Font =
	Enum.Font.GothamBold

minimizeButton.AutoButtonColor = false

minimizeButton.Parent = topBar

addCorner(minimizeButton, 7)


--// =========================================================
--// SIDEBAR
--// =========================================================

local sidebar = Instance.new("Frame")

sidebar.Position =
	UDim2.fromOffset(
		0,
		50
	)

sidebar.Size =
	UDim2.new(
		0,
		155,
		1,
		-50
	)

sidebar.BackgroundColor3 =
	COLORS.Sidebar

sidebar.BorderSizePixel = 0

sidebar.Parent = main


local sidebarPadding =
	Instance.new("UIPadding")

sidebarPadding.PaddingTop =
	UDim.new(0, 16)

sidebarPadding.PaddingLeft =
	UDim.new(0, 10)

sidebarPadding.PaddingRight =
	UDim.new(0, 10)

sidebarPadding.Parent =
	sidebar


local sidebarLayout =
	Instance.new("UIListLayout")

sidebarLayout.Padding =
	UDim.new(0, 7)

sidebarLayout.SortOrder =
	Enum.SortOrder.LayoutOrder

sidebarLayout.Parent =
	sidebar


--// =========================================================
--// CONTENT
--// =========================================================

local content = Instance.new("Frame")

content.Position =
	UDim2.fromOffset(
		155,
		50
	)

content.Size =
	UDim2.new(
		1,
		-155,
		1,
		-50
	)

content.BackgroundTransparency = 1

content.ClipsDescendants = true

content.Parent = main


--// =========================================================
--// DRAG SYSTEM
--// =========================================================

local dragging = false
local dragInput = nil
local dragStart = nil
local startPosition = nil


topBar.InputBegan:Connect(function(input)

	if input.UserInputType
		== Enum.UserInputType.MouseButton1
		or input.UserInputType
		== Enum.UserInputType.Touch then

		dragging = true

		dragStart =
			input.Position

		startPosition =
			main.Position


		input.Changed:Connect(function()

			if input.UserInputState
				== Enum.UserInputState.End then

				dragging = false

			end

		end)

	end

end)


topBar.InputChanged:Connect(function(input)

	if input.UserInputType
		== Enum.UserInputType.MouseMovement
		or input.UserInputType
		== Enum.UserInputType.Touch then

		dragInput = input

	end

end)


UserInputService.InputChanged:
	Connect(function(input)

		if input == dragInput
			and dragging then

			local delta =
				input.Position
				- dragStart


			main.Position =
				UDim2.new(

					startPosition.X.Scale,

					startPosition.X.Offset
						+ delta.X,

					startPosition.Y.Scale,

					startPosition.Y.Offset
						+ delta.Y

				)

		end

	end)


--// =========================================================
--// MINIMIZE SYSTEM
--// =========================================================

minimizeButton.MouseButton1Click:
	Connect(function()

		minimized =
			not minimized


		if minimized then

			sidebar.Visible = false
			content.Visible = false

			if miniRadarFrame then
				miniRadarFrame.Visible = true
			end

			minimizeButton.Text = "□"

			tween(
				main,
				{
					Size =
						UDim2.fromOffset(
							640,
							50
						)
				},
				0.2
			)

		else

			if miniRadarFrame then
				miniRadarFrame.Visible = false
			end

			minimizeButton.Text = "—"

			tween(
				main,
				{
					Size =
						UDim2.fromOffset(
							640,
							440
						)
				},
				0.2
			)


			task.delay(
				0.15,
				function()

					sidebar.Visible = true
					content.Visible = true

				end
			)

		end

	end)


--// =========================================================
--// RIGHT SHIFT HIDE / SHOW
--// =========================================================

UserInputService.InputBegan:
	Connect(function(input, processed)

		if processed then
			return
		end


		if input.KeyCode
			== Enum.KeyCode.RightShift then

			main.Visible =
				not main.Visible

		end

	end)


--// =========================================================
--// PAGE SYSTEM
--// =========================================================

local pages = {}
local tabButtons = {}

local currentPage = nil


local function createPage(name)

	local page =
		Instance.new("Frame")

	page.Name = name

	page.Position =
		UDim2.fromOffset(
			0,
			0
		)

	page.Size =
		UDim2.fromScale(
			1,
			1
		)

	page.BackgroundTransparency = 1

	page.Visible = false

	page.Parent = content

	pages[name] = page

	return page

end


local function switchPage(name)

	for pageName, page
		in pairs(pages) do

		page.Visible =
			pageName == name

	end


	for tabName, button
		in pairs(tabButtons) do

		if tabName == name then

			button.BackgroundColor3 =
				COLORS.AccentDark

			button.TextColor3 =
				COLORS.Text

		else

			button.BackgroundColor3 =
				Color3.fromRGB(
					18,
					19,
					25
				)

			button.TextColor3 =
				COLORS.SubText

		end

	end


	currentPage = name

end


local function createTab(
	name,
	icon,
	order
)

	local button =
		Instance.new("TextButton")

	button.Name = name

	button.Size =
		UDim2.new(
			1,
			0,
			0,
			42
		)

	button.BackgroundColor3 =
		COLORS.Sidebar

	button.BorderSizePixel = 0

	button.Text =
		"  "
		.. icon
		.. "   "
		.. name

	button.TextColor3 =
		COLORS.SubText

	button.TextSize = 13

	button.Font =
		Enum.Font.GothamMedium

	button.TextXAlignment =
		Enum.TextXAlignment.Left

	button.LayoutOrder =
		order

	button.AutoButtonColor = false

	button.Parent =
		sidebar

	addCorner(button, 8)


	button.MouseEnter:Connect(function()

		if currentPage ~= name then

			tween(
				button,
				{
					BackgroundColor3 =
						COLORS.Card
				}
			)

		end

	end)


	button.MouseLeave:Connect(function()

		if currentPage ~= name then

			tween(
				button,
				{
					BackgroundColor3 =
						COLORS.Sidebar
				}
			)

		end

	end)


	button.MouseButton1Click:
		Connect(function()

			switchPage(name)

		end)


	tabButtons[name] = button

end


--// =========================================================
--// CREATE PAGES
--// =========================================================

local homePage =
	createPage("Home")

local miningPage =
	createPage("Mining")

local boulderPage =
	createPage("Boulders")

local radarPage =
	createPage("Auto Buy")

local movementPage =
	createPage("Movement")


createTab(
	"Home",
	"⌂",
	1
)

createTab(
	"Mining",
	"⛏",
	2
)

createTab(
	"Boulders",
	"◆",
	3
)

createTab(
	"Auto Buy",
	"◉",
	4
)

createTab(
	"Movement",
	"➜",
	5
)


--// =========================================================
--// PAGE HEADER
--// =========================================================

local function createHeader(
	parent,
	titleText,
	description
)

	local label =
		Instance.new("TextLabel")

	label.Position =
		UDim2.fromOffset(
			24,
			20
		)

	label.Size =
		UDim2.new(
			1,
			-48,
			0,
			28
		)

	label.BackgroundTransparency = 1

	label.Text =
		titleText

	label.TextColor3 =
		COLORS.Text

	label.TextSize = 21

	label.Font =
		Enum.Font.GothamBold

	label.TextXAlignment =
		Enum.TextXAlignment.Left

	label.Parent =
		parent


	local desc =
		Instance.new("TextLabel")

	desc.Position =
		UDim2.fromOffset(
			24,
			49
		)

	desc.Size =
		UDim2.new(
			1,
			-48,
			0,
			20
		)

	desc.BackgroundTransparency = 1

	desc.Text =
		description

	desc.TextColor3 =
		COLORS.SubText

	desc.TextSize = 11

	desc.Font =
		Enum.Font.Gotham

	desc.TextXAlignment =
		Enum.TextXAlignment.Left

	desc.Parent =
		parent

end


--// =========================================================
--// CARD
--// =========================================================

local function createCard(
	parent,
	position,
	size
)

	local card =
		Instance.new("Frame")

	card.Position = position
	card.Size = size

	card.BackgroundColor3 =
		COLORS.Card

	card.BorderSizePixel = 0

	card.Parent = parent

	addCorner(card, 10)
	addStroke(card, 0.55)

	return card

end


--// =========================================================
--// ACTION BUTTON
--// =========================================================

local function createActionButton(
	parent,
	text,
	position,
	size
)

	local button =
		Instance.new("TextButton")

	button.Position = position
	button.Size = size

	button.BackgroundColor3 =
		COLORS.Input

	button.BorderSizePixel = 0

	button.Text = text

	button.TextColor3 =
		COLORS.Text

	button.TextSize = 13

	button.Font =
		Enum.Font.GothamSemibold

	button.AutoButtonColor = false

	button.Parent = parent

	addCorner(button, 8)


	button.MouseEnter:
		Connect(function()

			tween(
				button,
				{
					BackgroundColor3 =
						COLORS.CardHover
				}
			)

		end)


	button.MouseLeave:
		Connect(function()

			tween(
				button,
				{
					BackgroundColor3 =
						COLORS.Input
				}
			)

		end)


	return button

end


--// =========================================================
--// TOGGLE
--// =========================================================

local function createToggle(
	parent,
	name,
	description,
	position
)

	local button =
		Instance.new("TextButton")

	button.Position = position

	button.Size =
		UDim2.new(
			1,
			-32,
			0,
			66
		)

	button.BackgroundColor3 =
		COLORS.Card

	button.BorderSizePixel = 0

	button.Text = ""

	button.AutoButtonColor = false

	button.Parent = parent

	addCorner(button, 10)
	addStroke(button, 0.55)


	local titleLabel =
		Instance.new("TextLabel")

	titleLabel.Position =
		UDim2.fromOffset(
			15,
			10
		)

	titleLabel.Size =
		UDim2.new(
			1,
			-100,
			0,
			22
		)

	titleLabel.BackgroundTransparency = 1

	titleLabel.Text = name

	titleLabel.TextColor3 =
		COLORS.Text

	titleLabel.TextSize = 14

	titleLabel.Font =
		Enum.Font.GothamSemibold

	titleLabel.TextXAlignment =
		Enum.TextXAlignment.Left

	titleLabel.Parent =
		button


	local desc =
		Instance.new("TextLabel")

	desc.Position =
		UDim2.fromOffset(
			15,
			34
		)

	desc.Size =
		UDim2.new(
			1,
			-100,
			0,
			18
		)

	desc.BackgroundTransparency = 1

	desc.Text =
		description

	desc.TextColor3 =
		COLORS.SubText

	desc.TextSize = 10

	desc.Font =
		Enum.Font.Gotham

	desc.TextXAlignment =
		Enum.TextXAlignment.Left

	desc.Parent =
		button


	local state =
		Instance.new("TextLabel")

	state.AnchorPoint =
		Vector2.new(
			1,
			0.5
		)

	state.Position =
		UDim2.new(
			1,
			-14,
			0.5,
			0
		)

	state.Size =
		UDim2.fromOffset(
			56,
			28
		)

	state.BackgroundColor3 =
		COLORS.Red

	state.Text =
		"OFF"

	state.TextColor3 =
		Color3.new(
			1,
			1,
			1
		)

	state.TextSize = 11

	state.Font =
		Enum.Font.GothamBold

	state.Parent =
		button

	addCorner(state, 14)


	local object = {}

	object.Enabled = false
	object.Button = button


	function object:Set(value)

		object.Enabled = value


		if value then

			state.Text = "ON"

			tween(
				state,
				{
					BackgroundColor3 =
						COLORS.Green
				}
			)

		else

			state.Text = "OFF"

			tween(
				state,
				{
					BackgroundColor3 =
						COLORS.Red
				}
			)

		end

	end


	button.MouseButton1Click:
		Connect(function()

			object:Set(
				not object.Enabled
			)


			if object.OnChanged then

				object.OnChanged(
					object.Enabled
				)

			end

		end)


	return object

end


--// =========================================================
--// HOME PAGE
--// =========================================================

createHeader(
	homePage,
	"Dashboard",
	"Quick utilities dan saved position."
)


local homeCard =
	createCard(

		homePage,

		UDim2.fromOffset(
			24,
			85
		),

		UDim2.new(
			1,
			-48,
			0,
			110
		)

	)


local sellButton =
	createActionButton(

		homeCard,

		"💰  Sell All",

		UDim2.fromOffset(
			12,
			12
		),

		UDim2.new(
			1,
			-24,
			0,
			38
		)

	)


local saveButton =
	createActionButton(

		homeCard,

		"📍  Save Position",

		UDim2.fromOffset(
			12,
			58
		),

		UDim2.new(
			0.5,
			-17,
			0,
			38
		)

	)


local returnButton =
	createActionButton(

		homeCard,

		"↩  Return Position",

		UDim2.new(
			0.5,
			5,
			0,
			58
		),

		UDim2.new(
			0.5,
			-17,
			0,
			38
		)

	)


local antiAFKCard =
	createCard(

		homePage,

		UDim2.fromOffset(
			24,
			210
		),

		UDim2.new(
			1,
			-48,
			0,
			70
		)

	)


local antiTitle =
	Instance.new("TextLabel")

antiTitle.Position =
	UDim2.fromOffset(
		15,
		10
	)

antiTitle.Size =
	UDim2.new(
		1,
		-100,
		0,
		22
	)

antiTitle.BackgroundTransparency = 1

antiTitle.Text =
	"Anti AFK"

antiTitle.TextColor3 =
	COLORS.Text

antiTitle.TextSize = 14

antiTitle.Font =
	Enum.Font.GothamSemibold

antiTitle.TextXAlignment =
	Enum.TextXAlignment.Left

antiTitle.Parent =
	antiAFKCard


local antiDesc =
	Instance.new("TextLabel")

antiDesc.Position =
	UDim2.fromOffset(
		15,
		34
	)

antiDesc.Size =
	UDim2.new(
		1,
		-100,
		0,
		18
	)

antiDesc.BackgroundTransparency = 1

antiDesc.Text =
	"Otomatis aktif selama script berjalan"

antiDesc.TextColor3 =
	COLORS.SubText

antiDesc.TextSize = 10

antiDesc.Font =
	Enum.Font.Gotham

antiDesc.TextXAlignment =
	Enum.TextXAlignment.Left

antiDesc.Parent =
	antiAFKCard


local antiState =
	Instance.new("TextLabel")

antiState.AnchorPoint =
	Vector2.new(
		1,
		0.5
	)

antiState.Position =
	UDim2.new(
		1,
		-14,
		0.5,
		0
	)

antiState.Size =
	UDim2.fromOffset(
		62,
		28
	)

antiState.BackgroundColor3 =
	COLORS.Green

antiState.Text =
	"ACTIVE"

antiState.TextColor3 =
	Color3.new(
		1,
		1,
		1
	)

antiState.TextSize = 10

antiState.Font =
	Enum.Font.GothamBold

antiState.Parent =
	antiAFKCard

addCorner(
	antiState,
	14
)


--// =========================================================
--// MINING PAGE
--// =========================================================

createHeader(
	miningPage,
	"Auto Mining",
	"Mining otomatis mengikuti arah depan karakter."
)


local miningToggle =
	createToggle(

		miningPage,

		"Auto Mining",

		"Fire DigRequest otomatis setiap 0.12 detik",

		UDim2.fromOffset(
			16,
			85
		)

	)


--// =========================================================
--// MINING DIRECTION CARD
--// =========================================================

local directionCard =
	createCard(

		miningPage,

		UDim2.fromOffset(
			16,
			165
		),

		UDim2.new(
			1,
			-32,
			0,
			72
		)

	)


local directionLabel =
	Instance.new("TextLabel")

directionLabel.Position =
	UDim2.fromOffset(
		15,
		8
	)

directionLabel.Size =
	UDim2.new(
		0.5,
		0,
		0,
		22
	)

directionLabel.BackgroundTransparency = 1

directionLabel.Text =
	"Arah Mining"

directionLabel.TextColor3 =
	COLORS.Text

directionLabel.TextSize = 14

directionLabel.Font =
	Enum.Font.GothamSemibold

directionLabel.TextXAlignment =
	Enum.TextXAlignment.Left

directionLabel.Parent =
	directionCard


local directionDesc =
	Instance.new("TextLabel")

directionDesc.Position =
	UDim2.fromOffset(
		15,
		34
	)

directionDesc.Size =
	UDim2.new(
		0.55,
		0,
		0,
		18
	)

directionDesc.BackgroundTransparency = 1

directionDesc.Text =
	"Atur slope jalur farming"

directionDesc.TextColor3 =
	COLORS.SubText

directionDesc.TextSize = 10

directionDesc.Font =
	Enum.Font.Gotham

directionDesc.TextXAlignment =
	Enum.TextXAlignment.Left

directionDesc.Parent =
	directionCard


--// =========================================================
--// DROPDOWN
--// =========================================================

local dropdown =
	Instance.new("TextButton")

dropdown.AnchorPoint =
	Vector2.new(
		1,
		0
	)

dropdown.Position =
	UDim2.new(
		1,
		-14,
		0,
		15
	)

dropdown.Size =
	UDim2.fromOffset(
		145,
		40
	)

dropdown.BackgroundColor3 =
	COLORS.Input

dropdown.Text =
	"Tengah      ▼"

dropdown.TextColor3 =
	COLORS.Text

dropdown.TextSize = 12

dropdown.Font =
	Enum.Font.GothamMedium

dropdown.AutoButtonColor = false

dropdown.ZIndex = 82

dropdown.Parent =
	directionCard

addCorner(dropdown, 8)


local optionsFrame =
	Instance.new("Frame")

optionsFrame.AnchorPoint =
	Vector2.new(
		1,
		0
	)

optionsFrame.Position =
	UDim2.new(
		1,
		-175,
		0,
		223
	)

optionsFrame.Size =
	UDim2.fromOffset(
		145,
		120
	)

optionsFrame.BackgroundColor3 =
	Color3.fromRGB(
		20,
		22,
		29
	)

optionsFrame.BorderSizePixel = 0

optionsFrame.Visible = false

optionsFrame.ZIndex = 80

optionsFrame.Parent =
	miningPage

addCorner(
	optionsFrame,
	8
)

addStroke(
	optionsFrame,
	0.2
)


local optionsLayout =
	Instance.new("UIListLayout")

optionsLayout.Padding =
	UDim.new(
		0,
		3
	)

optionsLayout.Parent =
	optionsFrame


local optionsPadding =
	Instance.new("UIPadding")

optionsPadding.PaddingTop =
	UDim.new(
		0,
		5
	)

optionsPadding.PaddingLeft =
	UDim.new(
		0,
		5
	)

optionsPadding.PaddingRight =
	UDim.new(
		0,
		5
	)

optionsPadding.Parent =
	optionsFrame


local dropdownOpen = false


local function setDropdownOpen(value)

	dropdownOpen = value
	optionsFrame.Visible = value

	if value then

		dropdown.Text =
			miningDirection
			.. "      ▲"

	else

		dropdown.Text =
			miningDirection
			.. "      ▼"

	end

end


dropdown.MouseButton1Click:
	Connect(function()

		setDropdownOpen(
			not dropdownOpen
		)

	end)


for _, optionName
	in ipairs(
		{
			"Atas",
			"Tengah",
			"Bawah"
		}
	) do

	local option =
		Instance.new("TextButton")

	option.Size =
		UDim2.new(
			1,
			0,
			0,
			33
		)

	option.BackgroundColor3 =
		COLORS.Input

	option.Text =
		optionName

	option.TextColor3 =
		COLORS.Text

	option.TextSize = 11

	option.Font =
		Enum.Font.GothamMedium

	option.AutoButtonColor = false

	option.ZIndex = 81

	option.Parent =
		optionsFrame

	addCorner(
		option,
		6
	)


	option.MouseButton1Click:
		Connect(function()

			miningDirection =
				optionName

			setDropdownOpen(false)

		end)

end


local miningInfo =
	createCard(
		miningPage,
		UDim2.fromOffset(16, 245),
		UDim2.new(1, -32, 0, 62)
	)

local miningInfoText = Instance.new("TextLabel")
miningInfoText.Position = UDim2.fromOffset(14, 8)
miningInfoText.Size = UDim2.new(1, -28, 1, -16)
miningInfoText.BackgroundTransparency = 1
miningInfoText.Text =
	"Atas    → 7 studs maju + 2 atas\n"
	.. "Tengah → 7 studs maju\n"
	.. "Bawah   → 7 studs maju + 2 bawah"
miningInfoText.TextColor3 = COLORS.SubText
miningInfoText.TextSize = 10
miningInfoText.Font = Enum.Font.Code
miningInfoText.TextXAlignment = Enum.TextXAlignment.Left
miningInfoText.TextYAlignment = Enum.TextYAlignment.Top
miningInfoText.Parent = miningInfo

local destructiveToggle = createToggle(
	miningPage,
	"Destructive Mining",
	"Burst tanpa wait: depan, kiri, kanan, atas, bawah + diagonal dalam frame yang sama",
	UDim2.fromOffset(16, 315)
)


--// =========================================================
--// MOVEMENT PAGE
--// =========================================================

createHeader(
	movementPage,
	"Movement",
	"Movement utility untuk navigasi area mining."
)

local flyToggle = createToggle(
	movementPage,
	"Fly",
	"WASD • Space naik • Left Ctrl turun",
	UDim2.fromOffset(16, 85)
)

local speedCard = createCard(
	movementPage,
	UDim2.fromOffset(16, 165),
	UDim2.new(1, -32, 0, 64)
)

local speedLabel = Instance.new("TextLabel")
speedLabel.Position = UDim2.fromOffset(15, 8)
speedLabel.Size = UDim2.new(0.55, 0, 0, 22)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Movement Speed"
speedLabel.TextColor3 = COLORS.Text
speedLabel.TextSize = 14
speedLabel.Font = Enum.Font.GothamSemibold
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = speedCard

local speedDesc = Instance.new("TextLabel")
speedDesc.Position = UDim2.fromOffset(15, 33)
speedDesc.Size = UDim2.new(0.55, 0, 0, 18)
speedDesc.BackgroundTransparency = 1
speedDesc.Text = "Ketik angka bebas untuk kecepatan Fly"
speedDesc.TextColor3 = COLORS.SubText
speedDesc.TextSize = 10
speedDesc.Font = Enum.Font.Gotham
speedDesc.TextXAlignment = Enum.TextXAlignment.Left
speedDesc.Parent = speedCard

local speedBox = Instance.new("TextBox")
speedBox.AnchorPoint = Vector2.new(1, 0.5)
speedBox.Position = UDim2.new(1, -14, 0.5, 0)
speedBox.Size = UDim2.fromOffset(145, 38)
speedBox.BackgroundColor3 = COLORS.Input
speedBox.BorderSizePixel = 0
speedBox.Text = tostring(movementSpeed)
speedBox.PlaceholderText = "70"
speedBox.TextColor3 = COLORS.Text
speedBox.PlaceholderColor3 = COLORS.SubText
speedBox.TextSize = 12
speedBox.Font = Enum.Font.GothamMedium
speedBox.ClearTextOnFocus = false
speedBox.Parent = speedCard
addCorner(speedBox, 8)

speedBox.FocusLost:Connect(function()
	local value = tonumber(speedBox.Text)
	if value and value > 0 then
		movementSpeed = math.clamp(value, 1, 1000)
		speedBox.Text = tostring(movementSpeed)
	else
		speedBox.Text = tostring(movementSpeed)
	end
end)

local ragdollToggle = createToggle(
	movementPage,
	"Ragdoll",
	"ON = paksa Humanoid ke Physics • OFF = bangun kembali",
	UDim2.fromOffset(16, 242)
)

--// =========================================================
--// BOULDER PAGE
--// =========================================================

createHeader(
	boulderPage,
	"Boulder Tracker",
	"Live boulder logger, nearest target, dan teleport list."
)

local boulderStatsCard = createCard(
	boulderPage,
	UDim2.fromOffset(16, 78),
	UDim2.new(1, -32, 0, 96)
)

local boulderStatsText = Instance.new("TextLabel")
boulderStatsText.Position = UDim2.fromOffset(14, 10)
boulderStatsText.Size = UDim2.new(1, -28, 1, -20)
boulderStatsText.BackgroundTransparency = 1
boulderStatsText.Text = "Ever seen: 0    Current: 0    Hidden: 0    Revealed: 0\nNearest: None\nDistance: -"
boulderStatsText.TextColor3 = COLORS.SubText
boulderStatsText.TextSize = 11
boulderStatsText.Font = Enum.Font.Code
boulderStatsText.TextXAlignment = Enum.TextXAlignment.Left
boulderStatsText.TextYAlignment = Enum.TextYAlignment.Top
boulderStatsText.Parent = boulderStatsCard

local boulderStatus = Instance.new("TextLabel")
boulderStatus.Position = UDim2.fromOffset(24, 178)
boulderStatus.Size = UDim2.new(1, -48, 0, 20)
boulderStatus.BackgroundTransparency = 1
boulderStatus.Text = "Scanning..."
boulderStatus.TextColor3 = COLORS.SubText
boulderStatus.TextSize = 10
boulderStatus.Font = Enum.Font.GothamMedium
boulderStatus.TextXAlignment = Enum.TextXAlignment.Left
boulderStatus.Parent = boulderPage

local boulderScroll = Instance.new("ScrollingFrame")
boulderScroll.Position = UDim2.fromOffset(16, 202)
boulderScroll.Size = UDim2.new(1, -32, 1, -218)
boulderScroll.BackgroundColor3 = COLORS.Card
boulderScroll.BorderSizePixel = 0
boulderScroll.ScrollBarThickness = 3
boulderScroll.ScrollBarImageColor3 = COLORS.Accent
boulderScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
boulderScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
boulderScroll.Parent = boulderPage
addCorner(boulderScroll, 10)
addStroke(boulderScroll, 0.55)

local boulderLayout = Instance.new("UIListLayout")
boulderLayout.Padding = UDim.new(0, 6)
boulderLayout.Parent = boulderScroll

local boulderPadding = Instance.new("UIPadding")
boulderPadding.PaddingTop = UDim.new(0, 8)
boulderPadding.PaddingBottom = UDim.new(0, 8)
boulderPadding.PaddingLeft = UDim.new(0, 8)
boulderPadding.PaddingRight = UDim.new(0, 8)
boulderPadding.Parent = boulderScroll

-- Compact directional radar shown only while the main hub is minimized.
miniRadarFrame = Instance.new("Frame")
miniRadarFrame.Name = "MiniBoulderRadar"
miniRadarFrame.Size = UDim2.fromOffset(210, 210)
miniRadarFrame.Position = UDim2.new(1, -230, 0.5, -105)
miniRadarFrame.BackgroundColor3 = COLORS.Main
miniRadarFrame.BorderSizePixel = 0
miniRadarFrame.Visible = false
miniRadarFrame.ZIndex = 100
miniRadarFrame.Parent = gui
addCorner(miniRadarFrame, 105)
addStroke(miniRadarFrame, 0.1)

local miniRadarTitle = Instance.new("TextLabel")
miniRadarTitle.Size = UDim2.new(1, -20, 0, 25)
miniRadarTitle.Position = UDim2.fromOffset(10, 12)
miniRadarTitle.BackgroundTransparency = 1
miniRadarTitle.Text = "BOULDER RADAR"
miniRadarTitle.TextColor3 = COLORS.Text
miniRadarTitle.TextSize = 12
miniRadarTitle.Font = Enum.Font.GothamBold
miniRadarTitle.ZIndex = 101
miniRadarTitle.Parent = miniRadarFrame

local miniRadarArrow = Instance.new("TextLabel")
miniRadarArrow.AnchorPoint = Vector2.new(0.5, 0.5)
miniRadarArrow.Position = UDim2.fromScale(0.5, 0.46)
miniRadarArrow.Size = UDim2.fromOffset(70, 70)
miniRadarArrow.BackgroundTransparency = 1
miniRadarArrow.Text = "▲"
miniRadarArrow.TextColor3 = COLORS.Accent
miniRadarArrow.TextSize = 48
miniRadarArrow.Font = Enum.Font.GothamBlack
miniRadarArrow.ZIndex = 101
miniRadarArrow.Parent = miniRadarFrame

local miniRadarInfo = Instance.new("TextLabel")
miniRadarInfo.Size = UDim2.new(1, -24, 0, 68)
miniRadarInfo.Position = UDim2.new(0, 12, 1, -78)
miniRadarInfo.BackgroundTransparency = 1
miniRadarInfo.Text = "No boulder\n-\nX -  Y -  Z -"
miniRadarInfo.TextColor3 = COLORS.Text
miniRadarInfo.TextSize = 10
miniRadarInfo.Font = Enum.Font.Code
miniRadarInfo.TextXAlignment = Enum.TextXAlignment.Center
miniRadarInfo.TextYAlignment = Enum.TextYAlignment.Center
miniRadarInfo.ZIndex = 101
miniRadarInfo.Parent = miniRadarFrame

--// =========================================================
--// AUTO BUY PAGE - LIVE STOCK / EVENT DRIVEN
--// =========================================================

createHeader(
	radarPage,
	"Auto Buy",
	"Live stock Radar/Bomb. Tidak spam scan atau remote."
)

local autoBuyStatus = Instance.new("TextLabel")
autoBuyStatus.Position = UDim2.fromOffset(24, 72)
autoBuyStatus.Size = UDim2.new(1, -48, 0, 18)
autoBuyStatus.BackgroundTransparency = 1
autoBuyStatus.Text = "Waiting for RadarShopGui / BombShopGui..."
autoBuyStatus.TextColor3 = COLORS.SubText
autoBuyStatus.TextSize = 10
autoBuyStatus.Font = Enum.Font.GothamMedium
autoBuyStatus.TextXAlignment = Enum.TextXAlignment.Left
autoBuyStatus.Parent = radarPage

local radarToggle = createToggle(
	radarPage,
	"Auto Buy Radar",
	"ON = beli radar terpilih sekali saat stock refresh > 0",
	UDim2.fromOffset(16, 96)
)

local bombToggle = createToggle(
	radarPage,
	"Auto Buy Bomb",
	"ON = beli bomb terpilih sekali saat stock refresh > 0",
	UDim2.fromOffset(16, 170)
)

local pickerCard = createCard(
	radarPage,
	UDim2.fromOffset(16, 244),
	UDim2.new(1, -32, 0, 126)
)

local radarPickerLabel = Instance.new("TextLabel")
radarPickerLabel.Position = UDim2.fromOffset(14, 7)
radarPickerLabel.Size = UDim2.new(0.5, -20, 0, 20)
radarPickerLabel.BackgroundTransparency = 1
radarPickerLabel.Text = "Radar"
radarPickerLabel.TextColor3 = COLORS.Text
radarPickerLabel.TextSize = 12
radarPickerLabel.Font = Enum.Font.GothamSemibold
radarPickerLabel.TextXAlignment = Enum.TextXAlignment.Left
radarPickerLabel.Parent = pickerCard

local bombPickerLabel = radarPickerLabel:Clone()
bombPickerLabel.Position = UDim2.new(0.5, 6, 0, 7)
bombPickerLabel.Text = "Bomb"
bombPickerLabel.Parent = pickerCard

local radarDropdown = Instance.new("TextButton")
radarDropdown.Position = UDim2.fromOffset(14, 32)
radarDropdown.Size = UDim2.new(0.5, -21, 0, 38)
radarDropdown.BackgroundColor3 = COLORS.Input
radarDropdown.Text = "Select radar...      ▼"
radarDropdown.TextColor3 = COLORS.Text
radarDropdown.TextSize = 11
radarDropdown.Font = Enum.Font.GothamMedium
radarDropdown.AutoButtonColor = false
radarDropdown.ZIndex = 82
radarDropdown.Parent = pickerCard
addCorner(radarDropdown, 8)

local bombDropdown = radarDropdown:Clone()
bombDropdown.Position = UDim2.new(0.5, 7, 0, 32)
bombDropdown.Text = "Select bomb...      ▼"
bombDropdown.Parent = pickerCard

local refreshCatalogButton = createActionButton(
	pickerCard,
	"↻ Rebind Shop Slots",
	UDim2.fromOffset(14, 78),
	UDim2.new(1, -28, 0, 34)
)

local function makeFloatingOptionsFrame()
	local frame = Instance.new("ScrollingFrame")
	frame.Size = UDim2.fromOffset(230, 170)
	frame.BackgroundColor3 = Color3.fromRGB(20, 22, 29)
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.ZIndex = 200
	frame.ScrollBarThickness = 3
	frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	frame.CanvasSize = UDim2.new()
	frame.Parent = gui
	addCorner(frame, 8)
	addStroke(frame, 0.15)

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 3)
	layout.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 5)
	padding.PaddingBottom = UDim.new(0, 5)
	padding.PaddingLeft = UDim.new(0, 5)
	padding.PaddingRight = UDim.new(0, 5)
	padding.Parent = frame
	return frame
end

local radarOptionsFrame = makeFloatingOptionsFrame()
local bombOptionsFrame = makeFloatingOptionsFrame()
local radarDropdownOpen = false
local bombDropdownOpen = false
local radarCatalog = {}
local bombCatalog = {}

local function placePopupBelow(button, frame)
	local pos = button.AbsolutePosition
	local size = button.AbsoluteSize
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
	local width = math.max(size.X, 230)
	frame.Size = UDim2.fromOffset(width, 170)
	local x = math.clamp(pos.X, 6, math.max(6, viewport.X - width - 6))
	local y = pos.Y + size.Y + 4
	if y + 170 > viewport.Y - 6 then
		y = math.max(6, pos.Y - 174)
	end
	frame.Position = UDim2.fromOffset(x, y)
end

local function clearOptionButtons(frame)
	for _, child in ipairs(frame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local function selectedCount(selection)
	local n = 0
	for _, value in pairs(selection) do
		if value then n += 1 end
	end
	return n
end

local liveRadarStock = {}
local liveBombStock = {}
local stockConnections = {}
local boundStockLabels = {}
local watchedShopBodies = {}
local refreshQueued = false

-- One request is allowed per observed stock-state change. This drains xN stock
-- one-by-one as the shop UI confirms each successful purchase by decrementing.
local radarBuyInFlight = {}
local bombBuyInFlight = {}
-- Bomb-only: track confirmed progress and use bounded retries when stock stalls.
local bombActiveLabels = {}
local bombAttemptCounts = {}
local bombRequestTokens = {}
local BOMB_MAX_ATTEMPTS = 3
local BOMB_ACK_TIMEOUT = 2.5

local function getRemote(folderName, remoteName)
	local folder = ReplicatedStorage:FindFirstChild(folderName)
	return folder and folder:FindFirstChild(remoteName)
end

local function isTextObject(obj)
	return obj
		and (obj:IsA("TextLabel")
			or obj:IsA("TextButton")
			or obj:IsA("TextBox"))
end

local function parseStock(textValue)
	local text = tostring(textValue or "")
	local n = text:match("[xX]%s*(%d+)")
	if not n then
		n = text:match("(%d+)%s*[sS][tT][oO][cC][kK]")
	end
	return n and tonumber(n) or nil
end

local function getLiveStock(kind, itemName)
	if kind == "Radar" then
		return liveRadarStock[itemName]
	end
	return liveBombStock[itemName]
end

local function isSelectedAndEnabled(kind, itemName)
	if kind == "Radar" then
		return autoBuyRadarEnabled and selectedRadars[itemName] == true
	end
	return autoBuyBombEnabled and selectedBombs[itemName] == true
end

local function getInFlightTable(kind)
	return kind == "Radar" and radarBuyInFlight or bombBuyInFlight
end

local function tryBuyOne(kind, itemName, reason)
	if not isSelectedAndEnabled(kind, itemName) then
		return
	end

	local stock = getLiveStock(kind, itemName)
	if not stock or stock < 1 then
		return
	end

	local inFlight = getInFlightTable(kind)
	if inFlight[itemName] then
		return
	end

	local remote
	if kind == "Radar" then
		remote = getRemote("RadarRemotes", "BuyRadar")
	else
		remote = getRemote("BombRemotes", "BuyBomb")
	end

	if not remote then
		autoBuyStatus.Text = "Buy" .. kind .. " remote not found"
		return
	end

	-- Send only one outstanding request per item until stock confirms a change.
	inFlight[itemName] = true
	local bombToken
	if kind == "Bomb" then
		bombAttemptCounts[itemName] = (bombAttemptCounts[itemName] or 0) + 1
		bombRequestTokens[itemName] = (bombRequestTokens[itemName] or 0) + 1
		bombToken = bombRequestTokens[itemName]
	end

	if kind == "Radar" then
		remote:FireServer(itemName)
	else
		remote:FireServer(itemName, "cash")
	end

	autoBuyStatus.Text = kind .. ": " .. itemName .. " • x" .. tostring(stock) .. " • buy sent (" .. reason .. ")"

	if kind == "Bomb" then
		-- If shop stock doesn't move, retry at most twice. Stop if the server
		-- refuses purchases (no money / limit / remote argument mismatch).
		task.delay(BOMB_ACK_TIMEOUT, function()
			if bombRequestTokens[itemName] ~= bombToken then return end
			if not inFlight[itemName] or not isSelectedAndEnabled("Bomb", itemName) then return end
			local label = bombActiveLabels[itemName]
			local observed = label and label.Parent and parseStock(label.Text)
			if observed == nil or observed ~= stock then return end
			inFlight[itemName] = nil
			if (bombAttemptCounts[itemName] or 0) < BOMB_MAX_ATTEMPTS then
				tryBuyOne("Bomb", itemName, "ack timeout retry")
			else
				autoBuyStatus.Text = "Bomb: " .. itemName .. " x" .. stock .. " • no stock response after 3 requests (paused)"
			end
		end)
	else
		-- Radar path unchanged.
		task.delay(2, function()
			if inFlight[itemName] then
				inFlight[itemName] = nil
			end
		end)
	end
end

local function onStockChanged(kind, itemName, stockLabel, reason)
	if not stockLabel or not stockLabel.Parent then return end

	local newStock = parseStock(stockLabel.Text)
	if newStock == nil then return end

	if kind == "Radar" then
		liveRadarStock[itemName] = newStock
		radarBuyInFlight[itemName] = nil
	else
		if bombActiveLabels[itemName] ~= stockLabel then return end
		local previous = liveBombStock[itemName]
		if previous == newStock and reason ~= "shop bind/restock" then return end
		liveBombStock[itemName] = newStock
		bombBuyInFlight[itemName] = nil
		bombAttemptCounts[itemName] = 0
		bombRequestTokens[itemName] = (bombRequestTokens[itemName] or 0) + 1
	end

	-- Every confirmed stock state is enough. If x3 -> x2 after a successful
	-- purchase, this sends the next single request. x2 -> x1 sends the next, etc.
	-- When it reaches x0, it stops naturally.
	if newStock > 0 then
		tryBuyOne(kind, itemName, reason or "stock changed")
	end
end

local function bindStockLabel(kind, itemName, stockLabel)
	if not isTextObject(stockLabel) then return end
	if boundStockLabels[stockLabel] then return end
	boundStockLabels[stockLabel] = true

	-- A newly created Stock label means the shop may just have restocked/rebuilt.
	-- Treat it as a fresh state even if the numeric stock equals the previous cycle.
	if kind == "Radar" then
		radarBuyInFlight[itemName] = nil
	else
		bombActiveLabels[itemName] = stockLabel
		bombBuyInFlight[itemName] = nil
		bombAttemptCounts[itemName] = 0
		bombRequestTokens[itemName] = (bombRequestTokens[itemName] or 0) + 1
	end

	onStockChanged(kind, itemName, stockLabel, "shop bind/restock")

	local connection = stockLabel:GetPropertyChangedSignal("Text"):Connect(function()
		onStockChanged(kind, itemName, stockLabel, "stock changed")
	end)
	table.insert(stockConnections, connection)
end

local function findStockLabel(slot)
	local card = slot:FindFirstChild("Card")
	if card then
		local stock = card:FindFirstChild("Stock")
		if isTextObject(stock) then
			return stock
		end
	end

	for _, obj in ipairs(slot:GetDescendants()) do
		if obj.Name == "Stock" and isTextObject(obj) then
			return obj
		end
	end

	return nil
end

local refreshShopBindings

local function queueShopRefresh()
	if refreshQueued then return end
	refreshQueued = true

	task.defer(function()
		task.wait(0.05)
		refreshQueued = false
		if refreshShopBindings then
			refreshShopBindings()
		end
	end)
end

local function rebuildCatalogsFromShop()
	table.clear(radarCatalog)
	table.clear(bombCatalog)

	local function scanShop(guiName, kind, catalog)
		local shopGui = playerGui:FindFirstChild(guiName)
		local window = shopGui and shopGui:FindFirstChild("Window")
		local body = window and window:FindFirstChild("Body")
		if not body then return end

		if not watchedShopBodies[body] then
			watchedShopBodies[body] = true

			body.ChildAdded:Connect(function(child)
				if child.Name:sub(1, 5) == "Slot_" then
					queueShopRefresh()
				end
			end)

			body.ChildRemoved:Connect(function(child)
				if child.Name:sub(1, 5) == "Slot_" then
					queueShopRefresh()
				end
			end)

			body.DescendantAdded:Connect(function(obj)
				if obj.Name == "Stock" and isTextObject(obj) then
					queueShopRefresh()
				end
			end)
		end

		for _, slot in ipairs(body:GetChildren()) do
			if slot.Name:sub(1, 5) == "Slot_" then
				local itemName = slot.Name:sub(6)
				table.insert(catalog, itemName)
				local stockLabel = findStockLabel(slot)
				if stockLabel then
					bindStockLabel(kind, itemName, stockLabel)
				end
			end
		end
	end

	scanShop("RadarShopGui", "Radar", radarCatalog)
	scanShop("BombShopGui", "Bomb", bombCatalog)
	table.sort(radarCatalog)
	table.sort(bombCatalog)
end

local function updateMultiDropdownText(button, selection, noun)
	local n = selectedCount(selection)
	if n == 0 then
		button.Text = "Select " .. noun .. "...      ▼"
	elseif n == 1 then
		for name, yes in pairs(selection) do
			if yes then
				button.Text = name .. "      ▼"
				break
			end
		end
	else
		button.Text = tostring(n) .. " " .. noun .. "s selected      ▼"
	end
end

local function populateMultiOptions(frame, items, selection, button, noun, kind)
	clearOptionButtons(frame)
	for _, itemName in ipairs(items) do
		local option = Instance.new("TextButton")
		option.Size = UDim2.new(1, -10, 0, 32)
		option.BackgroundColor3 = COLORS.Input
		option.BorderSizePixel = 0
		option.TextColor3 = COLORS.Text
		option.TextSize = 11
		option.Font = Enum.Font.GothamMedium
		option.AutoButtonColor = false
		option.ZIndex = 201
		option.Parent = frame
		addCorner(option, 6)

		local function redraw()
			local stock = getLiveStock(kind, itemName)
			local stockText = stock ~= nil and ("  [x" .. tostring(stock) .. "]") or ""
			option.Text = (selection[itemName] and "✓  " or "○  ") .. itemName .. stockText
			option.BackgroundColor3 = selection[itemName] and COLORS.AccentDark or COLORS.Input
		end

		redraw()
		option.MouseButton1Click:Connect(function()
			selection[itemName] = not selection[itemName] or nil
			redraw()
			updateMultiDropdownText(button, selection, noun)

			if selection[itemName] then
				local inFlight = getInFlightTable(kind)
				inFlight[itemName] = nil
				if kind == "Bomb" then
					bombAttemptCounts[itemName] = 0
					bombRequestTokens[itemName] = (bombRequestTokens[itemName] or 0) + 1
				end
				tryBuyOne(kind, itemName, "selected")
			end
		end)
	end
end

refreshShopBindings = function()
	rebuildCatalogsFromShop()
	populateMultiOptions(radarOptionsFrame, radarCatalog, selectedRadars, radarDropdown, "radar", "Radar")
	populateMultiOptions(bombOptionsFrame, bombCatalog, selectedBombs, bombDropdown, "bomb", "Bomb")
	updateMultiDropdownText(radarDropdown, selectedRadars, "radar")
	updateMultiDropdownText(bombDropdown, selectedBombs, "bomb")
	autoBuyStatus.Text = "Live bound: " .. #radarCatalog .. " radar(s) • " .. #bombCatalog .. " bomb(s)"
end

radarDropdown.MouseButton1Click:Connect(function()
	radarDropdownOpen = not radarDropdownOpen
	bombDropdownOpen = false
	bombOptionsFrame.Visible = false
	if radarDropdownOpen then
		refreshShopBindings()
		placePopupBelow(radarDropdown, radarOptionsFrame)
	end
	radarOptionsFrame.Visible = radarDropdownOpen
end)

bombDropdown.MouseButton1Click:Connect(function()
	bombDropdownOpen = not bombDropdownOpen
	radarDropdownOpen = false
	radarOptionsFrame.Visible = false
	if bombDropdownOpen then
		refreshShopBindings()
		placePopupBelow(bombDropdown, bombOptionsFrame)
	end
	bombOptionsFrame.Visible = bombDropdownOpen
end)

refreshCatalogButton.MouseButton1Click:Connect(refreshShopBindings)

RunService.RenderStepped:Connect(function()
	if radarDropdownOpen and radarOptionsFrame.Visible then placePopupBelow(radarDropdown, radarOptionsFrame) end
	if bombDropdownOpen and bombOptionsFrame.Visible then placePopupBelow(bombDropdown, bombOptionsFrame) end
end)

radarToggle.OnChanged = function(enabled)
	autoBuyRadarEnabled = enabled
	if enabled then
		refreshShopBindings()
		for itemName, selected in pairs(selectedRadars) do
			if selected and (liveRadarStock[itemName] or 0) > 0 then
				radarBuyInFlight[itemName] = nil
				tryBuyOne("Radar", itemName, "toggle on")
			end
		end
	else
		table.clear(radarBuyInFlight)
	end
end

bombToggle.OnChanged = function(enabled)
	autoBuyBombEnabled = enabled
	if enabled then
		refreshShopBindings()
		for itemName, selected in pairs(selectedBombs) do
			if selected and (liveBombStock[itemName] or 0) > 0 then
				bombBuyInFlight[itemName] = nil
				bombAttemptCounts[itemName] = 0
				bombRequestTokens[itemName] = (bombRequestTokens[itemName] or 0) + 1
				tryBuyOne("Bomb", itemName, "toggle on")
			end
		end
	else
		table.clear(bombBuyInFlight)
		table.clear(bombAttemptCounts)
		for itemName in pairs(bombRequestTokens) do
			bombRequestTokens[itemName] += 1
		end
	end
end

-- Bind once now, then rebind whenever the shop GUI or its internal slots are rebuilt.
task.defer(refreshShopBindings)

playerGui.ChildAdded:Connect(function(child)
	if child.Name == "RadarShopGui" or child.Name == "BombShopGui" then
		task.delay(0.25, queueShopRefresh)
	end
end)

playerGui.DescendantAdded:Connect(function(obj)
	if obj.Name == "Body" then
		local fullName = obj:GetFullName()
		if fullName:find("RadarShopGui", 1, true) or fullName:find("BombShopGui", 1, true) then
			queueShopRefresh()
		end
	end
end)

--// =========================================================
--// SELL ALL
--// =========================================================

sellButton.MouseButton1Click:
	Connect(function()

		requestSell:FireServer(
			"All"
		)


		local oldText =
			sellButton.Text


		sellButton.Text =
			"✓ Sold"


		task.delay(
			1,
			function()

				if sellButton then

					sellButton.Text =
						oldText

				end

			end
		)

	end)


--// =========================================================
--// SAVE POSITION
--// =========================================================

saveButton.MouseButton1Click:
	Connect(function()

		local root =
			getRoot()


		if not root then
			return
		end


		savedPosition =
			root.CFrame


		saveButton.Text =
			"✓ Position Saved"


		task.delay(
			1,
			function()

				if saveButton then

					saveButton.Text =
						"📍  Save Position"

				end

			end
		)

	end)


--// =========================================================
--// RETURN POSITION
--// =========================================================

returnButton.MouseButton1Click:
	Connect(function()

		if not savedPosition then

			returnButton.Text =
				"No position saved"

			task.delay(
				1,
				function()

					returnButton.Text =
						"↩  Return Position"

				end
			)

			return

		end


		local root =
			getRoot()


		if not root then
			return
		end


		root.CFrame =
			savedPosition


		root.AssemblyLinearVelocity =
			Vector3.zero


		returnButton.Text =
			"✓ Returned"


		task.delay(
			1,
			function()

				if returnButton then

					returnButton.Text =
						"↩  Return Position"

				end

			end
		)

	end)


--// =========================================================
--// FLY FUNCTIONS
--// =========================================================

local function stopFly()

	flyEnabled = false


	if flyConnection then

		flyConnection:
			Disconnect()

		flyConnection = nil

	end


	if bodyVelocity then

		bodyVelocity:Destroy()
		bodyVelocity = nil

	end


	if bodyGyro then

		bodyGyro:Destroy()
		bodyGyro = nil

	end


	local humanoid =
		getHumanoid()


	if humanoid then

		humanoid.PlatformStand =
			false

	end

end


local function startFly()

	local root =
		getRoot()

	local humanoid =
		getHumanoid()


	if not root
		or not humanoid then

		return false

	end


	stopFly()


	root =
		getRoot()

	humanoid =
		getHumanoid()


	if not root
		or not humanoid then

		return false

	end


	flyEnabled = true


	bodyVelocity =
		Instance.new(
			"BodyVelocity"
		)

	bodyVelocity.Name =
		"RaineFlyVelocity"

	bodyVelocity.MaxForce =
		Vector3.new(
			math.huge,
			math.huge,
			math.huge
		)

	bodyVelocity.Velocity =
		Vector3.zero

	bodyVelocity.Parent =
		root


	bodyGyro =
		Instance.new(
			"BodyGyro"
		)

	bodyGyro.Name =
		"RaineFlyGyro"

	bodyGyro.MaxTorque =
		Vector3.new(
			math.huge,
			math.huge,
			math.huge
		)

	bodyGyro.P = 90000

	bodyGyro.CFrame =
		root.CFrame

	bodyGyro.Parent =
		root


	humanoid.PlatformStand =
		true


	flyConnection =
		RunService.RenderStepped:
			Connect(function()

				if not flyEnabled
					or not root
					or not root.Parent then

					return

				end


				local camera =
					workspace.CurrentCamera


				if not camera then
					return
				end


				local direction =
					Vector3.zero


				if UserInputService:IsKeyDown(
					Enum.KeyCode.W
				) then

					direction +=
						camera.CFrame.LookVector

				end


				if UserInputService:IsKeyDown(
					Enum.KeyCode.S
				) then

					direction -=
						camera.CFrame.LookVector

				end


				if UserInputService:IsKeyDown(
					Enum.KeyCode.A
				) then

					direction -=
						camera.CFrame.RightVector

				end


				if UserInputService:IsKeyDown(
					Enum.KeyCode.D
				) then

					direction +=
						camera.CFrame.RightVector

				end


				if UserInputService:IsKeyDown(
					Enum.KeyCode.Space
				) then

					direction +=
						Vector3.yAxis

				end


				if UserInputService:IsKeyDown(
					Enum.KeyCode.LeftControl
				) then

					direction -=
						Vector3.yAxis

				end


				if direction.Magnitude > 0 then

					direction =
						direction.Unit

				end


				if bodyVelocity then

					bodyVelocity.Velocity =
						direction
						* movementSpeed

				end


				local look =
					camera.CFrame.LookVector


				local flatLook =
					Vector3.new(
						look.X,
						0,
						look.Z
					)


				if bodyGyro
					and flatLook.Magnitude
					> 0.01 then

					bodyGyro.CFrame =
						CFrame.lookAt(

							root.Position,

							root.Position
								+ flatLook.Unit

						)

				end

			end)


	return true

end


flyToggle.OnChanged =
	function(enabled)

		if enabled then

			local success =
				startFly()


			if not success then

				flyToggle:Set(false)

			end

		else

			stopFly()

		end

	end


local ragdollEnabled = false

local function setRagdoll(enabled)
	local humanoid = getHumanoid()
	if not humanoid then return end
	ragdollEnabled = enabled
	if enabled then
		pcall(function()
			humanoid.AutoRotate = false
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		end)
	else
		pcall(function()
			humanoid.AutoRotate = true
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
	end
end

ragdollToggle.OnChanged = function(enabled)
	setRagdoll(enabled)
end

--// =========================================================
--// MINING POSITION
--// =========================================================

local function getMiningPosition()

	local root =
		getRoot()


	if not root then
		return nil
	end


	local look =
		root.CFrame.LookVector


	-- horizontal direction only
	local forward =
		Vector3.new(
			look.X,
			0,
			look.Z
		)


	if forward.Magnitude
		< 0.01 then

		return nil

	end


	forward =
		forward.Unit


	local verticalOffset =
		MINING_DIRECTIONS[
			miningDirection
		] or 0


	return root.Position

		+ (
			forward
			* FORWARD_DISTANCE
		)

		+ Vector3.new(
			0,
			verticalOffset,
			0
		)

end


local function createDigVector(
	x,
	y,
	z
)

	if vector
		and vector.create then

		return vector.create(
			x,
			y,
			z
		)

	end


	return Vector3.new(
		x,
		y,
		z
	)

end


local function digInFront()

	local target =
		getMiningPosition()


	if not target then
		return
	end


	local digPosition =
		createDigVector(

			target.X,
			target.Y,
			target.Z

		)


	digRequest:FireServer(
		digPosition
	)

end


miningToggle.OnChanged =
	function(enabled)
		autoMiningEnabled = enabled
	end

destructiveToggle.OnChanged = function(enabled)
	destructiveMiningEnabled = enabled
end

local function destructiveDigBurst()
	local root = getRoot()
	if not root then return end
	local look = root.CFrame.LookVector
	local forward = Vector3.new(look.X, 0, look.Z)
	if forward.Magnitude < 0.01 then return end
	forward = forward.Unit
	local right = Vector3.new(-forward.Z, 0, forward.X)
	local up = Vector3.yAxis
	local base = root.Position
	-- all requests are fired in the same Heartbeat with no task.wait between them
	local offsets = {
		forward * DESTRUCTIVE_RADIUS,
		forward * (DESTRUCTIVE_RADIUS + 4),
		right * DESTRUCTIVE_SIDE,
		-right * DESTRUCTIVE_SIDE,
		up * DESTRUCTIVE_VERTICAL,
		-up * DESTRUCTIVE_VERTICAL,
		forward * 5 + right * 5,
		forward * 5 - right * 5,
		forward * 5 + up * 5,
		forward * 5 - up * 5,
		right * 5 + up * 4,
		-right * 5 + up * 4,
		right * 5 - up * 4,
		-right * 5 - up * 4,
	}
	for _, offset in ipairs(offsets) do
		local p = base + offset
		digRequest:FireServer(createDigVector(p.X, p.Y, p.Z))
	end
end

--// FAST MINING - EVERY HEARTBEAT
RunService.Heartbeat:Connect(function()

	if autoMiningEnabled then
		digInFront()
	end
	if destructiveMiningEnabled then
		destructiveDigBurst()
	end

end)


--// =========================================================
--// BOULDER FUNCTIONS + PASSIVE LOGGER
--// =========================================================

local seenBoulders = {}
local seenCount = 0
local nearestBoulder = nil
local nearestBoulderPosition = nil
local nearestBoulderDistance = math.huge

local function getBoulderPosition(boulder)
	if not boulder then
		return nil
	end

	if boulder:IsA("Model") then
		local mesh = boulder:FindFirstChild("Mesh_0", true)
		if mesh and mesh:IsA("BasePart") then
			return mesh.Position
		end
		local ok, cf = pcall(function()
			return boulder:GetPivot()
		end)
		if ok and cf then
			return cf.Position
		end
	elseif boulder:IsA("BasePart") then
		return boulder.Position
	end

	local part = boulder:FindFirstChildWhichIsA("BasePart", true)
	return part and part.Position or nil
end

local function getBoulderTop(boulder)
	local pos = getBoulderPosition(boulder)
	if not pos then
		return nil
	end

	if boulder:IsA("BasePart") then
		return Vector3.new(pos.X, pos.Y + (boulder.Size.Y / 2) + BOULDER_HEIGHT_OFFSET, pos.Z)
	end

	if boulder:IsA("Model") then
		local ok, cf, size = pcall(function()
			local c, s = boulder:GetBoundingBox()
			return c, s
		end)
		if ok and cf and size then
			return Vector3.new(cf.Position.X, cf.Position.Y + (size.Y / 2) + BOULDER_HEIGHT_OFFSET, cf.Position.Z)
		end
	end

	return pos + Vector3.new(0, BOULDER_HEIGHT_OFFSET, 0)
end

local function uniqueBoulderKey(obj)
	local id = obj:GetAttribute("BoulderId")
	if id ~= nil then
		return tostring(id)
	end
	local pos = getBoulderPosition(obj)
	if pos then
		return string.format("%s_%.0f_%.0f_%.0f", obj.Name, pos.X, pos.Y, pos.Z)
	end
	return obj.Name .. "_" .. tostring(obj)
end

local function rememberBoulder(obj)
	local key = uniqueBoulderKey(obj)
	if not seenBoulders[key] then
		seenBoulders[key] = true
		seenCount += 1
	end
end

local function teleportToBoulder(boulder)
	local root = getRoot()
	if not root then
		return
	end
	local target = getBoulderTop(boulder)
	if not target then
		return
	end
	local look = root.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	if flatLook.Magnitude < 0.01 then
		flatLook = Vector3.new(0, 0, -1)
	end
	root.CFrame = CFrame.lookAt(target, target + flatLook.Unit)
	root.AssemblyLinearVelocity = Vector3.zero
end

local function createBoulderButton(boulder)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 42)
	button.BackgroundColor3 = COLORS.Input
	button.BorderSizePixel = 0
	button.Text = "◆  " .. boulder.Name
	button.TextColor3 = COLORS.Text
	button.TextSize = 12
	button.Font = Enum.Font.GothamMedium
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.AutoButtonColor = false
	button.Parent = boulderScroll
	addCorner(button, 7)

	local buttonPadding = Instance.new("UIPadding")
	buttonPadding.PaddingLeft = UDim.new(0, 13)
	buttonPadding.Parent = button

	button.MouseEnter:Connect(function()
		tween(button, {BackgroundColor3 = COLORS.CardHover})
	end)
	button.MouseLeave:Connect(function()
		tween(button, {BackgroundColor3 = COLORS.Input})
	end)
	button.MouseButton1Click:Connect(function()
		if boulder and boulder.Parent then
			teleportToBoulder(boulder)
		end
	end)
end

local boulderFolder = workspace:FindFirstChild("Boulders")
if boulderFolder then
	for _, obj in ipairs(boulderFolder:GetChildren()) do
		rememberBoulder(obj)
	end
	boulderFolder.ChildAdded:Connect(function(obj)
		task.wait(0.1)
		rememberBoulder(obj)
	end)
end

local lastBoulderSignature = ""

local function updateMiniRadar(root)
	if not miniRadarFrame then
		return
	end
	if not root or not nearestBoulderPosition or not nearestBoulder then
		miniRadarArrow.Rotation = 0
		miniRadarInfo.Text = "No boulder\n-\nX -  Y -  Z -"
		return
	end

	local delta = nearestBoulderPosition - root.Position
	local flatDelta = Vector3.new(delta.X, 0, delta.Z)
	if flatDelta.Magnitude > 0.01 then
		local dir = flatDelta.Unit
		local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
		local right = Vector3.new(root.CFrame.RightVector.X, 0, root.CFrame.RightVector.Z)
		if look.Magnitude > 0.01 and right.Magnitude > 0.01 then
			local angle = math.deg(math.atan2(dir:Dot(right.Unit), dir:Dot(look.Unit)))
			miniRadarArrow.Rotation = angle
		end
	end

	miniRadarInfo.Text = string.format(
		"%s\n%d studs\nX %.0f  Y %.0f  Z %.0f",
		nearestBoulder.Name,
		math.floor(nearestBoulderDistance + 0.5),
		nearestBoulderPosition.X,
		nearestBoulderPosition.Y,
		nearestBoulderPosition.Z
	)
end

local function refreshBoulders()
	local folder = workspace:FindFirstChild("Boulders")
	if not folder then
		boulderStatus.Text = "Folder Boulders tidak ditemukan"
		boulderStatsText.Text = "Ever seen: " .. seenCount .. "    Current: 0\nNearest: None"
		return
	end

	if folder ~= boulderFolder then
		boulderFolder = folder
		for _, obj in ipairs(folder:GetChildren()) do
			rememberBoulder(obj)
		end
		folder.ChildAdded:Connect(function(obj)
			task.wait(0.1)
			rememberBoulder(obj)
		end)
	end

	local boulders = folder:GetChildren()
	table.sort(boulders, function(a, b)
		return a.Name:lower() < b.Name:lower()
	end)

	local hidden, revealed = 0, 0
	local root = getRoot()
	nearestBoulder = nil
	nearestBoulderPosition = nil
	nearestBoulderDistance = math.huge

	local signatureParts = {}
	for _, boulder in ipairs(boulders) do
		rememberBoulder(boulder)
		table.insert(signatureParts, boulder.Name .. tostring(boulder))
		if boulder:GetAttribute("Revealed") == true then
			revealed += 1
		else
			hidden += 1
		end
		if root then
			local pos = getBoulderPosition(boulder)
			if pos then
				local dist = (pos - root.Position).Magnitude
				if dist < nearestBoulderDistance then
					nearestBoulderDistance = dist
					nearestBoulder = boulder
					nearestBoulderPosition = pos
				end
			end
		end
	end

	local nearestName = nearestBoulder and nearestBoulder.Name or "None"
	local nearestDistText = nearestBoulderDistance < math.huge and (math.floor(nearestBoulderDistance + 0.5) .. " studs") or "-"
	boulderStatsText.Text =
		"Ever seen: " .. seenCount .. "    Current: " .. #boulders .. "    Hidden: " .. hidden .. "    Revealed: " .. revealed ..
		"\nNearest: " .. nearestName ..
		"\nDistance: " .. nearestDistText
	updateMiniRadar(root)

	local signature = table.concat(signatureParts, "|")
	if signature == lastBoulderSignature then
		boulderStatus.Text = tostring(#boulders) .. " boulders ditemukan"
		return
	end
	lastBoulderSignature = signature

	for _, child in ipairs(boulderScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local valid = 0
	for _, boulder in ipairs(boulders) do
		if getBoulderTop(boulder) then
			valid += 1
			createBoulderButton(boulder)
		end
	end
	boulderStatus.Text = tostring(valid) .. " boulders ditemukan"
end

task.spawn(function()
	while gui.Parent do
		refreshBoulders()
		task.wait(0.5)
	end
end)


--// =========================================================
--// ANTI AFK - SPACE EVERY 14 MINUTES
--// =========================================================

local ANTI_AFK_INTERVAL = 14 * 60

local function antiAfkPulse()
	local sent = false
	if VirtualInputManager then
		local ok = pcall(function()
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
			task.wait(0.08)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
		end)
		sent = ok
	end
	if not sent then
		local humanoid = getHumanoid()
		if humanoid then
			pcall(function()
				humanoid.Jump = true
			end)
		end
	end
end

-- One visible activity pulse every 14 minutes, safely below Roblox's normal idle timeout.
task.spawn(function()
	while gui.Parent do
		task.wait(ANTI_AFK_INTERVAL)
		antiAfkPulse()
	end
end)

--// =========================================================
--// RESPAWN
--// =========================================================

player.CharacterAdded:
	Connect(function()

		if flyEnabled then

			flyToggle:Set(false)

			stopFly()

		end

		if ragdollEnabled then
			ragdollToggle:Set(false)
			ragdollEnabled = false
		end

	end)


--// =========================================================
--// START PAGE
--// =========================================================

--// =========================================================
-- Separate function scope prevents the Luau 200-local-register compile error.
task.spawn(function()
--// SMART MOUNTAIN EXPLORER V4
--// Local scope: avoids original 200-local-register compiler limit.
local page = createPage("Explorer")
createTab("Explorer", "⛏", 6)
createHeader(page, "Mountain Explorer V4", "Sweep surface + nearby crystal + altitude progression")

local enable = createToggle(page, "Adaptive Mountain Farm", "Sweep terrain, collect nearby, climb layers", UDim2.fromOffset(16, 74))
local settings = createCard(page, UDim2.fromOffset(16, 151), UDim2.new(1,-32,0,126))
local speed = 32
local directionRadius = 8
local layerHeight = 65
local targetTop = 2000 -- approximate target RELATIVE to mountain entrance, not world Y
local minHeight = 100
local knownBase, knownMountain = nil, nil
local session = {enabled=false, phase="IDLE", layer=0, heading=Vector3.new(1,0,0), sweepStart=0,
    lastMove=0,lastPos=nil, turnCount=0, lastDig=0,lastScan=0,lastCollect=0,
    lastSector=nil, sectors={}, queue={}, seen={}, progress=0, emptyAt=0, lastRock=0, layerSince=0,
    lootTarget=nil, lootSince=0, lastE=0, lastBoulderScan=0, boulder=nil, activeSince=0}

local function mkLabel(parent, txt, pos, size, fs)
    local o=Instance.new("TextLabel")
    o.BackgroundTransparency=1; o.Text=txt; o.Position=pos; o.Size=size
    o.TextColor3=COLORS.Text; o.TextSize=fs or 12; o.Font=Enum.Font.GothamMedium
    o.TextXAlignment=Enum.TextXAlignment.Left; o.Parent=parent
    return o
end
local speedText=mkLabel(settings,"Travel speed: 32 studs/s",UDim2.fromOffset(14,6),UDim2.new(1,-28,0,20),12)
local track=Instance.new("Frame")
track.Position=UDim2.fromOffset(20,40); track.Size=UDim2.new(1,-40,0,8)
track.BackgroundColor3=COLORS.Input; track.BorderSizePixel=0; track.Active=true; track.Parent=settings
addCorner(track,6)
local fill=Instance.new("Frame"); fill.Size=UDim2.fromScale((speed-8)/92,1)
fill.BackgroundColor3=COLORS.Accent; fill.BorderSizePixel=0; fill.Parent=track; addCorner(fill,6)
local knob=Instance.new("TextButton"); knob.Text=""; knob.Size=UDim2.fromOffset(18,18)
knob.AnchorPoint=Vector2.new(.5,.5); knob.Position=UDim2.fromScale(fill.Size.X.Scale,.5)
knob.BackgroundColor3=COLORS.Text; knob.BorderSizePixel=0; knob.Parent=track; addCorner(knob,9)
local sliding=false
local function updateSpeed(screenX)
    local t=math.clamp((screenX-track.AbsolutePosition.X)/math.max(1,track.AbsoluteSize.X),0,1)
    speed=math.floor(8+92*t+.5)
    local p=(speed-8)/92; fill.Size=UDim2.fromScale(p,1);knob.Position=UDim2.fromScale(p,.5)
    speedText.Text="Travel speed: "..speed.." studs/s (8–100)"
end
local function beginSlide(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        sliding=true; updateSpeed(input.Position.X)
    end
end
track.InputBegan:Connect(beginSlide);knob.InputBegan:Connect(beginSlide)
UserInputService.InputChanged:Connect(function(input)
    if sliding and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        updateSpeed(input.Position.X)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then sliding=false end
end)

local reachText=mkLabel(settings,"Target height above mountain entrance (studs):",UDim2.fromOffset(14,65),UDim2.new(1,-28,0,18),11)
local topBox=Instance.new("TextBox")
topBox.Position=UDim2.fromOffset(14,88);topBox.Size=UDim2.fromOffset(134,29)
topBox.BackgroundColor3=COLORS.Input;topBox.TextColor3=COLORS.Text;topBox.TextSize=12
topBox.ClearTextOnFocus=false;topBox.Text="2000";topBox.Parent=settings;addCorner(topBox,7)
local heightHint=mkLabel(settings,"2000 default • set per RNG mountain",UDim2.fromOffset(159,88),UDim2.new(1,-170,0,29),10)
topBox.FocusLost:Connect(function()
    targetTop=math.clamp(tonumber(topBox.Text) or targetTop,100,30000)
    topBox.Text=tostring(math.floor(targetTop))
end)
local placeCard=createCard(page,UDim2.fromOffset(16,288),UDim2.new(1,-32,0,90))
local setBase=createActionButton(placeCard,"Set Base",UDim2.new(0,10,0,10),UDim2.new(.5,-15,0,34))
local setMountain=createActionButton(placeCard,"Set Mountain Entry",UDim2.new(.5,5,0,10),UDim2.new(.5,-15,0,34))
local marks=mkLabel(placeCard,"Base: unset    Mountain: unset",UDim2.fromOffset(12,52),UDim2.new(1,-24,0,26),10)
local readRoot = getRoot
local function updateMarks()
    marks.Text="Base: "..(knownBase and "saved" or "unset").."   Mountain: "..(knownMountain and "saved" or "unset")
end
setBase.MouseButton1Click:Connect(function()
    local r=readRoot();if r then knownBase=r.Position;updateMarks() end
end)
setMountain.MouseButton1Click:Connect(function()
    local r=readRoot();if r then knownMountain=r.Position; updateMarks() end
end)

-- Compact status for the 440px-wide hub. The page becomes scrollable via its child status panel.
local statusBox=createCard(page,UDim2.fromOffset(16,389),UDim2.new(1,-32,0,104))
local status=mkLabel(statusBox,"OFF\nSet Base at spawn, then Mountain Entry at mine.",UDim2.fromOffset(12,8),UDim2.new(1,-24,1,-16),11)
status.TextWrapped=true;status.TextYAlignment=Enum.TextYAlignment.Top;status.Font=Enum.Font.Code
local pageScroll=Instance.new("ScrollingFrame")
pageScroll.Name="ExplorerScroll";pageScroll.Size=UDim2.fromScale(1,1)
pageScroll.BackgroundTransparency=1;pageScroll.ScrollBarThickness=4
pageScroll.CanvasSize=UDim2.fromOffset(0,512);pageScroll.Parent=page
for _,child in ipairs(page:GetChildren()) do
    if child~=pageScroll and child:IsA("GuiObject") then child.Parent=pageScroll end
end

local flightV,flightG
local function cleanup()
    if flightV then flightV:Destroy();flightV=nil end
    if flightG then flightG:Destroy();flightG=nil end
    local h=getHumanoid();if h and not flyEnabled then h.PlatformStand=false end
end
local function flight(root)
    if flightV and flightV.Parent==root then return end
    cleanup()
    flightV=Instance.new("BodyVelocity"); flightV.Name="RaineExplorerVelocity"
    flightV.MaxForce=Vector3.new(1e8,1e8,1e8);flightV.P=6500;flightV.Parent=root
    flightG=Instance.new("BodyGyro");flightG.Name="RaineExplorerGyro"
    flightG.MaxTorque=Vector3.new(1e8,1e8,1e8);flightG.P=20000;flightG.Parent=root
    local h=getHumanoid();if h then h.PlatformStand=true end
end
local function flyTowards(root,goal,dt,stop)
    flight(root)
    local delta=goal-root.Position
    local mag=delta.Magnitude
    local wanted=mag>(stop or 2.5) and delta.Unit*math.min(speed,mag*3) or Vector3.zero
    local a=1-math.exp(-9*math.clamp(dt,0,.1))
    flightV.Velocity=flightV.Velocity:Lerp(wanted,a)
    local flat=Vector3.new(delta.X,0,delta.Z)
    if flat.Magnitude>.1 then flightG.CFrame=CFrame.lookAt(root.Position,root.Position+flat.Unit) end
    return mag
end
local function terrainCast(origin,vec)
    local p=RaycastParams.new();p.FilterType=Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances={player.Character,gui};p.IgnoreWater=true
    return workspace:Raycast(origin,vec,p)
end
local function digSurface(root,vec)
    local hit=terrainCast(root.Position,vec)
    if hit and (hit.Position-root.Position).Magnitude<8 then
        local h=hit.Position+vec.Unit*.35
        digRequest:FireServer(createDigVector(h.X,h.Y,h.Z))
        return true
    end
    return false
end
local function sweepDig(root,now)
    if now-session.lastDig<.10 then return end
    session.lastDig=now
    local facing=session.heading
    if facing.Magnitude<.1 then facing=Vector3.new(1,0,0) end
    facing=Vector3.new(facing.X,0,facing.Z).Unit
    local side=Vector3.new(-facing.Z,0,facing.X)
    -- Rotate through 15 rays over time instead of firing all requests in a single frame.
    local rays={}
    for _,h in ipairs({-3,0,3}) do
        for _,w in ipairs({-5,0,5}) do
            table.insert(rays,facing*7+side*w+Vector3.new(0,h,0))
        end
    end
    table.insert(rays,side*6);table.insert(rays,-side*6)
    table.insert(rays,Vector3.new(0,-6,0));table.insert(rays,Vector3.new(0,6,0))
    local idx=(math.floor(now*10)%#rays)+1
    if digSurface(root,rays[idx]) then session.lastRock=now end
end
local function crystalCandidate(i)
    if i:IsA("ProximityPrompt") then
        local n=(i.ActionText.." "..i.ObjectText):lower()
        return n:find("crystal") or n:find("collect") or n:find("pick up") or n:find("gem")
    end
    if not (i:IsA("Model") or i:IsA("BasePart")) then return false end
    local n=i.Name:lower()
    return n:find("crystal") or n:find("shard") or n:find("gem") or n:find("mineral")
end
local function crystalPart(inst)
    if inst:IsA("ProximityPrompt") then inst=inst.Parent end
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") then return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart",true) end
end
local function nearestCollectible(root)
    local best=nil;local bestDist=13;local seen={}
    local currentTime=os.clock()
    for _,inst in ipairs(workspace:GetDescendants()) do
        if crystalCandidate(inst) then
            local part=crystalPart(inst)
            if part and not seen[part] and not part:IsDescendantOf(player.Character) and (session.seen[part] or 0)<currentTime then
                seen[part]=true
                local dist=(part.Position-root.Position).Magnitude
                -- Only nearby loot; ignore distant/display crystals (including base showcases).
                if dist<bestDist and (not knownBase or (part.Position-knownBase).Magnitude>90) then
                    local cast=terrainCast(root.Position,part.Position-root.Position)
                    if not cast or cast.Instance==part or cast.Instance:IsDescendantOf(part.Parent) then
                        best=part;bestDist=dist
                    end
                end
            end
        end
    end
    return best
end
local function collectE(root,part)
    if not part or not part.Parent then return end
    local prompt=part:FindFirstChildWhichIsA("ProximityPrompt",true)
    if not prompt and part.Parent then prompt=part.Parent:FindFirstChildWhichIsA("ProximityPrompt",true) end
    if prompt and prompt.Enabled and (part.Position-root.Position).Magnitude<=prompt.MaxActivationDistance and type(fireproximityprompt)=="function" then
        pcall(function() fireproximityprompt(prompt) end)
    elseif VirtualInputManager then
        pcall(function()
            VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.E,false,game)
            task.delay(.09,function() pcall(function() VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.E,false,game) end) end)
        end)
    end
end
local function sectorKey(pos)
    return math.floor(pos.X/32)..":"..math.floor(pos.Y/32)..":"..math.floor(pos.Z/32)
end
local function turnHeading()
    session.turnCount+=1
    local angle=math.rad((session.turnCount%2==0) and 100 or -90)
    local d=session.heading
    local out=Vector3.new(d.X*math.cos(angle)-d.Z*math.sin(angle),0,d.X*math.sin(angle)+d.Z*math.cos(angle))
    session.heading=out.Magnitude>.01 and out.Unit or Vector3.new(1,0,0)
end
local function resetSector(now,root)
    session.sweepStart=now
    session.lastPos=root.Position
    session.lastMove=now
    session.lastRock=now
    session.emptyAt=0
end
local function advanceLayer(now,root)
    session.layer+=1
    local maxLayers=math.max(1,math.floor(targetTop/layerHeight))
    if session.layer>maxLayers then session.layer=math.max(1,math.floor(maxLayers*.45)) end
    session.sectors={}
    session.layerSince=now
    session.turnCount+=1
    session.heading=Vector3.new(math.cos(session.turnCount*1.57),0,math.sin(session.turnCount*1.57))
    resetSector(now,root)
end
local function checkBase(root)
    return knownBase and knownMountain
       and (root.Position-knownBase).Magnitude<65
       and (root.Position-knownMountain).Magnitude>75
end
local function boulderNearby(root)
    -- Existing Boulder Tracker keeps updating; target only if revealed and near route.
    if not nearestBoulder or not nearestBoulder.Parent or nearestBoulder:GetAttribute("Revealed")~=true then return nil end
    local pos=getBoulderPosition(nearestBoulder)
    if pos and (pos-root.Position).Magnitude<=55 then return pos end
    return nil
end

local function activate(v)
    if v and flyEnabled then
        enable:Set(false);status.Text="Turn OFF manual Fly first.";return
    end
    session.enabled=v
    if v then
        session.phase="EXPLORE"
        session.layer=0;session.sectors={};session.lootTarget=nil
        session.lastScan=0;session.lastCollect=0;session.lastRock=os.clock()
        session.sweepStart=os.clock();session.layerSince=os.clock();session.lastPos=nil;session.lastMove=os.clock()
        local r=getRoot()
        if r then
            local dir=r.CFrame.LookVector
            session.heading=Vector3.new(dir.X,0,dir.Z).Unit
        end
    else
        session.phase="IDLE";cleanup();status.Text="OFF"
    end
end
enable.OnChanged=activate

RunService.Heartbeat:Connect(function(dt)
    if not session.enabled then return end
    local root=getRoot()
    if not root then cleanup();return end
    if flyEnabled then enable:Set(false);activate(false);return end
    local now=os.clock()
    if checkBase(root) then session.phase="RETURN" end
    if session.phase=="RETURN" then
        local d=flyTowards(root,knownMountain+Vector3.new(0,12,0),dt,10)
        status.Text=string.format("RETURN TO MOUNTAIN\nDistance: %.0f studs\nMining paused at base",d)
        if d<15 then
            session.phase="EXPLORE";session.layer=0;resetSector(now,root)
        end
        return
    end
    -- The base waypoint and mountain waypoint are required for reliable AFK recovery.
    -- If not set, exploration can still run, but auto-return will be unavailable.
    if not knownMountain then
        status.Text="Set Mountain Entry first.\nSet Base for hourly reset recovery."
        if flightV then flightV.Velocity=Vector3.zero end
        return
    end
    if now-session.lastScan>=1.6 then
        session.lastScan=now
        session.lootTarget=nearestCollectible(root)
    end
    local loot=session.lootTarget
    if loot and loot.Parent and (loot.Position-root.Position).Magnitude<=15 then
        if session.phase~="LOOT" then session.lootSince=now end
        session.phase="LOOT"
    elseif session.phase=="LOOT" then
        session.phase="EXPLORE";session.lootTarget=nil
    end
    if session.phase=="LOOT" then
        local distance=flyTowards(root,loot.Position,dt,3.6)
        if distance<=6 and now-session.lastE>=.55 then
            collectE(root,loot);session.lastE=now
        end
        if now-session.lootSince>2.5 or distance>20 then
            session.seen[loot]=now+8
            session.lootTarget=nil;session.phase="EXPLORE";session.lastScan=now+.3
        end
        status.Text=string.format("COLLECT NEARBY CRYSTAL\nDistance: %.1f | %.1fs left\nNext: resume sweep",distance,math.max(0,2.5-(now-session.lootSince)))
        return
    end
    local boulderPos=boulderNearby(root)
    if boulderPos and (boulderPos-root.Position).Magnitude>7 then
        -- Avoid prolonged chasing: boulder approach only for a bounded period.
        if session.phase~="BOULDER" then session.activeSince=now end
        if now-session.activeSince<6 then
            session.phase="BOULDER"
            flyTowards(root,boulderPos,dt,4)
            sweepDig(root,now)
            status.Text="BOULDER NEARBY\nApproach + open surrounding rock"
            return
        end
    end
    session.phase="EXPLORE"
    local key=sectorKey(root.Position)
    if key~=session.lastSector then
        session.lastSector=key
        session.sectors[key]=(session.sectors[key] or 0)+1
        session.lastMove=now;session.lastPos=root.Position
    end
    local direction=session.heading
    if direction.Magnitude<.1 then direction=Vector3.new(1,0,0) end
    local layerGoalY=knownMountain.Y+math.min(targetTop,session.layer*layerHeight)
    local rise=math.clamp(layerGoalY-root.Position.Y,-10,10)
    local goal=root.Position+direction*18+Vector3.new(0,rise,0)
    flyTowards(root,goal,dt,1.5)
    sweepDig(root,now)
    if not session.lastPos then session.lastPos=root.Position;session.lastMove=now end
    if (root.Position-session.lastPos).Magnitude>12 then session.lastMove=now;session.lastPos=root.Position end
    local repeated=(session.sectors[key] or 0)>3
    local stuck=(now-session.lastMove)>5
    local barren=(now-session.lastRock)>9
    if stuck or repeated or barren then
        turnHeading();resetSector(now,root)
    end
    -- Rise a layer periodically or when repeated empty surface; reset heading each layer.
    if now-session.layerSince>48 or (barren and session.turnCount%3==0 and now-session.layerSince>15) then
        advanceLayer(now,root)
    end
    -- Do not force mining when we're far from the mountain region.
    if (root.Position-knownMountain).Magnitude>math.max(200, targetTop*1.5) then
        session.phase="RETURN"
    end
    status.Text=string.format("EXPLORE / SWEEP  | Speed %d\nLayer %d • target Y %.0f • sectors %d\n%s | %s",speed,session.layer,layerGoalY,
       (function() local n=0;for _ in pairs(session.sectors) do n+=1 end;return n end)(),
       barren and "Searching next surface" or "Opening rock",knownBase and "Auto return ON" or "Set Base for recovery")
end)
player.CharacterAdded:Connect(function()
    cleanup()
    if session.enabled then session.phase="RETURN";session.lootTarget=nil end
end)

switchPage("Home")
end)
