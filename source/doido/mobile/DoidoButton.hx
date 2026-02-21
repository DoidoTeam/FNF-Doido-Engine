package doido.mobile;

#if TOUCH_CONTROLS
import flixel.FlxSprite;
import flixel.input.FlxInput;
import flixel.input.FlxInput.FlxInputState;
import flixel.input.IFlxInput;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

// custom button hitbox thing?
class DoidoButton extends FlxSprite implements IFlxInput
{
    public var currentState:FlxInputState = RELEASED;
	public var lastState:FlxInputState = RELEASED;

    //?????
    var hitbox:FlxSprite;

    public function new(x:Float = 0, y:Float = 0, width:Float = 100, height:Float = 100, ?alpha:Float = 0, ?color:FlxColor)
	{
		super(x, y);
        this.makeColor(width, height, (color == null ? 0xFFFF0000 : color));
        this.alpha = alpha;
	};

    public override function update(elapsed:Float):Void
    {
        super.update(elapsed);
        
        var overlap = checkButton();

        if(overlap) {
            lastState = currentState;
            currentState = pressed ? PRESSED : JUST_PRESSED;
        }
        else {
            lastState = currentState;
            currentState = pressed ? JUST_RELEASED : RELEASED;
        }
    }

    function checkButton():Bool {
        var touches:Array<FlxTouch> = FlxG.touches.list;
        if(touches == null || touches.length == 0) return false;
        for (camera in cameras)
        {
            for(touch in touches) {
                var pos:FlxPoint = touch.getWorldPosition(camera);
                var overlap = overlapsPoint(pos);
                pos.put();
                if(overlap) return true;
            }
        }
        return false;
    }

	public var justReleased(get, never):Bool;
	public var released(get, never):Bool;
	public var pressed(get, never):Bool;
	public var justPressed(get, never):Bool;

    inline function get_justReleased():Bool
		return currentState == JUST_RELEASED;

	inline function get_released():Bool
		return currentState == RELEASED || justReleased;

	inline function get_pressed():Bool
		return currentState == PRESSED || justPressed;

	inline function get_justPressed():Bool
		return currentState == JUST_PRESSED;
}
#end