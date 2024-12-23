package objects.note;

import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;
import objects.CharGroup;

class Strumline extends FlxGroup
{
	public var strumGroup:FlxTypedGroup<StrumNote>;
	public var noteGroup:FlxTypedGroup<Note>;
	public var holdGroup:FlxTypedGroup<Note>;
	public var allNotes:FlxTypedGroup<Note>;

	public var splashGroup:FlxTypedGroup<SplashNote>;
	public var coverGroup:FlxTypedGroup<SplashNote>;
	
	public var x:Float = 0;
	public var downscroll:Bool = false;
	
	public var pauseNotes:Bool = false;
	public var scrollSpeed:Float = 2.8;
	public var scrollTween:FlxTween;

	public var isPlayer:Bool = false;
	public var botplay:Bool = false;
	public var customData:Bool = false;

	public var character:CharGroup;

	public function new(x:Float, ?character:CharGroup, ?downscroll:Bool, ?isPlayer = false, ?botplay = true, ?assetModifier:String = "base")
	{
		super();
		this.x = x;
		this.downscroll = downscroll;
		this.isPlayer 	= isPlayer;
		this.botplay 	= botplay;
		this.character 	= character;
		
		allNotes = new FlxTypedGroup<Note>();
		
		add(strumGroup 	= new FlxTypedGroup<StrumNote>());
		add(holdGroup 	= new FlxTypedGroup<Note>());
		add(coverGroup 	= new FlxTypedGroup<SplashNote>());
		add(splashGroup = new FlxTypedGroup<SplashNote>());
		add(noteGroup 	= new FlxTypedGroup<Note>());
		
		for(i in 0...4)
		{
			var strum = new StrumNote();
			strum.reloadStrum(i, assetModifier);
			strumGroup.add(strum);
		}

		updateHitbox();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
	
	public function addNote(note:Note)
	{
		allNotes.add(note);
		if(note.isHold)
			holdGroup.add(note);
		else
			noteGroup.add(note);
	}

	public function removeNote(note:Note)
	{
		allNotes.remove(note);
		if(note.isHold)
			holdGroup.remove(note);
		else
			noteGroup.remove(note);
	}

	// only one splash per note
	public var spawnedSplashes:Array<String> = [];
	public function addSplash(note:Note)
	{
		// left-base-none
		var splashName:String
		= CoolUtil.getDirection(note.noteData) + '-'
		+ note.assetModifier + '-'
		+ note.noteType;

		if(!spawnedSplashes.contains(splashName))
		{
			spawnedSplashes.push(splashName);
			
			var splash = new SplashNote();
			splash.updateData(note);
			splashGroup.add(splash);
		}
		// preloading covers
		if(note.children.length > 0)
		{
			splashName += "-cover";
			if(!spawnedSplashes.contains(splashName))
			{
				spawnedSplashes.push(splashName);

				var splash = new SplashNote(true);
				splash.updateData(note.children[note.children.length - 1]);
				coverGroup.add(splash);
				splash.destroy();
			}
		}
	}

	public function playSplash(note:Note, isHold:Bool = false)
	{
		switch(SaveData.data.get("Note Splashes"))
		{
			case "PLAYER ONLY": if(!isPlayer) return;
			case "OFF": return;
		}
		var thisStrum = strumGroup.members[note.noteData];
		if(!isHold)
		{
			for(splash in splashGroup.members)
			{
				if(splash.assetModifier == note.assetModifier
				&& splash.noteType == note.noteType
				&& splash.noteData == note.noteData)
				{
					splash.playRandom();
					splash.x = thisStrum.x;
					splash.y = thisStrum.y;
				}
			}
		}
		else
		{
			if(!SaveData.data.get("Hold Splashes")) return;

			var splash = new SplashNote(true);
			splash.holdStrum = thisStrum;
			splash.updateData(note);
			splash.x = thisStrum.x;
			splash.y = thisStrum.y;
			coverGroup.add(splash);
		}
	}
	
	/*
	*	sets up the notes positions
	*	you can change it but i dont recommend it
	*/
	public function updateHitbox()
	{
		for(strum in strumGroup)
		{
			strum.y = (!downscroll ? 110 : FlxG.height - 110);
			
			strum.x = x;
			strum.x += CoolUtil.noteWidth() * strum.strumData;
			
			strum.x -= (CoolUtil.noteWidth() * (strumGroup.members.length - 1)) / 2;
			
			strum.initialPos.set(strum.x, strum.y);
		}
	}
}