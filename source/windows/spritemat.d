module windows.spritemat;

import pixelperfectengine.concrete.window;
import document;
import editorevents;
import std.conv : to;
import std.utf;

public class SprMatCreate : Window {
	Label label_path;
	TextBox textBox_path;
	Label label_sName;
	TextBox textBox_sName;
	Label label_sID;
	TextBox textBox_sID;
	Button button_browse;
	RadioButton radioButton_single;
	RadioButton radioButton_multi;
	RadioButtonGroup spriteAm;
	ListView listView_sprSheet;
	Button button_create;
	CheckBox checkBox_impPal;
	Label label_palShift;
	TextBox textBox_palShift;
	Label label_palOffset;
	TextBox textBox_palOffset;
	SmallButton smallButton_add;
	SmallButton smallButton_remove;
	MapDocument md;
	int layerID;
	bool multi;
	public this(MapDocument md, int layerID) {
		super(Box(0, 0, 295, 330), "Create New Sprite Material");
		this.md = md;
		this.layerID = layerID;
		label_path = new Label("File source:"d, "label0", Box(5, 20, 70, 40));
		textBox_path = new TextBox(""d, "textBox_path", Box(70, 20, 200, 40));
		button_browse = new Button("Browse"d, "button_browse", Box(225, 20, 290, 40));
		radioButton_single = new RadioButton("Single sprite"d, "radioButton0", Box(5, 45, 200, 64));
		label_sName = new Label("Name:"d, "label0", Box(5, 65, 50, 85));
		textBox_sName = new TextBox(""d, "textBox_path", Box(55, 65, 120, 85));
		label_sID = new Label("ID:"d, "label0", Box(125, 65, 150, 85));
		textBox_sID = new TextBox(""d, "textBox_path", Box(155, 65, 220, 85));
		radioButton_multi = new RadioButton("Multiple sprites (sheet)"d, "radioButton1", Box(5, 90, 200, 109));
		listView_sprSheet = new ListView(
				new ListViewHeader(16, [40 ,40 ,40 ,40 ,40 ,80], ["ID:" ,"x:" ,"y:" ,"w:" ,"h:" ,"Name:"]), 
				null, "listView_sprSheet", Box(5, 110, 290, 260));
		button_create = new Button("Create"d, "button0", Box(225, 265, 290, 285));
		smallButton_add = new SmallButton("addMaterialB", "addMaterialA", "", Box.bySize(5, 265, 16, 16));
		smallButton_remove = new SmallButton("removeMaterialB", "removeMaterialA", "", Box.bySize(5 + 16, 265, 16, 16));
		checkBox_impPal = new CheckBox("Import palette"d, "CheckBox0", Box(5, 285, 200, 305));
		label_palShift = new Label("palShift:"d, "label_palShift", Box(5, 305, 50, 325));
		textBox_palShift = new TextBox("0"d, "textBox_palShift", Box(50, 305, 100, 325));
		label_palOffset = new Label("palOffset:"d, "label_palOffset", Box(105, 305, 150, 325));
		textBox_palOffset = new TextBox("0"d, "textBox_palOffset", Box(150, 305, 200, 325));

		spriteAm = new RadioButtonGroup([radioButton_single, radioButton_multi]);
		spriteAm.onToggle = &radioButtonGroup_onToggle;

		addElement(label_path);
		addElement(textBox_path);
		addElement(button_browse);
		button_browse.onMouseLClick = &button_browse_onClick;
		addElement(radioButton_single);
		addElement(radioButton_multi);
		addElement(listView_sprSheet);
		addElement(button_create);
		button_create.onMouseLClick = &button_create_onClick;
		addElement(checkBox_impPal);
		addElement(label_palShift);
		addElement(textBox_palShift);
		addElement(label_palOffset);
		addElement(textBox_palOffset);
		addElement(textBox_sID);
		addElement(textBox_sName);
		addElement(smallButton_add);
		smallButton_add.onMouseLClick = &smallButton_add_onClick;
		addElement(smallButton_remove);
		smallButton_remove.onMouseLClick = &smallButton_remove_onClick;

		listView_sprSheet.state = ElementState.Disabled;
		smallButton_add.state = ElementState.Disabled;
		smallButton_remove.state = ElementState.Disabled;
		textBox_sID.state = ElementState.Disabled;
		textBox_sName.state = ElementState.Disabled;
	}
	protected void radioButtonGroup_onToggle(Event ev) {
		if (ev.aux is radioButton_single) {
			multi = false;
			listView_sprSheet.state = ElementState.Disabled;
			smallButton_add.state = ElementState.Disabled;
			smallButton_remove.state = ElementState.Disabled;
			textBox_sID.state = ElementState.Enabled;
			textBox_sName.state = ElementState.Enabled;
		} else if (ev.aux is radioButton_multi) {
			multi = true;
			listView_sprSheet.state = ElementState.Enabled;
			smallButton_add.state = ElementState.Enabled;
			smallButton_remove.state = ElementState.Enabled;
			textBox_sID.state = ElementState.Disabled;
			textBox_sName.state = ElementState.Disabled;
		}
	}
	protected void button_browse_onClick(Event ev) {
		import pixelperfectengine.concrete.dialogs.filedialog;
		handler.addWindow(new FileDialog("Select sprite sheet source", "fileLoad", &onFileSelect, 
				[FileDialog.FileAssociationDescriptor("All supported files", [".png",".tga",".bmp"]),
				FileDialog.FileAssociationDescriptor("Portable network graphics file", [".png"]),
				FileDialog.FileAssociationDescriptor("Truevision TARGA", [".tga"]),
				FileDialog.FileAssociationDescriptor("Windows bitmap", [".bmp"])], "./"));
	}
	protected void onFileSelect(Event ev) {
		FileEvent fev = cast(FileEvent)ev;
		textBox_path.setText(toUTF32(fev.getFullPath));
	}
	protected void button_create_onClick(Event ev) {
		import collections.treemap;
		int[] id;
		string[] name;
		Box[] spriteCoords;
		if (multi) {
			TreeMap!(uint, void) idChecker;
			for (int i ; i < listView_sprSheet.numEntries ; i++) {
				idChecker.put(to!uint(listView_sprSheet[i][0].text.toDString));
				id ~= to!uint(listView_sprSheet[i][0].text.toDString);
				spriteCoords ~= Box.bySize(to!uint(listView_sprSheet[i][1].text.toDString), 
						to!uint(listView_sprSheet[i][2].text.toDString), to!uint(listView_sprSheet[i][3].text.toDString), 
						to!uint(listView_sprSheet[i][4].text.toDString));
				name ~= toUTF8(listView_sprSheet[i][5].text.toDString);
			}
			if (idChecker.length != listView_sprSheet.numEntries) {
				handler.message("ID error!", "ID duplicates found!");
				return;
			}
		} else {
			name ~= toUTF8(textBox_sName.getText().toDString());
			id ~= to!uint(textBox_sID.getText().toDString());
		}
		md.events.addToTop(new AddSpriteSheetEvent(md, layerID, to!int(textBox_palOffset.getText.toDString), 
				to!int(textBox_palShift.getText.toDString), toUTF8(textBox_path.getText.toDString), spriteCoords, id, name));
		close();
	}
	protected void smallButton_add_onClick(Event ev) {
		listView_sprSheet ~= new ListViewItem(16, ["0","0","0","0","0",""], 
				[TextInputFieldType.DecimalP, TextInputFieldType.DecimalP, TextInputFieldType.DecimalP, TextInputFieldType.DecimalP, 
				TextInputFieldType.DecimalP, TextInputFieldType.Text]);
	}
	protected void smallButton_remove_onClick(Event ev) {
		if (listView_sprSheet.value >= 0){
			listView_sprSheet.removeEntry(listView_sprSheet.value);
			listView_sprSheet.refresh();
		}
	}
}
