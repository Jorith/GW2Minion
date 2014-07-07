mc_multibotmanager = { }
mc_multibotmanager.mainwindow = { name = GetString("multibotmanager"), x = 350, y = 100, w = 250, h = 300}
mc_multibotmanager.visible = false
mc_multibotmanager.lasttick = 0
mc_multibotmanager.leadername = ""
mc_multibotmanager.leaderserverID = 0
mc_multibotmanager.leaderWPID = 0

function mc_multibotmanager.ModuleInit() 	
	
	if (Settings.GW2Minion.gMultiBotEnabled == nil) then
		Settings.GW2Minion.gMultiBotEnabled = "0"
	end
   	if (Settings.GW2Minion.gRole == nil) then
		Settings.GW2Minion.gRole = "Party Member"
	end
	
	if (Settings.GW2Minion.Party == nil) then
		Settings.GW2Minion.Party = {}
		for idx=1,4 do
			if (Settings.GW2Minion.Party[idx] == nil) then
				Settings.GW2Minion.Party[idx] = "None"
			end				
		end
		Settings.GW2Minion.Party = Settings.GW2Minion.Party
	end	
	
	
	if ( Settings.GW2Minion.MBSGroup == nil ) then
		Settings.GW2Minion.MBSGroup = "Group1"
	end
	if ( Settings.GW2Minion.gMultiIP == nil ) then
		Settings.GW2Minion.gMultiIP = "127.0.0.1"
	end
	if ( Settings.GW2Minion.gMultiPort == nil ) then
		Settings.GW2Minion.gMultiPort = "7777"
	end
	if ( Settings.GW2Minion.gMultiPw == nil ) then
		Settings.GW2Minion.gMultiPw = "minionpw"
	end
	
    local wnd = GUI_GetWindowInfo("MinionBot")
    GUI_NewWindow(mc_multibotmanager.mainwindow.name,wnd.x+wnd.width,wnd.y,mc_multibotmanager.mainwindow.w,mc_multibotmanager.mainwindow.h,true)
	GUI_NewCheckbox(mc_multibotmanager.mainwindow.name,GetString("activated"),"gMultiBotEnabled",GetString("generalSettings"))
	GUI_NewField(mc_multibotmanager.mainwindow.name,GetString("status"),"dPartyStatus",GetString("generalSettings"))
	GUI_NewField(mc_multibotmanager.mainwindow.name,GetString("partyrole"),"gRole",GetString("generalSettings"))
	GUI_NewField(mc_multibotmanager.mainwindow.name,GetString("member1"),"dMember1",GetString("groupInfo"))
	GUI_NewField(mc_multibotmanager.mainwindow.name,GetString("member2"),"dMember2",GetString("groupInfo"))
	GUI_NewField(mc_multibotmanager.mainwindow.name,GetString("member3"),"dMember3",GetString("groupInfo"))
	GUI_NewField(mc_multibotmanager.mainwindow.name,GetString("member4"),"dMember4",GetString("groupInfo"))
	GUI_NewButton(mc_multibotmanager.mainwindow.name,GetString("usecurrentparty"), "bcopyParty",GetString("groupInfo"))
	RegisterEventHandler("bcopyParty", mc_multibotmanager.CopyParty)
	
	GUI_NewField(mc_multibotmanager.mainwindow.name,GetString("MBSGroup"),"MBSGroup",GetString("serverInfo"))
	GUI_NewField(mc_multibotmanager.mainwindow.name,GetString("MBSIP"),"gMultiIP",GetString("serverInfo"))
	GUI_NewField(mc_multibotmanager.mainwindow.name,GetString("MBSPort"),"gMultiPort",GetString("serverInfo"))
	GUI_NewField(mc_multibotmanager.mainwindow.name,GetString("MBSPW"),"gMultiPw",GetString("serverInfo"))
	
						
	gPartyMGR = Settings.GW2Minion.gPartyMGR
	gRole = "Party Member"
	dMember1 = Settings.GW2Minion.Party[1]
	dMember2 = Settings.GW2Minion.Party[2]
	dMember3 = Settings.GW2Minion.Party[3]
	dMember4 = Settings.GW2Minion.Party[4]
	
	MBSGroup = Settings.GW2Minion.MBSGroup
	gMultiIP = Settings.GW2Minion.gMultiIP
	gMultiPort = Settings.GW2Minion.gMultiPort
	gMultiPw = Settings.GW2Minion.gMultiPw
	gMultiBotEnabled = Settings.GW2Minion.gMultiBotEnabled
		
    GUI_UnFoldGroup(mc_multibotmanager.mainwindow.name,GetString("generalSettings"))		
    GUI_UnFoldGroup(mc_multibotmanager.mainwindow.name,GetString("groupInfo"))
	
    GUI_WindowVisible(mc_multibotmanager.mainwindow.name,false)

	-- fix for getting the proper leader/minion role on reload lua
	if (gMultiBotEnabled == "1" and MultiBotIsConnected() ) then
		MultiBotJoinChannel(MBSGroup)
	end
end


function mc_multibotmanager.ToggleMenu()
    if (mc_multibotmanager.visible) then
        GUI_WindowVisible(mc_multibotmanager.mainwindow.name,false)	
        mc_multibotmanager.visible = false
    else
        local wnd = GUI_GetWindowInfo("MinionBot")	
        GUI_MoveWindow( mc_multibotmanager.mainwindow.name, wnd.x+wnd.width,wnd.y) 
        GUI_WindowVisible(mc_multibotmanager.mainwindow.name,true)	
        mc_multibotmanager.visible = true
    end
end

function mc_multibotmanager.OnUpdate( tickcount )
    if ( tickcount - mc_multibotmanager.lasttick > 500 ) then
        mc_multibotmanager.lasttick = tickcount
        
        if (gMultiBotEnabled == "1") then
						
			if ( MultiBotIsConnected() )then
				
				mc_multibotmanager.LeaderBroadCast()
				mc_multibotmanager.UpdatePartyStatus()					
					
			else
				dPartyStatus = tostring("Connecting to MultibotServer.")
				if ( not MultiBotConnect( gMultiIP , tonumber(gMultiPort) , gMultiPw) ) then
					gMultiBotEnabled = "0"
					ml_error("Cannot reach MultibotComServer... ")
					ml_error("Start the MultibotServer.exe and/or setup the correct Password,IP and Port if you have changed them!")
				else
					if (MultiBotJoinChannel(MBSGroup)) then
						d("Successfully Joined channel "..MBSGroup)
						dPartyStatus = tostring("Connected to MultibotServer")
					else
						ml_error("Can't join Multibot Channel?!")
						dPartyStatus = tostring("Can't join Multibot Channel")
					end						
				end	
			end
		else
			dPartyStatus = tostring("Disabled..")
		end			
    end
end

function mc_multibotmanager.CopyParty()
	local party = Player:GetParty()	
	if ( TableSize(party) > 1 ) then		
		local pname = Player.name
		local count = 1
				
		for idx=1,4 do			
			Settings.GW2Minion.Party[idx] = "None"
			_G["dMember"..idx] = "None"			
		end
		
		local index, player  = next( party )
		while ( index ~= nil and player ~= nil ) do			
			if ( player.name ~= pname and player.name ~= "") then
				Settings.GW2Minion.Party[count] = player.name
				_G["dMember"..count] = player.name
				count = count + 1
			end
			index, player  = next( party,index )
		end
	end
	Settings.GW2Minion.Party = Settings.GW2Minion.Party
	GUI_RefreshWindow(mc_multibotmanager.mainwindow.name)
end

mc_multibotmanager.broadcastTmr = 0
mc_multibotmanager.broadcastTmr2 = 0
function mc_multibotmanager.LeaderBroadCast()
	if ( Player:GetRole() == 1 ) then
		if ( mc_global.now - mc_multibotmanager.broadcastTmr > 5000 ) then
			mc_multibotmanager.broadcastTmr = mc_global.now
			local pname = Player.name
			if ( pname ~= nil and pname ~= "" ) then
				MultiBotSend( "1;"..pname,MBSGroup )
			end
			local data = mc_multibotmanager.GetPlayerPartyData()
			if ( data and tonumber(data.currentserverid)~=nil) then			
				MultiBotSend( "2;"..data.currentserverid,MBSGroup )
			end
			
			local id,wp = next(WaypointList("nearest,onmesh,notcontested,samezone"))
			if (id and wp ) then
				MultiBotSend( "3;"..wp.id,MBSGroup )
			end
		end
		
		if ( mc_global.now - mc_multibotmanager.broadcastTmr2 > 1500 ) then
			mc_multibotmanager.broadcastTmr2 = mc_global.now
			-- targetID
			local t = Player:GetTarget()		
			if ( t ~= nil and TableSize(t) > 0 and t.distance < 1500 and t.selectable and t.attackable and t.dead == false) then				
				MultiBotSend( "4;"..t.id,MBSGroup )	
			end			
		end		
	end
end

--connectionstatus 2 = disco/offline , 3 = connected, 4=invitation pending on player
--invitationstatus 1 = not in a party, 2 partyinvite, 4 squadinvite , 5 teaminvite
function mc_multibotmanager.UpdatePartyStatus()
			
	if ( Player:GetRole() == 1 ) then
		-- Invite the others		
		local party = Player:GetParty()	
		if ( TableSize(party) < mc_multibotmanager.membercount()+1 ) then
			-- Not all Members are in our party yet		
			local myname = Player.name			
			local setupparty = Settings.GW2Minion.Party
			
			local idx, pname  = next( setupparty )
			while ( idx ~= nil and pname ~= nil ) do
				if (pname ~= "None" and pname ~= "") then
					
					local found = false
					local index, player  = next( party )
					while ( index ~= nil and player ~= nil and player.name ~= "") do			
						if ( player.name == pname ) then
							found = true
							break -- this player is already in our party
						end
						index, player  = next( party,index )
					end
					
					if ( not found and mc_blacklist.IsBlacklisted(pname) == false) then	
						d("Inviting "..pname)
						dPartyStatus = "Inviting "..pname
						SendChatMsg(GW2.CHATCHANNEL.Say,"/invite "..pname)												
						mc_blacklist.AddBlacklistEntry(GetString("partymember"), idx, pname, mc_global.now + 30000)
						return 
					end
				end
				idx, pname  = next( setupparty,idx )
			end	
			dPartyStatus = "Partymember missing.."			
		else
			dPartyStatus = "Party Complete"			
		end
	
	else
		-- Wait for invitation and accept
		if ( mc_multibotmanager.leadername ~= nil and mc_multibotmanager.leadername ~= "" ) then 
			local party = Player:GetParty()
			if ( TableSize(party) > 0 ) then
				local pname = Player.name
				local index, player  = next( party )
				while ( index ~= nil and player ~= nil ) do	
					if ( player.name == pname and player.name ~= "") then
						-- check if we got a party invite
						if ( player.hasparty == false ) then
							if ( (player.connectstatus == 3 or player.connectstatus == 2 or player.connectstatus == 1) and player.invitestatus == 2 ) then
								d("Accepting Party invitation from "..mc_multibotmanager.leadername)
								SendChatMsg(GW2.CHATCHANNEL.Say,"/join "..mc_multibotmanager.leadername)
								dPartyStatus = "Joining "..mc_multibotmanager.leadername							
								return
							else
								dPartyStatus = "Waiting for invite"
							end
						else
							dPartyStatus = "In a Party"
						end
					end
					index, player  = next( party,index )
				end
			end
		else
			dPartyStatus = "Waiting for leadername"
		end
	end		
end

function mc_multibotmanager.membercount()
	local count = 0
	local partylist = Settings.GW2Minion.Party
	if ( TableSize(partylist) > 0 ) then
		local index, player  = next( partylist )		
		while ( index ~= nil and player ~= nil ) do			
			if (player ~= "None" and player ~= "") then
				count = count + 1
			end
			index, player  = next( partylist,index )
		end	
	end
	return count
end

function mc_multibotmanager.GetPlayerPartyData()	
	local partylist = Player:GetParty()
	if ( TableSize(partylist) > 0 ) then
		local index, player  = next( partylist )		
		while ( index ~= nil and player ~= nil ) do
			if (player.id == Player.id) then
				return player
			end
			index, player  = next( partylist,index )
		end	
	end
	return nil
end


--**********************************************************
-- HandleMultiBotMessages
--**********************************************************
function HandleMultiBotMessages( event, message, channel )	
--d("MBM:" .. tostring(message) .. " chan: " .. tostring(channel))
		
	if (channel == MBSGroup ) then
		
		-- Set role of this client, multibotserver sends this info when a bot enters/leaves the channel
		if ( message:find('[[Leader]]') ~= nil) then
			Player:SetRole(1)
			gRole = "Party Leader"
			if ( gBotMode == GetString("minionmode") ) then
				gBotMode = GetString("grindMode")
				Settings.GW2Minion.gBotMode	= gBotMode
				mc_global.ResetBot()
				ml_task_hub:ClearQueues()
				mc_global.UpdateMode()
			end
		elseif ( message:find('[[Minion]]') ~= nil) then
			Player:SetRole(0)
			gRole = "Party Member"
			gBotMode = GetString("minionmode")
			Settings.GW2Minion.gBotMode	= gBotMode			
			mc_global.ResetBot()
			ml_task_hub:ClearQueues()
			mc_global.UpdateMode()
		end	
		
		if ( gMultiBotEnabled == "1" ) then
			local delimiter = message:find(';')
			if (delimiter ~= nil and delimiter ~= 0) then
				
				local msgID = message:sub(0,delimiter-1)
				local msg = message:sub(delimiter+1)
				if (tonumber(msgID) ~= nil and msg ~= nil ) then
				--d("msgID:" .. msgID)
				--d("msg:" .. msg)
					
					-- Leader sends Minion LeaderName	
					if ( tonumber(msgID) == 1 and msg ~= "" and Player:GetRole() == 0) then
                        mc_multibotmanager.leadername = msg
					
					-- Leader sends Minion his ServerID
					elseif ( tonumber(msgID) == 2 and msg ~= "" and Player:GetRole() == 0) then
                        mc_multibotmanager.leaderserverID = msg
					
					-- Leader sends Minion his Closest Waypoint ID
					elseif ( tonumber(msgID) == 3 and msg ~= "" and Player:GetRole() == 0) then
                        mc_multibotmanager.leaderWPID = msg
					
					-- Leader sends Minions his TargetID to attack
					elseif ( tonumber(msgID) == 4 and tonumber(msg) ~= nil and msg ~= "" and Player:GetRole() == 0) then
						mc_followbot.KilltargetID = msg
					end
				end
			end
		end
	end
end


RegisterEventHandler("MultiBotManager.toggle", mc_multibotmanager.ToggleMenu)
RegisterEventHandler("Module.Initalize",mc_multibotmanager.ModuleInit)
RegisterEventHandler("MULTIBOT.Message",HandleMultiBotMessages)
