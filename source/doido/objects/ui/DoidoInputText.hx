package doido.objects.ui;

import flixel.text.FlxInputText;
import flixel.util.FlxSignal;
import flixel.FlxSprite;

// regular flixel input text, but styled
// really janky but im not sure how else we could do this...
class DoidoInputText extends FlxInputText
{
	// manual positioning stuff we use to style this
	static inline var xOffset:Int = 2;
	static inline var yOffset:Int = 1;
	static inline var widthOffset:Int = 4;
	static inline var heightOffset:Int = 2;
	static inline var selHeightOffset:Int = 1;

	public function new(x:Float = 0, y:Float = 0, width:Int = 150, ?text:String)
	{
		super(x + xOffset, y + yOffset, width - widthOffset, text, 14);
		font = Assets.font("phantommuff");
		fieldBorderThickness = 3;
		selectionColor = 0xFF0000FF;
	}

	override function regenBackground()
	{
		if (!background)
			return;

		_regenBackground = false;

		var bgWidth = Std.int(fieldWidth + widthOffset);
		var bgHeight = Std.int(height + heightOffset);

		_fieldBorderSprite.makeGraphic(bgWidth, bgHeight, fieldBorderColor);
		_fieldBorderSprite.visible = fieldBorderThickness > 0;

		_backgroundSprite.makeGraphic(bgWidth - (fieldBorderThickness * 2), bgHeight - (fieldBorderThickness * 2), backgroundColor);
		_backgroundSprite.visible = backgroundColor.alpha > 0;

		updateBackgroundPosition();
	}

	override function updateBackgroundPosition():Void
	{
		if (!background)
			return;

		_fieldBorderSprite.setPosition(x - xOffset, y - yOffset);
		_backgroundSprite.setPosition(x + fieldBorderThickness - xOffset, y + fieldBorderThickness - yOffset);

		clipSprite(_fieldBorderSprite, true);
		clipSprite(_backgroundSprite);
	}

	override function updateSelectionBoxes():Void
	{
		if (textField == null || _selectionBoxes == null)
			return;

		super.updateSelectionBoxes();

		for (box in _selectionBoxes)
			box.setGraphicSize(box.width, box.height + selHeightOffset);
	}

	@:deprecated("PsychUIInputText deprecated. Please replace onChange with onTextChange.")
	public var onChange:FlxTypedSignal<String->String->DoidoInputText->Void> = new FlxTypedSignal<String->String->DoidoInputText->Void>();
}
