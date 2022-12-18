module boxobject;

import pixelperfectengine.graphics.common;
import pixelperfectengine.graphics.text;
import pixelperfectengine.graphics.fontsets;
import pixelperfectengine.graphics.bitmap;
import pixelperfectengine.graphics.draw;
import pixelperfectengine.map.mapformat;
import pixelperfectengine.system.etc : min, max, clamp;
import CPUblit.composing.copy;
import CPUblit.colorlookup;

/** 
 * Implements box object display data.
 */
public class BoxObjectDrawer {
	BoxObject	base;
	/// Contains the generated text from the name of the object.
	Bitmap32Bit	text;
	Text		name;
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
		import windows.colorpicker : drawLine;
		Box screenPos = base.position;
		Color displayColor = base.color;
		screenPos.relMove(sX * -1, sY * -1);
		int x0 = screenPos.left, y0 = screenPos.top, x1 = screenPos.right, y1 = screenPos.bottom;
		clamp(x0, 0, rW);
		clamp(y0, 0, rH);
		clamp(x1, 0, rW);
		clamp(y1, 0, rH);
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
		const int textWidth = x0 + text.width < rW ? text.width : text.width - (rW - (x0 + text.width));
		const int textHeight = y0 + text.height >= rH ? text.height : text.height - (rH - (y0 + text.height));
		for (int y ; y < textHeight ; y++) {
			copy(cast(uint*)text.getPtr + (y * textWidth), cast(uint*)dest.ptr + ((y + y0) * pitch) + x0, textWidth);
		}
	}
	public bool isOnDisplay(int sX, int sY, int rW, int rH) {
		Box screen = Box.bySize(sX, sY, rW, rH);
		return screen.isBetween(base.position.cornerUL) || screen.isBetween(base.position.cornerUR) || 
				screen.isBetween(base.position.cornerLL) || screen.isBetween(base.position.cornerLR);
	}
}
