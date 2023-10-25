module windows.objectlist;

import pixelperfectengine.concrete.window;
import pixelperfectengine.map.mapformat;

import app;
import document;
import editorevents;
import std.conv : to;
import std.utf : toUTF32, toUTF8;

import windows.colorpicker;

public class ObjectList : Window {
    ListView		listView_objects;
    SmallButton[]   buttons;
    CheckBox        checkBox_Solo;
	Color			selectedColor;
    public this(int x, int y, void delegate() onClose) @trusted {
        super(Box(x, y, x + 129, y + 249), "Objects"d);
        this.onClose = onClose;
        listView_objects = new ListView(new ListViewHeader(16, [40, 120], ["ID"d, "Name"d]), null, "listView_objects", 
                Box(1, 17, 128, 215));
        listView_objects.editEnable = true;
        listView_objects.onItemSelect = &onItemSelect;
        listView_objects.onTextInput = &onItemRename;
        addElement(listView_objects);
        {//0
			SmallButton sb = new SmallButton("trashButtonB", "trashButtonA", "trash", Box(113, 233, 129, 248));
			sb.onMouseLClick = &button_trash_onClick;
			buttons ~= sb;
		}
		{//1
			SmallButton sb = new SmallButton("settingsButtonB", "settingsButtonA", "editObj", Box(97, 233, 113, 248));
			//sb.onMouseLClickRel = &button_trash_onClick;
			buttons ~= sb;
		}
        {//2
			SmallButton sb = new SmallButton("addBoxObjectB", "addBoxObjectA", "addBoxObject",
					Box(1, 217, 16, 232));
			sb.onMouseLClick = &button_addBoxObject;
			buttons ~= sb;
		}
        {//3
			SmallButton sb = new SmallButton("addPolylineObjectB", "addPolylineObjectA", "addPolylineObject",
					Box(17, 217, 32, 232));
			//sb.onMouseLClick = &button_newTileLayer_onClick;
			buttons ~= sb;
		}
        {//4
			SmallButton sb = new SmallButton("addCompositeTileObjectB", "addCompositeTileObjectA", "addCompositeTileObject",
					Box(33, 217, 48, 232));
			//sb.state = ElementState.Disabled;
			//sb.onMouseLClick = &button_newTileLayer_onClick;
			buttons ~= sb;
		}
        {//5
			SmallButton sb = new SmallButton("addSpriteObjectB", "addSpriteObjectA", "addSpriteObject",
					Box(49, 217, 64, 232));
			sb.onMouseLClick = &button_addSpriteObject;
			buttons ~= sb;
		}
        {//6
			SmallButton sb = new SmallButton("drawCompositeTileObjectB", "drawCompositeTileObjectA", "drawCompositeTileObject",
					Box(65, 217, 80, 232));
			//sb.state = ElementState.Disabled;
			//sb.onMouseLClick = &button_newTileLayer_onClick;
			buttons ~= sb;
		}
        {//7
			SmallButton sb = new SmallButton("colorPickerB", "colorPickerA", "colorPicker", Box(81, 233, 96, 248));
			sb.onMouseLClick = &button_colorPicker;
			buttons ~= sb;
		}
		foreach (SmallButton key; buttons) {
			addElement(key);
		}
		buttons[3].state = ElementState.Disabled;
		buttons[4].state = ElementState.Disabled;
		buttons[6].state = ElementState.Disabled;
		selectedColor = Color(0xff, 0xff, 0xff, 0xFF);
    }
    protected void onItemSelect(Event ev) {
		if (prg.selDoc !is null && listView_objects.value != -1) {
			MapDocument md = prg.selDoc;
			try {
				md.selObject = to!int(listView_objects[listView_objects.value][0].getText);
				md.updatePropertyList_obj();
			} catch (Exception e) {

			}
		}
    }
    protected void onItemRename(Event ev) {
        if (prg.selDoc !is null) {
			CellEditEvent cev = cast(CellEditEvent)ev;
			MapDocument md = prg.selDoc;
			md.events.addToTop(new ObjectRemaneEvent(md, md.selectedLayer, md.selObject, toUTF8(cev.text.toDString)));
		}
    }
    protected void button_trash_onClick(Event ev) {
		if (prg.selDoc !is null) {
			MapDocument md = prg.selDoc;
			md.events.addToTop(new ObjectRemovalEvent(md, md.selectedLayer, md.selObject));
		}
    }
	protected void button_colorPicker(Event ev) {
		handler.addPopUpElement(new ColorPicker(&colorPicker_onSelect, selectedColor));
	}
	protected void button_addBoxObject(Event ev) {
		if (prg.selDoc !is null) {
			MapDocument md = prg.selDoc;
			md.armBoxPlacement(selectedColor);
		}
	}
	protected void button_addPolylineObject(Event ev) {
		if (prg.selDoc !is null) {

		}
	}
	protected void button_addSpriteObject(Event ev) {
		if (prg.selDoc !is null) {
			MapDocument md = prg.selDoc;
			md.armSpritePlacement();
		}
	}
	protected void colorPicker_onSelect(Color c) {
		selectedColor = c;
	}
	public void updateObjectList(MapObjectRange)(MapObjectRange objects) {
		listView_objects.clear();
		foreach (MapObject key; objects) {
			listView_objects ~= new ListViewItem(16, [to!dstring(key.pID), toUTF32(key.name)], 
					[TextInputFieldType.None, TextInputFieldType.Text]);
		}
	}
}