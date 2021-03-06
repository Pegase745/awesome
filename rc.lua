--{{---| Libraries |-----------------------------------------------------------

-- Standard awesome library
local gears 	= require("gears")
local awful	= require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")

-- Widget and layout library
local wibox 	= require("wibox")
local vicious 	= require("vicious")
local assault   = require("widgets.assault")
require("widgets.volume")
require("widgets.kbdcfg")

-- Theme handling library
local beautiful = require("beautiful")

-- Notification library
local naughty 	= require("naughty")
local menubar 	= require("menubar")

--{{---| Error handling |-------------------------------------------------------

if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end

--{{---| Theme |----------------------------------------------------------------

beautiful.init("/usr/share/awesome/themes/default/theme.lua")
-- theme.wallpaper = "/home/pegase/Perso/Pictures/mile.jpg"

--{{---| Variables |------------------------------------------------------------

modkey 		= "Mod4"
terminal 	= "x-terminal-emulator -x tmux"
editor 		= os.getenv("EDITOR") or "editor"
editor_cmd 	= terminal .. " -e " .. editor

--{{---| Table of layouts |------------------------------------------------------

local layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.max.fullscreen,
}

--{{---| Wallpaper |-------------------------------------------------------------

if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end

--{{---| Tags |------------------------------------------------------------------

tags = {}
for s = 1, screen.count() do
    tags[s] = awful.tag({ 1, 2, 3, 4, 5 }, s, layouts[2])
end

--{{---| Tags |------------------------------------------------------------------

myawesomemenu = {
   { "edit config", 		editor_cmd .. " " .. awesome.conffile },
   { "restart", 		awesome.restart },
   { "quit", 			awesome.quit }
}

myappsmenu = {
   { "calculator",         "gnome-calculator" },
   { "file manager",       "gnome-open /home/pegase/" },
   { "terminal",           terminal }
}

mymainmenu = awful.menu({ items = {
	{ "awesome",		myawesomemenu },
	{ "apps",		myappsmenu },
        { "hibernate",          "sudo pm-hibernate" },
        { "reboot",             "sudo reboot" },
        { "shutdown",           "sudo halt -p" }
   }
})

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon, menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it

--{{---| Widgets |-------------------------------------------------------------------------------------------

-- Textclock

local clockwidget = awful.widget.textclock()

-- CPU

local cpuwidget = awful.widget.graph()
cpuwidget:set_width(50)
cpuwidget:set_background_color("#494B4F")
cpuwidget:set_color({ type = "linear", from = { 0, 0 }, to = { 10,0 }, stops = { {0, "#FF5656"}, {0.5, "#88A175"},
                    {1, "#AECF96" }}})
vicious.register(cpuwidget, vicious.widgets.cpu, "$1")

-- RAM

local memwidget = awful.widget.progressbar()
memwidget:set_width(8)
memwidget:set_height(10)
memwidget:set_vertical(true)
memwidget:set_background_color("#494B4F")
memwidget:set_border_color(nil)
memwidget:set_color({ type = "linear", from = { 0, 0 }, to = { 10,0 }, stops = { {0, "#AECF96"}, {0.5, "#88A175"},
                    {1, "#FF5656"}}})
vicious.register(memwidget, vicious.widgets.mem, "$1", 13)

-- Battery (needs acpi)

local batterywidget = assault({
   battery = "BAT1", -- battery ID to get data from
   adapter = "AC", -- ID of the AC adapter to get data from
   width = 36, -- width of battery
   height = 15, -- height of battery
   bolt_width = 19, -- width of charging bolt
   bolt_height = 11, -- height of charging bolt
   stroke_width = 2, -- width of battery border
   peg_top = (calculated), -- distance from the top of the battery to the start of the peg
   font = beautiful.font, -- font to use
   critical_level = 0.10, -- battery percentage to mark as critical (between 0 and 1, default is 10%)
   normal_color = beautiful.fg_normal, -- color to draw the battery when it's discharging
   critical_color = "#ff0000", -- color to draw the battery when it's at critical level
   charging_color = "#00ff00" -- color to draw the battery when it's charging
})

-- Function to return time remaining for battery
function get_battery_remaining_time()
    local fh = assert(io.popen("acpi | cut -d, -f 3 -", "r"))
    local str = fh:read("*l")
    return str 
end

batterytooltip = awful.tooltip({ objects = { batterywidget }, })

batterywidgettimer = timer({ timeout = 10 })
batterywidgettimer:connect_signal("timeout",
  function()
	batterytooltip:set_text(get_battery_remaining_time())
  end    
)    
batterywidgettimer:start()

-- Separators

spr = wibox.widget.textbox()
spr:set_text(' ')

--{{---| Wibox |-------------------------------------------------------------------------------------------

mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({
                                                      theme = { width = 250 }
                                                  })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    mypromptbox[s] = awful.widget.prompt()
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s, height = "16" })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mylauncher)
    left_layout:add(spr)
    left_layout:add(mytaglist[s])
    left_layout:add(mypromptbox[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    if s == 1 then right_layout:add(wibox.widget.systray()) end
    right_layout:add(spr)
    right_layout:add(spr)
    right_layout:add(mylayoutbox[s])
    right_layout:add(spr)
    right_layout:add(cpuwidget)
    right_layout:add(spr)
    right_layout:add(memwidget)
    right_layout:add(spr)
    right_layout:add(batterywidget)
    right_layout:add(spr)
    right_layout:add(volume_widget)
    right_layout:add(spr)
    right_layout:add(kbdcfg.widget)
    right_layout:add(spr)
    right_layout:add(clockwidget)

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
end

--{{---| Mouse bindings |-----------------------------------------------------------------------------------

root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))

--{{---| Key bindings |-----------------------------------------------------------------------------------

globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),
    -- Menubar
    -- awful.key({ modkey }, 	     "p", function() menubar.show() end),

    -- (Launch xev and on key press, fetch the keymap code for binding)

    -- Audio
    awful.key({ }, "XF86AudioLowerVolume", function () awful.util.spawn("amixer -D pulse sset Master 5%-") end),
    awful.key({ }, "XF86AudioRaiseVolume", function () awful.util.spawn("amixer -D pulse sset Master 5%+") end),
    awful.key({ }, "XF86AudioMute",        function () awful.util.spawn("amixer -D pulse sset Master toggle") end),
    awful.key({ }, "XF86AudioMicMute",     function () awful.util.spawn("amixer -D pulse sset Mic toggle") end),

    -- Brightness (apt-get install xbacklight)
    awful.key({ }, "XF86MonBrightnessDown", function () awful.util.spawn("xbacklight -dec 15") end),
    awful.key({ }, "XF86MonBrightnessUp", function () awful.util.spawn("xbacklight -inc 15") end),

    -- Screenshot (apt-get install scrot)
    awful.key({ }, "Print", function () awful.util.spawn("scrot -u -e 'gimp $f'") end),

    -- Special Keys
    -- awful.key({ }, "XF86Display",    function () awful.util.spawn("automatic xrandr setup") end),
    -- awful.key({ }, "XF86WLAN",       function () awful.util.spawn("cut/uncut wifi") end),
    -- awful.key({ }, "XF86Tools",      function () awful.util.spawn("open settings i guess") end),
    -- awful.key({ }, "XF86Search",     function () awful.util.spawn("search for something") end),
    -- awful.key({ }, "XF86LaunchA",    function () awful.util.spawn("launch an app") end),
    awful.key({ }, "XF86MyComputer", function () awful.util.spawn("gnome-open /home/pegase/") end),

    -- Screen lock
    awful.key({ modkey, "Control" }, "l", function () awful.util.spawn("xscreensaver-command -lock") end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    -- awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey,           }, "o",      function (c) awful.client.movetoscreen(c,c.screen-1) end),
    awful.key({ modkey,           }, "p",      function (c) awful.client.movetoscreen(c,c.screen+1) end),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Bind all key numbers to tags.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.movetotag(tag)
                          end
                     end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.toggletag(tag)
                          end
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

--{{---| Set keys |-------------------------------------------------------------

root.keys(globalkeys)

--{{---| Rules |----------------------------------------------------------------

awful.rules.rules = {
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}

--{{---| Signals |--------------------------------------------------------------

client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

--{{---| Run Once |-----------------------------------------------------------------------

function run_once(prg,arg_string,pname,screen)
    if not prg then
        do return nil end
    end

    if not pname then
       pname = prg
    end

    if not arg_string then
        awful.util.spawn_with_shell("pgrep -f -u $USER -x '" .. pname .. "' || (" .. prg .. ")",screen)
    else
        awful.util.spawn_with_shell("pgrep -f -u $USER -x '" .. pname .. " ".. arg_string .."' || (" .. prg .. " " .. arg_string .. ")",screen)
    end
end

--{{---| Autostart |--------------------------------------------------------------------------

-- Network manager applet
run_once("nm-applet",nil)

-- xScreensaver
awful.util.spawn_with_shell("xscreensaver -no-splash")

-- Work special screens
-- awful.util.spawn_with_shell("xrandr --output DP-2 --auto --left-of eDP-1 && xrandr --output HDMI-1 --auto --left-of DP-2")
awful.util.spawn_with_shell("xrandr --output eDP-1 --auto --left-of DP-2")
