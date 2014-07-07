mc_ai_unstuck = {}
mc_ai_unstuck.enabled = true
mc_ai_unstuck.stucktimer = 0
mc_ai_unstuck.stuckcounter = 0
mc_ai_unstuck.idletimer = 0
mc_ai_unstuck.idlecounter = 0
mc_ai_unstuck.respawntimer = 0
mc_ai_unstuck.ismoving = false
mc_ai_unstuck.lastpos = nil
mc_ai_unstuck.stuckcounter2 = 0
mc_ai_unstuck.conditions = "791,727,721" --Fear, Immobilized, Crippled. -- Needs more! (all debufs that slow you down.)
mc_ai_unstuck.Obstacles = {}
mc_ai_unstuck.AvoidanceAreas = {}

function mc_ai_unstuck:OnUpdate( tick )
	
	if ( not mc_ai_unstuck.enabled ) then return end	
	
	if ( Player.alive == false) then 
		mc_ai_unstuck.Reset()
		return
	end
	
	
	if 	(mc_ai_unstuck.lastpos == nil) or (mc_ai_unstuck.lastpos and type(mc_ai_unstuck.lastpos) ~= "table") then
		mc_ai_unstuck.lastpos = Player.pos
		return	
	end
	
	if ( gBotMode == GetString("assistMode") ) then return end
	if ( mc_helper.HasBuffs(Player, mc_ai_unstuck.conditions) ) then return end --Fear and Immobilized
	
	-- Stuck check for movement stucks
	if ( Player:IsMoving()) then
		local movedirs = Player:GetMovement()
		if ( not movedirs.backward and tick - mc_ai_unstuck.stucktimer > 500 ) then
			mc_ai_unstuck.stucktimer = tick
			local pPos = Player.pos
			if ( pPos ) then
				--d(Distance2D ( pPos.x, pPos.y, mc_ai_unstuck.lastpos.x, mc_ai_unstuck.lastpos.y))				
				local bcheck = Distance2D ( pPos.x, pPos.y, mc_ai_unstuck.lastpos.x,  mc_ai_unstuck.lastpos.y) < 75
				if ( mc_ai_unstuck.ismoving == true ) then
					bcheck = Distance2D ( pPos.x, pPos.y, mc_ai_unstuck.lastpos.x,  mc_ai_unstuck.lastpos.y) < 110
				end
				
				if ( bcheck ) then					
					if ( mc_ai_unstuck.stuckcounter > 1 ) then
						d("Seems we are stuck?")
						if ( Player:CanMove() ) then
							Player:Jump()
						end
					end
					if ( mc_ai_unstuck.stuckcounter > 8 ) then
						mc_ai_unstuck.HandleStuck()
					end
					mc_ai_unstuck.stuckcounter = mc_ai_unstuck.stuckcounter + 1
				else
					mc_ai_unstuck.stuckcounter = 0
					if ( mc_ai_unstuck.ismoving == true ) then
						Player:UnSetMovement(2)
						Player:UnSetMovement(3)
						mc_ai_unstuck.ismoving = false
					end
				end
				mc_ai_unstuck.lastpos = Player.pos
			end
		end
	else
		mc_ai_unstuck.stuckcounter = 0
		if ( c_MoveToLeader.nearleader ) then return end
		if ( gBotMode == GetString("followmode") ) then return end
		-- Idle stuck check	
		if ( tick - mc_ai_unstuck.idletimer > 6000 ) then
			mc_ai_unstuck.idletimer = tick
			if ( not Player:IsCasting() and not Player:IsConversationOpen() and not Inventory:IsVendorOpened() ) then
				local pPos = Player.pos
				
				if ( pPos ) then				
					if ( Distance2D ( pPos.x, pPos.y, mc_ai_unstuck.lastpos.x,  mc_ai_unstuck.lastpos.y) < 75 ) then
						mc_ai_unstuck.idlecounter = mc_ai_unstuck.idlecounter + 1
						if ( mc_ai_unstuck.idlecounter > 10 ) then -- 60 seconds of doing nothing
							d("Our bot seems to be doing nothing anymore...")
							mc_ai_unstuck.idlecounter = 0
							mc_ai_unstuck.HandleStuck()							
						end
					else
						mc_ai_unstuck.idlecounter = 0
						mc_ai_unstuck.logoutTmr = 0
					end
				end
				mc_ai_unstuck.lastpos = Player.pos
			end
		end
	end	
end

mc_ai_unstuck.logoutTmr = 0
function mc_ai_unstuck.HandleStuck()
	if ( mc_global.now - mc_ai_unstuck.respawntimer < 30000 ) then
		ml_error("We used a waypoint for unstuck within the last 30 seconds already but are stuck again !?")
		ml_error("Stopping bot...")
		mc_global.togglebot("0")
			--ExitGW()
	else
		if ( not Player.inCombat ) then
			if ( Inventory:GetInventoryMoney() < 300 ) then
				ml_error("We may not have enough money for using the waypoint anymore...")
			end
			d("Trying to teleport to nearest waypoint for unstuck..")		
			-- safetycheck
			local id,wp = next(WaypointList("nearest,onmesh,notcontested,samezone"))
			if ( id and wp and wp.distance > 250 ) then
				if ( Player:RespawnAtClosestWaypoint() ) then
					mc_global.Wait(3000)
					mc_ai_unstuck.respawntimer = mc_global.now
				end
			else
				ml_error("We are at a waypoint but need to teleport again!? Something weird is going on, stopping bot")
				d("Logging out...")
				Player:Logout()
				mc_global.Wait(3000)
			end
			mc_ai_unstuck.logoutTmr = 0
		else
			if ( mc_ai_unstuck.logoutTmr == 0 ) then
				mc_ai_unstuck.logoutTmr = mc_global.now
			elseif ( mc_global.now - mc_ai_unstuck.logoutTmr > 60000 and gAutostartbot == "1" ) then
				mc_ai_unstuck.logoutTmr = mc_global.now
				d("Logging out...")
				Player:Logout()
				mc_global.Wait(3000)
			end
			
			d("Seems we are still in combat, cant use waypoint..TimeLeft till logout: "..tostring(60000 - (mc_global.now - mc_ai_unstuck.logoutTmr)))
			if ( c_NeedValidTarget:evaluate() ) then 
				e_SearchTarget:execute()
			else				
				e_KillTarget:execute()				
			end
		end
	end	
	mc_ai_unstuck.stuckcounter = 0	
end


function mc_ai_unstuck.stuckhandler( event, distmoved, stuckcount )
	
	if ( Player.alive == false) then 
		mc_ai_unstuck.Reset()
		return
	end
	
	d("STUCK? Distance Moved: "..tostring(distmoved) .. " Count: "..tostring(stuckcount) )
		
	if ( tonumber(stuckcount) < 20 and Player:CanMove() and mc_helper.HasBuffs(Player, mc_ai_unstuck.conditions) == false ) then --Fear and Immobilized
		Player:Jump()
		
		-- Add a try to kill blocking destroyable gadgets here?
		
		
		local i = math.random(0,1)
		if ( i == 0 ) then
			Player:SetMovement(2)
			mc_ai_unstuck.ismoving = true
		elseif ( i == 1 ) then
			Player:SetMovement(3)
			mc_ai_unstuck.ismoving = true
		end
	
	elseif ( tonumber(stuckcount) == 10 or tonumber(stuckcount) == 15) then
		ml_error("Trying to avoid stucked position..")
		-- Setting an avoidancearea at this point to hopefully find a way around it
		local pPos = Player.pos
		if ( pPos ) then
			--TODO: add proper checks for this , like is ther already a obstacle etcetc
			table.insert(mc_ai_unstuck.AvoidanceAreas, { x=pPos.x, y=pPos.y, z=pPos.z, r=50 })
			d("Adding AvoidanceArea with size "..tostring(50))
			NavigationManager:SetAvoidanceAreas(mc_ai_unstuck.AvoidanceAreas)
		end		
		Player:Stop() -- force recreation of path
		Player:SetMovement(1) -- try walking backwards a bit
		ml_global_information.Wait( 1000 )
		
	elseif ( tonumber(stuckcount) > 20 ) then
		ml_error("We are STUCK!")
		mc_ai_unstuck.HandleStuck()
	end
end

function mc_ai_unstuck.Reset()
	mc_ai_unstuck.stucktimer = 0
	mc_ai_unstuck.stuckcounter = 0
	mc_ai_unstuck.idletimer = 0
	mc_ai_unstuck.idlecounter = 0
	mc_ai_unstuck.respawntimer = 0
	mc_ai_unstuck.ismoving = false
	mc_ai_unstuck.lastpos = nil
	mc_ai_unstuck.logoutTmr = 0
	Player:UnSetMovement(1)
	Player:UnSetMovement(2)
	Player:UnSetMovement(3)
end

RegisterEventHandler("Gameloop.Stuck",mc_ai_unstuck.stuckhandler) -- gets called by c++ when using the navigationsystem
