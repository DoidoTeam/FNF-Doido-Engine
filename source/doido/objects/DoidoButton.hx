package doido.objects;

import flixel.FlxSprite;
import flixel.input.FlxInput;
import flixel.input.FlxInput.FlxInputState;
import flixel.input.IFlxInput;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxSignal;
import flixel.group.FlxSpriteGroup;

class DoidoButton extends FlxSpriteGroup implements IFlxInput
{
    var hitbox:ButtonHitbox;
    var sprite:FlxSprite;

    public function new(x:Float = 0, y:Float = 0) {
		super(x,y);
        hitbox = new ButtonHitbox(0,0,100,100,0.5);
        sprite = new FlxSprite();
        add(sprite);
        add(hitbox);
    }

    public function fromImage(key:String) {
        sprite.loadImage(key);
        sprite.updateHitbox();
        hitbox.reload(sprite.width, sprite.height);
    }

    public var justReleased(get, never):Bool;
	public var released(get, never):Bool;
	public var pressed(get, never):Bool;
	public var justPressed(get, never):Bool;

    inline function get_justReleased():Bool
		return hitbox.justReleased;

	inline function get_released():Bool
		return hitbox.released;

	inline function get_pressed():Bool
		return hitbox.pressed;

	inline function get_justPressed():Bool
		return hitbox.justPressed;
}

// custom button hitbox thing?
class ButtonHitbox extends FlxSprite implements IFlxInput
{
    public var currentState:FlxInputState = RELEASED;
	public var lastState:FlxInputState = RELEASED;

    public var onUp(default, null):FlxSignal = new FlxSignal();
    public var onDown(default, null):FlxSignal = new FlxSignal();

    public var holdMode:Bool = false;

    var _alpha:Float;
    var _color:FlxColor;

    public function new(x:Float = 0, y:Float = 0, width:Float = 100, height:Float = 100, ?alpha:Float, ?color:FlxColor)
	{
		super(x, y);
        _color = 0xFFFF0000;
        _alpha = 0;
        reload(width, height, alpha, color);
	}

    public function reload(width:Float = 100, height:Float = 100, ?alpha:Float, ?color:FlxColor) {
        if(alpha != null)
            _alpha = alpha;
        if(color != null)
            _color = color;

        this.makeColor(width, height, _color);
        this.alpha = _alpha;

        currentState = RELEASED;
        lastState = RELEASED;
    }

    public override function update(elapsed:Float):Void
    {
        super.update(elapsed);
        
        var overlap = checkButton();

        if(overlap) {
            lastState = currentState;
            currentState = pressed ? PRESSED : JUST_PRESSED;
            if(justPressed)
                onDown.dispatch();
        }
        else {
            lastState = currentState;
            currentState = pressed ? JUST_RELEASED : RELEASED;
            if(justReleased)
                onUp.dispatch();
        }
    }

    function checkButton():Bool {
        #if TOUCH_CONTROLS
        if(checkTouch()) return true;
        #end
        return checkMouse();
    }

    function checkMouse():Bool {
        if(holdMode && (pressed || justPressed))
            return FlxG.mouse.pressed;

        if(FlxG.mouse.pressed) {
            for (camera in cameras) {
                var pos:FlxPoint = FlxG.mouse.getWorldPosition(camera);
                var overlap = overlapsPoint(pos);
                pos.put();
                if (overlap) return true;
            }
        }

        return false;
    }

    #if TOUCH_CONTROLS
    function checkTouch():Bool {
        var touches:Array<FlxTouch> = FlxG.touches.list;
        if(touches != null && touches.length != 0) {
            for (camera in cameras) {
                for(touch in touches) {
                    var pos:FlxPoint = touch.getWorldPosition(camera);
                    var overlap = overlapsPoint(pos);
                    pos.put();
                    if(overlap) return true;
                }
            }
        }
        return false;
    }
    #end

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