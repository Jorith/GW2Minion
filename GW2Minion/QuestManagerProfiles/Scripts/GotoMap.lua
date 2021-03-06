-- Goto Position x,y,z script for QuestManager
script = inheritsFrom( ml_task )
script.name = "GotoMap"
script.Data = {}

--******************
-- ml_quest_mgr Functions
--******************
function script:UIInit( identifier )
	-- You need to create the ScriptUI Elements exactly like you see here, the "event" needs to start with "tostring(identifier).." and the group needs to be GetString("questStepDetails")
	GUI_NewField(ml_quest_mgr.stepwindow.name,"PortalPos X",tostring(identifier).."GotoX",GetString("questStepDetails"))
	GUI_NewField(ml_quest_mgr.stepwindow.name,"PortalPos Y",tostring(identifier).."GotoY",GetString("questStepDetails"))
	GUI_NewField(ml_quest_mgr.stepwindow.name,"PortalPos Z",tostring(identifier).."GotoZ",GetString("questStepDetails"))
	GUI_NewButton(ml_quest_mgr.stepwindow.name,"FacePortal & PressMe",tostring(identifier).."SetPosition",GetString("questStepDetails"))
	GUI_NewField(ml_quest_mgr.stepwindow.name,"TargetMapID",tostring(identifier).."TargetMapID",GetString("questStepDetails"))
	GUI_NewButton(ml_quest_mgr.stepwindow.name,"Goto TargetMap & PressMe",tostring(identifier).."SetTargetMapID",GetString("questStepDetails"))
end

function script:SetData( identifier, tData )
	-- Save the data in our script-"instance" aka global variables and set the UI elements
	if ( identifier and tData ) then		
		--d("script:SetData: "..tostring(identifier))
				
		self.Data = tData
		
		-- Update the script UI (make sure the Data assigning to a _G is NOT nil! else crashboooombang!)
		if ( self.Data["GotoX"] ) then _G[tostring(identifier).."GotoX"] = self.Data["GotoX"] end
		if ( self.Data["GotoY"] ) then _G[tostring(identifier).."GotoY"] = self.Data["GotoY"] end
		if ( self.Data["GotoZ"] ) then _G[tostring(identifier).."GotoZ"] = self.Data["GotoZ"] end
		if ( self.Data["TargetMapID"] ) then _G[tostring(identifier).."TargetMapID"] = self.Data["TargetMapID"] end
	end
end

function script:EventHandler( identifier, event, value )
	-- for extended UI event handling, gets called when a scriptUI element is pressed	
	if ( event == "SetPosition" ) then
		local pPos = Player.pos
		if ( pPos ) then
			-- Set Data
			self.Data["GotoX"] = pPos.x		
			self.Data["GotoY"] = pPos.y
			self.Data["GotoZ"] = pPos.z
			-- Update UI fields
			_G[tostring(identifier).."GotoX"] = pPos.x
			_G[tostring(identifier).."GotoY"] = pPos.y
			_G[tostring(identifier).."GotoZ"] = pPos.z			
		end
	elseif( event == "SetTargetMapID" ) then
		local mid = Player:GetLocalMapID()
		if (mid) then
			self.Data["TargetMapID"] = mid
			_G[tostring(identifier).."TargetMapID"] = mid
		end	
	end	
end

--******************
-- ml_Task Functions
--******************
script.valid = true
script.completed = false
script.subtask = nil
script.process_elements = {}
script.overwatch_elements = {} 

function script:Init()
    -- Add Cause&Effects here
	-- Dead?
	self:add(ml_element:create( "Dead", c_dead, e_dead, 225 ), self.process_elements)
	
	-- Downed
	self:add(ml_element:create( "Downed", c_downed, e_downed, 200 ), self.process_elements)
	
	-- AoELooting Characters
	self:add(ml_element:create( "AoELoot", c_AoELoot, e_AoELoot, 175 ), self.process_elements)
			
	-- Normal Chests	
	self:add(ml_element:create( "LootingChest", c_LootChests, e_LootChests, 155 ), self.process_elements)
	
	-- Resting
	self:add(ml_element:create( "Resting", c_resting, e_resting, 145 ), self.process_elements)	

	-- Normal Looting
	self:add(ml_element:create( "Looting", c_LootCheck, e_LootCheck, 130 ), self.process_elements)

	-- Deposit Items
	self:add(ml_element:create( "DepositingItems", c_deposit, e_deposit, 120 ), self.process_elements)	
	
	-- GoTo Position
	self:add(ml_element:create( "GoToPosition", self.c_goto, self.e_goto, 110 ), self.process_elements)	
	
	-- Destination Map Reached
	self:add(ml_element:create( "MapChanged", self.c_mapcheck, self.e_mapcheck, 100 ), self.process_elements)
	
	self:AddTaskCheckCEs()
end


function script:task_complete_eval()		
	return false
end
function script:task_complete_execute()
   self.completed = true
end



-- Cause&Effect
script.c_goto = inheritsFrom( ml_cause )
script.e_goto = inheritsFrom( ml_effect )
script.e_goto.reached = false
function script.c_goto:evaluate() 
	if ( script.e_goto.reached == true ) then return false end
	
	if (tonumber(ml_task_hub:CurrentTask().Data["GotoX"]) ~= nil and
		tonumber(ml_task_hub:CurrentTask().Data["GotoY"]) ~= nil and
		tonumber(ml_task_hub:CurrentTask().Data["GotoZ"]) ~= nil) then
		return true
	else
		ml_error("Quest GoToPosition Step has no Position set!")
	end
	return false
end
script.e_goto.tmr = 0
script.e_goto.threshold = 2000
function script.e_goto:execute()
	ml_log("e_goto")
	local pPos = Player.pos
	if (pPos) then
		local dist = Distance3D( ml_task_hub:CurrentTask().Data["GotoX"],ml_task_hub:CurrentTask().Data["GotoY"],ml_task_hub:CurrentTask().Data["GotoZ"],pPos.x,pPos.y,pPos.z)
		ml_log("("..tostring(math.floor(dist))..")")
		if ( dist > 50 ) then
			--d(tostring(ml_task_hub:CurrentTask().Data["GotoX"]).." "..tostring(ml_task_hub:CurrentTask().Data["GotoY"]).." "..tostring(ml_task_hub:CurrentTask().Data["GotoZ"]))
			local navResult = tostring(Player:MoveTo(ml_task_hub:CurrentTask().Data["GotoX"],ml_task_hub:CurrentTask().Data["GotoY"],ml_task_hub:CurrentTask().Data["GotoZ"],50,false,false,true))		
			if (tonumber(navResult) < 0) then					
				ml_error("e_gotoPosition result: "..tonumber(navResult))					
			end			

			if ( mc_global.now - script.e_goto.tmr > script.e_goto.threshold ) then
				script.e_goto.tmr = mc_global.now
				script.e_goto.threshold = math.random(1000,5000)
				mc_skillmanager.HealMe()
			end	

			return ml_log(true)
		else
			script.e_goto.reached = true
			-- move hopefully into portal
			Player:SetMovement(0)
		end
	end	
	return ml_log(false)
end


script.c_mapcheck = inheritsFrom( ml_cause )
script.e_mapcheck = inheritsFrom( ml_effect )
function script.c_mapcheck:evaluate() 	
	if (tonumber(ml_task_hub:CurrentTask().Data["TargetMapID"]) ~= nil ) then
		if (script.e_goto.reached == true ) then 
			return true 		
		end		
	else
		ml_error("Quest GotoMap Step has no TargetMapID set!")
	end
	return false
end
function script.e_mapcheck:execute()
	ml_log("e_mapcheck")
	if ( tonumber(ml_task_hub:CurrentTask().Data["TargetMapID"]) == Player:GetLocalMapID() ) then
		d("TargetMap reached, step finished")
		ml_task_hub:CurrentTask().completed = true
		ml_log(true)
	else
		if (Player.IsMoving() == false) then 
			Player:SetMovement(0)
		end
		ml_error("TargetMap not yet reached..")
	end
	return ml_log(false)
end


return script