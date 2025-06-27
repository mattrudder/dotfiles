
-- Window Management
local function move_window_to_screen(screen, x, y, w, h)
    local win = hs.window.focusedWindow()
    local f = win:frame()
    local max = screen:frame()

    f.x = max.x + (max.w * x)
    f.y = max.y + (max.h * y)
    f.w = max.w * w
    f.h = max.h * h
    win:setFrame(f)
end

local function move_window(x, y, w, h)
    local win = hs.window.focusedWindow()
    move_window_to_screen(win:screen(), x, y, w, h)
end

local function move_window_to_next_screen()
    local win = hs.window.focusedWindow()
    local f = win:frame()
    local screen = win:screen()
    local max = screen:frame()
    local next = screen:next()

    local w = f.w / max.w
    local h = f.h / max.h
    local x = (f.x - max.x) / max.w
    local y = (f.y - max.y) / max.h
    move_window_to_screen(next, x, y, w, h)
end

-- Left Half: Ctrl+Shift+Cmd+Left
hs.hotkey.bind({"ctrl", "shift"}, "Left", function()
    move_window(0, 0, 0.5, 1)
end)

-- Right Half: Ctrl+Shift+Cmd+Right
hs.hotkey.bind({"ctrl", "shift"}, "Right", function()
    move_window(0.5, 0, 0.5, 1)
end)

-- Top Half: Ctrl+Shift+Cmd+Top
hs.hotkey.bind({"ctrl", "shift"}, "Up", function()
    move_window(0, 0, 1, 0.5)
end)

-- Bottom Half: Ctrl+Shift+Cmd+Down
hs.hotkey.bind({"ctrl", "shift"}, "Down", function()
    move_window(0, 0.5, 1, 0.5)
end)

-- Maximize: Ctrl+Shift+Cmd+Return
hs.hotkey.bind({"ctrl", "shift"}, "Return", function()
    move_window(0, 0, 1, 1)
end)

-- Centered 75%: Ctrl+Shift+Cmd+Delete
hs.hotkey.bind({"ctrl", "shift"}, "Delete", function()
    move_window(0.125, 0.125, 0.75, 0.75)
end)

-- Move window to next screen: Ctrl+Shift+Space
hs.hotkey.bind({"ctrl", "shift"}, "Space", function()
    move_window_to_next_screen()
end)

-- Sleep: Shift+Cmd+F12
hs.hotkey.bind({"ctrl", "shift"}, "f12", function()
    hs.execute("pmset displaysleepnow")
end)

-- Console
hs.hotkey.bind({"ctrl", "shift"}, "C", function()
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

