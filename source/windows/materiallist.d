module windows.materiallist;

import pixelperfectengine.concrete.window;
import pixelperfectengine.map.mapformat;

import app;

import std.utf : toUTF32, toUTF8;
import std.format;
import pixelperfectengine.system.etc : intToHex, clamp;

/**
 * Preliminary, future version will feature material selection with images.
 */
public class MaterialList : Window {
	//ListBox			listBox_materials;
	ListView		listView_materials;
	Label			palettePos;
	SmallButton		removeMaterial;
	SmallButton		addMaterial;
	CheckBox		horizMirror;
	CheckBox		vertMirror;
	CheckBox		ovrwrtIns;
	SmallButton		paletteUp;
	SmallButton		paletteDown;
	SmallButton		settings;
	SmallButton		tileFlags;

	protected TileInfo[] tiles;
	protected int[] spriteIDs;
	protected dstring[6] tileFlagNames;
	//protected SpriteInfo[] sprites;
	protected ListViewHeader tileListHeader;
	protected ListViewHeader spriteListHeader;
	public this(int x, int y, void delegate() onClose) @trusted {
		super(Box(x, y, x + 129, y + 249), prg.lang.output["materiallist_title"]);
		this.onClose = onClose;
		StyleSheet ss = getStyleSheet();
		/+listBox_materials = new ListBox("listBox0", Coordinate(1, 17, 129, 218), [], new ListBoxHeader(tileListHeaderS.dup,
				tileListHeaderW.dup));+/
		tileListHeader = new ListViewHeader(16, [32, 120], 
			[prg.lang.output["materiallist_id"], prg.lang.output["materiallist_name"]]);
		spriteListHeader = new ListViewHeader(16, [40, 120, 64], 
			[prg.lang.output["materiallist_id"], prg.lang.output["materiallist_name"], prg.lang.output["materiallist_dim"]]);
		listView_materials = new ListView(tileListHeader, null, "listView_materials", Box(1, 17, 128, 215));
		listView_materials.onItemSelect = &onItemSelect;
		listView_materials.editEnable = true;
		listView_materials.onTextInput = &onItemRename;
		addElement(listView_materials);
		
		removeMaterial = new SmallButton("removeMaterialB", "removeMaterialA", "rem", Box(113, 233, 129, 248));
		removeMaterial.onMouseLClick = &button_trash_onClick;
		addElement(removeMaterial);
		
		addMaterial = new SmallButton("addMaterialB", "addMaterialA", "add", Box(113, 217, 129, 232));
		addMaterial.onMouseLClick = &button_addMaterial_onClick;
		addElement(addMaterial);
		
		horizMirror = new CheckBox("horizMirrorB", "horizMirrorA", "horizMirror", Box(1, 217, 16, 232));
		horizMirror.onToggle = &horizMirror_onClick;
		addElement(horizMirror);
		
		vertMirror = new CheckBox("vertMirrorB", "vertMirrorA", "vertMirror", Box(17, 217, 32, 232));
		vertMirror.onToggle = &vertMirror_onClick;
		addElement(vertMirror);
		
		ovrwrtIns = new CheckBox("ovrwrtInsB", "ovrwrtInsA", "ovrwrtIns", Box(33, 217, 48, 232));
		ovrwrtIns.onToggle = &ovrwrtIns_onClick;
		addElement(ovrwrtIns);
		
		paletteUp = new SmallButton("paletteUpB", "paletteUpA", "palUp", Box(1, 233, 16, 248));
		paletteUp.onMouseLClick = &palUp_onClick;
		addElement(paletteUp);
		
		paletteDown = new SmallButton("paletteDownB", "paletteDownA", "palDown", Box(17, 233, 32, 248));
		paletteDown.onMouseLClick = &palDown_onClick;
		addElement(paletteDown);
		
		settings = new SmallButton("settingsButtonB", "settingsButtonA", "editMat", Box(97, 233, 112, 248));
		settings.onMouseLClick = &button_editMat_onClick;
		addElement(settings);
		
		tileFlags = new SmallButton("tileFlagsButtonB", "tileFlagsButtonA", "tileFlags", Box.bySize(49, 217, 16, 16));
		tileFlags.onMouseLClick = &button_tileFlags_onClick;
		addElement(tileFlags);

		tileFlagNames[0] = "[L]Bit0: N/A";
		tileFlagNames[1] = "[L]Bit1: N/A";
		tileFlagNames[2] = "[L]Bit2: N/A";
		tileFlagNames[3] = "[L]Bit3: N/A";
		tileFlagNames[4] = "[L]Bit4: N/A";
		tileFlagNames[5] = "[L]Bit5: N/A";

		palettePos = new Label("0x00", "palettePos", Box(34, 234, 96, 248));
		addElement(palettePos);
	}
	public void setTileFlagName(int num, string name) {
		tileFlagNames[num] = tileFlagNames[num][0..8] ~ toUTF32(name);
	}
	public void updateMaterialList(TileInfo[] list) @trusted {
		import pixelperfectengine.system.etc : intToHex;
		spriteIDs.length = 0;
		tiles = list;
		ListViewItem[] output;
		output.reserve = list.length;
		listView_materials.clear;
		
		foreach (item ; list) {
			ListViewItem f = new ListViewItem(16, [format("%04Xh"d,item.id), toUTF32(item.name)], 
					[TextInputFieldType.None, TextInputFieldType.Text]);
			output ~= f;
		}
		listView_materials.setHeader(tileListHeader, output);
		listView_materials.refresh;
		tileFlags.state = ElementState.Enabled;
		tileFlagNames[0] = "[L]Bit0: N/A";
		tileFlagNames[1] = "[L]Bit1: N/A";
		tileFlagNames[2] = "[L]Bit2: N/A";
		tileFlagNames[3] = "[L]Bit3: N/A";
		tileFlagNames[4] = "[L]Bit4: N/A";
		tileFlagNames[5] = "[L]Bit5: N/A";
		/+listBox_materials.updateColumns(output, new ListBoxHeader(tileListHeaderS.dup, tileListHeaderW.dup));+/
	}
	public void updateMaterialList(int[] id, string[] name, int[2][] size) @trusted {
		assert(id.length == name.length);
		assert(id.length == size.length);
		ListViewItem[] output;
		output.reserve = id.length;
		listView_materials.clear;
		tiles.length = 0;

		for (int i; i < id.length ; i++) {
			ListViewItem f = new ListViewItem(16, [format("%04Xh"d,id[i]), toUTF32(name[i]), 
					format("%d \u00d7 %d"d, size[i][0], size[i][1])], 
					[TextInputFieldType.None, TextInputFieldType.Text, TextInputFieldType.None]);
			//f[1].editable = true;
			output ~= f;
		}
		listView_materials.setHeader(spriteListHeader, output);
		listView_materials.refresh;
		tileFlags.state = ElementState.Disabled;
		spriteIDs = id;
	}
	private void vertMirror_onClick(Event ev) {
		CheckBox sender = cast(CheckBox)ev.sender;
		if (prg.selDoc) {
			if(sender.isChecked) {
				prg.selDoc.tileMaterial_FlipVertical(true);
			} else {
				prg.selDoc.tileMaterial_FlipVertical(false);
			}
		}
	}
	private void horizMirror_onClick(Event ev) {
		CheckBox sender = cast(CheckBox)ev.sender;
		if (prg.selDoc) {
			if(sender.isChecked) {
				prg.selDoc.tileMaterial_FlipHorizontal(true);
			} else {
				prg.selDoc.tileMaterial_FlipHorizontal(false);
			}
		}
	}
	private void button_addMaterial_onClick(Event ev) {
		prg.initAddMaterials;
	}
	private void button_tileFlags_onClick(Event ev) {
		auto chrFrmt = getStyleSheet.getChrFormatting("smallFixed");
		handler.addPopUpElement(new PopUpMenu([
			new PopUpMenuElement("\0", new Text(tileFlagNames[0], chrFrmt)),
			new PopUpMenuElement("\1", new Text(tileFlagNames[1], chrFrmt)),
			new PopUpMenuElement("\2", new Text(tileFlagNames[2], chrFrmt)),
			new PopUpMenuElement("\3", new Text(tileFlagNames[3], chrFrmt)),
			new PopUpMenuElement("\4", new Text(tileFlagNames[4], chrFrmt)),
			new PopUpMenuElement("\5", new Text(tileFlagNames[5], chrFrmt)),
		], "tileFlags", &onTileFlagsToggle));
	}
	private void onTileFlagsToggle(Event ev) {
		MenuEvent me = cast(MenuEvent)ev;
		const int num = cast(int)me.itemNum;
		if (prg.selDoc) {
			const uint currFlags = prg.selDoc.tileMaterial_SetFlag(num, tileFlagNames[num][1] == 'L');
			if (currFlags & (1<<num)) {
				tileFlagNames[num] = tileFlagNames[num][0..1] ~ "H" ~ tileFlagNames[num][2..$];
			} else {
				tileFlagNames[num] = tileFlagNames[num][0..1] ~ "L" ~ tileFlagNames[num][2..$];
			}
		}
	}
	
	private void button_editMat_onClick(Event ev) {

	}
	private void button_trash_onClick(Event ev) {
		if (listView_materials.value != -1) {
			if (tiles.length)
				prg.selDoc.removeTile(tiles[listView_materials.value].id);
			else if (spriteIDs.length)
				prg.selDoc.removeSprite(spriteIDs[listView_materials.value]);
		}
	}
	public void palUp_onClick(Event ev) {
		if (prg.selDoc)
			palettePos.setText("0x" ~ intToHex!dstring(prg.selDoc.tileMaterial_PaletteUp, 2));
	}
	public void palDown_onClick(Event ev) {
		if (prg.selDoc)
			palettePos.setText("0x" ~ intToHex!dstring(prg.selDoc.tileMaterial_PaletteDown, 2));
	}

	private void ovrwrtIns_onClick(Event ev) {
		CheckBox sender = cast(CheckBox)ev.sender;
		if (prg.selDoc)
			prg.selDoc.voidfill = sender.isChecked;
	}
	private void onItemSelect(Event ev) {
		if (tiles.length) {
			prg.selDoc.tileMaterial_Select(tiles[listView_materials.value].id);
		} else if (spriteIDs.length) {
			prg.selDoc.selSprMat = spriteIDs[listView_materials.value];
		}
	}
	private void onItemRename(Event ev) {
		CellEditEvent cee = cast(CellEditEvent)ev;
		string newName = toUTF8(cee.text().text());
		prg.selDoc.renameTile(tiles[listView_materials.value].id, newName);
	}
	public void nextTile() {
		if (prg.selDoc) {
			if (listView_materials.value < listView_materials.numEntries() - 1)
				listView_materials.value = listView_materials.value + 1;
			if (listView_materials.value != -1)
				prg.selDoc.tileMaterial_Select(tiles[listView_materials.value].id);
		}
	}
	public void prevTile() {
		if (prg.selDoc) {
			if (listView_materials.value > 0)
				listView_materials.value = listView_materials.value - 1;
			if (listView_materials.value != -1)
				prg.selDoc.tileMaterial_Select(tiles[listView_materials.value].id);
		}
	}
}

