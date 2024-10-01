package states.menu;

import data.Discord.DiscordIO;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import data.Highscore;
import data.Highscore.ScoreData;
import data.GameData.MusicBeatState;
import data.SongData;
import gameObjects.menu.AlphabetMenu;
import gameObjects.hud.HealthIcon;
import states.*;
import subStates.DeleteScoreSubState;
import states.editors.ChartingState;

using StringTools;

typedef CreditData = {
	var name:String;
    var icon:String;
    var color:FlxColor;
    var info:String;
	var link:Null<String>;
}
class CreditsState extends MusicBeatState
{
	var creditList:Array<CreditData> = [];
    
	function addCredit(name:String, icon:String, color:FlxColor, info:String, ?link:Null<String>)
	{
		creditList.push({
            name: name,
            icon: icon,
            color: color,
            info: info,
			link: link,
        });
	}

	static var curSelected:Int = 0;

	var bg:FlxSprite;
	var bgTween:FlxTween;
	var grpItems:FlxGroup;
	var infoTxtFocus:AlphabetMenu;
	var infoTxt:FlxText;

	override function create()
	{
		super.create();
		CoolUtil.playMusic("freakyMenu");

		DiscordIO.changePresence("Credits - Thanks!!");

		bg = new FlxSprite().loadGraphic(Paths.image('menu/backgrounds/menuDesat'));
		bg.scale.set(1.2,1.2); bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		grpItems = new FlxGroup();
		add(grpItems);

		infoTxt = new FlxText(0, 0, FlxG.width * 0.6, 'balls');
		infoTxt.setFormat(Main.gFont, 24, 0xFFFFFFFF, CENTER);
        infoTxt.setBorderStyle(OUTLINE, 0xFF000000, 1.5);
        add(infoTxt);

		final specialPeople = 'Anakim, ArturYoshi, BeastlyChip♧, Bnyu, Evandro, NxtVithor, Pi3tr0, Raphalitos, ZieroSama <33';
		final specialCoders = 'Teles, Crowplexus, Gazozoz';
		// yes, this implies coders aren't people
		// :D
		
		// btw you dont need to credit everyone here on your mod, just credit doido engine as a whole and we're good
		addCredit('DiogoTV', 			'diogotv', 	 0xFFC385FF, "Doido Engine's Owner and Main Coder", 				'https://bsky.app/profile/diogotv.bsky.social');
		addCredit('teles', 				'teles', 	 0xFFFF95AC, "Doido Engine's Additional Coder",					'https://youtube.com/@telesfnf');
		addCredit('Anna The Fennec',	'anna', 	 0xFFFFE100, "Main designer of Doido Engine's chart editor",		'https://bsky.app/profile/goldenfoxy.bsky.social');
		addCredit('JulianoBeta', 		'juyko', 	 0xFF0BA5FF, "Composed Doido Engine's offset menu music",			'https://www.youtube.com/@prodjuyko');
		addCredit('CrowPlexus',			'crowplexus',0xFF292C2E, "Creator of HScript Iris",							'https://github.com/crowplexus/hscript-iris');
		addCredit('yoisabo',			'yoisabo',	 0xFF56EF19, "Chart Editor's Event Icons Artist",					'https://bsky.app/profile/yoisabo.bsky.social');
		addCredit('doubleonikoo', 		'nikoo', 	 0xFF60458A, "is gonna make an actual logo for Doido Engine soon",	'https://bsky.app/profile/doubleonikoo.bsky.social');
		addCredit('Github Contributors','github', 	 0xFFFFFFFF, 'Thank you\n${specialCoders}!!', 'https://github.com/DoidoTeam/FNF-Doido-Engine/graphs/contributors');
		addCredit('Special Thanks', 	'heart', 	 0xFFC01B42, 'Thank you\n${specialPeople}!!', "https://youtu.be/rnr8Oo2RV_c");
		
		for(i in 0...creditList.length)
		{
			var credit = creditList[i];

			var item = new AlphabetMenu(0, 0, credit.name, false);
			item.align = CENTER;
			item.updateHitbox();
			grpItems.add(item);

			var icon = new FlxSprite();
			icon.loadGraphic(Paths.image('credits/${credit.icon}'));
			grpItems.add(icon);

			if(credit.icon == "anna")
				icon.offset.y = 30;

			item.icon = icon;
			item.ID = i;
			icon.ID = i;

			item.spaceX = 0;
			item.spaceY = 200;
			item.xTo = (FlxG.width / 2) - (icon.width / 2);
			item.focusY = i - curSelected;
			item.updatePos();

			//item.x = FlxG.width + 200;
		}
		changeSelection();
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		curSelected = FlxMath.wrap(curSelected, 0, creditList.length - 1);
		
		for(rawItem in grpItems.members)
		{
			if(Std.isOfType(rawItem, AlphabetMenu))
			{
				var item = cast(rawItem, AlphabetMenu);
				item.focusY = item.ID - curSelected;

				item.alpha = 0.4;
				if(item.ID == curSelected) {
					infoTxtFocus = item;
					item.alpha = 1;
				}
			}
		}

		infoTxt.text = creditList[curSelected].info;
		infoTxt.screenCenter(X);
		
		if(bgTween != null) bgTween.cancel();
		bgTween = FlxTween.color(bg, 0.4, bg.color, creditList[curSelected].color);

		if(change != 0)
			FlxG.sound.play(Paths.sound("menu/scrollMenu"));
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(Controls.justPressed(UI_UP))
			changeSelection(-1);
		if(Controls.justPressed(UI_DOWN))
			changeSelection(1);

		if(Controls.justPressed(BACK))
			Main.switchState(new MainMenuState());

		#if !mobile
		if(Controls.justPressed(ACCEPT))
		{
			var daCredit = creditList[curSelected].link;
			if(daCredit != null)
				CoolUtil.openURL(daCredit);
		}
		#end
		
		infoTxt.y = infoTxtFocus.y + infoTxtFocus.height + 48;
		for(rawItem in grpItems.members)
		{
			if(Std.isOfType(rawItem, AlphabetMenu))
			{
				var item = cast(rawItem, AlphabetMenu);
				item.icon.x = item.x + (item.width / 2);
				item.icon.y = item.y - item.icon.height / 6;
				item.icon.alpha = item.alpha;
			}
		}
	}
}