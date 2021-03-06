-- Goto Position x,y,z script for QuestManager
script = inheritsFrom( ml_task )
script.name = "ExploreMapObject"
script.Data = {}

--******************
-- ml_quest_mgr Functions
--******************
function script:UIInit( identifier )
	-- You need to create the ScriptUI Elements exactly like you see here, the "event" needs to start with "tostring(identifier).." and the group needs to be GetString("questStepDetails")
	GUI_NewField(ml_quest_mgr.stepwindow.name,"Goto X",tostring(identifier).."GotoX",GetString("questStepDetails"))
	GUI_NewField(ml_quest_mgr.stepwindow.name,"Goto Y",tostring(identifier).."GotoY",GetString("questStepDetails"))
	GUI_NewField(ml_quest_mgr.stepwindow.name,"Goto Z",tostring(identifier).."GotoZ",GetString("questStepDetails"))
	GUI_NewButton(ml_quest_mgr.stepwindow.name,"Set Current Position",tostring(identifier).."SetPosition",GetString("questStepDetails"))
		
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
		
	-- AoELooting Gadgets/Chests needed ?
		
	-- Partymember Downed/Dead
	self:add(ml_element:create( "RevivePartyMember", c_memberdown, e_memberdown, 172 ), self.process_elements)	
	
	-- Revive Players
	self:add(ml_element:create( "RevivePlayer", c_reviveDownedPlayersInCombat, e_reviveDownedPlayersInCombat, 170 ), self.process_elements)
		
	-- Aggro
	self:add(ml_element:create( "Aggro", c_AggroEx, e_AggroEx, 165 ), self.process_elements) --reactive queue
	
	-- Dont Dive lol
	self:add(ml_element:create( "SwimUP", c_SwimUp, e_SwimUp, 160 ), self.process_elements)
	
	-- Normal Chests	
	self:add(ml_element:create( "LootingChest", c_LootChests, e_LootChests, 155 ), self.process_elements)
		
	-- Resting
	self:add(ml_element:create( "Resting", c_resting, e_resting, 145 ), self.process_elements)	

	-- Normal Looting
	self:add(ml_element:create( "Looting", c_LootCheck, e_LootCheck, 130 ), self.process_elements)

	-- Deposit Items
	self:add(ml_element:create( "DepositingItems", c_deposit, e_deposit, 120 ), self.process_elements)	
	
	-- Re-Equip Gathering Tools
	self:add(ml_element:create( "EquippingGatherTool", c_GatherToolsCheck, e_GatherToolsCheck, 110 ), self.process_elements)	
	
	-- Quick-Repair & Vendoring (when a vendor is nearby)	
	self:add(ml_element:create( "QuickSellItems", c_quickvendorsell, e_quickvendorsell, 100 ), self.process_elements)
	self:add(ml_element:create( "QuickBuyItems", c_quickbuy, e_quickbuy, 99 ), self.process_elements)
	self:add(ml_element:create( "QuickRepairItems", c_quickrepair, e_quickrepair, 98 ), self.process_elements)
	
	-- Repair & Vendoring
	self:add(ml_element:create( "SellItems", c_vendorsell, e_vendorsell, 90 ), self.process_elements)	
	self:add(ml_element:create( "BuyItems", c_vendorbuy, e_vendorbuy, 89 ), self.process_elements)
	self:add(ml_element:create( "RepairItems", c_vendorrepair, e_vendorrepair, 88 ), self.process_elements)
	
	-- Salvaging
	self:add(ml_element:create( "Salvaging", c_salvage, e_salvage, 75 ), self.process_elements)
		
	-- ReviveNPCs
	self:add(ml_element:create( "ReviveNPC", c_reviveNPC, e_reviveNPC, 70 ), self.process_elements)	
	
	-- Gathering	
	self:add(ml_element:create( "Gathering", c_gatherTask, e_gatherTask, 65 ), self.process_elements)
		
	-- Kill Stuff Nearby
	self:add(ml_element:create( "SearchAndKillNearby", c_SearchAndKillNearby, e_SearchAndKillNearby, 45 ), self.process_elements)	
		
	-- GoTo Position
	self:add(ml_element:create( "GoToPosition", self.c_goto, self.e_goto, 30 ), self.process_elements)	
	
	self:AddTaskCheckCEs()
end


function script:task_complete_eval()		
	return false
end
function script:task_complete_execute()
	d("WWWWWWWWWWW")
   self.completed = true
end



-- Cause&Effect
script.c_goto = inheritsFrom( ml_cause )
script.e_goto = inheritsFrom( ml_effect )
function script.c_goto:evaluate() 
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
	ml_log("e_ExploringMap")
	local pPos = Player.pos
	if (pPos) then
		local dist = Distance3D( ml_task_hub:CurrentTask().Data["GotoX"],ml_task_hub:CurrentTask().Data["GotoY"],ml_task_hub:CurrentTask().Data["GotoZ"],pPos.x,pPos.y,pPos.z)
		ml_log("("..tostring(math.floor(dist))..")")
		if ( dist > 100 ) then
			--d(tostring(ml_task_hub:CurrentTask().Data["GotoX"]).." "..tostring(ml_task_hub:CurrentTask().Data["GotoY"]).." "..tostring(ml_task_hub:CurrentTask().Data["GotoZ"]))
			local navResult = tostring(Player:MoveTo(ml_task_hub:CurrentTask().Data["GotoX"],ml_task_hub:CurrentTask().Data["GotoY"],ml_task_hub:CurrentTask().Data["GotoZ"],125,false,false,true))		
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
			ml_task_hub:CurrentTask().completed = true
		end
	end	
	return ml_log(false)
end


return script