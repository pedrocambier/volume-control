local volume = {}

local awful = require ("awful")
local wibox = require ("wibox")
local beautiful = require ("beautiful")

-- Helper Function
local function cmd(command)
	awful.spawn.with_shell(command)
end

-- Local Varibales
local init = true
local level = 50 -- initial level
local muted = false
local MIN = 0 -- minimum volume level of 'amixer plyback'
local MAX = 100 -- maximum volume level of 'amixer playback'
local STEP = 5 -- step to update volume level (up / down).
local widget = wibox.widget{
	markup = '',
	halign = "center",
	valign = "center",
	font = beautiful.font,
	widget = wibox.widget.textbox
}

-- Local Fucntions
local function getmessage(value)
	return string.format(" %-4s  ", value)
end
local function updatewidget()
	if(init) then
		awful.spawn.easy_async("wpctl get-volume @DEFAULT_AUDIO_SINK@", function(stdout)
			local value = tonumber(string.match(stdout, "%d%.%d+"))
			level = value * 100
			levelperc = math.tointeger(level)
			if(string.find(stdout, "MUTED")) then
				muted = true
				widget.markup = getmessage("  " .. levelperc .. "%")
			else
				muted = false
				widget.markup = getmessage("  " .. levelperc .. "%")
			end
		end)
		init = false
		return
	end
	levelperc = math.tointeger(level)
	if(muted) then
		widget.markup = getmessage("  " .. levelperc .. "%")
		return
	end
	widget.markup = getmessage("  " .. levelperc .. "%")
end

-- Update the widget to set an initial value
updatewidget()
--
local function updatelevel(val)
	level = level + val
	if(level > MAX) then
		level = MAX
	elseif (level < MIN) then
		level = MIN
	else
		return
	end
end

-- Public Functions
function volume.getwidget()
	return widget
end

function volume.up()
	cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ " .. STEP .. "%+")
	--cmd("amixer set Master playback " .. STEP .. "+")
	updatelevel(STEP)
	updatewidget()
end

function volume.down()
	cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ " .. STEP .. "%-")
	updatelevel(-STEP)
	updatewidget()
end

-- Mute / Unmute
function volume.toggle()
	cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
	muted = not muted
	updatewidget()
end

return volume
