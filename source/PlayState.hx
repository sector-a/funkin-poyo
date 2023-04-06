package;

import openfl.Lib;
import Song.SwagSection;
import Song.SwagSong;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.input.keyboard.FlxKey;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import flixel.util.FlxStringUtil;
import lime.utils.Assets;
#if hxCodec
#if (hxCodec == "2.6.0") 
import VideoHandler;
import VideoSprite;
#elseif (hxCodec >= "2.6.1") 
import hxcodec.VideoHandler;
import hxcodec.VideoSprite;
#else 
import vlc.MP4Handler as VideoHandler;
import vlc.MP4Sprite as VideoSprite;
#end
#end
#if windows
import Discord.DiscordClient;
#end

using StringTools;

class PlayState extends MusicBeatState {
	public static var instance:PlayState = null;

	public static var curStage:String = '';
	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	public static var weekSong:Int = 0;
	public static var shits:Int = 0;
	public static var bads:Int = 0;
	public static var goods:Int = 0;
	public static var sicks:Int = 0;

	var lastRating:FlxSprite;

	public static var noteAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
	var songLength:Float = 0;

	#if windows
	var storyDifficultyText:String = "";
	var iconRPC:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	private var vocals:FlxSound;
	private var P1vocals:FlxSound;
	private var P2vocals:FlxSound;
	private var SepVocalsNull:Bool = false;

	public static var dad:Character;
	public static var gf:Character;
	public static var boyfriend:Boyfriend;

	public var notes:FlxTypedGroup<Note>;

	private var unspawnNotes:Array<Note> = [];

	public var strumLine:FlxSprite;

	private var curSection:Int = 0;

	private var camFollow:FlxObject;

	private static var prevCamFollow:FlxObject;

	public static var strumLineNotes:FlxTypedGroup<FlxSprite> = null;
	public static var playerStrums:FlxTypedGroup<FlxSprite> = null;
	public static var cpuStrums:FlxTypedGroup<FlxSprite> = null;

	var camZoomPerNote:Bool = false;

	//poyo mode things
	var strum_1:FlxTypedGroup<FlxSprite> = null;
	var strum_2:FlxTypedGroup<FlxSprite> = null;

	var playerChar:Character;
	var opponentChar:Character;

	private var curSong:String = "";

	private var gfSpeed:Int = 1;
	private var gfCanBop:Bool = true;

	public var health:Float = 1;

	private var combo:Int = 0;

	public static var misses:Int = 0;

	private var accuracy:Float = 0.00;
	private var totalNotesHit:Float = 0;
	private var totalPlayed:Int = 0;

	private var healthBarBG:FlxSprite;
	private var healthBar:FlxBar;

	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;

	private var camGame:FlxCamera;

	var notesHitArray:Array<Date> = [];

	var songScore:Int = 0;
	var songScoreDef:Int = 0;
	var scoreTxt:FlxText;
	var RatingCounter:FlxText;
	var timer:FlxText;
	var info:FlxText;

	var cameraZoom:Float = 1;
	var cameraBop:Int = 4;
	var cameraCanBop:Bool = true;
	var manualCam:Bool = false;

	var stage:Stage;

	public static var campaignScore:Int = 0;

	var inCutscene:Bool = false;

	private var triggeredAlready:Bool = false;
	private var allowedToHeadbang:Bool = false;

	private var botPlayState:FlxText;

	var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var hideGf:Bool = false; // write hideGf = true in stage to remove gf !
	
	override public function create() {
		instance = this;
		FlxG.mouse.visible = false;

		Paths.clearStoredMemory();

		if (!Assets.exists(Paths.P1voice(PlayState.SONG.song)) || !Assets.exists(Paths.P2voice(PlayState.SONG.song)))
			SepVocalsNull = true;

		if (FlxG.save.data.fpsCap > 290)
			(cast(Lib.current.getChildAt(0), Main)).setFPSCap(800);

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		sicks = 0;
		bads = 0;
		shits = 0;
		goods = 0;

		misses = 0;

		#if windows
		switch (storyDifficulty) {
			case 0:
				storyDifficultyText = "Easy";
			case 1:
				storyDifficultyText = "Normal";
			case 2:
				storyDifficultyText = "Hard";
		}

		iconRPC = SONG.player2;

		if (isStoryMode)
			detailsText = "Story Mode: Week " + storyWeek;
		else
			detailsText = "Freeplay";

		detailsPausedText = "Paused - " + detailsText;
		DiscordClient.changePresence(detailsText
			+ " "
			+ SONG.song
			+ " ("
			+ storyDifficultyText
			+ ") "
			+ Ratings.GenerateLetterRank(accuracy),
			"\nAcc: "
			+ HelperFunctions.truncateFloat(accuracy, 2)
			+ "% | Score: "
			+ songScore
			+ " | Misses: "
			+ misses, iconRPC);
		#end

		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.alpha = 0.0001;
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);

		FlxCamera.defaultCameras = [camGame];

		persistentUpdate = persistentDraw = true;

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		stage = new Stage(SONG.stage);
		add(stage);
		curStage = stage.curStage;
		camGame.setScrollBoundsRect(stage.findMinX(),stage.findMinY(),stage.width,stage.height);

		var gfVersion:String = 'gf';

		switch (SONG.gfVersion) {
			default:
				gfVersion = 'gf';
		}

		gf = new Character(0, 0, gfVersion);
		gf.scrollFactor.set(0.95, 0.95);
		dad = new Character(0, 0, SONG.player2);
		boyfriend = new Boyfriend(0, 0, SONG.player1);

		switch (curStage)
		{
			case 'cityvspoyo':
				boyfriend.x = 1480;
				boyfriend.y = 500;
				dad.x = 700;
				dad.y = 240;
				gf.x = 919;
				gf.y = 200;
				dad.camZoom = 0.8;
				boyfriend.camZoom = 1;
		}
		if (!hideGf)
			add(gf);
		add(dad);
		add(boyfriend);

		Conductor.songPosition = -5000;

		if (FlxG.save.data.bgNotesAlpha != 0) {
			var width = 490;
			var notesBgBF:FlxSprite = new FlxSprite(FlxG.save.data.middleScroll ? (FlxG.width / 2) - (width / 2) : (FlxG.save.data.poyoMode ? 80 : (FlxG.width / 2) + 80), 0).makeGraphic(width, FlxG.height, FlxColor.BLACK);
			notesBgBF.cameras = [camHUD];
			notesBgBF.alpha = FlxG.save.data.bgNotesAlpha;
			add(notesBgBF);
		}

		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();

		if (FlxG.save.data.downscroll)
			strumLine.y = FlxG.height - 165;

		strumLineNotes = new FlxTypedGroup<FlxSprite>();
		add(strumLineNotes);

		grpNoteSplashes = new FlxTypedGroup<NoteSplash>(8);

		var noteSplash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(noteSplash);
		noteSplash.alpha = 0.00001;

		add(grpNoteSplashes);

		playerStrums = new FlxTypedGroup<FlxSprite>();
		cpuStrums = new FlxTypedGroup<FlxSprite>();

		if (!FlxG.save.data.poyoMode) {
			strum_1 = playerStrums;
			playerChar = boyfriend;
			strum_2 = cpuStrums;
			opponentChar = dad;
		} else {
			strum_1 = cpuStrums;
			playerChar = dad;
			strum_2 = playerStrums;
			opponentChar = boyfriend;
		}

		generateSong(SONG.song);

		camFollow = new FlxObject(0, 0, 1, 1);
		camGame.zoom = dad.camZoom * cameraZoom;
		camFollow.setPosition(dad.getGraphicMidpoint().x + dad.camPos[0], dad.getGraphicMidpoint().y + dad.camPos[1]);

		if (prevCamFollow != null) {
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0.04 * (60 / (cast(Lib.current.getChildAt(0), Main)).getFPS()));
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		healthBarBG = new FlxSprite(0, FlxG.height * 0.9).loadGraphic(Paths.image('healthBar', 'shared'));
		if (FlxG.save.data.downscroll)
			healthBarBG.y = 50;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.createFilledBar(dad.barColor, boyfriend.barColor);
		add(healthBar);

		RatingCounter = new FlxText(20, 0, 0, ': ${sicks}\nGoods: ${goods}\nBads: ${bads}\nShits: ${shits}\nMisses: ${misses}', 20);
		RatingCounter.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		RatingCounter.borderSize = 1;
		RatingCounter.borderQuality = 2;
		RatingCounter.scrollFactor.set();
		RatingCounter.cameras = [camHUD];
		RatingCounter.screenCenter(Y);
		if (FlxG.save.data.ratingCounter && !FlxG.save.data.botplay)
			add(RatingCounter);

		botPlayState = new FlxText(healthBarBG.x + healthBarBG.width / 2 - 75, healthBarBG.y + (FlxG.save.data.downscroll ? 100 : -100), 0, "BOTPLAY", 20);
		botPlayState.setFormat(Paths.font("vcr.ttf"), 42, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botPlayState.borderSize = 2;
		botPlayState.borderQuality = 2;
		botPlayState.scrollFactor.set();

		if (FlxG.save.data.botplay)
			add(botPlayState);

		iconP1 = new HealthIcon(SONG.player1, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		add(iconP1);

		iconP2 = new HealthIcon(SONG.player2, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		add(iconP2);

		scoreTxt = new FlxText(FlxG.width / 2 - 235, healthBarBG.y + 35, 0, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.borderSize = 1;
		scoreTxt.borderQuality = 2;
		scoreTxt.scrollFactor.set();
		if (!FlxG.save.data.botplay)
			add(scoreTxt);

		timer = new FlxText(20, scoreTxt.y - 25, 0, '', 25);
		timer.setFormat(Paths.font("vcr.ttf"), 25, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		if (FlxG.save.data.downscroll)
			timer.y = 65;
		timer.borderSize = 1;
		timer.borderQuality = 2;
		timer.scrollFactor.set();
		if (FlxG.save.data.timer)
			add(timer);

		info = new FlxText(20, scoreTxt.y - 5, 0, '', 25);
		info.setFormat(Paths.font("vcr.ttf"), 25, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		if (FlxG.save.data.downscroll)
			info.y = 45;
		info.borderSize = 1;
		info.borderQuality = 2;
		info.scrollFactor.set();
		add(info);

		grpNoteSplashes.cameras = [camHUD];
		strumLineNotes.cameras = [camHUD];
		notes.cameras = [camHUD];
		timer.cameras = [camHUD];
		info.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		botPlayState.cameras = [camHUD];

		#if mobile
		addHitbox();
		addHitboxCamera();
		#end

		startingSong = true;
	
		switch (curSong.toLowerCase())
		{
			default:
				startCountdown();
		}

		super.create();

		Paths.clearUnusedMemory();
	}

	var startTimer:FlxTimer;

	function startCountdown():Void {
		inCutscene = canPause = false;

		generateStaticArrows(0);
		generateStaticArrows(1);

		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer) {
			dad.dance();
			gf.dance();
			boyfriend.dance();

			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('default', ['ready', "set", "go"]);
			var introAlts:Array<String> = introAssets.get('default');

			switch (swagCounter) {
				case 0:
					FlxG.sound.play(Paths.sound('intro3', 'shared'), 0.6);
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0], 'shared'));
					ready.scrollFactor.set();
					ready.updateHitbox();
					ready.screenCenter();
					add(ready);

					FlxTween.tween(ready, {alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween) {
							ready.destroy();
						}
					});

					FlxG.sound.play(Paths.sound('intro2', 'shared'), 0.6);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1], 'shared'));
					set.scrollFactor.set();
					set.screenCenter();
					add(set);

					FlxTween.tween(set, {alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween) {
							set.destroy();
						}
					});

					FlxG.sound.play(Paths.sound('intro1', 'shared'), 0.6);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[2], 'shared'));
					go.scrollFactor.set();
					go.updateHitbox();
					go.screenCenter();
					add(go);

					FlxTween.tween(go, {alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween) {
							go.destroy();
						}
					});

					FlxG.sound.play(Paths.sound('introGo', 'shared'), 0.6);
			}

			swagCounter += 1;
		}, 4);
	}

	var previousFrameTime:Int = 0;
	var songTime:Float = 0;

	var songStarted = false;

	function startSong():Void {
		startingSong = false;
		songStarted = canPause = true;
		previousFrameTime = FlxG.game.ticks;

		if (!paused)
			FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);

		FlxG.sound.music.onComplete = endSong;
		if (SepVocalsNull)
			vocals.play();
		else
			for (vocals in [P1vocals, P2vocals])
				vocals.play();

		songLength = FlxG.sound.music.length;
		FlxTween.tween(camHUD, {alpha: 1}, 0.6, {ease: FlxEase.circOut});
		
		switch (curSong) {
			default:
				allowedToHeadbang = false;
		}

		#if windows
		DiscordClient.changePresence(detailsText
			+ " "
			+ SONG.song
			+ " ("
			+ storyDifficultyText
			+ ") "
			+ Ratings.GenerateLetterRank(accuracy),
			"\nAcc: "
			+ HelperFunctions.truncateFloat(accuracy, 2)
			+ "% | Score: "
			+ songScore
			+ " | Misses: "
			+ misses, iconRPC);
		#end
	}

	var debugNum:Int = 0;

	private function generateSong(dataPath:String):Void {
		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			if (SepVocalsNull) {
				vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
			} else {
				P1vocals = new FlxSound().loadEmbedded(Paths.P1voice(PlayState.SONG.song));
				P2vocals = new FlxSound().loadEmbedded(Paths.P2voice(PlayState.SONG.song));
			}
		else
			vocals = new FlxSound();

		if (SepVocalsNull)
			FlxG.sound.list.add(vocals);
		else
			for (vocals in [P1vocals, P2vocals])
				FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0;
		for (section in noteData) {
			var coolSection:Int = Std.int(section.lengthInSteps / 4);

			for (songNotes in section.sectionNotes) {
				var daStrumTime:Float = songNotes[0];
				if (daStrumTime < 0)
					daStrumTime = 0;
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
					gottaHitNote = !section.mustHitSection;

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;
//RADIUSSHIT LOL
				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.sustainLength = songNotes[2];
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				for (susNote in 0...Math.floor(susLength)) {
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true);
					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);

					sustainNote.mustPress = gottaHitNote;

					if (sustainNote.mustPress)
						sustainNote.x += FlxG.width / 2;
				}

				swagNote.mustPress = gottaHitNote;

				if (swagNote.mustPress)
					swagNote.x += FlxG.width / 2;
			}
			daBeats += 1;
		}

		unspawnNotes.sort(sortByShit);

		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int {
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	private function generateStaticArrows(player:Int):Void {
		for (i in 0...4) {
			var babyArrow:FlxSprite = new FlxSprite(0, strumLine.y);

			switch (SONG.noteStyle) {
				case 'normal':
					babyArrow.frames = Paths.getSparrowAtlas('NOTE_assets', 'shared');
					babyArrow.animation.addByPrefix('green', 'arrowUP');
					babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
					babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
					babyArrow.animation.addByPrefix('red', 'arrowRIGHT');

					babyArrow.antialiasing = true;
					babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

					switch (Math.abs(i)) {
						case 0:
							babyArrow.x += Note.swagWidth * 0;
							babyArrow.animation.addByPrefix('static', 'arrowLEFT');
							babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
						case 1:
							babyArrow.x += Note.swagWidth * 1;
							babyArrow.animation.addByPrefix('static', 'arrowDOWN');
							babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
						case 2:
							babyArrow.x += Note.swagWidth * 2;
							babyArrow.animation.addByPrefix('static', 'arrowUP');
							babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
						case 3:
							babyArrow.x += Note.swagWidth * 3;
							babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
							babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
					}

				default:
					babyArrow.frames = Paths.getSparrowAtlas('NOTE_assets', 'shared');
					babyArrow.animation.addByPrefix('green', 'arrowUP');
					babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
					babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
					babyArrow.animation.addByPrefix('red', 'arrowRIGHT');

					babyArrow.antialiasing = true;
					babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

					switch (Math.abs(i)) {
						case 0:
							babyArrow.x += Note.swagWidth * 0;
							babyArrow.animation.addByPrefix('static', 'arrowLEFT');
							babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
						case 1:
							babyArrow.x += Note.swagWidth * 1;
							babyArrow.animation.addByPrefix('static', 'arrowDOWN');
							babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
						case 2:
							babyArrow.x += Note.swagWidth * 2;
							babyArrow.animation.addByPrefix('static', 'arrowUP');
							babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
						case 3:
							babyArrow.x += Note.swagWidth * 3;
							babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
							babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
					}
			}

			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();

			if (!isStoryMode) {
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}

			babyArrow.ID = i;

			switch (player) {
				case 0:
					cpuStrums.add(babyArrow);
					if (FlxG.save.data.middleScroll && !FlxG.save.data.poyoMode)
						babyArrow.visible = false;
					else if (FlxG.save.data.middleScroll && FlxG.save.data.poyoMode)
						babyArrow.x = (FlxG.width / 2) - (Note.swagWidth * 2) + (Note.swagWidth * i);
				case 1:
					playerStrums.add(babyArrow);
					if (FlxG.save.data.middleScroll && !FlxG.save.data.poyoMode)
						babyArrow.x = (FlxG.width / 2) - (Note.swagWidth * 2) + (Note.swagWidth * i);
					else if (FlxG.save.data.middleScroll && FlxG.save.data.poyoMode)
						babyArrow.visible = false;
			}

			babyArrow.animation.play('static');
			if (!FlxG.save.data.middleScroll)
				babyArrow.x += ((FlxG.width / 2) * player) + 100;

			strum_2.forEach(function(spr:FlxSprite) {
				spr.centerOffsets();
			});

			strumLineNotes.add(babyArrow);
		}
	}

	function tweenCamIn():Void {
		FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
	}

	override function openSubState(SubState:FlxSubState) {
		if (paused) {
			if (FlxG.sound.music != null) {
				FlxG.sound.music.pause();
				if (SepVocalsNull)
					vocals.pause();
				else
					for (vocals in [P1vocals, P2vocals])
						vocals.pause();
			}

			#if windows
			DiscordClient.changePresence("PAUSED on "
				+ SONG.song
				+ " ("
				+ storyDifficultyText
				+ ") "
				+ Ratings.GenerateLetterRank(accuracy),
				"Acc: "
				+ HelperFunctions.truncateFloat(accuracy, 2)
				+ "% | Score: "
				+ songScore
				+ " | Misses: "
				+ misses, iconRPC);
			#end
			if (!startTimer.finished)
				startTimer.active = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState() {
		if (paused) {
			if (FlxG.sound.music != null && !startingSong)
				resyncVocals();

			if (!startTimer.finished)
				startTimer.active = true;
			paused = false;

			#if windows
			if (startTimer.finished) {
				DiscordClient.changePresence(detailsText
					+ " "
					+ SONG.song
					+ " ("
					+ storyDifficultyText
					+ ") "
					+ Ratings.GenerateLetterRank(accuracy),
					"\nAcc: "
					+ HelperFunctions.truncateFloat(accuracy, 2)
					+ "% | Score: "
					+ songScore
					+ " | Misses: "
					+ misses, iconRPC, true,
					songLength
					- Conductor.songPosition);
			} else
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy), iconRPC);
			#end
		}

		super.closeSubState();
	}

	function resyncVocals():Void {
		if (SepVocalsNull)
			vocals.pause();
		else
			for (vocals in [P1vocals, P2vocals])
				vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		if (SepVocalsNull) {
			vocals.time = Conductor.songPosition;
			vocals.play();
		} else
			for (vocals in [P1vocals, P2vocals]) {
				vocals.time = Conductor.songPosition;
				vocals.play();
			}

		#if windows
		DiscordClient.changePresence(detailsText
			+ " "
			+ SONG.song
			+ " ("
			+ storyDifficultyText
			+ ") "
			+ Ratings.GenerateLetterRank(accuracy),
			"\nAcc: "
			+ HelperFunctions.truncateFloat(accuracy, 2)
			+ "% | Score: "
			+ songScore
			+ " | Misses: "
			+ misses, iconRPC);
		#end
	}

	function playCutscene(name:String, atEndOfSong:Bool = false) {
		inCutscene = true;
		FlxG.sound.music.stop();

		var video:VideoHandler = new VideoHandler();
		video.finishCallback = function() {
			if (atEndOfSong) {
				if (storyPlaylist.length <= 0)
					FlxG.switchState(new StoryMenuState());
				else {
					SONG = Song.loadFromJson(storyPlaylist[0].toLowerCase());
					FlxG.switchState(new PlayState());
				}
			} else
				startCountdown();
		}
		video.playVideo(Paths.video(name));
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	public static var songRate = 1.5;

	override public function update(elapsed:Float) {
		info.text = '${SONG.song}' + ' - ' + (storyDifficulty == 2 ? "Hard" : storyDifficulty == 1 ? "Normal" : "Easy");
		if (FlxG.save.data.timer) {
			var curTime:Float = Conductor.songPosition;
			if (curTime < 0)
				curTime = 0;
			var secondsTotal:Int = Math.floor(curTime / 1000);
			if (secondsTotal < 0)
				secondsTotal = 0;
			timer.text = FlxStringUtil.formatTime(secondsTotal, false) + ' / ' + FlxStringUtil.formatTime(songLength / 1000, false);
		}
		if (FlxG.save.data.ratingCounter)
			RatingCounter.text = 'Sicks: ${sicks}\nGoods: ${goods}\nBads: ${bads}\nShits: ${shits}\n';
		if (FlxG.save.data.botplay && FlxG.keys.justPressed.ONE)
			camHUD.visible = !camHUD.visible;

		{
			var balls = notesHitArray.length - 1;
			while (balls >= 0) {
				var cock:Date = notesHitArray[balls];
				if (cock != null && cock.getTime() + 1000 < Date.now().getTime())
					notesHitArray.remove(cock);
				else
					balls = 0;
				balls--;
			}
		}

		super.update(elapsed);

		var scoreTxtChecked:Bool = false;

		if (FlxG.save.data.accuracyDisplay) {
			scoreTxt.text = Ratings.CalculateRanking(songScore, songScoreDef, accuracy);
			scoreTxt.screenCenter(X);

			scoreTxtChecked = true;
		} else {
			scoreTxt.text = "Score: " + songScore;
			scoreTxt.screenCenter(X);
			scoreTxt.x += 125;

			scoreTxtChecked = true;
		}

		if ((FlxG.keys.justPressed.ENTER #if android || FlxG.android.justReleased.BACK #end) && startedCountdown && canPause) {
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;
			openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}

		if (FlxG.keys.justPressed.SEVEN) {
			#if windows
			DiscordClient.changePresence("Chart Editor", null, null, true);
			#end
			FlxG.switchState(new ChartingState());
		}

		if (FlxG.keys.justPressed.NINE) {
			#if windows
			DiscordClient.changePresence("Animation Debug", null, null, true);
			#end
			FlxG.switchState(new offsets.AnimationDebug());
		}

		iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, 0.50)));
		iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, 0.50)));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		if (health > 2)
			health = 2;
		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		if (startingSong) {
			if (startedCountdown) {
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		} else {
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused) {
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;
				if (Conductor.lastSongPos != Conductor.songPosition) {
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
				}
			}
		}

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null) {
			if (!manualCam && camFollow.x != dad.getMidpoint().x + dad.camPos[0] && !PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
				camFollow.setPosition(dad.getMidpoint().x + dad.camPos[0], dad.getMidpoint().y + dad.camPos[1]);
			if (!manualCam && camGame.zoom != dad.camZoom * cameraZoom && !PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
				camGame.zoom = FlxMath.lerp(dad.camZoom * cameraZoom, camGame.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * 1), 0, 1));

			if (!manualCam && camFollow.x != boyfriend.getMidpoint().x + boyfriend.camPos[0] && PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
				camFollow.setPosition(boyfriend.getMidpoint().x + boyfriend.camPos[0], boyfriend.getMidpoint().y + boyfriend.camPos[1]);
			if (!manualCam && camGame.zoom != boyfriend.camZoom * cameraZoom && PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
				camGame.zoom = FlxMath.lerp(boyfriend.camZoom * cameraZoom, camGame.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * 1), 0, 1));

			if (manualCam && camGame.zoom != cameraZoom)
				camGame.zoom = FlxMath.lerp(cameraZoom, camGame.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * 1), 0, 1));
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		if (health <= 0) {
			playerChar.stunned = true;

			persistentUpdate = false;
			persistentDraw = false;
			paused = true;

			if (SepVocalsNull)
				vocals.stop();
			else
				for (vocals in [P1vocals, P2vocals])
					vocals.stop();
			FlxG.sound.music.stop();

			openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

			#if windows
			DiscordClient.changePresence("GAME OVER -- "
				+ SONG.song
				+ " ("
				+ storyDifficultyText
				+ ") "
				+ Ratings.GenerateLetterRank(accuracy),
				"\nAcc: "
				+ HelperFunctions.truncateFloat(accuracy, 2)
				+ "% | Score: "
				+ songScore
				+ " | Misses: "
				+ misses, iconRPC);
			#end
		}
		if (!inCutscene && FlxG.save.data.resetButton) {
			var resetBind = FlxKey.fromString(FlxG.save.data.resetBind);
			
			if ((FlxG.keys.anyJustPressed([resetBind]))) {
				playerChar.stunned = true;

				persistentUpdate = false;
				persistentDraw = false;
				paused = true;

				if (SepVocalsNull)
					vocals.stop();
				else
					for (vocals in [P1vocals, P2vocals])
						vocals.stop();
				FlxG.sound.music.stop();

				openSubState(new GameOverSubstate(playerChar.getScreenPosition().x, playerChar.getScreenPosition().y));

				#if windows
				DiscordClient.changePresence("GAME OVER -- "
					+ SONG.song
					+ " ("
					+ storyDifficultyText
					+ ") "
					+ Ratings.GenerateLetterRank(accuracy),
					"\nAcc: "
					+ HelperFunctions.truncateFloat(accuracy, 2)
					+ "% | Score: "
					+ songScore
					+ " | Misses: "
					+ misses, iconRPC);
				#end
			}
		}

		if (unspawnNotes[0] != null) {
			if (unspawnNotes[0].strumTime - Conductor.songPosition < 3500) {
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic) {
			notes.forEachAlive(function(daNote:Note) {
				if (daNote.tooLate) {
					daNote.active = false;
					daNote.visible = false;
				} else {
					daNote.visible = true;
					daNote.active = true;
				}
				if (FlxG.save.data.downscroll) {
					if (daNote.mustPress)
						daNote.y = (playerStrums.members[Math.floor(Math.abs(daNote.noteData))].y
							+ 0.45 * (Conductor.songPosition - daNote.strumTime) * FlxMath.roundDecimal(SONG.speed, 2));
					else
						daNote.y = (strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].y
							+ 0.45 * (Conductor.songPosition - daNote.strumTime) * FlxMath.roundDecimal(SONG.speed, 2));
					if (daNote.isSustainNote) {
						daNote.x += daNote.width / 2 + 20;
						daNote.y -= daNote.height / 2 - 50;
						if (daNote.animation.curAnim.name.endsWith('end'))
							daNote.y -= daNote.height / 2 - 67.5;

						if (!FlxG.save.data.botplay) {
							if ((!daNote.mustPress || daNote.wasGoodHit || daNote.prevNote.wasGoodHit && !daNote.canBeHit)
								&& daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= (strumLine.y + Note.swagWidth / 2)) {
								var swagRect = new FlxRect(0, 0, daNote.frameWidth * 2, daNote.frameHeight * 2);
								swagRect.height = (strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].y
									+ Note.swagWidth / 2
									- daNote.y) / daNote.scale.y;
								swagRect.y = daNote.frameHeight - swagRect.height;

								daNote.clipRect = swagRect;
							}
						} else {
							var swagRect = new FlxRect(0, 0, daNote.frameWidth * 2, daNote.frameHeight * 2);
							swagRect.height = (strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].y
								+ Note.swagWidth / 2
								- daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;

							daNote.clipRect = swagRect;
						}
					}
				} else {
					if (daNote.mustPress)
						daNote.y = (playerStrums.members[Math.floor(Math.abs(daNote.noteData))].y
							- 0.45 * (Conductor.songPosition - daNote.strumTime) * FlxMath.roundDecimal(SONG.speed, 2));
					else
						daNote.y = (strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].y
							- 0.45 * (Conductor.songPosition - daNote.strumTime) * FlxMath.roundDecimal(SONG.speed, 2));
					if (daNote.isSustainNote) {
						daNote.y -= daNote.height / 2;

						if (!FlxG.save.data.botplay) {
							if ((!daNote.mustPress || daNote.wasGoodHit || daNote.prevNote.wasGoodHit && !daNote.canBeHit)
								&& daNote.y + daNote.offset.y * daNote.scale.y <= (strumLine.y + Note.swagWidth / 2)) {
								var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
								swagRect.y = (strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].y
									+ Note.swagWidth / 2
									- daNote.y) / daNote.scale.y;
								swagRect.height -= swagRect.y;

								daNote.clipRect = swagRect;
							}
						} else {
							var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
							swagRect.y = (strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].y + Note.swagWidth / 2 - daNote.y) / daNote.scale.y;
							swagRect.height -= swagRect.y;

							daNote.clipRect = swagRect;
						}
					}
				}

				var altAnim:String = "";
				if ((FlxG.save.data.poyoMode ? daNote.mustPress : !daNote.mustPress) && daNote.wasGoodHit) {

					if (SONG.notes[Math.floor(curStep / 16)] != null) {
						if (SONG.notes[Math.floor(curStep / 16)].altAnim)
							altAnim = '-alt';
					}

					if ((FlxG.save.data.noteSplashes && (FlxG.save.data.poyoMode || (SONG.song.toLowerCase() == 'epic' && FlxG.random.bool(68)))) && !daNote.isSustainNote) {
						var noteSplash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
						noteSplash.setupNoteSplash(strum_2.members[Std.int(daNote.noteData)].getMidpoint().x, strum_2.members[Std.int(daNote.noteData)].getMidpoint().y, daNote.noteData);
						grpNoteSplashes.add(noteSplash);
					}

					opponentChar.playAnim(noteAnimations[Std.int(Math.abs(daNote.noteData))] + altAnim, true);
					opponentChar.holdTimer = 0;

					strum_2.forEach(function(spr:FlxSprite) {
						if (Math.abs(daNote.noteData) == spr.ID) {
							spr.animation.play('confirm', true);
						}
						if (spr.animation.curAnim.name == 'confirm') {
							spr.centerOffsets();
							spr.offset.x -= 13;
							spr.offset.y -= 13;
						} else
							spr.centerOffsets();
					});

					if (SONG.needsVoices)
						if (SepVocalsNull)
							vocals.volume = 1;
						else
							for (vocals in [P1vocals, P2vocals])
								vocals.volume = 1;

					if (!daNote.isSustainNote) {
						var noteDiff:Float = Math.abs(daNote.strumTime - Conductor.songPosition);
						daNote.rating = Ratings.CalculateRating(noteDiff);

						popUpScore(daNote, false);
					}

					daNote.active = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}

				if (daNote.mustPress) {
					daNote.visible = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].visible;
					daNote.x = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].x;
					if (!daNote.isSustainNote)
						daNote.angle = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].angle;
					daNote.alpha = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].alpha;
				} else if (!daNote.wasGoodHit) {
					daNote.visible = strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].visible;
					daNote.x = strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].x;
					if (!daNote.isSustainNote)
						daNote.angle = strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].angle;
					daNote.alpha = strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].alpha;
				}

				if (daNote.isSustainNote) {
					daNote.x += daNote.width / 2 + 20;
					daNote.y += daNote.height / 2;
				}

				if (((FlxG.save.data.poyoMode ? !daNote.mustPress : daNote.mustPress) && daNote.tooLate && !FlxG.save.data.downscroll || (FlxG.save.data.poyoMode ? !daNote.mustPress : daNote.mustPress) && daNote.tooLate && FlxG.save.data.downscroll)
					&& (FlxG.save.data.poyoMode ? !daNote.mustPress : daNote.mustPress)) {
					if (daNote.isSustainNote && daNote.wasGoodHit) {
						daNote.kill();
						notes.remove(daNote, true);
					} else {
						health -= 0.075;
						if (SepVocalsNull)
							vocals.volume = 0;
						else
							P1vocals.volume = 0;

						noteMiss(daNote.noteData, daNote);
					}

					daNote.visible = false;
					daNote.kill();
					notes.remove(daNote, true);
				}
			});

			for (char in [dad, boyfriend]) {
				if (char.specialTransition) {
					for (animation in noteAnimations) {
						if (char.animation.curAnim.name == animation && char.animation.finished)
							char.dance();
					}
				}
			}
		}

		strum_2.forEach(function(spr:FlxSprite) {
			if (spr.animation.finished) {
				spr.animation.play('static');
				spr.centerOffsets();
			}
		});

		if (!inCutscene)
			keyShit();
	}

	function endSong():Void {
		if (FlxG.save.data.fpsCap > 290)
			(cast(Lib.current.getChildAt(0), Main)).setFPSCap(290);

		canPause = false;
		FlxG.sound.music.volume = 0;
		if (SepVocalsNull)
			vocals.volume = 0;
		else
			for (vocals in [P1vocals, P2vocals])
				vocals.volume = 0;
		if (SONG.validScore) {
			var songHighscore = StringTools.replace(PlayState.SONG.song, " ", "-");
			#if !switch
			Highscore.saveScore(songHighscore, Math.round(songScore), storyDifficulty);
			#end
		}

		if (isStoryMode) {
			campaignScore += Math.round(songScore);

			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0) {
				FlxG.sound.playMusic(Paths.music('freakyMenu'));

				transIn = FlxTransitionableState.defaultTransIn;
				transOut = FlxTransitionableState.defaultTransOut;

				FlxG.switchState(new StoryMenuState());

				StoryMenuState.weekUnlocked[Std.int(Math.min(storyWeek + 1, StoryMenuState.weekUnlocked.length - 1))] = true;

				if (SONG.validScore) {
					Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty);
				}
				FlxG.save.flush();
			} else {
				var difficulty:String = "";

				if (storyDifficulty == 0)
					difficulty = '-easy';

				if (storyDifficulty == 2)
					difficulty = '-hard';

				var nextSongLowercase = StringTools.replace(PlayState.storyPlaylist[0], " ", "-").toLowerCase();
				var songLowercase = StringTools.replace(PlayState.SONG.song, " ", "-").toLowerCase();

				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				prevCamFollow = camFollow;

				PlayState.SONG = Song.loadFromJson(nextSongLowercase + difficulty, PlayState.storyPlaylist[0]);
				FlxG.sound.music.stop();

				FlxG.switchState(new PlayState());
			}
		} else {
			FlxG.switchState(new FreeplayState());
		}
	}

	var endingSong:Bool = false;

	var hits:Array<Float> = [];

	private function popUpScore(daNote:Note, player:Bool = true):Void {
		var noteDiff:Float = Math.abs(Conductor.songPosition - daNote.strumTime);
		var wife:Float = EtternaFunctions.wife3(noteDiff, Conductor.timeScale);
		if (SONG.needsVoices)
			if (SepVocalsNull)
				vocals.volume = 1;
			else
				for (vocals in [P1vocals, P2vocals])
					vocals.volume = 1;

		var placement:String = Std.string(combo);

		var rating:FlxSprite = new FlxSprite();
		var daRating = daNote.rating;
		var score:Float = 350;

		var strumToUse:FlxTypedGroup<FlxSprite> = player ? strum_1 : strum_2;

		switch (daRating) {
			case 'shit':
				daRating = 'shit';
				score = -300;
				if (player) {
					combo = 0;
					health -= 0.2;
					shits++;
					totalNotesHit += 0.25;
				}
			case 'bad':
				daRating = 'bad';
				score = 0;
				if (player) {
					health -= 0.06;
					bads++;
					totalNotesHit += 0.50;
				}
			case 'good':
				daRating = 'good';
				score = 200;
				if (player) {
					goods++;
					if (health < 2)
						health += 0.04;
					totalNotesHit += 0.75;
				}
			case 'sick':
				daRating = 'sick';
				if (player) {
					if (health < 2)
						health += 0.1;
					totalNotesHit += 1;
					sicks++;
				}
		}
		if (daRating == 'sick' && FlxG.save.data.noteSplashes) {
			var noteSplash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
			noteSplash.setupNoteSplash(strumToUse.members[Std.int(daNote.noteData)].getMidpoint().x, strum_1.members[Std.int(daNote.noteData)].getMidpoint().y, daNote.noteData);
			grpNoteSplashes.add(noteSplash);
		}

		if ((daRating != 'shit' || daRating != 'bad') && player) {
			songScore += Math.round(score);
			songScoreDef += Math.round(ConvertScore.convertScore(noteDiff));
		}

		if (FlxG.save.data.ratings) {
			if (lastRating != null) {
				lastRating.kill();
			}
			rating.loadGraphic(Paths.image(daRating, 'shared'));
			rating.screenCenter();
			rating.x += player ? (FlxG.save.data.poyoMode ? 200 : -200) : (FlxG.save.data.poyoMode ? -200 : 200);
			rating.y -= 50;
			rating.acceleration.y = 550;
			rating.velocity.y -= FlxG.random.int(140, 175);

			if (!FlxG.save.data.botplay)
				add(rating);

			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = true;
			rating.updateHitbox();
			rating.cameras = [camHUD];

			FlxTween.tween(rating, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					rating.destroy();
				},
				startDelay: Conductor.crochet * 0.001
			});
		}
		curSection += 1;
	}

	var upHold:Bool = false;
	var downHold:Bool = false;
	var rightHold:Bool = false;
	var leftHold:Bool = false;

	private function keyShit():Void {
		var holdArray:Array<Bool> = [controls.LEFT, controls.DOWN, controls.UP, controls.RIGHT];
		var pressArray:Array<Bool> = [controls.LEFT_P, controls.DOWN_P, controls.UP_P, controls.RIGHT_P];
		var releaseArray:Array<Bool> = [controls.LEFT_R, controls.DOWN_R, controls.UP_R, controls.RIGHT_R];

		var possibleNotes:Array<Note> = [];
		var directionList:Array<Int> = [];
		var directionsAccounted:Array<Bool> = [false,false,false,false]; // we don't want to do judgments for more than one presses

		if (FlxG.save.data.botplay)
			for (i in [holdArray, pressArray, releaseArray])
				i = [false];

		notes.forEachAlive(function(daNote:Note) {
			if ((FlxG.save.data.poyoMode ? !daNote.mustPress : daNote.mustPress) && !daNote.tooLate && !daNote.wasGoodHit && daNote.canBeHit) {
				if (!directionList.contains(daNote.noteData)) {
					possibleNotes.push(daNote);
					directionList.push(daNote.noteData);
				} else {
					directionsAccounted[daNote.noteData] = true;
					for (coolNote in possibleNotes) {
						if (coolNote.noteData == daNote.noteData && daNote.strumTime < coolNote.strumTime) {
							possibleNotes.remove(coolNote);
							possibleNotes.push(daNote);
						}
					}
				}
			}
		});

		possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

		if (possibleNotes.length != 0) {
			for (note in possibleNotes) {
				if (pressArray[note.noteData] && !note.isSustainNote) {
					goodNoteHit(note);
					continue;
				}
				if (holdArray[note.noteData] && note.isSustainNote) {
					goodNoteHit(note);
					continue;
				}
			}
		}

		for (char in [dad, boyfriend]) {
			if (char.holdTimer > (Conductor.crochet / 1000) * char.maxHTimer && isCharacterSinging(char) && !char.specialTransition)
				char.dance();
		}

		strum_1.forEach(function(spr:FlxSprite) {
			if (pressArray[spr.ID] && spr.animation.curAnim.name != 'confirm')
				spr.animation.play('pressed');
			if (!holdArray[spr.ID])
				spr.animation.play('static');

			if (spr.animation.curAnim.name == 'confirm') {
				spr.centerOffsets();
				spr.offset.x -= 13;
				spr.offset.y -= 13;
			} else
				spr.centerOffsets();
		});
	}

	function noteMiss(direction:Int = 1, daNote:Note):Void {
		playerChar.holdTimer = 0;
		if (!boyfriend.stunned) {
			health -= 0.04;
			if (combo > 5 && gf.animOffsets.exists('sad') && !FlxG.save.data.poyoMode) {
				gf.playAnim('sad');
			}
			combo = 0;
			misses++;

			songScore -= 10;

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3, 'shared'), FlxG.random.float(0.1, 0.2));

			playerChar.playAnim(noteAnimations[Std.int(direction)] + '-miss', true);

			updateAccuracy();
		}
	}

	function updateAccuracy() {
		totalPlayed += 1;
		accuracy = Math.max(0, totalNotesHit / totalPlayed * 100);
	}

	function getKeyPresses(note:Note):Int {
		var possibleNotes:Array<Note> = [];

		notes.forEachAlive(function(daNote:Note) {
			if (daNote.canBeHit && (FlxG.save.data.poyoMode ? !daNote.mustPress : daNote.mustPress) && !daNote.tooLate) {
				possibleNotes.push(daNote);
				possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
			}
		});
		if (possibleNotes.length == 1)
			return possibleNotes.length + 1;
		return possibleNotes.length;
	}

	var mashing:Int = 0;
	var mashViolations:Int = 0;

	var etternaModeScore:Int = 0;

	function noteCheck(controlArray:Array<Bool>, note:Note):Void {
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition);

		note.rating = Ratings.CalculateRating(noteDiff);

		if (controlArray[note.noteData]) {
			goodNoteHit(note, (mashing > getKeyPresses(note)));
		}
	}

	function goodNoteHit(note:Note, resetMashViolation = true):Void {
		playerChar.holdTimer = 0;
		if (mashing != 0)
			mashing = 0;

		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition);

		note.rating = Ratings.CalculateRating(noteDiff);
		if (!note.isSustainNote)
			notesHitArray.unshift(Date.now());

		if (!resetMashViolation && mashViolations >= 1)
			mashViolations--;

		if (mashViolations < 0)
			mashViolations = 0;

		if (!note.wasGoodHit) {
			if (!note.isSustainNote) {
				popUpScore(note);
				combo++;
			} else
				totalNotesHit += 1;

			playerChar.playAnim(noteAnimations[Std.int(note.noteData)], true);

			strum_1.forEach(function(spr:FlxSprite) {
				if (Math.abs(note.noteData) == spr.ID)
					spr.animation.play('confirm', true);
			});

			note.wasGoodHit = true;
			if (SONG.needsVoices)
				if (SepVocalsNull)
					vocals.volume = 1;
				else
					for (vocals in [P1vocals, P2vocals])
						vocals.volume = 1;

			note.kill();
			notes.remove(note, true);
			note.destroy();

			updateAccuracy();
		}
	}

	override function stepHit() {
		var WHYISTHERESOMUCHZOOMS:Array<Array<Int>> = [
			[
				1294,
				1358,
				1422,
				1454,
				1486
			],
			[
				1326,
				1358,
				1390,
				1454,
				1486,
				1490,
				1518
			]
		];
		super.stepHit();
		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
			resyncVocals();

		if (SONG.song.toLowerCase() == 'epic') {
			for (event in WHYISTHERESOMUCHZOOMS[0])  {
				if (curStep == event) {
					cameraZoom = 1.2;
				} else if (curStep == event + 4) {
					cameraZoom = 1;
				}
			}
			for (event in WHYISTHERESOMUCHZOOMS[1])  {
				if (curStep == event) {
					cameraZoom = 1.45;
				} else if (curStep == event + 4) {
					cameraZoom = 1;
				}
			}
		}

		#if windows
		songLength = FlxG.sound.music.length;
		DiscordClient.changePresence(detailsText
			+ " "
			+ SONG.song
			+ " ("
			+ storyDifficultyText
			+ ") "
			+ Ratings.GenerateLetterRank(accuracy),
			"Acc: "
			+ HelperFunctions.truncateFloat(accuracy, 2)
			+ "% | Score: "
			+ songScore
			+ " | Misses: "
			+ misses, iconRPC, true,
			songLength
			- Conductor.songPosition);
		#end
	}

	override function beatHit() {
		super.beatHit();

		if (SONG.song.toLowerCase() == 'epic') {
			if (curBeat == 0) {
				gfCanBop = false;
				cameraCanBop = false;
			}
			if (curBeat == 16) {
				gfCanBop = true;
				cameraCanBop = true;
				gfSpeed = 4;
			}
	
			if (curBeat == 48) {
				gfSpeed = 2;
				cameraBop = 2;
			}

			if (curBeat == 64) {
				gfSpeed = 1;
				cameraBop = 1;
			}

			if (curBeat == 80) {
				cameraZoom = 1.25;
				camGame.fade(FlxColor.BLACK, Conductor.crochet / 250);
				cameraBop = 2;
				gfSpeed = 2;
			}
	
			if (curBeat == 88) {
				cameraZoom = 1;
				gfSpeed = 1;
				cameraBop = 4;
				camGame.flash(FlxColor.WHITE, 0.4);
				camGame.fade(FlxColor.BLACK, 0, true);
			}

			if (curBeat == 152) {
				manualCam = true;
				camFollow.setPosition(stage.width / 2, stage.height / 2 - 125);
				cameraZoom = 1;
			}

			if (curBeat == 216) {
				cameraZoom = 1;
				gfSpeed = 4;
				manualCam = false;
				cameraCanBop = false;
				camGame.flash(FlxColor.WHITE, 1);
				stage.alpha = 0.62;
			}

			if (curBeat == 248) {
				cameraCanBop = true;
				gfSpeed = 2;
			}

			if (curBeat == 312) {
				cameraZoom = 1.25;
				camGame.fade(FlxColor.BLACK, Conductor.crochet / 250);
				cameraBop = 2;
				gfSpeed = 2;
			}

			if (curBeat == 320) {
				stage.alpha = 1;
				cameraZoom = 1;
				gfSpeed = 1;
				cameraBop = 4;
				cameraCanBop = false;
				camGame.flash(FlxColor.WHITE, 0.4);
				camGame.fade(FlxColor.BLACK, 0, true);
			}

			if (curBeat == 384)
				camZoomPerNote = true;

			if (curBeat == 448) {
				cameraCanBop = true;
				camZoomPerNote = false;
				cameraZoom = 1;
			}

			if (curBeat == 512) {
				cameraBop = 2;
				manualCam = true;
				cameraZoom = 1;
				camFollow.setPosition(stage.width / 2, stage.height / 2 - 125);
			}

			if (curBeat == 576) {
				manualCam = false;
			}
		}

		if (curBeat % cameraBop == 0 && cameraCanBop)
			camGame.zoom += 0.045;

		if (generatedMusic)
			notes.sort(FlxSort.byY, (FlxG.save.data.downscroll ? FlxSort.ASCENDING : FlxSort.DESCENDING));
		
		if (SONG.notes[Math.floor(curStep / 16)] != null) {
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
			if (curBeat % 2 == 0) {
				for (character in [dad, boyfriend]) {
					if (character.curCharacter != 'gf' && !character.specialTransition && !isCharacterSinging(character))
						character.dance();
					if (character.curCharacter != 'gf' && character.specialTransition && character.animation.curAnim.name == 'idle')
						character.dance();
					else if (curBeat % gfSpeed == 0 && character.curCharacter == 'gf')
						character.dance();
				}
			}
		}

		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (curBeat % gfSpeed == 0 && gfCanBop)
			gf.dance();
	}

	function isCharacterSinging(char:Character) {
		for (animation in noteAnimations) {
			if (char.animation.curAnim.name == animation) {
				return true;
				break;
			} else
				continue;
		}
		return false;
	}	

	override function destroy(){
		instance = null;
		return super.destroy();
	}
}
