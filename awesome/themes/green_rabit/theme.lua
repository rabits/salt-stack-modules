---------------------------
-- PSA's Awesome 3 theme --
---------------------------

config_path = "/usr/share/awesome/themes/green_rabit"
theme = {}

theme.font			= "DejaVu Sans Mono 12"

theme.bg_normal		= "#003300"
theme.bg_focus		= "#005500"
theme.bg_urgent		= "#00aa00"
theme.bg_minimize	= "#001100"

theme.fg_normal		= "#007700"
theme.fg_focus		= "#00cc00"
theme.fg_urgent		= "#00ff00"
theme.fg_minimize	= "#001100"

theme.border_width	= "1"
theme.border_normal	= "#000000"
theme.border_focus	= "#005500"
theme.border_marked	= "#004400"

-- There are another variables sets
-- overriding the default one when
-- defined, the sets are:
-- [taglist|tasklist]_[bg|fg]_[focus|urgent]
-- titlebar_[bg|fg]_[normal|focus]
-- Example:
--taglist_bg_focus = #ff0000

-- Display the taglist squares
theme.taglist_squares_sel		= config_path .. "/taglist/squarefw.png"
theme.taglist_squares_unsel		= config_path .. "/taglist/squarew.png"

theme.tasklist_floating_icon	= config_path .. "/tasklist/floatingw.png"

-- Variables set for theming menu
-- menu_[bg|fg]_[normal|focus]
-- menu_[border_color|border_width]
theme.menu_submenu_icon			= config_path .. "/submenu.png"
theme.menu_height				= "15"
theme.menu_width				= "150"

-- You can add as many variables as
-- you wish and access them by using
-- beautiful.variable in your rc.lua
--bg_widget    = #cc0000

-- Define the image to load
theme.titlebar_close_button_normal				= config_path .. "/titlebar/close_normal.png"
theme.titlebar_close_button_focus				= config_path .. "/titlebar/close_focus.png"

theme.titlebar_ontop_button_normal_inactive		= config_path .. "/titlebar/ontop_normal_inactive.png"
theme.titlebar_ontop_button_focus_inactive		= config_path .. "/titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_active		= config_path .. "/titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_active		= config_path .. "/titlebar/ontop_focus_active.png"

theme.titlebar_sticky_button_normal_inactive	= config_path .. "/titlebar/sticky_normal_inactive.png"
theme.titlebar_sticky_button_focus_inactive		= config_path .. "/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_active		= config_path .. "/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_active		= config_path .. "/titlebar/sticky_focus_active.png"

theme.titlebar_floating_button_normal_inactive	= config_path .. "/titlebar/floating_normal_inactive.png"
theme.titlebar_floating_button_focus_inactive	= config_path .. "/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_active	= config_path .. "/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_active		= config_path .. "/titlebar/floating_focus_active.png"

theme.titlebar_maximized_button_normal_inactive	= config_path .. "/titlebar/maximized_normal_inactive.png"
theme.titlebar_maximized_button_focus_inactive	= config_path .. "/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_active	= config_path .. "/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_active	= config_path .. "/titlebar/maximized_focus_active.png"

-- You can use your own command to set your wallpaper
theme.wallpaper_cmd = { "feh --bg-scale '" .. config_path .. "/background.png'" }

-- You can use your own layout icons like this:
theme.layout_fairh		= config_path .. "/layouts/fairhw.png"
theme.layout_fairv		= config_path .. "/layouts/fairvw.png"
theme.layout_floating	= config_path .. "/layouts/floatingw.png"
theme.layout_magnifier	= config_path .. "/layouts/magnifierw.png"
theme.layout_max		= config_path .. "/layouts/maxw.png"
theme.layout_fullscreen	= config_path .. "/layouts/fullscreenw.png"
theme.layout_tilebottom	= config_path .. "/layouts/tilebottomw.png"
theme.layout_tileleft	= config_path .. "/layouts/tileleftw.png"
theme.layout_tile		= config_path .. "/layouts/tilew.png"
theme.layout_tiletop	= config_path .. "/layouts/tiletopw.png"
--theme.layout_spiral  = config_path .. "/layouts/spiralw.png"
--theme.layout_dwindle = config_path .. "/layouts/dwindlew.png"

--theme.awesome_icon = "/usr/share/awesome/icons/awesome16.png"

return theme
