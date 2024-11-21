package backend.game;

#if VIDEOS_ALLOWED
import flixel.graphics.FlxGraphic;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import haxe.io.Bytes;
import haxe.io.Path;
import hxvlc.externs.Types;
import hxvlc.util.macros.Define;
import hxvlc.util.Location;
import hxvlc.openfl.Video;
import openfl.utils.Assets;
import sys.FileSystem;

using StringTools;

class DoidoVideoSprite extends FlxSprite
{
	/**
	 * Indicates whether the video should automatically pause when focus is lost.
	 *
	 * Must be set before loading a video.
	 */
	public var autoPause:Bool = FlxG.autoPause;
	public var forcePause:Bool = false;

	#if FLX_SOUND_SYSTEM
	/**
	 * Determines if Flixel automatically adjusts the volume based on the Flixel sound system's current volume.
	 */
	public var autoVolumeHandle:Bool = true;
	#end

	/**
	 * The video bitmap object.
	 */
	public var bitmap(default, null):Null<Video>;

	/**
	 * Creates a `FlxVideoSprite` at a specified position.
	 *
	 * @param x The initial X position of the sprite.
	 * @param y The initial Y position of the sprite.
	 */
	public function new(?x:Float = 0, ?y:Float = 0):Void
	{
		super(x, y);

		#if (FLX_SOUND_SYSTEM && flixel >= "5.9.0")
		FlxG.sound.onVolumeChange.add(onVolumeChange);
		#end

		bitmap = new Video(antialiasing);
		bitmap.forceRendering = true;
		bitmap.onOpening.add(function():Void
		{
			if (bitmap != null)
			{
				bitmap.role = LibVLC_Role_Game;

				#if FLX_SOUND_SYSTEM
				if (autoVolumeHandle)
					bitmap.volume = Math.floor(FlxMath.bound(getCalculatedVolume(), 0, 1) * Define.getFloat('HXVLC_FLIXEL_VOLUME_MULTIPLIER', 100));
				#end
			}
		});
		bitmap.onFormatSetup.add(function():Void
		{
			if (bitmap != null && bitmap.bitmapData != null)
				loadGraphic(FlxGraphic.fromBitmapData(bitmap.bitmapData, false, null, false));
		});
		bitmap.visible = false;
		FlxG.game.addChild(bitmap);

		makeGraphic(1, 1, FlxColor.TRANSPARENT);
	}

	/**
	 * Loads a video from the specified location.
	 *
	 * @param location The location of the media file or stream.
	 * @param options Additional options to configure the media.
	 * @return `true` if the media was loaded successfully, `false` otherwise.
	 */
	public function load(location:Location, ?options:Array<String>):Bool
	{
		if (bitmap == null)
			return false;

		if (autoPause)
		{
			if (!FlxG.signals.focusGained.has(resume))
				FlxG.signals.focusGained.add(resume);

			if (!FlxG.signals.focusLost.has(pause))
				FlxG.signals.focusLost.add(pause);
		}

		if (location != null && !(location is Int) && !(location is Bytes) && (location is String))
		{
			final location:String = cast(location, String);

			if (!location.contains('://'))
			{
				final absolutePath:String = FileSystem.absolutePath(location);

				if (FileSystem.exists(absolutePath))
					return bitmap.load(absolutePath, options);
				else if (Assets.exists(location))
				{
					final assetPath:String = Assets.getPath(location);

					if (assetPath != null)
					{
						if (FileSystem.exists(assetPath) && Path.isAbsolute(assetPath))
							return bitmap.load(assetPath, options);
						else if (!Path.isAbsolute(assetPath))
						{
							try
							{
								final assetBytes:Bytes = Assets.getBytes(location);

								if (assetBytes != null)
									return bitmap.load(assetBytes, options);
							}
							catch (e:Dynamic)
							{
								FlxG.log.error('Error loading asset bytes from location "$location": $e');

								return false;
							}
						}
					}

					return false;
				}
				else
				{
					FlxG.log.warn('Unable to find the video file at location "$location".');

					return false;
				}
			}
		}

		return bitmap.load(location, options);
	}

	/**
	 * Loads a media subitem from the current media's subitems list at the specified index.
	 *
	 * @param index The index of the subitem to load.
	 * @param options Additional options to configure the loaded subitem.
	 * @return `true` if the subitem was loaded successfully, `false` otherwise.
	 */
	public inline function loadFromSubItem(index:Int, ?options:Array<String>):Bool
	{
		return bitmap == null ? false : bitmap.loadFromSubItem(index, options);
	}

	/**
	 * Parses the current media item with the specified options.
	 *
	 * @param parse_flag The parsing option.
	 * @param timeout The timeout in milliseconds.
	 * @return `true` if parsing succeeded, `false` otherwise.
	 */
	public inline function parseWithOptions(parse_flag:Int, timeout:Int):Bool
	{
		return bitmap == null ? false : bitmap.parseWithOptions(parse_flag, timeout);
	}

	/**
	 * Stops parsing the current media item.
	 */
	public inline function parseStop():Void
	{
		bitmap?.parseStop();
	}

	/**
	 * Starts video playback.
	 *
	 * @return `true` if playback started successfully, `false` otherwise.
	 */
	public inline function play():Bool
	{
		return bitmap == null ? false : bitmap.play();
	}

	/**
	 * Stops video playback.
	 */
	public inline function stop():Void
	{
		bitmap?.stop();
	}

	/**
	 * Pauses video playback.
	 */
	public inline function pause():Void
	{
		bitmap?.pause();
	}

	/**
	 * Resumes playback of a paused video.
	 */
	public inline function resume():Void
	{
		if(!forcePause)
			bitmap?.resume();
	}

	/**
	 * Toggles between play and pause states of the video.
	 */
	public inline function togglePaused():Void
	{
		bitmap?.togglePaused();
	}

	#if FLX_SOUND_SYSTEM
	/**
	 * Calculates and returns the current volume based on Flixel's sound settings by default.
	 *
	 * The volume is automatically clamped between `0` and `1` by the calling code. If the sound is muted, the volume is `0`.
	 *
	 * @return The calculated volume.
	 */
	public dynamic function getCalculatedVolume():Float
	{
		return (FlxG.sound.muted ? 0 : 1) * FlxG.sound.volume;
	}
	#end

	public override function destroy():Void
	{
		if (FlxG.signals.focusGained.has(resume))
			FlxG.signals.focusGained.remove(resume);

		if (FlxG.signals.focusLost.has(pause))
			FlxG.signals.focusLost.remove(pause);

		#if (FLX_SOUND_SYSTEM && flixel >= "5.9.0")
		if (FlxG.sound.onVolumeChange.has(onVolumeChange))
			FlxG.sound.onVolumeChange.remove(onVolumeChange);
		#end

		super.destroy();

		if (bitmap != null)
		{
			bitmap.dispose();

			FlxG.removeChild(bitmap);

			bitmap = null;
		}
	}

	public override function kill():Void
	{
		bitmap?.pause();

		super.kill();
	}

	public override function revive():Void
	{
		super.revive();

		bitmap?.resume();
	}

	public override function update(elapsed:Float):Void
	{
		#if (FLX_SOUND_SYSTEM && flixel < "5.9.0")
		if (bitmap != null && autoVolumeHandle)
			bitmap.volume = Math.floor(FlxMath.bound(getCalculatedVolume(), 0, 1) * Define.getFloat('HXVLC_FLIXEL_VOLUME_MULTIPLIER', 100));
		#end

		super.update(elapsed);
	}

	#if (FLX_SOUND_SYSTEM && flixel >= "5.9.0")
	@:noCompletion
	private function onVolumeChange(_):Void
	{
		if (bitmap != null && autoVolumeHandle)
			bitmap.volume = Math.floor(FlxMath.bound(getCalculatedVolume(), 0, 1) * Define.getFloat('HXVLC_FLIXEL_VOLUME_MULTIPLIER', 100));
	}
	#end

	@:noCompletion
	private override function set_antialiasing(value:Bool):Bool
	{
		return antialiasing = (bitmap == null ? value : (bitmap.smoothing = value));
	}
}
#end