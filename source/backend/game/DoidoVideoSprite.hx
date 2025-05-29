package backend.game;

#if hxvlc 
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

/*
	This class extends FlxSprite to display video files in HaxeFlixel. But in a DOIDO kind of way...
	There's hardly gonna be a need for you to use this so please refer to VideoPlayerSubstate to find out how videos work
*/

@:nullSafety
class DoidoVideoSprite extends FlxSprite
{
	/**
	 * Indicates whether the video should automatically pause when focus is lost.
	 *
	 * Must be set before loading a video.
	 */
	public var autoPause:Bool = FlxG.autoPause;

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
	 * Internal tracker for whether the video is paused or not.
	 */
	@:noCompletion
	private var resumeOnFocus:Bool = false;

	/**
	 * Creates a `DoidoVideoSprite` at a specified position.
	 *
	 * @param x The initial X position of the sprite.
	 * @param y The initial Y position of the sprite.
	 */
	public function new(?x:Float = 0, ?y:Float = 0):Void
	{
		super(x, y);

		bitmap = new Video(antialiasing);
		bitmap.forceRendering = true;
		bitmap.onOpening.add(function():Void
		{
			if (bitmap != null)
			{
				bitmap.role = LibVLC_Role_Game;

				#if (FLX_SOUND_SYSTEM && flixel >= "5.9.0")
				if (!FlxG.sound.onVolumeChange.has(onVolumeChange))
					FlxG.sound.onVolumeChange.add(onVolumeChange);
				#elseif (FLX_SOUND_SYSTEM && flixel < "5.9.0")
				if (!FlxG.signals.postUpdate.has(onVolumeUpdate))
					FlxG.signals.postUpdate.add(onVolumeUpdate);
				#end

				#if FLX_SOUND_SYSTEM
				onVolumeChange(0.0);
				#end
			}
		});
		bitmap.onFormatSetup.add(function():Void
		{
			if (bitmap != null)
			{
				if (bitmap.bitmapData != null)
					loadGraphic(FlxGraphic.fromBitmapData(bitmap.bitmapData, false, null, false));
			}
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
			if (!FlxG.signals.focusGained.has(onFocusGained))
				FlxG.signals.focusGained.add(onFocusGained);

			if (!FlxG.signals.focusLost.has(onFocusLost))
				FlxG.signals.focusLost.add(onFocusLost);
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
	 * Restarts video from the beginning
	 */
	public inline function restart():Void
	{
		if(bitmap != null)
			bitmap.time = 0;
		resume();
	}

	/**
	 * Resumes playback of a paused video.
	 */
	public inline function resume():Void
	{
		bitmap?.resume();
	}

	/**
	 * Finishes playback of a video.
	 */
	public inline function finish():Void
	{
		if(bitmap != null) {
			for(event in bitmap.onEndReached.__listeners)
				event();
		}
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
	 * The volume is automatically clamped between `0` and `2.55` by the calling code. If the sound is muted, the volume is `0`.
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
		if (FlxG.signals.focusGained.has(onFocusGained))
			FlxG.signals.focusGained.remove(onFocusGained);

		if (FlxG.signals.focusLost.has(onFocusLost))
			FlxG.signals.focusLost.remove(onFocusLost);

		#if (FLX_SOUND_SYSTEM && flixel >= "5.9.0")
		if (FlxG.sound.onVolumeChange.has(onVolumeChange))
			FlxG.sound.onVolumeChange.remove(onVolumeChange);
		#elseif (FLX_SOUND_SYSTEM && flixel < "5.9.0")
		if (FlxG.signals.postUpdate.has(onVolumeUpdate))
			FlxG.signals.postUpdate.remove(onVolumeUpdate);
		#end

		super.destroy();

		if (bitmap != null)
		{
			FlxG.removeChild(bitmap);
			bitmap.dispose();
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

	@:noCompletion
	private function onFocusGained():Void
	{
		if (resumeOnFocus)
		{
			resumeOnFocus = false;

			resume();
		}
	}

	@:noCompletion
	private function onFocusLost():Void
	{
		resumeOnFocus = bitmap == null ? false : bitmap.isPlaying;

		pause();
	}

	#if FLX_SOUND_SYSTEM
	#if (flixel < "5.9.0")
	@:noCompletion
	private function onVolumeUpdate():Void
	{
		onVolumeChange(0.0);
	}
	#end

	@:noCompletion
	private function onVolumeChange(vol:Float):Void
	{
		if (bitmap != null)
		{
			if (autoVolumeHandle)
				bitmap.volume = Math.floor(FlxMath.bound(getCalculatedVolume(), 0, 2.55) * Define.getFloat('HXVLC_FLIXEL_VOLUME_MULTIPLIER', 100));
		}
	}
	#end

	@:noCompletion
	private override function set_antialiasing(value:Bool):Bool
	{
		return antialiasing = (bitmap == null ? value : (bitmap.smoothing = value));
	}
}
#elseif html5
import flixel.util.FlxColor;
import openfl.events.NetStatusEvent;
import openfl.media.SoundTransform;
import openfl.media.Video;
import openfl.net.NetConnection;
import openfl.net.NetStream;
import flixel.FlxSprite;

/**
 * Taken from base game.
 */
class DoidoVideoSprite extends FlxSprite
{
	var video:Video;
	var netStream:NetStream;
	var videoPath:String;

	/**
	 * A callback to execute when the video finishes.
	 */
	public var finishCallBack:Void->Void;

	/**
	 * A callback meant to close the video when it finishes.
	 */
	public var closeCallBack:Void->Void;

	public function new(videoPath:String) {
		super();

		makeGraphic(2, 2, FlxColor.TRANSPARENT);

		video = new Video();
		video.x = 0;
		video.y = 0;
		video.alpha = 0;

		FlxG.game.addChild(video);

		var netConnection:NetConnection = new NetConnection();
		netConnection.connect(null);

		netStream = new NetStream(netConnection);
		netStream.client = {onMetaData: onClientMetaData};
		netConnection.addEventListener(NetStatusEvent.NET_STATUS, onNetConnectionNetStatus);
		netStream.play(videoPath);
	}

	/**
	 * Tell the DoidoVideoSprite to pause playback.
	 */
	public function pause():Void {
		if (netStream != null)
			netStream.pause();
	}

	/**
	 * Tell the DoidoVideoSprite to resume if it is paused.
	 */
	public function resume():Void {
		// Resume playing the video.
		if (netStream != null)
			netStream.resume();
	}

	var videoAvailable:Bool = false;
	var frameTimer:Float;

	static final FRAME_RATE:Float = 60;

	public override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (frameTimer >= (1 / FRAME_RATE)) {
			frameTimer = 0;
			pixels.draw(video);
		}

		if (videoAvailable)
			frameTimer += elapsed;
	}

	/**
	 * Tell the DoidoVideoSprite to seek to the beginning.
	 */
	public function restart():Void {
		// Seek to the beginning of the video.
		if (netStream != null) {
			netStream.seek(0);
			netStream.play(videoPath);
		}
	}

	/**
	 * Tell the DoidoVideoSprite to end.
	 */
	public function finish():Void {
		FlxG.removeChild(video);

		if (finishCallBack != null)
			finishCallBack();

		if(closeCallBack != null)
			closeCallBack();
	}

	public override function destroy():Void {
		if (netStream != null) {
			netStream.dispose();

			if (FlxG.game.contains(video))
				FlxG.game.removeChild(video);
		}
		super.destroy();
	}

	/**
	 * Callback executed when the video stream loads.
	 * @param metaData The metadata of the video
	 */
	public function onClientMetaData(metaData:Dynamic):Void {
		video.attachNetStream(netStream);
		onVideoReady();
	}

	function onVideoReady():Void {
		video.width = FlxG.width;
		video.height = FlxG.height;
		videoAvailable = true;

		onVolumeChanged(FlxG.sound.muted ? 0 : FlxG.sound.volume);
		makeGraphic(Std.int(video.width), Std.int(video.height), FlxColor.TRANSPARENT);
	}

	function onVolumeChanged(volume:Float):Void {
		netStream.soundTransform = new SoundTransform(volume);
	}

	function onNetConnectionNetStatus(event:NetStatusEvent):Void {
		if (event.info.code == 'NetStream.Play.Complete')
			finish();
	}
}
#end