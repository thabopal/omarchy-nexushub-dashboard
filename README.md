# NexusHub Dashboard for Omarchy

A modular Quickshell dashboard for Omarchy with a dock, personal widgets, profiles, and a master enable/disable path.

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
