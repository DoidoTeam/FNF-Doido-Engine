package objects.stages;

import objects.StageScript;
import flixel.FlxSprite;
import states.PlayState;

class School extends StageScript {
    override function create() {
        stage.bfPos.x -= 70;
        stage.dadPos.x += 50;
        stage.gfPos.x += 20;
        stage.gfPos.y += 50;
        
        var bgSky = new FlxSprite().loadGraphic(Paths.image('stages/school/weebSky'));
        bgSky.scrollFactor.set(0.1, 0.1);
        add(bgSky);
        
        var bgSchool:FlxSprite = new FlxSprite(-200, 0).loadGraphic(Paths.image('stages/school/weebSchool'));
        bgSchool.scrollFactor.set(0.6, 0.90);
        add(bgSchool);
        
        var bgStreet:FlxSprite = new FlxSprite(-200).loadGraphic(Paths.image('stages/school/weebStreet'));
        bgStreet.scrollFactor.set(0.95, 0.95);
        add(bgStreet);
        
        var fgTrees:FlxSprite = new FlxSprite(-200 + 170, 130).loadGraphic(Paths.image('stages/school/weebTreesBack'));
        fgTrees.scrollFactor.set(0.9, 0.9);
        add(fgTrees);
        
        var bgTrees:FlxSprite = new FlxSprite(-200 - 380, -1100);
        bgTrees.frames = Paths.getPackerAtlas('stages/school/weebTrees');
        bgTrees.animation.add('treeLoop', CoolUtil.intArray(18), 12);
        bgTrees.animation.play('treeLoop');
        bgTrees.scrollFactor.set(0.85, 0.85);
        add(bgTrees);

        if(!lowQuality) {
            var treeLeaves:FlxSprite = new FlxSprite(-200, -40);
            treeLeaves.frames = Paths.getSparrowAtlas('stages/school/petals');
            treeLeaves.animation.addByPrefix('leaves', 'PETALS ALL', 24, true);
            treeLeaves.animation.play('leaves');
            treeLeaves.scrollFactor.set(0.85, 0.85);
            add(treeLeaves);
            
            var bgGirls = new FlxSprite(-100, 175); // 190
            bgGirls.frames = Paths.getSparrowAtlas('stages/school/bgFreaks');
            bgGirls.scrollFactor.set(0.9, 0.9);
            
            var girlAnim:String = "girls group";
            if(PlayState.SONG.song == 'roses')
                girlAnim = 'fangirls dissuaded';
            
            bgGirls.animation.addByIndices('danceLeft',  'BG $girlAnim', CoolUtil.intArray(14),		"", 24, false);
            bgGirls.animation.addByIndices('danceRight', 'BG $girlAnim', CoolUtil.intArray(30, 15), "", 24, false);
            bgGirls.animation.play('danceLeft');
            bgGirls._stepHit = function(curStep:Int)
            {
                if(curStep % 4 == 0)
                {
                    if(bgGirls.animation.curAnim.name == 'danceLeft')
                        bgGirls.animation.play('danceRight', true);
                    else
                        bgGirls.animation.play('danceLeft', true);
                }
            }
            add(bgGirls);
        }
        
        // easier to manage
        for(rawItem in members)
        {
            if(Std.isOfType(rawItem, FlxSprite))
            {
                var item:FlxSprite = cast rawItem;
                item.antialiasing = false;
                item.isPixelSprite = true;
                item.scale.set(6,6);
                item.updateHitbox();
                item.x -= 170;
                item.y -= 145;
            }
        }
    }
}