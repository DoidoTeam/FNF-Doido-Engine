package doido.utils;

import states.PlayState;
import doido.song.SongHandler;
import flixel.util.FlxSort;

typedef Event =
{
	var name:String;
	var desc:String;
	var values:Array<EventValue>;
	// var type:String; -- ????
}

typedef EventValue =
{
	var name:String;
	var ?info:String;
	var defaultValue:Dynamic;

	// dropdown
	var ?options:Array<Dynamic>;

	// steppers
	var ?step:Float;
	var ?min:Float;
	var ?max:Float;
	var ?decimals:Int;
}

class EventUtil
{
	public static var events:Array<Event> = [
		/*{
			name: "Test Event",
			desc: "Event with the sole purpose of testing value fields.",
			values: [
				{
					name: "Dropdown",
					info: "Which Character to play animation on.",
					defaultValue: "dad",
					options: PlayState.availableCharacters
				},
				{
					name: "Text",
					info: "Which animation to play.",
					defaultValue: "idle",
				},
				{
					name: "Float",
					info: "Speed at which the notes should scroll at.",
					defaultValue: 2.0,
				},
				{
					name: "Int",
					info: "Speed but as an int",
					defaultValue: 5,
					step: 1,
					min: 0,
					max: 10
				},
				{
					name: "Checkmark",
					defaultValue: false
				},
			]
		},*/
		{
			name: "Camera Focus",
			desc: "Focus the camera on a specific character.",
			values: [
				{
					name: "Character",
					info: "Which Character to focus on.",
					defaultValue: "dad",
					options: PlayState.availableCharacters
				},
				{
					name: "X Offset",
					info: "Offset along the x axis.",
					defaultValue: 0,
					min: 0,
					max: 2000,
					step: 50,
					decimals: 0
				},
				{
					name: "Y Offset",
					info: "Offset along the y axis.",
					defaultValue: 0,
					min: 0,
					max: 2000,
					step: 50,
					decimals: 0
				}
			]
		},
		{
			name: "Play Animation",
			desc: "Make a Character play a specific animation.",
			values: [
				{
					name: "Character",
					info: "Which Character to play animation on.",
					defaultValue: "dad",
					options: PlayState.availableCharacters
				},
				{
					name: "Animation",
					info: "Which animation to play.",
					defaultValue: "idle",
				},
			]
		},
		{
			name: "Change Character",
			desc: "Change a specific Character.",
			values: [
				{
					name: "Target",
					info: "Which target Character to change.",
					defaultValue: "dad",
					options: PlayState.availableCharacters
				},
				{
					name: "New Character",
					info: "Which Character to change to.",
					defaultValue: "face",
					// options: PlayState.availableCharacters // nota, mudar para lista dos personagens
				},
			]
		},
		{
			name: "Freeze Notes",
			desc: "Stop note scroll indefinitely, or until changed.",
			values: [
				{
					name: "Enabled",
					defaultValue: false
				},
			]
		},
		{
			name: "Change Note Speed",
			desc: "Change the speed at which notes scroll.",
			values: [
				{
					name: "Speed",
					info: "Speed at which the notes should scroll at.",
					defaultValue: 2.0,
				},
				{
					name: "Duration",
					info: "How long the tween will take, in steps. Setting to 0 will disable tween.",
					defaultValue: 4.0,
				}
			]
		}
	];

	public static function getEvent(name:String):Event
	{
		for (e in events)
			if (e.name == name)
				return e;

		return null;
	}

	public static function getEventSprite(name:String):String
	{
		var eventName:String = name.toLowerCase().replace(' ', '_');

		if (!Assets.fileExists('images/editors/charting/events/$eventName', IMAGE))
			eventName = "unknown_event";

		return 'editors/charting/events/$eventName';
	}

	public static function sortEvents(Obj1:EventData, Obj2:EventData):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.stepTime, Obj2.stepTime);
}
