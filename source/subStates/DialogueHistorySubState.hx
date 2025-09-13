package subStates;

import backend.song.Conductor;
import backend.utils.DialogueUtil;
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.sound.FlxSound;
import objects.menu.Alphabet;
import objects.dialogue.DialogueObjects;
import states.*;

class DialogueHistorySubState extends MusicBeatSubState
{	
    var data:DialogueData;

	var boxGrp:FlxTypedGroup<DialogueBox>;
    var txtGrp:FlxTypedGroup<FlxText>;

	var curSelected:Int = 0;
    var spacing:Float = -350;

	public function new(data:DialogueData)
	{
		super();
		this.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
        this.data = data;

        curSelected = data.pages.length - 1;

		var banana = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		add(banana);

		banana.alpha = 0;
		FlxTween.tween(banana, {alpha: 0.65}, 0.1);

        boxGrp = new FlxTypedGroup<DialogueBox>();
        txtGrp = new FlxTypedGroup<FlxText>();

		add(boxGrp);
		add(txtGrp);

        var boxSkin:String = "default";

        var fontScale:Float = 1.0;
        var fontFamily:String = "vcr.ttf";
        var fontColor:Int = 0xFFFFFFFF;
        var fontBold:Bool = false;

        var fontBorderSize:Float = 1.5;
        var fontBorderColor:Int = 0xFF000000;
        var fontBorderType:FlxTextBorderStyle = OUTLINE;

        for(i in 0...data.pages.length) {
            var swagPage = data.pages[i];

            // feeling like yandere dev
            if(swagPage.boxSkin != null)
                boxSkin = swagPage.boxSkin;
			if(swagPage.fontScale != null)
                fontScale = swagPage.fontScale;
            if(swagPage.fontFamily != null)
                fontFamily = Paths.font(swagPage.fontFamily);
            if(swagPage.fontColor != null)
                fontColor = swagPage.fontColor;
            if(swagPage.fontBold != null)
                fontBold = swagPage.fontBold;
            if(swagPage.fontBorderType != null)
				fontBorderType = CoolUtil.stringToBorder(swagPage.fontBorderType);
			if(swagPage.fontBorderColor != null)
				fontBorderColor = swagPage.fontBorderColor;
			if(swagPage.fontBorderSize != null)
				fontBorderSize = swagPage.fontBorderSize;

            var box = new DialogueBox();
            box.reloadBox(boxSkin, true);
            box.ID = i;

            box.x == box.boxPos.x + ((FlxG.width/2) - (box.width/2));
            box.y == box.boxPos.y + ((FlxG.height/2) - (box.height/2)) + ((curSelected - box.ID) * spacing);

            boxGrp.add(box);

            var text = new FlxText(0, 0, 0, swagPage.text);
            text.setFormat(fontFamily, Math.floor(36 * fontScale), fontColor, LEFT);
            text.setBorderStyle(fontBorderType, fontBorderColor, fontBorderSize);
            text.bold = fontBold;
            text.antialiasing = false;
            text.updateHitbox();
            text.ID = i;

            text.x = box.x + box.txtPos.x;
			text.y = box.y + box.txtPos.y;
            text.fieldWidth = box.fieldWidth;

            txtGrp.add(text);
        }

        var stateTxt = new FlxText(0,0,0,'DIALOGUE HISTORY');
        stateTxt.setFormat(Main.gFont, 36, 0xFFFFFFFF, LEFT);
		stateTxt.setBorderStyle(OUTLINE, 0xFF000000, 2.5);
		stateTxt.x = FlxG.width - stateTxt.width - 5;
        stateTxt.y = 3;
		stateTxt.alpha = 1;
        add(stateTxt);

		changeSelection();

        #if TOUCH_CONTROLS
        stateTxt.x = 0;
		createPad("back", [FlxG.cameras.list[FlxG.cameras.list.length - 1]]);
		#end
	}

	var inputDelay:Float = 0.05;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

        for(box in boxGrp.members) {
            box.y = FlxMath.lerp(box.y, ((FlxG.height/2) - (box.height/2)) + ((curSelected - box.ID) * spacing), elapsed*8);
            box.alpha = FlxMath.lerp(box.alpha, (box.ID == curSelected ? 1 : 0.5), elapsed*12);
        }

        for(text in txtGrp.members) {
            for(box in boxGrp.members)
                if(text.ID == box.ID)
                    text.y = box.y + box.txtPos.y;

            text.alpha = FlxMath.lerp(text.alpha, (text.ID == curSelected ? 1 : 0.5), elapsed*12);
        }

		if(inputDelay > 0)
		{
			inputDelay -= elapsed;
			return;
		}

        if(Controls.justPressed(UI_UP))
            changeSelection(-1);
        if(Controls.justPressed(UI_DOWN))
            changeSelection(1);

        // works the same as resume
        if(Controls.justPressed(BACK))
            close();
	}

    override function close()
    {
        CoolUtil.activateTimers(true);
        super.close();
    }

	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		curSelected = FlxMath.wrap(curSelected, 0, data.pages.length - 1);

		if(change != 0)
			FlxG.sound.play(Paths.sound("menu/scrollMenu"));
	}
}