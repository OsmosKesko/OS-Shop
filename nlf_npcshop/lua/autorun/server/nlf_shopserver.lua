--[[
Addon by Osmos[FR] : https://steamcommunity.com/id/ThePsyca/
Info : Public Addon
]]--

--[[ INIT ]]--

util.AddNetworkString("Shop::Open")

util.AddNetworkString("Shop::Buy")

util.AddNetworkString("Shop::AddItem")

util.AddNetworkString("Shop::RegisterNewItem")

util.AddNetworkString("Shop::EditItem")

util.AddNetworkString("Shop::DeleteItem")

util.AddNetworkString("Shop::ClChangeItem")

util.AddNetworkString("Shop::StartChangeItem")

util.AddNetworkString("Shop::EditOldItem")

util.AddNetworkString("Shop::StartRob")

util.AddNetworkString("Shop::CopsHUD")

--[[ SQL TABLE ]]--

local function osshop_createtable()
	if not sql.TableExists("osshop_data") then
		sql.Query( "CREATE TABLE osshop_data( id INTEGER PRIMARY KEY AUTOINCREMENT ,isweapon varchar(4), name varchar(150), entclass varchar(150), models varchar(400), desc varchar(600), price bigint(20) )" )
		print("[ Osshop ] : Create Table")
	end
end

hook.Add( "InitPostEntity", "osshop::InitTable", timer.Simple( 0.1, function() osshop_createtable() end ) )

--[[ HUD ]]--

local function copshud(npc)
        for k, v in pairs (  player.GetAll() ) do
        	if osshop.teamcops[team.GetName(v:Team())] then
        		DarkRP.notify(v, 3, 4, osshop.lang[kla].txt36)
        		net.Start("Shop::CopsHUD")
        		net.WriteEntity(npc)
        		net.WriteBool(true)
        		net.Send(v)

        		timer.Simple(osshop.robduration,function() 
        		net.Start("Shop::CopsHUD")
        		net.WriteEntity(npc)
        		net.WriteBool(false)
        		net.Send(v)
        		end)
			end
		end
end

--[[ Function ]]--

local kla = osshop.choice

net.Receive("Shop::Buy",function(len , pl)
local npc = net.ReadEntity()
local id = net.ReadInt(32)

	if not IsValid(npc) then return end
	if not npc:GetClass() == "nlf_shopx" then return end
	if 	npc:GetNWBool("Npc::InRobbing") then return end
	local itemt = sql.Query("SELECT * FROM osshop_data")

	local dataitem
			if itemt then 
				dataitem = itemt 
			else
				return
			end

	if osshop.antispam then
	if pl.timedelay == nil then
	 pl.timedelay = 0
	  end

	if CurTime() <  pl.timedelay then 	DarkRP.notify(pl, 1, 4, osshop.lang[kla].txt31) return end
	 pl.timedelay = CurTime() + 5
	end

	if pl:GetPos():DistToSqr(npc:GetPos())>200 then 

		if pl:getDarkRPVar( "money" ) < tonumber(dataitem[id].price) then
			DarkRP.notify(pl, 1, 4, osshop.lang[kla].txt19) return
		end 
		pl:addMoney(- dataitem[id].price)
			if dataitem[id].isweapon then
				pl:Give(dataitem[id].entclass)
				DarkRP.notify(pl, 0, 4, osshop.lang[kla].txt20)
			else
					local buyp = ents.Create(dataitem[id].entclass)
				buyp:SetPos(pl:GetPos() + pl:GetAngles():Forward()*25 + pl:GetAngles():Up()*15)
				buyp:SetAngles(pl:GetAngles())
				buyp:Spawn()
				buyp:Activate()
				DarkRP.notify(pl, 0, 4, osshop.lang[kla].txt21)
			end

	end

end)

net.Receive("Shop::RegisterNewItem",function(len, pl)
local info = net.ReadTable()

if not osshop.staff[pl:GetUserGroup()] then return end

local IsWeapoon 
	if info.isw == osshop.lang[kla].yes then
		IsWeapoon = "true"
	elseif info.isw == osshop.lang[kla].no then
		IsWeapoon = "false"
	else
		DarkRP.notify(pl, 1, 4, "[Osshop] : "..osshop.lang[kla].txt22)	return
	end

	if (info.name == osshop.lang[kla].txt13) then
		DarkRP.notify(pl, 1, 4, "[ Osshop ] : "..osshop.lang[kla].txt23) return 
	elseif (info.class == osshop.lang[kla].txt14) then
		DarkRP.notify(pl, 1, 4, "[ Osshop ] : "..osshop.lang[kla].txt24)  return
	elseif (info.model == osshop.lang[kla].txt15) then
		DarkRP.notify(pl, 1, 4, "[ Osshop ] : "..osshop.lang[kla].txt25) return
	elseif (info.price == osshop.lang[kla].txt16) then
		DarkRP.notify(pl, 1, 4, "[ Osshop ] : "..osshop.lang[kla].txt26) return
	elseif (info.desc == osshop.lang[kla].txt17) then
		DarkRP.notify(pl, 1, 4, "[ Osshop ] : "..osshop.lang[kla].txt27) return
	end

	if not sql.TableExists("osshop_data") then
		osshop_createtable()
	end

	sql.Query("INSERT INTO osshop_data VALUES( NULL,'"..IsWeapoon.."','"..info.name.."','"..info.class.."','"..info.model.."','"..info.desc.."','"..info.price.."' ) ")
		DarkRP.notify(pl, 0, 4, "[ Osshop ] : "..osshop.lang[kla].txt28)
end)

net.Receive("Shop::DeleteItem",function(len , pl) 
local key = net.ReadInt(32)
local npc = net.ReadEntity()

if not osshop.staff[pl:GetUserGroup()] then return end
	local itemt = sql.Query("SELECT * FROM osshop_data")
	local dataitem
			if itemt then 
				dataitem = itemt 
			else
				return
			end
		sql.Query("DELETE FROM osshop_data WHERE id =" .. dataitem[key].id)
		DarkRP.notify(pl, 0, 4, "[Osshop] : "..osshop.lang[kla].txt29)

					local myt = sql.Query("SELECT * FROM osshop_data")
			local ntsend 
			if myt then 
				ntsend = myt 
			else
				ntsend = {}
			end

			net.Start("Shop::Open")
			net.WriteEntity(npc)
			net.WriteTable(ntsend)
			net.Send(pl)
end)

net.Receive("Shop::StartChangeItem", function(len, pl)
local key = net.ReadInt(32)
local npc = net.ReadEntity()

if not osshop.staff[pl:GetUserGroup()] then return end

	local itemt = sql.Query("SELECT * FROM osshop_data")
local dataitem
			if itemt[key] then 
				dataitem = itemt[key] 
			else
				return
			end

			net.Start("Shop::ClChangeItem")
			net.WriteEntity(npc)
			net.WriteTable(dataitem)
			net.Send(pl)


end)

net.Receive("Shop::EditOldItem", function(len, pl)
local npc = net.ReadEntity()
local info = net.ReadTable()

local IsWeapoon 
	if info.isw == osshop.lang[kla].yes then
		IsWeapoon = "true"
	elseif info.isw == osshop.lang[kla].no then
		IsWeapoon = "false"
	end

if not osshop.staff[pl:GetUserGroup()] then return end
	local itemt = sql.Query("SELECT * FROM osshop_data WHERE id ="..info.id)
	if not itemt then return end
	sql.Query([[UPDATE osshop_data SET isweapon = "]]..IsWeapoon..[[", name = "]]..info.name..[[", entclass = "]]..info.class..[[", models = "]]..info.model..[[", desc = "]]..info.desc..[[", price = "]]..info.price..[[" WHERE id =]]..info.id)
	DarkRP.notify(pl, 0, 4, "[Osshop] : "..osshop.lang[kla].txt30)

						local myt = sql.Query("SELECT * FROM osshop_data")
			local ntsend 
			if myt then 
				ntsend = myt 
			else
				ntsend = {}
			end

			net.Start("Shop::Open")
			net.WriteEntity(npc)
			net.WriteTable(ntsend)
			net.Send(pl)
end)

net.Receive("Shop::StartRob", function(len, pl)
    local npc = net.ReadEntity()

    if osshop.teamforrob and not osshop.teamrob[team.GetName(pl:Team())] then
        DarkRP.notify(pl, 1, 4, osshop.lang[kla].txt32)

        return
    end

    if not IsValid(npc) then return end
    if not npc:GetClass() == "nlf_shopx" then return end
    if npc:GetNWBool("Npc::InRobbing") then return end

    if pl:GetPos():DistToSqr(npc:GetPos()) > 200 then
        if npc.robdelay == nil then
            npc.robdelay = 0
        end

        if CurTime() < npc.robdelay then
            DarkRP.notify(pl, 1, 4, osshop.lang[kla].txt33)

            return
        end

			copshud(npc)
        npc:SetNWBool("Npc::InRobbing", true)
        npc:SetNWInt("NPC::Robber", pl)
        npc:SetNWInt("NPC::Timer", CurTime() + osshop.robduration)
        DarkRP.notify(pl, 0, 4, osshop.lang[kla].txt34)

        timer.Simple(osshop.robduration, function()
            local pos = (npc:GetPos() + npc:GetAngles():Forward() * 50 + pl:GetAngles():Up() * 50)
            DarkRP.createMoneyBag(pos, 1500)
            DarkRP.notify(pl, 0, 4, osshop.lang[kla].txt35)
            npc:SetNWBool("Npc::InRobbing", false) 
		    npc:SetNWInt("NPC::Robber", nil) 
		    npc:SetNWInt("NPC::Timer", 0)
            npc.robdelay = CurTime() + osshop.robdelay
        end)
    end
end)

--[[ PlayerSay ]]--

hook.Add( "PlayerSay", "ossshop.onsay", function( ply, text )
	
	if osshop.staff[ply:GetUserGroup()] and text == osshop.additemcommand then
		net.Start("Shop::AddItem")
		net.Send(ply)
		return ""
	end

end)


--[[
Addon by Osmos[FR] : https://steamcommunity.com/id/ThePsyca/
Info : Public Addon
]]--