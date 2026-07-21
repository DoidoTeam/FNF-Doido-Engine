package doido.system;

import doido.objects.system.Transition;
import flixel.FlxBasic;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.graphics.FlxGraphic;
import flixel.FlxSprite;
import lime.app.Application;
import openfl.display.BitmapData;
import lime.math.Rectangle;
#if SCREENSHOT_FEATURE
import sys.FileSystem;
import sys.io.File;

class Screenshot extends FlxBasic
{
	private static var lastScreenshot:FlxSprite;

	var screnshotDelay:Int = 0;

	override function update(elapsed:Float)
	{
		if (screnshotDelay > 0)
		{
			screnshotDelay--;
			if (screnshotDelay <= 0)
			{
				screnshotDelay = 0;
				takeScreenshot();
			}
		}

		if (FlxG.keys.justPressed.F2 #if debug && !FlxG.keys.pressed.SHIFT #end)
		{
			screnshotDelay = 2;
			MusicBeat.getTopCamera().stopFlash();
			clearScreenshot();
		}

		super.update(elapsed);
	}

	public function takeScreenshot()
	{
		// sorry no screenshots during transitions
		if (Std.isOfType(MusicBeat.activeState, Transition))
			return;

		FlxG.sound.play(Assets.sound('screenshot'));

		var rect:Rectangle = new Rectangle();
		var scaleImage:Bool = !FlxG.keys.pressed.SHIFT;
		var scaleX:Float = FlxG.stage.window.width / FlxG.width;
		var scaleY:Float = FlxG.stage.window.height / FlxG.height;
		var scale:Float = Math.min(scaleX, scaleY);
		if (!scaleImage)
			scale = 1 / scale;

		if (scaleImage)
		{
			rect = new Rectangle((FlxG.stage.window.width - FlxG.width * scale) / 2, (FlxG.stage.window.height - FlxG.height * scale) / 2, FlxG.width * scale, FlxG.height * scale);
		}

		var rawImage = Application.current.window.readPixels(scaleImage ? rect : null);
		if (scaleImage)
			rawImage.resize(FlxG.width, FlxG.height);
		var pngBytes = rawImage.encode(PNG);
		if (!FileSystem.exists("screenshots/"))
			FileSystem.createDirectory("screenshots/");
		var i:Int = 0;
		var rawName:String = Date.now().toString().replace(":", "-");
		var name:String = rawName;
		while (FileSystem.exists('screenshots/$name.png'))
		{
			i++;
			name = '$rawName ($i)';
		}
		File.saveBytes('screenshots/$name.png', pngBytes);
		var camera = MusicBeat.getTopCamera();
		camera.flash(0.8, null, true);

		lastScreenshot = new FlxSprite().loadGraphic(FlxGraphic.fromBitmapData(BitmapData.fromImage(rawImage)));
		if (scaleImage)
			lastScreenshot.scale.set(0.25, 0.25);
		else
			lastScreenshot.scale.set(0.25 * scale, 0.25 * scale);
		lastScreenshot.updateHitbox();
		lastScreenshot.cameras = [camera];

		MusicBeat.activeState.add(lastScreenshot);

		lastScreenshot.y = FlxG.height;
		FlxTween.tween(lastScreenshot, {y: FlxG.height - lastScreenshot.height}, 0.4, {
			ease: FlxEase.cubeOut,
			startDelay: 0.6,
			onComplete: (twn) ->
			{
				FlxTween.tween(lastScreenshot, {x: -FlxG.width}, 0.4, {
					ease: FlxEase.cubeIn,
					startDelay: 1.6,
					onComplete: (twn) ->
					{
						clearScreenshot();
					}
				});
			}
		});
	}

	public static function clearScreenshot()
	{
		if (lastScreenshot == null)
			return;
		FlxTween.cancelTweensOf(lastScreenshot);
		MusicBeat.activeState.remove(lastScreenshot);
		Cache.killGraphic(lastScreenshot.graphic);
		lastScreenshot = null;
	}
}
#else
class Screenshot extends FlxBasic
{
	// just in case
	public static function clearScreenshot() {}
}
#end
