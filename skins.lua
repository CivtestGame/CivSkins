
-- M Skin base: civskins_mbase_1.png
-- F Skin base: civskins_fbase_1.png

-- Hair: civskins_hair_1.png
-- Face: civskins_face_1.png
-- Eyes: civskins_eyes_1.png
-- Beard: civskins_beard_1.png

-- Chest: civskins_chest_1.png
-- Pants: civskins_legs_1.png
-- Shoes: civskins_shoes_1.png

civskins.components = {}

local component_texture_path =
   minetest.get_modpath(minetest.get_current_modname()) .. "/textures"

local function populate_components()
   local file_list = minetest.get_dir_list(component_texture_path, false)
   for _,file in ipairs(file_list) do
      local category, value = file:match("civskins_(%a+)_(%d+).png")
      civskins.components[category] = civskins.components[category] or {}
      local comps = civskins.components[category]
      civskins.components[category][tonumber(value)] = file
   end
end

populate_components()

local hair_colors = {
   random_base = 0, random_peak = 200,
   colors = {
      "#aeaeae", "#d0a513", "#5b3000", "#6f4d28",
   }
}

local skin_colors = {
   random_base = 100, random_peak = 125,
   biome_weighting = true,
   colors = {
      -- these are ordered by brightness, light-->dark
      -- Light colors
      "#ebd1bc",
      "#e1bc9e",
      "#d19e76",

      -- Tanned colors
      "#ecab77",
      "#d06b1a",
      "#b46322",

      -- Dark colors
      "#81410e",
      "#5b3000",
      "#411f02"
   }
}

local eye_colors = {
   random_base = 0, random_peak = 200,
   colors = {
      "#ff0000", "#0ff000", "#00ff00", "#000ff0", "#0000ff",
      "#ff00ff", "#fff00f", "#f0ff0f", "#0ffff0", "#00ffff"
   }
}

local pants_colors = {
   random_base = 0, random_peak = 100,
   colors = {
      "#ff0000", "#0ff000", "#00ff00", "#000ff0", "#0000ff",
      "#ff00ff", "#fff00f", "#f0ff0f", "#0ffff0", "#00ffff"
   }
}

local function set_meta_for_category(player, cat, actual_cat, chance,
                                     color_spec, comp_idx_override,
                                     color_idx_override)
   local meta = player:get_meta()

   if chance and chance > math.random(100) then
      meta:set_string("civskins_"..cat, "")
      return
   end

   local comps = civskins.components[actual_cat or cat]
   if not comps then
      meta:set_string("civskins_"..cat, "")
      return
   end

   local comps_idx = comp_idx_override or math.random(#comps)
   if color_spec then
      local colors = color_spec.colors
      local randbase = color_spec.random_base
      local randpeak = color_spec.random_peak

      local color_idx = color_idx_override or math.random(#colors)
      if color_spec.biome_weighting then
         local ppos = player:get_pos()
         local heat = minetest.get_heat(ppos)
         if cat == "base" then
            -- this is a bit messy, but the results are good
            if heat > 75 then
               comps_idx = 2
               color_idx = math.random(6, 9)
            elseif heat > 60 and heat <= 75 then
               if math.random(2) == 2 then
                  comps_idx = 1
                  color_idx = math.random(7, 9)
               else
                  comps_idx = 2
                  color_idx = math.random(3, 6)
               end
            elseif heat > 35 and heat <= 60 then
               comps_idx = 1
               color_idx = math.random(4, 7)
            else
               comps_idx = 1
               color_idx = math.random(1, 3)
            end
         end
      end

      local colorize = "^[colorize:"..colors[color_idx]
         .. ":" .. tostring(math.random(randbase, randpeak))

      meta:set_string("civskins_"..cat, "("..comps[comps_idx]..colorize..")")
      return comps_idx, color_idx
   else
      meta:set_string(
         "civskins_"..cat, comps[comps_idx]
      )
      return comps_idx
   end
end

function civskins.gen_male_skin(player)
   set_meta_for_category(player, "base", "mbase", nil, skin_colors)
   set_meta_for_category(player, "hair", nil, 20, hair_colors)
   -- set_meta_for_category(meta, "face")

   -- since eye whites are constant, we should use the same whites and eyes
   local eye_idx = set_meta_for_category(player, "eyewhites")
   set_meta_for_category(player, "eyes", nil, nil, eye_colors, eye_idx)

   -- set_meta_for_category(meta, "beard", nil, 50)
   -- set_meta_for_category(meta, "chest")
   set_meta_for_category(player, "pants", nil, nil, pants_colors)
end

function civskins.gen_female_skin(player)
   set_meta_for_category(player, "base", "fbase", nil, skin_colors)
   -- set_meta_for_category(meta, "face")

   -- since eye whites are constant, we should use the same whites and eyes
   local eye_idx = set_meta_for_category(player, "eyewhites")
   set_meta_for_category(player, "eyes", nil, nil, eye_colors, eye_idx)

   local _, color_idx = set_meta_for_category(
      player, "pants", nil, nil, pants_colors
   )

   set_meta_for_category(
      player, "top", nil, nil, pants_colors, nil, color_idx
   )

   set_meta_for_category(player, "hair", "fhair", nil, hair_colors)
end

function civskins.has_skin(player)
   local meta = player:get_meta()
   return meta:get("civskins_base")
end

-- Basically, this is the entrypoint for 3d_armor, or whatever else cares about
-- our skin.

local function merge_components(components)
   local accum = ""
   for i,component in ipairs(components) do
      if accum ~= "" and component ~= "" then
         accum = accum .. "^" .. component
      elseif accum == "" and component ~= "" then
         accum = component
      end
   end
   return accum ~= "" and accum
end

local function get_component_for_category(meta, cat)
   return meta:get_string("civskins_"..cat)
end

function civskins.get_skin(pname)
   local player = minetest.get_player_by_name(pname)
   if not player then
      return "civskins_mbase_1.png"
   end

   local meta = player:get_meta()
   local skin = merge_components({
         get_component_for_category(meta, "base"),
         -- get_component_for_category(meta, "face"),
         get_component_for_category(meta, "eyewhites"),
         get_component_for_category(meta, "eyes"),
         get_component_for_category(meta, "top"),
         get_component_for_category(meta, "pants"),
         get_component_for_category(meta, "hair"),
   })
   return skin
end

function civskins.assign_skin(player)
   if math.random(0, 1) == 1 then
      civskins.gen_female_skin(player)
   else
      civskins.gen_male_skin(player)
   end
end

minetest.register_on_newplayer(function(player)
      civskins.assign_skin(player)
end)

minetest.register_on_joinplayer(function(player)
      if not civskins.has_skin(player) then
         civskins.assign_skin(player)
      end
end)
