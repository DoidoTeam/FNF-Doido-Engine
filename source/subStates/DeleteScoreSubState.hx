package subStates;

import gameObjects.menu.Alphabet;
import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import data.GameData.MusicBeatSubState;
import data.Highscore;

class DeleteScoreSubState extends MusicBeatSubState
{
    var song:String;
    var diff:String;

    var grpItems:FlxTypedGroup<Alphabet>;
    var curSelection:Int = 0;

    public function new(song:String, diff:String, ?displayName:String)
    {
        super();
        this.song = song;
        this.diff = diff;
        playSound();
        
        var bg = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFF000000);
        bg.screenCenter();
        add(bg);

        bg.alpha = 0;
		FlxTween.tween(bg, {alpha: 0.9}, 0.1);

        if(displayName == null)
            displayName = song;

        var title = new Alphabet(0, 150, 'DELETE SCORE OF\\${displayName.replace('-', ' ')}\\on ${diff} DIFFICULTY??', true);
        title.x = FlxG.width / 2;
        title.align = CENTER;
        title.updateHitbox();
        add(title);

        grpItems = new FlxTypedGroup<Alphabet>();
        for(i in 0...2)
        {
            var opt = new Alphabet(0, 480, (i == 0) ? "NO" : "YES", true);
            opt.x = (FlxG.width / 2) + 190 * ((i == 0) ? -1 : 1);
            opt.align = CENTER;
            opt.updateHitbox();
            grpItems.add(opt);
            opt.ID = i;
        }
        add(grpItems);
        changeSelection(false);
    }

    public static var deletedScore:Bool = false;

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if(Controls.justPressed("BACK"))
        {
            playSound();
            close();
        }

        if(Controls.justPressed("ACCEPT"))
        {
            if(curSelection == 1)
            {
                Highscore.highscoreMap.remove('$song-$diff');
                Highscore.save();
                deletedScore = true;
            }

            playSound();
            close();
        }
        
        if(Controls.justPressed("UI_LEFT")
        || Controls.justPressed("UI_RIGHT"))
            changeSelection();
    }

    function changeSelection(hasSound:Bool = true)
    {
        if(hasSound)
        {
            FlxG.sound.play(Paths.sound('menu/scrollMenu'));
            curSelection++;
            if(curSelection > 1)
                curSelection = 0;
        }

        for(item in grpItems.members)
        {
            item.alpha = 0.4;
            if(item.ID == curSelection)
                item.alpha = 1.0;
        }
    }

    function playSound()
        FlxG.sound.play(Paths.sound('menu/cancelMenu'));
}