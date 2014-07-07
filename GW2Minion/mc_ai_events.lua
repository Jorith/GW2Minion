-- Handles Events
mc_ai_events = {}

mc_ai_event = inheritsFrom(ml_task)
mc_ai_event.name = "DoEvent"

function mc_ai_event.Create()
	local newinst = inheritsFrom(mc_ai_event)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.eventID = nil
	newinst.maxduration = 900000 --15min
	newinst.curduration = 0
    return newinst
end

-- special Causes for Events, since the char should stay near the event and dont wander off
function mc_ai_event:Init()
	d("mc_ai_eventINIT")
	-- Dead?
	self:add(ml_element:create( "Dead", c_dead, e_dead, 300 ), self.process_elements)
	
	-- Downed
	self:add(ml_element:create( "Downed", c_downed, e_downed, 280 ), self.process_elements)
	
	-- AoELooting Characters
	self:add(ml_element:create( "AoELoot", c_AoELoot, e_AoELoot, 260 ), self.process_elements)
		
	-- AoELooting Gadgets/Chests needed ?
	
	
	-- Revive PartyMember
	
	
	-- Move InRange of Event
	self:add(ml_element:create( "MovingToEvent", c_MoveInEventRange, e_MoveInEventRange, 220 ), self.process_elements)
			
	-- Aggro
	self:add(ml_element:create( "Aggro", c_Aggro, e_Aggro, 160 ), self.process_elements) --reactive queue
		
	-- Normal Chests	
	self:add(ml_element:create( "LootingChest", c_event_LootChests, e_LootChests, 155 ), self.process_elements)
	
	-- Resting
	self:add(ml_element:create( "Resting", c_resting, e_resting, 145 ), self.process_elements)	

	-- Normal Looting
	self:add(ml_element:create( "Looting", c_event_LootCheck, e_Loot, 130 ), self.process_elements)

	-- Deposit Items
	self:add(ml_element:create( "DepositingItems", c_deposit, e_deposit, 120 ), self.process_elements)	
			
	-- Salvaging
	self:add(ml_element:create( "Salvaging", c_salvage, e_salvage, 75 ), self.process_elements)

	-- ReviveNPCs
	self:add(ml_element:create( "ReviveNPC", c_event_reviveNPC, e_reviveNPC, 70 ), self.process_elements)	
	
	-- Do EventObjectives
	self:add(ml_element:create( "DoEventObjectives", c_DoEventObjectives, e_DoEventObjectives, 60 ), self.process_elements)	
				
	
	self:AddTaskCheckCEs()
end
function mc_ai_event:task_complete_eval()
	-- Event timer check
	if ( ml_task_hub:CurrentTask().curduration == 0 ) then 
		ml_task_hub:CurrentTask().curduration = mc_global.now
	elseif ( mc_global.now - ml_task_hub:CurrentTask().curduration > ml_task_hub:CurrentTask().maxduration ) then
		d("Event maxduration (15 minutes) have passed...moving on")
		mc_blacklist.AddBlacklistEntry(GetString("event"), ml_task_hub:CurrentTask().eventID, "Event", mc_global.now + 1800000)
		return true		
	end
	
	-- Event gone
	local eID = ml_task_hub:CurrentTask().eventID
	if ( eID == nil or TableSize(MapMarkerList("nearest,onmesh,eventID="..eID..",exclude_eventid="..mc_blacklist.GetExcludeString(GetString("event"))))==0 ) then
		c_MoveInEventRange.range = 1350
		c_MoveInEventRange.reached = false
		d("Event Done..")
		if ( c_MoveInEventRange.reached == false and c_MoveInEventRange.movingtoevent == true and Player:IsMoving() and c_MoveInEventRange.lastdist >= 3500)  then
			-- should hopefully prevent the back n forth on the corner of where an event is visible
			
		else
			return true
		end
	end
	return false
end

function mc_ai_event:task_complete_execute()
   self.completed = true
end


-- For adding a doEvent Subtask
c_doEvents = inheritsFrom( ml_cause )
e_doEvents = inheritsFrom( ml_effect )
function c_doEvents:evaluate()	
	if ( gDoEvents == "0" ) then return false end
	local evList = MapMarkerList("nearest,isevent,onmesh,worldmarkertype="..mc_global.WorldMarkerType..",exclude_eventid="..mc_blacklist.GetExcludeString(GetString("event")))
	local i,e = next(evList)
	if ( i and e ) then
		local evi = e.eventinfo
		if ( evi and evi.level <= Player.level + 3 ) then
			return true
		end
	end
	return false
end
function e_doEvents:execute()
	ml_log("e_doEvents")
	local evList = MapMarkerList("nearest,isevent,onmesh,worldmarkertype="..mc_global.WorldMarkerType..",exclude_eventid="..mc_blacklist.GetExcludeString(GetString("event")))
	local i,e = next(evList)
	if ( i and e ) then
		local evi = e.eventinfo
		if ( evi and evi.level <= Player.level + 3 ) then
			local newTask = mc_ai_event.Create()
			newTask.eventID = e.eventID
			ml_task_hub:CurrentTask():AddSubTask(newTask)
			return ml_log(true)
		end
	end
	return ml_log(false)
end


c_MoveInEventRange = inheritsFrom( ml_cause )
e_MoveInEventRange = inheritsFrom( ml_effect )
c_MoveInEventRange.reached = false
c_MoveInEventRange.range = 2500 -- gets changed depending what objective we have
c_MoveInEventRange.lastdist = 3500
c_MoveInEventRange.movingtoevent = false
function c_MoveInEventRange:evaluate()
	local eID = ml_task_hub:CurrentTask().eventID
	if ( tonumber(eID)~=nil ) then
		local evList = MapMarkerList("nearest,onmesh,eventID="..eID..",exclude_eventid="..mc_blacklist.GetExcludeString(GetString("event")))
		local i,e = next(evList)
		if ( i and e ) then
			if ( c_MoveInEventRange.reached == false) then
				return true
			else
				-- Check if we moved too far away from the event
				local pPos = Player.pos
				local ePos = e.pos
				if (pPos) then
					c_MoveInEventRange.lastdist = Distance2D ( pPos.x, pPos.y, ePos.x, ePos.y)
					if ( c_MoveInEventRange.lastdist > c_MoveInEventRange.range ) then
						return true					
					end
				end			
			end
		end
	end
	return false
end
e_MoveInEventRange.tmr = 0
e_MoveInEventRange.threshold = 2000
function e_MoveInEventRange:execute()
	ml_log("e_MoveInEventRange")
	local eID = ml_task_hub:CurrentTask().eventID
	if ( tonumber(eID)~=nil ) then
		local evList = MapMarkerList("nearest,onmesh,eventID="..eID..",exclude_eventid="..mc_blacklist.GetExcludeString(GetString("event")))
		local i,e = next(evList)
		if ( i and e ) then
			local pPos = Player.pos
			local ePos = e.pos
			if (pPos and ePos) then
				c_MoveInEventRange.lastdist = Distance2D( pPos.x, pPos.y, ePos.x, ePos.y)
				ml_log(tostring(math.floor(c_MoveInEventRange.lastdist)))
				if ( c_MoveInEventRange.reached == false) then
					-- 1st time get into event range
					if ( c_MoveInEventRange.lastdist > 350 ) then
						if ( c_DestroyGadget:evaluate() ) then e_DestroyGadget:execute() end
						MoveOnlyStraightForward()
						local navResult = tostring(Player:MoveTo(ePos.x,ePos.y,ePos.z,125,false,false,true))		
						if (tonumber(navResult) < 0) then					
							d("mc_ai_events.MoveInEventRange result: "..tonumber(navResult))					
						else
							c_MoveInEventRange.movingtoevent = true
						end
						
						if ( mc_global.now - e_MoveInEventRange.tmr > e_MoveInEventRange.threshold ) then
							e_MoveInEventRange.tmr = mc_global.now
							e_MoveInEventRange.threshold = math.random(1000,5000)
							mc_skillmanager.HealMe()
						end	
						
						return ml_log(true)
					else
						c_MoveInEventRange.movingtoevent = false
						c_MoveInEventRange.reached = true
					end
					
				else
					-- Check if we moved too far away from the event we are in
					if ( c_MoveInEventRange.lastdist > c_MoveInEventRange.range ) then
						if ( c_DestroyGadget:evaluate() ) then e_DestroyGadget:execute() end
						MoveOnlyStraightForward()
						local navResult = tostring(Player:MoveTo(ePos.x,ePos.y,ePos.z,125,false,false,true))		
						if (tonumber(navResult) < 0) then					
							d("mc_ai_events.MoveBackIntoEventRange result: "..tonumber(navResult))					
						end
						
						if ( mc_global.now - e_MoveInEventRange.tmr > e_MoveInEventRange.threshold ) then
							e_MoveInEventRange.tmr = mc_global.now
							e_MoveInEventRange.threshold = math.random(1000,5000)
							mc_skillmanager.HealMe()
						end	
						
						c_MoveInEventRange.reached = false
						return ml_log(true)
					end
				end
			end
		end
	end
	return ml_log(false)
end


c_DoEventObjectives = inheritsFrom( ml_cause )
e_DoEventObjectives = inheritsFrom( ml_effect )
function c_DoEventObjectives:evaluate()
	local eID = ml_task_hub:CurrentTask().eventID
	if ( tonumber(eID)~=nil ) then
		local evList = MapMarkerList("nearest,onmesh,eventID="..eID..",exclude_eventid="..mc_blacklist.GetExcludeString(GetString("event")))
		if ( TableSize(evList)>0) then
			local i,e = next(evList)
			if ( i and e ) then
				return true		
			end
		end
	end
	return false
end
function e_DoEventObjectives:execute()
	ml_log("e_DoEventObjectives")
	local eID = ml_task_hub:CurrentTask().eventID
	if ( tonumber(eID)~=nil ) then
		local evList = MapMarkerList("nearest,onmesh,eventID="..eID..",exclude_eventid="..mc_blacklist.GetExcludeString(GetString("event")))
		if ( TableSize(evList)>0) then
			local i,e = next(evList)
			if ( i and e ) then
			
				--pick out the first objective
				local evoList = e.eventobjectivelist				
				if ( evoList ) then
					local oid,obj = next(evoList)
					if ( oid and obj ) then
						local objType = obj.type
						-- Add seperate SubTasks here...if you want lol
						if ( objType == GW2.OBJECTIVETYPE.BreakMoral ) then 
						ml_log("OBJECTIVETYPE.BreakMoral")
						c_MoveInEventRange.range = 3000
						
						elseif ( objType == GW2.OBJECTIVETYPE.CaptureLocation ) then
						ml_log("OBJECTIVETYPE.CaptureLocation")
						c_MoveInEventRange.range = 2500
						
						elseif ( objType == GW2.OBJECTIVETYPE.CollectItems ) then 
						ml_log("OBJECTIVETYPE.CollectItems")
						c_MoveInEventRange.range = 4000
						
						d("Bot cant handle CollectItems-Events, blacklisting it..")
						mc_blacklist.AddBlacklistEntry(GetString("event"), e.eventID, "CollectItems", mc_global.now + 1800000)
						ml_task_hub:CurrentTask().completed = true
						
						elseif ( objType == GW2.OBJECTIVETYPE.Counter ) then 
						ml_log("OBJECTIVETYPE.Counter")
						-- obj.value1 = 0 when multiple enemies, when 1 enemy then it is the ID of that
						-- obj.value2 = countermax
						-- obj.value4 = currentcount
						c_MoveInEventRange.range = 3000
						-- Kill Main Boss
						local target = nil						
						if ( obj.value1 and obj.value1 ~= 0 ) then
							target = CharacterList:Get(obj.value1)
							if ( not target ) then
								target = GadgetList:Get(obj.value1)
							end
							if ( target ) then
								local t = Player:GetTarget()
								if ( t and t.id ~= target.id ) then
									return Player:SetTarget(t.id)
								end
							end
						end
						return ml_log(true)
						elseif ( objType == GW2.OBJECTIVETYPE.KillCount ) then 
						ml_log("OBJECTIVETYPE.KillCount")
						-- value 4 = kills left ?
						c_MoveInEventRange.range = 3000
						
						elseif ( objType == GW2.OBJECTIVETYPE.Cull ) then 
						ml_log("OBJECTIVETYPE.Cull")
						-- valie 1 and 2 , possibly scaling values ?
						-- value 4 = amount of objects/enemies remaining 
						c_MoveInEventRange.range = 3000
						
						elseif ( objType == GW2.OBJECTIVETYPE.DefendGadget ) then 
						ml_log("OBJECTIVETYPE.DefendGadget")
						c_MoveInEventRange.range = 2500
						
						elseif ( objType == GW2.OBJECTIVETYPE.Escort ) then 
						c_MoveInEventRange.range = 1500
						ml_log("OBJECTIVETYPE.Escort")
						--Value 4 = ID to escort
						if ( obj.value4 and obj.value4 ~= 0 ) then
							target = CharacterList:Get(obj.value4)
							if ( not target ) then
								target = GadgetList:Get(obj.value4)
							end
							if ( target ) then
								-- Make sure our Target is alive, else revive
								if ( (target.downed or target.dead) and Player.health.percent > 50 and target.distance < 3000) then
									if (not target.isInInteractRange) then
										local tPos = target.pos
										if ( tPos ) then
											Player:MoveTo(tPos.x,tPos.y,tPos.z,130,false,true,true)
											return true
										end
									else
										Player:StopMovement()
										local t = Player:GetTarget()
										if ( not t or t.id ~= id ) then
											Player:SetTarget( id )
										else
											if ( Player:GetCurrentlyCastedSpell() == 17 ) then								
												Player:Interact( id )
												ml_log("Reviving..")
												mc_global.Wait(1000)
												return true
											end	
										end
									end
								end
							end
						end
						
						elseif ( objType == GW2.OBJECTIVETYPE.EventStatus ) then 
						ml_log("OBJECTIVETYPE.EventStatus")
						c_MoveInEventRange.range = 2500
						
						elseif ( objType == GW2.OBJECTIVETYPE.InteractWithGadget ) then 
						ml_log("OBJECTIVETYPE.InteractWithGadget")
						c_MoveInEventRange.range = 3500
						
						elseif ( objType == GW2.OBJECTIVETYPE.Intimidate ) then 
						ml_log("OBJECTIVETYPE.Intimidate")
						c_MoveInEventRange.range = 3500
						-- value1 == ID of enemy to "intimidate" if there is only 1 
						-- value2 = amount of enemies to intimidate (?)
						elseif ( objType == GW2.OBJECTIVETYPE.IntimidateScaled ) then 
						ml_log("OBJECTIVETYPE.IntimidateScaled")
						c_MoveInEventRange.range = 3500
						
						elseif ( objType == GW2.OBJECTIVETYPE.RepairGadget ) then 
						ml_log("OBJECTIVETYPE.RepairGadget")
						c_MoveInEventRange.range = 3500
						
						elseif ( objType == GW2.OBJECTIVETYPE.Timer ) then 
						ml_log("OBJECTIVETYPE.Timer")
						c_MoveInEventRange.range = 3500
						
						-- value2 = current timer (counting down from value3 to 0 in ms)
						-- value3 = start timer value 
						elseif ( objType == GW2.OBJECTIVETYPE.Tripwire ) then 
						ml_log("OBJECTIVETYPE.Tripwire")
						c_MoveInEventRange.range = 2500
						
						elseif ( objType == GW2.OBJECTIVETYPE.WvwHold ) then 
						ml_log("OBJECTIVETYPE.WvwHold")
						c_MoveInEventRange.range = 2500
						
						elseif ( objType == GW2.OBJECTIVETYPE.WvwOrbResetTimer ) then 
						ml_log("OBJECTIVETYPE.WvwOrbResetTimer")
						c_MoveInEventRange.range = 4500
						
						elseif ( objType == GW2.OBJECTIVETYPE.WvwUpgrade ) then 
						ml_log("OBJECTIVETYPE.WvwUpgrade")
						c_MoveInEventRange.range = 4500
						
						else
							ml_error("Unhandled EventType !!!! : "..tostring(objType))
							d("Bot cant handle Events, blacklisting it..")
							mc_blacklist.AddBlacklistEntry(GetString("event"), e.eventID, "CollectItems", mc_global.now + 1800000)
							ml_task_hub:CurrentTask().completed = true
						end
					end						
				end
			end
		end
	end
	
	--
							-- KillKillKill lol
						if ( c_NeedValidTargetEvent:evaluate() ) then 
							e_SearchTargetEvent:execute()
						else
							if ( c_MoveIntoCombatRange:evaluate() ) then
								e_MoveIntoCombatRange:execute()
							else
								e_KillTarget:execute()
							end
						end
	
	return ml_log(false)
end

c_NeedValidTargetEvent = inheritsFrom( ml_cause )
function c_NeedValidTargetEvent:evaluate()
	local target = Player:GetTarget()
	if ( TableSize( target ) > 0 ) then	
		--d("NeedValidTarget "..tostring(not target.alive and not target.attackable and not target.onmesh))
		if (Player.swimming == 0 and not target.alive or not target.attackable or not target.onmesh or target.pathdistance > c_MoveInEventRange.range) then
			return true
		else
			e_SearchTargetEvent.Tmr = 0
			return false
		end
	end	
	return true
end
e_SearchTargetEvent = inheritsFrom( ml_effect )
e_SearchTargetEvent.lastID = 0
e_SearchTargetEvent.count = 0
e_SearchTargetEvent.Tmr = 0
e_SearchTargetEvent.PathThrottle = 0
function e_SearchTargetEvent:execute()
	ml_log("e_SearchTargetEvent")
	-- Weakest Aggro in CombatRange first	
	local TList = ( CharacterList("lowesthealth,attackable,alive,aggro,onmesh,maxdistance="..ml_global_information.AttackRange) )
	if ( TableSize( TList ) > 0 ) then
		local id, E  = next( TList )
		if ( id ~= nil and id ~= 0 and E ~= nil ) then
			--d("Found Aggro Target: "..(E.name).." ID:"..tostring(id))
			e_SearchTargetEvent.Tmr = 0
			return ml_log(Player:SetTarget(id))			
		end		
	end
	
	-- Then nearest attackable Gadget
	local TList = ( GadgetList("nearest,attackable,alive,onmesh,maxdistance="..ml_global_information.AttackRange..",exclude_contentid="..mc_blacklist.GetExcludeString(GetString("monsters"))) )
	if ( TableSize( TList ) > 0 ) then
		local id, E  = next( TList )
		if ( id ~= nil and id ~= 0 and E ~= nil ) then
			d("Found Gadget Target: "..(E.name).." ID:"..tostring(id))
			e_SearchTargetEvent.Tmr = 0
			return ml_log(Player:SetTarget(id))			
		end		
	end
	
	-- Then nearest attackable Target
	if ( mc_global.now - e_SearchTargetEvent.PathThrottle > 2500 ) then
		e_SearchTargetEvent.PathThrottle = mc_global.now
		TList = ( CharacterList("attackable,alive,shortestpath,onmesh,maxpathdistance="..c_MoveInEventRange.range..",exclude_contentid="..mc_blacklist.GetExcludeString(GetString("monsters"))))
		if ( TableSize( TList ) > 0 ) then
			local id, E  = next( TList )
			if ( id ~= nil and id ~= 0 and E ~= nil ) then
				d("New Target ID"..tostring(id))
				
				-- Blacklist if we cant select it..happens sometimes when it is outside our select range
				if (e_SearchTargetEvent.lastID == id ) then
					e_SearchTargetEvent.count = e_SearchTargetEvent.count+1
					if ( e_SearchTargetEvent.count > 10 ) then
						e_SearchTargetEvent.count = 0
						e_SearchTargetEvent.lastID = 0
						mc_blacklist.AddBlacklistEntry(GetString("monsters"), E.contentID, E.name, mc_global.now + 60000)
						d("Seems we cant select/target/reach our target, blacklisting it for 60seconds..")
					end
				else
					e_SearchTargetEvent.lastID = id
					e_SearchTargetEvent.count = 0
				end
				e_SearchTargetEvent.Tmr = 0
				return ml_log(Player:SetTarget(id))
			end		
		end
	end
	-- Seems there is nothing to attack nearby...
	if ( e_SearchTargetEvent.Tmr == 0 ) then 
		e_SearchTargetEvent.Tmr = mc_global.now 
	elseif ( mc_global.now - e_SearchTargetEvent.Tmr > 60000 ) then
		d("Seems there is a problem with the Event, nothing to attack in the last 60sec, blacklisting it..")
		mc_blacklist.AddBlacklistEntry(GetString("event"), ml_task_hub:CurrentTask().eventID, "Event", mc_global.now + 1800000)
		ml_task_hub:CurrentTask().completed = true
		e_SearchTargetEvent.Tmr = 0
	end
	
	return ml_log(false)
end


-- Special Causes for Events, this is needed to not make the char wander away
c_event_LootChests = inheritsFrom( ml_cause )
function c_event_LootChests:evaluate()
	if ( Inventory.freeSlotCount > 0 ) then
		local eID = ml_task_hub:CurrentTask().eventID
		if ( tonumber(eID)~=nil ) then
			local evList = MapMarkerList("nearest,onmesh,eventID="..eID..",exclude_eventid="..mc_blacklist.GetExcludeString(GetString("event")))
			local i,e = next(evList)
			if ( i and e ) then
				local ePos = e.pos
				if (ePos) then
				
					local GList = GadgetList("onmesh,lootable,maxdistance=4000")
					if ( TableSize( GList ) > 0 ) then			
						local index, LT = next( GList )
						while ( index ~= nil and LT~=nil ) do
							local gPos = LT.pos
							if ( LT.selectable and (LT.contentID == 17698 or LT.contentID == 198260 or LT.contentID == 232192 or LT.contentID == 232193 or LT.contentID == 232194 or LT.contentID == 262863 or LT.contentID == 236384) 
								and gPos~= nil and Distance2D( gPos.x, gPos.y, ePos.x, ePos.y) < c_MoveInEventRange.range) then --or LT.contentID == 41638
								--d("CHEST: "..tostring(LT.name).." "..tostring(LT.distance).." "..tostring(LT.contentID).." "..tostring(LT.lootable).." "..tostring(index))
								return true
							end
							index, LT = next( GList,index )
						end
					end
				end
			end
		end
	end
	return false
end

c_event_LootCheck = inheritsFrom( ml_cause )
function c_event_LootCheck:evaluate()
	if ( Inventory.freeSlotCount > 0 ) then
		local LList = CharacterList("shortestpath,lootable,onmesh")
		if ( TableSize(LList) > 0 ) then
			local eID = ml_task_hub:CurrentTask().eventID
			if ( tonumber(eID)~=nil ) then
				local evList = MapMarkerList("nearest,onmesh,eventID="..eID..",exclude_eventid="..mc_blacklist.GetExcludeString(GetString("event")))
				local i,e = next(evList)
				if ( i and e ) then
					local ePos = e.pos
					if (ePos) then
					
						local id, entity = next( LList )
						while ( id ~= nil and entity~=nil ) do
							local gPos = entity.pos
							if ( gPos ) then 
								if ( c_MoveInEventRange.range < 1200 ) then
									if ( Distance2D( gPos.x, gPos.y, ePos.x, ePos.y) < 1500) then
										return true
									end
								else
									if ( Distance2D( gPos.x, gPos.y, ePos.x, ePos.y) < c_MoveInEventRange.range) then
										return true
									end
								end
							end
							id, entity = next( LList,id )
						end
					end
				end
			end
		end
	end
	return false
end

c_event_reviveNPC = inheritsFrom( ml_cause )
function c_event_reviveNPC:evaluate()
	if ( Player.inCombat == false ) then
		local CList = CharacterList("shortestpath,selectable,interactable,dead,friendly,npc,onmesh,maxdistance=2500")
		if ( TableSize(CList) > 0 ) then
			local eID = ml_task_hub:CurrentTask().eventID
			if ( tonumber(eID)~=nil ) then
				local evList = MapMarkerList("nearest,onmesh,eventID="..eID..",exclude_eventid="..mc_blacklist.GetExcludeString(GetString("event")))
				local i,e = next(evList)
				if ( i and e ) then
					local ePos = e.pos
					if (ePos) then
					
						local id, entity = next( CList )
						while ( id ~= nil and entity~=nil ) do
							local gPos = entity.pos
							if ( gPos ) then 
								if ( c_MoveInEventRange.range < 1200 ) then
									if ( Distance2D( gPos.x, gPos.y, ePos.x, ePos.y) < 1500) then
										return true
									end
								else
									if ( Distance2D( gPos.x, gPos.y, ePos.x, ePos.y) < c_MoveInEventRange.range) then
										return true
									end
								end
							end
							id, entity = next( CList,id )
						end
					end
				end
			end
		end
	end
	return false
end