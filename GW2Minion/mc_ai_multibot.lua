mc_ai_multibot = inheritsFrom(ml_task)
mc_ai_multibot.name = "MinionMode"

function mc_ai_multibot.Create()
	local newinst = inheritsFrom(mc_ai_multibot)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
            
    return newinst
end

function mc_ai_multibot:Init()

	-- MultiBotReadyCheck
	self:add(ml_element:create( "MultiBotReadyCheck", c_MultiBotReady, e_MultiBotReady, 500 ), self.process_elements)
	
	-- Dead?
	self:add(ml_element:create( "Dead", c_dead_mb, e_dead_mb, 480 ), self.process_elements)
	
	-- Downed
	self:add(ml_element:create( "Downed", c_downed, e_downed, 470 ), self.process_elements)
	
	-- Dont Dive lol
	self:add(ml_element:create( "SwimUP", c_SwimUp, e_SwimUp, 465 ), self.process_elements)
	
	-- AoELooting Characters
	self:add(ml_element:create( "AoELoot", c_AoELoot, e_AoELoot, 460 ), self.process_elements)
	
	-- Partymember Downed/Dead
	self:add(ml_element:create( "Downed", c_memberdown, e_memberdown, 450 ), self.process_elements)
	
	-- Normal Looting
	self:add(ml_element:create( "Looting", c_LootCheck_mb, e_LootCheck, 430 ), self.process_elements)

	-- Deposit Items
	self:add(ml_element:create( "DepositingItems", c_deposit, e_deposit, 420 ), self.process_elements)	
	
	-- Re-Equip Gathering Tools
	self:add(ml_element:create( "EquippingGatherTool", c_GatherToolsCheck, e_GatherToolsCheck, 415 ), self.process_elements)	
	
	-- Quick-Repair & Vendoring (when a vendor is nearby)	
	self:add(ml_element:create( "QuickSellItems", c_quickvendorsell, e_quickvendorsell, 400 ), self.process_elements)
	self:add(ml_element:create( "QuickBuyItems", c_quickbuy, e_quickbuy, 390 ), self.process_elements)
	self:add(ml_element:create( "QuickRepairItems", c_quickrepair, e_quickrepair, 380 ), self.process_elements)
	
	-- Repair & Vendoring
	self:add(ml_element:create( "SellItems", c_vendorsell, e_vendorsell, 370 ), self.process_elements)	
	self:add(ml_element:create( "BuyItems", c_vendorbuy, e_vendorbuy, 360 ), self.process_elements)
	self:add(ml_element:create( "RepairItems", c_vendorrepair, e_vendorrepair, 350 ), self.process_elements)
	
	-- Salvaging
	self:add(ml_element:create( "Salvaging", c_salvage, e_salvage, 340 ), self.process_elements)
	
	-- Follow Leader
	self:add(ml_element:create( "FollowLeader", c_MoveToLeader, e_MoveToLeader, 320 ), self.process_elements)
	
	-- ReviveNPCs
	self:add(ml_element:create( "ReviveNPC", c_reviveNPC_mb, e_reviveNPC, 300 ), self.process_elements)	
	
	-- Gathering
	self:add(ml_element:create( "Gathering", c_gatherTask, e_gatherTask, 280 ), self.process_elements)
	
	-- Finish Enemy
	self:add(ml_element:create( "FinishHim", c_FinishHim, e_FinishHim, 270 ), self.process_elements)
	
	-- Valid Target
	self:add(ml_element:create( "NeedValidTarget", c_NeedValidTarget, e_SetAggroTarget_mb, 260 ), self.process_elements)
		
	-- Get into Combat Range
	self:add(ml_element:create( "MovingIntoCombatRange", c_MoveIntoCombatRange, e_MoveIntoCombatRange, 250 ), self.process_elements)
	
	-- Kill Target
	self:add(ml_element:create( "MovingIntoCombatRange", c_KillTarget, e_KillTarget, 225 ), self.process_elements)
	
end

if ( mc_global.BotModes) then
	mc_global.BotModes[GetString("minionmode")] = mc_ai_multibot
end


------------
c_MultiBotReady = inheritsFrom( ml_cause )
e_MultiBotReady = inheritsFrom( ml_effect )
function c_MultiBotReady:evaluate()
    return ( gMultiBotEnabled == "0" or MultiBotIsConnected() == false or mc_multibotmanager.leadername == "" or TableSize(Player:GetParty()) <=1 )
end
function e_MultiBotReady:execute()
	ml_log("e_MultiBotReady ")
	Player:StopMovement()
	ml_log(false)
end

c_dead_mb = inheritsFrom( ml_cause )
e_dead_mb = inheritsFrom( ml_effect )
c_dead_mb.deadTmr = 0
function c_dead_mb:evaluate()
	if ( Player.dead ) then
		return true
	end
	c_dead_mb.deadTmr = 0
	return false
end
function e_dead_mb:execute()
	ml_log("e_dead_mb")	
	local party = Player:GetParty()
	local pPos = Player.pos
	
	local found = false	
	if ( TableSize(party) > 1 ) then		
		local idx,pmember = next(party)	
		while (idx and pmember) do
			if ( pmember.id ~= 0 ) then
				local char = CharacterList:Get(pmember.id)
				if ( char ) then
					local cPos = char.pos
					if ( cPos and Distance2D ( pPos.x, pPos.y, cPos.x, cPos.y) < 4000 and char.dead == false) then
						found = true
						break
					end
				end
			end
			idx,pmember=next(party,idx)
		end
	end
	
	-- Check for nearby Players who can rezz us
	--if ( found == false ) then
	--	if ( TableSize(CharacterList("nearest,alive,friendly,player,maxdistance=2500"))>0 ) then
	--		found = true
	--	end
	--end
	
	if ( found ) then
		ml_log("Waiting for Players/Partymember to rezz me")
	else	
		if ( c_dead_mb.deadTmr == 0 ) then
			c_dead_mb.deadTmr = mc_global.now
		else
			if ( mc_global.now - c_dead_mb.deadTmr > 3500 ) then
				c_dead_mb.deadTmr = 0
				d( "Dead: Respawn at nearest waypoint " )
				d( Player:RespawnAtClosestWaypoint() )
				mc_global.ResetBot()
			end
		end
	end
end

c_memberdown = inheritsFrom( ml_cause )
e_memberdown = inheritsFrom( ml_effect )
function c_memberdown:evaluate()
	local party = Player:GetParty()
	local pPos = Player.pos
	if ( TableSize(party) >0 ) then
		local idx,pmember = next(party)	
		while (idx and pmember) do
			if ( pmember.id ~= 0 ) then
				local char = CharacterList:Get(pmember.id)
				if ( char ) then
					local cPos = char.pos
					if ( cPos ~= nil and Distance2D ( pPos.x, pPos.y, cPos.x, cPos.y) < 4000 and char.onmesh and (char.downed == true or char.dead == true) and Player.health.percent > 50) then
						return true
					end
				end
			end
			idx,pmember=next(party,idx)
		end
	end
	return false
end
function e_memberdown:execute()
	ml_log("e_memberdown")	
	local party = Player:GetParty()
	local pPos = Player.pos	
	local pchar = nil
	local idx,pmember = next(party)	
	while (idx and pmember) do
		if ( pmember.id ~= 0 ) then
			local char = CharacterList:Get(pmember.id)
			if ( char ) then
				local cPos = char.pos
				if ( cPos and Distance2D ( pPos.x, pPos.y, cPos.x, cPos.y) < 4000 and char.onmesh and (char.downed == true or char.dead == true)) then
					pchar = char
					break
				end
			end
		end
		idx,pmember=next(party,idx)
	end
	
	if ( pchar ) then
		if (not pchar.isInInteractRange) then
			-- MoveIntoInteractRange
			local tPos = pchar.pos
			if ( tPos ) then
				if ( c_DestroyGadget:evaluate() ) then e_DestroyGadget:execute() end
				MoveOnlyStraightForward()
				local navResult = tostring(Player:MoveTo(tPos.x,tPos.y,tPos.z,50,false,true,true))		
				if (tonumber(navResult) < 0) then
					d("e_memberdown.MoveIntoRange result: "..tonumber(navResult))					
				end
				ml_log("MoveToDownedPartyMember..")
				return ml_log(true)
			end
		else
			-- Grab that thing
			Player:StopMovement()
			
			if (Player.profession == 8 ) then -- Necro, leave shroud
				local deathshroud = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_13)
				if ( deathshroud ~= nil and deathshroud.skillID == 10585 and Player:CanCast() and Player:GetCurrentlyCastedSpell() == 17) then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_13)
					mc_global.Wait(500)
					return
				end
			end
					
			local t = Player:GetTarget()
			if ( not t or t.id ~= pchar.id ) then
				Player:SetTarget( pchar.id )
			else				
				Player:Interact( pchar.id )
				ml_log("Rezzing..")
				mc_global.Wait(1000)
				return ml_log(true)
			end
		end
		
	else	
		ml_error("There should be a downed/dead partymember but we cant find him!")
	end
end


c_MoveToLeader = inheritsFrom( ml_cause )
e_MoveToLeader = inheritsFrom( ml_effect )
c_MoveToLeader.nearleader = false
function c_MoveToLeader:evaluate()
	local party = Player:GetParty()
	local pPos = Player.pos	
	
	local idx,pmember = next(party)	
	while (idx and pmember) do
		if ( pmember.name == mc_multibotmanager.leadername) then
		
			if (pmember.id ~= 0) then
				local char = CharacterList:Get(pmember.id)
				if ( char ) then
					local cPos = char.pos
					if ( cPos ) then
											
						if ( c_MoveToLeader.nearleader == false ) then 
							ml_log("e_MoveToLeader ")
							return true
						else 
							if (not Player.inCombat and Distance2D ( pPos.x, pPos.y, cPos.x, cPos.y) > 750) then
								c_MoveToLeader.nearleader = false
								ml_log("e_MoveToLeader ")
								return true
							elseif (Player.inCombat and Distance2D ( pPos.x, pPos.y, cPos.x, cPos.y) > 2750) then
								c_MoveToLeader.nearleader = false
								ml_log("e_MoveToLeader ")
								return true						
							end					
						end					
					end
				else
				
					ml_log("Leader is not in our CharacterList!?")	
				end
			else
				-- Leader is not in our local map / dc / other server
				local pPlayer = mc_multibotmanager.GetPlayerPartyData()
				if (pPlayer ~= nil and pmember.currentserverid ~= pPlayer.currentserverid ) then
					ml_log("Leader is on a different Server!")
					local sID = tonumber(mc_multibotmanager.leaderserverID)
					if ( sID ~= nil and sID > 0 ) then
						local serverlist = {}
						if ( sID > 1000 and sID < 2000 ) then
							serverlist = mc_datamanager.ServersUS
						elseif ( sID > 2000 and sID < 3000 ) then
							serverlist = mc_datamanager.ServersEU
						end	
						if ( TableSize(serverlist) > 0) then
							local i,entry = next ( serverlist)
							while i and entry do
								if ( entry.id == sID ) then
									gGuestServer = entry.name
									SetServer(sID)									
									d("Setting Guestserver: "..(entry.name) .." ID: ".. tostring(entry.id))
									Player:Logout()
									mc_global.Wait(5000)
									break
								end
								i,entry = next ( serverlist,i)
							end
						end
					end
									
				elseif ( pmember.mapid ~= Player:GetLocalMapID()) then
					ml_log("Leader is not in our map! ")
					if ( tonumber(mc_multibotmanager.leaderWPID) ~= nil and tonumber(mc_multibotmanager.leaderWPID) > 0 and Player.inCombat == false and Inventory:GetInventoryMoney() > 500) then
						ml_log(" Using closest Waypoint to get to Leader: ")
						local id,wp = next(WaypointList("nearest,onmesh,notcontested,samezone"))
						if ( id and wp and tonumber(wp.id) == tonumber(mc_multibotmanager.leaderWPID) ) then
							d("Our leader switched maps and we are waiting for new wapointID")
							mc_global.Wait(5000)
						else							
							ml_log(Player:TeleportToWaypoint(tonumber(mc_multibotmanager.leaderWPID)))
							mc_global.Wait(5000)
						end
					end
				
				elseif ( pmember.connectstatus == 1 ) then
					ml_log("Leader has disconnected?!")
				
				else					
					ml_log("Unknown error in finding the leader! ")		
				end
			end
			return false
		end
		idx,pmember=next(party,idx)
	end
	return false
end
e_MoveToLeader.ldist = math.random(150,600)
e_MoveToLeader.tmr = 0
e_MoveToLeader.thresh = 2000
e_MoveToLeader.throttle = 1000
function e_MoveToLeader:execute()	
	local party = Player:GetParty()
	local pPos = Player.pos	
	
	local idx,pmember = next(party)	
	while (idx and pmember) do
		if ( pmember.id ~= 0 and pmember.name == mc_multibotmanager.leadername) then
			local char = CharacterList:Get(pmember.id)
			if ( char ) then
				local cPos = char.pos
				if ( cPos ) then
					
					if ( Distance2D ( pPos.x, pPos.y, cPos.x, cPos.y) > e_MoveToLeader.ldist ) then
						local nPos = NavigationManager:GetClosestPointOnMesh(cPos)
						local navResult = 0
						if ( c_DestroyGadget:evaluate() ) then e_DestroyGadget:execute() end
						MoveOnlyStraightForward()
						if (nPos) then						
							navResult = tostring(Player:MoveTo(nPos.x,nPos.y,nPos.z,150,false,true,true))		
						end
						if ( tonumber(navResult) < 0 ) then
							navResult = tostring(Player:MoveTo(cPos.x,cPos.y,cPos.z,150,false,true,true))
						end
						
						if (tonumber(navResult) < 0 and tonumber(navResult) ~= -3) then					
							d("e_MoveToLeader.MoveToLeader result: "..tonumber(navResult))					
						end
						if ( mc_global.now - e_MoveToLeader.tmr > e_MoveToLeader.thresh ) then
							e_MoveToLeader.tmr = mc_global.now
							e_MoveToLeader.thresh = math.random(1000,3000)
							mc_skillmanager.HealMe()
						end	
					else
						d("Arrived at Leader..")
						if ( char.movementstate == 3 ) then
							e_MoveToLeader.ldist = math.random(150,600)
						else
							e_MoveToLeader.ldist = math.random(65,250)
						end
						Player:StopMovement()
						c_MoveToLeader.nearleader = true
					end					
				end
			end
			return false
		end
		idx,pmember=next(party,idx)
	end
	return ml_log(false)
end

c_LootCheck_mb = inheritsFrom( ml_cause )
function c_LootCheck_mb:evaluate()
    return Inventory.freeSlotCount > 0 and TableSize(CharacterList("nearest,lootable,onmesh,maxdistance=1500")) > 0
end

c_reviveNPC_mb = inheritsFrom( ml_cause )
function c_reviveNPC_mb:evaluate()
    return (gRevive == "1" and not Player.inCombat and TableSize(CharacterList("shortestpath,selectable,interactable,dead,friendly,npc,onmesh,maxdistance=1500,exclude="..mc_blacklist.GetExcludeString(GetString("monsters")))) > 0)
end

c_Gathering_mb = inheritsFrom( ml_cause )
c_Gathering_mb.throttle = 2500
function c_Gathering_mb:evaluate()
	if ( gGather == "1" and c_Gathering.tPos == nil ) then
		local _,gadget = next(GadgetList("onmesh,shortestpath,gatherable,maxpathdistance=2000"))
		if (gadget) then
			c_Gathering.tPos = gadget.pos
		end
	end
	
	if ( gGather == "1" and Inventory.freeSlotCount > 0 and c_Gathering.tPos ~= nil and TableSize(c_Gathering.tPos) > 0 ) then
		local pPos = Player.pos
		if ( Distance3D( pPos.x, pPos.y, pPos.z, c_Gathering.tPos.x, c_Gathering.tPos.y, c_Gathering.tPos.z) < 3000 ) then
			return true
		end
	end
	c_Gathering.tPos = nil
	return false
end


e_SetAggroTarget_mb = inheritsFrom( ml_effect )
function e_SetAggroTarget_mb:execute()
	ml_log("e_SetAggroTarget")
		
	local party = Player:GetParty()	
	local idx,pmember = next(party)	
	while (idx and pmember) do
		if ( pmember.id ~= 0 and pmember.name == mc_multibotmanager.leadername) then
			local char = CharacterList:Get(pmember.id)
			if ( char ) then
			
				-- nearest to leader first	
				local TList = nil 
				if (not Player.inCombat) then
					TList = CharacterList("nearest,attackable,alive,aggro,onmesh,distanceto="..char.id..",maxdistance=750")
				else
					TList = CharacterList("nearest,attackable,alive,aggro,onmesh,distanceto="..char.id..",maxdistance=1750")
				end
				if ( TableSize( TList ) > 0 ) then
					local id, E  = next( TList )
					if ( id ~= nil and id ~= 0 and E ~= nil ) then
						d("New Aggro Target ID:"..tostring(id))
						Player:SetTarget(id)
						return ml_log(true)	
					end		
				end
			end
			break
		end
		idx,pmember = next(party,idx)	
	end
	
	-- lowesthealth in CombatRange first	
	local TList = ( CharacterList("lowesthealth,attackable,alive,aggro,onmesh,maxdistance="..ml_global_information.AttackRange) )
	if ( TableSize( TList ) > 0 ) then
		local id, E  = next( TList )
		if ( id ~= nil and id ~= 0 and E ~= nil ) then
			--d("New Aggro Target: "..(E.name).." ID:"..tostring(id))
			Player:SetTarget(id)
			return ml_log(true)	
		end		
	end
		
	-- Then nearest Aggro Target
	TList = ( CharacterList("attackable,alive,aggro,nearest,onmesh") )
	if ( TableSize( TList ) > 0 ) then
		local id, E  = next( TList )
		if ( id ~= nil and id ~= 0 and E ~= nil ) then
			--d("New Aggro Target: "..(E.name).." ID:"..tostring(id))
			Player:SetTarget(id)
			return ml_log(true)	
		end		
	end
	
	return ml_log(false)
end