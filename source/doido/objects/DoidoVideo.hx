package doido.objects;

import flixel.util.FlxSignal;

#if hxvlc
import hxvlc.flixel.FlxVideoSprite;

class DoidoVideo extends FlxVideoSprite
{
	public var exitSignal:FlxSignal = new FlxSignal();

	public function new()
	{
		super();

		bitmap.onEndReached.add(exitSignal.dispatch);
		bitmap.onFormatSetup.add(function():Void {
			if (bitmap != null && bitmap.bitmapData != null) {
				setGraphicSize(FlxG.width, FlxG.height);
				updateHitbox();
				screenCenter();
			}
		});
	}

	public function finish():Void
	{
		exitSignal.dispatch();
	}
	
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

class DoidoVideo extends FlxSprite
{
	private var video:Video;
	private var netStream:NetStream;
	private var videoPath:String;

	public var exitSignal:FlxSignal = new FlxSignal();

	public function new()
	{
		super();

		makeGraphic(2, 2, FlxColor.TRANSPARENT);

		video = new Video();
		video.x = 0;
		video.y = 0;
		video.alpha = 0;

		FlxG.game.addChild(video);
	}

	public function load(videoPath:String)
	{
		this.videoPath = videoPath;

		var netConnection:NetConnection = new NetConnection();
		netConnection.connect(null);
		netStream = new NetStream(netConnection);
		netStream.client = {onMetaData: onMetaData};
		netConnection.addEventListener(NetStatusEvent.NET_STATUS, onStatusEvent);
	}

	public function play():Void
	{
		netStream.play(videoPath);
	}

	public function pause():Void
	{
		if (netStream != null)
			netStream.pause();
	}

	public function resume():Void
	{
		if (netStream != null)
			netStream.resume();
	}

	public function restart():Void
	{
		if (netStream != null)
		{
			netStream.seek(0);
			netStream.play(videoPath);
		}
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

		if (Controls.justPressed(VOLUME_MUTE) || Controls.justPressed(VOLUME_UP) || Controls.justPressed(VOLUME_DOWN))
			updateVolume();
	}

	public function finish():Void
	{
		FlxG.removeChild(video);
		exitSignal.dispatch();
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

	public function updateVolume():Void
	{
		netStream.soundTransform = new SoundTransform(FlxG.sound.muted ? 0 : FlxG.sound.volume);
	}

	public function onMetaData(metaData:Dynamic)
	{
		video.attachNetStream(netStream);
		video.width = FlxG.width;
		video.height = FlxG.height;
		videoAvailable = true;
		
		makeGraphic(Std.int(video.width), Std.int(video.height), FlxColor.TRANSPARENT);
		updateVolume();
	}

	public function onStatusEvent(event:NetStatusEvent)
	{
		if (event.info.code == 'NetStream.Play.Complete')
			finish();
	}
}
#end
