-- Rabit's Configuration file for Awesome 3.4
-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")

-- Scratchpad
local scratch = require("scratch")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Error:",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.add_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
theme_path = "/usr/share/awesome/themes/green_rabit/theme.lua"
beautiful.init(theme_path)

-- This is used later as the default terminal and editor to run.
terminal = "x-terminal-emulator"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
--    awful.layout.suit.tile,
--    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
--    awful.layout.suit.tile.top,
--    awful.layout.suit.fair,
--    awful.layout.suit.fair.horizontal,
--    awful.layout.suit.spiral,
--    awful.layout.suit.spiral.dwindle,
--    awful.layout.suit.max,
--    awful.layout.suit.max.fullscreen,
--    awful.layout.suit.magnifier,
    awful.layout.suit.floating
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
-- Taglist numerals
taglist_numbers_langs = {
    'arabic',
    'chinese',
    'traditional_chinese',
    'east_arabic',
    'roman',
    'thai',
}
taglist_numbers_sets = {
    arabic={ 1, 2, 3, 4, 5, 6, 7, 8, 9 },
    chinese={"一", "二", "三", "四", "五", "六", "七", "八", "九"},
    traditional_chinese={"壹", "貳", "叄", "肆", "伍", "陸", "柒", "捌", "玖"},
    east_arabic={'١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'}, -- '٠' 0
    roman={'Ⅰ', 'Ⅱ', 'Ⅲ', 'Ⅳ', 'Ⅴ', 'Ⅵ', 'Ⅶ', 'Ⅷ', 'Ⅸ'},
    thai={'๑', '๒', '๓', '๔', '๕', '๖', '๗', '๘', '๙'},
}

tags = {}
math.randomseed(os.time())
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    local taglist = taglist_numbers_sets[taglist_numbers_langs[math.random(table.getn(taglist_numbers_langs))]]
    tags[s] = awful.tag(taglist, s, layouts[1])
    awful.layout.set(awful.layout.suit.floating, tags[s][1])
    awful.layout.set(awful.layout.suit.tile.left, tags[s][5])
    awful.layout.set(awful.layout.suit.floating, tags[s][8])
end
-- }}}

-- {{{ Wibox
-- Separator
separator = widget({ type = "textbox" })
separator.width = 3

-- CPU
cpuwidget = { layout = awful.widget.layout.horizontal.leftright }
local jiffies = {}
function activecpu()
    for line in io.lines("/proc/stat") do
        local cpu, user, nice, sys = string.match(line, "cpu(%d+)\ +(%d+)\ +(%d+)\ +(%d+)")
        if cpu and user and sys and nice then
            local newjiffies = user + nice + sys
            cpu = cpu + 1
            if not jiffies[cpu] then
                jiffies[cpu] = newjiffies
                cpuwidget[cpu] = {}
                cpuwidget[cpu][1] = awful.widget.progressbar()
                cpuwidget[cpu][1]:set_width(10)
                cpuwidget[cpu][1]:set_height(28)
                cpuwidget[cpu][1]:set_color("#00ff00")
                cpuwidget[cpu][1]:set_max_value(100)
                cpuwidget[cpu][1]:set_vertical(true)
                cpuwidget[cpu][2] = widget({ type="textbox" })
            end
            local factive = io.open("/sys/devices/system/cpu/cpu" .. (cpu - 1) .. "/online")
            cpuwidget[cpu][1]:set_background_color("#000000")
            if factive ~= nil then
                if factive:read("*n") ~= 1 then
                    cpuwidget[cpu][1]:set_background_color("#333333")
                end
                factive:close()
            end
            cpuwidget[cpu][1]:set_value(newjiffies-jiffies[cpu])
            cpuwidget[cpu][2].text = "<b>" .. cpu .. "</b>"
            jiffies[cpu] = newjiffies
        end
    end
end

-- Clock for cpu
local cputimer = timer { timeout = 1 }
cputimer:add_signal("timeout", function() activecpu() end)
cputimer:start()

-- MEMORY
memwidget = {}
local memtext = "00.0%"
memwidget[2] = widget({ type="textbox" })
memwidget[2].text = memtext
memwidget[1] = awful.widget.progressbar()
memwidget[1]:set_width(50)
memwidget[1]:set_height(34)
memwidget[1]:set_color("#004400")
memwidget[1]:set_background_color("#000000")
memwidget[1]:set_vertical(false)

function activemem()
    local total, free
    free = 0
    for line in io.lines('/proc/meminfo') do
        for key, value in string.gmatch(line, "(%w+):\ +(%d+).+") do
            if key == "MemFree" then free = free + tonumber(value)
            elseif key == "Buffers" then free = free + tonumber(value)
            elseif key == "Cached" then free = free + tonumber(value)
            elseif key == "MemTotal" then total = tonumber(value) end
        end
    end
    memwidget[2].text = string.format("%4.1f%%",(100-(free/total)*100))
    memwidget[1]:set_max_value(total)
    memwidget[1]:set_value(total-free)
end

-- Clock for mem
local memtimer = timer { timeout = 5 }
memtimer:add_signal("timeout", function() activemem() end)
memtimer:start()

-- BATTERY
batterywidget = { layout = awful.widget.layout.horizontal.leftright }
for line in io.popen('ls -a /sys/class/power_supply'):lines() do
    local f = io.open("/sys/class/power_supply/" .. line .. "/capacity", 'r')
    if f ~= nil then
        io.close(f)
        local battery = string.format("%5s",string.sub(line,0,5))
        batterywidget[line] = {}
        batterywidget[line][2] = widget({ type="textbox" })
        batterywidget[line][2].text = battery
        batterywidget[line][1] = awful.widget.progressbar()
        batterywidget[line][1]:set_width(50)
        batterywidget[line][1]:set_height(34)
        batterywidget[line][1]:set_color("#00ff00")
        batterywidget[line][1]:set_background_color("#000000")
        batterywidget[line][1]:set_max_value(100)
        batterywidget[line][1]:set_vertical(false)
    end
end
function activebattery()
    for battery in pairs(batterywidget) do
        if battery ~= "layout" then
            local fstatus = io.open("/sys/class/power_supply/" .. battery .. "/status")
            local fcapacity = io.open("/sys/class/power_supply/" .. battery .. "/capacity")
            if fcapacity ~= nil then
                local capacity = fcapacity:read("*n")
                if fstatus:read() == "Charging" then
                    batterywidget[battery][1]:set_background_color("#002200")
                    batterywidget[battery][1]:set_color("#005500")
                else
                    if capacity ~= nil then
                        if capacity > 15 then
                            batterywidget[battery][1]:set_background_color("#000000")
                            batterywidget[battery][1]:set_color("#000077")
                        else
                            batterywidget[battery][1]:set_background_color("#770000")
                        end
                    end
                end
                fstatus:close()
                batterywidget[battery][1]:set_value(capacity)
                fcapacity:close()
            end
        end
    end
end

-- Clock for battery
local batterytimer = timer { timeout = 10 }
batterytimer:add_signal("timeout", function() activebattery() end)
batterytimer:start()

-- Vicious widgets
--vicious = require("vicious")

-- Layout display
layoutwidget = widget({ type="textbox", align = "right" })

function refreshlayout()
   local layout = os.execute("xset -q | grep -F LED | cut -c63 | grep -q -F '0'")
   if layout == 0 then layoutwidget.text = 'en'
   else layoutwidget.text = 'ru' end
end

local layouttimer = timer { timeout = 2 }
layouttimer:add_signal("timeout", function() refreshlayout() end)
layouttimer:start()

-- Create a clockbox widget
myclockbox = widget({ type="textbox", align = "right" })

-- Create a systray
mysystray = widget({ type = "systray" })

-- Create machine name
mymachinename = widget({ type="textbox", align="left" })
mymachinename:buttons(awful.util.table.join(
   awful.button({ }, 1, function () scratch.drop("urxvt", "bottom", "center", 1, 0.5, true) end)
))

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
    awful.button({ }, 1, awful.tag.viewonly)
)
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
    awful.button({ }, 1, function (c)
        if not c:isvisible() then
            awful.tag.viewonly(c:tags()[1])
        end
        client.focus = c
        c:raise()
    end)
)

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
        awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
        awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end)
    ))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
        return awful.widget.tasklist.label.currenttags(c, s)
        end, mytasklist.buttons
    )

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
            mymachinename,
            mytaglist[s],
            mylayoutbox[s],
            s == 1 and cpuwidget or nil,
            s == 1 and separator or nil,
            s == 1 and memwidget or nil,
            s == 1 and separator or nil,
            s == 1 and batterywidget or nil,
            mypromptbox[s],
            separator,
            layout = awful.widget.layout.horizontal.leftright
        },
        myclockbox,
        separator,
        layoutwidget,
        s == 1 and mysystray or nil,
        separator,
        mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }
end
-- }}}

-- {{{ Mouse bindings
--root.buttons(awful.util.table.join(
--    awful.button({ }, 3, function () mymainmenu:toggle() end),
--    awful.button({ }, 4, awful.tag.viewnext),
--    awful.button({ }, 5, awful.tag.viewprev)
--))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    -- Switch layout
    awful.key({ modkey,        }, "Left",    awful.tag.viewprev),
    awful.key({ modkey,        }, "Right",   awful.tag.viewnext),
    awful.key({ modkey,        }, "Escape",  awful.tag.history.restore),
    awful.key({ modkey         }, "l", function () awful.util.spawn('light-locker-command -l') end),
    awful.key({ "Mod1"         }, "space", function () scratch.drop("urxvt", "bottom", "center", 1, 0.5, true) end),

    awful.key({ modkey,        }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,            }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,            }, "w", function () mymainmenu:show(true)        end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"    }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"    }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,            }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,            }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,                }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control"    }, "r", awesome.restart),
--    awful.key({ modkey, "Shift"        }, "q", awesome.quit),

    awful.key({ modkey,                }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,                }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"        }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"        }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control"    }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control"    }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,                }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"        }, "space", function () awful.layout.inc(layouts, -1) end),

    -- Prompt
    awful.key({ modkey                }, "x",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey                }, "r",
              function ()
                  awful.prompt.run({ prompt = "Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,                }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"        }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control"      }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control"      }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,                }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"        }, "r",      function (c) c:redraw()                        end),
    awful.key({ modkey,                }, "n",      function (c) c.minimized = not c.minimized    end),
    awful.key({ modkey,                }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical    = not c.maximized_vertical
        end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
    keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                function ()
                    local screen = mouse.screen
                    if tags[screen][i] then
                        awful.tag.viewonly(tags[screen][i])
                    end
                end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                function ()
                    local screen = mouse.screen
                    if tags[screen][i] then
                      awful.tag.viewtoggle(tags[screen][i])
                    end
                end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                function ()
                    if client.focus and tags[client.focus.screen][i] then
                        awful.client.movetotag(tags[client.focus.screen][i])
                    end
                end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                function ()
                    if client.focus and tags[client.focus.screen][i] then
                        awful.client.toggletag(tags[client.focus.screen][i])
                    end
                end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
        properties = { floating = true } },
    { rule = { class = "Smplayer" },
        properties = { floating = true } },
    { rule = { class = "feh" },
        properties = { floating = true } },
    { rule = { class = "psi", name = "Psi+" },
        callback = awful.mouse.client.snap },
    { rule = { class = "Gimp" },
        properties = { }, callback = awful.mouse.client.snap },
    -- always map on tags.
    { rule = { class = "Firefox" },
        properties = { tag = tags[1][1] } },
    { rule = { class = "psi" },
        properties = { tag = tags[1][4] } },
    { rule = { class = "Thunderbird" },
        properties = { tag = tags[1][5] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)
        c.size_hints_honor = false

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
--
-- Timers and setups

-- Clock for cpu
clocktimer = timer { timeout = 1 }
clocktimer:add_signal("timeout", function()
    myclockbox.text = "(" .. os.time() .. ") " .. os.date("%X %d/%m/%y") .. " "
end)
clocktimer:start()

-- Machine name
for line in io.lines("/etc/hostname") do
    hostname = os.getenv("USER") .. "@" .. line
end
mymachinename.text = " <b>" .. hostname .. "</b> "

-- Autorun programs

-- Run program in one instance
function run_once(prg, screen)
    if not prg then
        do return nil end
    end
    local program = string.match(prg, "^([-_%a%d]+)")
    awful.util.spawn_with_shell("pgrep -f -u " .. os.getenv("USER") .. " -x " .. program .. " || (" .. prg .. ")", screen)
end

autorun = true
autorunApps = 
{ 
    "thunderbird",
    "keepassx",
    "nm-applet",
    "gnome-sound-applet",
    "light-locker"
}
if autorun then
    for app = 1, #autorunApps do
        run_once(autorunApps[app])
    end
end

