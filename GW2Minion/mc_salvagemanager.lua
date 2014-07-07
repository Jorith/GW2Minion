mc_salvagemanager = {}
-- SalvageManager for adv. sell customization
mc_salvagemanager.mainwindow = { name = GetString("salvagemanager"), x = 350, y = 50, w = 250, h = 350}
mc_salvagemanager.editwindow = { name = GetString("salvageeditor"), w = 250, h = 350}
mc_salvagemanager.filterList = {}
mc_salvagemanager.visible = false
mc_salvagemanager.ticks = 0


function mc_salvagemanager.ModuleInit()
	
	if (Settings.GW2Minion.SalvageManager_FilterList == nil) then
		Settings.GW2Minion.SalvageManager_FilterList = {
		{
			itemtype = "Weapon",
			name = "Weapons_Junk",
			rarity = "Junk",
			preferedKit = "None",
		},
		
		{
			itemtype = "Weapon",
			name = "Weapons_Common",
			rarity = "Common",
			preferedKit = "None",
		},
		
		{
			itemtype = "Weapon",
			name = "Weapons_Masterwork",
			rarity = "Masterwork",
			preferedKit = "None",
		},
		
		{
			itemtype = "Weapon",
			name = "Weapons_Fine",
			rarity = "Fine",
			preferedKit = "None",
		},
		
		{
			itemtype = "Armor",
			name = "Armor_Junk",
			rarity = "Junk",
			preferedKit = "None",
		},
		
		{
			itemtype = "Armor",
			name = "Armor_Common",
			rarity = "Common",
			preferedKit = "None",
		},
		
		{
			itemtype = "Armor",
			name = "Armor_Masterwork",
			rarity = "Masterwork",
			preferedKit = "None",
		},
		
		{
			itemtype = "Armor",
			name = "Armor_Fine",
			rarity = "Fine",
			preferedKit = "None",
		},
		
		}
	end
	if (Settings.GW2Minion.SalvageManager_Active == nil ) then
		Settings.GW2Minion.SalvageManager_Active = "1"
	end
	if (Settings.GW2Minion.SalvageManager_ItemIDInfo == nil ) then
		Settings.GW2Minion.SalvageManager_ItemIDInfo = {}
	end

	
	-- MANAGER WINDOW
	GUI_NewButton(mc_global.window.name, GetString("salvage"), "SalvageManager.toggle",GetString("vendorSettings"))
	
	-- Salvage SETTINGS
	GUI_NewWindow(mc_salvagemanager.mainwindow.name,mc_salvagemanager.mainwindow.x,mc_salvagemanager.mainwindow.y,mc_salvagemanager.mainwindow.w,mc_salvagemanager.mainwindow.h,true)
	GUI_NewCheckbox(mc_salvagemanager.mainwindow.name,GetString("active"),"SalvageManager_Active",GetString("salvage"))
	GUI_NewField(mc_salvagemanager.mainwindow.name,GetString("newfiltername"),"SalvageManager_NewFilterName",GetString("salvage"))
	GUI_NewButton(mc_salvagemanager.mainwindow.name,GetString("newfilter"),"SalvageManager_NewFilter",GetString("salvage"))
	RegisterEventHandler("SalvageManager_NewFilter",mc_salvagemanager.filterWindow)
	
	GUI_SizeWindow(mc_salvagemanager.mainwindow.name,mc_salvagemanager.mainwindow.w,mc_salvagemanager.mainwindow.h)
	GUI_UnFoldGroup(mc_salvagemanager.mainwindow.name,GetString("salvage"))
	GUI_WindowVisible(mc_salvagemanager.mainwindow.name,false)
	
	-- Salvage IDs	
	GUI_NewComboBox(mc_salvagemanager.mainwindow.name,GetString("salvageByIDtems"),"SalvageManager_ItemToSalvage",GetString("salvageByID"),"")
	GUI_NewButton(mc_salvagemanager.mainwindow.name,GetString("salvageByIDAddItem"),"SalvageManager_AdditemID",GetString("salvageByID"))
	RegisterEventHandler("SalvageManager_AdditemID",mc_salvagemanager.AddItemID)
	GUI_NewComboBox(mc_salvagemanager.mainwindow.name,GetString("salvageItemList"),"SalvageManager_ItemIDList",GetString("salvageByID"),"")
	SalvageManager_ItemIDList = "None"
	GUI_NewButton(mc_salvagemanager.mainwindow.name,GetString("salvageByIDRemoveItem"),"SalvageManager_RemoveitemID",GetString("salvageByID"))
	RegisterEventHandler("SalvageManager_RemoveitemID",mc_salvagemanager.RemoveItemID)
	
	-- Salvage FILTERS
	GUI_UnFoldGroup(mc_salvagemanager.mainwindow.name,GetString("salvagefilters"))
	
	-- EDITOR WINDOW
	GUI_NewWindow(mc_salvagemanager.editwindow.name,mc_salvagemanager.mainwindow.x+mc_salvagemanager.mainwindow.w,mc_salvagemanager.mainwindow.y,mc_salvagemanager.editwindow.w,mc_salvagemanager.editwindow.h,true)
	GUI_NewField(mc_salvagemanager.editwindow.name,GetString("name"),"SalvageManager_Name",GetString("filterdetails"))
	GUI_NewComboBox(mc_salvagemanager.editwindow.name,GetString("itemtype"),"SalvageManager_Itemtype",GetString("filterdetails"),"")
	GUI_NewComboBox(mc_salvagemanager.editwindow.name,GetString("rarity"),"SalvageManager_Rarity",GetString("filterdetails"),GetString("rarityNone")..","..GetString("rarityJunk")..","..GetString("rarityCommon")..","..GetString("rarityFine")..","..GetString("rarityMasterwork")..","..GetString("rarityRare")..","..GetString("rarityExotic"))
	GUI_NewComboBox(mc_salvagemanager.editwindow.name,GetString("preferedKit"),"SalvageManager_Kit",GetString("filterdetails"),GetString("rarityNone")..","..GetString("buyCrude")..","..GetString("buyBasic")..","..GetString("buyFine")..","..GetString("buyJourneyman")..","..GetString("buyMaster")..","..GetString("mysticKit")..","..GetString("unlimitedKit"))
	GUI_NewButton(mc_salvagemanager.editwindow.name,GetString("delete"),"SalvageManager_DeleteFilter")
	RegisterEventHandler("SalvageManager_DeleteFilter",mc_salvagemanager.deleteFilter)
	
	GUI_SizeWindow(mc_salvagemanager.editwindow.name,mc_salvagemanager.editwindow.w,mc_salvagemanager.editwindow.h)
	GUI_UnFoldGroup(mc_salvagemanager.editwindow.name,GetString("filterdetails"))
	GUI_WindowVisible(mc_salvagemanager.editwindow.name,false)

	local i,_ = next(GW2.ITEMTYPE)
	local list = "None"
	while (i ~= nil) do
		list = list .. "," .. i
		i,_ = next(GW2.ITEMTYPE, i)
	end
	SalvageManager_Itemtype_listitems = list
	
	SalvageManager_Active = Settings.GW2Minion.SalvageManager_Active
	SalvageManager_ItemIDInfo = Settings.GW2Minion.SalvageManager_ItemIDInfo
	if (Player) then
		mc_salvagemanager.updateItemIDList()
		mc_salvagemanager.filterList = Settings.GW2Minion.SalvageManager_FilterList
		mc_salvagemanager.refreshFilterlist()
		mc_salvagemanager.UpdateSalvageSingleItemList()
	end
end

--Fill the "Salvage Single Item"-dropdownlist
function mc_salvagemanager.UpdateSalvageSingleItemList()
	local list = "None"
	local iList = Inventory("salvagable")
	if (TableSize(iList)>0)then
		local i,item = next(iList)
		while (i and item) do
			if (item.name and item.name ~= "" )then
				list = list .. "," .. item.name
			end		
			i,item=next(iList,i)
		end
	end
	SalvageManager_ItemToSalvage_listitems = list
end

--Add itemID to itemIDlist.
function mc_salvagemanager.AddItemID()
	if ( SalvageManager_ItemToSalvage and SalvageManager_ItemToSalvage ~= "None" and SalvageManager_ItemToSalvage ~= "" ) then
		-- Make sure this item is not already in our SellList
			local id,lItem = next(SalvageManager_ItemIDInfo)
			local found = false
			while (id and lItem) do
				if (SalvageManager_ItemToSalvage == lItem.name) then
					return
				end
				id,lItem = next(SalvageManager_ItemIDInfo, id)
			end
		
		-- Find Item by Name in Inventory
		local iList = Inventory("")
		local iItem = nil
		if (TableSize(iList)>0)then
			local i,item = next(iList)
			while (i and item) do				
				if (item.name and item.name ~= "" and item.name == SalvageManager_ItemToSalvage)then
					iItem = item
					break
				end		
				i,item=next(iList,i)
			end
		end
		if (iItem) then		
			table.insert(SalvageManager_ItemIDInfo, {name = iItem.name, itemID = iItem.itemID})		
		end
		Settings.GW2Minion.SalvageManager_ItemIDInfo = SalvageManager_ItemIDInfo
		mc_salvagemanager.updateItemIDList()		
		SalvageManager_ItemToSalvage = "None"
	end	
end

--Remove itemIDlist entry
function mc_salvagemanager.RemoveItemID()
	if ( SalvageManager_ItemIDList and SalvageManager_ItemIDList ~= "None" and SalvageManager_ItemIDList~="") then
		_,start = string.find(SalvageManager_ItemIDList, "-")
		local iID = string.sub(SalvageManager_ItemIDList, start + 2, -1)
		local id,item = next(SalvageManager_ItemIDInfo)
		while (id and item) do	
			if (item.itemID == tonumber(iID)) then				
				table.remove(SalvageManager_ItemIDInfo, id)
			end
			id,item = next(SalvageManager_ItemIDInfo, id)
		end
		Settings.GW2Minion.SalvageManager_ItemIDInfo = SalvageManager_ItemIDInfo
		mc_salvagemanager.updateItemIDList()
	end
end

--Update itemID list.
function mc_salvagemanager.updateItemIDList()
	local list = "None"
	SalvageManager_ItemIDs = ""
	local _,item = next(SalvageManager_ItemIDInfo)
	while (item) do
		list = list .. "," .. item.name .. " - " .. item.itemID
		if (SalvageManager_ItemIDs == "") then
			SalvageManager_ItemIDs = item.itemID
		else
			SalvageManager_ItemIDs = SalvageManager_ItemIDs .. "," .. item.itemID
		end
		_,item = next(SalvageManager_ItemIDInfo, _)
	end
	SalvageManager_ItemIDList = "None"
	SalvageManager_ItemIDList_listitems = list
end

--Create filtered salvage item list.
function mc_salvagemanager.createItemList()
	local items = Inventory("salvagable,exclude_contentid="..mc_blacklist.GetExcludeString(GetString("salvageItems")))
	local filteredItems = {}
	if (items) then
		local id, item = next(items)
		while (id and item) do
			if (item.salvagable and item.soulbound == false) then
				local addItem = false
				local _, filter = next(mc_salvagemanager.filterList)
				while (filter) do
					if (mc_salvagemanager.validFilter(filter)) then
						if ((filter.rarity == nil or filter.rarity == "None" or GW2.ITEMRARITY[filter.rarity] == item.rarity) and
						(filter.itemtype == nil or filter.itemtype == "None" or GW2.ITEMTYPE[filter.itemtype] == item.itemtype)) then
							addItem = true
						end
					end
					_, filter = next(mc_salvagemanager.filterList, _)
				end
				-- Check for single itemlist
				local iID,lItem = next(SalvageManager_ItemIDInfo)
				while (iID and lItem) do
					if (item.itemID == lItem.itemID) then
						addItem = true
						break
					end
					iID,lItem = next(SalvageManager_ItemIDInfo, iID)
				end	
				
				if (addItem) then
					table.insert(filteredItems, item)
				end
			end
			id, item = next(items, id)
		end
		if (filteredItems) then
			return filteredItems
		end
	end
	return false
end


--Check if filter is valid: 
function mc_salvagemanager.validFilter(filter)
	if (filter.itemtype ~= "None" and filter.itemtype ~= nil and
	filter.rarity ~= "None" and filter.rarity ~= nil) then
		return true
	elseif (filter.rarity == "Junk") then
		return true
	end
	return false
end

--Have Salvagable item.
function mc_salvagemanager.haveSalvagebleItem()
	if (ValidTable(mc_salvagemanager.createItemList())) then
		return true
	end
	return false
end


--New filter/Load filter.
function mc_salvagemanager.filterWindow(filterNumber)
	if (mc_salvagemanager.filterList[filterNumber] == nil and not mc_salvagemanager.filterExcists() and SalvageManager_NewFilterName ~= nil and SalvageManager_NewFilterName ~= "") then
		filterNumber = TableSize(mc_salvagemanager.filterList) + 1
		mc_salvagemanager.filterList[filterNumber] = {name = SalvageManager_NewFilterName, rarity = "None", itemtype = "None", preferedKit = "None"}
		mc_salvagemanager.refreshFilterlist()
		Settings.GW2Minion.SalvageManager_FilterList = mc_salvagemanager.filterList
	end
	if (string.find(filterNumber, "SalvageManager_Filter")) then
		filterNumber = string.gsub(filterNumber, "SalvageManager_Filter", "")
		filterNumber = tonumber(filterNumber)
	end
	if (mc_salvagemanager.filterList[filterNumber] ~= nil) then
		SalvageManager_Name = mc_salvagemanager.filterList[filterNumber].name or "None"
		SalvageManager_Rarity = mc_salvagemanager.filterList[filterNumber].rarity or "None"
		SalvageManager_Itemtype = mc_salvagemanager.filterList[filterNumber].itemtype or "None"
		SalvageManager_Kit = mc_salvagemanager.filterList[filterNumber].preferedKit or "None"
		GUI_WindowVisible(mc_salvagemanager.editwindow.name,true)
	end
	SalvageManager_CurFilter = filterNumber
end

--Delete filter.
function mc_salvagemanager.deleteFilter()
	table.remove(mc_salvagemanager.filterList, SalvageManager_CurFilter)
	Settings.GW2Minion.SalvageManager_FilterList = mc_salvagemanager.filterList
	mc_salvagemanager.refreshFilterlist()
end

--Check if filter name excists.
function mc_salvagemanager.filterExcists()
	local i,v = next(mc_salvagemanager.filterList)
	while (i and v) do
		if (SalvageManager_NewFilterName == v.name) then
			return true
		end
		i,v = next(mc_salvagemanager.filterList, i)
	end
	return false
end

--Refresh filters.
function mc_salvagemanager.refreshFilterlist()
	GUI_Delete(mc_salvagemanager.mainwindow.name,GetString("salvagefilters"))
	local i, v = next(mc_salvagemanager.filterList)
	while (i and v) do
		GUI_NewButton(mc_salvagemanager.mainwindow.name, mc_salvagemanager.filterList[i].name, "SalvageManager_Filter" .. i,GetString("salvagefilters"))
		RegisterEventHandler("SalvageManager_Filter" .. i ,mc_salvagemanager.filterWindow)
		i, v = next(mc_salvagemanager.filterList, i)
	end
	SalvageManager_Name = nil
	SalvageManager_Rarity = nil
	SalvageManager_Itemtype = nil
	SalvageManager_Kit = nil
	GUI_WindowVisible(mc_salvagemanager.editwindow.name,false)
	GUI_UnFoldGroup(mc_salvagemanager.mainwindow.name,GetString("salvagefilters"))
end

--Save filters.
function mc_salvagemanager.GUIVarUpdate(Event, NewVals, OldVals)
	for k,v in pairs(NewVals) do
		if ( k == "SalvageManager_Active" ) then Settings.GW2Minion[tostring(k)] = v
		elseif (k == "SalvageManager_Name"  or
				k == "SalvageManager_Rarity" or
				k == "SalvageManager_Itemtype" or 
				k == "SalvageManager_Kit")
		then
		mc_salvagemanager.filterList[SalvageManager_CurFilter].rarity = SalvageManager_Rarity
		mc_salvagemanager.filterList[SalvageManager_CurFilter].itemtype = SalvageManager_Itemtype
		mc_salvagemanager.filterList[SalvageManager_CurFilter].preferedKit = SalvageManager_Kit
		end
		Settings.GW2Minion.SalvageManager_FilterList = mc_salvagemanager.filterList
	end
end


function mc_salvagemanager.ToggleMenu()
	if (mc_salvagemanager.visible) then
		GUI_WindowVisible(mc_salvagemanager.mainwindow.name,false)
		GUI_WindowVisible(mc_salvagemanager.editwindow.name,false)
		mc_salvagemanager.visible = false
	else
		local wnd = GUI_GetWindowInfo("MinionBot")
		GUI_MoveWindow( mc_salvagemanager.mainwindow.name, wnd.x+wnd.width,wnd.y) 
		GUI_WindowVisible(mc_salvagemanager.mainwindow.name,true)
		mc_salvagemanager.visible = true
		mc_salvagemanager.UpdateSalvageSingleItemList()
	end
end


RegisterEventHandler("SalvageManager.toggle", mc_salvagemanager.ToggleMenu)
RegisterEventHandler("GUI.Update",mc_salvagemanager.GUIVarUpdate)
RegisterEventHandler("Module.Initalize",mc_salvagemanager.ModuleInit)