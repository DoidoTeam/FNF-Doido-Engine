package objects.mobile;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.ui.FlxButton;
import flixel.input.FlxInput.FlxInputState;
import flixel.util.FlxTimer;

class DoidoPad extends FlxSpriteGroup
{
	public var padActive:Bool = false;

	var buttonWidth:Float = 105;
	var buttonMap:Map<String, FlxButton> = [];

	public function new(mode:String = "blank"):Void
	{
		super();
		padActive = true;

		switch (mode)
		{
			case "pause":
				var button:FlxButton = createButton(FlxG.width - buttonWidth, 0, 'util/pause', 0.8);
				buttonMap.set("PAUSE", button);
				add(button);
			case "back":
				var button:FlxButton = createButton(FlxG.width - buttonWidth, 0, 'util/back', 0.8);
				buttonMap.set("BACK", button);
				add(button);

			case "reset":
				var button:FlxButton = createButton(FlxG.width - buttonWidth, 0, 'util/back', 0.8);
				buttonMap.set("BACK", button);
				add(button);

				var button:FlxButton = createButton(FlxG.width - (buttonWidth*2), 0, 'util/reset', 0.8);
				buttonMap.set("RESET", button);
				add(button);

			case "dialogue":
				var button:FlxButton = createButton(FlxG.width - buttonWidth, 0, 'util/skip', 0.8);
				buttonMap.set("BACK", button);
				add(button);

				var button:FlxButton = createButton(FlxG.width - (buttonWidth*2), 0, 'util/log', 0.8);
				buttonMap.set("TEXT_LOG", button);
				add(button);
		}

		togglePad(true);
	}

	public function togglePad(active:Bool)
	{
		if(active)
			padActive = (Lambda.count(buttonMap) > 0);
		else
			padActive = false;

		for (button in buttonMap) {
			if(padActive)
				button.alpha = (SaveData.data.get("Button Opacity") / 10);
			else
				button.alpha = 0;
		}
	}

	// buttons get manually destroyed when changing states
	override public function destroy():Void
	{
		super.destroy();
		padActive = false;

		for (button in buttonMap)
			button.destroy();
	}

	private function createButton(x:Float, y:Float, path:String, scale:Float = 1):FlxButton
	{
		var button:FlxButton = new FlxButton();

		if (Paths.fileExists('images/mobile/buttons/${path}.png'))
			button.loadGraphic(Paths.getGraphic('mobile/buttons/$path'));
		else
			button.loadGraphic(Paths.getGraphic('mobile/buttons/default.png'));

		button.solid = false;
		button.immovable = true;

		button.scale.set(scale, scale);
		button.updateHitbox();

		button.x = x;
		button.y = y;

		return button;
	}

	public function checkButton(buttonID:String, inputState:FlxInputState):Bool
	{
		if(!padActive)
			return false;
		
		var button = buttonMap.get(buttonID);
		if(button != null)
		{
			switch(inputState) {
				case PRESSED:
					return button.pressed;
				case RELEASED:
					return button.released;
				case JUST_PRESSED:
					return button.justPressed && !button.justReleased;
				case JUST_RELEASED:
					return button.justReleased;
			}
		}
		return false;
	}
}