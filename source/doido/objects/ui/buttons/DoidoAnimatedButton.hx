package doido.objects.ui.buttons;

class DoidoAnimatedButton extends DoidoButton
{
	public function new(sprite:String, animation:String, ?onUp:Void->Void, ?onDown:Void->Void)
	{
		super(onUp, onDown);

		this.loadSparrow(sprite);
		this.animation.addByPrefix("idle", animation + "0000", 0, false);
		this.animation.addByPrefix("pressed", animation + "0001", 0, false);
		this.animation.play("idle", true);

		this.onUp.add(() ->
		{
			if (!disabled)
				this.animation.play("idle");
		});
		this.onDown.add(() ->
		{
			if (!disabled)
				this.animation.play("pressed");
		});
		this.onOut.add(() ->
		{
			if (!disabled)
				this.animation.play("idle");
		});

		maxScale = 1;
		minScale = 0.95;
	}

	override function set_disabled(b:Bool):Bool
	{
		if (b == disabled)
			return disabled;

		super.set_disabled(b);
		animation.play(b ? "pressed" : "idle");
		return disabled;
	}
}
