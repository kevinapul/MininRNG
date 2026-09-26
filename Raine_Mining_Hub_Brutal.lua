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

		if flyEnabled then

			flyToggle:Set(false)

			stopFly()

		end

	end)


--// =========================================================
--// START PAGE
--// =========================================================



--// =========================================================
--// WALK SPEED RESPAWN RESTORE
--// =========================================================

player.CharacterAdded:
	Connect(function(character)

		local humanoid =
			character:WaitForChild(
				"Humanoid",
				10
			)

		if humanoid then

			humanoid.WalkSpeed =
				WALK_SPEED

		end

	end)
