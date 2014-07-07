-- GrindMode Behavior
mc_ai_assist = inheritsFrom(ml_task)
mc_ai_assist.name = "AssistMode"

function mc_ai_assist.Create()
	local newinst = inheritsFrom(mc_ai_assist)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
            
    return newinst
end

function mc_ai_assist:Init()

end

mc_ai_assist.tmr = 0
mc_ai_assist.threshold = 2000
function mc_ai_assist:Process()
	--ml_log("AssistMode_Process->")
		
	if ( not Player.dead ) then
		if ( mc_global.now - c_AoELoot.lastused >1050 and Inventory.freeSlotCount > 0) then
			c_AoELoot.lastused = mc_global.now
			Player:AoELoot()
		end
		
		if ( c_salvage:evaluate() == true ) then e_salvage:execute() end
		
		if ( FinishEnemy() == true ) then return end
		
		
		if ( mc_global.now - mc_ai_assist.tmr > mc_ai_assist.threshold and Player:IsMoving()) then
			mc_ai_assist.tmr = mc_global.now
			mc_ai_assist.threshold = math.random(500,1000)
			mc_skillmanager.HealMe()
		end	
		
		if ( sMtargetmode == "None" ) then 
			mc_skillmanager.AttackTarget( nil ) 
			
		elseif ( sMtargetmode ~= "None" ) then 
			mc_ai_assist.SetTargetAssist()
		end
	end				
	
end


function mc_ai_assist.SelectTargetExtended(maxrange, los)
    
	local filterstring = "attackable,alive,maxdistance="..tostring(maxrange)
	
	if (los == "1") then filterstring = filterstring..",los" end
	if (sMmode == "Players Only") then filterstring = filterstring..",player" end
	if (sMtargetmode == "LowestHealth") then filterstring = filterstring..",lowesthealth" end
	if (sMtargetmode == "Closest") then filterstring = filterstring..",nearest" end
	if (sMtargetmode == "Biggest Crowd") then filterstring = filterstring..",clustered=600" end
	
	local TargetList = CharacterList(filterstring)
	if ( TargetList ) then
		local id,entry = next(TargetList)
		if (id and entry ) then
			ml_log("Attacking "..tostring(entry.id) .. " name "..entry.name)
			return entry
		end
	end	
	return nil
end

function mc_ai_assist.SetTargetAssist()
	-- Try to get Enemy with los in range first
	local target = mc_ai_assist.SelectTargetExtended(ml_global_information.AttackRange, 1)	
	if ( not target ) then target = mc_ai_assist.SelectTargetExtended(ml_global_information.AttackRange, 0) end
	if ( not target ) then target = mc_ai_assist.SelectTargetExtended(ml_global_information.AttackRange + 250, 0) end
	
	if ( target ) then 
		Player:SetTarget(target.id)
		return mc_skillmanager.AttackTarget( target.id ) 		
	else
		-- see if we can swap weapons/kits to get a better attackrange
		local currTarget = Player:GetTarget()
		if ( currTarget ~= nil ) then
			return mc_skillmanager.AttackTarget( currTarget.id )
		end
		return false
	end
end

function mc_ai_assist.moduleinit()
	
	if (Settings.GW2Minion.sMtargetmode == nil) then
		Settings.GW2Minion.sMtargetmode = "None"
	end
	if (Settings.GW2Minion.sMmode == nil) then
		Settings.GW2Minion.sMmode = "Everything"
	end
	GUI_NewComboBox(mc_global.window.name,GetString("sMtargetmode"),"sMtargetmode",GetString("assistMode"),"None,LowestHealth,Closest,Biggest Crowd");
	GUI_NewComboBox(mc_global.window.name,GetString("sMmode"),"sMmode",GetString("assistMode"),"Everything,Players Only")
	
	sMtargetmode = Settings.GW2Minion.sMtargetmode
	sMmode = Settings.GW2Minion.sMmode
	
end

c_FinishHim = inheritsFrom( ml_cause )
e_FinishHim = inheritsFrom( ml_effect )
function FinishEnemy()    
	if ( Player:IsMoving() == false and Player.health.percent > 15 ) then
		local EList = CharacterList("nearest,downed,aggro,attackable,maxdistance=150,onmesh")
		if ( EList ) then
			local id,entity = next (EList)
			if ( id and entity ) then
				if ( entity.isInInteractRange and entity.selectable) then
					local t = Player:GetTarget()
					if ( t and t.id == id ) then						
						Player:Interact( id )
						ml_log("Finishing..")						
						mc_global.Wait(1000)
						return true						
					end
				end
			end
		end
	end
	return false
end


-- Adding it to our botmodes
if ( mc_global.BotModes ) then
	mc_global.BotModes[GetString("assistMode")] = mc_ai_assist
end 

RegisterEventHandler("Module.Initalize",mc_ai_assist.moduleinit)