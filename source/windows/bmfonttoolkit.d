module windows.bmfonttoolkit;

import pixelperfectengine.concrete.window;
import pixelperfectengine.concrete.dialogs.filedialog;

import bmfont;

import std.conv : to;
import std.string : format;
import std.format : unformatValue;
import std.algorithm.mutation : remove;
import app;

public class BMFontToolkit : Window {
	Font font;

	ListView listView0;
	ListViewHeader lvhInfo;
	ListViewHeader lvhChar;
	ListViewHeader lvhKerning;
	ListViewHeader lvhSources;
	Button button_load;
	Button button_save;
	Button button_remove;
	Button button_add;
	RadioButtonGroup group;
	RadioButton radioButton_common;
	RadioButton radioButton_info;
	RadioButton radioButton_char;
	RadioButton radioButton_kerning;
	RadioButton radioButton_sources;
	public this() {
		auto lang = prg.lang.output;
		super(Box(0, 0, 345, 305), lang["bmfonteditor_title"]);

		lvhInfo = new ListViewHeader(16, [100, 200], [lang["bmfonteditor_lvhInfo_name"], lang["bmfonteditor_lvhInfo_value"]]);
		lvhChar = new ListViewHeader(
			16, [40, 32, 32, 24, 24, 32, 32, 24, 16, 24], [lang["bmfonteditor_lvhChar_id"], lang["bmfonteditor_lvhChar_x"], 
			lang["bmfonteditor_lvhChar_y"], lang["bmfonteditor_lvhChar_w"], lang["bmfonteditor_lvhChar_h"], 
			lang["bmfonteditor_lvhChar_x0"], lang["bmfonteditor_lvhChar_y0"], lang["bmfonteditor_lvhChar_xA"], 
			lang["bmfonteditor_lvhChar_p"], lang["bmfonteditor_lvhChar_ch"]]
		);
		lvhKerning = new ListViewHeader(16, [48, 48, 32], [lang["bmfonteditor_lvhKerning_id0"], 
			lang["bmfonteditor_lvhKerning_id1"], lang["bmfonteditor_lvhKerning_am"]]
		);
		lvhSources = new ListViewHeader(16, [32, 300], 
			[lang["bmfonteditor_lvhSources_id"], lang["bmfonteditor_lvhSources_path"]]
		);
		listView0 = new ListView(lvhInfo, [], "listView0", Box(5, 20, 260, 300));
		button_load = new Button(lang["bmfonteditor_load"], "button_load", Box(265, 20, 340, 40));
		button_save = new Button(lang["bmfonteditor_save"], "button_save", Box(265, 45, 340, 65));
		button_remove = new Button(lang["bmfonteditor_remove"], "button_remove", Box(265, 280, 340, 300));
		button_add = new Button(lang["bmfonteditor_add"], "button_add", Box(265, 255, 340, 275));
		radioButton_common = new RadioButton(lang["bmfonteditor_common"], "radioButton_common", Box(265, 70, 340, 86));
		radioButton_info = new RadioButton(lang["bmfonteditor_info"], "radioButton_info", Box(265, 87, 340, 103));
		radioButton_char = new RadioButton(lang["bmfonteditor_char"], "radioButton_char", Box(265, 104, 339, 120));
		radioButton_kerning = new RadioButton(lang["bmfonteditor_kerning"], "radioButton_kerning", Box(265, 121, 340, 137));
		radioButton_sources = new RadioButton(lang["bmfonteditor_sources"], "radioButton_sources", Box(265, 138, 340, 154));

		addElement(listView0);
		addElement(button_load);
		addElement(button_save);
		addElement(button_remove);
		addElement(button_add);
		addElement(radioButton_common);
		addElement(radioButton_info);
		addElement(radioButton_char);
		addElement(radioButton_kerning);
		addElement(radioButton_sources);

		listView0.editEnable = true;
		listView0.multicellEditEnable = true;
		listView0.onTextInput = &onListViewEdit;

		group = new RadioButtonGroup([radioButton_common, radioButton_info, radioButton_char, radioButton_kerning, 
				radioButton_sources]);
		group.onToggle = &onSelect;
		group.latch(radioButton_common);
		radioButton_common.setGroup(group);
		radioButton_info.setGroup(group);
		radioButton_char.setGroup(group);
		radioButton_kerning.setGroup(group);
		radioButton_sources.setGroup(group);

		button_load.onMouseLClick = &onLoadButton;
		button_save.onMouseLClick = &onSaveButton;
		button_remove.onMouseLClick = &onRemoveButton;
		button_add.onMouseLClick = &onAddButton;
	}
	protected void onAddButton(Event ev) {
		if (radioButton_char.isChecked) {
			font.chars ~= Font.Char.init;
		} else if (radioButton_kerning.isChecked) {
			font.kernings ~= Font.Kerning.init;
		} else if (radioButton_sources.isChecked) {
			font.pages ~= "";
		}
		updateListView();
	}
	protected void onRemoveButton(Event ev) {
		if (radioButton_char.isChecked) {
			font.chars = remove(font.chars, listView0.value);
		} else if (radioButton_kerning.isChecked) {
			font.kernings = remove(font.kernings, listView0.value);
		} else if (radioButton_sources.isChecked) {
			font.pages = remove(font.pages, listView0.value);
		}
		updateListView();
	}
	protected void onListViewEdit(Event ev) {
		CellEditEvent ceev = cast(CellEditEvent)ev;
		dstring text = ceev.text().text();
		try {
			if (radioButton_char.isChecked) {
				switch (ceev.column) {
					case 0:
						font.chars[ceev.row].id = text.to!uint(16);
						break;
					case 1:
						font.chars[ceev.row].x = to!ushort(text);
						break;
					case 2:
						font.chars[ceev.row].y = to!ushort(text);
						break;
					case 3:
						font.chars[ceev.row].width = to!ushort(text);
						break;
					case 4:
						font.chars[ceev.row].height = to!ushort(text);
						break;
					case 5:
						font.chars[ceev.row].xoffset = to!short(text);
						break;
					case 6:
						font.chars[ceev.row].yoffset = to!short(text);
						break;
					case 7:
						font.chars[ceev.row].xadvance = to!short(text);
						break;
					case 8:
						font.chars[ceev.row].page = to!ubyte(text);
						break;
					case 9:
						font.chars[ceev.row].chnl = cast(Channels)text.to!uint(16);
						break;
					default:
						break;
				}
			} else if (radioButton_kerning.isChecked) {
				switch (ceev.column) {
					case 0:
						font.kernings[ceev.row].first = text.to!uint(16);
						break;
					case 1:
						font.kernings[ceev.row].second = text.to!uint(16);
						break;
					case 2:
						font.kernings[ceev.row].amount = to!short(text);
						break;
					default:
						break;
				}
			} else if (radioButton_sources.isChecked) {
				font.pages[ceev.row] = to!string(text);
			} else if (radioButton_info.isChecked) {
				switch (ceev.row) {
					case 0:
						font.info.fontSize = to!short(text);
						break;
					case 1:
						font.info.bitField = cast(ubyte)text.to!uint(16);
						break;
					case 2:
						font.info.charSet = to!ubyte(text);
						break;
					case 3:
						font.info.stretchH = to!ushort(text);
						break;
					case 4:
						font.info.aa = to!ubyte(text);
						break;
					case 5:
						font.info.padding[0] = to!ubyte(text);
						break;
					case 6:
						font.info.padding[1] = to!ubyte(text);
						break;
					case 7:
						font.info.padding[2] = to!ubyte(text);
						break;
					case 8:
						font.info.padding[3] = to!ubyte(text);
						break;
					case 9:
						font.info.spacing[0] = to!ubyte(text);
						break;
					case 10:
						font.info.spacing[1] = to!ubyte(text);
						break;
					case 11:
						font.info.fontName = to!string(text);
						break;
					case 12:
						font.info.outline = to!ubyte(text);
						break;
					
					default:
						break;
				} 
			} else {
				switch (ceev.row) {
					case 0:
						font.common.lineHeight = to!ushort(text);
						break;
					case 1:
						font.common.base = to!ushort(text);
						break;
					case 2:
						font.common.scaleW = to!ushort(text);
						break;
					case 3:
						font.common.scaleH = to!ushort(text);
						break;
					case 4:
						font.common.pages = to!ushort(text);
						break;
					case 5:
						font.common.bitField = to!ubyte(text);
						break;
					case 6:
						font.common.alphaChnl = cast(ChannelType)to!uint(text);
						break;
					case 7:
						font.common.redChnl = cast(ChannelType)to!uint(text);
						break;
					case 8:
						font.common.greenChnl = cast(ChannelType)to!uint(text);
						break;
					case 9:
						font.common.blueChnl = cast(ChannelType)to!uint(text);
						break;					
					default:
						break;
				}
			}
		} catch (Exception e) {

		}
		
	}
	protected void onLoadButton(Event ev) {
		handler.addWindow(new FileDialog(prg.lang.output["bmfonteditor_fd_load"], "bmFontLoad", &onLoadEvent, 
				[FileDialog.FileAssociationDescriptor(prg.lang.output["fd_bmfont"].toDString, ["*.fnt"])], "./", false));
	}
	protected void onLoadEvent(Event ev) {
		import std.stdio : File;
		FileEvent fev = cast(FileEvent)ev;
		File f = File(fev.getFullPath());
		ubyte[] buffer;
		buffer.length = cast(size_t)f.size();
		f.rawRead(buffer);
		font = parseFnt(buffer);
		updateListView();
	}
	protected void onSaveButton(Event ev) {
		handler.addWindow(new FileDialog(prg.lang.output["bmfonteditor_fd_save"], "bmFontSave", &onSaveEvent, 
				[FileDialog.FileAssociationDescriptor(prg.lang.output["fd_bmfont"].toDString, ["*.fnt"])], "./", true));
	}
	protected void onSaveEvent(Event ev) {
		import std.stdio : File;
		FileEvent fev = cast(FileEvent)ev;
		File f = File(fev.getFullPath(), "wb");
		ubyte[] buffer = font.toBinary();
		f.rawWrite(buffer);
	}
	protected void onSelect(Event ev) {
		updateListView();
	}
	protected void updateListView() {
		auto lang = prg.lang.output;
		void setButtons(ElementState es) {
			button_remove.state(es);
			button_add.state(es);
		}
		if (radioButton_info.isChecked) {
			setButtons(ElementState.Disabled);
			TextInputFieldType[] tift = [TextInputFieldType.None, TextInputFieldType.Text];
			listView0.setHeader(lvhInfo, [
				new ListViewItem(16, [lang["bmfonteditor_lvinfo_size"], to!dstring(font.info.fontSize)], tift),
				new ListViewItem(16, [lang["bmfonteditor_lvinfo_bitfield"], to!dstring(font.info.bitField)], tift),
				new ListViewItem(16, [lang["bmfonteditor_lvinfo_charset"], to!dstring(font.info.charSet)], tift),
				new ListViewItem(16, [lang["bmfonteditor_lvinfo_strechhz"], to!dstring(font.info.stretchH)], tift),
				new ListViewItem(16, [lang["bmfonteditor_lvinfo_antial"], to!dstring(font.info.aa)], tift),
				new ListViewItem(16, [lang["bmfonteditor_lvinfo_padup"], to!dstring(font.info.padding[0])], tift),
				new ListViewItem(16, [lang["bmfonteditor_lvinfo_paddn"], to!dstring(font.info.padding[1])], tift),
				new ListViewItem(16, [lang["bmfonteditor_lvinfo_padle"], to!dstring(font.info.padding[2])], tift),
				new ListViewItem(16, [lang["bmfonteditor_lvinfo_padri"], to!dstring(font.info.padding[3])], tift),
				new ListViewItem(16, [lang["bmfonteditor_lvinfo_spahz"], to!dstring(font.info.spacing[0])], tift),
				new ListViewItem(16, [lang["bmfonteditor_lvinfo_spave"], to!dstring(font.info.spacing[1])], tift),
				new ListViewItem(16, [lang["bmfonteditor_lvinfo_name"], to!dstring(font.info.fontName)], tift),
				new ListViewItem(16, [lang["bmfonteditor_lvinfo_outline"], to!dstring(font.info.outline)], tift),
			]);
		} else if (radioButton_common.isChecked) {
			setButtons(ElementState.Disabled);
			TextInputFieldType[] tift = [TextInputFieldType.None, TextInputFieldType.Text];
			listView0.setHeader(lvhInfo, [
				new ListViewItem(16, [lang["bmfonteditor_lvcommon_lh"], to!dstring(font.info.fontSize)], tift),
				new ListViewItem(16, [lang["bmfonteditor_lvcommon_base"], to!dstring(font.info.bitField)], tift),
				new ListViewItem(16, [lang["bmfonteditor_lvcommon_scw"], to!dstring(font.info.charSet)], tift),
				new ListViewItem(16, [lang["bmfonteditor_lvcommon_sch"], to!dstring(font.info.stretchH)], tift),
				new ListViewItem(16, [lang["bmfonteditor_lvcommon_pages"], to!dstring(font.info.aa)], tift),
				new ListViewItem(16, [lang["bmfonteditor_lvcommon_bitfield"], to!dstring(font.info.padding[0])], tift),
				new ListViewItem(16, [lang["bmfonteditor_lvcommon_cha"], to!dstring(font.info.padding[1])], tift),
				new ListViewItem(16, [lang["bmfonteditor_lvcommon_chr"], to!dstring(font.info.padding[2])], tift),
				new ListViewItem(16, [lang["bmfonteditor_lvcommon_chg"], to!dstring(font.info.padding[3])], tift),
				new ListViewItem(16, [lang["bmfonteditor_lvcommon_chb"], to!dstring(font.info.spacing[0])], tift),
			]);
		} else if (radioButton_char.isChecked) {
			setButtons(ElementState.Enabled);
			listView0.setHeader(lvhChar, []);
			foreach (key; font.chars) {
				listView0 ~= new ListViewItem(16, [
					format("%x"d, key.id), to!dstring(key.x), to!dstring(key.y), to!dstring(key.width), to!dstring(key.height), 
					to!dstring(key.xoffset), to!dstring(key.yoffset), to!dstring(key.xadvance), to!dstring(key.page), 
					format("%x"d, cast(int)key.chnl)
				], [
					TextInputFieldType.Text, TextInputFieldType.IntegerP, TextInputFieldType.IntegerP, TextInputFieldType.IntegerP, //width
					TextInputFieldType.IntegerP, TextInputFieldType.Integer, TextInputFieldType.Integer, TextInputFieldType.Integer, //xadvance
					TextInputFieldType.Integer, TextInputFieldType.Text
				]);
			}
			listView0.refresh();
		} else if (radioButton_kerning.isChecked) {
			setButtons(ElementState.Enabled);
			listView0.setHeader(lvhKerning, []);
			foreach (key; font.kernings) {
				listView0 ~= new ListViewItem(16, [format("%x"d, key.first), format("%x"d, key.second), to!dstring(key.amount)],
						[TextInputFieldType.Text, TextInputFieldType.Text, TextInputFieldType.Integer]);
			}
			listView0.refresh();
		} else {
			setButtons(ElementState.Enabled);
			listView0.setHeader(lvhSources, []);
			foreach (size_t i, string key; font.pages) {
				listView0 ~= new ListViewItem(16, [to!dstring(i), to!dstring(key)], [TextInputFieldType.None, 
						TextInputFieldType.Text]);
			}
			listView0.refresh();
		}
	}
}
