package data;

import flixel.FlxG;
import flixel.util.FlxAxes;
import gameObjects.mobile.VPad;
import flixel.FlxState;
#if FLX_TOUCH
import flixel.input.touch.FlxTouch;
#end

class MobileUtil
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

  public static var virtualPad:VPad;

  private static function get_pressed():Bool
  {
    #if FLX_TOUCH
    for (touch in FlxG.touches.list)
    {
      if (touch.pressed) return true;
    }
    #end

    return false;
  }

  private static function get_justPressed():Bool
  {
    #if FLX_TOUCH
    for (touch in FlxG.touches.list)
    {
      if (touch.justPressed) return true;
    }
    #end

    return false;
  }

  private static function get_justReleased():Bool
  {
    #if FLX_TOUCH
    for (touch in FlxG.touches.list)
    {
      if (touch.justReleased) return true;
    }
    #end

    return false;
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

  public static function createVPad(action:VAction, state:FlxState) {
    virtualPad = new VPad(action);
    if(state != null) {
      state.add(virtualPad);
      virtualPad.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
    }
  }
}