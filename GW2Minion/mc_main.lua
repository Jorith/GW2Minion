mc_global = { }
mc_global.window = { name="MinionBot", x=50, y=50, width=200, height=300 }
mc_global.advwindow = { name="AdvandedSettings", x=250, y=200 , width=200, height=170 }
mc_global.advwindowvisible = false
mc_global.path = GetStartupPath()
mc_global.now = 0
mc_global.lasttick = 0
mc_global.running = false
mc_global.BotModes = {}

ml_global_information = { }
ml_global_information.Now = 0

mc_global.WorldMarkerType = 24 -- enum for "in current map", changes on larger patches sometimes


function mc_global.moduleinit()
	
	if ( Settings.GW2Minion.gPulseTime == nil ) then
		Settings.GW2Minion.gPulseTime = "150"
	end
	if ( Settings.GW2Minion.gBotMode == nil ) then
        Settings.GW2Minion.gBotMode = GetString("grindMode")
    end
	if ( Settings.GW2Minion.gDepositItems == nil ) then
        Settings.GW2Minion.gDepositItems = "1"
    end
	if ( Settings.GW2Minion.gDoEvents == nil ) then
        Settings.GW2Minion.gDoEvents = "1"
    end
	if ( Settings.GW2Minion.gAutostartbot == nil ) then
		Settings.GW2Minion.gAutostartbot = "0"
	end
	if ( Settings.GW2Minion.gGuestServer == nil ) then
		Settings.GW2Minion.gGuestServer = "None"
	end
	if ( Settings.GW2Minion.gSkipCutscene == nil ) then
		Settings.GW2Minion.gSkipCutscene = "None"
	end
	if ( Settings.GW2Minion.gGather == nil ) then
		Settings.GW2Minion.gGather = "1"
	end
	if ( Settings.GW2Minion.gRevive == nil ) then
		Settings.GW2Minion.gRevive = "1"
	end	
	if ( Settings.GW2Minion.dDisableRender == nil ) then
		Settings.GW2Minion.dDisableRender = "0"
	end	
	
	if ( Settings.GW2Minion.gChatAlert == nil ) then
		Settings.GW2Minion.gChatAlert = {
			Whisper = "0",
			Say = "0",
			Info = "0",
			God = "0",
			Guild = "0",
			Party = "0",
		}
	end
	
	-- MAIN WINDOW
	GUI_NewWindow(mc_global.window.name,mc_global.window.x,mc_global.window.y,mc_global.window.width,mc_global.window.height)
	GUI_NewButton(mc_global.window.name,GetString("startStop"),"mc_global.startStop")
		
	GUI_NewButton(mc_global.window.name,GetString("showradar"),"Radar.toggle")
	RegisterEventHandler("mc_global.startStop", mc_global.eventhandler)
	GUI_NewCheckbox(mc_global.window.name,GetString("botEnabled"),"gBotRunning",GetString("botStatus"))
	GUI_NewCheckbox(mc_global.window.name,GetString("autoStartBot"),"gAutostartbot",GetString("botStatus"))
	GUI_NewComboBox(mc_global.window.name,GetString("botMode"),"gBotMode",GetString("botStatus"),"None")
	-- Debug fields
	--GUI_NewField(mc_global.window.name,"Task","dTrace",GetString("botStatus"))
	GUI_NewField(mc_global.window.name,"AttackRange","dAttackRange",GetString("botStatus"))
	GUI_NewCheckbox(mc_global.window.name,GetString("disabledrawing"),"dDisableRender",GetString("botStatus"))
		
	GUI_NewNumeric(mc_global.window.name,GetString("pulseTime"),"gPulseTime",GetString("settings"),"10","10000")

	GUI_NewCheckbox(mc_global.window.name,GetString("depositItems"),"gDepositItems",GetString("settings"))	
	GUI_NewCheckbox(mc_global.window.name,GetString("doEvents"),"gDoEvents",GetString("settings"))
	GUI_NewComboBox(mc_global.window.name,GetString("guestserver"),"gGuestServer",GetString("settings"),"None")	
	GUI_NewCheckbox(mc_global.window.name,GetString("skipcutscene"),"gSkipCutscene",GetString("settings"))
	GUI_NewCheckbox(mc_global.window.name,GetString("gatherMode"),"gGather",GetString("settings"))
	GUI_NewCheckbox(mc_global.window.name,GetString("revivecharacters"),"gRevive",GetString("settings"))
	
	GUI_NewCheckbox(mc_global.window.name,"Whisper","gChatAlertWhisper",GetString("checkChat"))
	GUI_NewCheckbox(mc_global.window.name,"Say","gChatAlertSay",GetString("checkChat"))
	GUI_NewCheckbox(mc_global.window.name,"Info","gChatAlertInfo",GetString("checkChat"))
	GUI_NewCheckbox(mc_global.window.name,"God","gChatAlertGod",GetString("checkChat"))
	GUI_NewCheckbox(mc_global.window.name,"Guild","gChatAlertGuild",GetString("checkChat"))
	GUI_NewCheckbox(mc_global.window.name,"Party","gChatAlertParty",GetString("checkChat"))	
	
	GUI_NewButton(mc_global.window.name, GetString("advancedSettings"), "AdvancedSettings.toggle")
	RegisterEventHandler("AdvancedSettings.toggle", mc_global.ToggleAdvMenu)
	
	-- ADVANCED SETTINGS WINDOW
	GUI_NewWindow(mc_global.advwindow.name,mc_global.advwindow.x,mc_global.advwindow.y,mc_global.advwindow.width,mc_global.advwindow.height,true)
	GUI_NewButton(mc_global.advwindow.name, GetString("multibotmanager"), "MultiBotManager.toggle")
	GUI_NewButton(mc_global.advwindow.name, GetString("blacklistManager"), "bToggleBlacklistMgr")
	RegisterEventHandler("bToggleBlacklistMgr", mc_blacklist.ToggleMenu)
	GUI_NewButton(mc_global.advwindow.name, GetString("questManager"), "QuestManager.toggle")	
	GUI_NewButton(mc_global.advwindow.name, GetString("skillManager"), "SkillManager.toggle")
	GUI_NewButton(mc_global.advwindow.name, GetString("maprotation"), "MapRotation.toggle")
	GUI_NewButton(mc_global.advwindow.name, GetString("meshManager"), "ToggleMeshManager")
		
	GUI_WindowVisible(mc_global.advwindow.name,false)
	
	-- setup bot mode
    local botModes = "None"
    if ( TableSize(mc_global.BotModes) > 0) then
        local i,entry = next ( mc_global.BotModes )
        while i and entry do
            botModes = botModes..","..i
            i,entry = next ( mc_global.BotModes,i)
        end
    end
	
	-- GuestServer
	local newserverlist = "None"
	local homeserverid = GetHomeServer()
	local serverlist = {}	
	if ( homeserverid > 1000 and homeserverid < 2000 ) then
		serverlist = mc_datamanager.ServersUS
	elseif ( homeserverid > 2000 and homeserverid < 3000 ) then
		serverlist = mc_datamanager.ServersEU
	end	
	if ( TableSize(serverlist) > 0) then
		local i,entry = next ( serverlist)
		while i and entry do			
			newserverlist = newserverlist..","..entry.name
			i,entry = next ( serverlist,i)
		end
	end
	gGuestServer_listitems = newserverlist
	gGuestServer = Settings.GW2Minion.gGuestServer
    
    gBotMode_listitems = botModes    
    gBotMode = Settings.GW2Minion.gBotMode	
	mc_global.UpdateMode()
	
	gBotRunning = "0"
	gPulseTime = Settings.GW2Minion.gPulseTime	
	gDepositItems = Settings.GW2Minion.gDepositItems	
	gDoEvents = Settings.GW2Minion.gDoEvents	
	gAutostartbot = Settings.GW2Minion.gAutostartbot
	gSkipCutscene = Settings.GW2Minion.gSkipCutscene
	gGather = Settings.GW2Minion.gGather
	gRevive = Settings.GW2Minion.gRevive
	gChatAlertWhisper = Settings.GW2Minion.gChatAlert.Whisper
	gChatAlertSay = Settings.GW2Minion.gChatAlert.Say
	gChatAlertInfo = Settings.GW2Minion.gChatAlert.Info
	gChatAlertGod = Settings.GW2Minion.gChatAlert.God
	gChatAlertGuild = Settings.GW2Minion.gChatAlert.Guild
	gChatAlertParty = Settings.GW2Minion.gChatAlert.Party

	if ( RenderManager ) then
		RenderManager:ToggleRendering(tonumber(dDisableRender))
	end
	GUI_UnFoldGroup(mc_global.window.name,GetString("botStatus") );
	
-- setup marker manager callbacks and vars
	if ( ml_marker_mgr ) then
		ml_marker_mgr.GetPosition = 	function () return ml_global_information.Player_Position end
		ml_marker_mgr.GetLevel = 		function () return ml_global_information.Player_Level end
		ml_marker_mgr.DrawMarker =		ml_globals.DrawMarker
		ml_marker_mgr.parentWindow = { Name="MinionBot" }
		ml_marker_mgr.markerPath = mc_global.path.. [[\Navigation\]]
		
	end
	
-- setup meshmanager
	if ( ml_mesh_mgr ) then
		ml_mesh_mgr.parentWindow.Name = "MinionBot"
		ml_mesh_mgr.GetMapID = function () return ml_global_information.CurrentMapID end
		ml_mesh_mgr.GetMapName = function () return ml_global_information.CurrentMapName end
		ml_mesh_mgr.GetPlayerPos = function () return ml_global_information.Player_Position end
		ml_mesh_mgr.averagegameunitsize = 50
		
		-- Set default meshes SetDefaultMesh(mapid, filename)
		ml_mesh_mgr.SetDefaultMesh(17,"Harathi Hinterlands")
			
		ml_mesh_mgr.SetDefaultMesh(19,"PlainsOfAshford")
		ml_mesh_mgr.SetDefaultMesh(20,"BlazzeridgeSteppes")
		ml_mesh_mgr.SetDefaultMesh(22,"FireHeartRise")
				
		ml_mesh_mgr.SetDefaultMesh(25,"IronMarches")
		ml_mesh_mgr.SetDefaultMesh(26,"Dredgehaunt Cliffs")
		ml_mesh_mgr.SetDefaultMesh(27,"LonarsPass")
		ml_mesh_mgr.SetDefaultMesh(28,"Wayfarer Foothills")		
		ml_mesh_mgr.SetDefaultMesh(29,"TimberlineFalls")
		ml_mesh_mgr.SetDefaultMesh(30,"FrostGorge Sound")
		
		ml_mesh_mgr.SetDefaultMesh(32,"DiessaPlateau")
		ml_mesh_mgr.SetDefaultMesh(34,"Caledon Forest")
		ml_mesh_mgr.SetDefaultMesh(35,"MetricaProvince")
		ml_mesh_mgr.SetDefaultMesh(39,"MountMaelstrom")
		
		ml_mesh_mgr.SetDefaultMesh(53,"Sparkfly Fen")
		ml_mesh_mgr.SetDefaultMesh(73,"BloodtideCoast")
				
		-- Setup the marker types we wanna use
		   --[[ local mapMarker = ml_marker:Create("MapMarker")
			mapMarker:SetType(GetString("mapMarker"))
			mapMarker:SetMinLevel(1)
			mapMarker:SetMaxLevel(50)
			mapMarker:AddField("int", "Target MapID", 0)			
			ml_marker_mgr.AddMarkerTemplate(mapMarker)			
			
			local vendorMarker = ml_marker:Create("vendorTemplate")
			vendorMarker:SetType(GetString("vendorMarker"))
			vendorMarker:SetMinLevel(1)
			vendorMarker:SetMaxLevel(50)
			ml_marker_mgr.AddMarkerTemplate(vendorMarker)--]]
			
			
			-- refresh the manager with the new templates
			ml_marker_mgr.RefreshMarkerTypes()
			ml_marker_mgr.RefreshMarkerNames()
				
		ml_mesh_mgr.InitMarkers() -- Update the Markers-group in the mesher UI
	end
	
-- setup blacklists
	if ( ml_blacklist_mgr ) then
		ml_blacklist_mgr.parentWindow = { Name="MinionBot" }
		
	end
	
end

function mc_global.onupdate( event, tickcount )
	mc_global.now = tickcount
	ml_global_information.Now = tickcount
	
	-- Update Variables
	if ( tickcount - mc_global.lasttick > tonumber(gPulseTime) ) then
		mc_global.lasttick = tickcount
		
		-- Update global variables
		ml_globals.UpdateGlobals()
			
		-- Mesher OnUpdate
		ml_mesh_mgr.OnUpdate( tickcount )
		
		-- SkillManager OnUpdate
		mc_skillmanager.OnUpdate( tickcount )
		
		-- PartyManager OnUpdate
		mc_multibotmanager.OnUpdate( tickcount )
		
		-- BlackList OnUpdate
		mc_blacklist.OnUpdate( tickcount )
		
		-- FollowBot OnUpdate
		mc_followbot.OnUpdate( tickcount )
	
		-- ChatMonitor OnUpdate
		mc_global.ChatMonitor( tickcount )
		
		if ( mc_global.running ) then		
			
			-- Let the bot tick ;)
			if ( mc_global.BotModes[gBotMode] ) then
													
				if( ml_task_hub:CurrentTask() ~= nil) then
					ml_log(ml_task_hub:CurrentTask().name.." :")
				end
				
				if ( ml_task_hub.shouldRun ) then
					if ( (gBotMode == GetString("grindMode") or gBotMode == GetString("exploreMode")) and mc_meshrotation.Update() == true) then
						
					end
					
					if (not ml_task_hub:Update() ) then
							ml_error("No task queued, please select a valid bot mode in the Settings drop-down menu")
					end
				end
				
				-- Unstuck OnUpdate
				mc_ai_unstuck:OnUpdate( tickcount )
				
			end
		
		elseif ( mc_global.running == false and gAutostartbot == "1" ) then
			mc_global.togglebot(1)
		else
			if ( tickcount - mc_global.lasttick > tonumber(gPulseTime) ) then
				mc_global.lasttick = tickcount
				ml_log("BOT: Not Running")
			end
		end
		GUI_SetStatusBar(ml_GetTraceString())
	end
end

mc_global.Charscreen_lastrun = 0
function mc_global.OnUpdateCharSelect(event, tickcount )
	
	mc_global.now = tickcount
	if (mc_global.Charscreen_lastrun == 0) then
		mc_global.Charscreen_lastrun = tickcount
	elseif ( gAutostartbot == "1" and tickcount - mc_global.Charscreen_lastrun > 2500) then
		mc_global.Charscreen_lastrun = tickcount
		
		GUI_SetStatusBar("In Characterscreen...Autostart Bot: "..tostring(gAutostartbot).. ", (Guest)Server: "..tostring(gGuestServer))
		
		if ( gGuestServer ~= nil and gGuestServer ~= "None" ) then
			local serverlist = {}
			local homeserverid = GetHomeServer()
			if ( homeserverid > 1000 and homeserverid < 2000 ) then
				serverlist = mc_datamanager.ServersUS
			elseif ( homeserverid > 2000 and homeserverid < 3000 ) then
				serverlist = mc_datamanager.ServersEU
			end	
			if ( TableSize(serverlist) > 0) then
				local i,entry = next ( serverlist)
				while i and entry do			
					if ( gGuestServer == entry.name ) then
						SetServer(entry.id)
						d("Selecting Guestserver: "..(entry.name) .." ID: ".. tostring(entry.id))
						break
					end
					i,entry = next ( serverlist,i)
				end
			end
			--gGuestServer_listitems = newserverlist
			--gGuestServer = Settings.GW2Minion.gGuestServer
			
		end		
		d("Pressing PLAY")
		PressKey("RETURN")				
	end
end

mc_global.Cinema_lastrun = 0
function mc_global.OnUpdateCutscene(event, tickcount )
	GUI_SetStatusBar("In Cutscene...")	
	mc_global.now = tickcount
	Player:StopMovement()
	if ( gSkipCutscene == "1" and tickcount - mc_global.Cinema_lastrun > 2000 ) then
		mc_global.Cinema_lastrun = tickcount
		d("Skipping Cutscene...")
		PressKey("ESC")
	end
end

-- parses the chat in order to play a warning signal when a whisper etc comes in
ml_global_information.chatmonitortmr = 0
mc_global.whispers = {}
function mc_global.ChatMonitor( tickcount )
	if ( tickcount - ml_global_information.chatmonitortmr > 5000 ) then
		ml_global_information.chatmonitortmr = tickcount
		if ( gChatAlertWhisper == "1" ) then
			local NewWhisper = GetChatMsg(GW2.CHATCHANNEL.Whisper, 100)
			if ( TableSize(NewWhisper) > 0 ) then
				if ( mc_global.whispers[GW2.CHATCHANNEL.Whisper] ~= nil and mc_global.whispers[GW2.CHATCHANNEL.Whisper] ~= NewWhisper[1]) then
					PlaySound(mc_global.path.."\\MinionFiles\\Sounds\\Alarm1.wav")
				end
				mc_global.whispers[GW2.CHATCHANNEL.Whisper] = NewWhisper[1]
			end
		end
		if ( gChatAlertSay == "1" ) then
			local NewWhisper = GetChatMsg(GW2.CHATCHANNEL.Say, 100)
			if ( TableSize(NewWhisper) > 0 ) then
				if ( mc_global.whispers[GW2.CHATCHANNEL.Say] ~= nil and mc_global.whispers[GW2.CHATCHANNEL.Say] ~= NewWhisper[1]) then
					PlaySound(mc_global.path.."\\MinionFiles\\Sounds\\Alarm1.wav")
				end
				mc_global.whispers[GW2.CHATCHANNEL.Say] = NewWhisper[1]
			end
		end
		if ( gChatAlertInfo == "1" ) then
			local NewWhisper = GetChatMsg(GW2.CHATCHANNEL.Info, 100)
			if ( TableSize(NewWhisper) > 0 ) then
				if ( mc_global.whispers[GW2.CHATCHANNEL.Info] ~= nil and mc_global.whispers[GW2.CHATCHANNEL.Info] ~= NewWhisper[1]) then
					PlaySound(mc_global.path.."\\MinionFiles\\Sounds\\Alarm1.wav")
					d("Info Alert!")
				end
				mc_global.whispers[GW2.CHATCHANNEL.Info] = NewWhisper[1]
			end
		end	
		if ( gChatAlertGod == "1" ) then
			local NewWhisper = GetChatMsg(GW2.CHATCHANNEL.God, 100)
			if ( TableSize(NewWhisper) > 0 ) then
				if ( mc_global.whispers[GW2.CHATCHANNEL.God] ~= nil and mc_global.whispers[GW2.CHATCHANNEL.God] ~= NewWhisper[1]) then
					PlaySound(mc_global.path.."\\MinionFiles\\Sounds\\Alarm1.wav")
					d("God Alert!")
				end
				mc_global.whispers[GW2.CHATCHANNEL.God] = NewWhisper[1]
			end
		end	
		if ( gChatAlertGuild == "1" ) then
			local NewWhisper = GetChatMsg(GW2.CHATCHANNEL.Guild, 100)
			if ( TableSize(NewWhisper) > 0 ) then
				if ( mc_global.whispers[GW2.CHATCHANNEL.Guild] ~= nil and mc_global.whispers[GW2.CHATCHANNEL.Guild] ~= NewWhisper[1]) then
					PlaySound(mc_global.path.."\\MinionFiles\\Sounds\\Alarm1.wav")					
				end
				mc_global.whispers[GW2.CHATCHANNEL.Guild] = NewWhisper[1]
			end
		end	
		if( gChatAlertParty == "1" ) then
			local NewWhisper = GetChatMsg(GW2.CHATCHANNEL.Party, 100)
			if ( TableSize(NewWhisper) > 0 ) then
				if ( mc_global.whispers[GW2.CHATCHANNEL.Party] ~= nil and mc_global.whispers[GW2.CHATCHANNEL.Party] ~= NewWhisper[1]) then
					PlaySound(mc_global.path.."\\MinionFiles\\Sounds\\Alarm1.wav")
				end
				mc_global.whispers[GW2.CHATCHANNEL.Party] = NewWhisper[1]
			end
		end	
	end
end
	
function mc_global.eventhandler(arg)
	if ( arg == "mc_global.startStop" or arg == "GW2MINION.toggle") then
		if ( gBotRunning == "1" ) then
			gAutostartbot = "0"
			mc_global.togglebot("0")			
		else
			gAutostartbot = "1"
			mc_global.togglebot("1")
		end
	end
end

function mc_global.guivarupdate(Event, NewVals, OldVals)
	for k,v in pairs(NewVals) do
		if (k == "gEnableLog" or
			k == "gDepositItems" or
			k == "gDoEvents" or 
			k == "sMmode" or 
			k == "sMtargetmode" or
			k == "SalvageManager_Active" or
			k == "gRepairBrokenLimit" or
			k == "gRepairDamageLimit" or 
			k == "MBSGroup" or 
			k == "gMultiPort" or 
			k == "gMultiPw" or 
			k == "gMultiIP" or 			
			k == "gAutostartbot" or
			k == "gGuestServer" or
			k == "gSkipCutscene" or
			k == "gGather" or
			k == "gRevive" )			
		then
			Settings.GW2Minion[tostring(k)] = v
		elseif (k == "dMember1") then Settings.GW2Minion.Party[1] = v Settings.GW2Minion.Party = Settings.GW2Minion.Party
		elseif (k == "dMember2") then Settings.GW2Minion.Party[2] = v Settings.GW2Minion.Party = Settings.GW2Minion.Party
		elseif (k == "dMember3") then Settings.GW2Minion.Party[3] = v Settings.GW2Minion.Party = Settings.GW2Minion.Party
		elseif (k == "dMember4") then Settings.GW2Minion.Party[4] = v Settings.GW2Minion.Party = Settings.GW2Minion.Party		
			
		elseif ( k == "gBotRunning" ) then
			mc_global.togglebot(v)			
		elseif ( k == "gBotMode") then        
			Settings.GW2Minion[tostring(k)] = v
			--mc_global.UpdateMode()
			--mm.NavMeshUpdate()
		elseif ( k == "gMultiBotEnabled" ) then
			if ( v == "0" ) then							
				MultiBotDisconnect()				
			end
			Settings.GW2Minion[tostring(k)] = v
		elseif ( k == "dDisableRender") then
			RenderManager:ToggleRendering(tonumber(v))
			Settings.GW2Minion[tostring(k)] = v
		elseif ( k == "gChatAlertWhisper") then Settings.GW2Minion.gChatAlert.Whisper = v Settings.GW2Minion.gChatAlert = Settings.GW2Minion.gChatAlert
		elseif ( k == "gChatAlertSay") then Settings.GW2Minion.gChatAlert.Say = v Settings.GW2Minion.gChatAlert = Settings.GW2Minion.gChatAlert
		elseif ( k == "gChatAlertInfo") then Settings.GW2Minion.gChatAlert.Info = v Settings.GW2Minion.gChatAlert = Settings.GW2Minion.gChatAlert
		elseif ( k == "gChatAlertGod") then Settings.GW2Minion.gChatAlert.God = v Settings.GW2Minion.gChatAlert = Settings.GW2Minion.gChatAlert
		elseif ( k == "gChatAlertGuild") then Settings.GW2Minion.gChatAlert.Guild = v Settings.GW2Minion.gChatAlert = Settings.GW2Minion.gChatAlert
		elseif ( k == "gChatAlertParty") then Settings.GW2Minion.gChatAlert.Party = v Settings.GW2Minion.gChatAlert = Settings.GW2Minion.gChatAlert
		
		end
	end
	GUI_RefreshWindow(mc_global.window.name)
end

function mc_global.UpdateMode()
	if (gBotMode == "None") then	
		ml_task_hub:ClearQueues()
	else	
		local task = mc_global.BotModes[gBotMode]
		if (task ~= nil) then
			ml_task_hub:Add(task.Create(), LONG_TERM_GOAL, TP_ASAP)
		end
    end
end

function mc_global.togglebot(arg)
	if arg == "0" then	
		d("Stopping Bot..")
		mc_global.running = false
		ml_task_hub.shouldRun = false		
		gBotRunning = "0"
		mc_global.ResetBot()
		ml_task_hub:ClearQueues()
		mc_global.UpdateMode()
	else
		d("Starting Bot..")
		mc_global.running = true
		ml_task_hub.shouldRun = true
		gBotRunning = "1"
		mc_meshrotation.currentMapTime = mc_global.now
	end
end

function mc_global.ResetBot()
	mc_ai_vendor.isSelling = false
	mc_ai_vendor.isBuying = false
	Player:StopMovement()
	Player:ClearTarget()
end

function mc_global.Wait( seconds ) 
	mc_global.lasttick = mc_global.lasttick + seconds
	-- extend unstucktimers
	mc_ai_unstuck.idletimer = mc_ai_unstuck.idletimer + seconds
end

function mc_global.ToggleAdvMenu()
    if (mc_global.advwindowvisible) then
        GUI_WindowVisible(mc_global.advwindow.name,false)	
        mc_global.advwindowvisible = false
    else
		local wnd = GUI_GetWindowInfo("MinionBot")	
        GUI_MoveWindow( mc_global.advwindow.name, wnd.x,wnd.y+wnd.height)
		GUI_WindowVisible(mc_global.advwindow.name,true)	
        mc_global.advwindowvisible = true
    end
end

-- gets called after a new navmesh was loaded successfully
function mc_global.NavMeshUpdate()
	mc_datamanager.UpdateLevelMap()
	
	-- try loading questprofile
	if ( gBotMode == GetString("grindMode") or gBotMode == GetString("exploreMode")) then
		local mapname = mc_datamanager.GetMapName( Player:GetLocalMapID())
		if ( mapname ~= nil and mapname ~= "" and mapname ~= "none" ) then
			mapname = mapname:gsub('%W','') -- only alphanumeric
			if ( mapname ~= nil and mapname ~= "" ) then
				gQMprofile = mapname
				ml_quest_mgr.UpdateCurrentProfileData()
			end
		end
	end
	
	if ( TableSize(ml_quest_mgr.QuestList) == 0 and (gBotMode == GetString("grindMode") or gBotMode == GetString("exploreMode"))) then
		mc_questmanager.GenerateMapExploreProfile()
	end
	
	mc_global.ResetBot()
	if ( Maprotation_Active == "1") then
		ml_task_hub:ClearQueues()
	end
	mc_global.UpdateMode()	

end

RegisterEventHandler("Module.Initalize",mc_global.moduleinit)
RegisterEventHandler("Gameloop.Update",mc_global.onupdate)
RegisterEventHandler("GUI.Update",mc_global.guivarupdate)
RegisterEventHandler("Gameloop.CharSelectUpdate",mc_global.OnUpdateCharSelect)
RegisterEventHandler("Gameloop.CutsceneUpdate",mc_global.OnUpdateCutscene)
RegisterEventHandler("GW2MINION.toggle", mc_global.eventhandler)
RegisterEventHandler("Gameloop.MeshReady",mc_global.NavMeshUpdate)