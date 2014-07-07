-- Interact with object Quest
script = inheritsFrom( ml_task )
script.name = "InteractObject"
script.Data = {}

--******************
-- ml_quest_mgr Functions
--******************
function script:UIInit( identifier )
	GUI_NewField(ml_quest_mgr.stepwindow.name,"Interact Object ID",tostring(identifier).."InteractObject",GetString("questStepDetails"))
	GUI_NewButton(ml_quest_mgr.stepwindow.name,"Set Object ID",tostring(identifier).."SetObjectID",GetString("questStepDetails"))
	GUI_NewField(ml_quest_mgr.stepwindow.name,"InteractDuration",tostring(identifier).."InteractDuration",GetString("questStepDetails"))
end

function script:SetData( identifier, tData )
	if ( identifier and tData ) then		
				
		self.Data = tData
		
		if ( self.Data["InteractObject"] ) then
		_G[tostring(identifier).."InteractObject"] = self.Data["InteractObject"]
		end
		if ( self.Data["InteractDuration"] ) then
		_G[tostring(identifier).."InteractDuration"] = self.Data["InteractDuration"]
		end
	end
end

function script:EventHandler( identifier, event, value )
	if ( event == "SetObjectID" ) then
	local t = Player:GetTarget()
		if ( t ) then
			-- Set Data
			self.Data["InteractObject"] = t.contentID	

			-- Update UI fields
			_G[tostring(identifier).."InteractObject"] = t.contentID
	
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
	self:add(ml_element:create( "Dead", c_dead, e_dead, 300 ), self.process_elements)
	
	-- Downed
	self:add(ml_element:create( "Downed", c_downed, e_downed, 280 ), self.process_elements)
	
	-- Move InRange of Object
	self:add(ml_element:create( "MovingToObject", c_MoveInObjectRange, e_MoveInObjectRange, 220 ), self.process_elements)
			
	-- Take the object
	self:add(ml_element:create( "InteractObject", self.c_Interact, self.e_Interact, 110 ), self.process_elements)	

	
	self:AddTaskCheckCEs()
end


function script:task_complete_eval()		
	return false
end
function script:task_complete_execute()
   self.completed = true
end



function script:task_complete_eval()	

	local oID = ml_task_hub:CurrentTask().Data["InteractObject"]
	if ( oID == nil or TableSize(MapMarkerList("onmesh, contentID="..oID))==0 ) then
		script.c_MoveInObject.range = 150
		script.c_MoveInObjectRange.reached = false
		return true
	end
	return false
end

function script:task_complete_execute()
   self.completed = true
end


script.c_MoveInObjectRange = inheritsFrom( ml_cause )
script.e_MoveInObjectRange = inheritsFrom( ml_effect )
script.c_MoveInObjectRange.reached = false
script.c_MoveInObjectRange.range = 50

function script.c_MoveInObjectRange:evaluate()
	local oID = ml_task_hub:CurrentTask().Data["InteractObject"]
	if ( tonumber(oID)~=nil ) then
		local evList = MapMarkerList("nearest,contentID="..oID)
		local i,e = next(evList)
		if ( i and e ) then
			if ( script.c_MoveInObjectRange.reached == false) then
				return true
			else
				local pPos = Player.pos
				local oPos = o.pos
				if (pPos) then
					if ( Distance2D ( pPos.x, pPos.y, oPos.x, oPos.y) > script.c_MoveInObjectRange.range ) then
						return true					
					end
				end			
			end
		end
	end
	return false
end
function script.e_MoveInObjectRange:execute()
	ml_log("e_MoveInObjectRange")
	local oID = ml_task_hub:CurrentTask().Data["InteractObject"]
	if ( tonumber(eID)~=nil ) then
		local objList = MapMarkerList("nearest,contentID="..oID)
		local i,e = next(objList)
		if ( i and e ) then
			local pPos = Player.pos
			local oPos = e.pos
			if (pPos and ePos) then
				ml_log(tostring(math.floor(Distance2D( pPos.x, pPos.y, oPos.x, oPos.y))))
				if ( script.c_MoveInObjectRange.reached == false) then
					-- 1st time get into object range
					if ( Distance2D ( pPos.x, pPos.y, oPos.x, oPos.y) > 50 ) then
						local navResult = tostring(Player:MoveTo(oPos.x,oPos.y,oPos.z,125,false,false,true))		
						if (tonumber(navResult) < 0) then					
							ml_error("InteractObject.c_MoveInObjectRange result: "..tonumber(navResult))					
						end
						return ml_log(true)
					else
						script.c_MoveInObjectRange.reached = true
					end
					
				else
					-- Check if we moved too far away from the object we are in
					if ( Distance2D ( pPos.x, pPos.y, oPos.x, oPos.y) > script.c_MoveInObjectRange.range ) then
						local navResult = tostring(Player:MoveTo(ePos.x,ePos.y,ePos.z,125,false,false,true))		
						if (tonumber(navResult) < 0) then					
							ml_error("InteractObject.MoveBackIntoObjectRange result: "..tonumber(navResult))					
						end
						script.c_MoveInObjectRange.reached = false
						return ml_log(true)
					end
				end
			end
		end
	end
	return ml_log(false)
end

-- Cause&Effect
script.c_Interact = inheritsFrom( ml_cause )
script.e_Interact = inheritsFrom( ml_effect )

function script.c_Interact:evaluate() 
	if (tonumber(ml_task_hub:CurrentTask().Data["InteractObject"])) ~= nil then
		return true
	else
		ml_error("Quest InteractObject Step has no id set!")
	end
	return false
end

function script.e_Interact:execute()
	ml_log("c_Interact")
	d(Player:Interact(ml_task_hub:CurrentTask().Data["InteractObject"]))
	local tdur = ml_task_hub:CurrentTask().Data["InteractDuration"]
	if ( tonumber (tdur) ~= nil ) then
		mc_global.Wait(tonumber(tdur))
	end
	ml_task_hub:CurrentTask().completed = true
end	






return script