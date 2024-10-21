package data;

typedef DialogueData = {
	var pages:Array<DialoguePage>;
}
typedef DialoguePage = {
	// box
	var ?boxSkin:String;
	// character
	var ?char:String;
	var ?charAnim:String;
	// images
	var ?underlayAlpha:Float;
	var ?background:DialogueSprite;
	var ?foreground:DialogueSprite;
	// dialogue text
	var ?text:String;
	// text settings
	var ?textDelay:Float;
	var ?fontFamily:String;
	var ?fontScale:Float;
	var ?fontColor:Int;
	var ?fontBold:Bool;
	// text border
	var ?fontBorderType:String;
	var ?fontBorderColor:Int;
	var ?fontBorderSize:Float;
	// music and sound
	var ?music:String;
	var ?clickSfx:String;
	var ?scrollSfx:Array<String>;
}

typedef DialogueSprite = {
	var name:String;
	var image:String;
	// position
	var ?x:Float;
	var ?y:Float;
	var ?screenCenter:String;
	// other sprite stuff
	var ?scale:Float;
	var ?alpha:Float;
	// flipping
	var ?flipX:Bool;
	var ?flipY:Bool;
	// animation array
	var ?animations:Array<Animation>;
}

typedef Animation = {
	var name:String;
	var prefix:String;
	var framerate:Int;
	var looped:Bool;
}

class DialogueUtil
{
	public static function loadDialogue(song:String):DialogueData
	{
		switch(song)
		{
			case 'senpai' | 'roses' | 'thorns':
				return loadCode(song);
			default:
				if(Paths.fileExists('images/dialogue/data/$song.json'))
					return cast Paths.json('images/dialogue/data/$song');
				else
					return defaultDialogue();
		};
	}

	inline public static function defaultDialogue():DialogueData
		return{pages: []};

	// Hardcoded DialogueData
	public static function loadCode(song:String):DialogueData
	{
		return switch(song)
		{
			case 'senpai':
				{
					pages:[
						{
							boxSkin: 'school',
							fontFamily: 'pixel.otf',
							fontColor: 0xFF3F2021,
							fontScale: 0.8,
							
							fontBorderType: 'shadow',
							fontBorderColor: 0xFFD89494,
							fontBorderSize: 4,

							music: 'dialogue/lunchbox',
							clickSfx: 'dialogue/clickText',
							scrollSfx: ['dialogue/talking'],
							
							// character
							char: 'senpai',
							
							text: 'Ah, a new fair maiden has come in search of true love!'
						},
						{
							text: 'A serenade between gentlemen shall decide where her beautiful heart shall reside.'
						},
						{
							char: 'bf-pixel',
							text: 'Beep bo bop'
						}
					]
				}
			
			case 'roses':
				{
					pages:[
						{
							boxSkin: 'school',
							fontFamily: 'pixel.otf',
							fontColor: 0xFF3F2021,
							fontScale: 0.8,
							
							fontBorderType: 'shadow',
							fontBorderColor: 0xFFD89494,
							fontBorderSize: 4,

							music: 'dialogue/lunchbox',
							clickSfx: 'dialogue/clickText',
							scrollSfx: ['dialogue/talking'],

							// character
							char: 'senpai-angry',
							
							text: 'Not bad for an ugly worm.',
						},
						{
							text: "But this time I'll rip your nuts off right after your girlfriend finishes gargling mine."
						},
						{
							char: 'bf-pixel',
							text: 'Bop beep be be skdoo bep',
						}
					]
				}
				
			case 'thorns':
				{
					pages:[
						{
							boxSkin: 'school-evil',
							fontFamily: 'pixel.otf',
							fontColor: 0xFFFFFFFF,
							fontScale: 0.8,
							fontBorderSize: 0,

							clickSfx: 'dialogue/clickText',
							scrollSfx: ['dialogue/talking'],

							// character
							char: 'spirit',
							
							text: 'Direct contact with real humans, after being trapped in here for so long...',
							textDelay: 5
						},
						{
							text: "and HER of all people."
						},
						{
							text: "I'll make her father pay for what he's done to me and all the others...."
						},
						{
							text: "I'll beat you and make you take my place."
						},
						{
							fontColor: 0xFFFF0000,
							text: "You don't mind your bodies being borrowed right?",
							textDelay: 3.4
						},
						{
							fontScale: 2.5,
							text: "It's only fair...",
							textDelay: 16
						},
					]
				}
			
			default:
				defaultDialogue();
		}
	}
}