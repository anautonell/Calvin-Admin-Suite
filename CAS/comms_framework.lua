local plrs = game.Players
local dService = game:GetService("DataStoreService")
local mService = game:GetService("MarketplaceService")
local tService = game:GetService("TeleportService")
local insService = game:GetService("InsertService")

local bansDs = dService:GetOrderedDataStore("CalvinAdminSuiteBans6")

local messageEvent = game.ReplicatedStorage:WaitForChild("Networking"):WaitForChild("MessageEvent")
local hintEvent = game.ReplicatedStorage:WaitForChild("Networking"):WaitForChild("HintEvent")
local listEvent = game.ReplicatedStorage:WaitForChild("Networking"):WaitForChild("ListEvent")
local banEvent = game.ReplicatedStorage:WaitForChild("Networking"):WaitForChild("BanEvent")
local cameraEvent = game.ReplicatedStorage:WaitForChild("Networking"):WaitForChild("CameraEvent")
local alertEvent = game.ReplicatedStorage:WaitForChild("Networking"):WaitForChild("AlertEvent")
local errEvent = game.ReplicatedStorage:WaitForChild("Networking"):WaitForChild("ErrorEvent")
local clientEvent = game.ReplicatedStorage:WaitForChild("Networking"):WaitForChild("ClientEvent")
local chatLogsFunc = game.ReplicatedStorage:WaitForChild("Networking"):WaitForChild("ChatLogsFunc")
local cmdsEvent = script.Networking:WaitForChild("CmdsEvent")
local event = script.Networking:WaitForChild("Event")

local api = require(script.Modules:WaitForChild("api"))
local cmdsMod = require(script.Modules:WaitForChild("commands"))
local loadstr = require(script.Modules:WaitForChild("Loadstring"))

local sLock = script.Values:WaitForChild("ServerLock")

local adminAPI = {}

cmdsEvent.Event:Connect(function(action, funcName, func)
	if action == "AddCmd" then
		adminAPI.commands[funcName] = func
	end
end)

local function getTeams(str)
	local teams = {}
	for team in str:gmatch("[^,]+") do
		for _, v in next, game.Teams:GetChildren() do
			if v.Name:lower():match("^"..team) then
				table.insert(teams, v)
			end
		end
	end
	return teams
end

local function getTools(str)
    local tools = {}
    for tool in str:gmatch("[^,]+") do
        for _,v in next, game.ServerStorage:GetChildren() do
            if v.Name:lower():match("^"..tool) then
                table.insert(tools,v)
            end
        end
    end
    return tools
end

local function create(cType, name)
	if cType == "Team" then
		local team = Instance.new("Team")
		team.Name = name
		team.AutoAssignable = false
		team.Parent = game.Teams
	end
end

adminAPI.commands = {
	
	cmds = function(sender) 
		local gui = script.UI:FindFirstChild("ListUI"):Clone()
		if gui then
			gui.Parent = sender:WaitForChild("PlayerGui")
			listEvent:FireClient(sender, "CreateCommands", {Cmds = cmdsMod})
		end
	end;
	
	tools = function(sender)
		local gui = script.UI:FindFirstChild("ListUI"):Clone()
		local tools = {}
		for i,v in next, game.ServerStorage:GetChildren() do
			if v:IsA("Tool") then
				table.insert(tools, v.Name)
			end
		end
		if gui then
			gui.Parent = sender:WaitForChild("PlayerGui")
			listEvent:FireClient(sender, "CreateTools", {Tools = tools})
		end
	end;
	
	bans = function(sender)
		local plr = plrs:FindFirstChild(sender.Name)
		local gui = script.UI:FindFirstChild("ListUI"):Clone()
		gui.Parent = plr:WaitForChild("PlayerGui")
		spawn(function()
			while wait() do
				local success, message = pcall(function()
					local pages = bansDs:GetSortedAsync(false, 30)
					local data = pages:GetCurrentPage()
					print(#data)
					listEvent:FireClient(sender, "ShowBans", {Bans = data})
				end)
				if not success then
					error(message)
					break
				end
				break
			end
		end)
	end;
	
	logs = function(sender)
		local chatLogs = chatLogsFunc:Invoke()
		local gui = script.UI:FindFirstChild("ListUI"):Clone()
		if gui then
			gui.Parent = sender:WaitForChild("PlayerGui")
			listEvent:FireClient(sender, "ShowLogs", {Logs = chatLogs})
		end
	end;
	
	admins = function(sender)
		local adminsTbl = api:getAdmins()
		local gui = script.UI:FindFirstChild("ListUI"):Clone()
		if gui then
			for id, perm in next, adminsTbl do
				gui.Parent = sender:WaitForChild("PlayerGui")
				listEvent:FireClient(sender, "ShowAdmins", {AdminID = id, AdminRole = perm})
			end
		end
	end;
	
	ban = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr and plr ~= sender then
				local gui = script:WaitForChild("UI"):FindFirstChild("BanUI"):Clone()
				if gui then
					gui.Parent = sender:WaitForChild("PlayerGui")
					banEvent:FireClient(sender, "SetBan", {BanPlr = plr.Name})
				end
			end
		end
	end;
	
	banid = function(sender, id)
		if not id or sender.UserId == id then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		event:Fire("BanPlayerFromUserID", {Target = tonumber(id)})
	end;
	
	unban = function(sender, target)
		local key = game.Players:GetUserIdFromNameAsync(target)
		local ban = bansDs:RemoveAsync(key)
		print("unbanned", key, ban)
	end;
	
	kick = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr then
				if plr ~= sender then
					plr:Kick("Oops, You have been kicked from game server using RoAdmin Admin Suite")
				end
			end
		end
	end;
	
	view = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr then
				cameraEvent:FireClient(sender, "UpdateCamera", {Target = plr})
			end
		end
	end;
	
	unview = function(sender)
		cameraEvent:FireClient(sender, "ResetCamera", {Sender = sender})
	end;

	--[[sis = function(sender, target)
		if not target then return end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				local shirt, pants = 1044496047, 1044496383
				plr.Character.Shirt.ShirtTemplate = "http://www.roblox.com/asset/?id="..shirt
				plr.Character.Pants.PantsTemplate = "http://www.roblox.com/asset/?id="..pants
				for i,v in next, plr.Character:GetChildren() do
					if v:IsA("Accessory") then
						v:Destroy()
					end
				end
				for i,v in next, script.Assets:GetChildren() do
					if v:IsA("Accessory") then
						v:Clone().Parent = plr.Character
					end
				end
			end
		end
	end;--]]
	
	respawn = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr then
				plr:LoadCharacter()
			end
		end
	end;

	refresh = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				local pos = plr.Character:GetPrimaryPartCFrame()
				plr:LoadCharacter()
				plr.Character:SetPrimaryPartCFrame(pos)
			end
		end
	end;

	team = function(sender, target, chosenTeam)
		if not target or not chosenTeam then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr then
				for _, team in next, getTeams(chosenTeam) do
					if team then
						plr.Team = team
						plr.TeamColor = team.TeamColor
					end
				end
			end
		end
	end;
	
	give = function(sender, target, obj)
		if not target or not obj then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr then
				for _, tool in next, getTools(obj) do
					if tool then
						tool:Clone().Parent = plr.Backpack
					end
				end
			end
		end
	end;

	removetools = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _,plr in next, api:getPlayers(sender, target) do
			if plr then
				plr.Backpack:ClearAllChildren()
				for i,v in pairs(plr.Character:GetChildren()) do
					if v:IsA("Tool") then
						v:Destroy()
					end
				end
			end
		end
	end;

	tp = function(sender, target, tpTo)
		tpTo = api:getPlayers(sender, tpTo)[1]
		if not tpTo or not tpTo.Character then return end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				plr.Character:MoveTo(tpTo.Character:GetPrimaryPartCFrame().p)
			end
		end
	end;
	
	to = function(sender, target, ...)
		if not target or not ... then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		local args = {...}
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				local vec = Vector3.new(args)
				plr.Character:MoveTo(vec)
			end
		end
	end;
	
	h = function(sender, ...)
		if not ... then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		local msg = table.concat({...}, " ")
		local newMsg = game:GetService("Chat"):FilterStringForBroadcast(msg, sender)
		for _, plr in next, plrs:GetPlayers() do 
			if plr:WaitForChild("PlayerGui") then
				local hintGui = script.UI:FindFirstChild("HintUI"):Clone()
				hintGui.Parent = plr:WaitForChild("PlayerGui")
			end
		end
		hintEvent:FireAllClients("CreateHint", sender.Name..": "..newMsg)
	end;
	
	hcountdown = function(sender, num)
		if not num then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, plrs:GetPlayers() do 
			if plr:WaitForChild("PlayerGui") then
				local hintGui = script.UI:FindFirstChild("HintUI"):Clone()
				hintGui.Parent = plr:WaitForChild("PlayerGui")
			end
		end
		hintEvent:FireAllClients("CreateCountdown", nil, num)
	end;
	
	m = function(sender, ...)
		if not ... then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		local msg = table.concat({...}, " ")
		local newMsg = game:GetService("Chat"):FilterStringForBroadcast(msg, sender)
		for _, plr in next, plrs:GetPlayers() do 
			if plr:WaitForChild("PlayerGui") then
				local hintGui = script.UI:FindFirstChild("MessageUI"):Clone()
				hintGui.Parent = plr:WaitForChild("PlayerGui")
			end
		end
		messageEvent:FireAllClients("CreateMessage", {Sender = sender, Msg = newMsg})
	end;

	alert = function(sender, target, ...)
		if not target or not ... then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		local msg = table.concat({...}, " ")
		local newMsg = game:GetService("Chat"):FilterStringForBroadcast(msg, sender)
		for _, plr in next, api:getPlayers(sender, target) do
			if plr then
				local pGui = plr:WaitForChild("PlayerGui")
				local gui = script.UI:FindFirstChild("AlertUI"):Clone()
				if gui then
					gui.Parent = pGui
					alertEvent:FireClient(plr, "AlertPlayer", newMsg)
				end
			end
		end
	end;
	
	admin = function(sender, target, role)
		if not target or not role then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _,plr in next, api:getPlayers(sender, target) do
			if plr ~= sender then
				api:addAdmin(plr, role)
				clientEvent:FireClient(plr, "ShowAdminMsg", {Role = role})
			end
		end
	end;
	
	unadmin = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr ~= sender then
				api:removeAdmin(plr)
			end
		end
	end;
	
	god = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				plr.Character.Humanoid.MaxHealth = math.huge
				plr.Character.Humanoid.Health = math.huge
			end
		end
	end;
	
	ungod = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				plr.Character.Humanoid.MaxHealth = 100
				plr.Character.Humanoid.Health = 100
			end
		end
	end;
	
	heal = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _,plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				plr.Character.Humanoid.Health = 100
			end
		end
	end;

	kill = function(sender, target) 
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _,plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				plr.Character:BreakJoints()
			end
		end
	end;
	
	fly = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do 
			if plr.Character then
				local scriptDep = script:WaitForChild("ScriptDependencies")
				local flyScript = scriptDep:FindFirstChild("Fly"):Clone()
				if flyScript then
					local boolVal = Instance.new("BoolValue")
					boolVal.Name = "FLIGHT_LIVE"
					boolVal.Parent = plr.Character.HumanoidRootPart
					flyScript.Disabled = false
					flyScript.Parent = plr.Character.HumanoidRootPart
				end
			end
		end
	end;
	
	unfly = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				local flyScript = plr.Character.HumanoidRootPart:FindFirstChild("Fly")
				local flightVal = plr.Character.HumanoidRootPart:FindFirstChild("FLIGHT_LIVE")
				if flyScript and flightVal then
					flyScript:Destroy()
					flightVal:Destroy()
				end
			end
		end
	end;
	
	flynoclip = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do 
			if plr.Character then
				local scriptDep = script:WaitForChild("ScriptDependencies")
				local flyScript = scriptDep:FindFirstChild("FlyClipper"):Clone()
				if flyScript then
					flyScript.Disabled = false
					flyScript.Parent = plr.Character.Humanoid
				end
			end
		end
	end;
	
	noclip = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do 
			if plr.Character then
				local scriptDep = script:WaitForChild("ScriptDependencies")
				local clipScript = scriptDep:FindFirstChild("Clipper"):Clone()
				if clipScript then
					clipScript.Disabled = false
					clipScript.Parent = plr.Character.Humanoid
				end
			end
		end
	end;
	
	clip = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				local flyScript = plr.Character.Humanoid:FindFirstChild("FlyClipper")
				local clipScript = plr.Character.Humanoid:FindFirstChild("Clipper")
				if flyScript then
					local enabledVal = flyScript:FindFirstChild("Enabled")
					if enabledVal.Value then
						enabledVal.Value = false
						wait(0.5)
						flyScript:Destroy()
					end
				elseif clipScript then
					clipScript:Destroy()
				end
			end
		end
	end;
	
	ff = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				local ff = Instance.new("ForceField")
				ff.Visible = true
				ff.Parent = plr.Character
			end
		end
	end;
	
	unff = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				if plr.Character:FindFirstChildOfClass("ForceField") then
					plr.Character:FindFirstChildOfClass("ForceField"):Destroy()
				end
			end
		end
	end;

	speed = function(sender, target, speed)
		if not target or not speed then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				plr.Character.Humanoid.WalkSpeed = tonumber(speed)
			end
		end
	end;
	
	freeze = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				plr.Character.Humanoid.WalkSpeed = 0
				plr.Character.Humanoid.JumpPower = 0
			end
		end
	end;
	
	thaw = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				plr.Character.Humanoid.WalkSpeed = 16
				plr.Character.Humanoid.JumpPower = 50
			end
		end
	end;

	place = function(sender, target, id)
		if not target or not id then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr then
				tService:Teleport(tonumber(id), plr)
			end
		end
	end;

	btools = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr then
				local btools = script.Assets:FindFirstChild("Building Tools"):Clone()
				btools.Parent = plr.Backpack
			end
		end
	end;

	sword = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do 
			if plr and plr.Backpack then
				local sword = script.Assets:FindFirstChild("LinkedSword"):Clone()
				sword.Parent = plr.Backpack
			end
		end
	end;
	
	sit = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				plr.Character.Humanoid.Sit = true
			end
		end
	end;
	
	jump = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				plr.Character.Humanoid.Jump = true
			end
		end
	end;
	
	jumppower = function(sender, target, number)
		if not target or not number then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				plr.Character.Humanoid.JumpPower = tonumber(number)
			end
		end
	end;

	ins = function(sender, id) 
		if not id then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		local model
		local success, err = pcall(function()
			model = insService:LoadAsset(id)
		end)
		if success then
			local char = workspace:FindFirstChild(sender.Name)
			local model = model:FindFirstChildOfClass("Model")
			if model.PrimaryPart and char then
				print(true)
				model:SetPrimaryPartCFrame(char.HumanoidRootPart.CFrame * CFrame.new(10, 0, 10))
				model.Parent = workspace.Objects
			else
				return
				--[[print(false)
				model:MoveTo(char.Head.Position + Vector3.new(0, 0, 0))
				model.Parent = workspace.Objects--]]
			end
		else
			warn("Unable to insert model because "..err)
		end
	end;
	
	track = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				clientEvent:FireClient(sender, "TargetPlayer", {Target = plr})
			end
		end
	end;
	
	untrack = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				clientEvent:FireClient(plr, "UntargetPlayer", {Target = plr})
			end
		end
	end;
	
	shutdown = function(sender)
		for _, plr in next, game.Players:GetPlayers() do
			local pGui = plr:WaitForChild("PlayerGui")
			local gui = script.UI:FindFirstChild("MessageUI"):Clone()
			if gui then
				gui.Parent = pGui
				messageEvent:FireAllClients("ShutdownMessage", {Sender = sender})
			end
			wait(3)
			plr:Kick("The game has shutdown")
		end
	end;
	
	rejoin = function(sender)
		local succeeded, errorMsg, placeId, instanceId = tService:GetPlayerPlaceInstanceAsync(sender.UserId)
		if succeeded then
			tService:TeleportToPlaceInstance(placeId, instanceId, sender)
		else
			warn("Could not join placeID - "..placeId.." because of: "..errorMsg)
		end
	end;
	
	join = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr then
				local succeeded, errorMsg, placeId, instanceId = tService:GetPlayerPlaceInstanceAsync(plr.UserId)
				if succeeded then
					tService:TeleportToPlaceInstance(placeId, instanceId, plr)
				else
					warn("Could not follow "..plr.Name..". "..errorMsg)
				end
			else 
				warn(plr.Name.." is not a valid Roblox user")
			end
		end
	end;
	
	hat = function(sender, target, id)
		if not target or not id then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				local hatObj
				local success, err = pcall(function()
					hatObj = insService:LoadAsset(id)
				end)
				if success then
					if hatObj:IsA("Model") then
						hatObj = hatObj:FindFirstChildOfClass("Accessory")
						hatObj.Parent = plr.Character
					end
				end
			end
		end
	end;
	
	gear = function(sender, target, id)
		if not target or not id then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				local toolObj
				local success, err = pcall(function()
					toolObj = insService:LoadAsset(id)
				end)
				if success then
					if toolObj:IsA("Model") then
						toolObj = toolObj:FindFirstChildOfClass("Tool")
						toolObj.Parent = plr.Character
					end
				end
			end
		end
	end;
	
	invisible = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				for _, obj in next, plr.Character:GetChildren() do
					if obj:IsA("BasePart") then
						obj.Transparency = 1
						if obj:FindFirstChild("face") then
							obj.face.Transparency = 1 
						end
					elseif obj:IsA("Accoutrement") and obj:findFirstChild("Handle") then 
						obj.Handle.Transparency = 1 
					end
				end
			end
		end
	end;
	
	visible = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				for _, obj in next, plr.Character:GetChildren() do
					if obj:IsA("BasePart") then
						obj.Transparency = 0
						if obj:FindFirstChild("face") then
							obj.face.Transparency = 0 
						end
					elseif obj:IsA("Accoutrement") and obj:findFirstChild("Handle") then 
						obj.Handle.Transparency = 0 
					end
				end
			end
		end
	end;
	
	regrav = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				local gravVal = plr.Character.HumanoidRootPart:FindFirstChild("Gravity")
				if gravVal then
					gravVal:Destroy()
				end
			end
		end
	end;
	
	setgrav = function(sender, target, grav)
		if not target or not grav then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				local gravVal = plr.Character.HumanoidRootPart:FindFirstChild("Gravity")
				if gravVal then
					gravVal:Destroy()
				end
				local bodyForce = Instance.new("BodyForce")
				bodyForce.Name = "Gravity"
				bodyForce.Force = Vector3.new(0,0,0)
				bodyForce.Parent = plr.Character.HumanoidRootPart
				for _, obj in next, plr.Character:GetChildren() do 
					if obj:IsA("BasePart") then 
						bodyForce.Force = bodyForce.Force - Vector3.new(0,obj:GetMass()*tonumber(grav),0) 
					elseif obj:IsA("Accoutrement") then 
						bodyForce.Force = bodyForce.Force - Vector3.new(0,obj.Handle:GetMass()*tonumber(grav),0) 
					end
				end
			end	
		end
	end;
	
	nograv = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				local gravVal = plr.Character.HumanoidRootPart:FindFirstChild("Gravity")
				if gravVal then
					gravVal:Destroy()
				end
				local bodyForce = Instance.new("BodyForce")
				bodyForce.Name = "Gravity"
				bodyForce.Force = Vector3.new(0,0,0)
				bodyForce.Parent = plr.Character.HumanoidRootPart
				for _, obj in next, plr.Character:GetChildren() do 
					if obj:IsA("BasePart") then 
						bodyForce.Force = bodyForce.Force + Vector3.new(0,obj:GetMass()*196.25,0) 
					elseif obj:IsA("Accoutrement") then 
						bodyForce.Force = bodyForce.Force + Vector3.new(0,obj.Handle:GetMass()*196.25,0) 
					end
				end
			end	
		end
	end;
	
	freefall = function(sender, target, height)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				plr.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(0,tonumber(height),0)
			end
		end
	end;
	
	name = function(sender, target, ...)
		if not target or not ... then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				local nameStr = table.concat({...}, " ")
				local plrName = game:GetService("Chat"):FilterStringForBroadcast(nameStr, sender)
				for _, obj in next, plr.Character:GetChildren() do 
					if obj:FindFirstChild("NameTag") then 
						plr.Character.Head.Transparency = 0 
						obj:Destroy() 
					end 
				end
				local headClone = plr.Character.Head:Clone()
				local model = Instance.new("Model")
				local humanoid = Instance.new("Humanoid")
				local weld = Instance.new("Weld")
				plr.Character.Head.Transparency = 1
				model.Name = plrName
				model.Parent = plr.Character
				headClone.CanCollide = false
				headClone.Parent = model
				humanoid.Name = "NameTag"
				humanoid.MaxHealth = plr.Character.Humanoid.MaxHealth
				humanoid.Health = plr.Character.Humanoid.Health
				humanoid.Parent = model
				weld.Part0 = headClone 
				weld.Part1 = plr.Character.Head
				weld.Parent = headClone
				plr.Character.Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
					humanoid.MaxHealth = plr.Character.Humanoid.MaxHealth
					wait()
					humanoid.Health = plr.Character.Humanoid.Health
				end)
			end
		end
	end;
	
	unname = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				local model = plr.Character:FindFirstChildOfClass("Model")
				if model then
					plr.Character.Head.Transparency = 0
					model:Destroy()
				end
			end
		end
	end;
	
	removepack = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				for _, obj in next, plr.Character:GetChildren() do
					if obj:IsA("CharacterMesh") then
						obj:Destroy()
					end
				end
			end
		end
	end;
	
	char = function(sender, target, Type)
		if not target or not Type then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				if game.Players:FindFirstChild(Type) then
					local UserId
					local success, err = pcall(function()
						UserId = game.Players:GetUserIdFromNameAsync(Type)
					end)
					if success then
						plr.CharacterAppearanceId = UserId
						plr:LoadCharacter()
					end
				else
					plr.CharacterAppearanceId = Type
					plr:LoadCharacter()
				end
			end
		end
	end;
	
	unchar = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				plr.CharacterAppearanceId = plr.UserId
				plr:LoadCharacter()
			end
		end
	end;
	
	clone = function(sender, target)
    	if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
    	for _,plr in next, api:getPlayers(sender, target) do
        	if plr.Character then
				plr.Character.Archivable = true
	            local clone = plr.Character:Clone()
				clone:MoveTo(plr.Character:GetPrimaryPartCFrame().p)
				clone.Parent = workspace.Objects
        	end
		end
	end;
	
	clr = function()
		workspace.Objects:ClearAllChildren()
	end;
	
	explode = function(sender, target)
		if not target then return end
		for _, plr in next, api:getPlayers(sender, target) do
			if plr.Character then
				local explosion = Instance.new("Explosion")
				explosion.BlastRadius = 10
				explosion.Position = plr.Character.HumanoidRootPart.Position
				explosion.Parent = workspace.Objects
			end
		end
	end;
	
	music = function(sender,...)
       if not ... then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		local clientSounds = {}
        if #{...} == 2 then
            local targets,id = ...
            for _,v in next, api:getPlayers(sender, targets) do
                if not clientSounds[v] then
                    local sound = Instance.new("Sound")
                    sound.Parent = v 
                    clientSounds[v] = sound
                end
				clientSounds[v].Looped = true
                clientSounds[v].SoundId = "rbxassetid://"..id
                clientSounds[v]:Play()
            end
        elseif #{...} == 1 then
            if not sound then
                sound = Instance.new("Sound")
                sound.Parent = workspace.Objects
            end
			sound.Looped = true 
            sound.SoundId = "rbxassetid://"..(...)
            sound:Play()
			local assetInfo = mService:GetProductInfo(...)
			for _, plr in next, game.Players:GetPlayers() do
				local gui = script.UI:FindFirstChild("HintUI"):Clone()
				gui.Parent = plr:WaitForChild("PlayerGui")
				hintEvent:FireAllClients("CreateHint", "Playing "..assetInfo.Name.." - "..assetInfo.AssetId)
			end
        end
	end;
	
	stop = function()
		for i,v in pairs(workspace.Objects:GetChildren()) do
			if v:IsA("Sound") then
				v:Destroy()
			end
		end
	end;
	
	time = function(sender, ...)
		if not ... then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		local newTime = table.concat({...}, "")
		game.Lighting.TimeOfDay = newTime
	end;
	
	prefix = function(sender)
		local getPrefix = api.getPrefix()
		clientEvent:FireClient(sender, "ShowPrefixMsg", {Prefix = getPrefix})
	end;
	
	ambient = function(sender, ...)
		if not ... then return end
		game.Lighting.Ambient = Color3.fromRGB((...):match("(%d+),(%d+),(%d+)"))
	end;
	
	oambient = function(sender, ...)
		if not ... then return end
		game.Lighting.OutdoorAmbient = Color3.fromRGB((...):match("(%d+),(%d+),(%d+)"))
	end;
	
	fov = function(sender, number)
		if not number then return end
		cameraEvent:FireClient(sender, "SetFOV", {FOV = tonumber(number)})
	end;
	
	fix = function(sender)
		local info = {
			["Ambient"] = Color3.fromRGB(0,0,0);
			["Brightness"] = 1;
			["ColorShift_Bottom"] = Color3.fromRGB(0,0,0);
			["ColorShift_Top"] = Color3.fromRGB(0,0,0);
			["GlobalShadows"] = true;
			["OutdoorAmbient"] = Color3.fromRGB(127, 127, 127);
			["Outlines"] = false;
			["TimeOfDay"] = "14:00:00"
		}
		for i,v in next, info do
			game.Lighting[i] = v
		end
	end;
	
	restraint = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		local values = script:WaitForChild("Values")
		local stringVal = Instance.new("StringValue")
		stringVal.Name = target
		stringVal.Value = sender.Name
		stringVal.Parent = values
	end;
	
	unrestraint = function(sender, target)
		if not target then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		local value = script.Values:FindFirstChild(target)
		if value then
			value:Destroy()
		end
	end;
	
	create = function(sender, cType, ...)
		--if not cType or name then return end
		if cType == "team" then
			local teamName = table.concat({...}, " ")
			local newName = game:GetService("Chat"):FilterStringForBroadcast(teamName, sender)
			create("Team", newName)
		end
	end;
	
	exec = function(sender, ...)
		if not ... then
			local ui = script.UI:FindFirstChild("ErrorUI"):Clone()
			if ui then
				ui.Parent = sender:WaitForChild("PlayerGui")
			end
			errEvent:FireClient(sender, "DisplayMsg", "Insufficient arguments provided")
			return
		end
		--[[if pcall(function() loadstring("local hi = 'test'") end) then
			print("loadstring is enabled")
		else
			errEvent:FireClient(sender, "DisplayMsg", "Loadstring is disabled")
		end--]]
		local codeStr = table.concat({...}, " ")
		local func, res 
		local success, err = pcall(function()
			func, res = loadstr(codeStr)
		end)
		if func and success then
			func()
			errEvent:FireClient(sender, "DisplayMsg", res)
		else
			warn(err)
			errEvent:FireClient(sender, "DisplayMsg", err)
		end
	end;
	
	slock = function()
		for _, plr in next, plrs:GetPlayers() do 
			if plr:WaitForChild("PlayerGui") then
				local hintGui = script.UI:FindFirstChild("HintUI"):Clone()
				hintGui.Parent = plr:WaitForChild("PlayerGui")
			end
		end
		sLock.Value = true
		hintEvent:FireAllClients("CreateLockMsg")
	end;
	
	unslock = function()
		for _, plr in next, plrs:GetPlayers() do 
			if plr:WaitForChild("PlayerGui") then
				local hintGui = script.UI:FindFirstChild("HintUI"):Clone()
				hintGui.Parent = plr:WaitForChild("PlayerGui")
			end
		end
		sLock.Value = false
		hintEvent:FireAllClients("CreateUnlockMsg")
	end;
}
--
return adminAPI

--[[
	You could also do like
	return
	{
		name = function(...)
		
		end
	}
--]]
