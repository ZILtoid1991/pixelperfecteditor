module windows.colorpicker;

import pixelperfectengine.concrete.popup.base;

/** 
 * Draws a line using a fixed point method. Is capable of drawing lines diagonally.
 * Params:
 *   x0 = The X coordinate of the first point.
 *   y0 = The Y coordinate of the first point.
 *   x1 = The X coordinate of the second point.
 *   y1 = The Y coordinate of the second point.
 *   color = The color of the line.
 *   dest = Where the line should be drawn.
 *   destWidth = The width of the destination buffer, ideally divisible without remainder by dest.length.
 */
public void drawLine(T)(int x0, int y0, int x1, int y1, T color, T[] dest, size_t destWidth) @safe @nogc nothrow pure {
	if (x0 < 0 || x0 >= destWidth) return;
	if (x1 < 0 || x1 >= destWidth) return;
	if (y0 < 0 || y0 >= (dest.length / destWidth)) return;
	if (y1 < 0 || y1 >= (dest.length / destWidth)) return;
	const int dirX = x1 < x0 ? -1 : 1, dirY = y1 < y0 ? -1 : 1;
	const int dx = abs(x1 - x0);
	const int dy = abs(y1 - y0);
	if (!dx || !dy) {
		if (!dy) {
			const sizediff_t offset = (destWidth * y0) + x0;
			for (int x ; x <= dx ; x++) {
				dest[offset + (x * dirX)] = color;
			}
		} else {
			sizediff_t offset = destWidth * y0 + x0;
			for (int y ; y <= dy ; y++) {
				dest[offset] = color;
				offset += destWidth * dirY;
			}
		}
	} else if(dx>=dy) {
		const double yS = cast(double)dy / dx * dirY;
		double y = 0;
		const sizediff_t offset = destWidth * y0 + x0;
		for (int x ; x <= dx ; x++) {
			dest[offset + (x * dirX) + (cast(int)nearbyint(y) * destWidth)] = color;
			y += yS;
		}
	} else {
		const double xS = cast(double)dx / dy * dirX;
		double x = 0;
		sizediff_t offset = destWidth * y0 + x0;
		for (int y ; y <= dy ; y++) {
			dest[offset + cast(int)nearbyint(x)] = color;
			offset += destWidth * dirY;
			x += xS;
		}
	}
}

public class ColorPicker : PopUpElement {
    Bitmap32Bit trueOutput;
    override public void draw() {
        
    }
}