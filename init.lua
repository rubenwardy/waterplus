-- Water Plus
-- By Rubenwardy
-- License: cc-by-sa

waterplus={}

-- Settings
waterplus.finite_water_steps=32 --how many finite water steps
waterplus.finite_water_inc_skip=1  --how many waters to skip before inc

-- Debug
function dPrint(msg)
	-- uncomment the following line to show debug text
	--print(msg)
end

-- Load Modules
dofile(minetest.get_modpath("waterplus").."/finite.lua")