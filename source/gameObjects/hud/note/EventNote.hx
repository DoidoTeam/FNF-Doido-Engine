package gameObjects.hud.note;

class EventNote extends Note
{
    public var eventName:String = '';
    public var value1:String = '';
    public var value2:String = '';
    public var value3:String = '';

    public function new()
    {
        super();
    }

    override public function reloadSprite():Note
    {
        loadGraphic(Paths.image('notes/events/event_note'));
        return this;
    }
}