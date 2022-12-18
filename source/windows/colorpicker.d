module windows.colorpicker;

import pixelperfectengine.concrete.popup.base;
import inteli.emmintrin;
import std.math;
import pixelperfectengine.graphics.draw;
import pixelperfectengine.system.etc : max, min;

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
	double hue, sat, level;
	Color selHue;
	Color selection;
	public void delegate(Color c) onColorPick;
	public this (void delegate(Color c) onColorPick, Color initColor) {
		output = new BitmapDrawer(259, 259);
		trueOutput = new Bitmap32Bit(259, 259);
		position = Box.bySize(0, 0, 259, 259);
		double xmax = max(initColor.fR, max(initColor.fG, initColor.fB));
		double xmin = min(initColor.fR, min(initColor.fG, initColor.fB));
		level = (xmax + xmin) / 2;
		if (level == 0.0) {
			hue = 0;
			sat = 0;
		} else {
			double c = xmax - xmin;
			sat = c / xmax;
			if (xmax == initColor.fR) {
				hue = ((initColor.fG - initColor.fB) / c) / 6;
			} else if (xmax == initColor.fG) {
				hue = (2 + (initColor.fB - initColor.fR) / c) / 6;
			} else {
				hue = (4 + (initColor.fR - initColor.fG) / c) / 6;
			}
			if (hue < 0) {
				hue += 1.0;
			}
			if (level == 0.0 || level == 1.0) {
				sat = 0;
			} else {
				sat = (xmax - level) / (min(level, 1.0 - level));
			}
			
		}
		real i = 2;
		const double h = hue * 6;
		immutable double c = 1.0;
		const double x = c * (c - abs(modf(h, i) - c));
		if (h >= 0 && h < 1) {
			selHue.fR = c;
			selHue.fG = x;
		} else if (h >= 1 && h < 2) {
			selHue.fR = 1 - x;
			selHue.fG = c;
		} else if (h >= 2 && h < 3) {
			selHue.fG = c;
			selHue.fB = x;
		} else if (h >= 3 && h < 4) {
			selHue.fG = 1 - x;
			selHue.fB = c;
		} else if (h >= 4 && h < 5) {
			selHue.fB = c;
			selHue.fR = x;
		} else if (h >= 5 && h < 6) {
			selHue.fB = 1 - x;
			selHue.fR = c;
		}
	}
    override public void draw() {
		import CPUblit.colorlookup;
		StyleSheet ss = getStyleSheet();
		
		output.drawBox(Box.bySize(0,0, output.output.width, output.output.height), ss.getColor("windowascent"));
		output.drawFilledBox(Box.bySize(1, 1, output.output.width - 2, output.output.height - 2), ss.getColor("window"));
		colorLookup(output.output.getPtr, trueOutput.getPtr, StyleSheet.defaultpaletteforGUI.ptr, 
				trueOutput.width * trueOutput.height);
		//draw circle of hue
        for (double d = 0 ; d <= 1 ; d+=1.0/(310*PI)) {
			Color col = Color(0, 0, 0, 1.0);
			real i = 2;
			const double h = d * 6;
			immutable double c = 1.0;
			const double x = c * (c - abs(modf(h, i) - c));
			if (h >= 0 && h < 1) {
				col.fR = c;
				col.fG = x;
			} else if (h >= 1 && h < 2) {
				col.fR = 1 - x;
				col.fG = c;
			} else if (h >= 2 && h < 3) {
				col.fG = c;
				col.fB = x;
			} else if (h >= 3 && h < 4) {
				col.fG = 1 - x;
				col.fB = c;
			} else if (h >= 4 && h < 5) {
				col.fB = c;
				col.fR = x;
			} else if (h >= 5 && h < 6) {
				col.fB = 1 - x;
				col.fR = c;
			}
			__m128d inner = interpolateCircle(__m128d(96.0), __m128d(129), d),
					outer = interpolateCircle(__m128d(128.0), __m128d(129), d);
			for (double e = 0 ; e <= 1 ; e+=0.02) {
				__m128d point = inner * __m128d(1 - e) + outer * __m128d(e);
				trueOutput.writePixel(cast(int)nearbyint(point[0]), cast(int)nearbyint(point[1]), col);
			}
			/* drawLine(cast(int)nearbyint(outer[0]), cast(int)nearbyint(outer[1]), cast(int)nearbyint(inner[0]), 
					cast(int)nearbyint(inner[1]), col, trueOutput.pixels, trueOutput.width); */
		}
		//draw the square
		//x axis is saturation, y axis is level
		for (int y ; y <= 133 ; y++) {
			const double l = (1.0 / 133) * y;
			for (int x ; x <= 133 ; x++) {
				const double s = (1.0 / 133) * x;
				Color cl;
				cl.a = 0xFF;
				cl.fR = selHue.fR() * s;
				cl.fG = selHue.fG() * s;
				cl.fB = selHue.fB() * s;
				cl.fR = cl.fR * (1.0 - l) + l;
				cl.fG = cl.fG * (1.0 - l) + l;
				cl.fB = cl.fB * (1.0 - l) + l;
				trueOutput.writePixel(62 + x, 62 + y, cl);
			}
		}
		/* for (double d = 0 ; d <= 1 ; d += 1 / (triP[1][1] - triP[0][1])) {
			//lerp the points of the triangle line-by-line
			__m128d c = triP[0] * __m128d(1 - d);
			__m128d from = c + triP[1] * __m128d(d);
			__m128d to = c + triP[2] * __m128d(d);
			for (double e = 0 ; e <= 1 ; e += 1 / (to[0] - from[0])) {
				//Calculate the color to draw
				Color cl;
				cl.a = 0xFF;
				cl.fR = selHue.fR() * d;
				cl.fG = selHue.fG() * d;
				cl.fB = selHue.fB() * d;
				cl.fR = cl.fR * (1.0 - e) + e;
				cl.fG = cl.fG * (1.0 - e) + e;
				cl.fB = cl.fB * (1.0 - e) + e;
				//get the current pixel to use
				double x = from[0] * (1.0 - e) + to[0] * e;
				trueOutput.writePixel(cast(int)nearbyint(x), cast(int)nearbyint(from[1]), cl);
			}
		} */
		//Draw hue selector line
		{
			__m128d inner = interpolateCircle(__m128d(96.0), __m128d(129), hue),
					outer = interpolateCircle(__m128d(128.0), __m128d(129), hue);
			drawLine(cast(int)outer[0], cast(int)outer[1], cast(int)inner[0], cast(int)inner[1], Color(0xFF, 0xFF, 0xFF, 0xFF), 
					trueOutput.pixels, trueOutput.width);
		}
		//Draw the Level/saturation selector circle
		{
			__m128d circleMidpoint;
			circleMidpoint[0] = sat * 133 + 62;
			circleMidpoint[1] = level * 133 + 62;
			for (double d = 0.0 ; d <= 1.0 ; d += 1.0 / 32) {
				const __m128d p = interpolateCircle(__m128d(7.0), circleMidpoint, d);
				trueOutput.writePixel(cast(int)p[0], cast(int)p[1], Color(0xFF, 0xFF, 0xFF, 0xFF));
			}
		}
    }
	override public ABitmap getOutput() {
		return trueOutput;
	}
	protected void mouseEventInternal(int x, int y) {
		//Calculate center distance
		const double r = sqrt(cast(real)pow(x - 129, 2) + pow(y - 129, 2));
		if (r >= 96 && r <= 128) {
			hue = (PI + atan2((x - 129) * -1.0, (y - 129) * -1.0)) / (PI * 2);
			calculateColorOutput();
			draw();
		} else if (x >= 62 && y >= 62 && x <= 62 + 133 && y <= 62 + 133) {
			level = (1.0 / 133) * (y - 62);
			sat = (1.0 / 133) * (x - 62);
			calculateColorOutput();
			draw();
			
		}
	}
	override public void passMCE(MouseEventCommons mec, MouseClickEvent mce) {
		if (mce.state && mce.button == MouseButton.Left) {
			mouseEventInternal(mce.x - position.left, mce.y - position.top);
		}
	}
	
	override public void passMME(MouseEventCommons mec, MouseMotionEvent mme) {
		if (mme.buttonState == MouseButtonFlags.Left) {
			mouseEventInternal(mme.x - position.left, mme.y - position.top);
		}
	}
	
	override public void passMWE(MouseEventCommons mec, MouseWheelEvent mwe) {
		real i = 1.0;
		if (mwe.y > 0) {
			hue = modf(hue += 0.05, i);
		} else if (mwe.y < 0) {
			hue = modf(hue -= 0.05, i);
		}
		if (mwe.x > 0) {
			hue = modf(hue += 0.01, i);
		} else if (mwe.x < 0) {
			hue = modf(hue -= 0.01, i);
		}
		if (hue < 0)
			hue += 1;
		calculateColorOutput();
		draw();
	}
	public void calculateColorOutput() {
		real i = 2;
		const double h = hue * 6;
		immutable double c = 1.0;
		const double x = c * (c - abs(modf(h, i) - c));
		if (h >= 0 && h < 1) {
			selHue.fR = c;
			selHue.fG = x;
			selHue.b = 0;
		} else if (h >= 1 && h < 2) {
			selHue.fR = 1 - x;
			selHue.fG = c;
			selHue.b = 0;
		} else if (h >= 2 && h < 3) {
			selHue.r = 0;
			selHue.fG = c;
			selHue.fB = x;
		} else if (h >= 3 && h < 4) {
			selHue.r = 0;
			selHue.fG = 1 - x;
			selHue.fB = c;
		} else if (h >= 4 && h < 5) {
			selHue.g = 0;
			selHue.fB = c;
			selHue.fR = x;
		} else if (h >= 5 && h < 6) {
			selHue.g = 0;
			selHue.fB = 1 - x;
			selHue.fR = c;
		}
		selection.fR = selHue.fR * sat;
		selection.fG = selHue.fG * sat;
		selection.fB = selHue.fB * sat;
		selection.fR = selection.fR * (1.0 - level) + level;
		selection.fG = selection.fG * (1.0 - level) + level;
		selection.fB = selection.fB * (1.0 - level) + level;
		if (onColorPick !is null)
			onColorPick(selection);
	}
}