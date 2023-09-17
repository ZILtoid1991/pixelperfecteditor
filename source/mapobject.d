module mapobject;

import pixelperfectengine.graphics.common;
import pixelperfectengine.graphics.text;
import pixelperfectengine.graphics.fontsets;
import pixelperfectengine.graphics.bitmap;
import pixelperfectengine.graphics.draw;
import pixelperfectengine.map.mapformat;
import pixelperfectengine.system.etc : min, max, clamp;
import CPUblit.composing.blitter;
import CPUblit.composing.specblt;
import CPUblit.colorlookup;

/** 
 * Implements drawable objects on the screen.
 */
public interface DrawableObject {
	/** 
	 * Draws the object to the screen.
	 * Params:
	 *   dest = Target framebuffer.
	 *   sX = Horizontal scrolling.
	 *   sY = Vertical scrolling.
	 *   rW = Raster width.
	 *   rH = Raster height.
	 *   offsetX = Skipped pixels at the left hand side.
	 *   pitch = Total width of the target framebuffer in pixels, including padding.
	 */
	public void draw(Color[] dest, int sX, int sY, int rW, int rH, const int offsetX, const int pitch);
	/** 
	 * Checks if the object on the screen.
	 * Params:
	 *   sX = Horizontal scrolling.
	 *   sY = Vertical scrolling.
	 *   rW = Raster width.
	 *   rH = Raster height.
	 * Returns: True if the object is on the screen, false otherwise.
	 */
	public bool isOnDisplay(int sX, int sY, int rW, int rH);
	/// Returns the priority ID of the underlying object.
	public @property int pID() @nogc @safe pure nothrow const;
}
/** 
 * Implements box object display data.
 */
public class BoxObjectDrawer : DrawableObject {
	BoxObject		base;
	/// Contains the generated text from the name of the object.
	Bitmap32Bit		text;
	Text			name;
	/// Global character formatting of the text, minus for the color, which is unique to each instance
	static CharacterFormattingInfo!Bitmap8Bit	defChrFormat;
	public this (BoxObject base, CharacterFormattingInfo!Bitmap8Bit cF = null) {
		import std.utf : toUTF32;
		this.base = base;
		name = new Text(toUTF32(base.name), cF !is null ? cF : defChrFormat);
		BitmapDrawer bd = new BitmapDrawer(name.getWidth, name.formatting.font.size * 2);
		bd.drawSingleLineText(Box.bySize(0,0,bd.output.width,bd.output.height), name, 0, 0);
		Color[2] palette;
		palette[1] = base.color;
		text = new Bitmap32Bit(bd.output.width, bd.output.height);
		colorLookup(bd.output.getPtr, text.getPtr, palette.ptr, text.width * text.height);
	}
	public void draw(Color[] dest, int sX, int sY, int rW, int rH, const int offsetX, const int pitch) {
		//Use this until CPUblit is updated on the engine side
		import CPUblit.drawing.line : drawLine;
		Box screenPos = base.position;
		Color displayColor = base.color;
		screenPos.relMove(sX * -1, sY * -1);
		int x0 = screenPos.left, y0 = screenPos.top, x1 = screenPos.right, y1 = screenPos.bottom;
		x0 = max(0, x0);
		x0 = min(rW - 1, x0);
		x1 = max(0, x1);
		x1 = min(rW - 1, x1);
		y0 = max(0, y0);
		y0 = min(rH - 2, y0);
		y1 = max(0, y1);
		y1 = min(rH - 2, y1);
		if (screenPos.left >= 0) {
			drawLine(x0 + offsetX, y0, x0 + offsetX, y1, displayColor, dest, pitch);
		}
		if (screenPos.right < rW) {
			drawLine(x1 + offsetX, y0, x1 + offsetX, y1, displayColor, dest, pitch);
		}
		if (screenPos.top >= 0) {
			drawLine(x0 + offsetX, y0, x1 + offsetX, y0, displayColor, dest, pitch);
		}
		if (screenPos.bottom < rH) {
			drawLine(x0 + offsetX, y1, x1 + offsetX, y1, displayColor, dest, pitch);
		}
		const int textWidth = x0 + 1 + text.width < rW ? text.width : rW - x0 - 1;
		assert(textWidth <= text.width);
		const int textHeight = y0 + text.height < rH ? text.height : rH - y0 - 2;
		assert(textHeight <= text.height);
		for (int y ; y < textHeight ; y++) {
			blitter(cast(uint*)text.getPtr + (y * text.width), cast(uint*)dest.ptr + ((y + y0 + 1) * pitch) + x0 + 2, textWidth);
		}
	}
	public bool isOnDisplay(int sX, int sY, int rW, int rH) {
		Box screen = Box.bySize(sX, sY, rW, rH);
		return screen.isBetween(base.position.cornerUL) || screen.isBetween(base.position.cornerUR) || 
				screen.isBetween(base.position.cornerLL) || screen.isBetween(base.position.cornerLR);
	}
	/// Returns the priority ID of the underlying object.
	public @property int pID() @nogc @safe pure nothrow const {
		return base.pID;
	}
}
public class SpriteObjectName : DrawableObject {
	SpriteObject	base;
	/// Contains the generated text from the name of the object.
	Bitmap32Bit		text;
	Text			name;
	/// Global character formatting of the text, minus for the color, which is unique to each instance
	static CharacterFormattingInfo!Bitmap8Bit	defChrFormat;

	public this(SpriteObject base, CharacterFormattingInfo!Bitmap8Bit cF = null) {
		import std.utf : toUTF32;
		this.base = base;
		name = new Text(toUTF32(base.name), cF !is null ? cF : defChrFormat);
		BitmapDrawer bd = new BitmapDrawer(name.getWidth, name.formatting.font.size * 2);
		bd.drawSingleLineText(Box.bySize(0,0,bd.output.width,bd.output.height), name, 0, 0);
		Color[2] palette;
		palette[1] = Color(0xFF, 0x00, 0x00, 0x00);
		text = new Bitmap32Bit(bd.output.width, bd.output.height);
		colorLookup(bd.output.getPtr, text.getPtr, palette.ptr, text.width * text.height);
	}

	public void draw(Color[] dest, int sX, int sY, int rW, int rH, const int offsetX, const int pitch) {
		Box screenPos = Box.bySize(base.x, base.y, text.width, text.height);
		Color displayColor = Color(0xFF,0xFF,0xFF,0xFF);
		screenPos.relMove(sX * -1, sY * -1);
		int x0 = screenPos.left, y0 = screenPos.top, x1 = screenPos.right, y1 = screenPos.bottom;
		x0 = max(0, x0);
		x0 = min(rW - 1, x0);
		x1 = max(0, x1);
		x1 = min(rW - 1, x1);
		y0 = max(0, y0);
		y0 = min(rH - 2, y0);
		y1 = max(0, y1);
		y1 = min(rH - 2, y1);
		/* if (screenPos.left >= 0) {
			drawLine(x0 + offsetX, y0, x0 + offsetX, y1, displayColor, dest, pitch);
		}
		if (screenPos.right < rW) {
			drawLine(x1 + offsetX, y0, x1 + offsetX, y1, displayColor, dest, pitch);
		}
		if (screenPos.top >= 0) {
			drawLine(x0 + offsetX, y0, x1 + offsetX, y0, displayColor, dest, pitch);
		}
		if (screenPos.bottom < rH) {
			drawLine(x0 + offsetX, y1, x1 + offsetX, y1, displayColor, dest, pitch);
		} */
		const int textWidth = x0 + 1 + text.width < rW ? text.width : rW - x0 - 1;
		assert(textWidth <= text.width);
		const int textHeight = y0 + text.height < rH ? text.height : rH - y0 - 2;
		assert(textHeight <= text.height);
		for (int y ; y < textHeight ; y++) {
			xorBlitter(cast(uint*)text.getPtr + (y * text.width), cast(uint*)dest.ptr + ((y + y0 + 1) * pitch) + x0 + 2, 
					textWidth);
		}
	}

	public bool isOnDisplay(int sX, int sY, int rW, int rH) {
		Box screen = Box.bySize(sX, sY, rW, rH);
		Box textPos = Box.bySize(base.x, base.y, text.width, text.height);
		return screen.isBetween(textPos.cornerUL) || screen.isBetween(textPos.cornerUR) || 
				screen.isBetween(textPos.cornerLL) || screen.isBetween(textPos.cornerLR);
	}

	public @property int pID() @nogc @safe pure nothrow const {
		return base.pID;
	}
}
public class PolylineObjectDrawer : DrawableObject {
	PolylineObject	base;
	Bitmap32Bit		text;
	Text			name;
	static CharacterFormattingInfo!Bitmap8Bit	defChrFormat;
	public this (PolylineObject base, CharacterFormattingInfo!Bitmap8Bit cF = null) {
		import std.utf : toUTF32;
		this.base = base;
		name = new Text(toUTF32(base.name), cF !is null ? cF : defChrFormat);
		BitmapDrawer bd = new BitmapDrawer(name.getWidth, name.formatting.font.size * 2);
		bd.drawSingleLineText(Box.bySize(0,0,bd.output.width,bd.output.height), name, 0, 0);
		Color[2] palette;
		palette[1] = base.color(0);
		text = new Bitmap32Bit(bd.output.width, bd.output.height);
		colorLookup(bd.output.getPtr, text.getPtr, palette.ptr, text.width * text.height);
	}
	public void draw(Color[] dest, int sX, int sY, int rW, int rH, const int offsetX, const int pitch) {
		// TODO: implement
	}

	public bool isOnDisplay(int sX, int sY, int rW, int rH) {
		return bool.init; // TODO: implement
	}
	/// Returns the priority ID of the underlying object.
	public @property int pID() @nogc @safe pure nothrow const {
		return base.pID;
	}
}