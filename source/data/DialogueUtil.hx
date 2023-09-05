package data;

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
							// character
							charLeft:  'senpai',
							charRight: '',
							charFocus: 'left',
							
							text: 'Ah, a new fair maiden has come\nin search of true love!',
						},
						{
							text: 'A serenade between gentlemen shall decide\nwhere her beautiful heart shall reside.'
						},
						{
							charRight: 'bf-pixel',
							charFocus: 'right',
							text: 'Beep bo bop',
						}
					]
				}
			
			case 'roses':
				{
					pages:[
						{
							boxSkin: 'school',
							// character
							charLeft:  'senpai-angry',
							charRight: '',
							charFocus: 'left',
							
							text: 'Not bad for an ugly worm.',
						},
						{
							text: "But this time I'll rip your nuts off right\nafter your girlfriend finishes gargling mine."
						},
						{
							charRight: 'bf-pixel',
							charFocus: 'right',
							text: 'Bop beep be be skdoo bep',
						}
					]
				}
				
			case 'thorns':
				{
					pages:[
						{
							boxSkin: 'school-evil',
							// character
							charLeft:  'spirit',
							charRight: '',
							charFocus: 'left',
							
							text: 'Direct contact with real humans,\nafter being trapped in here for so long...',
						},
						{
							text: "and HER of all people."
						},
						{
							text: "I'll make her father pay for what he's\ndone to me and all the others...."
						},
						{
							text: "I'll beat you and make you take my place."
						},
						{
							text: "You don't mind your bodies being borrowed right?"
						},
						{
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