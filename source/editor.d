﻿/*
 * Copyright (C) 2016-2017, by Laszlo Szeremi under the Boost license.
 *
 * Pixel Perfect Editor, graphics.outputScreen module
 */

module editor;

import pixelperfectengine.graphics.outputscreen;
import pixelperfectengine.graphics.raster;
import pixelperfectengine.graphics.layers;

import pixelperfectengine.graphics.bitmap;
import pixelperfectengine.graphics.draw;
import pixelperfectengine.system.input;
import pixelperfectengine.system.file;
import pixelperfectengine.system.etc;
import pixelperfectengine.system.config;
import pixelperfectengine.system.systemutility;
public import pixelperfectengine.system.lang.textparser;
import std.stdio;
import std.conv;
import std.utf;
import core.stdc.string : memcpy;
import bindbc.sdl;
import pixelperfectengine.concrete.window;
import pixelperfectengine.concrete.eventchainsystem;
import pixelperfectengine.map.mapformat;
import pixelperfectengine.system.timer;

import windows.resizemap;
import windows.about;
import editorevents;
public import windows.layerlist;
public import windows.materiallist;
public import windows.objectlist;
import document;
import windows.rasterwindow;
import windows.newtilelayer;
import windows.spritemat;
import clipboard;
import windows.propertylist;



public class NewDocumentDialog : Window{
	public Editor ie;
	private TextBox[] textBoxes;
	public this(Coordinate size, dstring title){
		super(size, title);
	}
	public this(Editor ie){
		this(Box(10,10,220,150),"New Document"d);
		this.ie = ie;
		Button[] buttons;
		Label[] labels;
		buttons ~= new Button("Ok", "ok", Box(150,110,200,130));

		labels ~= new Label("Name:","",Box(5,20,80,39));
		labels ~= new Label("RasterX:","",Box(5,40,80,59));
		labels ~= new Label("RasterY:","",Box(5,60,80,79));
		//labels ~= new Label("N. of colors:","",Coordinate(5,80,120,99));
		textBoxes ~= new TextBox("newdocument","name",Box(81,20,200,39));
		textBoxes ~= new TextBox("424","rX",Box(121,40,200,59));
		textBoxes ~= new TextBox("240","rY",Box(121,60,200,79));
		//textBoxes ~= new TextBox("","pal",Coordinate(121,80,200,99));
		addElement(buttons[0]);
		foreach(WindowElement we; labels){
			addElement(we);
		}
		foreach(TextBox we; textBoxes){
			//we.addTextInputHandler(inputhandler);
			addElement(we);
		}
		buttons[0].onMouseLClick = &buttonOn_onMouseLClickRel;
	}

	public void buttonOn_onMouseLClickRel(Event event){
		ie.createNewDocument(textBoxes[0].getText().text, to!int(textBoxes[1].getText().text), to!int(textBoxes[2].getText().text));

		close();
	}
}

public class TopLevelWindow : Window {
	public this(int width, int height, Editor prg) {
		Text mt(dstring text) @safe nothrow {
			return new Text(text, globalDefaultStyle.getChrFormatting("defaultRJ"));
		}
		super(Box(0, 0, width, height), ""d, [], null);
		MenuBar mb;
		{
			PopUpMenuElement[] menuElements;
			menuElements ~= new PopUpMenuElement("file", prg.lang.output["menubar_file"]);

			menuElements[0] ~= new PopUpMenuElement("new", prg.lang.output["menubar_file_new"]);
			menuElements[0] ~= new PopUpMenuElement("newTemp", prg.lang.output["menubar_file_newtemp"]);
			menuElements[0] ~= new PopUpMenuElement("load", prg.lang.output["menubar_file_load"]);
			menuElements[0] ~= new PopUpMenuElement("save", prg.lang.output["menubar_file_save"]);
			menuElements[0] ~= new PopUpMenuElement("saveAs", prg.lang.output["menubar_file_saveas"]);
			menuElements[0] ~= new PopUpMenuElement("saveTemp", prg.lang.output["menubar_file_savetemp"]);
			menuElements[0] ~= new PopUpMenuElement("exit", prg.lang.output["menubar_file_exit"]);

			menuElements ~= new PopUpMenuElement("edit", prg.lang.output["menubar_edit"]);

			menuElements[1] ~= new PopUpMenuElement("undo", prg.lang.output["menubar_edit_undo"]);
			menuElements[1] ~= new PopUpMenuElement("redo", prg.lang.output["menubar_edit_redo"]);
			menuElements[1] ~= new PopUpMenuElement("copy", prg.lang.output["menubar_edit_copy"]);
			menuElements[1] ~= new PopUpMenuElement("cut", prg.lang.output["menubar_edit_cut"]);
			menuElements[1] ~= new PopUpMenuElement("paste", prg.lang.output["menubar_edit_paste"]);
			menuElements[1] ~= new PopUpMenuElement("editorSetup", prg.lang.output["menubar_edit_editorsetup"]);
			menuElements[1] ~= new PopUpMenuElement("docSetup", prg.lang.output["menubar_edit_docsetup"]);

			menuElements ~= new PopUpMenuElement("view", prg.lang.output["menubar_view"]);

			menuElements[2] ~= new PopUpMenuElement("layerList", prg.lang.output["menubar_view_layerlist"]);
			menuElements[2] ~= new PopUpMenuElement("materialList", prg.lang.output["menubar_view_materiallist"]);
			menuElements[2] ~= new PopUpMenuElement("viewgrid", prg.lang.output["menubar_view_grid"]);
			menuElements[2] ~= new PopUpMenuElement("objlist", prg.lang.output["menubar_view_objects"]);
			menuElements[2] ~= new PopUpMenuElement("proplist", prg.lang.output["menubar_view_props"]);
			menuElements[2] ~= new PopUpMenuElement("resetLayers", prg.lang.output["menubar_view_reset"]);

			menuElements ~= new PopUpMenuElement("layers", prg.lang.output["menubar_layers"]);

			menuElements[3] ~= new PopUpMenuElement("newLayer", prg.lang.output["menubar_layers_new"]);
			menuElements[3] ~= new PopUpMenuElement("delLayer", prg.lang.output["menubar_layers_delete"]);
			menuElements[3] ~= new PopUpMenuElement("\\submenu\\", prg.lang.output["menubar_layers_import"], mt(">"));
			menuElements[3][2] ~= new PopUpMenuElement("tiledcsvi", prg.lang.output["menubar_layers_importcsv"]);
			menuElements[3][2] ~= new PopUpMenuElement("ppebinmapi", prg.lang.output["menubar_layers_importppebin"]);
			menuElements[3] ~= new PopUpMenuElement("\\submenu\\", prg.lang.output["menubar_layers_export"], mt(">"));
			menuElements[3][3] ~= new PopUpMenuElement("tiledcsve", prg.lang.output["menubar_layers_exportcsv"]);
			menuElements[3][3] ~= new PopUpMenuElement("ppebinmape", prg.lang.output["menubar_layers_exportppebin"]);
			menuElements[3] ~= new PopUpMenuElement("layerSrc", prg.lang.output["menubar_layers_resrc"]);
			menuElements[3] ~= new PopUpMenuElement("resizeLayer", prg.lang.output["menubar_layers_resize"]);

			menuElements ~= new PopUpMenuElement("tools", prg.lang.output["menubar_tools"]);

			//menuElements[4] ~= new PopUpMenuElement("tgaTool", prg.lang.output["menubar_tools_tga"]);
			menuElements[4] ~= new PopUpMenuElement("bmfontTool", prg.lang.output["menubar_tools_bmfont"]);

			menuElements ~= new PopUpMenuElement("help", prg.lang.output["menubar_help"]);

			//menuElements[5][0] = new PopUpMenuElement("helpFile", prg.lang.output["menubar_help_content"]);
			menuElements[5] ~= new PopUpMenuElement("about", prg.lang.output["menubar_help_about"]);

			mb = new MenuBar("mb", Box(0,0, width - 1, 15), menuElements);

			mb.onMenuEvent = &prg.menuEvent;
		}
		addElement(mb);
	}
	public override void draw(bool drawHeaderOnly = false) {
		output.drawFilledBox(position, 0);
		foreach (WindowElement we; elements) {
			we.draw();
		}
	}
	public override void drawHeader() {

	}
	///Passes mouse click event
	public override void passMCE(MouseEventCommons mec, MouseClickEvent mce) {
		lastMousePos = Point(mce.x - position.left, mce.y - position.top);
		foreach (WindowElement we; elements) {
			if (we.getPosition.isBetween(lastMousePos)) {
				lastMouseEventTarget = we;
				mce.x = lastMousePos.x;
				mce.y = lastMousePos.y;
				we.passMCE(mec, mce);
				return;
			}
		}
		foreach (ISmallButton sb; smallButtons) {
			WindowElement we = cast(WindowElement)sb;
			if (we.getPosition.isBetween(lastMousePos)) {
				lastMouseEventTarget = we;
				mce.x = lastMousePos.x;
				mce.y = lastMousePos.y;
				we.passMCE(mec, mce);
				return;
			}
		}
		lastMouseEventTarget = null;
	}
	///Passes mouse move event
	public override void passMME(MouseEventCommons mec, MouseMotionEvent mme) {
		lastMousePos = Point(mme.x - position.left, mme.y - position.top);
		if (lastMouseEventTarget) {
			mme.x = lastMousePos.x;
			mme.y = lastMousePos.y;
			lastMouseEventTarget.passMME(mec, mme);
			if (!lastMouseEventTarget.getPosition.isBetween(mme.x, mme.y)) {
				lastMouseEventTarget = null;
			}
		} else {
			foreach (WindowElement we; elements) {
				if (we.getPosition.isBetween(lastMousePos)) {
					lastMouseEventTarget = we;
					mme.x = lastMousePos.x;
					mme.y = lastMousePos.y;
					we.passMME(mec, mme);
					return;
				}
			}
		}
	}
}

public class Editor : InputListener, SystemEventListener {
	public OutputScreen[] ow;
	public Raster rasters;
	public InputHandler input;
	public wchar selectedTile;
	public SpriteLayer windowing;
	public SpriteLayer bitmapPreview;
	public bool onexit, exitDialog, newLayerDialog, mouseState, rasterRefresh;
	public Window test;
	public WindowHandler wh;
	
	public ConfigurationProfile configFile;
	public TextParser lang;
	private int mouseX, mouseY;
	//private Coordinate selection, selectedTiles;
	
	public MapDocument[dstring] documents;
	public MapDocument selDoc;
	public LayerList layerList;
	public MaterialList materialList;
	public ObjectList objectList;
	public PropertyList propertyList;
	public MapClipboard mapClipboard;
	public int[4] windowSizes;
	
	public this(string[] args){
		import sdlang;
		ConfigurationProfile.setVaultPath("ZILtoid1991","PixelPerfectEditor");
		if (args.length > 1) {
			if (args[1] == "--restore") {
				ConfigurationProfile.restoreDefaults;
			}
		}
		configFile = new ConfigurationProfile();

		//lang = new TextParser
		foreach (Tag t ; configFile.ancillaryTags) {
			if (t.name == "graphicsScaling") {
				windowSizes[2] = t.values[0].get!int;
				windowSizes[3] = t.values[1].get!int;
			} else if (t.name == "rasterSize") {
				windowSizes[0] = t.values[0].get!int;
				windowSizes[1] = t.values[1].get!int;
			}
		}
		if (!windowSizes[0]) windowSizes[0] = 848;
		if (!windowSizes[1]) windowSizes[1] = 480;
		if (!windowSizes[2]) windowSizes[2] = 2;
		if (!windowSizes[3]) windowSizes[3] = 2;

		windowing = new SpriteLayer(RenderingMode.Copy);
		bitmapPreview = new SpriteLayer();

		wh = new WindowHandler(windowSizes[0] * windowSizes[2], windowSizes[1] * windowSizes[3], windowSizes[0], 
				windowSizes[1], windowing);
		//wh.ie = this;

		//Initialize the Concrete framework
		INIT_CONCRETE();
		//Parse language file
		dstring langFile;
		//Note to self: create a better way to check for XML encoding
		{
			import sdlang;
			import std.algorithm.searching;
			File f = File(getPathToLocalizationFile(configFile.localCountry, configFile.localLang, ".xml"));
			char[] buffer;
			buffer.length = cast(size_t)f.size;
			f.rawRead(buffer);
			const size_t firstlineEnd = countUntil(buffer, '\n', '\r');
			if (countUntil(buffer[0..firstlineEnd], cast(const(char)[])"UTF-16"w) != -1) {
				langFile = toUTF32(cast(wstring)(buffer).idup);
			} else if (countUntil(buffer[0..firstlineEnd], cast(const(char)[])"UTF-32"d) != -1) {
				langFile = cast(dstring)(buffer).idup;
			} else {
				langFile = toUTF32(buffer.idup);
			}
		}
		lang = new TextParser(langFile, globalDefaultStyle.getChrFormatting("default"));
		lang.namedFormats["button"] = globalDefaultStyle.getChrFormatting("button");
		lang.namedFormats["menubar"] = globalDefaultStyle.getChrFormatting("menuBar");
		lang.parse();
		//writeln(globalDefaultStyle.drawParameters);
		//Initialize custom GUI elements
		{
			Bitmap8Bit[] customGUIElems = loadBitmapSheetFromFile!Bitmap8Bit(getPathToAsset("/system/concreteGUIE1.tga"), 16, 16);
			globalDefaultStyle.setImage(customGUIElems[0], "menuButtonA");
			globalDefaultStyle.setImage(customGUIElems[1], "menuButtonB");
			globalDefaultStyle.setImage(customGUIElems[2], "fullSizeButtonA");
			globalDefaultStyle.setImage(customGUIElems[3], "fullSizeButtonB");
			globalDefaultStyle.setImage(customGUIElems[4], "smallSizeButtonA");
			globalDefaultStyle.setImage(customGUIElems[5], "smallSizeButtonB");
			globalDefaultStyle.setImage(customGUIElems[6], "newDocumentButtonA");
			globalDefaultStyle.setImage(customGUIElems[7], "newDocumentButtonB");
			globalDefaultStyle.setImage(customGUIElems[8], "saveDocumentButtonA");
			globalDefaultStyle.setImage(customGUIElems[9], "saveDocumentButtonB");
			globalDefaultStyle.setImage(customGUIElems[10], "loadDocumentButtonA");
			globalDefaultStyle.setImage(customGUIElems[11], "loadDocumentButtonB");
			globalDefaultStyle.setImage(customGUIElems[12], "settingsButtonA");
			globalDefaultStyle.setImage(customGUIElems[13], "settingsButtonB");
			globalDefaultStyle.setImage(customGUIElems[14], "blankButtonA");
			globalDefaultStyle.setImage(customGUIElems[15], "blankButtonB");
		}
		{
			Bitmap8Bit[] customGUIElems = loadBitmapSheetFromFile!Bitmap8Bit(getPathToAsset("/system/concreteGUIE4.tga"), 16, 16);
			globalDefaultStyle.setImage(customGUIElems[0], "addMaterialA");
			globalDefaultStyle.setImage(customGUIElems[1], "addMaterialB");
			globalDefaultStyle.setImage(customGUIElems[2], "removeMaterialA");
			globalDefaultStyle.setImage(customGUIElems[3], "removeMaterialB");
			globalDefaultStyle.setImage(customGUIElems[4], "horizMirrorA");
			globalDefaultStyle.setImage(customGUIElems[5], "horizMirrorB");
			globalDefaultStyle.setImage(customGUIElems[6], "vertMirrorA");
			globalDefaultStyle.setImage(customGUIElems[7], "vertMirrorB");
			globalDefaultStyle.setImage(customGUIElems[8], "ovrwrtInsA");
			globalDefaultStyle.setImage(customGUIElems[9], "ovrwrtInsB");
			//globalDefaultStyle.setImage(customGUIElems[10], "");
			//globalDefaultStyle.setImage(customGUIElems[11], "");
			globalDefaultStyle.setImage(customGUIElems[12], "paletteDownA");
			globalDefaultStyle.setImage(customGUIElems[13], "paletteDownB");
			globalDefaultStyle.setImage(customGUIElems[14], "paletteUpA");
			globalDefaultStyle.setImage(customGUIElems[15], "paletteUpB");
		}
		{
			Bitmap8Bit[] customGUIElems = loadBitmapSheetFromFile!Bitmap8Bit(getPathToAsset("/system/concreteGUIE3.tga"), 16, 16);
			globalDefaultStyle.setImage(customGUIElems[0], "trashButtonA");
			globalDefaultStyle.setImage(customGUIElems[1], "trashButtonB");
			globalDefaultStyle.setImage(customGUIElems[2], "visibilityButtonA");
			globalDefaultStyle.setImage(customGUIElems[3], "visibilityButtonB");
			globalDefaultStyle.setImage(customGUIElems[4], "newTileLayerButtonA");
			globalDefaultStyle.setImage(customGUIElems[5], "newTileLayerButtonB");
			globalDefaultStyle.setImage(customGUIElems[6], "newSpriteLayerButtonA");
			globalDefaultStyle.setImage(customGUIElems[7], "newSpriteLayerButtonB");
			globalDefaultStyle.setImage(customGUIElems[8], "newTransformableTileLayerButtonA");
			globalDefaultStyle.setImage(customGUIElems[9], "newTransformableTileLayerButtonB");
			globalDefaultStyle.setImage(customGUIElems[10], "importLayerDataButtonA");
			globalDefaultStyle.setImage(customGUIElems[11], "importLayerDataButtonB");
			globalDefaultStyle.setImage(customGUIElems[12], "importMaterialDataButtonA");
			globalDefaultStyle.setImage(customGUIElems[13], "importMaterialDataButtonB");
			globalDefaultStyle.setImage(customGUIElems[14], "paletteButtonA");
			globalDefaultStyle.setImage(customGUIElems[15], "paletteButtonB");
		}
		{
			Bitmap8Bit[] customGUIElems = loadBitmapSheetFromFile!Bitmap8Bit(getPathToAsset("/system/concreteGUIE5.tga"), 16, 16);
			globalDefaultStyle.setImage(customGUIElems[0], "percentButtonA");
			globalDefaultStyle.setImage(customGUIElems[1], "percentButtonB");
			globalDefaultStyle.setImage(customGUIElems[2], "tileButtonA");
			globalDefaultStyle.setImage(customGUIElems[3], "tileButtonB");
			globalDefaultStyle.setImage(customGUIElems[4], "selMoveButtonA");
			globalDefaultStyle.setImage(customGUIElems[5], "selMoveButtonB");
			globalDefaultStyle.setImage(customGUIElems[6], "tilePlacementButtonA");
			globalDefaultStyle.setImage(customGUIElems[7], "tilePlacementButtonB");
			globalDefaultStyle.setImage(customGUIElems[8], "objPlacementButtonA");
			globalDefaultStyle.setImage(customGUIElems[9], "objPlacementButtonB");
			globalDefaultStyle.setImage(customGUIElems[10], "sprtPlacementButtonA");
			globalDefaultStyle.setImage(customGUIElems[11], "sprtPlacementButtonB");
			globalDefaultStyle.setImage(customGUIElems[12], "tileFlagsButtonA");
			globalDefaultStyle.setImage(customGUIElems[13], "tileFlagsButtonB");
			globalDefaultStyle.setImage(customGUIElems[14], "soloButtonA");
			globalDefaultStyle.setImage(customGUIElems[15], "soloButtonB");
		}
		{
			Bitmap8Bit[] customGUIElems = loadBitmapSheetFromFile!Bitmap8Bit(getPathToAsset("/system/concreteGUIE6.tga"), 16, 16);
			globalDefaultStyle.setImage(customGUIElems[0], "colorPickerA");
			globalDefaultStyle.setImage(customGUIElems[1], "colorPickerB");
			globalDefaultStyle.setImage(customGUIElems[2], "addBoxObjectA");
			globalDefaultStyle.setImage(customGUIElems[3], "addBoxObjectB");
			globalDefaultStyle.setImage(customGUIElems[4], "addPolylineObjectA");
			globalDefaultStyle.setImage(customGUIElems[5], "addPolylineObjectB");
			globalDefaultStyle.setImage(customGUIElems[6], "addCompositeTileObjectA");
			globalDefaultStyle.setImage(customGUIElems[7], "addCompositeTileObjectB");
			globalDefaultStyle.setImage(customGUIElems[8], "addSpriteObjectA");
			globalDefaultStyle.setImage(customGUIElems[9], "addSpriteObjectB");
			globalDefaultStyle.setImage(customGUIElems[10], "drawCompositeTileObjectA");
			globalDefaultStyle.setImage(customGUIElems[11], "drawCompositeTileObjectB");
			//globalDefaultStyle.setImage(customGUIElems[12], "importMaterialDataButtonA");
			//globalDefaultStyle.setImage(customGUIElems[13], "importMaterialDataButtonB");
			//globalDefaultStyle.setImage(customGUIElems[14], "paletteButtonA");
			//globalDefaultStyle.setImage(customGUIElems[15], "paletteButtonB");
		}
		globalDefaultStyle.font["dylex10"] = new Fontset!Bitmap8Bit(File(getPathToAsset("../system/dylex-6x10.fnt")), 
				getPathToAsset("../system/"));
		globalDefaultStyle.addChrFormatting(
				new CharacterFormattingInfo!Bitmap8Bit(globalDefaultStyle.getFontset("fixedWidth"), 0x1f, 0, 0, 16, 2), 
				"statusbar");
		globalDefaultStyle.addChrFormatting(
				new CharacterFormattingInfo!Bitmap8Bit(globalDefaultStyle.getFontset("dylex10"), 0x1f, 0, 0, 12, 0), "smallFixed");
		globalDefaultStyle.addChrFormatting(new CharacterFormattingInfo!(Bitmap8Bit)(globalDefaultStyle.getFontset("default"), 
				0x20, FormattingFlags.leftJustify, 0, 15, 2), "property-mandatory");
		globalDefaultStyle.addChrFormatting(new CharacterFormattingInfo!(Bitmap8Bit)(globalDefaultStyle.getFontset("default"), 
				0x21, FormattingFlags.leftJustify, 0, 15, 2), "property-constant");
		globalDefaultStyle.addChrFormatting(new CharacterFormattingInfo!(Bitmap8Bit)(globalDefaultStyle.getFontset("default"), 
				0x22, FormattingFlags.leftJustify, 0, 15, 2), "property-recognized");
		{
			import mapobject;
			BoxObjectDrawer.defChrFormat = new CharacterFormattingInfo!Bitmap8Bit(globalDefaultStyle.getFontset("dylex10"), 
					0x01, 0, 0, 11, 0);
			PolylineObjectDrawer.defChrFormat = BoxObjectDrawer.defChrFormat;
			SpriteObjectName.defChrFormat = BoxObjectDrawer.defChrFormat;
		}
		//wh.initGUI();

		input = new InputHandler();
		//input.ml ~= this;
		input.mouseListener = wh;
		input.inputListener = this;
		input.systemEventListener = this;
		//input.kb ~= KeyBinding(0, SDL_SCANCODE_ESCAPE, 0, "sysesc", Devicetype.KEYBOARD);
		//input.kb ~= configFile.keyBindingList;
		input.addBinding(InputHandler.getSysEscKey, InputBinding(InputHandler.sysescCode));
		configFile.loadBindings(input);
		
		WindowElement.inputHandler = input;
		
		ow ~= new OutputScreen("Pixel Perfect Editor", cast(ushort)(windowSizes[0] * windowSizes[2]), 
				cast(ushort)(windowSizes[1] * windowSizes[3]));

		rasters = new Raster(cast(ushort)windowSizes[0], cast(ushort)windowSizes[1], ow[0], 0, 1);
		ow[0].setMainRaster(rasters);
		rasters.addLayer(windowing, 0);
		rasters.addLayer(bitmapPreview, 1);
		rasters.loadPalette(loadPaletteFromFile(getPathToAsset("../system/concreteGUIE1.tga")));
		rasters.setPaletteIndex(0x00_20, Color(0x00,0xFF,0x00,0xff));
		rasters.setPaletteIndex(0x00_21, Color(0xFF,0x00,0xFF,0xff));
		rasters.setPaletteIndex(0x00_22, Color(0x7F,0x7F,0xFF,0xff));
		wh.setBaseWindow(new TopLevelWindow(windowSizes[0], windowSizes[1], this));
		wh.addBackground(loadBitmapFromFile!Bitmap32Bit(getPathToAsset("../system/background.png")));
		mapClipboard = new MapClipboard(10);
		//openMaterialList();
		//openLayerList();
		//openObjectList();
		//openPropertyList();
	}
	public void menuEvent(Event ev) {
		if (ev.type == EventType.Menu){
			MenuEvent mev = cast(MenuEvent)ev;
			switch (mev.itemSource) {
				case "save":
					onSave();
					break;
				case "saveAs":
					onSaveAs();
					break;
				case "load":
					onLoad();
					break;
				case "newLayer":
					initNewTileLayer();
					break;
				case "new":
					//TileLayerEditor tle = new TileLayerEditor(this);
					//wh.addWindow(tle);
					onNewDocument();
					break;
				case "resizeLayer":
					initResizeLayer();
					break;
				case "undo":
					onUndo();
					break;
				case "redo":
					onRedo();
					break;
				case "exit":
					onQuit();
					break;
				case "layerList":
					openLayerList();
					break;
				case "materialList":
					openMaterialList();
					break;
				case "objlist":
					openObjectList();
					break;
				case "proplist":
					openPropertyList();
					break;
				case "tiledcsvi":
					if (selDoc) {
						if (selDoc.getLayerInfo(selDoc.selectedLayer).type == LayerType.Tile || 
								selDoc.getLayerInfo(selDoc.selectedLayer).type == LayerType.TransformableTile) {
							import pixelperfectengine.concrete.dialogs.filedialog;
							wh.addWindow(new FileDialog("Import layer from CSV", "tiledcsvi", &tiledCSVImport, 
									[FileDialog.FileAssociationDescriptor("Tiled CSV file", ["*.csv"])], "./",));
						}
					}
					break;
				case "tiledcsve":
					if (selDoc) {
						if (selDoc.getLayerInfo(selDoc.selectedLayer).type == LayerType.Tile || 
								selDoc.getLayerInfo(selDoc.selectedLayer).type == LayerType.TransformableTile) {
							import pixelperfectengine.concrete.dialogs.filedialog;
							wh.addWindow(new FileDialog("Export layer as CSV", "tiledcsve", &tiledCSVExport, 
									[FileDialog.FileAssociationDescriptor("Tiled CSV file", ["*.csv"])], "./", true));
						}
					}
					break;
				case "ppebinmapi":
					if (selDoc) {
						if (selDoc.getLayerInfo(selDoc.selectedLayer).type == LayerType.Tile || 
								selDoc.getLayerInfo(selDoc.selectedLayer).type == LayerType.TransformableTile) {
							import pixelperfectengine.concrete.dialogs.filedialog;
							wh.addWindow(new FileDialog("Import layer from MBF", "ppebinmapi", &ppeBinImport, 
									[FileDialog.FileAssociationDescriptor("PixelPerfectEngine map binary file", ["*.mbf"])], "./",));
						}
					}
					break;
				case "ppebinmape":
					if (selDoc) {
						if (selDoc.getLayerInfo(selDoc.selectedLayer).type == LayerType.Tile || 
								selDoc.getLayerInfo(selDoc.selectedLayer).type == LayerType.TransformableTile) {
							import pixelperfectengine.concrete.dialogs.filedialog;
							wh.addWindow(new FileDialog("Export layer as MBF", "ppebinmape", &ppeBinExport, 
									[FileDialog.FileAssociationDescriptor("PixelPerfectEngine map binary file", ["*.mbf"])], "./", true));
						}
					}
					break;
				case "resetLayers":
					if (selDoc) {
						selDoc.outputWindow.clearDisplayLists();
					}
					break;
				case "copy":
					onCopy();
					break;
				case "cut":
					onCut();
					break;
				case "paste":
					onPaste();
					break;
				case "bmfontTool":
					import windows.bmfonttoolkit;
					wh.addWindow(new BMFontToolkit());
					break;
				case "viewgrid":
					onGridToggle();
					break;
				default:
					break;
			}
		}
	}
	private void tiledCSVImport(Event ev) {
		import csvconv : fromCSV;
		try {
			if (selDoc) {
				if (selDoc.getLayerInfo(selDoc.selectedLayer).type == LayerType.Tile || 
						selDoc.getLayerInfo(selDoc.selectedLayer).type == LayerType.TransformableTile) {
					ITileLayer target = cast(ITileLayer)(selDoc.mainDoc.layeroutput[selDoc.selectedLayer]);
					FileEvent fev = cast(FileEvent)ev;
					fromCSV(fev.getFullPath, selDoc);
				}
			}
		} catch (Exception e) {
			wh.message("CSV Import Error!", to!dstring(e.msg));
		}
	}
	private void tiledCSVExport(Event ev) {
		import csvconv : toCSV;
		try {
			if (selDoc) {
				if (selDoc.getLayerInfo(selDoc.selectedLayer).type == LayerType.Tile || 
						selDoc.getLayerInfo(selDoc.selectedLayer).type == LayerType.TransformableTile) {
					ITileLayer target = cast(ITileLayer)(selDoc.mainDoc.layeroutput[selDoc.selectedLayer]);
					FileEvent fev = cast(FileEvent)ev;
					toCSV(fev.getFullPath, target);
				}
			}
		} catch (Exception e) {
			wh.message("CSV Export Error!", to!dstring(e.msg));
		}
	}
	private void ppeBinImport(Event ev) {
		import pixelperfectengine.map.mapdata;
		try {
			if (selDoc) {
				if (selDoc.getLayerInfo(selDoc.selectedLayer).type == LayerType.Tile || 
						selDoc.getLayerInfo(selDoc.selectedLayer).type == LayerType.TransformableTile) {
					FileEvent fev = cast(FileEvent)ev;
					File source = File(fev.getFullPath, "rb");
					MapDataHeader header;
					MappingElement[] map = loadMapFile(source, header);
					selDoc.assignImportedTilemap(map, header.sizeX, header.sizeY);
				}
			}
		} catch (Exception e) {
			wh.message("MBF Import Error!", to!dstring(e.msg));
		}
	}
	private void ppeBinExport(Event ev) {
		import pixelperfectengine.map.mapdata;
		try {
			if (selDoc) {
				if (selDoc.getLayerInfo(selDoc.selectedLayer).type == LayerType.Tile || 
						selDoc.getLayerInfo(selDoc.selectedLayer).type == LayerType.TransformableTile) {
					ITileLayer source = cast(ITileLayer)(selDoc.mainDoc.layeroutput[selDoc.selectedLayer]);
					FileEvent fev = cast(FileEvent)ev;
					File target = File(fev.getFullPath, "wb");
					MapDataHeader header = MapDataHeader(source.getMX, source.getMY);
					saveMapFile(header, source.getMapping, target);
				}
			}
		} catch (Exception e) {
			wh.message("MBF Export Error!", to!dstring(e.msg));
		}
	}
	/**
	 * Called when a keybinding event is generated.
	 * The `id` should be generated from a string, usually the name of the binding.
	 * `code` is a duplicate of the code used for fast lookup of the binding, which also contains other info (deviceID, etc).
	 * `timestamp` is the time lapsed since the start of the program, can be used to measure time between keypresses.
	 * NOTE: Hat events on joysticks don't generate keyReleased events, instead they generate keyPressed events on release.
	 */
	public void keyEvent(uint id, BindingCode code, uint timestamp, bool isPressed) {
		import pixelperfectengine.system.etc : hashCalc;
		switch (id) {
			case hashCalc("copy"):
				if (!isPressed)
					onCopy;
				break;
			case hashCalc("cut"):
				if (!isPressed)
					onCut;
				break;
			case hashCalc("paste"):
				if (!isPressed)
					onPaste;
				break;
			case hashCalc("undo"):
				if (!isPressed)
					onUndo;
				break;
			case hashCalc("redo"):
				if (!isPressed)
					onRedo;
				break;
			case hashCalc("save"):
				if (!isPressed)
					onSave;
				break;
			case hashCalc("saveAs"):
				if (!isPressed)
					onSaveAs;
				break;
			case hashCalc("insert"):
				if (!isPressed){
					if (materialList)
						materialList.ovrwrtIns.toggle();
					else if (selDoc)
						selDoc.voidfill = !selDoc.voidfill;
				}
				break;
			case hashCalc("delArea"):
				if (selDoc && isPressed) 
					selDoc.deleteArea();
				break;
			case hashCalc("palUp"):
				if (isPressed) {
					if (materialList)
						materialList.palUp_onClick(null);
					else if (selDoc)
						selDoc.tileMaterial_PaletteUp;
				}
				break;
			case hashCalc("palDown"):
				if (isPressed) {
					if (materialList)
						materialList.palDown_onClick(null);
					else if (selDoc)
						selDoc.tileMaterial_PaletteDown;
				}
				break;
			case hashCalc("hMirror"):
				if (selDoc && !isPressed) {
					if (materialList)
						materialList.horizMirror.toggle;
					else
						selDoc.tileMaterial_FlipHorizontal;
				}
				break;
			case hashCalc("selFlipHoriz"):
				if (selDoc && !isPressed) {
					selDoc.flipTilesHoriz();
				}
				break;
			case hashCalc("selFlipVert"):
				if (selDoc && !isPressed) {
					selDoc.flipTilesVert();
				}
				break;
			case hashCalc("selMirrorHoriz"):
				if (selDoc && !isPressed) {
					selDoc.selMirrorHoriz();
				}
				break;
			case hashCalc("selMirrorVert"):
				if (selDoc && !isPressed) {
					selDoc.selMirrorVert();
				}
				break;
			case hashCalc("vMirror"):
				if (selDoc && !isPressed) {
					if (materialList)
						materialList.vertMirror.toggle;
					else 
						selDoc.tileMaterial_FlipVertical;
				}
				break;
			case hashCalc("place"):
				if (selDoc && !isPressed)
					selDoc.fillSelectedArea();
				break;
			case hashCalc("nextTile"):
				if (selDoc && isPressed) {
					if (materialList) {
						materialList.nextTile();
					} else {
						selDoc.tileMaterial_Up();
					}
				}
				break;
			case hashCalc("prevTile"):
				if (selDoc && isPressed) {
					if (materialList) {
						materialList.prevTile();
					} else {
						selDoc.tileMaterial_Down();
					}
				}
				break;
			case hashCalc("moveUp"):
				if (selDoc && isPressed)
					selDoc.moveSelection(0, -1);
				break;
			case hashCalc("moveDown"):
				if (selDoc && isPressed)
					selDoc.moveSelection(0, 1);
				break;
			case hashCalc("moveLeft"):
				if (selDoc && isPressed)
					selDoc.moveSelection(-1, 0);
				break;
			case hashCalc("moveRight"):
				if (selDoc && isPressed)
					selDoc.moveSelection(1, 0);
				break;
			case hashCalc("scrollUp"):
				if (selDoc) {
					if (isPressed) 
						selDoc.sYAmount = -1;
					else
						selDoc.sYAmount = 0;
				}
				break;
			case hashCalc("scrollDown"):
				if (selDoc) {
					if (isPressed) 
						selDoc.sYAmount = 1;
					else
						selDoc.sYAmount = 0;
				}
				break;
			case hashCalc("scrollLeft"):
				if (selDoc) {
					if (isPressed) 
						selDoc.sXAmount = 1;
					else
						selDoc.sXAmount = 0;
				}
				break;
			case hashCalc("scrollRight"):
				if (selDoc) {
					if (isPressed) 
						selDoc.sXAmount = -1;
					else
						selDoc.sXAmount = 0;
				}
				break;
			case hashCalc("resetLayers"):
				if (selDoc && !isPressed) {
					selDoc.outputWindow.clearDisplayLists();
				}
				break;
			case hashCalc("nextLayer"):
				if (selDoc && !isPressed) {
					if (layerList)
						layerList.nextLayer();
				}
				break;
			case hashCalc("prevLayer"):
				if (selDoc && !isPressed) {
					if (layerList)
						layerList.prevLayer();
				}
				break;
			case hashCalc("hideLayer"):
				if (selDoc && !isPressed) {
					if (layerList)
						layerList.checkBox_Hide.toggle();
				}
				break;
			case hashCalc("soloLayer"):
				if (selDoc && !isPressed) {
					if (layerList)
						layerList.checkBox_Solo.toggle();
				}
				break;
			case hashCalc("displayGrid"):
				if (!isPressed)
					onGridToggle();
				break;
			default:
				break;
		}
	}
	/**
	 * Called when an axis is being operated.
	 * The `id` should be generated from a string, usually the name of the binding.
	 * `code` is a duplicate of the code used for fast lookup of the binding, which also contains other info (deviceID, etc).
	 * `timestamp` is the time lapsed since the start of the program, can be used to measure time between keypresses.
	 * `value` is the current position of the axis normalized between -1.0 and +1.0 for joysticks, and 0.0 and +1.0 for analog
	 * triggers.
	 */
	public void axisEvent(uint id, BindingCode code, uint timestamp, float value) {

	}
	public void onUndo () {
		if(selDoc !is null){
			selDoc.events.undo;
			selDoc.outputWindow.updateRaster;
		}
	}
	public void onRedo () {
		if(selDoc !is null){
			selDoc.events.redo;
			selDoc.outputWindow.updateRaster;
		}
	}
	public void onLoad () {
		import pixelperfectengine.concrete.dialogs.filedialog;
		FileDialog fd = new FileDialog("Load document","docLoad",&onLoadDialog,[FileDialog.FileAssociationDescriptor(
			"PPE map file", ["*.xmf"])],"./",false);
		wh.addWindow(fd);
	}
	public void onNewDocument () {
		wh.addWindow(new NewDocumentDialog(this));
	}
	public void onLoadDialog (Event ev) {
		import std.utf : toUTF32;
		try {
			FileEvent event = cast(FileEvent)ev;
			selDoc = new MapDocument(event.getFullPath);
			dstring name = toUTF32(selDoc.mainDoc.getName);
			RasterWindow w = new RasterWindow(selDoc.mainDoc.getHorizontalResolution, selDoc.mainDoc.getVerticalResolution, 
					rasters.palette.ptr, name, selDoc);
			selDoc.outputWindow = w;
			selDoc.initSpriteLayers();
			wh.addWindow(w);
			documents[name] = selDoc;
			selDoc.updateLayerList();
			selDoc.updateMaterialList();
			selDoc.updateObjectList();
			selDoc.mainDoc.loadTiles(w);
			selDoc.mainDoc.loadMappingData();
			w.loadLayers();
			w.updateRaster();
		} catch (Exception e) {
			debug writeln(e);
		}
		
	}
	public void onSave () {
		if (selDoc) {
			if (selDoc.filename) {
				try {
					selDoc.mainDoc.save(selDoc.filename);
				} catch (Exception e) {
					debug writeln(e);
				}
			} else {
				onSaveAs();
			}
		}
	}
	public void onSaveAs () {
		import pixelperfectengine.concrete.dialogs.filedialog;
		FileDialog fd = new FileDialog("Save document as","docSave",&onSaveDialog,[FileDialog.FileAssociationDescriptor(
			"PPE map file", ["*.xmf"])],"./",true);
		wh.addWindow(fd);
	}
	public void onSaveDialog(Event ev) {
		import std.path : extension;
		import std.ascii : toLower;
		FileEvent event = cast(FileEvent)ev;
		selDoc.filename = event.getFullPath();
		if(extension(selDoc.filename) != ".xmf"){
			selDoc.filename ~= ".xmf";
		}
		try {
			selDoc.mainDoc.save(selDoc.filename);
		} catch (Exception e) {
			debug writeln(e);
		}
	}
	public void onCopy() {
		if (selDoc !is null) {
			selDoc.copy();
		}
	}
	public void onCut() {
		if (selDoc !is null) {
			selDoc.cut();
		}
	}
	public void onPaste() {
		if (selDoc !is null) {
			selDoc.paste();
		}
	}
	public void onGridToggle() {
		if (selDoc !is null) {
			selDoc.outputWindow.displayGrid = !selDoc.outputWindow.displayGrid;
		}
	}
	public void onQuit(){onExit();}
	public void controllerRemoved(uint ID){}
	public void controllerAdded(uint ID){}
	public void initResizeLayer() {
		//import resizeMap;
		if (selDoc !is null) {
			wh.addWindow(new ResizeMap(selDoc));
		}
	}
	/**
	 * Opens a window to ask the user for the data on the new tile layer
	 */
	public void initNewTileLayer(){
		if (selDoc !is null)
			wh.addWindow(new NewTileLayerDialog(this));
	}
	public void initNewSpriteLayer() {
		import windows.textinputdialog;
		if (selDoc !is null) {
			wh.addWindow(new TextInputDialog(Box.bySize(16, 16, 256, 256), &initNewSpriteLayer_onTextInput, "newSprtLayerName", 
					"Create new sprite layer", "Layer name:"));
		}
	}
	protected void initNewSpriteLayer_onTextInput(Text text) {
		import std.utf : toUTF8;
		newSpriteLayer(toUTF8(text.toDString));
	}
	/**
	 * Opens a window to ask the user for input on materials to be added
	 */
	public void initAddMaterials() {
		import windows.addtiles;
		if (selDoc !is null) {
			if (selDoc.mainDoc.getLayerInfo(selDoc.selectedLayer).type == LayerType.Tile || 
					selDoc.mainDoc.getLayerInfo(selDoc.selectedLayer).type == LayerType.TransformableTile) {
				ITileLayer itl = cast(ITileLayer)selDoc.mainDoc.layeroutput[selDoc.selectedLayer];
				const int tileX = itl.getTileWidth, tileY = itl.getTileHeight;
				wh.addWindow(new AddTiles(this, tileX, tileY));
			} else if (selDoc.mainDoc.getLayerInfo(selDoc.selectedLayer).type == LayerType.Sprite) {
				wh.addWindow(new SprMatCreate(selDoc, selDoc.selectedLayer, this));
			}
		}
	}
	/**
	 * Creates a new tile layer with the given data.
	 *
	 * file: Optional field. If given, it specifies the external file for binary map data. If it specifies an already
	 * existing file, then that file will be loaded. If null, then the map data will be embedded as a BASE64 chunk.
	 */
	public void newTileLayer(int tX, int tY, int mX, int mY, dstring name, string file, bool embed) {
		selDoc.events.addToTop(new CreateTileLayerEvent(selDoc, tX, tY, mX, mY, name, file, embed));
	}
	public void newSpriteLayer(string name) {
		selDoc.events.addToTop(new CreateSpriteLayerEvent(new SpriteLayer(), selDoc, selDoc.nextLayerNumber, name));
	}
	public void setRasterRefresh(){
		rasterRefresh = true;
	}
	public void whereTheMagicHappens() {
		//potential bug/odd behavior: I had to move these from the CTOR to here, as there they couldn't access some resources
		openMaterialList();
		openLayerList();
		openObjectList();
		openPropertyList();
		//rasters.refresh();
		while(!onexit){
			input.test();
			timer.test();
			rasters.refresh();
			if (selDoc) {
				selDoc.contScrollLayer();
			}
		}
		configFile.store();
	}
	public void onExit(){
		import pixelperfectengine.concrete.dialogs.defaultdialog;
		exitDialog=true;
		DefaultDialog dd = new DefaultDialog(Point(10,10), 256, "exitdialog","Exit application", "Are you sure?",
				["Yes","No","Pls save"],["ok","close","save"]);

		dd.output = &confirmExit;
		wh.addWindow(dd);

	}
	private void confirmExit(Event ev) {
		WindowElement we = cast(WindowElement)ev.sender;
		if (we.getSource == "ok") {
			onexit = true;
		}
	}
	/+public void newDocument(){
		NewDocumentDialog ndd = new NewDocumentDialog(input);
		ndd.ie = this;
		wh.addWindow(ndd);
	}+/
	public void createNewDocument(dstring name, int rX, int rY){
		import std.utf : toUTF8;
		MapDocument md = new MapDocument(toUTF8(name), rX, rY);
		RasterWindow w = new RasterWindow(rX, rY, rasters.palette.ptr, name, md);
		md.outputWindow = w;
		wh.addWindow(w);
		documents[name] = md;
		selDoc = md;
	}
	public void openLayerList() {
		if (!layerList) {
			layerList = new LayerList(0, 16, &onLayerListClosed);
			wh.addWindow(layerList);
		}
	}
	private void onLayerListClosed() {
		layerList = null;
	}
	public void openMaterialList() {
		if (!materialList) {
			materialList = new MaterialList(0, 230, &onMaterialListClosed);
			wh.addWindow(materialList);
		}
	}
	private void onMaterialListClosed() {
		materialList = null;
	}
	public void openObjectList() {
		if (!objectList) {
			objectList = new ObjectList(130, 230, &onObjectListClosed);
			wh.addWindow(objectList);
		}
	}
	private void onObjectListClosed() {
		objectList = null;
	}
	public void openPropertyList() {
		if (!propertyList) {
			propertyList = new PropertyList(130, 16, &onPropertyListClosed);
			wh.addWindow(propertyList);
		}
	}
	private void onPropertyListClosed() {
		propertyList = null;
	}
}
