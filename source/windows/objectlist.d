module windows.objectlist;

import pixelperfectengine.concrete.window;

import app;

public class ObjectList : Window {
    ListView		listView_objects;
    SmallButton[]   buttons;
    CheckBox        checkBox_Solo;
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
			SmallButton sb = new SmallButton("trashButtonB", "trashButtonA", "trash", Box(113, 197, 129, 213));
			sb.onMouseLClick = &button_trash_onClick;
			buttons ~= sb;
		}
		{//1
			SmallButton sb = new SmallButton("settingsButtonB", "settingsButtonA", "editObj", Box(97, 197, 113, 213));
			//sb.onMouseLClickRel = &button_trash_onClick;
			buttons ~= sb;
		}
        {//2
			SmallButton sb = new SmallButton("addBoxObjectB", "addBoxObjectA", "addBoxObject",
					Box(1, 181, 16, 196));
			//sb.onMouseLClick = &button_newTileLayer_onClick;
			buttons ~= sb;
		}
        {//3
			SmallButton sb = new SmallButton("addPolylineObjectB", "addPolylineObjectA", "addPolylineObject",
					Box(17, 181, 32, 196));
			//sb.onMouseLClick = &button_newTileLayer_onClick;
			buttons ~= sb;
		}
        {//4
			SmallButton sb = new SmallButton("addCompositeTileObjectB", "addCompositeTileObjectA", "addCompositeTileObject",
					Box(33, 181, 48, 196));
			//sb.onMouseLClick = &button_newTileLayer_onClick;
			buttons ~= sb;
		}
        {//5
			SmallButton sb = new SmallButton("addSpriteObjectB", "addSpriteObjectA", "addSpriteObject",
					Box(49, 181, 64, 196));
			//sb.onMouseLClick = &button_newTileLayer_onClick;
			buttons ~= sb;
		}
        {//6
			SmallButton sb = new SmallButton("drawCompositeTileObjectB", "drawCompositeTileObjectA", "drawCompositeTileObject",
					Box(65, 181, 80, 196));
			//sb.onMouseLClick = &button_newTileLayer_onClick;
			buttons ~= sb;
		}
        {//7
			SmallButton sb = new SmallButton("colorPickerB", "colorPickerA", "colorPicker", Box(81, 197, 96, 213));
			//sb.onMouseLClickRel = &button_trash_onClick;
			buttons ~= sb;
		}
    }
    protected void onItemSelect(Event ev) {

    }
    protected void onItemRename(Event ev) {
        
    }
    protected void button_trash_onClick(Event ev) {

    }
}