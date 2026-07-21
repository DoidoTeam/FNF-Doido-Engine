package doido.song.compat;

import doido.song.SongHandler;

typedef LegacySong =
{
	var song:String;
	var notes:Array<LegacySection>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;

	// Parity with other engines
	var ?gfVersion:String;
}

typedef LegacySection =
{
	var sectionNotes:Array<Dynamic>;
	var ?lengthInSteps:Int;
	var mustHitSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;

	// psych suport
	var ?sectionBeats:Float;
}

typedef LegacyBPMChange =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
}

// THIS CLASS IS STILL WIP
// WE WANT TO ADD SUPPORT FOR OTHER ENGINE'S CHARTS
// SO STAY TUNED :-)

class Legacy
{
	inline public static function getMetaFromLegacy(legacySong:LegacySong):DoidoMeta
	{
		return {
			player1: legacySong.player1,
			player2: legacySong.player2,
			gf: (legacySong.gfVersion == "stage-set") ? null : legacySong.gfVersion,
		}
	}

	inline public static function getChartFromLegacy(legacySong:LegacySong):DoidoChart
	{
		var CHART:DoidoChart = {
			song: legacySong.song,
			notes: [],
			bpm: legacySong.bpm,
			speed: legacySong.speed,

			// player1: legacySong.player1,
			// player2: legacySong.player2,
		};

		var unspawnNotes:Array<NoteData> = [];
		var daSection:Int = 0;
		var daSteps:Int = 0;

		// bpm change stuff for sustain notes
		var noteCrochet:Float = Conductor.calcStep(CHART.bpm);
		var bpmChangeMap = getLegacyBPMChanges(legacySong);
		var lastChange:LegacyBPMChange = {
			stepTime: 0,
			songTime: 0.0,
			bpm: legacySong.bpm
		};

		for (section in legacySong.notes)
		{
			for (event in bpmChangeMap)
				if (event.stepTime == daSteps)
				{
					lastChange = event;
					noteCrochet = Conductor.calcStep(event.bpm);
					Logs.print('changed note bpm ${event.bpm}');
				}

			for (songNotes in section.sectionNotes)
			{
				/* - late || + early */
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);
				var daNoteType:String = 'none';
				// very stupid but I'm lazy
				if (songNotes.length > 2)
					daNoteType = songNotes[3];

				// psych event notes come on
				if (songNotes[1] < 0)
					continue;

				var isPlayer = (songNotes[1] >= 4);
				if (section.mustHitSection)
					isPlayer = (songNotes[1] < 4);

				var legacyNote:NoteData = {
					// stepTime: (daStrumTime / noteCrochet),
					// lastChange.stepTime + ((songPos - lastChange.songTime) / stepCrochet);
					stepTime: lastChange.stepTime + ((daStrumTime - lastChange.songTime) / noteCrochet),
					lane: daNoteData,
					strumline: isPlayer ? 1 : 0,
					type: daNoteType,
					length: 0
				};

				unspawnNotes.push(legacyNote);

				var susLength:Float = songNotes[2];
				if (susLength > 0)
				{
					var rawLoop:Float = (susLength / noteCrochet);
					var holdLoop:Int = ((rawLoop - Math.floor(rawLoop) <= 0.8) ? Math.floor(rawLoop) : Math.round(rawLoop));
					if (holdLoop <= 0)
						holdLoop = 1;

					legacyNote.length = holdLoop;
				}
			}
			daSteps += section.lengthInSteps;
			daSection++;
		}
		CHART.notes = unspawnNotes;
		return CHART;
	}

	// TO - DO: convert actual events + make the camera section shit not suck!
	public static function getEventsFromLegacy(legacySong:LegacySong):DoidoEvents
	{
		var EVENTS:DoidoEvents = {
			events: [],
		};

		// converting old bpm changes into new bpm changes
		var bpmChangeMap = getLegacyBPMChanges(legacySong);
		for (event in bpmChangeMap)
		{
			/*lastChange = event;
				noteCrochet = Conductor.calcStep(event.bpm);
				Logs.print('changed note bpm ${event.bpm}'); */
			EVENTS.events.push({
				name: "BPM Change",
				stepTime: event.stepTime,
				data: [event.bpm],
			});
		}

		var sectionTime:Float = 0;
		var lastSection:Bool = false;
		for (section in legacySong.notes)
		{
			if (section.mustHitSection != lastSection || sectionTime == 0)
			{
				EVENTS.events.push({
					name: "Camera Focus",
					stepTime: sectionTime,
					data: [(section.mustHitSection ? "bf" : "dad"), 4, "classic", "inout", 0, 0],
				});
				lastSection = section.mustHitSection;
			}

			sectionTime += section.lengthInSteps ?? (section.sectionBeats * 4) ?? 16;
		}

		return EVENTS;
	}

	public static function getLegacyBPMChanges(song:LegacySong):Array<LegacyBPMChange>
	{
		var bpmChangeMap:Array<LegacyBPMChange> = [];

		if (song == null)
			return [];

		var curBPM:Float = song.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		for (i in 0...song.notes.length)
		{
			if (song.notes[i].changeBPM && song.notes[i].bpm != curBPM)
			{
				curBPM = song.notes[i].bpm;
				var event:LegacyBPMChange = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM
				};
				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = song.notes[i].lengthInSteps;
			totalSteps += deltaSteps;
			totalPos += Conductor.calcStep(curBPM) * deltaSteps;
		}
		return bpmChangeMap;
	}
}
