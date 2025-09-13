package states.menu;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import objects.menu.AlphabetMenu;

using StringTools;

typedef CreditData = {
	var name:String;
    var ?icon:String;
    var ?color:FlxColor;
    var ?info:String;
	var ?link:Null<String>;
}
class CreditsState extends MusicBeatState
{
	var creditList:Array<CreditData> = [];
    
	function addCredit(name:String, icon:String = "", color:FlxColor, info:String = "", ?link:Null<String>)
	{
		creditList.push({
            name: name,
            icon: icon,
            color: color,
            info: info,
			link: link,
        });
	}

	function addCategory(name:String)
	{
		creditList.push({
			name: name,
			icon: "",
			color: FlxColor.WHITE,
			info: "",
			link: null
		});
	}

	static var curSelected:Int = 1;
	var skipSelected:Array<Int> = [];

	var bg:FlxSprite;
	var bgTween:FlxTween;
	var grpItems:FlxGroup;
	var infoTxtFocus:AlphabetMenu;
	var infoTxt:FlxText;

	override function create()
	{
		super.create();
		/*
		*	Modify these to add your own credits!!
		*/
		final nikoo:Bool = (FlxG.random.bool(1));
		final specialPeople = 'Anakim, ArturYoshi, BeastlyChip♧, Bnyu, Evandro, NxtVithor, Pi3tr0, Raphalitos, ZieroSama';
		final specialCoders = 'ShadzXD, pisayesiwsi, crowplexus, Lasystuff, Gazozoz, Joalor64GH, LeonGamerPS1';
		// yes, this implies coders aren't people :D
		
		// btw you dont need to credit everyone here on your mod
		// just credit doido engine as a whole and we're good
		addCategory("Doido Engine's Crew");
		addCredit('DiogoTV', 			'diogotv', 	 0xFFC385FF, "Doido Engine's Owner and Main Coder", 				'https://bsky.app/profile/diogotv.bsky.social');
		addCredit('teles', 				'teles', 	 0xFFFF95AC, "Doido Engine's Additional Coder",					'https://youtube.com/@telesfnf');
		addCredit('GoldenFoxy',			'anna', 	 0xFFFFE100, "Main designer of Doido Engine's chart editor",		'https://bsky.app/profile/goldenfoxy.bsky.social');
		addCredit('JulianoBeta', 		'juyko', 	 0xFF0BA5FF, "Composed Doido Engine's offset menu music",			'https://www.youtube.com/@prodjuyko');
		addCredit('crowplexus',			'crowplexus',0xFF313538, "Creator of HScript Iris",							'https://github.com/crowplexus/hscript-iris');
		addCredit('yoisabo',			'yoisabo',	 0xFF56EF19, "Chart Editor's Event Icons Artist",					'https://bsky.app/profile/yoisabo.bsky.social');
		addCategory('Other Credits');
		addCredit('cocopuffs',			'coco',	 	 0xFF56EF19, "Mobile Button Artist", 'https://x.com/cocopuffswow');
		if(nikoo) addCredit('doubleonikoo', 'nikoo', 0xFF60458A, "Hey! What are you doing here?!",		'https://bsky.app/profile/doubleonikoo.bsky.social');
		addCredit('Github Contributors','github', 	 0xFFFFFFFF, 'Thank you\n${specialCoders}!!', 		'https://github.com/DoidoTeam/FNF-Doido-Engine/graphs/contributors');
		addCredit('Special Thanks', 	'heart', 	 0xFFC01B42, 'Thank you\n${specialPeople}!!\n<33', "https://youtu.be/N0IkgKHdgIc");
		
		/*
		*	Don't modify the rest of the code unless you know what you're doing!!
		*/
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

		var addLater:Array<AlphabetMenu> = [];
		for(i in 0...creditList.length)
		{
			var credit = creditList[i];

			var item = new AlphabetMenu(0, 0, credit.name, (credit.icon == ""));
			item.align = CENTER;
			item.updateHitbox();

			var xTo:Float = (FlxG.width / 2);
			if(!item.bold)
			{
				grpItems.add(item);

				var icon = new FlxSprite();
				icon.loadGraphic(Paths.image('credits/${credit.icon}'));
				grpItems.add(icon);

				// BIG ASS EARS
				if(credit.icon == "anna")
					icon.offset.y = 30;

				xTo -= (icon.width / 2);
				item.icon = icon;
				icon.ID = i;
			}
			else
			{
				item.yTo = 380;
				skipSelected.push(i);
				addLater.push(item);
			}

			item.ID = i;
			item.spaceX = 0;
			item.spaceY = 200;
			item.xTo = xTo;
			item.focusY = i - curSelected;
			item.updatePos();
		}
		for(i in addLater)
			grpItems.add(i);
		changeSelection();

		#if TOUCH_CONTROLS
		createPad("back");
		#end
	}

	function changeSelection(change:Int = 0, skipping:Bool = false):Void
	{
		curSelected += change;
		curSelected = FlxMath.wrap(curSelected, 0, creditList.length - 1);
		if(skipSelected.contains(curSelected))
			return changeSelection((change == 0) ? 1 : change, true);
		
		var titleItem:AlphabetMenu = null;
		for(rawItem in grpItems.members)
		{
			if(Std.isOfType(rawItem, AlphabetMenu))
			{
				var item = cast(rawItem, AlphabetMenu);
				item.focusY = item.ID - curSelected;

				if(!item.bold)
					item.alpha = 0.4;
				else
				{
					if(curSelected > item.ID + 1)
						titleItem = item;
					else
					{
						if(curSelected > item.ID)
							titleItem = null;
						item.yTo = 380;
					}
				}
				
				if(item.ID == curSelected) {
					infoTxtFocus = item;
					item.alpha = 1;
				}
			}
		}
		if(titleItem != null)
		{
			titleItem.focusY = 0;
			titleItem.yTo = 36;
		}

		infoTxt.text = creditList[curSelected].info;
		infoTxt.screenCenter(X);
		
		if(bgTween != null) bgTween.cancel();
		bgTween = FlxTween.color(bg, 0.4, bg.color, creditList[curSelected].color);

		if(change != 0 && !skipping)
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

		if(Controls.justPressed(ACCEPT))
		{
			var daCredit = creditList[curSelected].link;
			if(daCredit != null)
				CoolUtil.openURL(daCredit);
		}
		
		infoTxt.y = infoTxtFocus.y + infoTxtFocus.height + 48;
		for(rawItem in grpItems.members)
		{
			if(Std.isOfType(rawItem, AlphabetMenu))
			{
				var item = cast(rawItem, AlphabetMenu);
				if(item.icon == null) continue;
				item.icon.x = item.x + (item.width / 2);
				item.icon.y = item.y - item.icon.height / 6;
				item.icon.alpha = item.alpha;
			}
		}
	}
}
