package doido.objects;

#if hxvlc
import hxvlc.flixel.FlxVideoSprite;

// To-Do: Figure out if we need to change anything
class DoidoVideo extends FlxVideoSprite
{
	/**
	 * Restarts video from the beginning
	 */
	public inline function restart():Void
	{
		if (bitmap != null)
			bitmap.time = 0;
		resume();
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
 * To-Do: Figure out what to improve
 */
class DoidoVideo extends FlxSprite
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

	public function new(videoPath:String)
	{
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
	public function pause():Void
	{
		if (netStream != null)
			netStream.pause();
	}

	/**
	 * Tell the DoidoVideoSprite to resume if it is paused.
	 */
	public function resume():Void
	{
		// Resume playing the video.
		if (netStream != null)
			netStream.resume();
	}

	var videoAvailable:Bool = false;
	var frameTimer:Float;

	static final FRAME_RATE:Float = 60;

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (frameTimer >= (1 / FRAME_RATE))
		{
			frameTimer = 0;
			pixels.draw(video);
		}

		if (videoAvailable)
			frameTimer += elapsed;
	}

	/**
	 * Tell the DoidoVideoSprite to seek to the beginning.
	 */
	public function restart():Void
	{
		// Seek to the beginning of the video.
		if (netStream != null)
		{
			netStream.seek(0);
			netStream.play(videoPath);
		}
	}

	/**
	 * Tell the DoidoVideoSprite to end.
	 */
	public function finish():Void
	{
		FlxG.removeChild(video);

		if (finishCallBack != null)
			finishCallBack();

		if (closeCallBack != null)
			closeCallBack();
	}

	public override function destroy():Void
	{
		if (netStream != null)
		{
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
	public function onClientMetaData(metaData:Dynamic):Void
	{
		video.attachNetStream(netStream);
		onVideoReady();
	}

	function onVideoReady():Void
	{
		video.width = FlxG.width;
		video.height = FlxG.height;
		videoAvailable = true;

		onVolumeChanged(FlxG.sound.muted ? 0 : FlxG.sound.volume);
		makeGraphic(Std.int(video.width), Std.int(video.height), FlxColor.TRANSPARENT);
	}

	function onVolumeChanged(volume:Float):Void
	{
		netStream.soundTransform = new SoundTransform(volume);
	}

	function onNetConnectionNetStatus(event:NetStatusEvent):Void
	{
		if (event.info.code == 'NetStream.Play.Complete')
			finish();
	}
}
#end
