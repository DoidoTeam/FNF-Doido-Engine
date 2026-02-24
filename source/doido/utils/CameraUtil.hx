package doido.utils;

import flixel.FlxCamera;

class CameraUtil
{
    public static function createCam(cam:FlxCamera, ui:Bool = false, defaultDrawTarget:Bool = false):FlxCamera {
        if(ui) cam.bgColor.alpha = 0;
        if(!defaultDrawTarget) FlxG.cameras.add(cam, false);
        else {
            FlxG.cameras.reset(cam);
            FlxG.cameras.setDefaultDrawTarget(cam, true);
        }
        return cam;
    }
}