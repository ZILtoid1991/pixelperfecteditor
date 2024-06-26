module windows.addtiles;

import pixelperfectengine.concrete.window;
import pixelperfectengine.concrete.dialogs.filedialog;
import dimage;

import editor;

import std.conv : to;

public class AddTiles : Window {
	public enum Mode {
		Regular,
		RestrictTo4Bit,
		RestrictTo8Bit,
		RestrictTo16Bit,
		RestrictTo32Bit,
	}
	Label label_Source;
	Button button_Source;
	TextBox textBox_Source;
	Label label_palShift;
	TextBox textBox_palShift;
	CheckBox checkBox_palImport;
	CheckBox checkBox_embDat;
	Label label_palOffset;
	TextBox textBox_palOffset;
	Button button_Ok;
	Label label_name;
	TextBox textBox_name;
	Label label_numStyle;
	TextBox textBox_numStyle;
	Editor editor;
	Image source;
	int sizeX, sizeY;
	public this(Editor editor, int sizeX, int sizeY, Mode mode = Mode.Regular) {
		//super(Coordinate(0, 0, 165, 230), "Add Tiles"d);
		super(Coordinate(0, 0, 165, 230), editor.lang.output["addtiles_title"]);
		label_Source = new Label(editor.lang.output["addtiles_source"], "label_Source", Box(5, 21, 88, 40));
		button_Source = new Button(editor.lang.output["button_browse"], "button_Source", Box(90, 20, 160, 40));
		textBox_Source = new TextBox(""d, "textBox_Source", Box(5, 42, 160, 62));
		label_palShift = new Label(editor.lang.output["addtiles_palShift"], "label_palShift", Box(5, 64, 88, 82));
		textBox_palShift = new TextBox("8"d, "textBox_palShift", Box(100, 64, 160, 84));
		checkBox_palImport = new CheckBox(editor.lang.output["addtiles_palImport"], "CheckBox0", Box(5, 156, 160, 172));
		checkBox_embDat = new CheckBox(editor.lang.output["addtiles_embDat"], "CheckBox1", Box(5, 173, 160, 189));
		label_palOffset = new Label(editor.lang.output["addtiles_palOffset"], "label_palOffset", Box(5, 88, 99, 105));
		textBox_palOffset = new TextBox("0"d, "textBox_palOffset", Box(100, 86, 160, 106));
		textBox_palOffset.setFilter(TextInputFieldType.IntegerP);
		button_Ok = new Button(editor.lang.output["button_ok"], "button_Ok", Box(91, 206, 161, 226));
		label_name = new Label(editor.lang.output["addtiles_name"], "label_name", Box(5, 110, 79, 126));
		textBox_name = new TextBox(""d, "textBox_name", Box(45, 108, 160, 128));
		label_numStyle = new Label(editor.lang.output["addtiles_numStyle"], "label_numStyle", Box(5, 130, 120, 150));
		textBox_numStyle = new TextBox("h0000"d, "textBox_numStyle", Box(120, 130, 160, 150));
		this.sizeX = sizeX;
		this.sizeY = sizeY;
		addElement(label_Source);
		addElement(button_Source);
		button_Source.onMouseLClick = &button_Source_onClick;
		addElement(textBox_Source);
		textBox_Source.onTextInput = &textBox_Source_onTextInput;
		addElement(label_palShift);
		textBox_palShift.setFilter(TextInputFieldType.IntegerP);
		addElement(textBox_palShift);
		addElement(checkBox_palImport);
		addElement(checkBox_embDat);
		addElement(label_palOffset);
		textBox_palOffset.setFilter(TextInputFieldType.IntegerP);
		addElement(textBox_palOffset);
		addElement(button_Ok);
		button_Ok.onMouseLClick = &button_Ok_onClick;
		addElement(label_name);
		addElement(textBox_name);
		addElement(label_numStyle);
		addElement(textBox_numStyle);
		checkBox_embDat.state = ElementState.Disabled;
		this.editor = editor;
	}
	private void button_Source_onClick(Event e) {
		handler.addWindow(new FileDialog("Import Tile Source"d, "fileDialog_TSBrowse", &fileDialog_TSBrowse_event,
				[FileDialog.FileAssociationDescriptor("All supported formats", ["*.tga", "*.png", "*.bmp"]),
					/+FileDialog.FileAssociationDescriptor("PPE Extendible Map file", ["*.xmf"]),+/
					FileDialog.FileAssociationDescriptor("Targa Graphics File", ["*.tga"]),
					FileDialog.FileAssociationDescriptor("Windows Bitmap File", ["*.bmp"]),
					FileDialog.FileAssociationDescriptor("Portable Network Graphics File", ["*.png"]),], "./"));
	}
	private void textBox_palShift_onTextInput(Event e) {
		//validate input type
		//import pixelperfectengine.system.etc : isInteger;
		const int value = to!int(textBox_palShift.getText.text);
		if (value < 1 || value > 8) {
			handler.message("Bad value!"d, "Value must be between 1 and 8!"d);
		}
	}
	private void fileDialog_TSBrowse_event(Event ev) {
		FileEvent e = cast(FileEvent)ev;
		if (!loadFile(e.getFullPath)) {
			textBox_Source.setText(to!dstring(e.getFullPath));
		}
	}
	private void textBox_Source_onTextInput(Event e) {
		if (loadFile(to!string(textBox_Source.getText.text))) {
			textBox_Source.setText(""d);
		}
		
	}
	private int loadFile(string path) {
		import std.path : extension;
		import std.stdio : File;
		import pixelperfectengine.system.etc : nextPow2;
		File f = File(path);
		try {
			switch (path.extension) {
				case ".xmp"://TO DO: enable importing material data from other map files
					break;
				case ".png":
					source = PNG.load(f);
					break;
				case ".tga":
					source = TGA.load!(File, true, true)(f);
					break;
				case ".bmp":
					source = BMP.load(f);
					break;
				default:
					handler.message("Unsupported file format!"d, "The specified file format is not supported!"d);
					return -1;
			}
		} catch (Exception ex) {
			import std.conv : to;
			handler.message("Error!"d, to!dstring(ex.msg));
			return -1;
		}
		if (source.width % sizeX || source.height % sizeY) {
			handler.message("Tile size Mismatch!"d, "Supplied bitmap file is unsuitable for this layer as a tile source!"d);
			source = null;
			return -1;
		}
		if(source.isIndexed) {
			checkBox_palImport.check();
			const int paletteLengthPOw2 = cast(int)nextPow2(source.palette.length);
			textBox_palShift.state = ElementState.Enabled;
			switch (paletteLengthPOw2) {
				case 2:
					textBox_palShift.setText("1");
					break;
				case 4:
					textBox_palShift.setText("2");
					break;
				case 8:
					textBox_palShift.setText("3");
					break;
				case 16:
					textBox_palShift.setText("4");
					break;
				case 32:
					textBox_palShift.setText("5");
					break;
				case 64:
					textBox_palShift.setText("6");
					break;
				case 128:
					textBox_palShift.setText("7");
					break;
				case 256:
					textBox_palShift.setText("8");
					break;
				default: break;
			}
		} else {
			textBox_palShift.setText("");
			textBox_palShift.state = ElementState.Disabled;
			textBox_palOffset.setText("");
			textBox_palOffset.state = ElementState.Disabled;
			checkBox_palImport.state = ElementState.Disabled;
		}
		return 0;
	}
	private void button_Ok_onClick(Event e) {
		import pixelperfectengine.system.etc : parseHex, parseOct, parseDec;
		import editorevents : AddTileSheetEvent;
		//detect numbering style
		uint numStyle0;
		int numFrom;
		dstring numStyle = textBox_numStyle.getText.text;
		if (numStyle.length) {
			if (numStyle[0] == 'h' || numStyle[$-1] == 'h') { 
				numStyle0 = 1;
				numStyle0 |= cast(uint)((numStyle.length - 1) << 8);
			}
			else if (numStyle[0] == 'o' || numStyle[$-1] == 'o') { 
				numStyle0 = 2;
				numStyle0 |= cast(uint)((numStyle.length - 1) << 8);
			}
			else if (numStyle.length >= 2) { 
				if (numStyle[0..2] == "0x")	{
					numStyle0 = 1;
					numStyle0 |= cast(uint)((numStyle.length - 2) << 8);
				}
				else if (numStyle[0..2] == "0o") {
					numStyle0 = 2;
					numStyle0 |= cast(uint)((numStyle.length - 2) << 8);
				}
			} else numStyle0 = cast(uint)(numStyle.length << 8);
			switch (numStyle0) {
				case 1: numFrom = parseHex(numStyle); break;
				case 2: numFrom = parseOct(numStyle); break;
				default: numFrom = parseDec(numStyle); break;
			}
			string name0 = to!string(textBox_name.getText.text);
			string[3] name;
			if (name0.length) {
				for (size_t i ; i < name0.length ; i++) {
					if (name0[i] == '#') {
						name[0] = name0[0..i];
						if (i + 2 < name0.length) {
							name[1] = name0[i+2..$];
						}
					}
				}
			}
			if(!name[0].length) name[0] = name0;
			name[2] = to!string(textBox_Source.getText.text);
			const int paletteShift = checkBox_palImport.isChecked ? to!int(textBox_palShift.getText.text) : -1;
			const int paletteOffset = checkBox_palImport.isChecked ? to!int(textBox_palOffset.getText.text) : -1;
			
			editor.selDoc.events.addToTop(new AddTileSheetEvent(source, editor.selDoc, editor.selDoc.selectedLayer, 
					paletteOffset, paletteShift, name, numFrom, numStyle0));
			editor.selDoc.updateMaterialList;
			
			this.close;
		} else {
			handler.message("Error!"d, "Numbering style must be specified in this case!");
		}
	}
}
