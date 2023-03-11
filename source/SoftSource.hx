import animateatlas.AtlasFrameMaker;
import flixel.FlxG;
import flixel.addons.effects.FlxTrail;
import flixel.input.keyboard.FlxKey;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.util.FlxTimer;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.util.FlxColor;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets;
import flixel.math.FlxMath;
import flixel.util.FlxSave;
import flixel.addons.transition.FlxTransitionableState;
import flixel.system.FlxAssets.FlxShader;
import FunkinLua.CustomSubstate;

#if hscript
import hscript.Parser;
import hscript.Interp;
import hscript.Expr;
#end
#if sys
import sys.FileSystem;
import sys.io.File;
#end
#if (!flash && sys)
import flixel.addons.display.FlxRuntimeShader;
#end

class SoftSource
{
    public static var parser:Parser = new Parser();
	public var interp:Interp;

	public var variables(get, never):Map<String, Dynamic>;

	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	public function get_variables()
	{
		return interp.variables;
	}

	public function new()
	{
		interp = new Interp();
		interp.variables.set('FlxG', FlxG);
		interp.variables.set('FlxSprite', FlxSprite);
		interp.variables.set('FlxCamera', FlxCamera);
		interp.variables.set('FlxTimer', FlxTimer);
		interp.variables.set('FlxTween', FlxTween);
		interp.variables.set('FlxEase', FlxEase);
		interp.variables.set('PlayState', PlayState);
		interp.variables.set('game', PlayState.instance);
		interp.variables.set('state', CustomState.instance);
		interp.variables.set('Paths', Paths);
		interp.variables.set('Conductor', Conductor);
		interp.variables.set('ClientPrefs', ClientPrefs);
		interp.variables.set('Character', Character);
		interp.variables.set('Alphabet', Alphabet);
		interp.variables.set('CustomSubstate', CustomSubstate);
        interp.variables.set('MusicBeatState', MusicBeatState);
        interp.variables.set('MusicBeatSubstate', MusicBeatSubstate);
        interp.variables.set('CustomState', CustomState);
		interp.variables.set('FlxTypedGroup', FlxTypedGroup);
		interp.variables.set('FlxMath', FlxMath);
		interp.variables.set('FlxSave', FlxSave);
		interp.variables.set('FlxBasic', FlxMath);
		interp.variables.set('FlxObject', FlxObject);
		interp.variables.set('FlxText', FlxText);
		interp.variables.set('FlxSound', FlxSound);
		interp.variables.set('FlxGroup', FlxGroup);
		interp.variables.set('FlxState', FlxState);
		interp.variables.set('controls', controls);
		#if (!flash && sys)
		interp.variables.set('FlxRuntimeShader', FlxRuntimeShader);
		#end
		interp.variables.set('ShaderFilter', openfl.filters.ShaderFilter);
		interp.variables.set('StringTools', StringTools);

		interp.variables.set('switchToCustomState', function(state:String) {
			MusicBeatState.switchState(new CustomState(state));
		});

		// Variable Support

		interp.variables.set('setVar', function(name:String, value:Dynamic)
		{
			CustomState.instance.vars.set(name, value);
		});
		interp.variables.set('getVar', function(name:String)
		{
			var result:Dynamic = null;
			if(CustomState.instance.vars.exists(name)) result = CustomState.instance.vars.get(name);
			return result;
		});
		interp.variables.set('removeVar', function(name:String)
		{
			if(CustomState.instance.vars.exists(name))
			{
				CustomState.instance.vars.remove(name);
				return true;
			}
			return false;
		});

		// Other Functions

		interp.variables.set('add', function(object:flixel.FlxBasic)
		{
			return CustomState.instance.add(object);
		});

		interp.variables.set('runHxFile', function(key:String)
		{
			runHxFile(key);
		});

		interp.variables.set('loadGraphic', function(asset:String)
		{
			return new FlxSprite().loadGraphic(Paths.image(asset));
		});

		interp.variables.set('importLib', function(libName:String, ?libPackage:String = '') {
			var str:String = '';
			if(libPackage.length > 0)
				str = libPackage + '.';
			interp.variables.set(libName, Type.resolveClass(str + libName));
		});

		interp.variables.set('colorHex', function(hex:Int)
		{
			return FlxColor.fromInt(hex);
		});
		interp.variables.set('alignText', function(dir:String) {
			switch (dir)
			{
				case 'LEFT':
					return FlxTextAlign.LEFT;
				case 'CENTER':
					return FlxTextAlign.CENTER;
				case 'RIGHT':
					return FlxTextAlign.RIGHT;
			}
			return FlxTextAlign.LEFT;
		});
	}

    public static function runHxFile(key:String, ?ignoreMods:Bool = false) {
        if (FileSystem.exists(Paths.hx(key)))
        {
            var code:String = File.getContent(Paths.hx(key));
			//trace(code);
			var program:Expr = SoftSource.parser.parseString(code);
			//trace(program);
		    SoftSource.parser.line = 1;
		    SoftSource.parser.allowTypes = true;
		    new SoftSource().interp.execute(program);
        }
        else
        {
            trace('file "'+Paths.hx(key)+'" does not exist');
        }
    }
}

class CustomState extends MusicBeatState
{
	var targetstate:String;
	public static var instance:CustomState;
	#if (haxe >= "4.0.0")
	public var vars:Map<String, Dynamic> = new Map();
	#else
	public var vars:Map<String, Dynamic> = new Map<String, Dynamic>();
	#end

	public function new(state:String) {
		targetstate = state;
		super();
	}

    override function create() {
		instance = this;
		SoftSource.runHxFile('states/'+targetstate+'/create');
		super.create();
	}
	override function update(elapsed:Float) {
		SoftSource.runHxFile('states/'+targetstate+'/update');
		super.update(elapsed);
	}
}