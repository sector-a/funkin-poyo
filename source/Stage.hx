package;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;
import flixel.FlxMath;

class Stage extends FlxTypedGroup<FlxSprite>{
	public static var curStage:String = 'stage'
	public function new(stageName:String) {
		super();
		switch (stageName) {
			case 'cityvspoyo':
				curStage = 'cityvspoyo';
				var bg:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('bg', 'poyo'));
				bg.antialiasing = true;
				add(bg);
			default:
				curStage = 'cityvspoyo';
				var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('bg', 'poyo'));
				bg.antialiasing = true;
				add(bg);
		}
	}

	public function returnStageWH() {
		var size = [0, 0];
		forEachAlive(function(spr:FlxSprite) {
			if (spr.width > size[0]) size = spr.width;
			if (spr.height > size[1]) size = spr.height;
		}
		return size;
	}
}