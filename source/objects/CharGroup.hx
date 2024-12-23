package objects;

import flixel.group.FlxGroup;

class CharGroup extends FlxTypedGroup<Character>
{
    public var loadedChars:Array<String> = [];
    public var isPlayer:Bool = false;
    public var curChar:String = 'bf';
    public var char:Character;
    
    public function new(isPlayer:Bool = false, curChar:String = "bf")
    {
        super();
        this.isPlayer = isPlayer;
        this.curChar = curChar;
        addChar(curChar);
        reload();
    }

    public function addChar(charName:String)
    {
        if(!loadedChars.contains(charName))
        {
            loadedChars.push(charName);
            var char = new Character(charName, isPlayer);
            add(char);
            if(isPlayer)
                addChar(char.deathChar);
        }
    }
    
    public function setPos(x:Float = 0, y:Float = 0)
    {
        for(char in members)
        {
            char.x = x - (char.width / 2);
            char.y = y - char.height;
            char.x += char.globalOffset.x;
            char.y += char.globalOffset.y;
        }
    }

    public function reload()
    {
        for(i in members)
        {
            if(i.curChar != curChar)
                i.alpha = 0.0001;
            else
                char = i;
        }
        
        // avoids crashing ig
        if(char == null)
        {
            curChar = members[0].curChar;
            reload();
            return;
        } 
        char.alpha = 1.0;
    }
}