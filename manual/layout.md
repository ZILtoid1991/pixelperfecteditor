```
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
|Menubar                                                                                                              |
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
******************* *******************
|Layers           | |Properties       |   ***************************************************
|                 | |                 |   |Viewport                                         |
|                 | |                 |   |                                                 |
|                 | |                 |   |                                                 |
******************* *******************   |                                                 |
******************* *******************   |                                                 |
|Materials        | |Objects          |   |                                                 |
|                 | |                 |   |                                                 |
|                 | |                 |   |                                                 |
|                 | |                 |   ***************************************************
******************* *******************
```

# Menubar

# Windows

## Layers

This window lists all the available layers, makes it possible to hide or only show the selected layer, and managing 
layers themselves (adding, deleting, setting priorities, exporting data). The cogwheel button allows one to edit some
more advanced properties of the layer, such as shared materials.

## Properties

Displays the properties of the last selected item from objects or layers. Every "system" property (properties that are 
mandatory and cannot be deleted) that are editable are visualized by green color, and constants (tile sizes, etc) are 
purple. Recognized custom properties are light-blue.

Color notation is editable within the configuration.

## Materials

Displays the available materials of the layer, allows the management of said materials, while also displaying some 
options about placement (horizontal and vertical mirroring, insert/overwrite, palette selection, flags, etc.).

Note that it cannot delete "shared" materials directly, for that one needs to enter the advanced options menu (the 
cogwheel button) of the layer.

## Objects

Lists all the objects placed on the map, allows the arming of placing new objects