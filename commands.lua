
minetest.register_privilege("civskins", "Allows CivSkins-related commands.")

local function skin_base_setter(skin_base)
   return function(sender, target)
      local player = minetest.get_player_by_name(target)
      if not player then
         minetest.chat_send_player(sender, "Player not found.")
         return false
      end

      civskins.assign_skin(player, skin_base)

      minetest.chat_send_player(
         sender, "Skin for "..target.." changed to "..skin_base.."."
      )

      if armor then
         armor.textures[target].skin = armor:get_player_skin(target)
         armor:update_player_visuals(player)
      end
   end
end


minetest.register_chatcommand(
   "civskins_set_male",
   {
      params = "[<target>]",
      description = "Sets a target player's skin to a random male one.",
      privs = { civskins = true },
      func = skin_base_setter("male")
   }
)

minetest.register_chatcommand(
   "civskins_set_female",
   {
      params = "[<target>]",
      description = "Sets a target player's skin to a random female one.",
      privs = { civskins = true },
      func = skin_base_setter("female")
   }
)
