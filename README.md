# NexusHub Dashboard for Omarchy

A modular Quickshell dashboard for Omarchy with a dock, personal widgets, and persistent profiles.

## Widget controls and profiles

Open the NexusHub Control Center and use the controls card to show or hide System Monitor, Weather, GitHub Activity, and Project Pulse. Changes persist through Omarchy's bar settings.

- **Development** — System Monitor, GitHub Activity, and Project Pulse
- **Daily** — System Monitor, Weather, and Project Pulse
- **Focus** — System Monitor only

Changing an individual widget switches the profile label to **Custom** without changing the dock.

## Design goals

- every visible module is optional
- no edits to `/usr/share/omarchy`
- install and remove through Omarchy's native plugin system
- theme-aware colours instead of hardcoded widget palettes
- safe fallback to stock Omarchy when disabled

## Planned modules

Clock, weather, sunrise/sunset, system monitor, GitHub, football, markets, projects, verse, calendar, now playing, and a configurable dock.

## Install (alpha)

Do not enable this yet on a daily-driver session. First clone and validate it:

```bash
omarchy plugin add https://github.com/thabopal/omarchy-nexushub-dashboard.git
omarchy plugin validate ~/.config/omarchy/plugins/dev.thabopal.nexushub-dashboard
```

The first runtime-tested release will include the exact enable command.

## License

MIT
