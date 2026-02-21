package doido.mobile;

#if TOUCH_CONTROLS
import flixel.FlxG;
import flixel.input.touch.FlxTouch;
import flixel.input.FlxInput.FlxInputState;

class TouchHandler
{
    public static function getTap(inputState:FlxInputState):Bool
    {
        var touch:FlxTouch = FlxG.touches.list[0];
        if(touch == null) return false;

        switch(inputState)
        {
            case PRESSED:
                return touch.pressed;
            case RELEASED:
                return touch.released;
            case JUST_PRESSED:
                return touch.justReleased;
            case JUST_RELEASED:
                return touch.justReleased;
        }
    }

    public static function getSwipe(direction:DoidoKey = ANY):Bool
    {
        switch (direction) {
            case UI_UP:
                return Save.data.invertY ? swipe(45, 135) : swipe(-135, -45);
            case UI_DOWN:
                return Save.data.invertY ? swipe(-135, -45) : swipe(45, 135);
            case UI_RIGHT:
                return Save.data.invertX ? swipe(135, -135, false) : swipe(-45, 45);
            case UI_LEFT:
                return Save.data.invertX ? swipe(-45, 45) : swipe(135, -135, false);
            default:
                return getSwipe(UI_UP) || getSwipe(UI_DOWN) || getSwipe(UI_LEFT) || getSwipe(UI_RIGHT);
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