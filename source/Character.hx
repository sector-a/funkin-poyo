package;

import flixel.FlxSprite;
import flixel.util.FlxColor;

using StringTools;

class Character extends FlxSprite {
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = 'bf';
	public var barColor:FlxColor;

	public var holdTimer:Float = 0;

	public var camPos:Array<Float> = [0, 0];
	public var camZoom:Float = 1;

	public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false) {
		super(x, y);

		animOffsets = new Map<String, Array<Dynamic>>();
		curCharacter = character;
		this.isPlayer = isPlayer;
		antialiasing = true;

		switch (curCharacter) {
			case 'gf':
				frames = Paths.getSparrowAtlas('characters/poyo_gf', 'poyo');
				scale.set(0.8, 0.8);
				animation.addByPrefix('hey', 'giggle', 24, false);
				animation.addByPrefix('danceLeft', 'left', 24, false);
				animation.addByPrefix('danceRight', 'right', 24, false);

				addOffset('hey', -15, -6);
				addOffset('danceLeft');
				addOffset('danceRight', -20, 9);

				playAnim('danceRight');

				barColor = 0xFFA2044B;
			case 'poyo':
				frames = Paths.getSparrowAtlas('characters/PoyoAssets', 'poyo');

				animation.addByPrefix('idle', 'poyo_boppin', 24);
				animation.addByPrefix('singLEFT', 'poyo_left', 24, false);
				animation.addByPrefix('singDOWN', 'poyo_down', 24, false);
				animation.addByPrefix('singUP', 'poyo_up', 24, false);
				animation.addByPrefix('singRIGHT', 'poyo_right', 24, false);

				addOffset('idle');
				addOffset("singLEFT", 115, -10);
				addOffset("singDOWN", 27, -20);
				addOffset("singUP", 30, 100);
				addOffset("singRIGHT", -150, 18);

				playAnim('idle');

				barColor = 0xFFaf66ce;
				camPos = [200, -150];
			case 'bf':
				frames = Paths.getSparrowAtlas('characters/newbfpoyo', 'poyo');

				animation.addByPrefix('idle', 'BF idle dance', 24, false);
				animation.addByPrefix('singUP', 'BF NOTE UP0', 24, false);
				animation.addByPrefix('singLEFT', 'BF NOTE LEFT0', 24, false);
				animation.addByPrefix('singRIGHT', 'BF NOTE RIGHT0', 24, false);
				animation.addByPrefix('singDOWN', 'BF NOTE DOWN0', 24, false);
				animation.addByPrefix('hey', 'BF HEY!!', 24, false);

				addOffset('hey', -3, 0);
				addOffset('idle', 0, 0);
				addOffset('singDOWN', -9, 15);
				addOffset('singRIGHT', -1, -1);
				addOffset('singUP', 0, 7);
				addOffset('singLEFT', -3, 2);

				playAnim('idle');

				flipX = true;

				barColor = 0xFF31b0d1;
				camPos = [-100, 0];
		}

		dance();

		if (isPlayer)
			flipX = !flipX;
	}

	override function update(elapsed:Float) {
		if (!curCharacter.startsWith('bf')) {
			if (animation.curAnim != null && animation.curAnim.name.startsWith('sing')) {
				holdTimer += elapsed;
			}

			var dadVar:Float = 4;

			if (curCharacter == 'poyo')
				dadVar = 6.1;
			if (holdTimer >= Conductor.stepCrochet * dadVar * 0.001) {
				dance();
				holdTimer = 0;
			}
		}
		super.update(elapsed);
	}

	private var danced:Bool = false;

	public function dance() {
		switch (curCharacter) {
			case 'gf':
				if (!animation.curAnim.name.startsWith('hair')) {
					danced = !danced;

					if (danced)
						playAnim('danceRight');
					else
						playAnim('danceLeft');
				}
			default:
				playAnim('idle');
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void {
		animation.play(AnimName, Force, Reversed, Frame);

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName)) {
			offset.set(daOffset[0], daOffset[1]);
		} else
			offset.set(0, 0);

		if (curCharacter == 'gf') {
			if (AnimName == 'singLEFT') {
				danced = true;
			} else if (AnimName == 'singRIGHT') {
				danced = false;
			}

			if (AnimName == 'singUP' || AnimName == 'singDOWN') {
				danced = !danced;
			}
		}
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0) {
		animOffsets[name] = [x, y];
	}
}
