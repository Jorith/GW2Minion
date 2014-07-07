ml_globals = {}

-- Global vars which are used very often and we can just reduce the hammering by getting them once per frame
function ml_globals.UpdateGlobals()
	
	if ( Player ~= nil ) then
		if (mc_skillmanager) then 	ml_global_information.AttackRange = mc_skillmanager.GetAttackRange() end
				
		ml_global_information.Player_Health = Player.health or { current = 0, max = 0, percent = 0 }
		ml_global_information.Player_Power = Player.power or 0
		ml_global_information.Player_Endurance = Player.endurance or 0		
		ml_global_information.Player_InCombat = Player.inCombat or false	
		ml_global_information.CurrentMapID = Player:GetLocalMapID()
		if ( mc_datamanager ) then  ml_global_information.CurrentMapName = mc_datamanager.GetMapName( Player:GetLocalMapID()) end
		ml_global_information.Player_Position = Player.pos
		ml_global_information.Player_Level = Player.level
		
		-- Update Debug fields	
		dAttackRange = ml_global_information.AttackRange
		mc_global.AttackRange = ml_global_information.AttackRange  -- for backwards compatibility ;)
	end
end

-- Draw Marker function
function ml_globals.DrawMarker( marker )
	local markertype = marker:GetType()
	local pos = marker:GetPosition()

    local color = 0
    local s = 25
    local h = 150
	
    if ( markertype == GetString("grindMarker") ) then
        color = 1 -- red
    elseif ( markertype == GetString("miningMarker") ) then 
        color = 4 --blue
    elseif ( markertype == GetString("fishingMarker") ) then
        color = 7 -- yellow	
    elseif ( markertype == GetString("vendorMarker") ) then
        color = 8 -- orange
    end
    --Building the vertices for the object
    local t = { 
        [1] = { pos.x-s, pos.y+s, pos.z-s-h, color },
        [2] = { pos.x+s, pos.y+s, pos.z-s-h, color  },	
        [3] = { pos.x,   pos.y-s,   pos.z-h, color  },
        
        [4] = { pos.x+s, pos.y+s, pos.z-s-h, color },
        [5] = { pos.x+s, pos.y+s, pos.z+s-h, color  },	
        [6] = { pos.x,   pos.y-s,   pos.z-h, color  },
        
        [7] = { pos.x+s, pos.y+s, pos.z+s-h, color },
        [8] = { pos.x-s, pos.y+s, pos.z+s-h, color  },	
        [9] = { pos.x,   pos.y-s,   pos.z-h, color  },
        
        [10] = { pos.x-s, pos.y+s, pos.z+s-h, color },
        [11] = { pos.x-s, pos.y+s, pos.z-s-h, color  },	
        [12] = { pos.x,   pos.y-s,   pos.z-h, color  },
    }
    local id = RenderManager:AddObject(t)
    return id
end


-- Init all variables before the rest of the bot loads
ml_globals.UpdateGlobals()














