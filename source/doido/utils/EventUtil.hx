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
	var ?getOptions:Void->Array<Dynamic>;

	// steppers
	var ?step:Float;
	var ?min:Float;
	var ?max:Float;
	var ?decimals:Int;
}

class EventUtil
{
	public static var eventLists:Map<String, Array<String>> = [
		"Main" => ["Camera", "Objects", "Screen", "Gameplay", "Misc"],
		"Camera" => ["Camera Focus", "Change Cam Zoom"],
		"Objects" => ["Change Character", "Play Animation", "Change Stage"],
		"Screen" => ["Flash Screen", "Fade Screen"],
		"Gameplay" => ["Change Note Speed", "Freeze Notes"],
		"Misc" => ["Trigger Tag"]
	];

	public static var events:Array<Event> = [
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
			name: "Change Cam Zoom",
			desc: "Change the Camera Zoom.",
			values: [
				{
					name: "New Zoom",
					info: "How much zoom to change to.",
					defaultValue: 1,
					min: 0.1,
					max: 3,
					step: 0.05,
					decimals: 2
				},
				{
					name: "Duration",
					info: "How long the zoom will take, in steps. If 0, zoom will be instant or lerp.",
					defaultValue: 4,
					min: 0,
					max: 128,
					step: 1,
					decimals: 0
				},
				{
					name: "Easing",
					info: "Easing function to make your tweens smoother.",
					defaultValue: "linear",
					options: TweenUtil.availableEases
				},
				{
					name: "Modifier",
					info: "Modifier that declares where the easing is applied to the tween.",
					defaultValue: "InOut",
					options: TweenUtil.availableModifiers
				},
				/*{
					name: "Lerping",
					info: "If enabled, will use a classic lerp smoothing.",
					defaultValue: false
				},*/
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
					getOptions: () -> return Assets.list("data/characters/", true, JSON).concat(["face"]),
				},
			]
		},
		{
			name: "Change Stage",
			desc: "Change to specific Stage.",
			values: [
				{
					name: "New Stage",
					info: "Which Stage to change to.",
					defaultValue: "stage",
					getOptions: () -> return Assets.list("data/scripts/stages/", true, SCRIPT),
				},
			]
		},
		{
			name: "Flash Screen",
			desc: "Flash a Camera with a specific color.",
			values: [
				{
					name: "Duration",
					info: "How long the flash will take, in steps.",
					defaultValue: 5,
					min: 1,
					max: 128,
					step: 1,
					decimals: 0
				},
				{
					name: "Color",
					info: "What color to flash the screen with.",
					defaultValue: "WHITE"
				},
				{
					name: "Camera",
					info: "Which camera to flash.",
					defaultValue: "Game",
					options: PlayState.availableCameras
				}
			]
		},
		{
			name: "Fade Screen",
			desc: "Fade to or from a screen.",
			values: [
				{
					name: "Fade In",
					info: "If enabled, will fade in from the selected color.",
					defaultValue: false
				},
				{
					name: "Duration",
					info: "How long the fade will take, in steps.",
					defaultValue: 16,
					min: 1,
					max: 128,
					step: 1,
					decimals: 0
				},
				{
					name: "Color",
					info: "What color to fade the screen with.",
					defaultValue: "BLACK"
				},
				{
					name: "Camera",
					info: "Which camera to fade.",
					defaultValue: "Game",
					options: PlayState.availableCameras
				}
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
					min: 0.1,
					max: 10,
					step: 0.1,
					decimals: 1
				},
				{
					name: "Duration",
					info: "How long the tween will take, in steps. Setting to 0 will disable tween.",
					defaultValue: 4,
					min: 0,
					max: 128,
					step: 1,
					decimals: 0
				},
				{
					name: "Easing",
					info: "Easing function to make your tweens smoother.",
					defaultValue: "linear",
					options: TweenUtil.availableEases
				},
				{
					name: "Modifier",
					info: "Modifier that declares where the easing is applied to the tween.",
					defaultValue: "InOut",
					options: TweenUtil.availableModifiers
				}
			]
		},
		{
			name: "Trigger Tag",
			desc: "Create a custom event.",
			values: [
				{
					name: "Tag",
					info: "Tag which declares which custom event to play.",
					defaultValue: ""
				},
				{
					name: "Value 1",
					info: "Value 1",
					defaultValue: ""
				},
				{
					name: "Value 2",
					info: "Value 2",
					defaultValue: ""
				},
				{
					name: "Value 3",
					info: "Value 3",
					defaultValue: ""
				},
				{
					name: "Value 4",
					info: "Value 4",
					defaultValue: ""
				},
				{
					name: "Value 5",
					info: "Value 5",
					defaultValue: ""
				},
			]
		},
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
	];

	public static function getEvent(name:String):Event
	{
		// because i dont want this one in the list lol
		if (name == "New Event")
		{
			return {
				name: "New Event",
				desc: "Please choose an event from the list to begin.",
				values: []
			};
		}

		var event:Event = null;
		for (e in events)
		{
			if (e.name == name)
			{
				event = e;
				break;
			}
		}

		if (event != null)
		{
			for (value in event.values)
			{
				if (value.getOptions != null)
					value.options = value.getOptions();
			}
		}

		return event;
	}

	public static function getLength(data:EventData)
	{
		var event:Event = getEvent(data.name);

		if (event != null)
		{
			for (i in 0...event.values.length)
				if (event.values[i].name == "Duration" || event.values[i].name == "Length")
					return data.data[i];
		}

		return -1;
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
