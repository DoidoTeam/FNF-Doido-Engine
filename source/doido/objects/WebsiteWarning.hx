package doido.objects;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxTween;

class WebsiteWarning extends MusicBeatSubState
{
	var url:String = '';

	var curSelected:Int = 0;
	var grpItems:FlxTypedGroup<Alphabet>;

	public function new(url:String)
	{
		super();
		this.url = url;
		var bg = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFF000000);
		bg.alpha = 0.0;
		add(bg);

		var messages:Array<String> = ["Warning\nThis action will take you to", url, "Are you sure?",];
		var lastItem:Alphabet = null;
		for (i in 0...messages.length)
		{
			var item = new Alphabet(FlxG.width / 2, 80, messages[i], (i != 1));
			if (lastItem != null)
				item.y = lastItem.y + lastItem.height + 16;
			if (i == 1)
				item.scale.set(0.45, 0.45);
			else
				item.scale.set(0.7, 0.7);
			item.align = CENTER;
			item.updateHitbox();

			if (i == 1)
			{
				item.text = '<color value=#FFFFFF>${messages[i]}</color>';
			}

			lastItem = item;
			add(item);
		}

		grpItems = new FlxTypedGroup<Alphabet>();
		for (i in 0...2)
		{
			var opt = new Alphabet(0, 480, (i == 0) ? "NO" : "YES", true);
			opt.x = (FlxG.width / 2) + 190 * ((i == 0) ? -1 : 1);
			opt.align = CENTER;
			opt.updateHitbox();
			grpItems.add(opt);
			opt.ID = i;
		}
		add(grpItems);
		changeSelection(false);

		FlxG.sound.play(Assets.sound('cancel'), 0.4);
		FlxTween.tween(bg, {alpha: 0.85}, 0.1);
	}

	function changeSelection(change:Bool = true)
	{
		if (change)
		{
			FlxG.sound.play(Assets.sound('scroll'));
			curSelected++;
			if (curSelected > 1)
				curSelected = 0;
		}

		for (item in grpItems.members)
		{
			item.alpha = 0.4;
			if (item.ID == curSelected)
				item.alpha = 1.0;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		var back = Controls.justPressed(BACK);
		if (Controls.justPressed(ACCEPT) || back)
		{
			if (curSelected == 0 || back)
				FlxG.sound.play(Assets.sound('cancel'), 0.4);
			else
				FlxG.openURL(url);

			close();
		}

		if (Controls.justPressed(UI_LEFT) || Controls.justPressed(UI_RIGHT))
			changeSelection();
	}
}
