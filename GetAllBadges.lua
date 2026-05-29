-- get all badges
local HttpService = game:GetService("HttpService")
local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")

local TARGET_USER = "Smartlightyear"
local UNIVERSE_ID = game.GameId -- Automatically detects the live game ID

local player = Players:FindFirstChild(TARGET_USER)

if not player then
	warn("You must be logged in as " .. TARGET_USER .. " in this server to run this script!")
	return
end

-- Using a proxy because live Roblox servers cannot send HTTP requests directly to roblox.com
local proxyUrl = "https://badges.roproxy.com/v1/universes/" .. UNIVERSE_ID .. "/badges?limit=100&sortOrder=Asc"

local success, response = pcall(function()
	return HttpService:GetAsync(proxyUrl)
end)

if success then
	local data = HttpService:JSONDecode(response)
	local badges = data.data
	
	if not badges or #badges == 0 then
		print("No badges found for this game or proxy failed to fetch data.")
		return
	end
	
	print("Successfully connected! Found " .. #badges .. " badges. Processing...")
	
	for _, badgeInfo in ipairs(badges) do
		local badgeId = badgeInfo.id
		local badgeName = badgeInfo.name
		
		-- Check ownership and award
		local hasBadgeSuccess, hasBadge = pcall(function()
			return BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
		end)
		
		if hasBadgeSuccess and not hasBadge then
			local awarded, err = pcall(function()
				BadgeService:AwardBadge(player.UserId, badgeId)
			end)
			if awarded then
				print("Awarded: " .. badgeName)
			else
				warn("Skipped " .. badgeName .. " (Error: " .. tostring(err) .. ")")
			end
		else
			print("Already owned: " .. badgeName)
		end
		
		-- Small delay to keep the server from stuttering or rate-limiting
		task.wait(0.1)
	end
	print("Finished processing all game badges!")
else
	warn("HTTP Fetch Failed. Make sure 'Allow HTTP Requests' is enabled in this game's settings.")
end
