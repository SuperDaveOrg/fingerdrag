# fingerdrag

macOS-style three- and four-finger drag for Linux touchpads, on desktops that
do not offer the setting.

Rest three or four fingers on the touchpad and move them: the pointer drags as
if the left button were held. Lift, reposition, and continue within a short
moment to keep dragging.

## Do you need this?

libinput has implemented the gesture since 1.28. It is off by default, and the
compositor has to turn it on. Run the doctor to see where your system stands:

    ./fingerdrag doctor

| Desktop | Status |
|---------|--------|
| Hyprland, sway, labwc | Native config option. You do not need fingerdrag. |
| KDE Plasma, up to 6.8 | No setting. **fingerdrag fills this gap.** |
| KDE Plasma 6.9 and later | Setting planned in System Settings, see [upstream status](docs/UPSTREAM.md). |
| Any X11 desktop: Cinnamon, Xfce, MATE and others | The X driver has no drag option. **fingerdrag is the only route.** |
| GNOME on Wayland, up to 50 | No setting. fingerdrag should fill this gap; not yet tried on hardware. |
| Others | Not verified yet. `doctor` reports what it finds. |

## Install

Debian, Ubuntu, Linux Mint and other systems based on them:

    git clone https://github.com/SuperDaveOrg/fingerdrag
    cd fingerdrag
    ./fingerdrag install

Then log out and back in. You get three-finger drag, and the install says so
when it finishes. For four fingers instead:

    ./fingerdrag install --fingers 4

On libinput 1.31 and later, three-finger drag takes over the three-finger
tap, which is middle click by default. Four-finger drag keeps it.

### Older releases: Ubuntu 24.04, Linux Mint 22, Debian 12

These ship a libinput older than 1.28, which has no drag support at all.
fingerdrag can build the libinput of the next release of your distribution
instead, from that release's signed source package:

    ./fingerdrag install --backport

| Your system | Source used |
|-------------|-------------|
| Ubuntu 24.04, Linux Mint 22 and other Ubuntu based systems | Ubuntu 26.04 |
| Debian 12 and systems based on it | Debian 13 |

Know what you are choosing. A backport replaces the system's libinput with a
much newer one. Touchpad behaviour such as acceleration and palm detection
may change, and libinput updates from your distribution stop applying.
`fingerdrag uninstall` puts the original packages back.

## What it does

1. Downloads the libinput source package, using your existing repository
   signatures. Your apt configuration is not modified.
2. Applies a small [patch series](patches/) and builds the packages, as your
   own user. Root is needed only for the final `dpkg -i`.
3. Saves the stock packages for rollback.
4. Installs an apt hook that tells you when a system upgrade has replaced the
   patched build. Nothing breaks when that happens, the gesture just stops
   working, which is easy to miss. Run `fingerdrag install` again to restore;
   it remembers `--fingers` and `--backport`.

Remove everything and return to stock packages with:

    fingerdrag uninstall

## Changing the finger count

`fingerdrag install --fingers 3|4` compiles the finger count in. This works on
every desktop, and is the only way on X11, where the X server is started by
the display manager and never sees per-user settings.

On Wayland there is a per-user shortcut that needs no rebuild:

    fingerdrag set 3|4|off

It writes `LIBINPUT_DRAG_3FG_DEFAULT` to `~/.config/environment.d`, which the
patched libinput reads when the session starts.

## The patches

- **Default on.** `tp_3fg_drag_default()` returns multi-finger drag instead
  of disabled. The finger count is a compiled-in default that the
  `LIBINPUT_DRAG_3FG_DEFAULT` environment variable can override.
- **Responsive start with tap-to-click** (libinput 1.31 and later). Upstream
  only takes the immediate finger-down path into the drag when tapping is
  disabled. With tapping enabled, quick drags are usually read as swipes.
  The patch gives the drag finger count to the drag.

## Tested

| System | libinput | Mode | Result |
|--------|----------|------|--------|
| TUXEDO OS 24.04, Plasma 6.6 Wayland, real hardware | 1.31.1 | stock | Daily use |
| Linux Mint 22, Cinnamon on X11, ThinkPad Z13 Gen 2, real hardware | 1.25 to 1.31.1 | backport | Three-finger drag works |
| Ubuntu 26.04, container | 1.31.1 | stock | Full cycle |
| Debian 13, container | 1.28.1 | stock | Full cycle |
| Linux Mint 22, container | 1.25 to 1.31.1 | backport | Full cycle |
| Ubuntu 24.04, container | 1.25 to 1.31.1 | backport | Full cycle |
| Debian 12, container | 1.22 to 1.28.1 | backport | Full cycle |

"Full cycle" is `tests/run.sh`: build, install, rebuild, upgrade warning,
restore, uninstall. Containers have no touchpad, so they prove packaging, not
gesture behaviour. Reports from real hardware are welcome.

## Limitations

- Debian and Ubuntu family only for now. Arch users have the
  `libinput-three-finger-drag` AUR package.
- Systems with libinput installed for several architectures are refused.
- Desktop gesture daemons such as touchegg see the same change: slow swipes
  with the drag finger count become drags.
- Where the compositor exposes the setting, `doctor` says so and you should
  use that instead.

## License

MIT. The patches modify libinput, which is also MIT licensed.
