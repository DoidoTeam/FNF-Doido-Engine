package states.editors;

import flixel.addons.display.shapes.FlxShapeBox;
import objects.menu.Alphabet;
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
    public static var EVENTS:SwagEventSong = SongData.defaultSongEvents();
	public static var songDiff:String = "normal";

    public static final GRID_SIZE = 40;
    public static var noteNum:Int = 4;
    public static var gridNum:Int = 1 + 8; // notes and events

    public static var songList:Array<FlxSound> = [];

    public static final mainGridColor:Array<FlxColor> = [0xFFECEFFF, 0xFFD8DAF6];
    public static final sideGridColor:Array<FlxColor> = [0xFFBDC7FF, 0xFFA7B2E7];
    public var mainGrid:ChartGrid;

    public var songPosLine:FlxSprite;

    public var undoList:Array<Void->Void> = []; // fills up with every action
    public var redoList:Array<Void->Void> = []; // very temporary since any action empties it, but useful
    public var isTyping:Bool = false;
    public var playing:Bool = false;

    public static var instance:ChartingState;

    override function create()
    {
        super.create();
        instance = this;
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
        
        // loading the notes from the chart file
        for(note in SONG.notes)
        {
            // psych event notes come on
			if(note.data < 0) continue;

            addNoteToGrid(note);
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

    public function getSwagNote(note:Note):SwagNote
    {
        var returnNote:SwagNote = null;
        for(swagNote in SONG.notes)
        {
            if(swagNote.step == note.stepTime
            && swagNote.data == note.noteData + (4 * note.strumlineID))
            {
                returnNote = swagNote;
            }
        }
        return returnNote;
    }

    public function addNoteToGrid(newNote:SwagNote)
    {
        // notes
        var noteStep:Float = newNote.step;
        var noteData:Int = (newNote.data % 4);
        var noteType:String = (newNote.type != null) ? newNote.type : 'none';

        var swagNote = new ChartNote();
        swagNote.updateData(noteStep, noteData, noteType);
        swagNote.holdStepLength = newNote.holdLength;
        swagNote.reloadSprite();

        swagNote.setGraphicSize(GRID_SIZE, GRID_SIZE);
        swagNote.updateHitbox();

        var isPlayer = (newNote.data >= 4);

        swagNote.strumlineID = isPlayer ? 1 : 0;

        mainGrid.notes.push(swagNote);
        swagNote.setPosition(FlxG.width, FlxG.height);
        swagNote.draw();

        // adding a hold note to it even if its not a hold note
        var holdNote = new ChartNote();
        holdNote.isHold = true;
        holdNote.updateData(noteStep, noteData, noteType);
        holdNote.reloadSprite();
        holdNote.parentNote = swagNote;
        swagNote.children = [holdNote];

        for(note in [swagNote, holdNote])
            note.antialiasing = false;
    }

    public function addNote(?newNote:SwagNote)
    {
        if(newNote == null)
        {
            if(FlxG.mouse.x >= mainGrid.x + GRID_SIZE)
            {
                // notes
                newNote = {
                    step: (mainGrid.hoverSquare.y - mainGrid.y) / GRID_SIZE,
                    data: Math.floor((mainGrid.hoverSquare.x - mainGrid.getGridNoteX()) / GRID_SIZE),
                    holdLength: 0,
                    type: 'none',
                };
            }
            else
            {
                // events
            }
        }
        SONG.notes.push(newNote);
        addNoteToGrid(newNote);
    }
    
    public function removeNote(note:ChartNote)
    {
        var swagNote = getSwagNote(note);
        if(swagNote != null)
            SONG.notes.remove(swagNote);
        if(mainGrid.notes.contains(note))
            mainGrid.notes.remove(note);
        note.destroy();
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

		if(true)
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
    public var hoverSquare:FlxSprite;
    public var divLine:FlxSprite;
    public var beatLine:FlxSprite;
    public var notes:Array<ChartNote> = [];

    public var sectTxt:Alphabet;
    public var sectCount:Int = 0;

    public function getGridNoteX():Float {
        return x + GRID_SIZE;
    }

    public function new() {
        super();
        gridSquare = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE, 0xFFFFFFFF);
        gridSquare.antialiasing = false;

        hoverSquare = new FlxShapeBox(0, 0, GRID_SIZE, GRID_SIZE, {
            thickness: 3,
            color: 0xFF000000,
        }, FlxColor.TRANSPARENT);
        hoverSquare.antialiasing = false;

        beatLine = new FlxSprite().makeGraphic(GRID_SIZE * GRID_WIDTH, 2, 0xFFFFFFFF);
        beatLine.antialiasing = false;

        divLine = new FlxSprite().makeGraphic(2, FlxG.height + 2, 0xFF000000);
        divLine.antialiasing = false;
        divLine.screenCenter(Y);

        sectTxt = new Alphabet(0, 0, "00", true);
        sectTxt.scale.set(0.4,0.4);
        sectTxt.align = RIGHT;
        sectTxt.updateHitbox();
    }

    public var draggingL:Bool = false;

    public var noteOverlap:ChartNote = null;

    override public function draw()
    {
        sectTxt.x = x - 8;
        sectCount = 0;

        // super.draw();
        gridSquare.y = y;
        var stopGrid:Bool = false;
        var gridStep:Int = 0;
        while(!stopGrid)
        {
            // if its onscreen
            if(gridSquare.y > -GRID_SIZE && gridSquare.y < FlxG.height)
            {
                for(i in 0...GRID_WIDTH)
                {
                    gridSquare.x = x + (GRID_SIZE * i);
                    gridSquare.color = ChartingState.mainGridColor[(gridStep + i) % 2];
                    gridSquare.draw();
                }
                if(gridStep % 4 == 0)
                {
                    beatLine.color = ((gridStep == 0) ? 0xFF000000 : 0xFFFF0000);
                    beatLine.setPosition(x, gridSquare.y);
                    beatLine.draw();
                }
                if(gridStep == 0)
                {
                    sectTxt.text = Std.string(sectCount).lpad("0", 2);
                    sectTxt.y = beatLine.y;
                    sectTxt.draw();
                }
                if(FlxG.mouse.x > x && FlxG.mouse.x < x + GRID_SIZE * GRID_WIDTH
                && FlxG.mouse.y > y)
                {
                    hoverSquare.x = x + Math.floor((FlxG.mouse.x - x) / GRID_SIZE) * GRID_SIZE;
			        hoverSquare.y = y + Math.floor((FlxG.mouse.y - y) / GRID_SIZE) * GRID_SIZE;
                    hoverSquare.visible = true;
                } else
                    hoverSquare.visible = false;
            }
            else if(gridSquare.y > FlxG.height)
                stopGrid = true;
            gridSquare.y += GRID_SIZE;
            gridStep = (gridStep + 1) % 16;

            if(gridStep == 0)
                sectCount++;
        }
        divLine.x = x + GRID_SIZE;
        divLine.draw();
        divLine.x += GRID_SIZE * ChartingState.noteNum;
        divLine.draw();

        var hasNoteOverlap:Bool = false;
        for(swagNote in notes)
        {
            swagNote.y = y + swagNote.stepTime * GRID_SIZE;
            if(swagNote.y + swagNote.height + GRID_SIZE * swagNote.holdStepLength > 0
            && swagNote.y < FlxG.height)
            {
                swagNote.x = x + GRID_SIZE + (swagNote.noteData * GRID_SIZE);
                if(swagNote.strumlineID == 1)
                    swagNote.x += (GRID_SIZE * ChartingState.noteNum);
                if(swagNote.holdStepLength > 0)
                {
                    var holdNote = swagNote.children[0];
                    holdNote.setGraphicSize(GRID_SIZE * 0.3, GRID_SIZE * swagNote.holdStepLength);
                    holdNote.updateHitbox();
                    holdNote.x = swagNote.x + GRID_SIZE / 2 - holdNote.width / 2;
                    holdNote.y = swagNote.y + GRID_SIZE;
                    holdNote.draw();
                }
                swagNote.draw();
            }

            if(!draggingL)
            {
                function swapOverlap(noteSwap:ChartNote)
                {
                    if(noteOverlap == null)
                        noteOverlap = noteSwap;
                    else if(noteSwap.y > noteOverlap.y)
                        noteOverlap = noteSwap;
                }
                
                if(FlxG.mouse.overlaps(swagNote))
                {
                    swapOverlap(swagNote);
                    hasNoteOverlap = true;
                }
                if(swagNote.holdStepLength > 0)
                {
                    var swagHold = swagNote.children[0];
                    if(FlxG.mouse.overlaps(swagHold))
                    {
                        swapOverlap(cast swagHold);
                        hasNoteOverlap = true;
                    }
                }
                
                if(!hasNoteOverlap)
                {
                    noteOverlap = null;
                }
                else
                {
                    CoolUtil.setCursor(POINTER);
                }
            }
        }
        if(hoverSquare.visible)
        {
            hoverSquare.draw();
            if(noteOverlap != null)
            {
                draggingL = FlxG.mouse.pressed;
                var formatOverlap = (noteOverlap.isHold ? noteOverlap.parentNote : noteOverlap);

                var swagNote:SwagNote = ChartingState.instance.getSwagNote(formatOverlap);
                if(draggingL)
                {
                    var gridOffset:Float = (noteOverlap.isHold ? 0 : GRID_SIZE);
                    var stepLength:Float = Math.round((FlxG.mouse.y - (noteOverlap.y + gridOffset)) / GRID_SIZE);
                    if(stepLength < 0)
                        stepLength = 0;

                    formatOverlap.holdStepLength = stepLength;
                    swagNote.holdLength = stepLength;
                }
                
                if(!noteOverlap.isHold)
                {
                    if(FlxG.mouse.pressedRight)
                        ChartingState.instance.removeNote(noteOverlap);
                }
            }
            else if(FlxG.mouse.x >= x && FlxG.mouse.x <= x + GRID_SIZE * GRID_WIDTH && FlxG.mouse.y >= y)
            {
                if(FlxG.mouse.justReleased)
                {
                    ChartingState.instance.addNote();
                }
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