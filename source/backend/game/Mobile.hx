package backend.game;

#if TOUCH_CONTROLS
import flixel.FlxG;
import flixel.input.touch.FlxTouch;
import flixel.input.FlxInput.FlxInputState;

class Mobile
{
    public static function getTap(inputState:FlxInputState):Bool
    {
        var touch:FlxTouch = FlxG.touches.list[0];

        if(touch == null || getMouse(inputState))
            return getMouse(inputState);

        switch(inputState)
        {
            case PRESSED:
                return touch.pressed;
            case RELEASED:
                return touch.released;
            case JUST_PRESSED:
                return touch.justPressed;
            case JUST_RELEASED:
                return touch.justReleased;
        }
    }

    // Used for mouse control on mobile
    public static function getMouse(inputState:FlxInputState):Bool
    {
        switch(inputState)
        {
            case PRESSED:
                return FlxG.mouse.pressed;
            case RELEASED:
                return FlxG.mouse.released;
            case JUST_PRESSED:
                return FlxG.mouse.justPressed;
            case JUST_RELEASED:
                return FlxG.mouse.justReleased;
        }
    }

    public static function getSwipe(direction:String = "ANY"):Bool
    {
        switch (direction) {
            case "UP" | "UI_UP":
                return invert("Y") ? swipe(45, 135) : swipe(-135, -45);
            case "DOWN" | "UI_DOWN":
                return invert("Y") ? swipe(-135, -45) : swipe(45, 135);
            case "RIGHT" | "UI_RIGHT":
                return invert("X") ? swipe(135, -135, false) : swipe(-45, 45);
            case "LEFT" | "UI_LEFT":
                return invert("X") ? swipe(-45, 45) : swipe(135, -135, false);
            default:
                return getSwipe("UP") || getSwipe("DOWN") || getSwipe("LEFT") || getSwipe("RIGHT");
        }
    }

    static function swipe(lower:Int, upper:Int, and:Bool = true, distance:Int = 20):Bool
    {
        for (swipe in FlxG.swipes)
        {
            return (and ?
                ((swipe.degrees > lower && swipe.degrees < upper) && swipe.distance > distance):
                ((swipe.degrees > lower || swipe.degrees < upper) && swipe.distance > distance)
            );
        }

        return false;
    }

    static function invert(axes:String):Bool
    {
        switch(SaveData.data.get("Invert Swipes"))
        {
            case "HORIZONTAL":
                return axes == "X";
            case "VERTICAL":
                return axes == "Y";
            case "BOTH":
                return true;
            default:
                return false;
        }
    }

    public static var back(get, never):Bool;

    private static function get_back():Bool
    {
        #if android
        return FlxG.android.justReleased.BACK;
        #else
        return false;
        #end
    }
}
#end