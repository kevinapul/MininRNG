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
local BRUTAL_INTERVAL = 0.03
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
	"Movement",
	"➜",
	4
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


local brutalFarmToggle =
	createToggle(

		miningPage,

		"Brutal Farm",

		"Hancurkan cepat di sekitar: depan, belakang, kiri, kanan, atas, bawah",

		UDim2.fromOffset(
			16,
			160
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
			235
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

dropdown.ZIndex = 10

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
		-14,
		0,
		58
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

optionsFrame.ZIndex = 20

optionsFrame.Parent =
	directionCard

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

	option.ZIndex = 21

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

		UDim2.fromOffset(
			16,
			320
		),

		UDim2.new(
			1,
			-32,
			0,
			58
		)

	)


local miningInfoText =
	Instance.new("TextLabel")

miningInfoText.Position =
	UDim2.fromOffset(
		14,
		10
	)

miningInfoText.Size =
	UDim2.new(
		1,
		-28,
		1,
		-20
	)

miningInfoText.BackgroundTransparency = 1

miningInfoText.Text =
	"Atas    → 7 studs maju + 2 atas\n"
	.. "Tengah → 7 studs maju\n"
	.. "Bawah   → 7 studs maju + 2 bawah"

miningInfoText.TextColor3 =
	COLORS.SubText

miningInfoText.TextSize = 11

miningInfoText.Font =
	Enum.Font.Code

miningInfoText.TextXAlignment =
	Enum.TextXAlignment.Left

miningInfoText.TextYAlignment =
	Enum.TextYAlignment.Top

miningInfoText.Parent =
	miningInfo


--// =========================================================
--// MOVEMENT PAGE
--// =========================================================

createHeader(
	movementPage,
	"Movement",
	"Movement utility untuk navigasi area mining."
)


local flyToggle =
	createToggle(

		movementPage,

		"Fly",

		"WASD • Space naik • Left Ctrl turun",

		UDim2.fromOffset(
			16,
			85
		)

	)


local flyCard =
	createCard(

		movementPage,

		UDim2.fromOffset(
			16,
			165
		),

		UDim2.new(
			1,
			-32,
			0,
			75
		)

	)


local flyInfo =
	Instance.new("TextLabel")

flyInfo.Position =
	UDim2.fromOffset(
		15,
		10
	)

flyInfo.Size =
	UDim2.new(
		1,
		-30,
		1,
		-20
	)

flyInfo.BackgroundTransparency = 1

flyInfo.Text =
	"Fly Speed\n"
	.. tostring(FLY_SPEED)
	.. " studs/sec"

flyInfo.TextColor3 =
	COLORS.SubText

flyInfo.TextSize = 12

flyInfo.Font =
	Enum.Font.GothamMedium

flyInfo.TextXAlignment =
	Enum.TextXAlignment.Left

flyInfo.TextYAlignment =
	Enum.TextYAlignment.Top

flyInfo.Parent =
	flyCard


--// =========================================================
--// WALK SPEED
--// =========================================================

local walkCard =
	createCard(

		movementPage,

		UDim2.fromOffset(
			16,
			255
		),

		UDim2.new(
			1,
			-32,
			0,
			92
		)

	)


local walkLabel = Instance.new("TextLabel")
walkLabel.Position = UDim2.fromOffset(15, 10)
walkLabel.Size = UDim2.new(0.5, 0, 0, 22)
walkLabel.BackgroundTransparency = 1
walkLabel.Text = "Walk Speed"
walkLabel.TextColor3 = COLORS.Text
walkLabel.TextSize = 14
walkLabel.Font = Enum.Font.GothamSemibold
walkLabel.TextXAlignment = Enum.TextXAlignment.Left
walkLabel.Parent = walkCard


local speedBox = Instance.new("TextBox")
speedBox.AnchorPoint = Vector2.new(1, 0)
speedBox.Position = UDim2.new(1, -14, 0, 10)
speedBox.Size = UDim2.fromOffset(110, 34)
speedBox.BackgroundColor3 = COLORS.Input
speedBox.BorderSizePixel = 0
speedBox.Text = tostring(WALK_SPEED)
speedBox.PlaceholderText = "16"
speedBox.ClearTextOnFocus = false
speedBox.TextColor3 = COLORS.Text
speedBox.TextSize = 13
speedBox.Font = Enum.Font.GothamMedium
speedBox.Parent = walkCard
addCorner(speedBox, 8)


local walkStatus = Instance.new("TextLabel")
walkStatus.Position = UDim2.fromOffset(15, 42)
walkStatus.Size = UDim2.new(0.55, 0, 0, 28)
walkStatus.BackgroundTransparency = 1
walkStatus.Text = "Current: " .. tostring(WALK_SPEED)
walkStatus.TextColor3 = COLORS.SubText
walkStatus.TextSize = 11
walkStatus.Font = Enum.Font.Gotham
walkStatus.TextXAlignment = Enum.TextXAlignment.Left
walkStatus.Parent = walkCard


local applySpeedButton =
	createActionButton(

		walkCard,

		"Apply",

		UDim2.new(
			1,
			-124,
			0,
			50
		),

		UDim2.fromOffset(
			110,
			30
		)

	)


local function applyWalkSpeed()
	local value = tonumber(speedBox.Text)

	if not value then
		speedBox.Text = tostring(WALK_SPEED)
		return
	end

	value = math.clamp(value, 1, 300)
	WALK_SPEED = value
	speedBox.Text = tostring(value)

	local humanoid = getHumanoid()

	if humanoid then
		humanoid.WalkSpeed = value
	end

	walkStatus.Text = "Current: " .. tostring(value)
end


applySpeedButton.MouseButton1Click:
	Connect(function()
		applyWalkSpeed()
	end)


speedBox.FocusLost:
	Connect(function(enterPressed)
		if enterPressed then
			applyWalkSpeed()
		end
	end)


--// =========================================================
--// BOULDER PAGE
--// =========================================================

createHeader(
	boulderPage,
	"Boulder Teleport",
	"Auto scan Workspace.Boulders setiap 3 detik."
)


local boulderStatus =
	Instance.new("TextLabel")

boulderStatus.Position =
	UDim2.fromOffset(
		24,
		76
	)

boulderStatus.Size =
	UDim2.new(
		1,
		-48,
		0,
		25
	)

boulderStatus.BackgroundTransparency = 1

boulderStatus.Text =
	"Scanning..."

boulderStatus.TextColor3 =
	COLORS.SubText

boulderStatus.TextSize = 11

boulderStatus.Font =
	Enum.Font.GothamMedium

boulderStatus.TextXAlignment =
	Enum.TextXAlignment.Left

boulderStatus.Parent =
	boulderPage


local boulderScroll =
	Instance.new("ScrollingFrame")

boulderScroll.Position =
	UDim2.fromOffset(
		24,
		105
	)

boulderScroll.Size =
	UDim2.new(
		1,
		-48,
		1,
		-125
	)

boulderScroll.BackgroundColor3 =
	COLORS.Card

boulderScroll.BorderSizePixel = 0

boulderScroll.ScrollBarThickness = 3

boulderScroll.ScrollBarImageColor3 =
	COLORS.Accent

boulderScroll.CanvasSize =
	UDim2.new(
		0,
		0,
		0,
		0
	)

boulderScroll.AutomaticCanvasSize =
	Enum.AutomaticSize.Y

boulderScroll.Parent =
	boulderPage

addCorner(
	boulderScroll,
	10
)

addStroke(
	boulderScroll,
	0.55
)


local boulderLayout =
	Instance.new("UIListLayout")

boulderLayout.Padding =
	UDim.new(
		0,
		6
	)

boulderLayout.Parent =
	boulderScroll


local boulderPadding =
	Instance.new("UIPadding")

boulderPadding.PaddingTop =
	UDim.new(
		0,
		8
	)

boulderPadding.PaddingBottom =
	UDim.new(
		0,
		8
	)

boulderPadding.PaddingLeft =
	UDim.new(
		0,
		8
	)

boulderPadding.PaddingRight =
	UDim.new(
		0,
		8
	)

boulderPadding.Parent =
	boulderScroll


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
						* FLY_SPEED

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

		autoMiningEnabled =
			enabled

	end


task.spawn(function()

	while true do

		if autoMiningEnabled then

			digInFront()

		end


		task.wait(
			MINING_INTERVAL
		)

	end

end)


--// =========================================================
--// BRUTAL FARM
--// =========================================================

local function fireDigAt(position)
	local digPosition =
		createDigVector(
			position.X,
			position.Y,
			position.Z
		)

	digRequest:FireServer(
		digPosition
	)
end


local function brutalFarmBurst()

	local root = getRoot()

	if not root then
		return
	end

	local cf = root.CFrame

	local forward = Vector3.new(
		cf.LookVector.X,
		0,
		cf.LookVector.Z
	)

	if forward.Magnitude < 0.01 then
		forward = Vector3.new(0, 0, -1)
	else
		forward = forward.Unit
	end

	local right = Vector3.new(
		cf.RightVector.X,
		0,
		cf.RightVector.Z
	)

	if right.Magnitude < 0.01 then
		right = Vector3.new(1, 0, 0)
	else
		right = right.Unit
	end

	local p = root.Position
	local r = BRUTAL_RADIUS
	local y = BRUTAL_VERTICAL

	-- Tidak ada wait/cooldown di antara FireServer berikut.
	local targets = {
		p + forward * r,
		p - forward * r,
		p + right * r,
		p - right * r,

		p + Vector3.new(0, y, 0),
		p - Vector3.new(0, y, 0),

		p + (forward + right).Unit * r,
		p + (forward - right).Unit * r,
		p + (-forward + right).Unit * r,
		p + (-forward - right).Unit * r,

		p + forward * r + Vector3.new(0, y * 0.65, 0),
		p + forward * r - Vector3.new(0, y * 0.65, 0),

		p - forward * r + Vector3.new(0, y * 0.65, 0),
		p - forward * r - Vector3.new(0, y * 0.65, 0),
	}

	for _, target in ipairs(targets) do
		fireDigAt(target)
	end

end


brutalFarmToggle.OnChanged =
	function(enabled)

		brutalFarmEnabled = enabled

	end


task.spawn(function()

	while true do

		if brutalFarmEnabled then
			brutalFarmBurst()
		end

		task.wait(BRUTAL_INTERVAL)

	end

end)


--// =========================================================
--// BOULDER FUNCTIONS
--// =========================================================

local function getBoulderTop(
	boulder
)

	if not boulder then
		return nil
	end


	if boulder:IsA(
		"BasePart"
	) then

		return Vector3.new(

			boulder.Position.X,

			boulder.Position.Y
				+ (
					boulder.Size.Y
					/ 2
				)
				+ BOULDER_HEIGHT_OFFSET,

			boulder.Position.Z

		)

	end


	if boulder:IsA(
		"Model"
	) then

		local success,
			cf,
			size =
			pcall(function()

				local boundingCF,
					boundingSize =
					boulder:GetBoundingBox()

				return
					boundingCF,
					boundingSize

			end)


		if success
			and cf
			and size then

			return Vector3.new(

				cf.Position.X,

				cf.Position.Y
					+ (
						size.Y
						/ 2
					)
					+ BOULDER_HEIGHT_OFFSET,

				cf.Position.Z

			)

		end

	end


	local part =
		boulder:
			FindFirstChildWhichIsA(
				"BasePart",
				true
			)


	if part then

		return Vector3.new(

			part.Position.X,

			part.Position.Y
				+ (
					part.Size.Y
					/ 2
				)
				+ BOULDER_HEIGHT_OFFSET,

			part.Position.Z

		)

	end


	return nil

end


local function teleportToBoulder(
	boulder
)

	local root =
		getRoot()


	if not root then
		return
	end


	local target =
		getBoulderTop(
			boulder
		)


	if not target then
		return
	end


	local look =
		root.CFrame.LookVector


	local flatLook =
		Vector3.new(
			look.X,
			0,
			look.Z
		)


	if flatLook.Magnitude
		< 0.01 then

		flatLook =
			Vector3.new(
				0,
				0,
				-1
			)

	end


	root.CFrame =
		CFrame.lookAt(

			target,

			target
				+ flatLook.Unit

		)


	root.AssemblyLinearVelocity =
		Vector3.zero

end


--// =========================================================
--// BOULDER BUTTON
--// =========================================================

local function createBoulderButton(
	boulder
)

	local button =
		Instance.new("TextButton")

	button.Size =
		UDim2.new(
			1,
			0,
			0,
			42
		)

	button.BackgroundColor3 =
		COLORS.Input

	button.BorderSizePixel = 0

	button.Text =
		"◆  "
		.. boulder.Name

	button.TextColor3 =
		COLORS.Text

	button.TextSize = 12

	button.Font =
		Enum.Font.GothamMedium

	button.TextXAlignment =
		Enum.TextXAlignment.Left

	button.AutoButtonColor = false

	button.Parent =
		boulderScroll

	addCorner(
		button,
		7
	)


	local buttonPadding =
		Instance.new(
			"UIPadding"
		)

	buttonPadding.PaddingLeft =
		UDim.new(
			0,
			13
		)

	buttonPadding.Parent =
		button


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


	button.MouseButton1Click:
		Connect(function()

			if boulder
				and boulder.Parent then

				teleportToBoulder(
					boulder
				)

			end

		end)

end


--// =========================================================
--// BOULDER REFRESH
--// =========================================================

local lastBoulderSignature =
	""


local function refreshBoulders()

	local folder =
		workspace:
			FindFirstChild(
				"Boulders"
			)


	if not folder then

		boulderStatus.Text =
			"Folder Boulders tidak ditemukan"

		return

	end


	local boulders =
		folder:GetChildren()


	table.sort(
		boulders,

		function(a, b)

			return
				a.Name:lower()
				<
				b.Name:lower()

		end
	)


	local signatureParts = {}


	for _, boulder
		in ipairs(boulders) do

		table.insert(
			signatureParts,

			boulder.Name
				.. tostring(boulder)

		)

	end


	local signature =
		table.concat(
			signatureParts,
			"|"
		)


	if signature
		== lastBoulderSignature then

		boulderStatus.Text =
			tostring(
				#boulders
			)
			.. " boulders ditemukan"

		return

	end


	lastBoulderSignature =
		signature


	for _, child
		in ipairs(
			boulderScroll:GetChildren()
		) do

		if child:IsA(
			"TextButton"
		) then

			child:Destroy()

		end

	end


	local valid = 0


	for _, boulder
		in ipairs(boulders) do

		if getBoulderTop(
			boulder
		) then

			valid += 1

			createBoulderButton(
				boulder
			)

		end

	end


	boulderStatus.Text =
		tostring(valid)
		.. " boulders ditemukan"

end


task.spawn(function()

	while true do

		refreshBoulders()

		task.wait(
			BOULDER_REFRESH_TIME
		)

	end

end)


--// =========================================================
--// ANTI AFK - HYBRID
--// =========================================================

local ANTI_AFK_INTERVAL = 45

local function antiAfkPulse()

	local camera = workspace.CurrentCamera

	-- VirtualUser pulse
	pcall(function()

		VirtualUser:CaptureController()

		VirtualUser:Button2Down(
			Vector2.new(0, 0),
			camera and camera.CFrame or CFrame.new()
		)

		task.wait(0.1)

		VirtualUser:Button2Up(
			Vector2.new(0, 0),
			camera and camera.CFrame or CFrame.new()
		)

	end)


	-- Humanoid activity pulse
	-- Sangat kecil supaya tidak mengganggu posisi farming
	local humanoid = getHumanoid()

	if humanoid then

		pcall(function()

			humanoid:Move(
				Vector3.new(0.01, 0, 0),
				false
			)

			task.wait(0.1)

			humanoid:Move(
				Vector3.zero,
				false
			)

		end)

	end

end


-- Backup kalau Roblox mendeteksi Idled
player.Idled:Connect(function()

	antiAfkPulse()

end)


-- Jangan tunggu Idled:
-- pulse rutin setiap 45 detik
task.spawn(function()

	while true do

		task.wait(ANTI_AFK_INTERVAL)

		antiAfkPulse()

	end

end)

--// =========================================================
--// RESPAWN
--// =========================================================

player.CharacterAdded:
	Connect(function()

		task.wait(0.5)

		local humanoid = getHumanoid()
		if humanoid then
			humanoid.WalkSpeed = WALK_SPEED
		end

		if flyEnabled then

			flyToggle:Set(false)

			stopFly()

		end

	end)


--// =========================================================
--// START PAGE
--// =========================================================

switchPage("Home")