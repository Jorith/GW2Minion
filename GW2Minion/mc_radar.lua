-- Main config file of GW2Minion

mc_radar = {}
mc_radar.MainWindow = { Name = "Radar", x=250, y=200 , width=200, height=200 }
mc_radar.visible = false

function mc_radar.OnUpdate( event, tickcount )
    
end

-- Module Event Handler
function mc_radar.HandleInit()	
    GUI_SetStatusBar("Initalizing GW2 Radar...")
        
    if ( Settings.GW2Minion.gRadar == nil ) then
        Settings.GW2Minion.gRadar = "0"
    end		
    if ( Settings.GW2Minion.g2dRadar == nil ) then
        Settings.GW2Minion.g2dRadar = "0"
    end	
    if ( Settings.GW2Minion.g3dRadar == nil ) then
        Settings.GW2Minion.g3dRadar = "0"
    end	
    if ( Settings.GW2Minion.g2dRadarFullScreen == nil ) then
        Settings.GW2Minion.g2dRadarFullScreen = "0"
    end	
    if ( Settings.GW2Minion.gRadarShowNode == nil ) then
        Settings.GW2Minion.gRadarShowNode = "0"
    end		
    if ( Settings.GW2Minion.gRadarShowPlayers == nil ) then
        Settings.GW2Minion.gRadarShowPlayers = "0"
    end	
    if ( Settings.GW2Minion.gRadarShowBattleNPCs == nil ) then
        Settings.GW2Minion.gRadarShowBattleNPCs = "0"
    end	
    if ( Settings.GW2Minion.gRadarShowOnlyEnemies == nil ) then
        Settings.GW2Minion.gRadarShowOnlyEnemies = "0"
    end		
	if ( Settings.GW2Minion.gRadarZoom == nil ) then
        Settings.GW2Minion.gRadarZoom = "10"
    end	
    if ( Settings.GW2Minion.gRadarX == nil ) then
        Settings.GW2Minion.gRadarX = 5
    end		
    if ( Settings.GW2Minion.gRadarY == nil ) then
        Settings.GW2Minion.gRadarY = 5
    end	
    
    GUI_NewWindow(mc_radar.MainWindow.Name,mc_radar.MainWindow.x,mc_radar.MainWindow.y,mc_radar.MainWindow.width,mc_radar.MainWindow.height)	
    GUI_NewCheckbox(mc_radar.MainWindow.Name,GetString("enableRadar"),"gRadar","Radar" );
    GUI_NewCheckbox(mc_radar.MainWindow.Name,GetString("enable2DRadar"),"g2dRadar","Radar" );
    GUI_NewCheckbox(mc_radar.MainWindow.Name,GetString("enable3DRadar"),"g3dRadar","Radar" );
    GUI_NewCheckbox(mc_radar.MainWindow.Name,GetString("fullscreenRadar"),"g2dRadarFullScreen","Radar" );
	GUI_NewNumeric(mc_radar.MainWindow.Name,"Zoom","gRadarZoom","Radar","1","200");
    GUI_NewCheckbox(mc_radar.MainWindow.Name,GetString("showNodes"),"gRadarShowNode","RadarSettings" );
    GUI_NewCheckbox(mc_radar.MainWindow.Name,GetString("showPlayers"),"gRadarShowPlayers","RadarSettings" );
    GUI_NewCheckbox(mc_radar.MainWindow.Name,GetString("showBattleNPCs"),"gRadarShowBattleNPCs","RadarSettings" );
	GUI_NewCheckbox(mc_radar.MainWindow.Name,GetString("showOnlyEnemies"),"gRadarShowOnlyEnemies","RadarSettings" );	
        
    GUI_NewNumeric(mc_radar.MainWindow.Name,GetString("xPos"),"gRadarX","RadarSettings" );
    GUI_NewNumeric(mc_radar.MainWindow.Name,GetString("yPos"),"gRadarY","RadarSettings" );
    
    gRadar = Settings.GW2Minion.gRadar
    g2dRadar = Settings.GW2Minion.g2dRadar
    g3dRadar = Settings.GW2Minion.g3dRadar
    g2dRadarFullScreen = Settings.GW2Minion.g2dRadarFullScreen
	gRadarZoom = Settings.GW2Minion.gRadarZoom
    gRadarShowNode = Settings.GW2Minion.gRadarShowNode
    gRadarShowPlayers = Settings.GW2Minion.gRadarShowPlayers
    gRadarShowBattleNPCs = Settings.GW2Minion.gRadarShowBattleNPCs
	gRadarShowOnlyEnemies = Settings.GW2Minion.gRadarShowOnlyEnemies
    gRadarX = Settings.GW2Minion.gRadarX
    gRadarY = Settings.GW2Minion.gRadarY
    
	if ( HackManager ) then
		if ( gRadar == "0") then HackManager:SetRadarSettings("gRadar",false) else HackManager:SetRadarSettings("gRadar",true) end
		if ( g2dRadar == "0") then HackManager:SetRadarSettings("g2dRadar",false) else HackManager:SetRadarSettings("g2dRadar",true) end
		if ( g3dRadar == "0") then HackManager:SetRadarSettings("g3dRadar",false) else HackManager:SetRadarSettings("g3dRadar",true) end
		if ( g2dRadarFullScreen == "0") then HackManager:SetRadarSettings("g2dRadarFullScreen",false) else HackManager:SetRadarSettings("g2dRadarFullScreen",true) end
		if ( gRadarZoom == "0") then HackManager:SetRadarSettings("gRadarZoom","5") end	
		if ( gRadarShowNode == "0") then HackManager:SetRadarSettings("gRadarShowNode",false) else HackManager:SetRadarSettings("gRadarShowNode",true) end
		if ( gRadarShowPlayers == "0") then HackManager:SetRadarSettings("gRadarShowPlayers",false) else HackManager:SetRadarSettings("gRadarShowPlayers",true) end
		if ( gRadarShowBattleNPCs == "0") then HackManager:SetRadarSettings("gRadarShowBattleNPCs",false) else HackManager:SetRadarSettings("gRadarShowBattleNPCs",true) end
		if ( gRadarShowOnlyEnemies == "0") then HackManager:SetRadarSettings("gRadarShowOnlyEnemies",false) else HackManager:SetRadarSettings("gRadarShowOnlyEnemies",true) end
		
		if ( tonumber(gRadarX) ~= nil) then HackManager:SetRadarSettings("gRadarX",tonumber(gRadarX)) end
		if ( tonumber(gRadarY) ~= nil) then HackManager:SetRadarSettings("gRadarY",tonumber(gRadarY)) end
    end
	
	GUI_NewButton(mc_radar.MainWindow.Name,"Cant See Radar? Press Me","Dev.ChangeMDepth")
	GUI_UnFoldGroup(mc_radar.MainWindow.Name,"Radar");	
    GUI_WindowVisible(mc_radar.MainWindow.Name,false)
end

function mc_radar.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if (k == "gRadar" or
            k == "g2dRadar" or 			
            k == "g3dRadar" or
            k == "g2dRadarFullScreen" or
            k == "gRadarShowNode" or
            k == "gRadarShowPlayers" or
            k == "gRadarShowBattleNPCs" or	
			k == "gRadarShowOnlyEnemies")
        then
            Settings.GW2Minion[tostring(k)] = v
            if ( v == "0") then
                HackManager:SetRadarSettings(k,false)
            else
                HackManager:SetRadarSettings(k,true)
            end
        end
        if ( k == "gRadarX" and tonumber(v) ~= nil) then
            Settings.GW2Minion[tostring(k)] = v*10
            HackManager:SetRadarSettings(k,tonumber(v*10))
        end
        if ( k == "gRadarY" and tonumber(v) ~= nil) then
            Settings.GW2Minion[tostring(k)] = v*10
            HackManager:SetRadarSettings(k,tonumber(v*10))
        end
		if ( k == "gRadarZoom" and tonumber(v) ~= nil) then
            Settings.GW2Minion[tostring(k)] = v
            HackManager:SetRadarSettings(k,tonumber(v))
        end
		
    end
    GUI_RefreshWindow(mc_radar.MainWindow.Name)
end

function mc_radar.ToggleMenu()
    if (mc_radar.visible) then
        GUI_WindowVisible(mc_radar.MainWindow.Name,false)	
        mc_radar.visible = false
    else
		local wnd = GUI_GetWindowInfo("MinionBot")	
        GUI_MoveWindow( mc_radar.MainWindow.Name, wnd.x,wnd.y+wnd.height)
		GUI_WindowVisible(mc_radar.MainWindow.Name,true)	
        mc_radar.visible = true
    end
end

-- Register Event Handlers
RegisterEventHandler("Module.Initalize",mc_radar.HandleInit)
RegisterEventHandler("Radar.toggle", mc_radar.ToggleMenu)
RegisterEventHandler("GUI.Update",mc_radar.GUIVarUpdate)