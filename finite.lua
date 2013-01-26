-- Water Plus
-- By Rubenwardy
-- License: cc-by-sa

-- Setup Finite
waterplus.finite_water_inc=1/(waterplus.finite_water_steps /(1+waterplus.finite_water_inc_skip))
waterplus.finite_water_max=math.floor(1.43/waterplus.finite_water_inc) --how many finite water values (give a new style water effect)

-- Debug log print settings
dPrint("Water steps: "..waterplus.finite_water_steps)
dPrint("Water max: "..waterplus.finite_water_max)
dPrint("Water inc: "..waterplus.finite_water_inc)
dPrint("Water inc_skip: "..waterplus.finite_water_inc_skip)

-- Locals
local h=waterplus.finite_water_inc
local c=1

dPrint("C: "..c)
dPrint("H: "..h)

-- Block create function
waterplus.finite_blocks = {}
waterplus.register_step = function(a,height)
	print("Register finite block "..a.." with a height of "..height)
	minetest.register_node("waterplus:finite_"..a, {
		description = "Finite Water "..a,
		tiles = {
                       {name="default_water_source_animated.png", animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=2.0}}
		},
		drawtype = "nodebox",
    	alpha = WATER_ALPHA,
		paramtype = "light",
		walkable = false,
		pointable = false,
		diggable = false,
		buildable_to = true,
		post_effect_color = {a=64, r=100, g=100, b=200},
		groups = {water=3,finite_water=((a/waterplus.finite_water_steps)*100), puts_out_fire=1},
		node_box = {
			type="fixed",
			fixed={
				{-0.5,-0.5,-0.5,0.5,height-0.5,0.5},
			},
		},
	})
	table.insert(waterplus.finite_blocks,"waterplus:finite_"..a)
	bucket.register_liquid(
		"waterplus:finite_"..a,
		"",
		":bucket:bucket_finite_"..a,
		"bucket_water.png"
	)
end

--Create blocks
for a=1, waterplus.finite_water_max do
	c=c+1
	
	if c>waterplus.finite_water_inc_skip then
        	c = 0
        	h = h + waterplus.finite_water_inc
	end

	waterplus.register_step(a,h)
    waterplus.finite_water_max_id = a

end
waterplus.finite_water_max_name="waterplus:finite_"..waterplus.finite_water_max_id

--The ABM
minetest.register_abm({
	nodenames = waterplus.finite_blocks,
	interval = 1/10,
	chance = 1,
	action = function(pos,node)
		local node_id = getNumberFromName(node.name)

		dPrint("")
		dPrint("Waterplus [finite] - Calculating for "..node_id.." at "..pos.x..","..pos.y..","..pos.z)

        local upc = {x=pos.x, y=pos.y-1, z=pos.z}
        -- recieve pressure from up
        local pressure = 0
        if minetest.env:get_node(upc).name == waterplus.finite_water_max_name or minetest.env:get_node(upc).name == "default:water_source" then
            --pressure = minetest.env:get_meta(upc):get_int('pressure') or 1
            pressure = 1
        end
		--print("Waterplus [finite] - Calculating for "..node_id.." at "..pos.x..","..pos.y..","..pos.z..' press='..pressure)
		
		local target = {x=pos.x,y=pos.y,z=pos.z}
		target.y=target.y-1
		dPrint(target.x..","..target.z)
		--if performDrop(pos,target) then return end
		if performDrop(pos,target) then 
            if minetest.env:get_node(upc).name == "default:water_source" then
		        minetest.env:set_node(upc,{name = "waterplus:finite_"..waterplus.finite_water_max_id})
            end
            pos=target 
        end

    	local source_name = minetest.env:get_node(pos).name
	    local source_id = getNumberFromName(source_name) or 0 
    	local coords = {

	   	   {x=pos.x-1,y=pos.y-1,z=pos.z, f=1},   -- vertical drop
	       {x=pos.x+1,y=pos.y-1,z=pos.z, f=1},   --f= can flow or drop
		   {x=pos.x,y=pos.y-1,z=pos.z-1, f=1},
		   {x=pos.x,y=pos.y-1,z=pos.z+1, f=1},	

	   	   {x=pos.x-1,y=pos.y,z=pos.z,h=1, f=1, wi=1}, -- h=horisontal flow
	       {x=pos.x+1,y=pos.y,z=pos.z,h=1, f=1, wi=1}, -- wi= standard water infect
		   {x=pos.x,y=pos.y,z=pos.z-1,h=1, f=1, wi=1},
		   {x=pos.x,y=pos.y,z=pos.z+1,h=1, f=1, wi=1},	

	   	   {x=pos.x,y=pos.y+1,z=pos.z, wi=1, u=1},   -- look up
        }
        local can = 0;
        local can_water = 1;
    	for i = 1,9 do
	      	local name = minetest.env:get_node(coords[i]).name
            local target_id = getNumberFromName(name)
--print("test nei "..name ..' = '.. (target_id or 'NO'))
	       	if coords[i].f and name == "air" then 
                coords[i].v = waterplus.finite_water_max_id 
                coords[i].t = 0
                can = 1
            elseif name=="default:water_flowing" then
		        minetest.env:set_node(coords[i],{name = "waterplus:finite_10"})
            elseif coords[i].wi and name=="default:water_source" and source_id<waterplus.finite_water_max_id then
--print('convert up='..(coords[i].u or '')..' me=' .. source_id)
		        minetest.env:set_node(coords[i],{name = "waterplus:finite_"..waterplus.finite_water_max_id})
            elseif target_id == nil then 
            elseif coords[i].f and target_id >= 1 then 
                --coords[i].v = waterplus.finite_water_steps - target_id
                coords[i].t = target_id
                coords[i].o = target_id --original
                if coords[i].h and pressure < 1 then
                    if coords[i].t < source_id then
                        can = 1
                        coords[i].v = source_id - target_id
                    end
                else
                    coords[i].v = waterplus.finite_water_max_id - target_id
                    can = 1
                end
--print('test water ' .. (coords[i].wi or 'nwi') .. ' t=' .. target_id)
                if coords[i].wi and (target_id < waterplus.finite_water_max_id or name == "air") then 
                    can_water = 0
--print('cant water' .. target_id)
                end
            end
    	end
        --local flowed

-- twice: for drop then flow
        for pass=0,1 do
          while can>0 and source_id do 
            local flowed = 0
    	    for i = 1+(pass*4),4+(pass*4) do
                local min = 0
                if coords[i].h and pressure < 1 then 
                    min = coords[i].t 
                    if not min or min < 1 then min = 1 end
                end
                
                if coords[i].v and coords[i].v > 0 and source_id > min then 
                    coords[i].v = coords[i].v - 1
                    source_id = source_id - 1
                    coords[i].a = 1     -- (coords[i].a or 0) + 1
                    coords[i].t = coords[i].t + 1
                    flowed = 1
--print ('flow v=' .. coords[i].v ..' t='.. coords[i].t .. ' s='..source_id)
                    if source_id <= 1 then break end
                end
            end 
            if source_id < 1 or flowed < 1 then break end
--print ('res flv='..flowed .. ' sid='..source_id)
          end
        end
        for i = 1,8 do
            if coords[i].a and coords[i].a ~= coords[i].t then 
--print ('repl '..(coords[i].o or 'air') ..' to' .. coords[i].t)
		        minetest.env:set_node(coords[i],{name = "waterplus:finite_"..coords[i].t})
            end
        end
        local set = "waterplus:finite_"..source_id
        if source_id < 1 then set = "air" end
--print('test canwater' .. can_water ..' me='.. source_id)
        if can_water and source_id == waterplus.finite_water_max_id then set = "default:water_source"  end
        if set ~= source_name then
--print('src set ' .. ' was= '..source_name.. ' now '..source_id .. ' to '..set)
            minetest.env:set_node(pos,{name = set})
        end

--[[ not used
        if source_id < 1 then return end
 
        if 1 then return end





		target = {x=pos.x,y=pos.y,z=pos.z}
		target.x=target.x+1
		dPrint(target.x..","..target.z)
		performFlow(pos,target)

		target = {x=pos.x,y=pos.y,z=pos.z}
		target.x=target.x-1
		dPrint(target.x..","..target.z)
		performFlow(pos,target)

		target = {x=pos.x,y=pos.y,z=pos.z}
		target.z=target.z+1
		dPrint(target.x..","..target.z)
		performFlow(pos,target)
		
		target = {x=pos.x,y=pos.y,z=pos.z}
		target.z=target.z-1
		dPrint(target.x..","..target.z)
		performFlow(pos,target)

		target = {x=pos.x,y=pos.y,z=pos.z}
		target.x=target.x+1
		target.z=target.z+1
		dPrint(target.x..","..target.z)
		performFlow(pos,target)

		target = {x=pos.x,y=pos.y,z=pos.z}
		target.x=target.x+1
		target.z=target.z-1
		dPrint(target.x..","..target.z)
		performFlow(pos,target)

		target = {x=pos.x,y=pos.y,z=pos.z}
		target.x=target.x-1
		target.z=target.z+1
		dPrint(target.x..","..target.z)
		performFlow(pos,target)
]]

		dPrint("--Calculation Complete")
		dPrint("")
	end,
})

-- name (string)
function getNumberFromName(name)
	return tonumber(string.gsub(name, "waterplus:finite_", ""),10)
end

--from (pos): position of the node the abm is being run on
--to (pos): position of the node to check
--[[
function performFlow(from,to)
	dPrint("> Flow Calculation")
	local target = minetest.env:get_node(to).name
	local target_id = getNumberFromName(target)
	local source = minetest.env:get_node(from).name
	local id = getNumberFromName(source)
	
	if id == nil then
	   id = 0
	end

	if target ~= "air" and tonumber(target_id) == nil then
		dPrint("  > Exit on is not finite liquid")
		return
	end

	if target_id == nil then
		target_id=0
	end
	
	dPrint("  > Testing Heights: "..id.." vs "..target_id)

	if id == 1 and target_id == 0 and math.random(1,4) == 1 then
		if performDrop(from, {x=to.x,y=to.y-1,z=to.z}) then 
			return 
		end
	end

	if id > target_id and id > 0 then
		dPrint("    > Flowing")

		local nh_to = "waterplus:finite_"..(target_id+1)
		local nh_from = "waterplus:finite_"..(id-1)

		if (id-1) < 1 or (target_id+1) > waterplus.finite_water_max then
			dPrint("    > Exit on too high, or too low")
			return
		end
		
		minetest.env:set_node(from,{name = nh_from})
		minetest.env:set_node(to,{name = nh_to})

		dPrint("    > Done")
	end
end
]]

--from (pos): position of the node the abm is being run on
--to (pos): position of the node to check
function performDrop(from,to)
	dPrint("> Drop Calculation")
	local target = minetest.env:get_node(to).name
	local target_id = getNumberFromName(target)
	local source = minetest.env:get_node(from).name
	local id = getNumberFromName(source)

	if target ~= "air" and tonumber(target_id) == nil then
		dPrint("  > Exit on is not finite liquid")
		return
	end

	if target_id == nil then
		target_id=0
	end

	if target_id >= waterplus.finite_water_max_id then
        return
	end
	
	if id == nil then
	   id = 0
	end

    --dPrint('droptest '..target_id ..'+'.. id ..' maxid='.. waterplus.finite_water_max_id ..' max='.. waterplus.finite_water_max)
	target_id = target_id + id
	id=0

	if target_id > waterplus.finite_water_max_id then
	   id = target_id - waterplus.finite_water_max_id
	   target_id = waterplus.finite_water_max_id
	end

	local nh_to = "waterplus:finite_"..(target_id)
	local nh_from = "waterplus:finite_"..(id)

	if id == 0 or id == nil then
	   nh_from = "air"
	end

    --print("drop ".. nh_from ..'->'..nh_to )
	minetest.env:set_node(from,{name = nh_from})
	minetest.env:set_node(to,{name = nh_to})

	return 1

end

minetest.register_alias("default:water_source","waterplus:finite_20")
minetest.register_alias("default:water_flowing","waterplus:finite_10")

minetest.register_craftitem(":bucket:bucket_water", {
	inventory_image = "bucket_water.png",
	stack_max = 1,
	liquids_pointable = true,
	on_use = function(itemstack, user, pointed_thing)
		-- Must be pointing to node
		if pointed_thing.type ~= "node" then
			return
		end
		-- Check if pointing to a buildable node
		n = minetest.env:get_node(pointed_thing.under)
		if minetest.registered_nodes[n.name].buildable_to then
			-- buildable; replace the node
			minetest.env:add_node(pointed_thing.under, {name="waterplus:finite_20"})
		else
			-- not buildable to; place the liquid above
			-- check if the node above can be replaced
			n = minetest.env:get_node(pointed_thing.above)
			if minetest.registered_nodes[n.name].buildable_to then
				minetest.env:add_node(pointed_thing.above, {name="waterplus:finite_20"})
			else
				-- do not remove the bucket with the liquid
				return
			end
		end
		return {name="bucket:bucket_empty"}
	end
})
