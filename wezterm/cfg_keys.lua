local wezterm = require "wezterm"

local cfg = {}

cfg.disable_default_key_bindings = true
cfg.enable_csi_u_key_encoding = true

cfg.keys = {

  -- Tabs
  -- {mods = "SUPER",   key = "n", action = wezterm.action{SpawnTab="DefaultDomain"}},
  -- {mods = "SUPER",   key = "l", action = wezterm.action{ActivateTabRelative=1}},
  -- {mods = "SUPER",   key = "h", action = wezterm.action{ActivateTabRelative=-1}},
  -- {mods = "SUPER",   key = "w", action = wezterm.action{CloseCurrentTab={confirm=true}}}, -- Ctrl-Shift-w

  -- Wezterm features
  { mods = 'SUPER',             key = 'q',  action = wezterm.action.QuitApplication },
  { mods = 'SUPER',             key = 'n',  action = wezterm.action.SpawnWindow },

  { mods = 'SUPER|SHIFT',       key = 't',  action = wezterm.action.SpawnTab 'CurrentPaneDomain', },

  { mods = "SUPER",             key = "k",  action = wezterm.action{ClearScrollback = "ScrollbackAndViewport"}},
  { mods = "SUPER",             key = "f",  action = wezterm.action{Search = {CaseInSensitiveString = ""}}},

  { mods = "SUPER",             key = "y",  action = wezterm.action.SendString '\x18\x40\x73\x79'     }, -- SUPER+Y in terminal, send C-x @ s y   hex code get from showkey -a
  { mods = "SUPER",             key = "o",  action = wezterm.action.SendString '\x18\x40\x73\x6f'     }, -- SUPER+o in terminal, send C-x @ s o   hex code get from showkey -a
  { mods = "SUPER",             key = "b",  action = wezterm.action.SendString '\x18\x40\x73\x62'     }, -- SUPER+b in terminal, send C-x @ s b   hex code get from showkey -a
  { mods = "SUPER|SHIFT",       key = ";",  action = wezterm.action.SendString '\x18\x40\x73\x3a'     }, -- SUPER+: in terminal, send C-x @ s :   hex code get from showkey -a

  { mods = "SUPER",             key = "c",  action = wezterm.action{CopyTo = "Clipboard"}},
  { mods = "SUPER",             key = "v",  action = wezterm.action.PasteFrom("Clipboard")},

  { mods = "CTRL",              key = "Insert",  action = wezterm.action{CopyTo = "Clipboard"}},
  { mods = "SHIFT",             key = "Insert",  action = wezterm.action.PasteFrom("Clipboard")},

  { mods = "SUPER|SHIFT",       key = "j",  action = wezterm.action.SendString '\x13\x0a'     }, -- cmd+shift+j  next session,  send C-s C-j
  { mods = "SUPER|SHIFT",       key = "k",  action = wezterm.action.SendString '\x13\x0b'     }, -- cmd+shift+k  next session,  send C-s C-k

  { mods = "SUPER|SHIFT",       key = "h",  action = wezterm.action.SendString '\x13\x13\x68'     }, -- cmd+shift+h  send C-s C-s h
  { mods = "SUPER|SHIFT",       key = "l",  action = wezterm.action.SendString '\x13\x13\x6c'     }, -- cmd+shift+l  send C-s C-s l
  { mods = "SUPER|SHIFT",       key = "n",  action = wezterm.action.SendString '\x13\x13\x6e'     }, -- cmd+shift+l  send C-s C-s n

  { mods = "SUPER",             key = "h",  action = wezterm.action.SendString '\x13\x68'     }, -- cmd+h        next window,   send C-s h
  { mods = "SUPER",             key = "l",  action = wezterm.action.SendString '\x13\x6c'     }, -- cmd+l        next window,   send C-s l

  { mods = "SUPER|SHIFT",       key = "{",  action = wezterm.action.SendString '\x13\x68'     }, -- cmd+h        next window,   send C-s h
  { mods = "SUPER|SHIFT",       key = "}",  action = wezterm.action.SendString '\x13\x6c'     }, -- cmd+l        next window,   send C-s l

  -- { mods = "SUPER|SHIFT",       key = "{",  action = wezterm.action.ActivateTabRelative(-1)    }, -- cmd+shift+[  prev tab
  -- { mods = "SUPER|SHIFT",       key = "}",  action = wezterm.action.ActivateTabRelative(1)     }, -- cmd+shift+]  next tab

  { mods = "SUPER",             key = "t",  action = wezterm.action.SendString '\x13\x6e'     }, -- cmd+t  new window,          send C-s c
  { mods = "SUPER",             key = "w",  action = wezterm.action.SendString '\x13\x78'     }, -- cmd+d  kill pane,           send C-s x
  { mods = "SUPER",             key = "W",  action = wezterm.action.SendString '\x13\x58'     }, -- cmd+d  kill pane,           send C-s X
  { mods = "SUPER",             key = "r",  action = wezterm.action.SendString '\x13\x5b'     }, -- cmd+r  selection mode,      send C-s [
  { mods = "SUPER",             key = "e",  action = wezterm.action.SendString '\x13\x6d'     }, -- cmd+m  toggle mouse,        send C-s m

  { mods = "SUPER",             key = "1",  action = wezterm.action.SendString '\x13\x31'     }, -- cmd+m  toggle mouse,        send C-s m
  { mods = "SUPER",             key = "2",  action = wezterm.action.SendString '\x13\x32'     }, -- cmd+m  toggle mouse,        send C-s m
  { mods = "SUPER",             key = "3",  action = wezterm.action.SendString '\x13\x33'     }, -- cmd+m  toggle mouse,        send C-s m
  { mods = "SUPER",             key = "4",  action = wezterm.action.SendString '\x13\x34'     }, -- cmd+m  toggle mouse,        send C-s m
  { mods = "SUPER",             key = "5",  action = wezterm.action.SendString '\x13\x35'     }, -- cmd+m  toggle mouse,        send C-s m
  { mods = "SUPER",             key = "6",  action = wezterm.action.SendString '\x13\x36'     }, -- cmd+m  toggle mouse,        send C-s m
  { mods = "SUPER",             key = "7",  action = wezterm.action.SendString '\x13\x37'     }, -- cmd+m  toggle mouse,        send C-s m
  { mods = "SUPER",             key = "8",  action = wezterm.action.SendString '\x13\x38'     }, -- cmd+m  toggle mouse,        send C-s m
  { mods = "SUPER",             key = "9",  action = wezterm.action.SendString '\x13\x39'     }, -- cmd+m  toggle mouse,        send C-s m
  { mods = "SUPER",             key = "0",  action = wezterm.action.SendString '\x13\x30'     }, -- cmd+m  toggle mouse,        send C-s m







  { mods = 'SUPER',             key = '=',  action = wezterm.action.IncreaseFontSize },
  { mods = 'SUPER',             key = '-',  action = wezterm.action.DecreaseFontSize },

  { mods = "CTRL",              key = "X",  action = "ShowLauncher"},
  { mods = "CTRL",              key = "q",  action = wezterm.action.SendString '\x11'         }, -- ctrl-q      send ctrl-q
  { mods = "CTRL",              key = "/",  action = wezterm.action.SendString '\x1f'         }, -- ctrl-/      send ctrl-/, which is equal with ctrl-_

  -- {mods = "CTRL", key = "0", action = "ResetFontSize"}, -- Ctrl-Shift-0
}

wezterm.on("my-toggle-ligature", function(win, _pane)
  local overrides = win:get_config_overrides() or {}
  if not overrides.harfbuzz_features then
    -- If we haven't overriden it yet, then override with ligatures disabled
    overrides.harfbuzz_features =  {"calt=0", "clig=0", "liga=0"}
  else
    -- else we did already, and we should disable the override now
    overrides.harfbuzz_features = nil
  end
  win:set_config_overrides(overrides)
end)

local key_ev = {mods = "CTRL", key = "G", action = wezterm.action{EmitEvent="my-toggle-ligature"}} -- Ctrl-Shift-g
table.insert(cfg.keys, key_ev)

return cfg
