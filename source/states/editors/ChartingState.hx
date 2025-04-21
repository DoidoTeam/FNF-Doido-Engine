package states.editors;

import flixel.sound.FlxSound;
import backend.song.Conductor;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import backend.game.GameData.MusicBeatState;
import backend.song.SongData;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import objects.note.*;

class ChartingState extends MusicBeatState
{
	public static var SONG:SwagSong = SongData.defaultSong();
    public static var EVENTS:EventSong = SongData.defaultSongEvents();
	public static var songDiff:String = "normal";

    public static final GRID_SIZE = 40;
    public static var noteNum:Int = 4;

    public static var songList:Array<FlxSound> = [];

    public static final mainGridColor:Array<FlxColor> = [0xFFECEFFF, 0xFFD8DAF6];
    public static final sideGridColor:Array<FlxColor> = [0xFFBDC7FF, 0xFFA7B2E7];
    public var mainGrid:ChartGrid;

    public var songPosLine:FlxSprite;

    public var isTyping:Bool = false;
    public var playing:Bool = false;

    override function create()
    {
        super.create();
        loadAudio();

        var bg = new FlxSprite().loadGraphic(Paths.image("menu/charteditor/background"));
		bg.screenCenter();
		bg.scrollFactor.set();
		add(bg);

        mainGrid = new ChartGrid();
        add(mainGrid);
        mainGrid.truePos.set(
            FlxG.width / 2 - (GRID_SIZE * noteNum),
            FlxG.height / 2
        );

        songPosLine = new FlxSprite().makeGraphic(GRID_SIZE * noteNum * 2, 4, 0xFFFFFFFF);
		songPosLine.setPosition(mainGrid.truePos.x, mainGrid.truePos.y);
		add(songPosLine);
        
        for(section in SONG.notes)
        {
            // notes
            for(note in section.sectionNotes)
            {
                // psych event notes come on
				if(note[1] < 0) continue;

                var daStrumTime:Float = note[0];
				var daNoteData:Int = Std.int(note[1] % 4);
				var daNoteType:String = 'none';
				if(note.length > 2)
					daNoteType = note[3];

                var newNote = new Note();
                newNote.updateData(daStrumTime, daNoteData, daNoteType, PlayState.assetModifier);
                newNote.reloadSprite();
                newNote.setGraphicSize(GRID_SIZE, GRID_SIZE);
				newNote.updateHitbox();

                var isPlayer = (note[1] >= 4);
				if(section.mustHitSection)
					isPlayer = (note[1] <  4);

                newNote.strumlineID = (isPlayer ? 1 : 0);

                mainGrid.notes.push(newNote);
            }
        }
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if(!isTyping)
        {
            if(FlxG.keys.justPressed.ENTER)
            {
                FlxG.mouse.visible = false;
                //addAutoSave();
                PlayState.songDiff = songDiff;
                PlayState.SONG = SONG;
                PlayState.EVENTS = EVENTS;
                Main.switchState(new LoadingState());
                return;
            }

            var mult:Float = (FlxG.keys.pressed.SHIFT ? 4 : 1);
            var move:Float = ((FlxG.keys.pressed.S ? 1 : 0)-(FlxG.keys.pressed.W ? 1 : 0));
            move -= (FlxG.mouse.wheel * 20);

            if(move != 0)
            {
                Conductor.songPos += 1000 * move * mult * elapsed;
                playing = false;
            }
            
            if(FlxG.keys.justPressed.SPACE)
                playing = !playing;
        }

        if(playing)
            Conductor.songPos += elapsed * 1000;
        if(Conductor.songPos < -Conductor.crochet)
            Conductor.songPos = -Conductor.crochet;
        if(Conductor.songPos > songLength)
        {
            playing = false;
            Conductor.songPos = 0;
        }

        for(audio in songList)
        {
            if(playing && Conductor.songPos >= 0)
            {
                if(!audio.playing || Math.abs(audio.time - Conductor.songPos) >= 20) {
                    audio.stop();
                    audio.play();
                    audio.time = Conductor.songPos;
                }
            }
            else if(audio.playing)
                audio.stop();
        }

        mainGrid.truePos.y = (FlxG.height / 2) -
            (Conductor.songPos * ((GRID_SIZE/* * GRID_ZOOM*/) / Conductor.stepCrochet));
            
        if(FlxG.keys.justPressed.NUMPADNINE)
            FlxG.camera.zoom = (FlxG.camera.zoom == 1 ? 0.75 : 1);
    }

    override function stepHit()
    {
        super.stepHit();
    }

    // goes for the shortest audio
	public static var songLength:Float = 0;
	function loadAudio()
	{
		songList = [];
		songLength = 0;
		function addMusic(music:FlxSound):Void
		{
			FlxG.sound.list.add(music);

			if(music.length > 0)
			{
				songList.push(music);

				if(music.length < songLength)
					songLength = music.length;
			}

			music.play();
			music.stop();
		}

		var daSong:String = SONG.song.toLowerCase();

		var inst = new FlxSound();
		inst.loadEmbedded(Paths.inst(daSong, songDiff), false, false);
		songLength = inst.length;
		addMusic(inst);

		if(SONG.needsVoices)
		{
			var vocals = new FlxSound();
			vocals.loadEmbedded(Paths.vocals(daSong, songDiff, '-player'), false, false);
			addMusic(vocals);

			// opponent vocals
			if(Paths.songPath(daSong, 'Voices', songDiff, '-opp').endsWith('-opp'))
			{
				var vocalsOpp = new FlxSound();
				vocalsOpp.loadEmbedded(Paths.vocals(daSong, songDiff, '-opp'), false, false);
				addMusic(vocalsOpp);
			}
		}
	}
}
class ChartGrid extends FlxSprite
{
    final GRID_SIZE = ChartingState.GRID_SIZE;
    final GRID_WIDTH:Int = ChartingState.noteNum * 2;

    public var truePos:FlxPoint = FlxPoint.get();

    public var divLine:FlxSprite;
    public var notes:Array<Note> = [];

    public function new() {
        super();
        makeGraphic(GRID_SIZE, GRID_SIZE, 0xFFFFFFFF);
        antialiasing = false;
        divLine = new FlxSprite().makeGraphic(GRID_SIZE * GRID_WIDTH, 2, 0xFFFFFFFF);
        divLine.antialiasing = false;
    }

    override public function draw()
    {
        y = truePos.y;
        for(section in ChartingState.SONG.notes)
        {
            for(j in 0...section.lengthInSteps)
            {
                // if its onscreen
                if(y > -GRID_SIZE && y < FlxG.height)
                {
                    for(i in 0...GRID_WIDTH)
                    {
                        x = truePos.x + (GRID_SIZE * i);
                        color = ChartingState.mainGridColor[(j + i) % 2];
                        super.draw();
                    }
                    if(j % 4 == 0)
                    {
                        divLine.color = ((j == 0) ? 0xFF000000 : 0xFFFF0000);
                        divLine.setPosition(truePos.x, y);
                        divLine.draw();
                    }
                }
                y += GRID_SIZE;
            }
        }
        for(note in notes)
        {
            note.y = truePos.y + FlxMath.remapToRange(
                note.songTime,
                0, Conductor.stepCrochet,
                0, GRID_SIZE
            );
            if(note.y + note.height > 0 && note.y < FlxG.height)
            {
                note.x = truePos.x + (note.noteData * GRID_SIZE);
                if(note.strumlineID == 1)
                    note.x += (GRID_SIZE * ChartingState.noteNum);
                note.draw();
            }
        }
    }
}
class ChartNote extends Note
{
    public var editorScale:Float = 1.0;

    public function new()
    {
        super();
    }
}