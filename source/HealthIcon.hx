package;

import flixel.FlxSprite;
import openfl.utils.Assets as OpenFlAssets;

using StringTools;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;

	private var isOldIcon(default, null):Bool = false;
	private var isPlayer(default, null):Bool = false;
	private var char(default, null):String = '';

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		isOldIcon = (char == 'bf-old');
		this.isPlayer = isPlayer;
		changeIcon(char);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	inline public function swapOldIcon():Void {
		(isOldIcon = !isOldIcon) ? changeIcon('bf-old') : changeIcon('bf');
	}

	private var iconOffsets:FlxPoint = new FlxPoint(0, 0);

	public function changeIcon(char:String):Void {
		if(this.char != char) {
			var name:String = 'icons/' + char;
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; //Older versions of psych engine's support
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; //Prevents crash from missing icon
			var file:Dynamic = Paths.image(name);

			loadGraphic(file); //Get file size
			loadGraphic(file, true, 150, 150); //Then load it fr

			animation.add(char, [for (i in 0...frames.frames.length) i], 0, false, isPlayer);
			animation.play(char);
			this.char = char;

			iconOffsets.set((width - 150) / frames.frames.length, (height - 150) / frames.frames.length);

			antialiasing = (ClientPrefs.globalAntialiasing && !char.endsWith('-pixel'));
			scrollFactor.set();
			updateHitbox();
		}
	}

	override function updateHitbox():Void
	{
		super.updateHitbox();
		offset = iconOffsets;
	}

	/**
	 * Store which health percentage will make a frame play
	 * Percentage => Frame
	 */
	public var animationMap:Map<Int, Int> = [
		0 => 0, // Default
		20 => 1 // Lose
		80 => 2 // Winning
	];

	public dynamic function updateFrame(health:Float):Void {
		for (healthPercent => frame in animationMap)
			if (health < healthPercent && animation.frames >= frame)
				animation.curAnim.curFrame = frame;
	}

	inline public function getCharacter():String {
		return char;
	}
}
