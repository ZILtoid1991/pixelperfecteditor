module windows.colorpicker;

import pixelperfectengine.concrete.popup.base;
import inteli.emmintrin;
import std.math;

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

public __m128d interpolateCircle(__m128d sizes, __m128d center, double t) @nogc @safe pure nothrow {
	__m128d result;
	result[0] = sin(2*PI*t);
	result[1] = cos(2*PI*t);
	result *= sizes;
	result += center;
	return result;
}

public class ColorPicker : PopUpElement {
    Bitmap32Bit trueOutput;
	double hue;
    override public void draw() {
        for (double d = 0 ; d <= 1 ; d+=1/(64*64*PI)) {
			Color col = Color(0, 0, 0, 1.0);
			const double h = d * 6;
			immutable double c = 1.0;
			const double x = c * (c - abs(fmod(h, 2) - c));
			if (h >= 0 && h < 1) {
				col.fR = c;
				col.fG = x;
			} else if (h >= 1 && h < 2) {
				col.fR = x;
				col.fG = c;
			} else if (h >= 2 && h < 3) {
				col.fG = c;
				col.fB = x;
			} else if (h >= 3 && h < 4) {
				col.fG = x;
				col.fB = c;
			} else if (h >= 4 && h < 5) {
				col.fB = c;
				col.fR = x;
			} else if (h >= 5 && h < 6) {
				col.fB = x;
				col.fR = c;
			}
			__m128d inner = interpolateCircle(__m128d(96.0), __m128d(64.5), d),
					outer = interpolateCircle(__m128d(128.0), __m128d(64.5), d);
			drawLine(cast(int)outer[0], cast(int)outer[1], cast(int)inner[0], cast(int)inner[1], col, trueOutput.pixels, 
					trueOutput.width);
		}
    }
}