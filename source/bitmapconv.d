module bitmapconv;

import pixelperfectengine.map.mapdata;
import pixelperfectengine.map.mapformat;
import pixelperfectengine.graphics.layers;
import pixelperfectengine.system.exc;
import pixelperfectengine.system.etc;
import dimage.base;

import document;
import std.stdio;
import std.conv : to;

/**
 * Converts a bitmap image to a tile layer's mapping layout.
 * Params:
 *   source = the image source for the bitmap.
 *   dest = the target mapdocument.
 */
public void fromBitmap(Image source, MapDocument dest) @trusted {
	MappingElement[] nativeMap;
	const int width = source.width, height = source.height;
	nativeMap.reserve(width * height);
	switch (source.getPixelFormat) {
	case PixelFormat.Grayscale8Bit, PixelFormat.Indexed8Bit:
		IImageData id = source.imageData;
		for (int y ; y < height ; y++) {
			for (int x ; x < width ; x++) {
				nativeMap ~= MappingElement(id.raw()[x + (y * width)]);
			}
		}
		break;
	case PixelFormat.Grayscale16Bit:
		MonochromeImageData!ushort id = cast(MonochromeImageData!ushort)source.imageData;
		for (int y ; y < height ; y++) {
			for (int x ; x < width ; x++) {
				nativeMap ~= MappingElement(id[x, y]);
			}
		}
		break;
	case PixelFormat.Indexed4Bit:
		IndexedImageData4Bit id = cast(IndexedImageData4Bit)source.imageData;
		for (int y ; y < height ; y++) {
			for (int x ; x < width ; x++) {
				nativeMap ~= MappingElement(id[x, y]);
			}
		}
		break;
	case PixelFormat.Indexed2Bit:
		IndexedImageData2Bit id = cast(IndexedImageData2Bit)source.imageData;
		for (int y ; y < height ; y++) {
			for (int x ; x < width ; x++) {
				nativeMap ~= MappingElement(id[x, y]);
			}
		}
		break;
	case PixelFormat.Indexed1Bit:
		IndexedImageData1Bit id = cast(IndexedImageData1Bit)source.imageData;
		for (int y ; y < height ; y++) {
			for (int x ; x < width ; x++) {
				nativeMap ~= MappingElement(id[x, y]);
			}
		}
		break;
	case PixelFormat.Grayscale4Bit:
		MonochromeImageData4Bit id = cast(MonochromeImageData4Bit)source.imageData;
		for (int y ; y < height ; y++) {
			for (int x ; x < width ; x++) {
				nativeMap ~= MappingElement(id[x, y]);
			}
		}
		break;
	case PixelFormat.Grayscale2Bit:
		MonochromeImageData2Bit id = cast(MonochromeImageData2Bit)source.imageData;
		for (int y ; y < height ; y++) {
			for (int x ; x < width ; x++) {
				nativeMap ~= MappingElement(id[x, y]);
			}
		}
		break;
	case PixelFormat.Grayscale1Bit:
		MonochromeImageData1Bit id = cast(MonochromeImageData1Bit)source.imageData;
		for (int y ; y < height ; y++) {
			for (int x ; x < width ; x++) {
				nativeMap ~= MappingElement(id[x, y]);
			}
		}
		break;
	default:
		throw new BitmapImportException("Format error!");
	}
	dest.assignImportedTilemap(nativeMap, width, height);
}

/**
 * Thrown on import errors.
 */
public class BitmapImportException : PPEException {
	///
	@nogc @safe pure nothrow this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null)
    {
        super(msg, file, line, nextInChain);
    }
	///
    @nogc @safe pure nothrow this(string msg, Throwable nextInChain, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line, nextInChain);
    }
}