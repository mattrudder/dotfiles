# Apollo display scripts

PowerShell scripts that snapshot the host's display configuration on stream connect, isolate the per-client virtual display Apollo creates, and restore the previous layout on disconnect.

## Files

- `Connect-ApolloDisplay.ps1` — saves current `Get-DisplayConfig` to `state/display-state.xml`, polls for the named virtual display (default 10s), then disables all other active displays and sets the virtual one as primary.
- `Disconnect-ApolloDisplay.ps1` — restores `state/display-state.xml` via `Use-DisplayConfig` and deletes the snapshot.
- `state/` — runtime state (XML snapshot + `apollo.log`). Contents are gitignored.

Both scripts depend on the `DisplayConfig` module vendored at `pwsh/modules/DisplayConfig/5.2.1/`. They prefer the system-installed module if `PSModulePath` resolves it, otherwise they fall back to the vendored copy.

The virtual display is matched against the `DisplayName` property returned by `Get-DisplayInfo` (Apollo names the virtual display after the connecting client, e.g. `hex-tablet`).

## Apollo wiring

These scripts are wired through Apollo's [Client Commands](https://github.com/ClassicOldSong/Apollo/wiki/Client-Commands) feature (the `do`/`undo` pair that fires on client connect/disconnect), **not** the standard Sunshine `prep-cmd`. Two requirements:

1. **Per-app gate must be on.** The target app needs `"allow-client-commands": true` in `apps.json` (UI toggle: *Allow client commands* / *Allow client prepare commands* on the app's settings page). Without this, Apollo silently skips the commands. The default `Desktop` entry ships with it set to `false`.
2. **The commands themselves are configured in the app's Client Commands section** in the Web UI (https://localhost:47990 → Applications → *app* → Client Commands), or directly in `apps.json`.

Apollo's connect-time client name is exposed via `${APOLLO_CLIENT_NAME}` (the project renamed the Sunshine `${SUNSHINE_*}` variables to `${APOLLO_*}`).

In the Web UI, set:

- **Do Command:**
  ```
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\matt\.dotfiles\apollo\Connect-ApolloDisplay.ps1" -VirtualDisplayName "${APOLLO_CLIENT_NAME}"
  ```
- **Undo Command:**
  ```
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\matt\.dotfiles\apollo\Disconnect-ApolloDisplay.ps1"
  ```
- **Run as administrator:** off — `DisplayConfig` works fine in the user session, and elevation puts the command in a session that can't see the displays.

Equivalent `apps.json` shape (Apollo writes this when you save in the UI):

```json
{
  "name": "Desktop",
  "allow-client-commands": true,
  "prep-cmd": [
    {
      "do":   "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"C:\\Users\\matt\\.dotfiles\\apollo\\Connect-ApolloDisplay.ps1\" -VirtualDisplayName \"${APOLLO_CLIENT_NAME}\"",
      "undo": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"C:\\Users\\matt\\.dotfiles\\apollo\\Disconnect-ApolloDisplay.ps1\"",
      "elevated": false
    }
  ],
  "uuid": "..."
}
```

## Manual usage

```powershell
# Stream connect (host-side)
.\Connect-ApolloDisplay.ps1 -VirtualDisplayName "hex-tablet"

# Stream disconnect (host-side)
.\Disconnect-ApolloDisplay.ps1
```

If `Connect` fails after writing the state file (e.g., the virtual display never appeared), the snapshot is left on disk — run `Disconnect` manually to roll back.
