package doido.utils;

import states.PlayState;

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
	var ?options:Array<Dynamic>;
}

class EventUtil
{
	public static var events:Array<Event> = [
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
}
