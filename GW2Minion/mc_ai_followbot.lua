mc_followbot = {}
mc_followbot.lasttick = 0
mc_followbot.targetname = ""
mc_followbot.targetID = 0
mc_followbot.targetInParty = false
mc_followbot.KilltargetID = 0
mc_followbot.targetPath = {} -- holds positions of the target we follow


function mc_followbot.ModuleInit( )

 	if ( Settings.GW2Minion.mc_followbot_targetname == nil ) then
		Settings.GW2Minion.mc_followbot_targetname = ""
	end
	if ( Settings.GW2Minion.mc_followbot_targetID == nil ) then
		Settings.GW2Minion.mc_followbot_targetID = 0
	end
	GUI_NewField(mc_global.window.name,"FollowPathSize","gtargetPathSize",GetString("followmode"))
	GUI_NewField(mc_global.window.name,GetString("followtarget"),"gFollowTarget",GetString("followmode"))
	GUI_NewButton(mc_global.window.name,GetString("followtarget"),"mc_followbot.FollowTarget",GetString("followmode"))
	RegisterEventHandler("mc_followbot.FollowTarget", mc_followbot.SetFollowTarget)	
	
	gFollowTarget = Settings.GW2Minion.mc_followbot_targetname.."("..tostring(Settings.GW2Minion.mc_followbot_targetID)..")"
	mc_followbot.targetname = Settings.GW2Minion.mc_followbot_targetname
	mc_followbot.targetID = Settings.GW2Minion.mc_followbot_targetID
end
RegisterEventHandler("Module.Initalize",mc_followbot.ModuleInit)

-- Sets the Target to Follow/Monitor
function mc_followbot.SetFollowTarget()
	local t = Player:GetTarget()
	if ( t ) then
		mc_followbot.targetname = t.name
		Settings.GW2Minion.mc_followbot_targetname = mc_followbot.targetname
		mc_followbot.targetID = t.id
		Settings.GW2Minion.mc_followbot_targetID = mc_followbot.targetID
		gFollowTarget = t.name.."("..tostring(t.id)..")"
	end
end

function mc_followbot.OnUpdate( tick )	
	if ( gBotMode == GetString("followmode") and tick - mc_followbot.lasttick > 250 ) then
		mc_followbot.lasttick = tick
		if ( mc_followbot.targetID ~= 0 ) then
			local target = CharacterList:Get(mc_followbot.targetID)
			if ( TableSize(target)>0 ) then
				local mstate = target.movementstate
				local tpos = target.pos					
				
				-- UPDATE NAVPATH
				local pSize = TableSize(mc_followbot.targetPath)				
				if ( pSize > 0 ) then
					-- Extend existing path
					local pPos = Player.pos
					local dist = Distance3D( tpos.x, tpos.y, tpos.z, mc_followbot.targetPath[pSize].pos.x ,mc_followbot.targetPath[pSize].pos.y , mc_followbot.targetPath[pSize].pos.z)
					if ( dist < 500 and dist > 120 ) then
						table.insert(mc_followbot.targetPath, { pos = { x=tpos.x, y=tpos.y, z=tpos.z } , flag = mstate })
					end
					
				else
					-- Start new path
					local pPos = Player.pos
					local dist = Distance3D( pPos.x, pPos.y, pPos.z, tpos.x, tpos.y, tpos.z)
					if ( dist < 1500 and target.los == true or dist < 500 ) then
						table.insert(mc_followbot.targetPath, { pos = { x=tpos.x, y=tpos.y, z=tpos.z } , flag = mstate })
					else
						ml_log("Target_To_Follow_Is_out_of_Followrange")
					end
				end
				
				-- OPTIMIZE NAVPATH by removing crossing paths etc
				if ( TableSize(mc_followbot.targetPath) > 0 ) then
					local optpath = {}
					local idx = 1
					local pPos = Player.pos
										
					-- get closest startpoint to player
					local shortestdist = 450
					if ( target.los == true ) then shortestdist = 1500 end
						
					for i = 1, TableSize(mc_followbot.targetPath), 1 do
						local dist = Distance3D( pPos.x, pPos.y, pPos.z, mc_followbot.targetPath[i].pos.x, mc_followbot.targetPath[i].pos.y, mc_followbot.targetPath[i].pos.z)
						if ( dist < shortestdist ) then
							shortestdist = dist
							idx = i
						end						
					end					
					-- remove every useless node from start to idx
					if ( idx > 1 ) then
						for i = idx, TableSize(mc_followbot.targetPath), 1 do
							table.insert(optpath,mc_followbot.targetPath[idx])
						end
						mc_followbot.targetPath = deepcopy(optpath)
					end					
					
					-- shorten path by removing "crossings"										
					if ( TableSize(mc_followbot.targetPath) > 2 ) then
						optpath = {}
						local optimized = false
						for i = 1, TableSize(mc_followbot.targetPath)-2, 1 do
							for k = i+2, TableSize(mc_followbot.targetPath), 1 do
								local dist = Distance3D( mc_followbot.targetPath[i].pos.x ,mc_followbot.targetPath[i].pos.y , mc_followbot.targetPath[i].pos.z, mc_followbot.targetPath[k].pos.x ,mc_followbot.targetPath[k].pos.y , mc_followbot.targetPath[k].pos.z)
								
								if ( dist < 110 ) then
									-- we can shortcut our path here
									-- add start nodes till shortening point
									for j = 1, i, 1 do
										table.insert(optpath,mc_followbot.targetPath[j])
									end
									-- add last points
									for j = k, TableSize(mc_followbot.targetPath), 1 do
										table.insert(optpath,mc_followbot.targetPath[k])
									end
									mc_followbot.targetPath = deepcopy(optpath)
									optimized = true
									break
								end
							end
							if ( optimized == true ) then
								break
							end
						end
					end
				end
				
				-- NAVIGATE
				gtargetPathSize = TableSize(mc_followbot.targetPath)
				
			else
				ml_log("Target_To_Follow_Is_not_Nearby!!")
				mc_followbot.targetPath = {}
			end
		end	
	end
end


-- Task
mc_ai_followbot = inheritsFrom(ml_task)
mc_ai_followbot.name = "MinionFollowMode"
function mc_ai_followbot.Create()
	local newinst = inheritsFrom(mc_ai_followbot)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
            
    return newinst
end

function mc_ai_followbot:Init()

	-- MultiBotReadyCheck
	self:add(ml_element:create( "MultiBotCheck", c_MultiBotCheck, e_MultiBotCheck, 500 ), self.process_elements)
	
	-- Dead?
	self:add(ml_element:create( "Dead", c_dead_mb, e_dead_mb, 480 ), self.process_elements)
	
	-- Downed
	self:add(ml_element:create( "Downed", c_downed, e_downed, 470 ), self.process_elements)
	
	-- Dont Dive lol
	--self:add(ml_element:create( "SwimUP", c_SwimUp, e_SwimUp, 465 ), self.process_elements)
	
	-- AoELooting Characters
	self:add(ml_element:create( "AoELoot", c_AoELoot, e_AoELoot, 460 ), self.process_elements)
	
	-- Partymember Downed/Dead
	self:add(ml_element:create( "Downed", c_memberdown, e_memberdown, 450 ), self.process_elements)
	
	-- Deposit Items
	self:add(ml_element:create( "DepositingItems", c_deposit, e_deposit, 420 ), self.process_elements)	
	
	-- Re-Equip Gathering Tools
	self:add(ml_element:create( "EquippingGatherTool", c_GatherToolsCheck, e_GatherToolsCheck, 410 ), self.process_elements)	
	
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

	-- InteractNearby
	self:add(ml_element:create( "InteractNearby", c_interactNearby, e_interactNearby, 300 ), self.process_elements)	
		
	-- Follow Leader
	self:add(ml_element:create( "FollowLeader", c_MoveToLeader_fm, e_MoveToLeader_fm, 320 ), self.process_elements)
	
	-- Multibot-get target 
	self:add(ml_element:create( "GettingTarget", c_MultiBotGetTarget, e_MultiBotGetTarget, 310 ), self.process_elements)
	
	-- Valid Target
	self:add(ml_element:create( "NeedValidTarget", c_NeedValidTarget_fm, e_NeedValidTarget_fm, 260 ), self.process_elements)
		
	-- Get into Combat Range - extra movment req
	self:add(ml_element:create( "MovingIntoCombatRange", c_MoveIntoCombatRange_fm, e_MoveIntoCombatRange_fm, 250 ), self.process_elements)
	
	-- Kill Target
	self:add(ml_element:create( "KillTarget", c_KillTarget_fm, e_KillTarget_fm, 225 ), self.process_elements)
	
end

if ( mc_global.BotModes) then
	mc_global.BotModes[GetString("followmode")] = mc_ai_followbot
end


------------Utilize multibot / party data if followtarget is in our party
c_MultiBotCheck = inheritsFrom( ml_cause )
e_MultiBotCheck = inheritsFrom( ml_effect )
function c_MultiBotCheck:evaluate()
    if ( gMultiBotEnabled == "1" and MultiBotIsConnected() == true and mc_multibotmanager.leadername ~= "" and TableSize(Player:GetParty()) >1 and mc_multibotmanager.leadername == mc_followbot.targetname ) then
		mc_followbot.targetInParty = true
	end
	mc_followbot.targetInParty = false
	return false
end
function e_MultiBotCheck:execute()
end

c_MultiBotGetTarget = inheritsFrom( ml_cause )
e_MultiBotGetTarget = inheritsFrom( ml_effect )
function c_MultiBotGetTarget:evaluate()
    if ( (mc_followbot.targetInParty == true or (mc_multibotmanager.leadername ~= "" and mc_followbot.targetID ~= 0 and TableSize(CharacterList:Get(mc_followbot.targetID)) > 0 )) and mc_followbot.KilltargetID ~= 0 ) then
		local target = CharacterList:Get(mc_followbot.KilltargetID)
		if ( TableSize(target) == 0 ) then
			target = GadgetList:Get(mc_followbot.KilltargetID)
		end
		local t = Player:GetTarget()		
		if ( t == nil or ( TableSize(target) > 0 and t.id ~= target.id and target.distance < 1500 and target.selectable and target.attackable and target.dead == false)) then
			return true
		end
	end
	mc_followbot.KilltargetID = 0
	return false
end
function e_MultiBotGetTarget:execute()
	if ( (mc_followbot.targetInParty == true or (mc_multibotmanager.leadername ~= "" and mc_followbot.targetID ~= 0 and TableSize(CharacterList:Get(mc_followbot.targetID)) > 0 )) and mc_followbot.KilltargetID ~= 0 ) then
		local target = CharacterList:Get(mc_followbot.KilltargetID)
		if ( TableSize(target) == 0 ) then
			target = GadgetList:Get(mc_followbot.KilltargetID)
		end
		if ( TableSize(target) > 0 ) then
			Player:SetTarget(target.id)
			ml_log(true)
		end
	end
	ml_log(false)
end

c_interactNearby = inheritsFrom( ml_cause )
e_interactNearby = inheritsFrom( ml_effect )
function c_interactNearby:evaluate()
    local t = Player:GetInteractableTarget()
	if ( t and t.interactable) then
		if ( t.isCharacter ) then
			if ( ( t.downed and (Player.inCombat == false or Player.health.percent > 50)) or 
				 ( t.dead and t.attitude == 0 and (Player.inCombat == false or Player.health.percent > 90) )
				) then
				return true							
			end
		else
			if ( t.gatherable and Player.inCombat == false ) then
				return true
			end
		end
	end
	return false
end
function e_interactNearby:execute()
	local t = Player:GetInteractableTarget()
	if ( t and t.interactable) then		
		Player:StopMovement()
		local mt = Player:GetTarget()
		if ( t.selectable and (not mt or mt.id ~= t.id )) then
			Player:SetTarget( t.id )
		else				
			if (Player.profession == 8 ) then -- Necro, leave shroud
				local deathshroud = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_13)
				if ( deathshroud ~= nil and deathshroud.skillID == 10585 and Player:CanCast() and Player:GetCurrentlyCastedSpell() == 17) then
					Player:CastSpell(GW2.SKILLBARSLOT.Slot_13)
					mc_global.Wait(350)
					return
				end
			end
			
			-- yeah I know, but this usually doesnt break ;)
			if ( Player:GetCurrentlyCastedSpell() == 17 ) then	
				Player:Interact( t.id )
				ml_log("Interacting..")						
				mc_global.Wait(400)
				return true
			end	
		end		
	end
end


c_NeedValidTarget_fm = inheritsFrom( ml_cause )
e_NeedValidTarget_fm = inheritsFrom( ml_effect )
function c_NeedValidTarget_fm:evaluate()
	local target = Player:GetTarget()
	if ( TableSize( target ) > 0 ) then
		return ( target.dead or not target.attackable or (target.distance > ml_global_information.AttackRange and target.distance > 800 and target.los == false))
	end	
	return true
end
function e_NeedValidTarget_fm:execute()
	ml_log("e_NeedValidTarget_fm")
		
	local party = Player:GetParty()
	if ( TableSize(party)>0 ) then
		local idx,pmember = next(party)	
		while (idx and pmember) do
			if ( pmember.id ~= 0 and pmember.name == mc_multibotmanager.leadername) then
				local char = CharacterList:Get(pmember.id)
				if ( char ) then
				
					-- nearest to leader first	
					local TList = nil 
					if (not Player.inCombat) then
						TList = CharacterList("nearest,attackable,alive,aggro,distanceto="..char.id..",maxdistance=750")
					else
						TList = CharacterList("nearest,attackable,alive,aggro,distanceto="..char.id..",maxdistance=1750")
					end
					if ( TableSize( TList ) > 0 ) then
						local id, E  = next( TList )
						if ( id ~= nil and id ~= 0 and E ~= nil and E.distance <  ml_global_information.AttackRange) then
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
	end
	
	-- we do PVP n kill players first ! :D
	-- lowesthealth Player in CombatRange first	
	local TList = ( CharacterList("nearest,attackable,alive,player,aggro,maxdistance="..ml_global_information.AttackRange) )
	if ( TableSize( TList ) > 0 ) then
		local id, E  = next( TList )
		if ( id ~= nil and id ~= 0 and E ~= nil ) then
			--d("New Aggro Target: "..(E.name).." ID:"..tostring(id))
			Player:SetTarget(id)
			return ml_log(true)	
		end		
	end
			
	-- lowesthealth in CombatRange 	
	local TList = ( CharacterList("nearest,attackable,downed,player,maxdistance="..ml_global_information.AttackRange) )
	if ( TableSize( TList ) > 0 ) then
		local id, E  = next( TList )
		if ( id ~= nil and id ~= 0 and E ~= nil ) then
			--d("New Aggro Target: "..(E.name).." ID:"..tostring(id))
			Player:SetTarget(id)
			return ml_log(true)	
		end		
	end
	
	-- lowesthealth NPC in CombatRange 	
	local TList = ( CharacterList("nearest,attackable,alive,aggro,maxdistance="..ml_global_information.AttackRange) )
	if ( TableSize( TList ) > 0 ) then
		local id, E  = next( TList )
		if ( id ~= nil and id ~= 0 and E ~= nil ) then
			--d("New Aggro Target: "..(E.name).." ID:"..tostring(id))
			Player:SetTarget(id)
			return ml_log(true)	
		end		
	end
	
	-- lowest gadget	
	local TList = GadgetList("nearest,attackable,selectable,alive,maxdistance="..ml_global_information.AttackRange..",exclude_contentid="..mc_blacklist.GetExcludeString(GetString("monsters")))
	if ( TableSize( TList ) > 0 ) then
		local id, E  = next( TList )
		if ( id ~= nil and id ~= 0 and E ~= nil ) then
			--d("New Aggro Target: "..tostring(E.name).." ID:"..tostring(id))
			Player:SetTarget(id)
			return ml_log(true)	
		end		
	end
	
	-- Then nearest Aggro Target
	TList = ( CharacterList("attackable,alive,aggro,nearest,maxdistance=1000") )
	if ( TableSize( TList ) > 0 ) then
		local id, E  = next( TList )
		if ( id ~= nil and id ~= 0 and E ~= nil ) then
			--d("New Aggro Target: "..(E.name).." ID:"..tostring(id))
			Player:SetTarget(id)
			return ml_log(true)	
		end		
	end
	
	--some failsave
	if ( Player:IsMoving() ) then
		Player:StopMovement()
	end
	
	return ml_log(false)
end


c_MoveIntoCombatRange_fm = inheritsFrom( ml_cause )
e_MoveIntoCombatRange_fm = inheritsFrom( ml_effect )
c_MoveIntoCombatRange_fm.running = false
function c_MoveIntoCombatRange_fm:evaluate()    
	local t = Player:GetTarget()
	if ( t ) then		
		if (t.distance >= ml_global_information.AttackRange or (t.isCharacter and not t.los) or (t.isGadget and not t.los and t.distance > ml_global_information.AttackRange) or (t.isGadget and not t.los and t.distance > 350)) then
			if (Player.onmesh ) then
				return true
			else
				-- not moving on navmesh, record path from our current pos so we can walk it back							
				if ( t.los and t.distance < 800 and t.distance > ml_global_information.AttackRange ) then 
					return true
				end				
			end
		else
			if ( c_MoveIntoCombatRange_fm.running ) then 
				c_MoveIntoCombatRange_fm.running = false
				Player:StopMovement()
			end
		end
	end
	return false
end

e_MoveIntoCombatRange_fm.tmr = 0
e_MoveIntoCombatRange_fm.threshold = 2000
function e_MoveIntoCombatRange_fm:execute()
	ml_log("e_MoveIntoCombRng")
	local t = Player:GetTarget()
	if ( t ) then	
		if (Player.onmesh ) then		
			if ( t.distance >= ml_global_information.AttackRange or not t.los)then
				local tPos = t.pos
				-- moveto(x,y,z,stoppingdistance,navsystem(normal/follow),navpath(straight/random),smoothturns)		
				if ( tPos ) then
					--d("MoveIntoCombatRange..Running")
					if ( c_DestroyGadget:evaluate() ) then e_DestroyGadget:execute() end
					MoveOnlyStraightForward()
					local navResult = tostring(Player:MoveTo(tPos.x,tPos.y,tPos.z,100+t.radius,false,false,true))		
					if (tonumber(navResult) < 0) then					
						d("mc_ai_combat.MoveIntoCombatRange result: "..tonumber(navResult))					
					end
					
					if ( mc_global.now - e_MoveIntoCombatRange_fm.tmr > e_MoveIntoCombatRange_fm.threshold ) then
						e_MoveIntoCombatRange_fm.tmr = mc_global.now
						e_MoveIntoCombatRange_fm.threshold = math.random(1000,5000)
						mc_skillmanager.HealMe()
					end	
					c_MoveIntoCombatRange.running = true
					return true
				end
			end
		else
			-- try to record our way to target to be able to walk it back
			local tpos = t.pos
			local pSize = TableSize(mc_followbot.targetPath)
			if ( pSize > 0 ) then
				-- Extend existing path by adding our walking at beginning
				local pPos = Player.pos
				local dist = Distance3D( pPos.x, pPos.y, pPos.z, mc_followbot.targetPath[1].pos.x ,mc_followbot.targetPath[1].pos.y , mc_followbot.targetPath[1].pos.z)
				if ( dist > 120 and dist < 250 ) then
					table.insert(mc_followbot.targetPath ,1, { pos = { x=pPos.x, y=pPos.y, z=pPos.z } , flag = mstate })
				end				
			else
				-- start a new path
				local pPos = Player.pos
				local mstate = Player.movementstate
				table.insert(mc_followbot.targetPath, { pos = { x=pPos.x, y=pPos.y, z=pPos.z } , flag = mstate })				
			end
			-- move to target
			Player:SetFacing(tpos.x, tpos.y, tpos.z)
			if ( Player:CanMove() and Player:IsMoving() == false) then
				Player:SetMovement(0)
				c_MoveIntoCombatRange_fm.running = true
			end
		end
	end
	return ml_log(false)
end


c_KillTarget_fm = inheritsFrom( ml_cause )
e_KillTarget_fm = inheritsFrom( ml_effect )
function c_KillTarget_fm()
	return true
end
function e_KillTarget_fm:execute()
	ml_log("e_KillTarget_fm")
	local t = Player:GetTarget()
	if ( t and t.alive and t.attackable) then
		local pos = t.pos
		if ( pos ) then
			Player:SetFacing(pos.x,pos.y,pos.z)
			mc_skillmanager.AttackTarget( t.id )
			
			if ( Player.onmesh ) then
				DoCombatMovement()
			end
			
			return ml_log(true)
		end
	else
		Player:StopMovement()		 
	end	
	return ml_log(false)
end



c_MoveToLeader_fm = inheritsFrom( ml_cause )
e_MoveToLeader_fm = inheritsFrom( ml_effect )
c_MoveToLeader_fm.nearleader = false
c_MoveToLeader_fm.randomDist = math.random(100,500)
c_MoveToLeader_fm.tmr = 0
c_MoveToLeader_fm.threshold = 2000
function c_MoveToLeader_fm:evaluate()
	
	if ( Player.onmesh ) then 
		if ( mc_followbot.targetInParty == true ) then
			return c_MoveToLeader:evaluate()
		else
			if ( mc_followbot.targetID ~= 0 ) then
				local target = CharacterList:Get(mc_followbot.targetID)
				if ( TableSize(target)>0 ) then			
					if ( target.distance > c_MoveToLeader_fm.randomDist ) then
						return true					
					end				
				else
					ml_log("TargetNotInCharacterList")
				end
			end
		end
	else
		if (TableSize(mc_followbot.targetPath) > 0 ) then			
			if ( mc_followbot.targetID ~= 0 ) then
				local target = CharacterList:Get(mc_followbot.targetID)
				if ( TableSize(target)>0 ) then				
					local mstate = target.movementstate
					local tpos = target.pos
					local pPos = Player.pos
					local dist = Distance3D( pPos.x, pPos.y, pPos.z, tpos.x, tpos.y, tpos.z)
					if ( dist > 400 or mstate == 3 and dist > 250 ) then
						return true
					end					
				end
				if ( c_MoveToLeader_fm.movingtoleader == true ) then
					c_MoveToLeader_fm.movingtoleader = false
					Player:StopMovement()
				end
			end
		end
	end	
	return false
end

e_MoveToLeader_fm.rndStopDist = math.random(55,300)
function e_MoveToLeader_fm:execute()
	if ( Player.onmesh == true) then 
		ml_log("Moving_With_Mesh_ToLeader")
		if ( mc_followbot.targetInParty == true ) then
			return e_MoveToLeader:execute()
		else
			if ( mc_followbot.targetID ~= 0 ) then
				local target = CharacterList:Get(mc_followbot.targetID)
				if ( TableSize(target)>0 ) then			
					if ( target.onmesh == true and target.distance > c_MoveToLeader_fm.randomDist ) then
						local tpos = target.pos
						local navResult = tostring(Player:MoveTo(tpos.x,tpos.y,tpos.z,c_MoveToLeader_fm.randomDist,false,true,true))		
						if (tonumber(navResult) < 0) then					
							d("mc_ai_followbot.e_MoveToLeader_fm result: "..tonumber(navResult))					
						end
						-- add this targetpoint on mesh as our first node in the navpath in case the target leaves the navmesh
						local mstate = target.movementstate
						mc_followbot.targetPath = {}
						table.insert(mc_followbot.targetPath, { pos = { x=tpos.x, y=tpos.y, z=tpos.z } , flag = mstate })
						
						if ( mc_global.now - c_MoveToLeader_fm.tmr > c_MoveToLeader_fm.threshold ) then
							c_MoveToLeader_fm.tmr = mc_global.now
							c_MoveToLeader_fm.threshold = math.random(1000,2000)
							mc_skillmanager.HealMe()
						end
						return ml_log(true)
					end				
				else
					ml_log("TargetNotInCharacterList")
				end
			end
		end		
	end
	
	
	--- handles movement offside the mesh	
		ml_log("Moving_Without_Mesh_ToLeader")
		if ( TableSize(mc_followbot.targetPath) > 0 ) then
			local node = mc_followbot.targetPath[1]
			local pPos = Player.pos
			local jump = false
			local dist = Distance3D( pPos.x, pPos.y, pPos.z, node.pos.x, node.pos.y, node.pos.z)
			-- followtarget was jumping/falling try 2d dist
			if ( node.flag == 5 or node.flag == 4) then
				dist = Distance2D( pPos.x, pPos.y, node.pos.x, node.pos.y)
			end
			
			-- last point
			if ( TableSize(mc_followbot.targetPath) == 1 ) then
				if ( dist < e_MoveToLeader_fm.rndStopDist ) then
					if ( node.flag == 5 or node.flag == 4) then jump = true end
					table.remove(mc_followbot.targetPath,1)
				end
			else
				if ( dist < 55 ) then
					if ( node.flag == 5 or node.flag == 4) then jump = true end
					table.remove(mc_followbot.targetPath,1)
				end
			end
			
			if ( TableSize(mc_followbot.targetPath) > 0 ) then
				node = mc_followbot.targetPath[1]
				Player:SetFacing(node.pos.x, node.pos.y, node.pos.z)
				if ( Player:CanMove() and Player:IsMoving() == false) then
					Player:SetMovement(0)
					c_MoveToLeader_fm.movingtoleader = true
				end
				if ( jump ) then Player:Jump() end
				
				if ( mc_global.now - c_MoveToLeader_fm.tmr > c_MoveToLeader_fm.threshold ) then
					c_MoveToLeader_fm.tmr = mc_global.now
					c_MoveToLeader_fm.threshold = math.random(1000,2000)
					mc_skillmanager.HealMe()
				end	
				
				ml_log("Moving to next pathnode")
			else
				c_MoveToLeader_fm.movingtoleader = false
				Player:StopMovement()
			end
		end
	return ml_log(false)
end

