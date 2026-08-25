package states.editors;

import doido.objects.ui.DoidoInputText;
import doido.objects.ui.PsychUIInputText;
import flixel.FlxSprite;

class InputTestState extends MusicBeatState
{
	override function create()
	{
		super.create();

		var bgLight = new FlxSprite().loadGraphic(Assets.image('editors/charting/bg/light'));
		bgLight.setGraphicSize(FlxG.width, FlxG.height);
		bgLight.updateHitbox();
		bgLight.screenCenter();
		add(bgLight);

		var field1:PsychUIInputText;
		field1 = new PsychUIInputText(100, 100, 145, "test psych", 14);
		add(field1);

		var field2:DoidoInputText;
		field2 = new DoidoInputText(100, 300, 145, "test flixel");
		add(field2);
	}
}
