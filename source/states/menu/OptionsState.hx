package states.menu;

import subStates.OptionsSubState;
import data.GameData.MusicBeatState;

class OptionsState extends MusicBeatState
{
    override function create()
    {
        super.create();
        var options = new OptionsSubState();
        
        openSubState(options);
        
        options.openSubState(new data.GameTransition(true));
    }
}