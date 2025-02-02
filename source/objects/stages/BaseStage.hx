package objects.stages;

import objects.StageScript;
import flixel.FlxSprite;

class BaseStage extends StageScript {
    override function create() {
        camZoom = 0.9;
				
        var bg = new FlxSprite(-600, -600).loadGraphic(Paths.image("stages/stage/stageback"));
        bg.scrollFactor.set(0.6,0.6);
        add(bg);
        
        var front = new FlxSprite(-580, 440);
        front.loadGraphic(Paths.image("stages/stage/stagefront"));
        add(front);
        
        if(!lowQuality) {
            var curtains = new FlxSprite(-600, -400).loadGraphic(Paths.image("stages/stage/stagecurtains"));
            curtains.scrollFactor.set(1.4,1.4);
            foreground.add(curtains);
        }
    }
}