package states;

import flixel.FlxG;
import flixel.FlxSprite;
import data.GameData.MusicBeatState;
import shaders.HoldNoteShader;

using StringTools;

class HoldNoteTestState extends MusicBeatState
{
	var block:FlxSprite;

	var shaderLine:FlxSprite;
	var actualShader:HoldNoteShader;

	override function create()
	{
		super.create();
		var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF777777);
		bg.screenCenter();
		add(bg);

		block = new FlxSprite().makeGraphic(20, 20, 0xFFFF0000);
		block.setGraphicSize(200,200);
		block.updateHitbox();
		add(block);

		shaderLine = new FlxSprite().makeGraphic(FlxG.width, 2, 0xFF000000);
		shaderLine.screenCenter(X);
		add(shaderLine);

		actualShader = new HoldNoteShader();
		block.shader = actualShader.shader;
		actualShader.cutY = FlxG.height / 2;
		shaderLine.y = FlxG.height / 2;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		block.setPosition(FlxG.mouse.x - 100, FlxG.mouse.y - 100);
		actualShader.y = block.y;
		//if(actualShader.downscroll)
		//	actualShader.y += block.height;

		if(FlxG.mouse.justPressed)
		{
			actualShader.cutY = FlxG.mouse.y;
			shaderLine.y = FlxG.mouse.y;
		}
		if(FlxG.mouse.justPressedRight)
			actualShader.downscroll = !actualShader.downscroll;
	}
}
