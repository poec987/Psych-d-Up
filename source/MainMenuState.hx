package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.util.FlxTimer;
import flixel.util.FlxGradient;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.display.FlxBackdrop;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import Achievements;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;

import sys.io.File;
import sys.FileSystem;
import haxe.Json;
import haxe.format.JsonParser;

using StringTools;

typedef StyleList =
{
	var styles:Array<String>;
}

typedef StyleSettings =
{
	var defaultButtons:Bool;
	var buttons:Array<String>;
	var offset:Int;
	var hasGradient:Bool;
	var gradientColor:Array<String>;
}

class MainMenuState extends MusicBeatState
{
	var bg:FlxSprite = new FlxSprite( -89).loadGraphic(Paths.image('mainmenu/' + ClientPrefs.menuStyle+'/menuBG'));
	var checker:FlxBackdrop = new FlxBackdrop(Paths.image('mainmenu/' + ClientPrefs.menuStyle +'/Main_Checker'), 0.2, 0.2, true, true);
	var gradientBar:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, 300, 0xFFde6f00);
	var side:FlxSprite = new FlxSprite(0,-220).loadGraphic(Paths.image('Main_Side'));
	
	public static var styleList:StyleList = getStyleFile('assets/images/mainmenu/styles.json');

	public static var ssFile:StyleSettings = getStyleSettings('assets/images/mainmenu/'+ClientPrefs.menuStyle+'/settings.json');

	public static var psychEngineVersion:String = '0.6.3'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;

	public static var menuStyles:Array<String> = ["PsychStyle"];

	var defaultButtons:Bool;
	var buttons:Array<String>;
	var offset:Int;
	var hasGradient:Bool;
	var gradientColor:Array<String>;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;
	
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'credits',
		#if !switch 'donate', #end
		'options'
	];

	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;
	
	var camLerp:Float = 0.1;

	override function create()
	{
		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;
		
		#if MODS_ALLOWED
		Paths.pushGlobalMods();
		#end
		WeekData.loadTheFirstEnabledMod();

		#if MODS_ALLOWED
		styleList = getStyleFile('mods/images/mainmenu/styles.json');
		ssFile = getStyleSettings('mods/images/mainmenu/'+ClientPrefs.menuStyle+'/settings.json');
		#end

		menuStyles = styleList.styles;
		
		defaultButtons = ssFile.defaultButtons;
		buttons = ssFile.buttons;
		offset = ssFile.offset;
		hasGradient = ssFile.hasGradient;
		gradientColor = ssFile.gradientColor;

		if (!defaultButtons) {
			optionShit = buttons;
		}

		SoftSource.runHxFile('images/mainmenu/'+ClientPrefs.menuStyle+'/init');

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement, false);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.9));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		bg.angle = 179;
		add(bg);

		camFollow = new FlxObject(1, 1, 2, 1);
		camFollowPos = new FlxObject(1, 1, 2, 1);
		add(camFollow);
		add(camFollowPos);
		
		if (hasGradient)
		{
			gradientBar = FlxGradient.createGradientFlxSprite(Math.round(FlxG.width), 512, [Std.parseInt(gradientColor[0]), Std.parseInt(gradientColor[1]), Std.parseInt(gradientColor[2])], 1, 90, true);
			gradientBar.y = FlxG.height - gradientBar.height;
			add(gradientBar);
			gradientBar.scrollFactor.set(0, 0);
			
			add(checker);
			checker.scrollFactor.set(0, 0.07);
			
			side.scrollFactor.x = 0;
			side.scrollFactor.y = (optionShit.length - 4) * 0.135;
			side.antialiasing = true;
			add(side);
		}

		magenta = new FlxSprite(-100).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = ClientPrefs.globalAntialiasing;
		magenta.color = 0xFFfd719b;
		add(magenta);
		
		// magenta.scrollFactor.set();

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1;
		/*if(optionShit.length > 6) {
			scale = 6 / optionShit.length;
		}*/

		for (i in 0...optionShit.length)
		{
			var offset:Float = -30 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, (i * 210)  + offset);
			menuItem.scale.x = scale;
			menuItem.scale.y = scale;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/'+ClientPrefs.menuStyle+'/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter(X);
			menuItem.x = menuItem.x + 30 + offset;
			FlxTween.tween(menuItem, {x: (menuItem.width / 4 + (i * 90) + 30) + 10}, 1.3, {ease: FlxEase.expoInOut});
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if(optionShit.length < 6) scr = 0;
			menuItem.scrollFactor.set(0, scr);
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			//menuItem.setGraphicSize(Std.int(menuItem.width * 0.58));
			menuItem.updateHitbox();
		}

		FlxG.camera.follow(camFollow, null, camLerp);

		side.alpha = 0;
		FlxG.camera.zoom = 3;
		FlxTween.tween(FlxG.camera, {zoom: 1}, 1.1, {ease: FlxEase.expoInOut});
		FlxTween.tween(bg, {angle: 0}, 1, {ease: FlxEase.quartInOut});
		FlxTween.tween(bg, {width: 1.1}, 1, {ease: FlxEase.quartInOut});
		FlxTween.tween(side, {alpha: 1}, 0.9, {ease: FlxEase.quartInOut});


		var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18) {
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if(!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) { //It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();
				ClientPrefs.saveSettings();
			}
		}
		#end

		super.create();
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement() {
		add(new AchievementObject('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "friday_night_play"');
	}
	#end

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
			if(FreeplayState.vocals != null) FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 10, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		checker.x -= 0.45 / (ClientPrefs.framerate / 60);
		checker.y -= 0.16 / (ClientPrefs.framerate / 60);
		
		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				if (optionShit[curSelected] == 'donate')
				{
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));

					
					FlxTween.tween(FlxG.camera, {zoom: 5}, 0.8, {ease: FlxEase.expoIn});
					FlxTween.tween(bg, {angle: 45}, 0.8, {ease: FlxEase.expoIn});
					
					new FlxTimer().start(0.4, function(tmr:FlxTimer)
					{
						var daChoice:String = optionShit[curSelected];

						SoftSource.runHxFile('images/mainmenu/'+ClientPrefs.menuStyle+'/'+daChoice);

						switch (daChoice)
						{
							case 'story_mode':
								MusicBeatState.switchState(new StoryMenuState());
							case 'freeplay':
								MusicBeatState.switchState(new FreeplayState());
							#if MODS_ALLOWED
							case 'mods':
								MusicBeatState.switchState(new ModsMenuState());
							#end
							case 'awards':
								MusicBeatState.switchState(new AchievementsMenuState());
							case 'credits':
								MusicBeatState.switchState(new CreditsState());
							case 'options':
								LoadingState.loadAndSwitchState(new options.OptionsState());
							case 'play':
								MusicBeatState.switchState(new PlayMenuState());
						}
					});
					
					menuItems.forEach(function(spr:FlxSprite)
					{
						FlxTween.tween(spr, {x: -600}, 0.6, {
							ease: FlxEase.backIn,
							onComplete: function(twn:FlxTween)
							{
								spr.kill();
							}
						});
						{
							FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
							{
								
							});
						}
					});
				}
			}
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);

		menuItems.forEach(function(spr:FlxSprite)
		{
			if (spr.ID == curSelected)
			{
				camFollow.y = FlxMath.lerp(camFollow.y, spr.y * 2.34, camLerp / (ClientPrefs.framerate / 60));
				camFollow.x = FlxMath.lerp(camFollow.x, spr.x, camLerp / (ClientPrefs.framerate / 60));
			}
		});
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			spr.updateHitbox();

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');
				var add:Float = 0;
				var add2:Float = 0;
				if(menuItems.length > 4) {
					add = menuItems.length * 8;
				}
				
				camFollow.setPosition(spr.x, spr.y * 2.34);
				spr.centerOffsets();
			}
		});
	}

	private static function getStyleFile(path:String):StyleList {
		var rawJson:String = null;
		#if MODS_ALLOWED
		if(FileSystem.exists(path)) {
			rawJson = File.getContent(path);
		}
		#else
		if(OpenFlAssets.exists(path)) {
			rawJson = Assets.getText(path);
		}
		#end

		if(rawJson != null && rawJson.length > 0) {
			return cast Json.parse(rawJson);
		}
		return null;
	}

	private static function getStyleSettings(path:String):StyleSettings {
		var rawJson:String = null;
		#if MODS_ALLOWED
		if(FileSystem.exists(path)) {
			rawJson = File.getContent(path);
		}
		#else
		if(OpenFlAssets.exists(path)) {
			rawJson = Assets.getText(path);
		}
		#end

		if(rawJson != null && rawJson.length > 0) {
			return cast Json.parse(rawJson);
		}
		return null;
	}
}
