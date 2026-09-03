# NexusHub Dashboard for Omarchy

A modular Quickshell dashboard for Omarchy with a dock, personal widgets, and persistent profiles.

## Widget controls and profiles

System Monitor and Weather live directly on the desktop as click-through, glanceable cards. GitHub Activity, Project Pulse, and the controls remain in the compact Control Center. Use the controls card to show or hide every module; changes persist through Omarchy's bar settings.

Project Pulse scans visible folders under your home directory to a bounded depth and shows the three most recently committed Git repositories. Each entry includes its branch, clean/dirty state, latest commit, commit age, and upstream ahead/behind state. The scan is read-only and refreshes every two minutes while the card is enabled.

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
