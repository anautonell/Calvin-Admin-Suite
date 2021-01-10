local _script = script

_script.Setup:WaitForChild("Objects").Parent = workspace
_script.Setup:WaitForChild("Networking").Parent = game.ReplicatedStorage
_script.Setup.Scripts:WaitForChild("CameraHandler").Parent = game.StarterPlayer.StarterPlayerScripts
_script.Setup.Scripts:WaitForChild("ClientHandler").Parent = game.StarterPlayer.StarterPlayerScripts

local module = {}

local dService = game:GetService("DataStoreService")
local httpService = game:GetService("HttpService")

local bansDs = dService:GetOrderedDataStore("CalvinAdminSuiteBans6")
local maintDs = dService:GetDataStore("CASMaintenanceDatastore1")

local config = require(_script:WaitForChild("comms_framework"):WaitForChild("Modules"):WaitForChild("config"))
local cmds = require(_script:WaitForChild("comms_framework"))
local api = require(_script:WaitForChild("comms_framework"):WaitForChild("Modules"):WaitForChild("api"))
local proxyMod = require(_script:WaitForChild("comms_framework"):WaitForChild("Modules"):WaitForChild("HttpProxyAPI"))

local banEvent = game.ReplicatedStorage:WaitForChild("Networking"):WaitForChild("BanEvent")
local errEvent = game.ReplicatedStorage:WaitForChild("Networking"):WaitForChild("ErrorEvent")
local keybindsEvent = game.ReplicatedStorage:WaitForChild("Networking"):WaitForChild("KeybindsEvent")
local listEvent = game.ReplicatedStorage:WaitForChild("Networking"):WaitForChild("ListEvent")
local cmdBarEvent = game.ReplicatedStorage:WaitForChild("Networking"):WaitForChild("CmdBarEvent")
local cmdBarFunc = game.ReplicatedStorage:WaitForChild("Networking"):WaitForChild("CmdBarFunc")
local chatLogsFunc = game.ReplicatedStorage:WaitForChild("Networking"):WaitForChild("ChatLogsFunc")
local event = _script.comms_framework.Networking:WaitForChild("Event")
local func = _script.comms_framework.Networking:WaitForChild("Function")

local sLock = _script:WaitForChild("comms_framework"):WaitForChild("Values"):WaitForChild("ServerLock")

local maintVal = false

local keybinds = {}
local chatLogs = {}

local function OnUpdate(newVal)
	print(newVal)
	maintVal = newVal
end

local key = 17719207
local connection = maintDs:OnUpdate(key, OnUpdate)
connection:Disconnect()

game.Players.PlayerAdded:Connect(function(plr)
	local values = _script.comms_framework:WaitForChild("Values")
	
	if api:showUpdateLog() then
		_script.Setup.UI:WaitForChild("UpdateUI"):Clone().Parent = plr.PlayerGui
	end

	local key = plr.UserId
	local getData = bansDs:GetAsync(key)
	if getData or api:isBanned(plr.Name) then
		plr:Kick("You have been banned from this game using Calvin Admin Suite")
	end
	
	if sLock.Value == true then
		plr:Kick("Server is locked") 
	end
	
	if values:FindFirstChild(plr.Name) then
		plr:Kick("You have been put on a restraining order from ".. values[plr.Name].Value)
	end
	
	if api:isModulusVerificationEnabled() then
		if api:isVerified(plr) then
			return true
		end
	end
	
	wait(2.5)
	if api:isGroupBanned(plr) then
		plr:Kick("You are in a banned group")
	end	
	
	plr.Chatted:Connect(function(msg)
		
		table.insert(chatLogs, {User = plr.Name, Message = msg})
		
		if maintVal == true then 
			errEvent:FireClient(plr, "DisplayMsg", "Calvin Admin Suite is currently under maintenance, please try again later") 
			return 
		end 		
		
		if not msg:find("%"..config.prefix) then return end
		local commandsInMsg = {}
		
		for commandString in msg:gmatch("[^%"..config.prefix.."]+") do
			local commandName = commandString:match("%w+"):lower()

			commandsInMsg[commandName] = {}
			
			for arg in commandString:sub(commandName:len() + 1):gmatch("%S+") do -- going to add support for spaces and commas later 
				table.insert(commandsInMsg[commandName], (config.caseSensitiveCommands[commandName] and arg:lower() or arg))
			end
			
			if cmds.commands[commandName] and api:canUseCommand(plr, commandName) then
				cmds.commands[commandName](plr, unpack(commandsInMsg[commandName]))
				api:logCommandOnCard(plr, {CmdName = commandName, Args = unpack(commandsInMsg[commandName])})
			end
		end
		
	end)
end)

function chatLogsFunc.OnInvoke()
	return chatLogs
end

function cmdBarFunc.OnServerInvoke(plr, action)
	local state
	if action == "GetCmds" then
		local cmdsMod = require(_script.comms_framework.Modules:WaitForChild("commands"))
		state = cmdsMod
	end
	repeat wait() until state ~= nil
	return state 
end

banEvent.OnServerEvent:Connect(function(plr, action, Data)
	if action == "BanPlayer" then
		local bannedPlr = game.Players:FindFirstChild(Data.User)
		if bannedPlr then
			local key = bannedPlr.UserId
			bansDs:SetAsync(key, 1)
			bannedPlr:Kick(Data.Reason)
		end
	end
end)	

event.Event:Connect(function(action, Data)
	if action == "BanPlayer" then
		local bannedPlr = game.Players:FindFirstChild(Data.Target)
		local key = game.Players:GetUserIdFromNameAsync(Data.Target)
		bansDs:SetAsync(key, 1)
		if bannedPlr then
			bannedPlr:Kick("You have been banned from this game using Calvin Admin Suite")
		end
	elseif action == "BanPlayerFromUserID" then
		local plrName = game.Players:GetNameFromUserIdAsync(Data.Target)
		local bannedPlr = game.Players:FindFirstChild(plrName)
		bansDs:SetAsync(Data.Target, 1)
		if bannedPlr then
			bannedPlr:Kick("You have been banned from this game using Calvin Admin Suite")
		end
	end
end)

cmdBarEvent.OnServerEvent:Connect(function(plr, action, Data)
	if action == "FireCmdBarCommand" then
		local commandName = Data.Command:match("%w+"):lower()
		if cmds.commands[commandName] and api:canUseCommand(plr, commandName) then
			for arg in Data.Command:sub(commandName:len() + 1):gmatch("%S+") do 
				cmds.commands[commandName](plr, arg)
			end
		end
	end
end)

keybindsEvent.OnServerEvent:Connect(function(plr, action, Data)
	if action == "AddKeybind" then
		keybinds[Data.Key] = Data.Cmd
		keybindsEvent:FireClient(plr, "AddKeybind", {Key = Data.Key, Cmd = Data.Cmd})
	elseif action == "RemoveKeybind" then
		keybinds[Data.Key] = nil
		keybindsEvent:FireClient(plr, "RemoveKeybind", {Key = Data.Key})
	elseif action == "StartCommand" then
		if keybinds[Data.Key] then
			local commandName = keybinds[Data.Key]:match("%w+"):lower()
			if cmds.commands[commandName] and api:canUseCommand(plr, commandName) then
				for arg in keybinds[Data.Key]:sub(commandName:len() + 1):gmatch("%S+") do 
					cmds.commands[commandName](plr, arg)
				end
			end
		end
	end
end)

listEvent.OnServerEvent:Connect(function(plr, action, Data)
	if action == "GiveTool" then
		local toolObj = game.ServerStorage:FindFirstChild(Data.ToolName):Clone()
		if toolObj then
			toolObj.Parent = plr.Backpack
		end
	end
end)

return function(adminSettings)
	api:changePrefix(adminSettings.prefix)
	if adminSettings.settingsIcon then
		_script.Setup.UI:WaitForChild("GetAdminUI"):Clone().Parent = game.StarterGui
	else
		print("false, no!")
	end
	if adminSettings.updateLog then
		api:setUpdateLog(adminSettings.updateLog)
	else
		print("false, no!")
	end
	for name, perm in next, adminSettings.admins do
		api:addAdmin(name, perm)
	end
	for _, plr in next, adminSettings.bans do
		if plr then
			api:addBan(plr)
		end	
	end
	for id, tbl in next, adminSettings.groupAdmin do
		for rank, perm in next, tbl do
			print("GroupID - "..id,"Rank - "..rank,"PermLevel - "..perm)
			api:addGroupAdmin(id, rank, perm)
		end
	end
	local funcPerms, func
	for funcName, tbl in next, adminSettings.cmds do
		for i,v in next, tbl do
			if type(i) == "string" and i == "perms" then
				for permName, permBool in next, v do
					funcPerms = permName
				end
			elseif type(v) == "function" then
				func = v
			end
		end
		api:addToCommandList(funcPerms, funcName, func)
	end
	if adminSettings.trelloEnabled then
		api:setTrelloInfo(adminSettings.key, adminSettings.token, adminSettings.boardName, adminSettings.logCommands)
	end
	--	if adminSettings.modulusVerify then
--		api:setModulusVerification(true)
--	end
	for _, id in next, adminSettings.groupBans do
		api:addGroupBan(id)
	end
end