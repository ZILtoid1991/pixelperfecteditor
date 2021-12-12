module boxobject;

import pixelperfectengine.graphics.common;
import pixelperfectengine.graphics.text;
import pixelperfectengine.graphics.fontsets;
import pixelperfectengine.graphics.bitmap;

/** 
 * Implements box object display data.
 */
public struct BoxObject {
	/// Defines the place of the box.
	Box			prelimiters;
	/// The display color for the box.
	Color		displayColor;
	/// Contains the generated text from the name of the text.
	Bitmap8Bit	text;
	/// Global character formatting of the text, minus for the color, which is unique to each instance
	static CharacterFormattingInfo!Bitmap8Bit	chrFormat;
}