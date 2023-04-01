package;

import flixel.group.FlxSpriteGroup;
import flixel.FlxSprite;
import flixel.math.FlxMath;

class Stage extends FlxSpriteGroup<FlxSprite>{
	public var curStage:String = 'stage';
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
		var width:Float = 0;
		var height:Float = 0;
		forEachAlive(function(spr:FlxSprite) {
			if (spr.width > width) width = spr.width;
			if (spr.height > height) height = spr.height;
		});
		return [width, height];
	}
}