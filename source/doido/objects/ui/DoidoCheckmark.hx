package doido.objects.ui;

import doido.objects.ui.buttons.DoidoButton;

class DoidoCheckmark extends DoidoButton
{
	public var value(default, set):Bool;

	public function new(defVal:Bool = false, sprite:String = "editors/charting/checkmark", animation:String = "button checkmark", ?onUp:Void->Void, ?onDown:Void->Void)
	{
		super(onUp, onDown);

		this.loadSparrow(sprite);
		this.animation.addByPrefix("off", animation + "0000", 0, false);
		this.animation.addByPrefix("on", animation + "0001", 0, false);

		this.onUp.add(() ->
		{
			value = !value;
		});

		value = defVal;
		maxScale = 1;
		minScale = 0.95;
	}

	public function set_value(b:Bool)
	{
		value = b;
		animation.play((value ? "on" : "off"));
		return value;
	}
}
