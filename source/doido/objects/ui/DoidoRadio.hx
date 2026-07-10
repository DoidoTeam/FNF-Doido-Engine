package doido.objects.ui;

import flixel.text.FlxBitmapText;
import doido.objects.ui.buttons.DoidoButton;
import flixel.group.FlxSpriteGroup;

class DoidoRadio extends FlxSpriteGroup
{
	public var onToggle:Int->Void;
	public var cur(default, set):Int = -1;

	public var buttons:Array<DoidoButton> = [];
	public var labels:Array<FlxBitmapText> = [];

	public function new(options:Array<String>, defaultOpt:Int = 0, ?onToggle:Int->Void)
	{
		super();
		this.onToggle = onToggle;

		for (i in 0...options.length)
		{
			var button = new DoidoButton();
			button.loadSparrow("editors/charting/radio");
			button.ID = i;
			button.animation.addByPrefix("off", "button radio0000", 0, false);
			button.animation.addByPrefix("on", "button radio0001", 0, false);
			button.y = (button.height + 5) * i;
			button.onUp.add(() ->
			{
				cur = button.ID;
				if (this.onToggle != null)
					this.onToggle(button.ID);
			});
			button.maxScale = 1;
			button.minScale = 0.95;
			buttons.push(button);
			add(button);

			var label = new FlxBitmapText(0, 0, Assets.bitmapFont("phantommuff"));
			label.color = 0xFFD8DAF6;
			label.alignment = CENTER;
			label.text = options[i];
			label.scale.set(0.625, 0.625);
			label.updateHitbox();
			label.x = button.x + button.width + 4;
			label.y = button.y + 2;
			labels.push(label);
			add(label);
		}

		this.cur = defaultOpt;
	}

	public function set_cur(i:Int)
	{
		cur = i;
		for (button in buttons)
			button.animation.play((button.ID == i ? "on" : "off"));
		return cur;
	}
}
