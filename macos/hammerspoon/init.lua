
-- Window Management
local function move_window(x, y, w, h)
    local win = hs.window.focusedWindow()
    local f = win:frame()
    local screen = win:screen()
    local max = screen:frame()

    f.x = max.x + (max.w * x)
    f.y = max.y + (max.h * y)
    f.w = max.w * w
    f.h = max.h * h
    win:setFrame(f)
end

-- Left Half: Ctrl+Shift+Cmd+Left
hs.hotkey.bind({"ctrl", "shift", "cmd"}, "Left", function()
    move_window(0, 0, 0.5, 1)
end)

-- Right Half: Ctrl+Shift+Cmd+Right
hs.hotkey.bind({"ctrl", "shift", "cmd"}, "Right", function()
    move_window(0.5, 0, 0.5, 1)
end)

-- Top Half: Ctrl+Shift+Cmd+Top
hs.hotkey.bind({"ctrl", "shift", "cmd"}, "Up", function()
    move_window(0, 0, 1, 0.5)
end)

-- Bottom Half: Ctrl+Shift+Cmd+Down
hs.hotkey.bind({"ctrl", "shift", "cmd"}, "Down", function()
    move_window(0, 0.5, 1, 0.5)
end)

-- Maximize: Ctrl+Shift+Cmd+Return
hs.hotkey.bind({"ctrl", "shift", "cmd"}, "Return", function()
    move_window(0, 0, 1, 1)
end)

-- Centered 75%: Ctrl+Shift+Cmd+Delete
hs.hotkey.bind({"ctrl", "shift", "cmd"}, "Delete", function()
    move_window(0.125, 0.125, 0.75, 0.75)
end)

-- Sleep: Shift+Cmd+F12
hs.hotkey.bind({"shift", "cmd"}, "f12", function()
    hs.execute("pmset displaysleepnow")
end)

-- Console
hs.hotkey.bind({"ctrl", "shift", "cmd"}, "C", function()
    hs.toggleConsole()
end)

-- Console
hs.hotkey.bind({"ctrl", "shift", "cmd"}, "C", function()
    hs.toggleConsole()
end)

-- Reload
local function reload_config(files)
    local do_reload = false
    for _, file in pairs(files) do
        if file:sub(-4) == ".lua" then
            do_reload = true
        end
    end

    if do_reload then
        hs.reload()
    end
end

local watcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reload_config):start()
hs.notify.new({title="Hammerspoon", informativeText="Config loaded"}):send()

