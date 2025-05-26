package backend.song;

import backend.song.SongData.SwagSong;

typedef OldSwagSong =
{
	var song:String;
	var notes:Array<OldSwagSection>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;

	// Parity with other engines
	var ?gfVersion:String;
}
typedef OldSwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var lengthInSteps:Int;
	var mustHitSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var sectionBeats:Float;
}
typedef OldSwagEvent =
{
	var songEvents:Array<Dynamic>;
}

class SongConverter
{
    public inline static function updateDoidoChart():SwagSong
    {
        return null;
    }

    public inline static function downgradeDoidoChart():OldSwagSong
    {
        return null;
    }
}

/*
// later
inline public static function baseToDoido()
{

}

inline public static function doidoToBase()
{

}
*/