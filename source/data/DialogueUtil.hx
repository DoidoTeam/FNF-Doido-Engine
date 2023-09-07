package data;

import flixel.text.FlxText.FlxTextBorderStyle;
import gameObjects.Dialogue.DialogueData;
import gameObjects.Dialogue.DialoguePage;

class DialogueUtil
{
	public static function loadFromJson(jsonPath:String):DialogueData
	{
		return cast Paths.json('images/dialogue/data/' + jsonPath);
	}
	
	/*
	*	senpai week stuff
	*/
	public static function loadFromSong(song:String):DialogueData
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
							
							fontBorderType: SHADOW,
							fontBorderColor: 0xFFD89494,
							fontBorderSize: 4,
							
							// character
							char: 'senpai',
							
							text: 'Ah, a new fair maiden has come in\nsearch of true love!',
						},
						{
							text: 'A serenade between gentlemen shall\ndecide where her beautiful heart shall\nreside.'
						},
						{
							char: 'bf-pixel',
							text: 'Beep bo bop',
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
							
							fontBorderType: SHADOW,
							fontBorderColor: 0xFFD89494,
							fontBorderSize: 4,
							// character
							char: 'senpai-angry',
							
							text: 'Not bad for an ugly worm.',
						},
						{
							text: "But this time I'll rip your nuts off\nright after your girlfriend finishes\ngargling mine."
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
							// character
							char:  'spirit',
							
							text: 'Direct contact with real humans, after\nbeing trapped in here for so long...',
						},
						{
							text: "and HER of all people."
						},
						{
							text: "I'll make her father pay for what he's done\nto me and all the others...."
						},
						{
							text: "I'll beat you and make you take my place."
						},
						{
							fontColor: 0xFFFF0000,
							text: "You don't mind your bodies being borrowed\nright?"
						},
						{
							fontScale: 2.5,
							text: "It's only fair..."
						},
					]
				}
			
			default:
				{
					pages: [],
				}
		}
	}
}