module windows.colorpicker;

import pixelperfectengine.concrete.popup.base;
import inteli.emmintrin;
import std.math;
import pixelperfectengine.graphics.draw;
import pixelperfectengine.system.etc : max, min;

import CPUblit.drawing.line;

public __m128d interpolateCircle(__m128d sizes, __m128d center, double t) @nogc @safe pure nothrow {
	__m128d result;
	result[0] = sin(2*PI*t);
	result[1] = cos(2*PI*t);
	result *= sizes;
	result += center;
	return result;
}

double[3] rgb2hsv(Color rgb) @nogc @safe pure nothrow {
	double[3] result;
	double xmax = max(rgb.fR, max(rgb.fG, rgb.fB));
	double xmin = min(rgb.fR, min(rgb.fG, rgb.fB));
	const double d = xmax - xmin;
	result[2] = xmax;
	if (result[2] != 0)
		result[1] = d / xmax;
	else
		result[1] = 0;
	/* if (result[2] < 0.5)
		result[1] = (xmax - xmin) / (xmax + xmin);
	else
		result[1] = (xmax - xmin) / (2.0 - xmax - xmin); */
	if (xmax == rgb.fR)
		result[0] = (rgb.fG - rgb.fB)/d;
	else if (xmax == rgb.fG)
		result[0] = 2.0 + (rgb.fB - rgb.fR)/d;
	else
		result[0] = 4.0 + (rgb.fR - rgb.fG)/d;
	result[0] /= 6;
	if (isNaN(result[0]))
		result[0] = 0;
	if (isNaN(result[1]))
		result[1] = 0;
	return result;
}

public class ColorPicker : PopUpElement {
    Bitmap32Bit trueOutput;
	double hue, sat, value;
	Color selHue;
	Color selection;
	public void delegate(Color c) onColorPick;
	protected static immutable __m128 o = __m128([0, -1.0/3.0, 1.0/3.0, 0]);
	public this (void delegate(Color c) onColorPick, Color initColor) {
		output = new BitmapDrawer(259, 259);
		trueOutput = new Bitmap32Bit(259, 259);
		position = Box.bySize(0, 0, 259, 259);
		double[3] hsv = rgb2hsv(initColor);
		hue = hsv[0];
		sat = hsv[1];
		value = hsv[2];
		//selHue = hsl2rgb([hue, 0.0, 1.0]);
		calculateColorOutput;
		this.onColorPick = onColorPick;
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
			/* __m128 h = __m128(d) + o;
			for (int j ; j < 3 ; j++) {
				real i = 1;
				h[j] = modf(h[j], i);
			}
			h = __m128(1) - (2 * h);
			for (int j ; j < 3 ; j++) {
				h[j] = abs(h[j]);
			}
			__m128 fullsat = _mm_min_ps(_mm_max_ps(__m128(3) * h - __m128(1),__m128(0)), __m128(1));
			col.fR = fullsat[0];
			col.fG = fullsat[1];
			col.fB = fullsat[2]; */
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
		//x axis is saturation, y axis is value
		for (int y ; y <= 133 ; y++) {
			const double v = (1.0 / 133) * y;
			for (int x ; x <= 133 ; x++) {
				const double s = (1.0 / 133) * x;
				const double c_s = v * (1.0 - s);
				Color cl;
				cl.a = 0xFF;
				cl.fR = selHue.fR() * v;
				cl.fG = selHue.fG() * v;
				cl.fB = selHue.fB() * v;
				cl.fR = (cl.fR * s) + c_s;
				cl.fG = (cl.fG * s) + c_s;
				cl.fB = (cl.fB * s) + c_s;
				trueOutput.writePixel(62 + x, 62 + y, cl);
			}
		}
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
			circleMidpoint[1] = value * 133 + 62;
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
			value = (1.0 / 133) * (y - 62);
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
		selection.fR = selHue.fR * value;
		selection.fG = selHue.fG * value;
		selection.fB = selHue.fB * value;
		const double c_s = value * (1.0 - sat);
		selection.fR = (selection.fR * sat) + c_s;
		selection.fG = (selection.fG * sat) + c_s;
		selection.fB = (selection.fB * sat) + c_s;
		if (onColorPick !is null)
			onColorPick(selection);
	}
}