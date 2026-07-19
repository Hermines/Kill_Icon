return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Kill_Icon` encountered an error loading the Darktide Mod Framework.")

		new_mod("Kill_Icon", {
			mod_script       = "Kill_Icon/scripts/mods/Kill_Icon/Kill_Icon",
			mod_data         = "Kill_Icon/scripts/mods/Kill_Icon/Kill_Icon_data",
			mod_localization = "Kill_Icon/scripts/mods/Kill_Icon/Kill_Icon_localization",
		})
	end,
	packages = {},
}
