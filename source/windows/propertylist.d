module windows.propertylist;

import pixelperfectengine.concrete.window;
import sdlang;

public class PropertyList : Window {
	ListView		listView_properties;
	SmallButton		removeParam, addParam;
	public this(int x, int y, void delegate() onClose) {
		super(Box(0 + x, 0 + y, 129 + x, 213 + y), "Properties: NULL"d);
		this.onClose = onClose;
        listView_properties = new ListView(new ListViewHeader(16, [40, 120], ["ID"d, "Name"d]), null, 
				"listView_properties", Box.bySize(1, 17, 128, 180));
		addElement(listView_properties);
		
		removeParam = new SmallButton("removeMaterialB", "removeMaterialA", "rem", Box.bySize(113, 198, 16, 16));
		removeParam.onMouseLClick = &button_trash_onClick;
		removeParam.state = ElementState.Disabled;
		addElement(removeParam);		
		
		addParam = new SmallButton("addMaterialB", "addMaterialA", "add", Box(113 - 16, 198, 16, 16));
		addParam.onMouseLClick = &button_addParam_onClick;
		addElement(addParam);
		
	}
	protected void button_trash_onClick(Event ev) {

	}
	protected void button_addParam_onClick(Event ev) {
		
	}
	public void updatePropertyList_layer(Tag t) {

	}
	public void updatePropertyList_obj(Tag t) {
		
	}
}