package substates.editors;

import objects.ui.PlayField;
import doido.song.*;
import objects.*;
import objects.play.*;
import objects.ui.hud.*;
import objects.ui.notes.*;
import doido.song.AudioHandler;
import doido.song.SongHandler;
import doido.song.Conductor;
import states.PlayState;
import flixel.FlxSprite;
import doido.utils.NoteUtil;
import doido.utils.EditorUtil;

class ChartTestSubState extends MusicBeatSubState implements Playable
{
	public var SONG:DoidoSong;
	public var audio:AudioHandler;

	public var CHART(get, never):DoidoChart;
	public var META(get, never):DoidoMeta;
	public var EVENTS(get, never):DoidoEvents;

	public var health:Float = 1;
	public var downscroll:Bool = false;
	public var middlescroll:Bool = false;
	public var opponentSide:Bool = false;

	public var validScore:Bool = true;
	public var botplay(default, set):Bool;
	public var songLength(get, never):Float;
	public var player1(get, never):String;
	public var player2(get, never):String;

	var playField:PlayField;
	var hudClass:ClassHud;
	var startPos:Float = 0;

	public function new(SONG:DoidoSong, startPos:Float, opponentSide:Bool)
	{
		super();
		this.SONG = SONG;
		this.startPos = startPos;
		this.opponentSide = opponentSide;
	}

	override function close()
	{
		audio.pause();
		Conductor.songPos = startPos;
		Main.setFpsPos(18, FlxG.height - 125 - Std.int(Main.fpsCounter.bgHeight));
		super.close();
		MusicBeat.activeState.persistentDraw = true;
	}

	override function create()
	{
		super.create();
		Main.setFpsPos(5, 5);
		Timings.init();
		EditorUtil.setCursor(DEFAULT);

		var startOffset:Float = 820;
		Conductor.songPos = startPos - startOffset;

		if (NoteUtil.missSoundList.length <= 0)
			NoteUtil.loadMissSounds();

		var bg = new FlxSprite().loadGraphic(Assets.image('editors/charting/bg/light'));
		bg.screenCenter();
		add(bg);

		downscroll = (#if TOUCH_CONTROLS Save.data.modernControls #else false #end ?true:Save.data.downscroll);
		audio = new AudioHandler(CHART.song, PlayState.songDiff);
		audio.play(Conductor.songPos);

		hudClass = new TestHud(this);
		hudClass.init();
		add(hudClass);

		playField = new PlayField(CHART.notes, CHART.speed, downscroll, middlescroll, META.assets);
		playField.dadStrumline.botplay = !opponentSide;
		playField.dadStrumline.isPlayer = opponentSide;
		playField.bfStrumline.botplay = opponentSide;
		playField.bfStrumline.isPlayer = !opponentSide;
		add(playField);
		setUpInput();

		for (note in CHART.notes)
		{
			if (note.stepTime <= (curStepFloat))
				playField.curSpawnNote++;
		}
	}

	public function setUpInput()
	{
		function updateScore(note:Note, noteDiff:Float)
		{
			var rating = "sick";
			if (note.isHold)
			{
				Timings.addScoreHold(note);
				rating = Timings.addAccuracyHold(note.holdHitPercent);
			}
			else
			{
				Timings.addScore(note, noteDiff);
				rating = Timings.addAccuracyDiff(noteDiff);
				hudClass.popUpCombo(Timings.combo, META.assets.ratings);

				if (!note.missed)
					Timings.notesHit++;
			}

			if (rating != "miss")
				hudClass.popUpRating(rating, META.assets.ratings);
			hudClass.updateScoreTxt();
		}

		function muteVoices()
		{
			NoteUtil.playMissSound();
			audio.muteVoices = true;
		}

		playField.onNoteHit = (note, strumline) ->
		{
			if (note.isHold && !note.isHoldEnd)
				return;

			if (strumline.isPlayer)
			{
				if (note.missed)
					muteVoices();
				else
					audio.muteVoices = false;

				updateScore(note, playField.noteDiff(note.data));
			}
			else
			{
				if (audio.voicesOpp == null)
					audio.muteVoices = false;
			}
		};
		playField.onNoteMiss = (note, strumline) ->
		{
			if (note.isHold && !note.isHoldEnd)
				return;

			if (strumline.isPlayer)
			{
				muteVoices();
				updateScore(note, Timings.getTiming("miss").diff);
			}
		};

		// doing this so it doesn't update when you change the setting mid-song
		var ghostTapping:String = Save.data.ghostTapping.toLowerCase();

		playField.onGhostTap = (lane, strumline) ->
		{
			var punished:Bool = false;
			if (ghostTapping == "off" || (ghostTapping == "idle" && !strumline.ghostTappingIdle))
			{
				punished = true;

				Timings.score -= 100;
				Timings.addAccuracy(Timings.getTiming("bad").judge);

				Timings.addCombo(-1);
				NoteUtil.playMissSound();
				hudClass.updateScoreTxt();
			}
		};
	}

	var paused:Bool = false;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.ESCAPE)
			close();
		else if (Controls.justPressed(PAUSE))
			pauseSong();

		if (FlxG.keys.justPressed.TAB)
		{
			if (FlxG.keys.pressed.SHIFT)
			{
				downscroll = !downscroll;
				hudClass.updatePositions();
				for (strumline in playField.strumlines)
				{
					if (!strumline.hasModchart)
					{
						strumline.downscroll = downscroll;
						strumline.recalculateY();
						strumline.updateNotes(curStepFloat);
					}
				}
			}
			else
				botplay = !botplay;
		}

		if (!paused)
		{
			Conductor.songPos += elapsed * 1000 * audio.speed;
			playField.updateNotes(curStepFloat);
		}
	}

	public function pauseSong()
	{
		if (!paused)
			audio.pause();
		else
			audio.play();

		paused = !paused;
	}

	override function stepHit()
	{
		super.stepHit();
		playField.stepHit(curStep);

		if (!paused)
		{
			if (Conductor.songPos < audio.length - 2000)
				audio.sync();
			else if (Conductor.songPos >= audio.length)
				close();
		}

		hudClass.stepHit(curStep);
	}

	public function get_player1():String
		return META.player1;

	public function get_player2():String
		return META.player2;

	public function get_songLength():Float
		return audio.length;

	public function set_botplay(b:Bool):Bool
	{
		botplay = b;

		if (opponentSide)
			playField.dadStrumline.botplay = b;
		else
			playField.bfStrumline.botplay = b;

		return botplay;
	}

	public function get_CHART():DoidoChart
		return SONG.CHART;

	public function get_EVENTS():DoidoEvents
		return SONG.EVENTS;

	public function get_META():DoidoMeta
		return SONG.META;
}
