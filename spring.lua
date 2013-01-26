-- Water Plus
-- By Rubenwardy
-- License: cc-by-sa

minetest.register_node("waterplus:spring",{
	description = "Water Spring",
	tiles = {"default_grass.png", "waterplus_spring.png", "default_dirt.png^default_grass_side.png"},
	is_ground_content = true,
	groups = {crumbly=3},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_grass_footstep", gain=0.4},
	}),
	--paramtype = "light",
	--paramtype2 = "facedir",
})

minetest.register_abm({
	nodenames = {"waterplus:spring"},
	interval = 2,
	chance = 1,
	action = function(pos,node)
	    local ps = {x=pos.x, y=pos.y-1, z=pos.z}
	    minetest.env:set_node(ps,{name = waterplus.finite_water_max_name})
	end
})