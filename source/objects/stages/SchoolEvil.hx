package objects.stages;

import objects.StageScript;
import flixel.FlxSprite;

class SchoolEvil extends StageScript {
    override function create() {
        stage.bfPos.x -= 70;
        stage.dadPos.x += 50;
        stage.gfPos.x += 20;
        stage.gfPos.y += 50;
        
        var bg:FlxSprite = new FlxSprite(400, 100);
        bg.frames = Paths.getSparrowAtlas('stages/school/animatedEvilSchool');
        bg.animation.addByPrefix('idle', 'background 2', 24);
        bg.animation.play('idle');
        bg.scrollFactor.set(0.8, 0.9);
        bg.antialiasing = false;
        bg.scale.set(6,6);
        add(bg);
    }
}