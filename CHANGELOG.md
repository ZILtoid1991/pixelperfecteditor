# v0.11.0-alpha

## New features

### Object handling

The editor can handle two kind of objects:

* Box objects, to mark collision events, etc.
* Sprite objects, only available on dedicated sprite layers.

Objects are notated on each layer individually.

### Property handling

The editor can assign and edit properties of objects and layers, which can be read by the target applications.

### Language files

Language file support has been added. There are blindspots in what it's currently applied for.

## Bug fixes

Usually bugs that were present in prior engine versions. (Curr.: 0.11.0-alpha.4)

# v0.10.1

## New features

### AngelCode BMfont editor

The program now can manually create and edit BMfont files. There's currently no font generation tool planned, but it might be useful when creating fonts by hand that doesn't have uniform width.

### Grid

A grid can now be viewed during the editing process on tile layers.

## Bugfixes

The engine version is now updated to v0.10.0-beta.7, this brings engine-side fixes, like ListView editing and speed issues, etc.

# v0.10.0

## New features

## General bugfixes

* Various bugfixes on engine-side, like fixing scrollbar behavior and Listview issues.
* Fixed importing 24 or 32 bit images. It should no longer try to import palettes from such files.