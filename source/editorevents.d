module editorevents;

import document;
import clipboard;

public import pixelperfectengine.concrete.eventchainsystem;
public import pixelperfectengine.graphics.layers;
public import pixelperfectengine.map.mapformat;

import pixelperfectengine.system.file;

import std.stdio;
import std.conv : to;
import sdlang;

pragma(inline, true)
T clamp(T)(T input, const T min, const T max) @nogc @safe pure nothrow {
	if (input >= max) input = max;
	else if (input <= min) input = min;
	return input;
}

public class WriteToMapVoidFill : UndoableEvent {
	ITileLayer target;
	Coordinate area;
	MappingElement me;
	MappingElement[] original;
	public this(ITileLayer target, Coordinate area, MappingElement me){
		this.target = target;
		this.area = area;
		this.me = me;
		//mask.length = area.area;
	}
	public void redo() {
		original.length = 0;
		original.reserve(area.area);
		for (int y = area.top ; y <= area.bottom ; y++) {
			for (int x = area.left ; x <= area.right ; x++) {
				MappingElement o = target.readMapping(x,y);
				original ~= o;
				if (o.tileID == 0xFFFF)
					target.writeMapping(x,y,me);
			}
		}
	}
	public void undo() {
		size_t pos;
		for (int y = area.top ; y <= area.bottom ; y++) {
			for (int x = area.left ; x <= area.right ; x++) {
				target.writeMapping(x,y,original[pos]);
				pos++;
			}
		}
	}
}

public class WriteToMapOverwrite : UndoableEvent {
	ITileLayer target;
	Coordinate area;
	MappingElement me;
	MappingElement[] original;
	public this(ITileLayer target, Coordinate area, MappingElement me){
		this.target = target;
		this.area = area;
		this.me = me;
		//original.length = (area.width + 1) * (area.height + 1);
	}
	public void redo() {
		original.length = 0;
		original.reserve(area.area);
		for(int y = area.top ; y <= area.bottom ; y++){
			for(int x = area.left ; x <= area.right ; x++){
				original ~= target.readMapping(x,y);
				target.writeMapping(x,y,me);
			}
		}
	}
	public void undo() {
		size_t pos;
		for (int y = area.top ; y <= area.bottom ; y++) {
			for (int x = area.left ; x <= area.right ; x++) {
				target.writeMapping(x,y,original[pos]);
				pos++;
			}
		}
	}
}

public class WriteToMapSingle : UndoableEvent {
	ITileLayer target;
	int x;
	int y;
	MappingElement me;
	MappingElement original;
	public this(ITileLayer target, int x, int y, MappingElement me) {
		this.target = target;
		this.x = x;
		this.y = y;
		this.me = me;
	}
	public void redo() {
		original = target.readMapping(x,y);
		target.writeMapping(x,y,me);
		/*debug {
			import std.stdio : writeln;
			writeln("Layer was written at position ", x, ";", y," with values ", target.readMapping(x,y));
		}*/
	}
	public void undo() {
		target.writeMapping(x,y,original);
	}
}

public class CreateTileLayerEvent : UndoableEvent {
	TileLayer creation;
	MapDocument target;
	int tX;
	int tY;
	int mX;
	int mY;
	int pri;
	string name;
	string file;
	bool embed;
	Tag backup;

	public this(MapDocument target, int tX, int tY, int mX, int mY, dstring name, string file, bool embed) {
		import std.utf : toUTF8;
		creation = new TileLayer(tX, tY);
		creation.setRenderingMode(RenderingMode.Copy);
		this.target = target;
		//this.md = md;
		this.tX = tX;
		this.tY = tY;
		this.mX = mX;
		this.mY = mY;
		this.name = toUTF8(name);
		this.file = file;
		this.embed = embed;
		//this.imageReturnFunc = imageReturnFunc;
	}
	public void redo() {
		import std.file : exists, isFile;
		import std.path : baseName;
		import std.utf : toUTF8;
		import pixelperfectengine.system.etc : intToHex;
		if (backup) {	//If a backup exists, then re-add that to the document, then return.
			target.mainDoc.addNewLayer(pri, backup, creation);
			//target.outputWindow.addLayer(pri);
			return;
		}
		try {
			const int nextLayer = target.nextLayerNumber;

			//handle the following instances for mapping:
			//file == null AND embed
			//file == existing file AND embed
			//file == existing file AND !embed
			//file == nonexisting file
			if ((!exists(file) || !isFile(file)) && embed) {	//create new instance for the map by embedding data into the SDLang file
				//selDoc.mainDoc.tld[nextLayer] = new
				MappingElement[] me;
				me.length = mX * mY;
				creation.loadMapping(mX, mY, me);
				target.mainDoc.addNewTileLayer(nextLayer, tX, tY, mX, mY, name, creation);
				target.mainDoc.addEmbeddedMapData(nextLayer, me);
			} else if (!exists(file)) {	//Create empty file
				File f = File(file, "wb");
				MappingElement[] me;
				me.length = mX * mY;
				creation.loadMapping(mX, mY, me);
				target.mainDoc.addNewTileLayer(nextLayer, tX, tY, mX, mY, name, creation);
				saveMapFile(MapDataHeader(mX, mY), me, f);
				target.mainDoc.addMapDataFile(nextLayer, file);
			} else {	//load mapping, embed data into current file if needed
				MapDataHeader mdh;
				MappingElement[] me = loadMapFile(File(file), mdh);
				creation.loadMapping(mdh.sizeX, mdh.sizeY, me);
				target.mainDoc.addNewTileLayer(nextLayer, tX, tY, mX, mY, name, creation);
				if (embed)
					target.mainDoc.addEmbeddedMapData(nextLayer, me);
				else
					target.mainDoc.addMapDataFile(nextLayer, file);
			}

			//handle the following instances for materials:
			//res == image file
			//TODO: check if material resource file has any embedded resource data
			//TODO: enable importing from SDLang map files (*.xmf)
			//TODO: generate dummy tiles for nonexistent material
			/+if (exists(res)) {
				//load the resource file and test if it's the correct size (through an exception)
				source = loadImage(File(res));
				ABitmap[] tilesheet;
				switch (source.getBitdepth()) {
					case 4:
						Bitmap4Bit[] output = loadBitmapSheetFromImage!Bitmap4Bit(source, tX, tY);
						foreach(p; output)
							tilesheet ~= p;
						break;
					case 8:
						Bitmap8Bit[] output = loadBitmapSheetFromImage!Bitmap8Bit(source, tX, tY);
						foreach(p; output)
							tilesheet ~= p;
						break;
					case 16:
						Bitmap16Bit[] output = loadBitmapSheetFromImage!Bitmap16Bit(source, tX, tY);
						foreach(p; output)
							tilesheet ~= p;
						break;
					case 32:
						Bitmap32Bit[] output = loadBitmapSheetFromImage!Bitmap32Bit(source, tX, tY);
						foreach(p; output)
							tilesheet ~= p;
						break;
					default:
						throw new Exception("Unsupported bitdepth!");

				}
				if (tilesheet.length == 0) throw new Exception("No tiles were imported!");
				target.addTileSet(nextLayer, tilesheet);
				target.mainDoc.addsourceFile(nextLayer, res);
				{
					TileInfo[] idList;
					string nameBase = baseName(res);
					for (int id ; id < tilesheet.length ; id++) {
						idList ~= TileInfo(cast(wchar)id, id, nameBase ~ "0x" ~ intToHex(id, 4));
						//writeln(idList);
					}
					target.mainDoc.addTileInfo(nextLayer, idList, res);
				}
				if (source.isIndexed) {
					Color[] palette;
					/*foreach (color ; source.palette) {
						palette ~= Color(color.a, color.r, color.g, color.b);
						debug writeln(color);
					}*/
					auto sourcePalette = source.palette;
					palette.reserve(sourcePalette.length);
					for (ushort i ; i < sourcePalette.length ; i++){
						const auto origC = sourcePalette[i];
						const Color c = Color(origC.a, origC.r, origC.g, origC.b);
						palette ~= c;
					}
					target.mainDoc.addPaletteFile(res, "", cast(int)target.outputWindow.palette.length);
					target.outputWindow.palette = target.outputWindow.palette ~ palette;
					//debug writeln(target.outputWindow.palette);
				}

			}+/
			//target.outputWindow.addLayer(nextLayer);
			target.selectedLayer = nextLayer;
			pri = nextLayer;
			target.updateLayerList();
			target.updateMaterialList();
		} catch (Exception e) {
			writeln(e);
		}
	}
	public void undo() {
		//Just remove the added layer from the layerlists
		//target.outputWindow.removeLayer(pri);
		backup = target.mainDoc.removeLayer(pri);
		target.updateLayerList();
		target.updateMaterialList();
	}
}
public class ResizeTileMapEvent : UndoableEvent {
	MappingElement[] backup, destMap;
	int mX, mY, offsetX, offsetY, newX, newY;
	MapDocument targetDoc;
	int layer;
	bool patternRepeat;
	this(int[6] params, MapDocument targetDoc, int layer, bool patternRepeat) {
		mX = params[0];
		mY = params[1];
		offsetX = params[2];
		offsetY = params[3];
		newX = params[4];
		newY = params[5];
		this.targetDoc = targetDoc;
		this.layer = layer;
		this.patternRepeat = patternRepeat;
	}
	public void redo() {
		//backup current layer data
		ITileLayer targetLayer = cast(ITileLayer)targetDoc.mainDoc.layeroutput[layer];
		backup = targetLayer.getMapping();
		destMap.length = newX * newY;
		//writeln(destMap.length);
		if(patternRepeat) {
			int sX = offsetX % mX, sY = offsetY % mY;
			for (int iY ; iY < newY ; iY++) {
				for (int iX ; iX < newX ; iX++) {
					destMap[iX + (iY * newX)] = backup[sX + (sY * mX)];
					sX++;
					if (sX >= mX) sX = 0;
				}
				sY++;
				if (sY >= mY) sY = 0;
			}
		} else {
			for (int iY ; iY < mY ; iY++) {
				//Do a boundscheck, if falls outside of it do nothing. If inside, copy.
				if (iY + offsetY < newY && iY + offsetY >= 0) {
					for (int iX ; iX < mX ; iX++) {
						//Do a boundscheck, if falls outside of it do nothing. If inside, copy.
						if (iX + offsetX < newX && iX + offsetX >= 0) {
							destMap[iX + offsetX + ((iY + offsetY) * newY)] = backup[iX + (iY * mY)];
						} else if (iX + offsetX >= newX) break;
					}
				} else if (iY + offsetY >= newY) break;
			}
		}
		targetLayer.loadMapping(newX, newY, destMap);
		targetDoc.mainDoc.alterTileLayerInfo(layer, 4, newX);
		targetDoc.mainDoc.alterTileLayerInfo(layer, 5, newY);
	}
	public void undo() {
		ITileLayer targetLayer = cast(ITileLayer)targetDoc.mainDoc.layeroutput[layer];
		targetLayer.loadMapping(mX, mY, backup);
		targetDoc.mainDoc.alterTileLayerInfo(layer, 4, mX);
		targetDoc.mainDoc.alterTileLayerInfo(layer, 5, mY);
	}
}
public class AddTileSheetEvent : UndoableEvent {
	Image source;
	MapDocument targetDoc;
	int layer;
	int paletteOffset;
	int paletteShift;
	string preName, afterName, fileName;
	int numFrom;
	uint numStyle;		///0: decimal, 1: hex, 2: octal
	Tag backup;
	this(Image source, MapDocument targetDoc, int layer, int paletteOffset, int paletteShift, string[3] name, int numFrom, 
			uint numStyle) {
		this.source = source;
		this.targetDoc = targetDoc;
		this.layer = layer;
		this.paletteOffset = paletteOffset;
		this.paletteShift = paletteShift;
		preName = name[0];
		afterName = name[1];
		fileName = name[2];
		this.numFrom = numFrom;
		this.numStyle = numStyle;
	}
	public void redo() {
		import pixelperfectengine.system.etc : intToHex, intToOct;
		//Copy palette if exists (-1 means no palette or do not import palette)
		if (paletteOffset >= 0) {
			//Color[] targetPalette = targetDoc.outputWindow.paletteLocal;
			Color[] importedPalette = loadPaletteFromImage(source);
			assert(importedPalette.length);
			const ushort offset = cast(ushort)(paletteOffset << paletteShift);
			targetDoc.outputWindow.loadPaletteChunk(importedPalette, offset);
			targetDoc.mainDoc.addPaletteFile(fileName, "", paletteOffset << paletteShift, paletteShift);
		}
		if (backup is null) {
			//TODO: check if material resource file has any embedded resource data
			//TODO: enable importing from SDLang map files (*.xmf)
			//TODO: generate dummy tiles for nonexistent material
			
			//load the resource file and test if it's the correct size (through an exception)
			//source = loadImage(File(res));
			ITileLayer itl = cast(ITileLayer)targetDoc.mainDoc.layeroutput[layer];
			const int tX = itl.getTileWidth, tY = itl.getTileHeight;
			ABitmap[] tilesheet;
			switch (source.getBitdepth()) {
				case 4:
					Bitmap4Bit[] output = loadBitmapSheetFromImage!Bitmap4Bit(source, tX, tY);
					foreach(p; output)
						tilesheet ~= p;
					break;
				case 8:
					Bitmap8Bit[] output = loadBitmapSheetFromImage!Bitmap8Bit(source, tX, tY);
					foreach(p; output)
						tilesheet ~= p;
					break;
				case 16:
					Bitmap16Bit[] output = loadBitmapSheetFromImage!Bitmap16Bit(source, tX, tY);
					foreach(p; output)
						tilesheet ~= p;
					break;
				case 32:
					Bitmap32Bit[] output = loadBitmapSheetFromImage!Bitmap32Bit(source, tX, tY);
					foreach(p; output)
						tilesheet ~= p;
					break;
				default:
					throw new Exception("Unsupported bitdepth!");
			}
			if (tilesheet.length == 0) throw new Exception("No tiles were imported!");
			targetDoc.addTileSet(layer, tilesheet);
			targetDoc.mainDoc.addTileSourceFile(layer, fileName, null, 0);
			{
				TileInfo[] idList;
				for (int id ; id < tilesheet.length ; id++) {
					//idList ~= TileInfo(cast(wchar)id, id, nameBase ~ "0x" ~ intToHex(id, 4));
					string tilename = preName;
					switch(numStyle & 0x3) {
						case 1:
							tilename ~= intToHex(id + numFrom, numStyle>>>8);
							break;
						case 2:
							tilename ~= intToOct(id + numFrom, numStyle>>>8);
							break;
						default:
							string num = to!string(id);
							for (int i ; i < (numStyle>>>8) - num.length ; i++) {
								tilename ~= '0';
							}
							tilename ~= num;
							break;
					}
					tilename ~= afterName;
					idList ~= TileInfo(cast(wchar)id, cast(ushort)paletteShift, id, tilename);
					//writeln(idList);
				}
				targetDoc.mainDoc.addTileInfo(layer, idList, fileName, null);
			}			
		} else {
			
		}
	}
	public void undo() {
		//remove palette if exists
		if (paletteOffset >= 0) {
			const ushort offset = cast(ushort)(paletteOffset << paletteShift);
			targetDoc.outputWindow.clearPaletteChunk(cast(ushort)source.palette.length, offset);
		}
		
	}
}
/**
 * Cuts a selected portion of tiles out from a tilelayer.
 */
public class CutFromTileLayerEvent : UndoableEvent {
	ITileLayer target;
	Coordinate area;
	MappingElement[] original;
	public this(ITileLayer target, Coordinate area){
		this.target = target;
		this.area = area;
	}
	public void redo() {
		original.length = 0;
		original.reserve(area.area);
		for (int y = area.top ; y < area.bottom ; y++) {
			for (int x = area.left ; x < area.right ; x++) {
				MappingElement o = target.readMapping(x,y);
				original ~= o;
				target.writeMapping(x,y,MappingElement.init);
			}
		}
	}
	public void undo() {
		size_t pos;
		for (int y = area.top ; y < area.bottom ; y++) {
			for (int x = area.left ; x < area.right ; x++) {
				target.writeMapping(x,y,original[pos]);
				pos++;
			}
		}
	}
}
/**
 * Pastes a copied area to a given tilelayer.
 */
public class PasteIntoTileLayerEvent : UndoableEvent {
	MapClipboard.Item		item;
	ITileLayer				target;
	Point					position;
	MappingElement[]		original;
	bool					overwrite;
	public this (MapClipboard.Item item, ITileLayer target, Point position, bool overwrite = true) {
		this.item = item;
		this.target = target;
		this.position = position;
		this.overwrite = overwrite;
	}

	public void redo() {
		original.length = 0;
		original.reserve(item.width * item.height);
		if (overwrite) {
			for (int y = position.y, y0 ; y0 < item.height ; y++, y0++) {
				for (int x = position.x, x0 ; x0 < item.width ; x++, x0++) {
					MappingElement o = target.readMapping(x,y);
					original ~= o;
					target.writeMapping(x,y,item.map[x0 + (y0 * item.width)]);
				}
			}
		} else {
			for (int y = position.y, y0 ; y0 < item.height ; y++, y0++) {
				for (int x = position.x, x0 ; x0 < item.width ; x++, x0++) {
					MappingElement o = target.readMapping(x,y), n = item.map[x0 + (y0 * item.width)];
					original ~= o;
					if (n.tileID != 0xFFFF)
						target.writeMapping(x,y,n);
				}
			}
		}
	}

	public void undo() {
		size_t pos;
		for (int y = position.y ; y < position.y + item.height ; y++) {
			for (int x = position.x ; x < position.x + item.width ; x++) {
				target.writeMapping(x,y,original[pos]);
				pos++;
			}
		}
	}
}
/**
 * Removes a single tile.
 */
public class RemoveTile : UndoableEvent {
	int id;
	MapDocument targetDoc;
	int layer;
	Tag infobackup;
	ABitmap bitmapbackup;
	string source, dpkSource;
	this (int id, MapDocument targetDoc, int layer) {
		this.id = id;
		this.targetDoc = targetDoc;
		this.layer = layer;
	}

	public void redo() {
		infobackup = targetDoc.mainDoc.removeTile(layer, id, source, dpkSource);
		TileLayer tl = cast(TileLayer)targetDoc.mainDoc.layeroutput[layer];
		bitmapbackup = tl.getTile(cast(wchar)id);
		tl.removeTile(cast(wchar)id);
		targetDoc.updateMaterialList();
	}

	public void undo() {
		targetDoc.mainDoc.addTile(layer, infobackup, source, dpkSource);
		Tag t = targetDoc.mainDoc.getTileSourceTag(layer, source, dpkSource);
		TileLayer tl = cast(TileLayer)targetDoc.mainDoc.layeroutput[layer];
		tl.addTile(bitmapbackup, cast(wchar)id, cast(ubyte)(t.getAttribute!int("palShift")));
		targetDoc.updateMaterialList();
	}
}
/**
 * Renames a single tile
 */
public class RenameTile : UndoableEvent {
	int id;
	MapDocument targetDoc;
	int layer;
	string oldName, newName;

	this (int id, MapDocument targetDoc, int layer, string newName) {
		this.id = id;
		this.targetDoc = targetDoc;
		this.layer = layer;
		this.newName = newName;
	}

	public void redo() {
		oldName = targetDoc.mainDoc.renameTile(layer, id, newName);
		targetDoc.updateMaterialList();
	}

	public void undo() {
		targetDoc.mainDoc.renameTile(layer, id, oldName);
		targetDoc.updateMaterialList();
	}
}
/**
 * Removes a layer.
 */
public class RemoveLayer : UndoableEvent {
	MapDocument targetDoc;
	int layer;
	Tag infobackup;
	Layer databackup;
	this (MapDocument targetDoc, int layer) {
		this.targetDoc = targetDoc;
		this.layer = layer;
	}

	public void redo() {
		infobackup = targetDoc.mainDoc.layerData.remove(layer);
		databackup = targetDoc.mainDoc.layeroutput.remove(layer);
		targetDoc.updateLayerList();
	}

	public void undo() {
		targetDoc.mainDoc.layerData[layer] = infobackup;
		targetDoc.mainDoc.layeroutput[layer] = databackup;
		targetDoc.updateLayerList();
	}
}
/**
 * Renames a layer.
 */
public class RenameLayer : UndoableEvent {
	MapDocument targetDoc;
	int layer;
	string oldName, newName;
	this (MapDocument targetDoc, int layer, string newName) {
		this.targetDoc = targetDoc;
		this.layer = layer;
		this.newName = newName;
	}

	public void redo() {
		try {
			Tag t = targetDoc.mainDoc.layerData[layer];
			oldName = t.values[0].get!string();
			t.values[0] = Value(newName);
		} catch (DOMException e) {
			debug writeln(e);
		} catch (Exception e) {
			debug writeln(e);
		}
		targetDoc.updateLayerList();
	}
	
	public void undo() {
		try {
			Tag t = targetDoc.mainDoc.layerData[layer];
			//newName = t.values[0].get!string();
			t.values[0] = Value(oldName);
		} catch (DOMException e) {
			debug writeln(e);
		} catch (Exception e) {
			debug writeln(e);
		}
		targetDoc.updateLayerList();
	}
}
/**
 * Moves a layer in the priority list.
 */
public class ChangeLayerPriority : UndoableEvent {
	MapDocument targetDoc;
	int layer;
	int newPri;
	this (MapDocument targetDoc, int layer, int newPri) {
		this.targetDoc = targetDoc;
		this.layer = layer;
		this.newPri = newPri;
	}

	public void redo() {
		targetDoc.mainDoc.layerData[newPri] = targetDoc.mainDoc.layerData.remove(layer);
		targetDoc.mainDoc.layeroutput[newPri] = targetDoc.mainDoc.layeroutput.remove(layer);
		targetDoc.mainDoc.layerData[newPri].values[1] = Value(newPri);
		targetDoc.selectedLayer = newPri;
		targetDoc.updateLayerList();
	}
	
	public void undo() {
		targetDoc.mainDoc.layerData[layer] = targetDoc.mainDoc.layerData.remove(newPri);
		targetDoc.mainDoc.layeroutput[layer] = targetDoc.mainDoc.layeroutput.remove(newPri);
		targetDoc.mainDoc.layerData[layer].values[1] = Value(layer);
		targetDoc.selectedLayer = layer;
		targetDoc.updateLayerList();
	}
}
/**
 * Flips all selected tiles horizontally.
 */
public class FlipSelTilesH : UndoableEvent {
	ITileLayer			target;
	Box					area;
	MappingElement[]	backup;

	this (ITileLayer target, Box area) {
		this.target = target;
		this.area = area;
		backup.length = area.area;
		int i;
		for (int y = area.top ; y <= area.bottom ; y++) {
			for (int x = area.left ; x <= area.right ; x++, i++) {
				MappingElement w = target.readMapping(x, y);
				backup[i] = w;
			}
		}
	}

	public void redo() {
		for (int y = area.top ; y <= area.bottom ; y++) {
			for (int x = area.left ; x <= area.right ; x++) {
				MappingElement w = target.readMapping(x, y);
				w.attributes.horizMirror = !w.attributes.horizMirror;
				target.writeMapping(x, y, w);
			}
		}
	}

	public void undo() {
		int i;
		for (int y = area.top ; y <= area.bottom ; y++) {
			for (int x = area.left ; x <= area.right ; x++, i++) {
				target.writeMapping(x, y, backup[i]);
			}
		}
	}
}
/**
 * Flips all selected tiles vertically.
 */
public class FlipSelTilesV : UndoableEvent {
	ITileLayer			target;
	Box					area;
	MappingElement[]	backup;

	this (ITileLayer target, Box area) {
		this.target = target;
		this.area = area;
		backup.length = area.area;
		int i;
		for (int y = area.top ; y <= area.bottom ; y++) {
			for (int x = area.left ; x <= area.right ; x++, i++) {
				MappingElement w = target.readMapping(x, y);
				backup[i] = w;
			}
		}
	}

	public void redo() {
		for (int y = area.top ; y <= area.bottom ; y++) {
			for (int x = area.left ; x <= area.right ; x++) {
				MappingElement w = target.readMapping(x, y);
				w.attributes.vertMirror = !w.attributes.vertMirror;
				target.writeMapping(x, y, w);
			}
		}
	}

	public void undo() {
		int i;
		for (int y = area.top ; y <= area.bottom ; y++) {
			for (int x = area.left ; x <= area.right ; x++, i++) {
				target.writeMapping(x, y, backup[i]);
			}
		}
	}
}
/**
 * Mirrors selection horizontally. (Tile Layer)
 */
public class MirrorSelHTL : UndoableEvent {
	ITileLayer			target;
	Box					area;
	MappingElement[]	backup;

	this (ITileLayer target, Box area) {
		this.target = target;
		this.area = area;
		int i;
		backup.length = area.area;
		for (int y = area.top ; y <= area.bottom ; y++) {
			for (int x = area.left ; x <= area.right ; x++, i++) {
				backup[i] = target.readMapping(x, y);
			}
		}
	}

	public void redo() {
		for (int y0 = area.top ; y0 <= area.bottom ; y0++) {
			for (int x0 = area.left, x1 = area.right ; x0 < x1 ; x0++, x1--) {
				MappingElement w = target.readMapping(x0, y0);
				target.writeMapping(x0, y0, target.readMapping(x1, y0));
				target.writeMapping(x1, y0, w);
			}
		}
	}

	public void undo() {
		int i;
		for (int y = area.top ; y <= area.bottom ; y++) {
			for (int x = area.left ; x <= area.right ; x++, i++) {
				target.writeMapping(x, y, backup[i]);
			}
		}
	}
}
/**
 * Mirrors selection vertically. (Tile Layer)
 */
public class MirrorSelVTL : UndoableEvent {
	ITileLayer			target;
	Box					area;
	MappingElement[]	backup;

	this (ITileLayer target, Box area) {
		this.target = target;
		this.area = area;
		int i;
		backup.length = area.area;
		for (int y = area.top ; y <= area.bottom ; y++) {
			for (int x = area.left ; x <= area.right ; x++, i++) {
				backup[i] = target.readMapping(x, y);
			}
		}
	}

	public void redo() {
		for (int y0 = area.top, y1 = area.bottom ; y0 < y1 ; y0++, y1--) {
			for (int x0 = area.left ; x0 <= area.right ; x0++) {
				MappingElement w = target.readMapping(x0, y0);
				target.writeMapping(x0, y0, target.readMapping(x0, y1));
				target.writeMapping(x0, y1, w);
			}
		}
	}

	public void undo() {
		int i;
		for (int y = area.top ; y <= area.bottom ; y++) {
			for (int x = area.left ; x <= area.right ; x++, i++) {
				target.writeMapping(x, y, backup[i++]);
			}
		}
	}
}
/**
 * Mirrors selection both horizontally and vertically. (Tile Layer)
 */
public class MirrorSelBTL : UndoableEvent {
	ITileLayer			target;
	Box					area;
	MappingElement[]	backup;

	this (ITileLayer target, Box area) {
		this.target = target;
		this.area = area;
		int i;
		backup.length = area.area;
		for (int y = area.top ; y <= area.bottom ; y++) {
			for (int x = area.left ; x <= area.right ; x++, i++) {
				backup[i] = target.readMapping(x, y);
			}
		}
	}

	public void redo() {
		for (int y0 = area.top, y1 = area.bottom ; y0 < y1 ; y0++, y1--) {
			for (int x0 = area.left, x1 = area.right ; x0 < x1 ; x0++, x1--) {
				MappingElement w = target.readMapping(x0, y0);
				target.writeMapping(x0, y0, target.readMapping(x1, y1));
				target.writeMapping(x1, y1, w);
			}
		}
	}

	public void undo() {
		int i;
		for (int y = area.top ; y <= area.bottom ; y++) {
			for (int x = area.left ; x <= area.right ; x++, i++) {
				target.writeMapping(x, y, backup[i]);
			}
		}
	}
}
/**
 * Imports mapping data to a layer.
 */
public class ImportLayerData : UndoableEvent {
	ITileLayer target;
	Tag dataTarget;
	MappingElement[] newData;
	MappingElement[] backup;
	int width, height;
	int buw, buh;

	this(ITileLayer target, Tag dataTarget, MappingElement[] newData, int width, int height) {
		this.target = target;
		this.dataTarget = dataTarget;
		this.newData = newData;
		this.width = width;
		this.height = height;
		buw = target.getMX();
		buh = target.getMY();
		backup = target.getMapping();
	}

	public void redo() {
		dataTarget.values[4] = Value(width);
		dataTarget.values[5] = Value(height);
		target.loadMapping(width, height, newData);
	}

	public void undo() {
		dataTarget.values[4] = Value(buw);
		dataTarget.values[5] = Value(buh);
		target.loadMapping(buw, buh, backup);
	}
}
public class MapObjectPlacementEvent : UndoableEvent {
	Tag target;
	MapObject obj;
	MapDocument doc;
	public this (Tag target, MapObject obj, MapDocument doc) {
		this.target = target;
		this.obj = obj;
		this.doc = doc;
	}
	public void redo() {
		target.add(obj.serialize());
		doc.updateObjectList();
	}

	public void undo() {
		try {
			foreach (Tag key; target.namespaces["Object"].tags) {
				if (key.values[1].get!int == obj.pID) {
					key.remove;
				}
			}
		} catch (Exception e) {}
		doc.updateObjectList();
	}
}
public class ObjectRemovalEvent : UndoableEvent {
	MapDocument doc;
	int layerID;
	int objID;
	Tag backup;
	public this (MapDocument doc, int layerID, int objID) {
		this.doc = doc;
		this.layerID = layerID;
		this.objID = objID;
	}
	public void redo() {
		backup = doc.mainDoc.removeObjectFromLayer(layerID, objID);
		if (backup.name == "Sprite") {
			SpriteLayer sl = cast(SpriteLayer)doc.mainDoc.layeroutput[layerID];
			if (sl !is null) {
				sl.removeSprite(objID);
			}
		}
		doc.updateObjectList();
	}

	public void undo() {
		doc.mainDoc.addObjectToLayer(layerID, backup);
		if (backup.name == "Sprite") {
			SpriteLayer sl = cast(SpriteLayer)doc.mainDoc.layeroutput[layerID];
			if (sl !is null) {
				SpriteObject so = new SpriteObject(backup, layerID);
				sl.addSprite(doc.sprtResMan[layerID][so.ssID], so.pID, so.x, so.y, so.palSel, so.palShift, so.masterAlpha, 
						so.scaleHoriz, so.scaleVert, so.rendMode);
			}
		}
		doc.updateObjectList();
	}
}
public class ObjectPropertyAddEvent : UndoableEvent {
	MapObject obj;
	Tag property;
	MapDocument doc;
	public this (string name, string val, MapObject obj, MapDocument doc) {
		import std.string;
		this.obj = obj;
		if (isNumeric(val)) {
			property = new Tag(null, name, [Value(to!double(val))]);
		} else {
			property = new Tag(null, name, [Value(val)]);
		}
	}
	public void redo() {
		obj.mainTag.add(property);
	}

	public void undo() {
		property.remove();
	}
}
public class ObjectPropertyEditEvent : UndoableEvent {
	MapObject obj;
	Tag oldVal, newVal;
	MapDocument doc;
	public this (string name, string val, MapObject obj, MapDocument doc) {
		import std.string;
		this.obj = obj;
		if (isNumeric(val)) {
			newVal = new Tag(null, name, [Value(to!double(val))]);
		} else {
			newVal = new Tag(null, name, [Value(val)]);
		}
		oldVal = obj.mainTag.getTag(name);
	}
	public void redo() {
		oldVal.remove;
		obj.mainTag.add(newVal);
	}

	public void undo() {
		newVal.remove;
		obj.mainTag.add(oldVal);
	}
}
public class ObjectPropertyRemoveEvent : UndoableEvent {
	string propertyName;
	Tag backup;
	MapObject obj;
	MapDocument doc;
	public this (string name, MapObject obj, MapDocument doc) {
		this.obj = obj;
		propertyName = name;
		backup = this.obj.mainTag.getTag(name);
	}
	public void redo() {
		backup.remove();
	}

	public void undo() {
		obj.mainTag.add(backup);
	}
}
public class CreateSpriteLayerEvent : UndoableEvent {
	SpriteLayer creation;
	MapDocument target;
	int pri;
	string name;
	Tag backup;

	this(SpriteLayer creation, MapDocument target, int pri, string name) {
		this.creation = creation;
		this.target = target;
		this.pri = pri;
		this.name = name;
	}

	public void redo() {
		if (backup) {
			target.mainDoc.addNewLayer(pri, backup, creation);
		} else {
			target.mainDoc.addNewLayer(pri, new Tag("Layer", "Sprite", [Value(name), Value(pri)]), creation);
		}
		target.updateLayerList();
	}

	public void undo() {
		backup = target.mainDoc.removeLayer(pri);
		target.updateLayerList();
	}
}
public class SpriteObjectPlacementEvent : UndoableEvent {
	MapDocument doc;
	int layer;
	int pri;
	int matID;
	string name;
	int x;
	int y;
	int horizScale;
	int vertScale;
	int palSel;
	int alpha;
	RenderingMode rendMode;
	Tag backup;

	this(MapDocument doc, int layer, int pri, int matID, string name, int x, int y, int horizScale, int vertScale, 
			int palSel, int alpha, RenderingMode rendMode) {
		this.doc = doc;
		this.layer = layer;
		this.pri = pri;
		this.matID = matID;
		this.name = name;
		this.x = x;
		this.y = y;
		this.horizScale = horizScale;
		this.vertScale = vertScale;
		this.palSel = palSel;
		this.alpha = alpha;
		this.rendMode = rendMode;
	}

	public void redo() {
		SpriteLayer sl = cast(SpriteLayer)doc.mainDoc.layeroutput[layer];
		if (sl !is null) {
			Tag layerInfo = doc.mainDoc.layerData[layer];
			ubyte palShift;
			MapObject mo;
			if (backup is null) {
				//First get the filename, then look if there's a palette file with that name, and get the palette shift attribute.
				//A bit convoluted method, and I still haven't implemented shared resources and BOM files.
				try {
					string filename;
					foreach (Tag t0 ; layerInfo.namespaces["File"].tags) {
						if (t0.name == "SpriteSource") {
							if (t0.getValue!int() == matID) {
								filename = t0.getValue!string();
								goto filenameFound;
							}
						} else if (t0.name == "SpriteSheet") {
							Tag t1 = t0.getTag("SheetData");
							if (t1 !is null) {
								foreach (Tag t2 ; t1.tags) {
									if (t2.values[0].get!int == matID) {
										filename = t0.getValue!string();
										goto filenameFound;
									}
								}
							}
						}
					}
					filenameFound:
					foreach (Tag t0 ; layerInfo.namespaces["File"].tags) {
						if (t0.name == "Palette") {
							if (t0.expectValue!string == filename) {
								palShift = cast(ubyte)t0.getAttribute!int("palShift");
							}
						}
					}
				} catch (Exception e) {
					
				}
				mo = new SpriteObject(pri, layer, name, matID, x, y, horizScale, vertScale, rendMode, cast(ushort)palSel, palShift, 
						cast(ubyte)alpha);
			} else {
				mo = new SpriteObject(backup, layer);
				palShift = cast(ubyte)backup.getAttribute!int("palShift");
			}
			sl.addSprite(doc.sprtResMan[layer][matID], pri, x, y, cast(ushort)palSel, palShift, cast(ubyte)alpha, horizScale, 
					vertScale, rendMode);
			doc.mainDoc.addObjectToLayer(layer, mo.serialize);
		}
	}

	public void undo() {
		SpriteLayer sl = cast(SpriteLayer)doc.mainDoc.layeroutput[layer];
		if (sl !is null) {
			sl.removeSprite(pri);
			backup = doc.mainDoc.removeObjectFromLayer(layer, pri);
		}
	}
}

public class AddSpriteSheetEvent : UndoableEvent {
	MapDocument doc;
	int layer;
	int palOffset;
	int palShift;
	string fileSource;
	Box[] spriteCoords;
	int[] id;
	string[] name;
	Tag t;
	public this(MapDocument doc, int layer, int palOffset, int palShift, string fileSource, Box[] spriteCoords, int[] id, 
			string[] name) {
		this.doc = doc;
		this.layer = layer;
		this.palOffset = palOffset;
		this.palShift = palShift;
		this.fileSource = fileSource;
		this.spriteCoords = spriteCoords;
		this.id = id;
		this.name = name;
		assert(spriteCoords.length == id.length || !spriteCoords.length);
		assert(name.length == id.length);
	}

	public void redo() {
		Image imgSrc = loadImage(File(fileSource));
		if (!spriteCoords.length || spriteCoords.length == 1) {
			Attribute[] attr;
			if (name[0].length)
				attr ~= new Attribute("name", Value(name[0]));
			if (spriteCoords.length == 1) {
				attr ~= new Attribute("horizOffset", Value(spriteCoords[0].left));
				attr ~= new Attribute("vertOffset", Value(spriteCoords[0].top));
				attr ~= new Attribute("width", Value(spriteCoords[0].width));
				attr ~= new Attribute("height", Value(spriteCoords[0].height));
			}
			t = new Tag("File", "SpriteSource", [Value(id[0]), Value(fileSource)], attr);
		} else {
			t = new Tag("File", "SpriteSheet", [Value(fileSource)]);
			Tag t0 = new Tag(t, null, "SheetData");

			for (int i ; i < spriteCoords.length ; i++) {
				Attribute[] attr;
				if (name[i].length) {
					attr ~= new Attribute("name", Value(name[i]));
				}
				new Tag(t0, null, null, [Value(id[i]), Value(spriteCoords[i].left), Value(spriteCoords[i].top), 
						Value(spriteCoords[i].width), Value(spriteCoords[i].height)]);
				switch (imgSrc.getBitdepth) {
					case 2:
						doc.sprtResMan[layer][id[i]] = loadBitmapSliceFromImage!Bitmap2Bit(imgSrc, spriteCoords[i].left, 
								spriteCoords[i].top, clamp(spriteCoords[i].width, 0, imgSrc.width), 
								clamp(spriteCoords[i].height, 0, imgSrc.height));
						break;
					case 4:
						doc.sprtResMan[layer][id[i]] = loadBitmapSliceFromImage!Bitmap4Bit(imgSrc, spriteCoords[i].left, 
								spriteCoords[i].top, clamp(spriteCoords[i].width, 0, imgSrc.width), 
								clamp(spriteCoords[i].height, 0, imgSrc.height));
						break;
					case 8:
						doc.sprtResMan[layer][id[i]] = loadBitmapSliceFromImage!Bitmap8Bit(imgSrc, spriteCoords[i].left, 
								spriteCoords[i].top, clamp(spriteCoords[i].width, 0, imgSrc.width), 
								clamp(spriteCoords[i].height, 0, imgSrc.height));
						break;
					case 16:
						doc.sprtResMan[layer][id[i]] = loadBitmapSliceFromImage!Bitmap16Bit(imgSrc, spriteCoords[i].left, 
								spriteCoords[i].top, clamp(spriteCoords[i].width, 0, imgSrc.width), 
								clamp(spriteCoords[i].height, 0, imgSrc.height));
						break;
					default:
						doc.sprtResMan[layer][id[i]] = loadBitmapSliceFromImage!Bitmap32Bit(imgSrc, spriteCoords[i].left, 
								spriteCoords[i].top, clamp(spriteCoords[i].width, 0, imgSrc.width), 
								clamp(spriteCoords[i].height, 0, imgSrc.height));
						break;
				}
			}
		}
		if (imgSrc.palette !is null) {
			doc.outputWindow.loadPaletteChunk(loadPaletteFromImage(imgSrc), cast(ushort)palOffset);
			Attribute[] attr;
			if (palOffset) {
				attr ~= new Attribute("offset", Value(palOffset));
			}
			if (palShift > 0) {
				attr ~= new Attribute("palShift", Value(palShift));
			}
			doc.mainDoc.layerData[layer].add(new Tag("File", "Palette", [Value(fileSource)], attr));
		}
		doc.mainDoc.layerData[layer].add(t);
	}

	public void undo() {
		foreach (int i; id) {
			doc.sprtResMan[layer].remove(i);
			t.remove();
		}
	}
}
public class RemoveSpriteMaterialEvent : UndoableEvent {
	Tag backup;
	Tag parent;
	ABitmap bitmapBackup;
	MapDocument target;
	int layerID;
	int materialID;

	this (MapDocument target, int layerID, int materialID) {
		this.target = target;
		this.layerID = layerID;
		this.materialID = materialID;
	}

	public void redo() {
		Tag t = target.mainDoc.layerData[layerID];
		try {
			foreach (Tag t0 ; t.namespaces["File"].tags) {
				switch (t0.name) {
					case "SpriteSource":
						if (t0.values[0].get!int == layerID) {
							backup = t0.remove();
							bitmapBackup = target.sprtResMan[layerID][materialID];
							target.sprtResMan[layerID].remove(materialID);
							return;
						}
						break;
					case "SpriteSheet":
						foreach (Tag t1 ; t0.tags) {
							if (t1.values[0].get!int == layerID) {
								parent = t0;
								backup = t1.remove();
								bitmapBackup = target.sprtResMan[layerID][materialID];
								target.sprtResMan[layerID].remove(materialID);
								return;
							}
						}
						break;
					default:
						
						break;
				}
			}
		} catch (Exception e) {
		}
	}

	public void undo() {
		if (parent is null) {
			target.mainDoc.layerData[layerID].add(backup);
		} else {
			parent.add(backup);
		}
		target.sprtResMan[layerID][materialID] = bitmapBackup;
	}
}