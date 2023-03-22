package;

import flixel.FlxSprite;
import openfl.utils.Assets as OpenFlAssets;

using StringTools;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isOldIcon:Bool = false;
	private var isPlayer:Bool = false;
	private var char:String = '';
	private var fiveicons:Bool = false;

	public function new(char:String = 'bf', isPlayer:Bool = false, fiveicons:Bool)
	{
		super();
		isOldIcon = (char == 'bf-old');
		this.isPlayer = isPlayer;
		this.fiveicons = fiveicons;
		changeIcon(char, fiveicons);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	public function swapOldIcon() {
		if(isOldIcon = !isOldIcon) changeIcon('bf-old', false);
		else changeIcon('bf', false);
	}

	private var iconOffsets:Array<Float> = [0, 0];
	public function changeIcon(char:String, fiveicons:Bool) {
		if(this.char != char) {
			var name:String = 'icons/' + char;
			if (!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; //Older versions of psych engine's support
			if (!fiveicons) { 
				if (!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; //Prevents crash from missing icon
			}
			else {
				if (!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-fivetest'; //Prevents crash from missing icon (Five Icon flavor)
			}
			var file:Dynamic = Paths.image(name);

			loadGraphic(file); //Load stupidly first for getting the file size
			if (!fiveicons)
			{
				loadGraphic(file, true, Math.floor(width / 3), Math.floor(height)); //Then load it fr
				iconOffsets[0] = (width - 150) / 3;
				iconOffsets[1] = (width - 150) / 3;
				iconOffsets[2] = (width - 150) / 3;
				updateHitbox();
				
				animation.add(char, [0, 1, 2], 0, false, isPlayer);
				animation.play(char);
				this.char = char;
			}
			else
			{
				loadGraphic(file, true, Math.floor(width / 5), Math.floor(height)); //Then load it fr
				iconOffsets[0] = (width - 150) / 5;
				iconOffsets[1] = (width - 150) / 5;
				iconOffsets[2] = (width - 150) / 5;
				iconOffsets[3] = (width - 150) / 5;
				iconOffsets[4] = (width - 150) / 5;
				updateHitbox();
				
				animation.add(char, [0, 1, 2, 3, 4], 0, false, isPlayer);
				animation.play(char);
				this.char = char;
			}

			antialiasing = ClientPrefs.globalAntialiasing;
			if(char.endsWith('-pixel')) {
				antialiasing = false;
			}
		}
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
		offset.y = iconOffsets[2];
	}

	public function getCharacter():String {
		return char;
	}
}
