package states.editors;

import backend.game.GameData.MusicBeatState;
import backend.song.SongData;
import backend.song.Conductor;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import objects.note.*;

class ChartingState extends MusicBeatState
{
	public static var SONG:SwagSong = SongData.defaultSong();
    public static var EVENTS:EventSong = SongData.defaultSongEvents();
	public static var songDiff:String = "normal";

    public static final GRID_SIZE = 40;
    public static var noteNum:Int = 4;
    public static var gridNum:Int = 9;

    public static var songList:Array<FlxSound> = [];

    public static final mainGridColor:Array<FlxColor> = [0xFFECEFFF, 0xFFD8DAF6];
    public static final sideGridColor:Array<FlxColor> = [0xFFBDC7FF, 0xFFA7B2E7];
    public var mainGrid:ChartGrid;

    public var songPosLine:FlxSprite;

    public var undoList:Array<Void->Void> = [];
    public var redoList:Array<Void->Void> = [];
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

        var backGrid = new FlxSprite();
        backGrid.makeGraphic((GRID_SIZE * gridNum) + 8, FlxG.height + 2, 0xFF000000);
        backGrid.screenCenter();
        add(backGrid);

        mainGrid = new ChartGrid();
        mainGrid.setPosition(
            FlxG.width / 2 - (GRID_SIZE * gridNum / 2),
            FlxG.height / 2
        );
        add(mainGrid);
        
        songPosLine = new FlxSprite().makeGraphic(GRID_SIZE * gridNum, 4, 0xFFFFFFFF);
		songPosLine.setPosition(mainGrid.x, mainGrid.y);
		add(songPosLine);
        
        for(section in SONG.notes)
        {
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
                newNote.draw();
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

        mainGrid.y = (FlxG.height / 2) -
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
    final GRID_WIDTH:Int = ChartingState.gridNum;

    public var gridSquare:FlxSprite;
    public var divLine:FlxSprite;
    public var beatLine:FlxSprite;
    public var notes:Array<Note> = [];

    public function new() {
        super();
        gridSquare = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE, 0xFFFFFFFF);
        gridSquare.antialiasing = false;

        beatLine = new FlxSprite().makeGraphic(GRID_SIZE * GRID_WIDTH, 2, 0xFFFFFFFF);
        beatLine.antialiasing = false;

        divLine = new FlxSprite().makeGraphic(2, FlxG.height + 2, 0xFF000000);
        divLine.antialiasing = false;
        divLine.screenCenter(Y);
    }

    override public function draw()
    {
        // super.draw();
        gridSquare.y = y;
        for(section in ChartingState.SONG.notes)
        {
            for(j in 0...section.lengthInSteps)
            {
                // if its onscreen
                if(gridSquare.y > -GRID_SIZE && gridSquare.y < FlxG.height)
                {
                    for(i in 0...GRID_WIDTH)
                    {
                        gridSquare.x = x + (GRID_SIZE * i);
                        gridSquare.color = ChartingState.mainGridColor[(j + i) % 2];
                        gridSquare.draw();
                    }
                    if(j % 4 == 0)
                    {
                        beatLine.color = ((j == 0) ? 0xFF000000 : 0xFFFF0000);
                        beatLine.setPosition(x, gridSquare.y);
                        beatLine.draw();
                    }
                }
                gridSquare.y += GRID_SIZE;
            }
        }
        divLine.x = x + GRID_SIZE;
        divLine.draw();
        divLine.x += GRID_SIZE * ChartingState.noteNum;
        divLine.draw();
        for(note in notes)
        {
            note.y = y + FlxMath.remapToRange(
                note.songTime,
                0, Conductor.stepCrochet,
                0, GRID_SIZE
            );
            if(note.y + note.height > 0 && note.y < FlxG.height)
            {
                note.x = x + GRID_SIZE + (note.noteData * GRID_SIZE);
                if(note.strumlineID == 1)
                    note.x += (GRID_SIZE * ChartingState.noteNum);
                note.draw();
            }

            if(FlxG.mouse.overlaps(note))
            {
                //CoolUtil.setCursor(POINTER);
                
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