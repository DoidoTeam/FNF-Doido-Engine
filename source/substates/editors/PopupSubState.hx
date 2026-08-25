package substates.editors;

import doido.utils.EditorUtil;
import states.editors.ChartingState;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxBitmapText;
import animate.internal.elements.FlxSpriteElement;
import flixel.FlxSprite;
import flixel.FlxBasic;
import flixel.math.FlxMath;
import doido.objects.ui.buttons.DoidoAnimatedButton;
import flixel.math.FlxRect;

class PopupSubState extends MusicBeatSubState
{
	public var clipped:Bool = false;

	public var bg:FlxSprite;
	public var closeButton:DoidoAnimatedButton;
	public var titleText:FlxBitmapText;

	public var width:Float = 300;
	public var height:Float = 150;

	public var onClose:Void->Void;

	var objects:Array<FlxBasic> = [];

	public function new(title:String = "", width:Float = 300, height:Float = 150, ?objects:Array<FlxBasic>, ?clipped:Bool = false)
	{
		super();
		this.width = width;
		this.height = height;
		this.clipped = clipped;
		if (objects != null)
			this.objects = objects;

		bg = new FlxSprite().makeColor(0, 0, 0xFF000000);

		bg.screenCenter();
		bg.alpha = 0.7;
		add(bg);

		for (obj in this.objects)
			add(obj);

		closeButton = new DoidoAnimatedButton('editors/charting/close', 'close', () -> close());
		add(closeButton);

		titleText = new FlxBitmapText(0, 0, Assets.bitmapFont("phantommuff"));
		titleText.alignment = LEFT;
		titleText.text = title;
		titleText.color = 0xFFFFFFFF;
		titleText.scale.set(0.625, 0.625);
		titleText.updateHitbox();
		add(titleText);

		if (ChartingState.soundEffects)
			FlxG.sound.play(Assets.sound("options/options-close"));

		positionBg(0);
		positionTitle();
	}

	function positionTitle()
	{
		closeButton.x = bg.x + bg.width - closeButton.width - 8;
		closeButton.y = bg.y + 8;

		titleText.x = bg.x + 8;
		titleText.y = bg.y + 10;
	}

	function positionBg(elapsed:Float)
	{
		if (clipped)
			bg.scale.set(FlxMath.lerp(bg.scale.x, width, elapsed * 8), FlxMath.lerp(bg.scale.y, height, elapsed * 8));
		else
			bg.scale.set(width, height);

		bg.updateHitbox();
		bg.screenCenter();
	}

	override function draw()
	{
		if (clipped)
		{
			positionTitle();

			function check(obj:FlxBasic)
			{
				if (obj == null)
					return;

				if (Std.isOfType(obj, FlxSpriteGroup))
				{
					var grp:FlxSpriteGroup = cast obj;
					grp.forEach((member) -> check(member));
				}
				else if (Std.isOfType(obj, FlxGroup))
				{
					var grp:FlxGroup = cast obj;
					grp.forEach((member) -> check(member));
				}
				else if (Std.isOfType(obj, FlxSprite))
					setClip(cast obj, bg);
			}

			for (obj in objects)
				check(obj);

			setClip(closeButton, bg);
			setClip(titleText, bg);
		}

		super.draw();
	}

	// for some reason clipToSprite isnt working right
	function setClip(sprite:FlxSprite, bg:FlxSprite)
	{
		var newx:Float = bg.x - sprite.x;
		var newy:Float = bg.y - sprite.y;
		var newwidth:Float = (bg.x + bg.width - sprite.x) - newx;
		var newheight:Float = (bg.y + bg.height - sprite.y) - newy;
		sprite.clipRect = new FlxRect(newx / sprite.scale.x, newy / sprite.scale.y, newwidth / sprite.scale.x, newheight / sprite.scale.y);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if ((FlxG.keys.justPressed.ESCAPE || (FlxG.mouse.justReleased && !FlxG.mouse.overlaps(bg, MusicBeat.getTopCamera())))
			&& !EditorUtil.isTyping)
			close();

		if (clipped)
			positionBg(elapsed);
	}

	override function close()
	{
		if (onClose != null)
			onClose();

		if (ChartingState.soundEffects)
			FlxG.sound.play(Assets.sound("options/options-close"));

		super.close();
	}
}
