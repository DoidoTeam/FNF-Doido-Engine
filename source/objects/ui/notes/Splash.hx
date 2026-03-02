package objects.ui.notes;

import flixel.FlxSprite;
import objects.ui.notes.Note;
import doido.song.Timings;

class Splash extends BaseSplash
{
	override public function reloadSplash() {
		var direction:String = NoteUtil.intToString(note.data.lane);
        switch("la la la") {
			default:
				this.loadSparrow("notes/base/splashes");
				animation.addByPrefix("splash1", '$direction splash 1', 24, false);
				animation.addByPrefix("splash2", '$direction splash 2', 24, false);
				splashScale = 0.7;
		}

        alpha = startAlpha;
        scale.set(splashScale, splashScale);
		updateHitbox();
		playRandom();
	}

	private function playRandom(play:Bool = false) {
		var animList = animation.getNameList();
		playAnim(animList[FlxG.random.int(0, animList.length - 1)], true);
        splashed = true;
	}
}

class Cover extends BaseSplash
{
	public var strum:StrumNote = null;
	override public function reloadSplash() {
        var direction:String = NoteUtil.intToString(note.data.lane);
        switch("la la la") {
			default:
				this.loadSparrow("notes/base/covers");
				splashScale = 0.7;

				direction = direction.toUpperCase();
				animation.addByPrefix("start", 	'holdCoverStart$direction', 24, false);
				animation.addByPrefix("loop",  	'holdCover$direction', 		24, true);
				animation.addByPrefix("splash",	'holdCoverEnd$direction', 	24, false);
				
				for(anim in ["start", "loop", "splash"])
					addOffset(anim, 6, -28);
		}

        alpha = startAlpha;
        scale.set(splashScale, splashScale);
		updateHitbox();
		playAnim("start");
    }

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if(strum != null) {
			setPosition(strum.x, strum.y);
			if(strum.animation.curAnim.name != "confirm" || note.holdHitPercent >= 1.0) {
				if(animation.curAnim.name != "splash") {
					trace(note.holdHitPercent);
					if(note.holdHitPercent < Timings.timings.get("sick").hold)
						kill();
					else
						playAnim("splash");
				}
			}
		}
		
		if(animation.finished) {
			switch(animation.curAnim.name) {
				case "start": playAnim('loop');
				case "splash": splashed = true;
			}
		}
	}
}

class BaseSplash extends DoidoSprite
{
    public var startAlpha:Float = 1.0;
    public var splashScale:Float = 1.0;
    public var splashed:Bool = false;
    public var note:Note;
    
    public function new() {
		super();
	}

	public function loadData(note:Note) {
        visible = true;
		splashed = false;
		this.note = note;
	}

    public function reloadSplash() {}

    override function update(elapsed:Float) {
		super.update(elapsed);
        if(curAnimFinished && splashed)
            kill();
	}

	//offsets are set differently for splashes, since they're centered by default
	//multiple things break if you change it but be sure you update the hitbox and dont multiply the offsets by the scale
	override public function updateOffset() {
		updateHitbox();
		offset.x += frameWidth * scale.x / 2;
		offset.y += frameHeight* scale.y / 2;
		if(animOffsets.exists(curAnimName))
		{
			var daOffset = animOffsets.get(curAnimName);
			offset.x += daOffset[0];
			offset.y += daOffset[1];
		}
	}
}