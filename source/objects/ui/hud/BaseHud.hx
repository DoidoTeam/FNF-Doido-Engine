package objects.ui.hud;

class BaseHud extends FlxGroup
{
    public var playState:PlayState;
    public var hudName:String = "base";

    public var separator:String = " | ";
    public var scoreTxt:FlxText;

    public function new(hudName:String) {
        super();
        this.hudName = hudName;
    }

    public function init()
    {
        updateScoreTxt();
    }

    public function updateScoreTxt() {}
}