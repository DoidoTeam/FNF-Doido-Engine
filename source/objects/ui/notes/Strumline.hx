package objects.ui.notes;

import doido.song.Conductor;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import objects.ui.notes.Splash.Cover;

class Strumline extends FlxGroup
{
	public var x:Float = 0;
	public var downscroll:Bool = false;
	public var isPlayer:Bool = false;
	public var botplay:Bool = false;
	public var wide:Bool = false;

	public var scrollSpeed:Float = 1.0;

	public var hasModchart:Bool = false;
	public var pauseNotes:Bool = false;
	public var spawnStep:Float = 32;
	public var despawnStep:Float = 12;
	public var holdResolution:Float = 1;

	// checking if you can ghost tap with the "idle" option
	public var ghostTappingIdle:Bool = true;
	public var holdingNotes:Array<Bool> = [];

	public var quantNotes:Bool = Save.data.quantNotes;

	// use these to access the sprites
	public var strums:Array<StrumNote> = [];
	public var notes:Array<Note> = [];

	public var skin:String = "base";

	public function new(xOffset:Float, downscroll:Bool = false, isPlayer:Bool = false, botplay:Bool = false, wide:Bool = false, ?skin:String = "base")
	{
		super();
		x = (FlxG.width / 2) + xOffset;
		this.downscroll = downscroll;
		this.isPlayer = isPlayer;
		this.botplay = botplay;
		this.wide = wide;

		if (quantNotes)
			skin += '-quant';
		this.skin = skin;

		for (i in 0...4)
			holdingNotes.push(false);

		for (i in 0...NoteUtil.directions.length)
		{
			var strum = new StrumNote();
			strum.reloadStrum(i, skin);
			strum.zIndex = 0;
			strums.push(strum);
			add(strum);
		}

		recalculateX();
		recalculateY();
	}

	public function addNote(noteData:NoteData)
	{
		var holdResolution:Float = this.holdResolution;
		if (Save.data.lowQuality)
			holdResolution = 1;

		var note:Note = cast recycle(Note);
		note.loadData(noteData, skin);
		note.reloadSprite();
		note.zIndex = 2;
		notes.push(note);
		if (!members.contains(note))
			add(note);

		// searchs for hold notes
		if (noteData.length > 0)
		{
			var holdLength:Int = Math.ceil((noteData.length * holdResolution) + 1);
			var holdIndex:Float = 0.0;
			for (i in 0...holdLength)
			{
				var hold:Note = cast recycle(Note);
				hold.loadData(noteData, skin);

				hold.isHold = true;
				hold.isHoldEnd = (i == holdLength - 1);

				var step:Float = 1.0;
				if (i == holdLength - 2)
				{
					step = noteData.length - Math.floor(noteData.length);
					if (step <= 0.0)
						step = 1.0; // oh well
				}
				else if (hold.isHoldEnd)
					step = 0.5;

				hold.holdStep = step / (hold.isHoldEnd ? 1 : holdResolution);

				hold.holdIndex = holdIndex;
				note.children.push(hold);

				hold.reloadSprite();
				hold.holdParent = note;
				hold.zIndex = 1;
				notes.push(hold);
				if (!members.contains(hold))
					add(hold);

				holdIndex += hold.holdStep;
			}
		}

		sort(ZIndex.sort);
	}

	public function killNote(note:Note)
	{
		notes.remove(note);
		note.kill();
	}

	public function updateNotes(curStepFloat:Float)
	{
		var downMult:Int = (downscroll ? -1 : 1);

		for (note in notes)
		{
			var strum = strums[note.data.lane];
			var noteSpeed:Float = note.noteSpeed ?? scrollSpeed;
			noteSpeed *= note.noteSpeedMult;

			var noteTime:Float = (note.data.stepTime - curStepFloat);
			if (note.isHold)
				noteTime += note.holdIndex;

			var offsetX = 0.0; // note.noteOffset.x;
			var offsetY = (noteTime) * Conductor.stepCrochet * (noteSpeed * 0.45);
			var angle = note.noteAngle ?? strum.strumAngle;

			if (downscroll)
				angle += 180;

			if (note.isHold)
			{
				note.angle = -angle * downMult;
				var holdHeight:Float = note.holdStep * Conductor.stepCrochet * (noteSpeed * 0.45) + 2;
				note.scale.y = (holdHeight / note.frameHeight);
				note.updateHitbox();
			}

			note.updateOffsets();
			NoteUtil.setNotePos(note, strum, angle * downMult, offsetX, offsetY);
		}
		updateHoldClipping(curStepFloat);
	}

	public function updateHoldClipping(curStepFloat:Float)
	{
		// calculating the clipping by how much you held the note
		for (hold in notes)
		{
			if (!hold.isHold)
				continue;

			if (!hold.missed)
			{
				var holdHitLength = (curStepFloat - hold.data.stepTime);
				var daRect = (hold.clipRect ?? new FlxRect());
				daRect.set(0, 0, hold.frameWidth, hold.frameHeight);

				var rawSize:Float = (holdHitLength - hold.holdIndex);
				if (rawSize > 0)
				{
					daRect.y = FlxMath.remapToRange(rawSize, 0.0, hold.holdStep, 0.0, hold.frameHeight);
					if (daRect.y > daRect.height)
						daRect.y = daRect.height;
				}

				hold.clipRect = daRect;
			}
		}
	}

	public function addSplash(note:Note)
	{
		var splash:Splash = cast recycle(Splash);
		splash.loadData(note, skin);
		splash.zIndex = 3;
		splash.x = strums[note.data.lane].x;
		splash.y = strums[note.data.lane].y;
		splash.reloadSplash();
		if (!members.contains(splash))
			add(splash);
		sort(ZIndex.sort);
	}

	public function addCover(note:Note, splashEnabled:Bool = true)
	{
		var cover:Cover = cast recycle(Cover);
		cover.loadData(note, skin);
		cover.splashEnabled = splashEnabled;
		cover.zIndex = 3;
		cover.x = strums[note.data.lane].x;
		cover.y = strums[note.data.lane].y;
		cover.strum = strums[note.data.lane];
		cover.reloadSplash();
		if (!members.contains(cover))
			add(cover);
		sort(ZIndex.sort);
	}

	public function recalculateX()
	{
		for (strum in strums)
		{
			strum.x = x;
			strum.x += NoteUtil.noteWidth(wide) * strum.lane;
			strum.x -= (NoteUtil.noteWidth(wide) * (strums.length - 1)) / 2;
			if (wide)
				strum.x += (strum.lane < (NoteUtil.directions.length / 2) ? -100 : 100);

			strum.initialPos.x = strum.x;
		}
	}

	public function recalculateY()
	{
		for (strum in strums)
		{
			strum.y = (!downscroll ? 110 : FlxG.height - 110);
			strum.initialPos.y = strum.y;
		}
	}
}
