# Radio Atlas (Ryoku port)

Live radio on a rotatable globe from the QS Bar. Click a station signal to play
it, or click a country to browse its stations. Playback runs in `mpv`, with an
MPRIS bridge so the desktop media controls work.

Ported from `akshar.radio-atlas` 0.1.9 (Omarchy bar widget, by Akshar Patel) to
the Ryoku plugin contract. The player, the directory client, the sandbox and the
MPRIS bridge are the upstream code; the only changes are the runtime paths and
the plugin/host API surface.

## What it does

- **Widget** (`content/Widget.qml`): a globe glyph with the playing station or
  the volume. Left click opens the globe, middle click tunes a random station,
  right click stops or resumes, the wheel changes volume.
- **Panel** (`content/Panel.qml`): the globe — drag to spin, wheel to zoom,
  click a signal to play, click a country to browse. Below it: search, the
  station list, favourites and recent, the player (play/pause/stop/next/previous,
  volume, mute), and an audio-output picker.
- **Service** (`service/Main.qml`): the saved state (favourites, history,
  volume, audio output) and the station directory.

## What it runs, reads, writes

- Runs: `bin/radio-fetch` (the Radio Browser directory), `bin/radio-player`
  (mpv plus its MPRIS bridge), `bin/radio-state` (saved state),
  `bin/radio-session` + `bin/radio-sandbox` + `bin/radio-mpris` + `bin/radio-proxy`
  (the player's network sandbox and media bridge), `bin/radio-status.lua` (mpv's
  own status script), and `bin/radio-favicon` (station logos). Every command is
  declared in `dependencies.commands`.
- Reads: nothing outside its own tree except the station directory over HTTPS.
- Writes: its own state dir (`$RADIO_ATLAS_STATE_DIR`, default
  `$XDG_STATE_HOME/ryoku/plugins/radio-atlas`, i.e. the host's
  `pluginApi.stateDir`) and its runtime dir
  (`$RADIO_ATLAS_RUNTIME_DIR`, default `$XDG_RUNTIME_DIR/ryoku-radio-atlas`),
  plus the country and logo caches under
  `$XDG_CACHE_HOME/ryoku/plugins/radio-atlas`.
- No sudo, doas or su. No pkexec. No downloaded code is executed.

## Capabilities

- **Network** (`capabilities.network`): the hosts that appear as literals in this
  tree are declared — `all.api.radio-browser.info`, `api.radio-browser.info` and
  the sandbox's own `127.0.0.1:18765` bridge. Two kinds of traffic cannot be
  declared as literals, because those hosts come from the directory rather than
  from this plugin; they are bounded instead of enumerated:
  - **station streams**: playback connects to whatever `url_resolved` the
    directory returned for the chosen station;
  - **station artwork**: `bin/radio-favicon` fetches whatever `favicon` the
    directory returned for it.

  Both leave through `bin/radio-proxy`, which resolves the destination itself,
  refuses private, loopback, link-local and otherwise non-public addresses (and
  the synthetic `FAKE_IP_RANGE` unless the "benchmark IP" setting is on), pins
  the address it just validated, and relays only to that address — so DNS cannot
  change between the check and the connect, and redirects are re-checked the
  same way. The player never touches the network directly: it runs in a network
  namespace whose only route out is that proxy, and the QML in this plugin makes
  no network calls at all.
- **Audio**: playback through the PipeWire sink you choose, including RAOP
  (AirPlay) sinks.

## Removing it

Stop the player first, then remove the plugin:

```
radio-atlas stop          # or: ~/.local/share/ryoku/plugins/radio-atlas/bin/radio-player stop
ryoku plugin remove radio-atlas
```

Favourites, history and volume live in
`~/.local/state/ryoku/plugins/radio-atlas/state.json` and come back on a
reinstall; delete that file to clear them. The country and logo caches are under
`~/.cache/ryoku/plugins/radio-atlas/`.
