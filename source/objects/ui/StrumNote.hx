package objects.ui;

import objects.doido.DoidoSprite;

class StrumNote extends DoidoSprite
{
	public var strumData:Int = 0;
	public var direction:String = "";
	
	public var strumPath:BasePath = null;
	
	public function new()
	{
		super();
	}
	
	public function reloadStrum(strumData:Int)
	{
		this.strumData = strumData;
		this.direction = NoteUtil.intToString(strumData);
		
		switch("ill do it later")
		{
			default:
				this.loadSparrow("notes/base/strums");
				for (anim in ["static", "pressed", "confirm"]) {
					animation.addByPrefix(anim, 'strum $direction $anim', 24, false);
				}
				playAnim("static");
		}
	}
}