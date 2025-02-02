package objects;

import flixel.FlxBasic;
import objects.Stage;

import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import states.PlayState;

class StageScript {
    var lowQuality:Bool = false;
    var stage:Stage;
    public function new(stage:Stage) {
        @:privateAccess
        lowQuality = stage.lowQuality;
        this.stage = stage;
        create();
    }

    public var foreground(get,never):FlxGroup;
    function get_foreground():FlxGroup {
        return stage.foreground;
    }

    public var camZoom(get, set):Float;
    function get_camZoom():Float {
        return stage.camZoom;
    }
    function set_camZoom(value:Float) {
        stage.camZoom = value;
        return stage.camZoom;
    }

    public var members(get, null):Array<FlxBasic>;
    function get_members():Array<FlxBasic> {
        return stage.members;
    }

    public function create() {}
    public function update(elapsed:Float) {}
    public function stepHit(curStep:Int) {}

    public function add(obj:FlxBasic) {
        stage.add(obj);
    }

    public function remove(obj:FlxBasic) {
        stage.remove(obj);
    }

    public function callScript(fun:String, ?args:Array<Dynamic>) {
        stage.callScript(fun, args);
    }
}