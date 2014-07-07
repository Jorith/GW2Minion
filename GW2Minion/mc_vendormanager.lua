-- Takes care of Buying and Selling of Items/Tools logic
mc_vendormanager = {}
mc_vendormanager.sellmainwindow = { name = GetString("sellmanager"), x = 350, y = 50, w = 250, h = 350}
mc_vendormanager.selleditwindow = { name = GetString("selleditor"), w = 250, h = 350}
mc_vendormanager.filterList = {}
mc_vendormanager.sellwindowVisible = false

mc_vendormanager.buymainwindow = { name = GetString("buymanager"), x = 350, y = 50, w = 250, h = 350}
mc_vendormanager.buywindowvisible = false
mc_vendormanager.tools = {
	 -- sickles 1= lowest quality , 6 = orichalcum
	 [0] = 
	 {
	  [1] = 23029,
	  [2] = 22992, -- lvl10
	  [3] = 23004, -- lvl20
	  [4] = 23005, -- lvl30
	  [5] = 23008, -- lvl45
	  [6] = 22997, -- lvl60
	 },
	 -- logging 1= lowest quality , 6 = orichalcum
	 [1] = 
	 {
	  [1] = 23030,
	  [2] = 22994,
	  [3] = 23002,
	  [4] = 23006,
	  [5] = 23009,
	  [6] = 23000,
	 },
	 -- mining 1= lowest quality , 6 = orichalcum
	 [2] =
	 {
	  [1] = 23031,
	  [2] = 22995,
	  [3] = 23003,
	  [4] = 23007,
	  [5] = 23010,
	  [6] = 23001,
	 },
	 -- salvagingkits 0= lowest quality 
	 [3] = 
	 {
	  [0] = 23038, -- Crude Salvage Kit (rarity 1)
	  [1] = 23040, -- Basic Salvage Kit (rarity 1)
	  [2] = 23041, -- Fine (rarity 2)
	  [3] = 23042, -- Journeyman (rarity 3)
	  [4] = 23043  -- Master (rarity 4)
	 }
 }

 mc_vendormanager.LevelRestrictions = 
 { 
 	 --level restrictions	
	[1] = 0,
	[2] = 10, -- lvl10
	[3] = 20, -- lvl20
	[4] = 30, -- lvl30
	[5] = 45, -- lvl45
	[6] = 60, -- lvl60	
}

function mc_vendormanager.ModuleInit()
	
	-- SELLING
	if (Settings.GW2Minion.SellManager_FilterList == nil) then
		Settings.GW2Minion.SellManager_FilterList = {
		{
			itemID = "None",
			itemtype = "Weapon",
			name = "Weapons_Junk",
			rarity = "Junk",
			soulbound = "false",
			weapontype = "None",
		},
		
		{
			itemID = "None",
			itemtype = "Weapon",
			name = "Weapons_Common",
			rarity = "Common",
			soulbound = "false",
			weapontype = "None",
		},
		
		{
			itemID = "None",
			itemtype = "Weapon",
			name = "Weapons_Masterwork",
			rarity = "Masterwork",
			soulbound = "false",
			weapontype = "None",
		},
		
		{
			itemID = "None",
			itemtype = "Weapon",
			name = "Weapons_Fine",
			rarity = "Fine",
			soulbound = "false",
			weapontype = "None",
		},
		
		{
			itemID = "None",
			itemtype = "Armor",
			name = "Armor_Junk",
			rarity = "Junk",
			soulbound = "false",
			weapontype = "None",
		},
		
		{
			itemID = "None",
			itemtype = "Armor",
			name = "Armor_Common",
			rarity = "Common",
			soulbound = "false",
			weapontype = "None",
		},
		
		{
			itemID = "None",
			itemtype = "Armor",
			name = "Armor_Masterwork",
			rarity = "Masterwork",
			soulbound = "false",
			weapontype = "None",
		},
		
		{
			itemID = "None",
			itemtype = "Armor",
			name = "Armor_Fine",
			rarity = "Fine",
			soulbound = "false",
			weapontype = "None",
		},
		
		}
	end
	if (Settings.GW2Minion.SellManager_Active == nil ) then
		Settings.GW2Minion.SellManager_Active = "1"
	end
	if (Settings.GW2Minion.SellManager_ItemIDInfo == nil ) then
		Settings.GW2Minion.SellManager_ItemIDInfo = {}
	end
	if (Settings.GW2Minion.gRepairDamageLimit == nil ) then
		Settings.GW2Minion.gRepairDamageLimit = "5" -- Repair when more than 5 damaged items
	end
	if (Settings.GW2Minion.gRepairBrokenLimit == nil ) then
		Settings.GW2Minion.gRepairBrokenLimit = "2" -- Repair when more than 5 broken items
	end
	
		--REPAIR
	GUI_NewNumeric(mc_global.window.name,GetString("repairDamaged"),"gRepairDamageLimit",GetString("vendorSettings"),"0","15");
	GUI_NewNumeric(mc_global.window.name,GetString("repairBroken"),"gRepairBrokenLimit",GetString("vendorSettings"),"0","15");
	gRepairDamageLimit = Settings.GW2Minion.gRepairDamageLimit
	gRepairBrokenLimit = Settings.GW2Minion.gRepairBrokenLimit
	
	-- SELLMANAGER WINDOW
	GUI_NewButton(mc_global.window.name, GetString("sellGroup"), "sellManager.toggle",GetString("vendorSettings"))	
	-- SELL SETTINGS
	GUI_NewWindow(mc_vendormanager.sellmainwindow.name,mc_vendormanager.sellmainwindow.x,mc_vendormanager.sellmainwindow.y,mc_vendormanager.sellmainwindow.w,mc_vendormanager.sellmainwindow.h,true)
	GUI_NewCheckbox(mc_vendormanager.sellmainwindow.name,GetString("active"),"SellManager_Active",GetString("sellGroup"))
	GUI_NewField(mc_vendormanager.sellmainwindow.name,GetString("newfiltername"),"SellManager_NewFilterName",GetString("sellGroup"))
	GUI_NewButton(mc_vendormanager.sellmainwindow.name,GetString("newfilter"),"SellManager_NewFilter",GetString("sellGroup"))
	RegisterEventHandler("SellManager_NewFilter",mc_vendormanager.filterWindow)	
	GUI_SizeWindow(mc_vendormanager.sellmainwindow.name,mc_vendormanager.sellmainwindow.w,mc_vendormanager.sellmainwindow.h)
	GUI_UnFoldGroup(mc_vendormanager.sellmainwindow.name,GetString("sellGroup"))
	GUI_WindowVisible(mc_vendormanager.sellmainwindow.name,false)	
	GUI_UnFoldGroup(mc_vendormanager.sellmainwindow.name,GetString("sellfilters"))	
	-- SELL BY ID FILTER
	GUI_NewComboBox(mc_vendormanager.sellmainwindow.name,GetString("sellByIDtems"),"SellManager_ItemToSell",GetString("sellByID"),"")
	GUI_NewButton(mc_vendormanager.sellmainwindow.name,GetString("sellByIDAddItem"),"SellManager_AdditemID",GetString("sellByID"))
	RegisterEventHandler("SellManager_AdditemID",mc_vendormanager.AddItemID)
	GUI_NewComboBox(mc_vendormanager.sellmainwindow.name,GetString("sellItemList"),"SellManager_ItemIDList",GetString("sellByID"),"")
	SellManager_ItemIDList = "None"
	GUI_NewButton(mc_vendormanager.sellmainwindow.name,GetString("sellByIDRemoveItem"),"SellManager_RemoveitemID",GetString("sellByID"))
	RegisterEventHandler("SellManager_RemoveitemID",mc_vendormanager.RemoveItemID)
	-- SELLEDITOR WINDOW
	GUI_NewWindow(mc_vendormanager.selleditwindow.name,mc_vendormanager.sellmainwindow.x+mc_vendormanager.sellmainwindow.w,mc_vendormanager.sellmainwindow.y,mc_vendormanager.selleditwindow.w,mc_vendormanager.selleditwindow.h,true)
	GUI_NewField(mc_vendormanager.selleditwindow.name,GetString("name"),"SellManager_Name",GetString("filterdetails"))
	GUI_NewComboBox(mc_vendormanager.selleditwindow.name,GetString("soulbound"),"SellManager_Soulbound",GetString("filterdetails"),"true,false,either")
	GUI_NewComboBox(mc_vendormanager.selleditwindow.name,GetString("itemtype"),"SellManager_Itemtype",GetString("filterdetails"),"")
	GUI_NewComboBox(mc_vendormanager.selleditwindow.name,GetString("rarity"),"SellManager_Rarity",GetString("filterdetails"),GetString("rarityNone")..","..GetString("rarityJunk")..","..GetString("rarityCommon")..","..GetString("rarityFine")..","..GetString("rarityMasterwork")..","..GetString("rarityRare")..","..GetString("rarityExotic"));
	GUI_NewComboBox(mc_vendormanager.selleditwindow.name,GetString("weapontype"),"SellManager_Weapontype",GetString("filterdetails"),"")	
	GUI_NewButton(mc_vendormanager.selleditwindow.name,GetString("delete"),"SellManager_DeleteFilter")
	RegisterEventHandler("SellManager_DeleteFilter",mc_vendormanager.deleteFilter)	
	GUI_SizeWindow(mc_vendormanager.selleditwindow.name,mc_vendormanager.selleditwindow.w,mc_vendormanager.selleditwindow.h)
	GUI_UnFoldGroup(mc_vendormanager.selleditwindow.name,GetString("filterdetails"))
	GUI_WindowVisible(mc_vendormanager.selleditwindow.name,false)

	local i,_ = next(GW2.ITEMTYPE)
	local list = "None"
	while (i ~= nil) do
		list = list .. "," .. i
		i,_ = next(GW2.ITEMTYPE, i)
	end
	SellManager_Itemtype_listitems = list
	local i,_ = next(GW2.WEAPONTYPE)
	local list = "None"
	while (i ~= nil) do
		list = list .. "," .. i
		i,_ = next(GW2.WEAPONTYPE, i)
	end
	SellManager_Weapontype_listitems = list
		
	SellManager_Active = Settings.GW2Minion.SellManager_Active
	SellManager_ItemIDInfo = Settings.GW2Minion.SellManager_ItemIDInfo
	mc_vendormanager.filterList = Settings.GW2Minion.SellManager_FilterList	
	mc_vendormanager.refreshFilterlist()
	
	--********
	-- BUYING
	--********
	if (Settings.GW2Minion.BuyManager_Active == nil ) then
		Settings.GW2Minion.BuyManager_Active = "1"
	end
	
	if (Settings.GW2Minion.BuyManager_buyAllKits == nil ) then
		Settings.GW2Minion.BuyManager_buyAllKits = "0"
	end
	
	if (Settings.GW2Minion.BuyManager_Crudekit == nil ) then
		Settings.GW2Minion.BuyManager_Crudekit = "1"
	end
	
	if (Settings.GW2Minion.BuyManager_Basickit == nil ) then
		Settings.GW2Minion.BuyManager_Basickit = "1"
	end
	
	if (Settings.GW2Minion.BuyManager_Finekit == nil ) then
		Settings.GW2Minion.BuyManager_Finekit = "1"
	end
	
	if (Settings.GW2Minion.BuyManager_Journeymankit == nil ) then
		Settings.GW2Minion.BuyManager_Journeymankit = "1"
	end
	
	if (Settings.GW2Minion.BuyManager_Masterkit == nil ) then
		Settings.GW2Minion.BuyManager_Masterkit = "0"
	end
	
	if (Settings.GW2Minion.BuyManager_sStacks == nil ) then
		Settings.GW2Minion.BuyManager_sStacks = 1
	end
	
	if (Settings.GW2Minion.BuyManager_copperTools == nil ) then
		Settings.GW2Minion.BuyManager_copperTools = "1"
	end
	
	if (Settings.GW2Minion.BuyManager_ironTools == nil ) then
		Settings.GW2Minion.BuyManager_ironTools = "1"
	end
	
	if (Settings.GW2Minion.BuyManager_steelTools == nil ) then
		Settings.GW2Minion.BuyManager_steelTools = "1"
	end
	
	if (Settings.GW2Minion.BuyManager_darksteelTools == nil ) then
		Settings.GW2Minion.BuyManager_darksteelTools = "1"
	end
	
	if (Settings.GW2Minion.BuyManager_mithrilTools == nil ) then
		Settings.GW2Minion.BuyManager_mithrilTools = "1"
	end
	
	if (Settings.GW2Minion.BuyManager_orichalcumTools == nil ) then
		Settings.GW2Minion.BuyManager_orichalcumTools = "1"
	end
	
	if (Settings.GW2Minion.BuyManager_toolStacks == nil ) then
		Settings.GW2Minion.BuyManager_toolStacks = 1
	end
	
	-- BUYMANAGER WINDOW
	GUI_NewButton(mc_global.window.name, GetString("buyGroup"), "buymanager.toggle",GetString("vendorSettings"))
	
	-- BUY SETTINGS
	GUI_NewWindow(mc_vendormanager.buymainwindow.name,mc_vendormanager.buymainwindow.x,mc_vendormanager.buymainwindow.y,mc_vendormanager.buymainwindow.w,mc_vendormanager.buymainwindow.h,true)
	GUI_NewCheckbox(mc_vendormanager.buymainwindow.name,GetString("active"),"BuyManager_Active",GetString("buyGroup"))
	--GUI_NewCheckbox(mc_vendormanager.buymainwindow.name,GetString("buyAllKits"),"BuyManager_buyAllKits",GetString("buyGroup"))
	
	GUI_NewCheckbox(mc_vendormanager.buymainwindow.name,GetString("buyCrude"),"BuyManager_Crudekit",GetString("salvageKits"))
	GUI_NewCheckbox(mc_vendormanager.buymainwindow.name,GetString("buyBasic"),"BuyManager_Basickit",GetString("salvageKits"))
	GUI_NewCheckbox(mc_vendormanager.buymainwindow.name,GetString("buyFine"),"BuyManager_Finekit",GetString("salvageKits"))
	GUI_NewCheckbox(mc_vendormanager.buymainwindow.name,GetString("buyJourneyman"),"BuyManager_Journeymankit",GetString("salvageKits"))
	GUI_NewCheckbox(mc_vendormanager.buymainwindow.name,GetString("buyMaster"),"BuyManager_Masterkit",GetString("salvageKits"))
	GUI_NewNumeric(mc_vendormanager.buymainwindow.name,GetString("kitStock"),"BuyManager_sStacks",GetString("salvageKits"),"1","100")
	GUI_NewCheckbox(mc_vendormanager.buymainwindow.name,GetString("copperTools"),"BuyManager_copperTools",GetString("gatherTools"))
	GUI_NewCheckbox(mc_vendormanager.buymainwindow.name,GetString("ironTools"),"BuyManager_ironTools",GetString("gatherTools"))
	GUI_NewCheckbox(mc_vendormanager.buymainwindow.name,GetString("steelTools"),"BuyManager_steelTools",GetString("gatherTools"))
	GUI_NewCheckbox(mc_vendormanager.buymainwindow.name,GetString("darksteelTools"),"BuyManager_darksteelTools",GetString("gatherTools"))
	GUI_NewCheckbox(mc_vendormanager.buymainwindow.name,GetString("mithrilTools"),"BuyManager_mithrilTools",GetString("gatherTools"))
	GUI_NewCheckbox(mc_vendormanager.buymainwindow.name,GetString("orichalcumTools"),"BuyManager_orichalcumTools",GetString("gatherTools"))
	GUI_NewNumeric(mc_vendormanager.buymainwindow.name,GetString("toolStock"),"BuyManager_toolStacks",GetString("gatherTools"),"1","100")
	
	GUI_SizeWindow(mc_vendormanager.buymainwindow.name,mc_vendormanager.buymainwindow.w,mc_vendormanager.buymainwindow.h)
	GUI_UnFoldGroup(mc_vendormanager.buymainwindow.name,GetString("buyGroup"))
	GUI_WindowVisible(mc_vendormanager.buymainwindow.name,false)
	
	BuyManager_Active = Settings.GW2Minion.BuyManager_Active
	BuyManager_buyAllKits = Settings.GW2Minion.BuyManager_buyAllKits
	BuyManager_Crudekit = Settings.GW2Minion.BuyManager_Crudekit
	BuyManager_Basickit = Settings.GW2Minion.BuyManager_Basickit
	BuyManager_Finekit = Settings.GW2Minion.BuyManager_Finekit
	BuyManager_Journeymankit = Settings.GW2Minion.BuyManager_Journeymankit
	BuyManager_Masterkit = Settings.GW2Minion.BuyManager_Masterkit
	BuyManager_sStacks = Settings.GW2Minion.BuyManager_sStacks
	
	BuyManager_copperTools = Settings.GW2Minion.BuyManager_copperTools
	BuyManager_ironTools = Settings.GW2Minion.BuyManager_ironTools
	BuyManager_steelTools = Settings.GW2Minion.BuyManager_steelTools
	BuyManager_darksteelTools = Settings.GW2Minion.BuyManager_darksteelTools
	BuyManager_mithrilTools = Settings.GW2Minion.BuyManager_mithrilTools
	BuyManager_orichalcumTools = Settings.GW2Minion.BuyManager_orichalcumTools
	BuyManager_toolStacks = Settings.GW2Minion.BuyManager_toolStacks
	
	if (Player) then
		mc_vendormanager.UpdateSellSingleItemList()
		mc_vendormanager.updateItemIDList()
	end
end

--Fill the "Sell Single Item"-dropdownlist
function mc_vendormanager.UpdateSellSingleItemList()
	local list = "None"
	local iList = Inventory("")
	if (TableSize(iList)>0)then
		local i,item = next(iList)
		while (i and item) do
			if (item.name and item.name ~= "" )then
				list = list .. "," .. item.name
			end		
			i,item=next(iList,i)
		end
	end
	SellManager_ItemToSell_listitems = list
end

--Create filtered Sell-Itemlist of Items we can sell
function mc_vendormanager.createItemList()
	local items = Inventory("")
	local filteredItems = {}
	if (items) then
		local id, item = next(items)
		while (id and item) do
			local addItem = false
			local iid, filter = next(mc_vendormanager.filterList)
			while (iid and filter) do
				if (mc_vendormanager.validFilter(filter)) then
					if ((filter.rarity == "None" or filter.rarity == nil or GW2.ITEMRARITY[filter.rarity] == item.rarity) and
					(filter.itemtype == "None" or filter.itemtype == nil or GW2.ITEMTYPE[filter.itemtype] == item.itemtype) and
					(filter.weapontype == "None" or filter.weapontype == nil or GW2.WEAPONTYPE[filter.weapontype] == item.weapontype) and					
					(filter.soulbound == "either" or (filter.soulbound == nil and item.soulbound == false) or filter.soulbound == tostring(item.soulbound))) then
						addItem = true
					end
				end				
				iid, filter = next(mc_vendormanager.filterList, iid)
			end
			-- Check for single filtered list
			local iID,lItem = next(SellManager_ItemIDInfo)
			while (iID and lItem) do
				if (item.itemID == lItem.itemID) then
					addItem = true
					break
				end
				iID,lItem = next(SellManager_ItemIDInfo, iID)
			end
			
			if (addItem and item.accountbound == false) then
				table.insert(filteredItems, item)
			end
			id, item = next(items, id)
		end
		if (filteredItems) then
			return filteredItems
		end
	end
	return false
end

--Check if Sellfilter is valid: 
function mc_vendormanager.validFilter(filter)
	if (filter.itemtype ~= "None" and filter.itemtype ~= nil and
	filter.rarity ~= "None" and filter.rarity ~= nil) then
		return true
	elseif (filter.itemID ~= "None" and filter.itemID ~= nil) then
		return true

	elseif (filter.rarity == "Junk") then
		return true
	end
	return false
end

--New Sellfilter/Load Sellfilter.
function mc_vendormanager.filterWindow(filterNumber)
	if (mc_vendormanager.filterList[filterNumber] == nil and not mc_vendormanager.filterExcists() and SellManager_NewFilterName ~= nil and SellManager_NewFilterName ~= "") then
		filterNumber = TableSize(mc_vendormanager.filterList) + 1
		mc_vendormanager.filterList[filterNumber] = {name = SellManager_NewFilterName, soulbound = "false", rarity = "None", itemtype = "None", weapontype = "None"}
		mc_vendormanager.refreshFilterlist()
		Settings.GW2Minion.SellManager_FilterList = mc_vendormanager.filterList
	end
	if (string.find(filterNumber, "SellManager_Filter")) then
		filterNumber = string.gsub(filterNumber, "SellManager_Filter", "")
		filterNumber = tonumber(filterNumber)
	end
	if (mc_vendormanager.filterList[filterNumber] ~= nil) then
		SellManager_Name = mc_vendormanager.filterList[filterNumber].name or "None"
		SellManager_Soulbound = mc_vendormanager.filterList[filterNumber].soulbound or "false"
		SellManager_Rarity = mc_vendormanager.filterList[filterNumber].rarity or "None"
		SellManager_Itemtype = mc_vendormanager.filterList[filterNumber].itemtype or "None"
		SellManager_Weapontype = mc_vendormanager.filterList[filterNumber].weapontype or "None"		
		GUI_WindowVisible(mc_vendormanager.selleditwindow.name,true)
	end
	SellManager_CurFilter = filterNumber
end

--Delete Sellfilter.
function mc_vendormanager.deleteFilter()
	table.remove(mc_vendormanager.filterList, SellManager_CurFilter)
	Settings.GW2Minion.SellManager_FilterList = mc_vendormanager.filterList
	mc_vendormanager.refreshFilterlist()
end

--Check if Sellfilter name excists.
function mc_vendormanager.filterExcists()
	local i,v = next(mc_vendormanager.filterList)
	while (i and v) do
		if (SellManager_NewFilterName == v.name) then
			return true
		end
		i,v = next(mc_vendormanager.filterList, i)
	end
	return false
end

--Refresh Sellfilters.
function mc_vendormanager.refreshFilterlist()
	GUI_Delete(mc_vendormanager.sellmainwindow.name,GetString("sellfilters"))
	local i, v = next(mc_vendormanager.filterList)
	while (i and v) do
		GUI_NewButton(mc_vendormanager.sellmainwindow.name, mc_vendormanager.filterList[i].name, "SellManager_Filter" .. i,GetString("sellfilters"))
		RegisterEventHandler("SellManager_Filter" .. i ,mc_vendormanager.filterWindow)
		i, v = next(mc_vendormanager.filterList, i)
	end
	SellManager_Name = nil
	SellManager_Soulbound = nil
	SellManager_Rarity = nil
	SellManager_Itemtype = nil
	SellManager_Weapontype = nil
	
	GUI_WindowVisible(mc_vendormanager.selleditwindow.name,false)
	GUI_UnFoldGroup(mc_vendormanager.sellmainwindow.name,GetString("sellfilters"))
end

-- Add a single new Item to our SellList
function mc_vendormanager.AddItemID()
	if ( SellManager_ItemToSell and SellManager_ItemToSell ~= "None" and SellManager_ItemToSell ~= "" ) then
		-- Make sure this item is not already in our SellList
			local id,lItem = next(SellManager_ItemIDInfo)
			local found = false
			while (id and lItem) do
				if (SellManager_ItemToSell == lItem.name) then
					return
				end
				id,lItem = next(SellManager_ItemIDInfo, id)
			end
		
		-- Find Item by Name in Inventory
		local iList = Inventory("")
		local iItem = nil
		if (TableSize(iList)>0)then
			local i,item = next(iList)
			while (i and item) do				
				if (item.name and item.name ~= "" and item.name == SellManager_ItemToSell)then
					iItem = item
					break
				end		
				i,item=next(iList,i)
			end
		end
		if (iItem) then		
			table.insert(SellManager_ItemIDInfo, {name = iItem.name, itemID = iItem.itemID})		
		end
		Settings.GW2Minion.SellManager_ItemIDInfo = SellManager_ItemIDInfo
		mc_vendormanager.updateItemIDList()		
		SellManager_ItemToSell = "None"
	end	
end

function mc_vendormanager.RemoveItemID()
	if ( SellManager_ItemIDList and SellManager_ItemIDList ~= "None" and SellManager_ItemIDList~="") then
		_,start = string.find(SellManager_ItemIDList, "-")
		local itemID = string.sub(SellManager_ItemIDList, start + 2, -1)
		local id,item = next(SellManager_ItemIDInfo)
		while (id and item) do
			if (item.itemID == tonumber(itemID)) then
				table.remove(SellManager_ItemIDInfo, id)
			end
			id,item = next(SellManager_ItemIDInfo, id)
		end
		Settings.GW2Minion.SellManager_ItemIDInfo = SellManager_ItemIDInfo
		mc_vendormanager.updateItemIDList()
	end
end
-- Update the Sell Single ItemList Dropdownfield
function mc_vendormanager.updateItemIDList()
	local list = "None"
	SellManager_ItemIDs = ""
	local _,item = next(SellManager_ItemIDInfo)
	while (item) do
		list = list .. "," .. item.name .. " - " .. item.itemID
		if (SellManager_ItemIDs == "") then
			SellManager_ItemIDs = item.itemID
		else
			SellManager_ItemIDs = SellManager_ItemIDs .. "," .. item.itemID
		end
		_,item = next(SellManager_ItemIDInfo, _)
	end
	SellManager_ItemIDList = "None"
	SellManager_ItemIDList_listitems = list
end

--*************
--BUY FUNCTIONS
--*************
function mc_vendormanager.GetSalvageKitCount()
	local count = 0
	local sKits = Inventory("itemtype=" .. GW2.ITEMTYPE.SalvageTool)
	if (sKits) then
		local id,item = next(sKits)
		while (id and item) do
			count = count + 1
			id,item = next(sKits, id)
		end
	end
	return count
end

function mc_vendormanager.NeedSalvageKitInfo()
	local kitInfo = { count=0, kits={} }
	kitInfo.count = mc_vendormanager.GetSalvageKitCount()
	
	if (BuyManager_Crudekit == "1") then table.insert(kitInfo.kits, mc_vendormanager.tools[3][0]) end
	if (BuyManager_Basickit == "1") then table.insert(kitInfo.kits, mc_vendormanager.tools[3][1]) end
	if (BuyManager_Finekit == "1") then table.insert(kitInfo.kits, mc_vendormanager.tools[3][2]) end
	if (BuyManager_Journeymankit == "1") then table.insert(kitInfo.kits, mc_vendormanager.tools[3][3]) end
	if (BuyManager_Masterkit == "1") then table.insert(kitInfo.kits, mc_vendormanager.tools[3][4]) end
	return kitInfo
end

-- Need to buy kits / not used right now, maybe later..
function mc_vendormanager.GetNeedSalvageKitInfo()
	-- itemtype = GW2.ITEMTYPE.SalvalteTool = 13
	local kitsOwned = {[1]=0,[2]=0,[3]=0,[4]=0,[5]=0}
	local buyList = {}
	local sKits = Inventory("itemtype=" .. GW2.ITEMTYPE.SalvageTool)
	if (sKits) then
		local id,item = next(sKits)
		while (id and item) do
			kitsOwned[item.rarity] = (kitsOwned[item.rarity] + 1)
			if (item.itemID == 44602) then kitsOwned[1] = false end
			id,item = next(sKits, id)
		end
		if (BuyManager_Crudekit == "0") then kitsOwned[1] = false end
		if (BuyManager_Basickit == "0") then kitsOwned[2] = false end
		if (BuyManager_Finekit == "0") then kitsOwned[3] = false end
		if (BuyManager_Journeymankit == "0") then kitsOwned[4] = false end
		if (BuyManager_Masterkit == "0") then kitsOwned[5] = false end
		for rarity = #kitsOwned, 1, -1 do			
			if (kitsOwned[rarity] ~= false) then			
				table.insert(buyList, {count = tonumber(BuyManager_sStacks) - kitsOwned[rarity], itemID = mc_vendormanager.tools[3][rarity-1]})
			end
		end
	end
	return buyList
end

function mc_vendormanager.GetGatheringToolsCount()
	local buyList = {[1]=0,[2]=0,[3]=0}
	
	local fTool = Inventory:GetEquippedItemBySlot(GW2.EQUIPMENTSLOT.ForagingTool)
	local lTool = Inventory:GetEquippedItemBySlot(GW2.EQUIPMENTSLOT.LoggingTool)
	local mTool = Inventory:GetEquippedItemBySlot(GW2.EQUIPMENTSLOT.MiningTool)
	if (fTool) then buyList[1] = 1 end
	if (lTool) then buyList[2] = 1 end
	if (mTool) then buyList[3] = 1 end
	
	-- Check for unlimited tools -> we dont need to buy these
	if (fTool and fTool.rarity == 4 and fTool.stackcount == 0) then buyList[1] = 999 end
	if (lTool and lTool.rarity == 4 and lTool.stackcount == 0) then buyList[2] = 999 end
	if (mTool and mTool.rarity == 4 and mTool.stackcount == 0) then buyList[3] = 999 end
	
	local sTools = Inventory("itemtype=" .. GW2.ITEMTYPE.Gathering)
	if (sTools) then
		local pLevel = Player.level
		local id,item = next(sTools)
		while (id and item) do
			local itemID = item.itemID
			for invTools = 1, 6, 1 do				
				if (itemID == mc_vendormanager.tools[0][invTools] and pLevel >= mc_vendormanager.LevelRestrictions[invTools]) then buyList[1] = buyList[1] + 1  break end
				if (itemID == mc_vendormanager.tools[1][invTools] and pLevel >= mc_vendormanager.LevelRestrictions[invTools]) then buyList[2] = buyList[2] + 1  break end
				if (itemID == mc_vendormanager.tools[2][invTools] and pLevel >= mc_vendormanager.LevelRestrictions[invTools]) then buyList[3] = buyList[3] + 1  break end
			end
			id,item = next(sTools, id)
		end
	end
	return buyList
end

function mc_vendormanager.GetNeededGatheringToolsInfo()
	-- itemtype = GW2.ITEMTYPE.Gathering = 6
	local buyList = {[1]={},[2]={},[3]={}}
	for set = 0, 2, 1 do
		for _,v in pairs(mc_vendormanager.tools[set]) do
			buyList[set+1][v] = 0
		end
	end
	local fTool = Inventory:GetEquippedItemBySlot(GW2.EQUIPMENTSLOT.ForagingTool)
	local lTool = Inventory:GetEquippedItemBySlot(GW2.EQUIPMENTSLOT.LoggingTool)
	local mTool = Inventory:GetEquippedItemBySlot(GW2.EQUIPMENTSLOT.MiningTool)
	local fToolID = 0
	local lToolID = 0
	local mToolID = 0
	if (fTool) then fToolID = fTool.itemID end
	if (lTool) then lToolID = lTool.itemID end
	if (mTool) then mToolID = mTool.itemID end
	local toolsInUse = {
						[1] = fToolID,
						[2] = lToolID,
						[3] = mToolID
	}
	
	-- Substract the one we still have in use from the stacksize wanted
	for invTools = 1, 6, 1 do
		if (toolsInUse[1] == mc_vendormanager.tools[0][invTools]) then buyList[1][toolsInUse[1]] = buyList[1][toolsInUse[1]] + 1 end
		if (toolsInUse[2] == mc_vendormanager.tools[1][invTools]) then buyList[2][toolsInUse[2]] = buyList[2][toolsInUse[2]] + 1 end
		if (toolsInUse[3] == mc_vendormanager.tools[2][invTools]) then buyList[3][toolsInUse[3]] = buyList[3][toolsInUse[3]] + 1 end
	end
	
	-- Check for unlimited tools -> we dont need to buy these
	if (fTool and fTool.rarity == 4 and fTool.stackcount == 0) then buyList[1] = false end
	if (lTool and lTool.rarity == 4 and lTool.stackcount == 0) then buyList[2] = false end
	if (mTool and mTool.rarity == 4 and mTool.stackcount == 0) then buyList[3] = false end
	
	-- Count our remaining gatheringtools
	local gTools = Inventory("itemtype=" .. GW2.ITEMTYPE.Gathering)
	if ( TableSize(gTools)>0) then
		local id, item = next(gTools)
		while (id and item) do
			for set = 1, 3, 1 do
				if (buyList[set] and buyList[set][item.itemID]) then buyList[set][item.itemID] = buyList[set][item.itemID] + 1 end
			end
			id, item = next(gTools, id)
		end
	end
	
	mc_vendormanager.checkBuyFilters(buyList)
	for set = 1, 3, 1 do
		if (buyList[set]) then
			for key, owned in pairs(buyList[set]) do
				if type(buyList[set][key]) == "number" then
					buyList[set][key] = BuyManager_toolStacks - buyList[set][key]
				end
			end
		end
	end
	return buyList
end

function mc_vendormanager.checkBuyFilters(buyList)
	for tool = 1, 3, 1 do
		if (buyList[tool]) then
			local tID = 1
			local pLevel = Player.level
			if (BuyManager_copperTools == "0" or pLevel < mc_vendormanager.LevelRestrictions[tID]) then buyList[tool][mc_vendormanager.tools[tool-1][tID]] = false end
			tID = tID + 1
			if (BuyManager_ironTools == "0" or pLevel < mc_vendormanager.LevelRestrictions[tID]) then buyList[tool][mc_vendormanager.tools[tool-1][tID]] = false end
			tID = tID + 1
			if (BuyManager_steelTools == "0" or pLevel < mc_vendormanager.LevelRestrictions[tID]) then buyList[tool][mc_vendormanager.tools[tool-1][tID]] = false end
			tID = tID + 1
			if (BuyManager_darksteelTools == "0" or pLevel < mc_vendormanager.LevelRestrictions[tID]) then buyList[tool][mc_vendormanager.tools[tool-1][tID]] = false end
			tID = tID + 1
			if (BuyManager_mithrilTools == "0" or pLevel < mc_vendormanager.LevelRestrictions[tID]) then buyList[tool][mc_vendormanager.tools[tool-1][tID]] = false end
			tID = tID + 1
			if (BuyManager_orichalcumTools == "0" or pLevel < mc_vendormanager.LevelRestrictions[tID]) then buyList[tool][mc_vendormanager.tools[tool-1][tID]] = false end
		end
	end
	return buyList
end

function mc_vendormanager.GUIVarUpdate(Event, NewVals, OldVals)
	for k,v in pairs(NewVals) do
		if (k == "SellManager_Active" or 
			-- Salvage Kits
			k == "BuyManager_Active" or
			k == "BuyManager_Crudekit" or
			k == "BuyManager_Basickit" or
			k == "BuyManager_Finekit" or
			k == "BuyManager_Journeymankit" or
			k == "BuyManager_Masterkit" or
			k == "BuyManager_sStacks" or
			-- Gathering Tools
			k == "BuyManager_copperTools" or
			k == "BuyManager_ironTools" or
			k == "BuyManager_steelTools" or
			k == "BuyManager_darksteelTools" or
			k == "BuyManager_mithrilTools" or
			k == "BuyManager_orichalcumTools" or
			k == "BuyManager_toolStacks")
			then 
			Settings.GW2Minion[tostring(k)] = v
			
		elseif (k == "SellManager_Name"  or
				k == "SellManager_Soulbound"  or
				k == "SellManager_Rarity" or
				k == "SellManager_Itemtype" or
				k == "SellManager_Weapontype"				
				)
		then
			mc_vendormanager.filterList[SellManager_CurFilter].soulbound = SellManager_Soulbound
			mc_vendormanager.filterList[SellManager_CurFilter].rarity = SellManager_Rarity
			mc_vendormanager.filterList[SellManager_CurFilter].itemtype = SellManager_Itemtype
			mc_vendormanager.filterList[SellManager_CurFilter].weapontype = SellManager_Weapontype			
		end
		Settings.GW2Minion.SellManager_FilterList = mc_vendormanager.filterList
	end
end


function mc_vendormanager.SellToggleMenu()
	if (mc_vendormanager.sellwindowVisible) then
		GUI_WindowVisible(mc_vendormanager.sellmainwindow.name,false)
		GUI_WindowVisible(mc_vendormanager.selleditwindow.name,false)
		mc_vendormanager.sellwindowVisible = false
	else
		local wnd = GUI_GetWindowInfo("MinionBot")
		GUI_MoveWindow( mc_vendormanager.sellmainwindow.name, wnd.x+wnd.width,wnd.y) 
		GUI_WindowVisible(mc_vendormanager.sellmainwindow.name,true)
		mc_vendormanager.sellwindowVisible = true
		mc_vendormanager.UpdateSellSingleItemList()
	end
end


function mc_vendormanager.BuyToggleMenu()
	if (mc_vendormanager.buywindowvisible) then
		GUI_WindowVisible(mc_vendormanager.buymainwindow.name,false)
		mc_vendormanager.buywindowvisible = false
	else
		local wnd = GUI_GetWindowInfo("MinionBot")
		GUI_MoveWindow( mc_vendormanager.buymainwindow.name, wnd.x+wnd.width,wnd.y) 
		GUI_WindowVisible(mc_vendormanager.buymainwindow.name,true)
		mc_vendormanager.buywindowvisible = true
	end
end

RegisterEventHandler("sellManager.toggle", mc_vendormanager.SellToggleMenu)
RegisterEventHandler("buymanager.toggle", mc_vendormanager.BuyToggleMenu)
RegisterEventHandler("GUI.Update",mc_vendormanager.GUIVarUpdate)
RegisterEventHandler("Module.Initalize",mc_vendormanager.ModuleInit)