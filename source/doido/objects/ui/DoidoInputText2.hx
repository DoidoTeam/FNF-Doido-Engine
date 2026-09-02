package doido.objects.ui;

import flixel.text.FlxInputText;
import flixel.util.FlxSignal;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

class DoidoInputText2 extends FlxSpriteGroup
{
	public var inputText:FlxInputText;
	public var bg:FlxSprite;
	public var border:FlxSprite;

	public var onTextChange = new FlxTypedSignal<(text:String, change:FlxInputTextChange)->Void>();

	// manual positioning stuff we use to style this
	static inline var xOffset:Int = 2;
	static inline var yOffset:Int = 1;
	static inline var widthOffset:Int = 4;
	static inline var heightOffset:Int = 2;
	static inline var selHeightOffset:Int = 1;
	static inline var borderThickness:Int = 3;

	public function new(x:Float = 0, y:Float = 0, width:Int = 150, ?text:String)
	{
		super(x, y);

		inputText = new FlxInputText(xOffset, yOffset, width - widthOffset, text, 14);
		inputText.font = Assets.font("phantommuff");
		inputText.selectionColor = 0xFF0000FF;
		inputText.background = false;

		var _height = Std.int(inputText.height) + heightOffset;

		border = new FlxSprite();
		border.makeGraphic(width, _height, 0xff000000);

		bg = new FlxSprite(borderThickness, borderThickness);
		bg.makeGraphic(width - (borderThickness*2), _height - (borderThickness*2), 0xFFFFFFFF);

		add(border);
		add(bg);
		add(inputText);
	}
}
