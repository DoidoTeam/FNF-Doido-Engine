package gameObjects.mobile;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxTileFrames;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import flixel.ui.FlxButton;

enum VAction
{
	BACK; //BACK BUTTON FOR MENUS
	PAUSE; //PAUSE BUTTON FOR PLAYSTATE
	SKIP; //SKIP BUTTON FOR DIALOG
	BLANK; //NO BUTTONS
}

enum VButton
{
	UP;
	DOWN;
	LEFT;
	RIGHT;
	A;
	B;
	C;
	D;
	BACK;
	PAUSE;
}

/**
 * Virtual Gamepad
 *
 * @author Ka Wing Chin
 * @author teles
 */
class VPad extends FlxSpriteGroup
{
	public var buttonLeft:FlxButton = new FlxButton(0, 0);
	public var buttonUp:FlxButton = new FlxButton(0, 0);
	public var buttonRight:FlxButton = new FlxButton(0, 0);
	public var buttonDown:FlxButton = new FlxButton(0, 0);
	public var buttonA:FlxButton = new FlxButton(0, 0);
	public var buttonB:FlxButton = new FlxButton(0, 0);
	public var buttonC:FlxButton = new FlxButton(0, 0);
	public var buttonD:FlxButton = new FlxButton(0, 0);
	public var buttonBack:FlxButton = new FlxButton(0, 0);

	var padActive:Bool = false;

	public function new(Mode:VAction = BLANK):Void
	{
		super();

		switch (Mode)
		{
			case PAUSE:
				add(buttonBack = createButton(FlxG.width - 105, 0, 'util/pause', 0.8));
			case SKIP:
				add(buttonBack = createButton(FlxG.width - 105, 0, 'util/skip', 0.8));
			case BACK:
				add(buttonBack = createButton(FlxG.width - 105, 0, 'util/back', 0.8));


			/* -- REFERENCE POSITIONS FOR FACE BUTTONS
			case WATTS:
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, 'a'));
				add(buttonB = createButton(FlxG.width - 258, FlxG.height - 135, 'b'));
				add(buttonC = createButton(FlxG.width - 384, FlxG.height - 135, 'c'));
				add(buttonD = createButton(FlxG.width - 258, FlxG.height - 255, 'd'));
				add(buttonBack = createButton(FlxG.width - 105, 0, 'back', 0.5, 0.8));
			*/

			case BLANK: // do nothing
		}

		scrollFactor.set();

		padActive = true;
	}

	// buttons get manually destroyed when changing states
	override public function destroy():Void
	{
		super.destroy();
		padActive = false;
		
		buttonLeft = FlxDestroyUtil.destroy(buttonLeft);
		buttonUp = FlxDestroyUtil.destroy(buttonUp);
		buttonDown = FlxDestroyUtil.destroy(buttonDown);
		buttonRight = FlxDestroyUtil.destroy(buttonRight);
		buttonA = FlxDestroyUtil.destroy(buttonA);
		buttonB = FlxDestroyUtil.destroy(buttonB);
		buttonC = FlxDestroyUtil.destroy(buttonC);
		buttonD = FlxDestroyUtil.destroy(buttonD);
		buttonBack = FlxDestroyUtil.destroy(buttonBack);
	}

	private function createButton(x:Float, y:Float, path:String, scale:Float = 1, forcedAlpha:Float = 1):FlxButton
	{
		var button:FlxButton = new FlxButton();

		if (Paths.fileExists('images/android/buttons/${path}.png'))
			button.loadGraphic(Paths.getGraphic('android/buttons/$path'));
		else
			button.loadGraphic(Paths.getGraphic('android/buttons/default.png'));

		button.solid = false;
		button.immovable = true;

		button.scale.set(scale, scale);
		button.updateHitbox();

		button.x = x;
		button.y = y;
		button.alpha = forcedAlpha * (SaveData.data.get("Button Opacity") / 10);

		return button;
	}

	public function justPressed(Button:VButton):Bool {
		if(!padActive)
			return false;

		var buttonState:Null<Bool> = false;
		switch (Button)
		{
			case UP:
				buttonState = buttonUp.justPressed;
			case DOWN:
				buttonState = buttonDown.justPressed;
			case LEFT:
				buttonState = buttonLeft.justPressed;
			case RIGHT:
				buttonState = buttonRight.justPressed;
			case A:
				buttonState = buttonA.justPressed;
			case B:
				buttonState = buttonB.justPressed;
			case C:
				buttonState = buttonC.justPressed;
			case D:
				buttonState = buttonD.justPressed;
			case BACK:
				buttonState = buttonBack.justPressed;
			case PAUSE:
				buttonState = buttonBack.justPressed;
		}

		if(buttonState == null)
			buttonState = false;
		return buttonState;
	}

	public function pressed(Button:VButton):Bool {
		if(!padActive)
			return false;

		var buttonState:Null<Bool> = false;
		switch (Button)
		{
			case UP:
				buttonState = buttonUp.pressed;
			case DOWN:
				buttonState = buttonDown.pressed;
			case LEFT:
				buttonState = buttonLeft.pressed;
			case RIGHT:
				buttonState = buttonRight.pressed;
			case A:
				buttonState = buttonA.pressed;
			case B:
				buttonState = buttonB.pressed;
			case C:
				buttonState = buttonC.pressed;
			case D:
				buttonState = buttonD.pressed;
			case BACK:
				buttonState = buttonBack.pressed;
			case PAUSE:
				buttonState = buttonBack.pressed;
		}

		if(buttonState == null)
			buttonState = false;
		return buttonState;
	}

	public function justReleased(Button:VButton):Bool {
		if(!padActive)
			return false;

		var buttonState:Null<Bool> = false;
		switch (Button)
		{
			case UP:
				buttonState = buttonUp.justReleased;
			case DOWN:
				buttonState = buttonDown.justReleased;
			case LEFT:
				buttonState = buttonLeft.justReleased;
			case RIGHT:
				buttonState = buttonRight.justReleased;
			case A:
				buttonState = buttonA.justReleased;
			case B:
				buttonState = buttonB.justReleased;
			case C:
				buttonState = buttonC.justReleased;
			case D:
				buttonState = buttonD.justReleased;
			case BACK:
				buttonState = buttonBack.justReleased;
			case PAUSE:
				buttonState = buttonBack.pressed;
		}

		if(buttonState == null)
			buttonState = false;

		return buttonState;
	}
}