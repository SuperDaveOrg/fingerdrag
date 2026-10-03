# Upstream status

Checked on 2026-10-03. fingerdrag exists because of gaps upstream; the goal is
to close them and make this tool unnecessary.

## KWin and Plasma: already in progress, by someone else

- [kwin!9598](https://invent.kde.org/plasma/kwin/-/merge_requests/9598)
  "Expose multi-finger touchpad drag configuration", opened 2026-07-19 by
  Leo Chiu (pastleo). Milestone Plasma 6.9. Under active review by Jakob
  Petsovits, who pushed a fixup on 2026-10-02 renaming the D-Bus properties
  to `multiFingerDrag`, `defaultMultiFingerDrag` and
  `multiFingerDragMaxFingerCount`.
- [plasma-desktop!3894](https://invent.kde.org/plasma/plasma-desktop/-/merge_requests/3894)
  adds the Touchpad settings page controls. Same author, same milestone.
- Tracking bug: [433923](https://bugs.kde.org/show_bug.cgi?id=433923).

**Do not open a competing merge request.** The `multi-finger-drag` branch in
`~/projects/kwin` is superseded. The local `mr-9598` branch there predates the
property rename and needs a fresh fetch. Useful contributions here:

1. Build the branch and test it on real hardware, then report results on the
   merge request. Reviewers value independent hardware testing.
2. Report the tap-to-click interaction described below, since Plasma users
   will hit it as soon as the setting ships.

## libinput: one real gap left

State of `main` (1.32.0):

- The default is still disabled. That is by design and will not change; the
  default-on patch here is not for upstream.
- The finger-down entry into `GESTURE_STATE_3FG_DRAG_OR_SWIPE_START` is still
  gated on `!tp->tap.enabled` (`src/evdev-mt-touchpad-gestures.c`). With
  tap-to-click on, a drag can only start through the motion path.
- 1.32 times the fast-swipe test from initial contact (commit fdd43a4f),
  which helps when fingers rest before moving. Not in any 1.31.x release.
- Upstream's own tests already cover drag with tapping enabled, for slow
  starts. The gap is quick starts.
- Open issue [#1332](https://gitlab.freedesktop.org/libinput/libinput/-/issues/1332)
  "Three-finger drag doesn't work for fast drags" describes the same symptom
  from another user.

A patch for this already exists, uncommitted, on the
`3fg-drag-4fg-with-tapping` branch in `~/projects/libinput`. The reasoning and
the proposed commit message are in `~/projects/libinput-mr-notes.md`. It takes
the policy approach: enabling the drag for a finger count claims that finger
count, so the finger-down path is taken with tapping on and `tp_tap_notify()`
stops sending a button for it. Hardware testing showed the gate hurts at
three fingers as much as at four, which is why it is not a four-finger
special case.

It is the same change as `patches/1.31/0002` here, plus updated litest cases.

Before opening the merge request:

- Run the test suite, which needs root for uinput:
  `sudo ./builddir/libinput-test-suite --filter-test='*3fg_drag*'` and
  `--filter-test='*tap*'`.
- Rebase onto current `main` (1.32.0). The branch base already contains the
  1.32 timing fix, so the hardware finding stands with that fix present.
- Capture a `libinput record` of a failing quick drag with tapping enabled.
- Reference issue #1332 in the description.

Expected review topic: losing the three-finger tap. Fallbacks to offer are a
separate config option, or limiting the change to four fingers, where no tap
behaviour changes at all.

## GNOME: stalled, and unclaimed

Checked 2026-10-03. mutter has no call to the drag API in `main` or in the
GNOME 50 branch, so GNOME on Wayland has no setting either.

- [gsettings-desktop-schemas!101](https://gitlab.gnome.org/GNOME/gsettings-desktop-schemas/-/merge_requests/101)
  "Add a key for touchpad 3fg dragging": a draft by Peter Hutterer, the
  libinput maintainer, opened 2025-02-24 and untouched since 2025-05-02.
- [mutter#4589](https://gitlab.gnome.org/GNOME/mutter/-/issues/4589) "Add
  opt-in option to enable libinput's three-fingers drag", opened 2026-02-03.
- [mutter!1021](https://gitlab.gnome.org/GNOME/mutter/-/merge_requests/1021)
  from 2020 predates libinput's implementation and is obsolete.

Unlike KWin, nobody is actively carrying this. The work is a schema key, a
few lines in mutter's input settings, and a Settings toggle. Expect design
pushback: GNOME uses three-finger swipes for the overview and workspaces.

## X11: no upstream path

The `xf86-input-libinput` driver has no option for multi-finger drag, in the
1.5.0 release or in its git head (checked 2026-10-03, last commit 2025-10-23).
Xorg is in maintenance mode, so this is unlikely to change. A small merge
request adding the property would be a real contribution, but distributions
would take years to ship it. For Cinnamon, Xfce and MATE users, changing
libinput's default stays the only way.

Accounts needed: gitlab.freedesktop.org (new accounts must request fork
access through a ticket) and a KDE Identity for invent.kde.org.
