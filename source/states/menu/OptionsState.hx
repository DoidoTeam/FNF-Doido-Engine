package states.menu;

import backend.game.GameTransition;
import subStates.options.OptionsSubState;

class OptionsState extends MusicBeatState
{
    override function create()
    {
        super.create();

        var options = new OptionsSubState();
        
        openSubState(options);
        
        options.openSubState(new GameTransition(true));
    }
}