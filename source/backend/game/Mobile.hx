package backend.game;

#if TOUCH_CONTROLS
import flixel.FlxG;
import flixel.util.FlxAxes;
//import gameObjects.mobile.DoidoPad;
import flixel.FlxState;
import flixel.input.touch.FlxTouch;

class Mobile
{
  // Tapping screen
  public static var pressed(get, never):Bool;
  public static var justPressed(get, never):Bool;
  public static var justReleased(get, never):Bool;

  // Android BACK button
  public static var back(get, never):Bool;

  // Swiping on screen
  public static var swipeUp(get, never):Bool;
  public static var swipeDown(get, never):Bool;
  public static var swipeLeft(get, never):Bool;
  public static var swipeRight(get, never):Bool;
  public static var swipeAny(get, never):Bool;

  //public static var virtualPad:DoidoPad;

  private static function get_pressed():Bool
  {
    for (touch in FlxG.touches.list)
      if (touch.pressed) return true;

    return FlxG.mouse.pressed;
  }

  private static function get_justPressed():Bool
  {
    for (touch in FlxG.touches.list)
      if (touch.justPressed) return true;

    return FlxG.mouse.justPressed;
  }

  private static function get_justReleased():Bool
  {
    for (touch in FlxG.touches.list)
      if (touch.justReleased) return true;

    return FlxG.mouse.justReleased;
  }

  private static function get_back():Bool
  {
    #if android
    return FlxG.android.justReleased.BACK;
    #else
    return false;
    #end
  }

  static function get_swipeUp():Bool
    return invert(Y) ? swipe(45, 135, 20) : swipe(-135, -45, 20);

  static function get_swipeDown():Bool
    return invert(Y) ? swipe(-135, -45, 20) : swipe(45, 135, 20);

  static function get_swipeRight():Bool
    return invert(X) ? swipe(135, -135, 20, false) : swipe(-45, 45, 20);

  static function get_swipeLeft():Bool
    return invert(X) ? swipe(-45, 45, 20) : swipe(135, -135, 20, false);

  static function get_swipeAny():Bool
    return swipeRight || swipeLeft || swipeUp || swipeDown;

  static function swipe(lowerBound:Int, upperBound:Int, distance:Int = 20, andOr:Bool = true) {
    for (swipe in FlxG.swipes) {
      if(andOr) {
        if (
          swipe.degrees > lowerBound &&
          swipe.degrees < upperBound &&
          swipe.distance > distance ) 
          return true;
      }
      else {
        if (
          (swipe.degrees > lowerBound ||
          swipe.degrees < upperBound) &&
          swipe.distance > distance ) 
          return true;
      }
    }

    return false;
  }

  static function invert(axes:FlxAxes):Bool {
    switch(SaveData.data.get("Invert Swipes")) {
      case "HORIZONTAL":
        return axes == X;
      case "VERTICAL":
        return axes == Y;
      case "BOTH":
        return true;
    }

    return false;
  }

  /*
  public static function createPad(action:VAction, state:FlxState) {
    virtualPad = new DoidoPad(action);
    if(state != null) {
      state.add(virtualPad);
      virtualPad.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
    }
  }
  */
}
#else
class Mobile
{
  // Tapping screen
  public static var pressed:Bool = false;
  public static var justPressed:Bool = false;
  public static var justReleased:Bool = false;

  // Android BACK button
  public static var back:Bool = false;

  // Swiping on screen
  public static var swipeUp:Bool = false;
  public static var swipeDown:Bool = false;
  public static var swipeLeft:Bool = false;
  public static var swipeRight:Bool = false;
  public static var swipeAny:Bool = false;
}
#end