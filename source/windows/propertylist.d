module windows.propertylist;

import pixelperfectengine.concrete.window;
import sdlang;
import std.utf : toUTF32, toUTF8;
import std.conv : to;
import app;
import editorevents;
import core.internal.utf;

public class PropertyList : Window {
	ListView		listView_properties;
	SmallButton		removeParam, addParam;
	uint[]			propertyFlags;
	Tag				reference;
	enum PropertyFlags {
		init,
		Recognized		=	1<<0,
		Mandatory		=	1<<1,
		Constant		=	1<<2,
		IsMenu			=	1<<3,
	}
	public this(int x, int y, void delegate() onClose) {
		super(Box(0 + x, 0 + y, 129 + x, 213 + y), "Properties: NULL"d);
		this.onClose = onClose;
        listView_properties = new ListView(new ListViewHeader(16, [90, 240], ["Name"d, "Value"d]), null, 
				"listView_properties", Box.bySize(1, 17, 128, 180));
		addElement(listView_properties);
		listView_properties.onItemSelect = &listView_properties_onSelect;
		listView_properties.onTextInput = &listView_properties_onTextEdit;
		
		removeParam = new SmallButton("removeMaterialB", "removeMaterialA", "rem", Box.bySize(113, 198, 16, 16));
		removeParam.onMouseLClick = &button_trash_onClick;
		removeParam.state = ElementState.Disabled;
		addElement(removeParam);		
		
		addParam = new SmallButton("addMaterialB", "addMaterialA", "add", Box.bySize(113 - 16, 198, 16, 16));
		addParam.onMouseLClick = &button_addParam_onClick;
		addElement(addParam);
		
	}
	protected void button_trash_onClick(Event ev) {
		const int selectedItem = listView_properties.value;
		if (!(propertyFlags[selectedItem] & PropertyFlags.Mandatory) && selectedItem >= 0) {
			if (prg.selDoc !is null && reference !is null) {
				if (reference.namespace == "Object") {
					const string propertyName = listView_properties.selectedElement()[0].getText().toUTF8();
					prg.selDoc.events.addToTop(new ObjectPropertyRemoveEvent(propertyName, reference, prg.selDoc));
				}
			}
		}
	}
	protected void button_addParam_onClick(Event ev) {
		PopUpMenuElement[] menuList;
		menuList ~= new PopUpMenuElement("string", "String"d);
		menuList ~= new PopUpMenuElement("float", "Float"d);
		menuList ~= new PopUpMenuElement("int", "Integer"d);
		handler.addPopUpElement(new PopUpMenu(menuList, "valueMenu", &valueMenu_onSelect));
	}
	protected void valueMenu_onSelect(Event ev) {
		MenuEvent me = cast(MenuEvent)ev;
	}
	protected void listView_properties_onSelect(Event ev) {
		const int selectedItem = listView_properties.value;
		if ((propertyFlags[selectedItem] & PropertyFlags.Constant) || (propertyFlags[selectedItem] & PropertyFlags.Mandatory)) {
			removeParam.state = ElementState.Disabled;
		} else {
			removeParam.state = ElementState.Enabled;
		}
	}
	protected void listView_properties_onTextEdit(Event ev) {
		const int selectedItem = listView_properties.value;
		if (!(propertyFlags[selectedItem] & PropertyFlags.Constant) && selectedItem >= 0) {
			if (prg.selDoc !is null && reference !is null) {
				if (reference.namespace == "Object") {
					const string propertyName = listView_properties.selectedElement()[0].getText().toUTF8();
					switch (listView_properties.selectedElement()[1].textInputType) {
						case TextInputFieldType.Integer:
							break;
						case TextInputFieldType.Decimal:
							break;
						case TextInputFieldType.Text:
							break;
						default:
							break;
					}
				}
			}
		}
	}
	protected static TextInputFieldType getFieldType(Tag t) {
		if (t.values.length == 0) return TextInputFieldType.None;
		else if (t.values[0].peek!int() || t.values[0].peek!long()) return TextInputFieldType.Integer;
		else if (t.values[0].peek!double() || t.values[0].peek!float()) return TextInputFieldType.Decimal;
		else if (t.values[0].peek!string()) return TextInputFieldType.Text;
		else return TextInputFieldType.None;
	}
	protected static dstring getFieldValue(Tag t) {
		if (t.values.length == 0) return null;
		else if (t.values[0].peek!int()) return to!dstring(t.values[0].get!int);
		else if (t.values[0].peek!long()) return to!dstring(t.values[0].get!long);
		else if (t.values[0].peek!double()) return to!dstring(t.values[0].get!double);
		else if (t.values[0].peek!float()) return to!dstring(t.values[0].get!float);
		else if (t.values[0].peek!string()) return toUTF32(t.values[0].get!string);
		else return null;
	}
	public void updatePropertyList_layer(Tag t) {
		reference = t;
		propertyFlags.length = 0;
		listView_properties.clear();
		try {
			auto chrFrmt_recog = getStyleSheet().getChrFormatting("property-recognized");
			//auto chrFrmt_mand = getStyleSheet().getChrFormatting("property-mandatory");
			auto chrFrmt_const = getStyleSheet().getChrFormatting("property-constant");
			auto chrFrmt_def = getStyleSheet().getChrFormatting("default");
			switch (t.name) {	//Create the constants
				case "Tile", "TransformableTile":
					listView_properties ~= new ListViewItem(16, 
							[ListViewItem.Field(new Text("tileW"d, chrFrmt_const), null),
							ListViewItem.Field(new Text(to!dstring(t.values[2]), chrFrmt_def), null)]);
					propertyFlags ~= PropertyFlags.Constant;
					listView_properties ~= new ListViewItem(16, 
							[ListViewItem.Field(new Text("tileH"d, chrFrmt_const), null),
							ListViewItem.Field(new Text(to!dstring(t.values[3]), chrFrmt_def), null)]);
					propertyFlags ~= PropertyFlags.Constant;
					break;
				default:
					break;
			}
			foreach (Tag t0 ; t.tags) {
				switch (t0.name) {
					case "RenderingMode"://Treat `RenderingMode` as a menu opener
						listView_properties ~= new ListViewItem(16, 
								[ListViewItem.Field(new Text(toUTF32(t0.name), chrFrmt_recog), null),
								ListViewItem.Field(new Text("[...]"d, chrFrmt_def), null)]);
						propertyFlags ~= PropertyFlags.Recognized | PropertyFlags.IsMenu;
						break;
					case "ScrollRateX", "ScrollRateY", "TileFlagName0", "TileFlagName1", "TileFlagName2", "TileFlagName3", 
							"TileFlagName4", "TileFlagName5"://Recognized layer properties
						listView_properties ~= new ListViewItem(16, 
								[ListViewItem.Field(new Text(toUTF32(t0.name), chrFrmt_recog), null),
								ListViewItem.Field(new Text(getFieldValue(t0), chrFrmt_def), null, getFieldType(t0))]);
						propertyFlags ~= PropertyFlags.Recognized;
						break;
					default:
						listView_properties ~= new ListViewItem(16, 
								[ListViewItem.Field(new Text(toUTF32(t0.name), chrFrmt_def), null),
								ListViewItem.Field(new Text(getFieldValue(t0), chrFrmt_def), null, getFieldType(t0))]);
						propertyFlags ~= 0;
						break;
				}
			}
		} catch (Exception ex) {
			
		}
	}
	public void updatePropertyList_obj(Tag t) {
		reference = t;
		propertyFlags.length = 0;
		listView_properties.clear();
		try {
			//auto chrFrmt_recog = getStyleSheet().getChrFormatting("property-recognized");
			auto chrFrmt_mand = getStyleSheet().getChrFormatting("property-mandatory");
			//auto chrFrmt_const = getStyleSheet().getChrFormatting("property-constant");
			auto chrFrmt_def = getStyleSheet().getChrFormatting("default");
			switch (t.name) {
				case "Box":
					listView_properties ~= new ListViewItem(16, 
							[ListViewItem.Field(new Text("left"d, chrFrmt_mand), null),
							ListViewItem.Field(new Text(to!dstring(t.values[2]), chrFrmt_def), null, TextInputFieldType.Integer)]);
					propertyFlags ~= PropertyFlags.Mandatory;
					listView_properties ~= new ListViewItem(16, 
							[ListViewItem.Field(new Text("top"d, chrFrmt_mand), null),
							ListViewItem.Field(new Text(to!dstring(t.values[3]), chrFrmt_def), null, TextInputFieldType.Integer)]);
					propertyFlags ~= PropertyFlags.Mandatory;
					listView_properties ~= new ListViewItem(16, 
							[ListViewItem.Field(new Text("bottom"d, chrFrmt_mand), null),
							ListViewItem.Field(new Text(to!dstring(t.values[4]), chrFrmt_def), null, TextInputFieldType.Integer)]);
					propertyFlags ~= PropertyFlags.Mandatory;
					listView_properties ~= new ListViewItem(16, 
							[ListViewItem.Field(new Text("right"d, chrFrmt_mand), null),
							ListViewItem.Field(new Text(to!dstring(t.values[5]), chrFrmt_def), null, TextInputFieldType.Integer)]);
					propertyFlags ~= PropertyFlags.Mandatory;
					break;
				case "Sprite":
					listView_properties ~= new ListViewItem(16, 
							[ListViewItem.Field(new Text("posX"d, chrFrmt_mand), null),
							ListViewItem.Field(new Text(to!dstring(t.values[3]), chrFrmt_def), null, TextInputFieldType.Integer)]);
					propertyFlags ~= PropertyFlags.Mandatory;
					listView_properties ~= new ListViewItem(16, 
							[ListViewItem.Field(new Text("posY"d, chrFrmt_mand), null),
							ListViewItem.Field(new Text(to!dstring(t.values[4]), chrFrmt_def), null, TextInputFieldType.Integer)]);
					propertyFlags ~= PropertyFlags.Mandatory;
					listView_properties ~= new ListViewItem(16, 
							[ListViewItem.Field(new Text("scaleHoriz"d, chrFrmt_mand), null),
							ListViewItem.Field(new Text(to!dstring(t.getAttribute!int("scaleHoriz", 1024)), chrFrmt_def), null, 
							TextInputFieldType.Integer)]);
					propertyFlags ~= PropertyFlags.Mandatory;
					listView_properties ~= new ListViewItem(16, 
							[ListViewItem.Field(new Text("scaleVert"d, chrFrmt_mand), null),
							ListViewItem.Field(new Text(to!dstring(t.getAttribute!int("scaleVert", 1024)), chrFrmt_def), null, 
							TextInputFieldType.Integer)]);
					propertyFlags ~= PropertyFlags.Mandatory;
					listView_properties ~= new ListViewItem(16, 
							[ListViewItem.Field(new Text("masterAlpha"d, chrFrmt_mand), null),
							ListViewItem.Field(new Text(to!dstring(t.getAttribute!int("masterAlpha", 255)), chrFrmt_def), null, 
							TextInputFieldType.Integer)]);
					propertyFlags ~= PropertyFlags.Mandatory;
					listView_properties ~= new ListViewItem(16, 
							[ListViewItem.Field(new Text("palSel"d, chrFrmt_mand), null),
							ListViewItem.Field(new Text(to!dstring(t.getAttribute!int("palSel", 0)), chrFrmt_def), null, 
							TextInputFieldType.Integer)]);
					propertyFlags ~= PropertyFlags.Mandatory;
					break;
				default:
					break;
			}
		} catch (Exception ex) {

		}
	}
}