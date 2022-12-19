module windows.propertylist;

import pixelperfectengine.concrete.window;

public class PropertyList : Window {
    ListView		listView_properties;
    SmallButton[]   buttons;
    public this(int x, int y, void delegate() onClose) {
		super(Box(0 + x, 0 + y, 129 + x, 213 + y), "Layers"d);
    }
}