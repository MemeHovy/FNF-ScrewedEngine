package editors;

import Language.LanguageString;
import effects.ColorSwap;
#if desktop
import Discord.DiscordClient;
#end
import Conductor.BPMChangeEvent;
import FunkinLua;
import Section.SwagSection;
import Song.SwagSong;
import flash.geom.Rectangle;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUISlider;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
#if (flixel >= "5.3.0")
import flixel.sound.FlxSound;
#else
import flixel.system.FlxSound;
#end
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import haxe.Json;
import haxe.format.JsonParser;
import haxe.io.Bytes;
import lime.media.AudioBuffer;
import lime.utils.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.Assets as OpenFlAssets;
import openfl.utils.ByteArray;

#if sys
import flash.media.Sound;
import sys.FileSystem;
import sys.io.File;
#end

#if CRASH_HANDLER
import lime.app.Application;
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
#end

using StringTools;


#if (flixel >= "5.3.0")
@:access(flixel.sound.FlxSound._sound)
#else
@:access(flixel.system.FlxSound._sound)
#end
@:access(openfl.media.Sound.__buffer)
class ChartingState extends MusicBeatState
{
	public static var noteTypeList:Array<String> = //Used for backwards compatibility with 0.1 - 0.3.2 charts, though, you should add your hardcoded custom note types here too.
	[
		'',
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'Instakill Note',
		'GF Sing',
		'No Animation',
		'Random Scroll',
		'Rainbow Note',
		'Rainbow Random Scroll' // YESSSSS
	];
	private var noteTypeIntMap:Map<Int, String> = new Map<Int, String>();
	private var noteTypeMap:Map<String, Null<Int>> = new Map<String, Null<Int>>();
	public var ignoreWarnings:Bool = false;
	var undos = [];
	var eventStuff:Array<Dynamic> =
	[
		['', "Nothing. Yep, that's right."],
		['Dadbattle Spotlight', "Used in Dad Battle,\nValue 1: 0/1 = ON/OFF,\n2 = Target Dad\n3 = Target BF"],
		['Hey!', "Plays the \"Hey!\" animation from Bopeebo,\nValue 1: BF = Only Boyfriend, GF = Only Girlfriend,\nSomething else = Both.\nValue 2: Custom animation duration,\nleave it blank for 0.6s"],
		['Set GF Speed', "Sets GF head bopping speed,\nValue 1: 1 = Normal speed,\n2 = 1/2 speed, 4 = 1/4 speed etc.\nUsed on Fresh during the beatbox parts.\n\nWarning: Value must be integer!"],
		['Philly Glow', "Exclusive to Week 3\nValue 1: 0/1/2 = OFF/ON/Reset Gradient\n \nNo, i won't add it to other weeks."],
		['Kill Henchmen', "For Mom's songs, don't use this please, i love them :("],
		['Add Camera Zoom', "Used on MILF on that one \"hard\" part\nValue 1: Camera zoom add (Default: 0.015)\nValue 2: UI zoom add (Default: 0.03)\nLeave the values blank if you want to use Default."],
		['BG Freaks Expression', "Should be used only in \"school\" Stage!"],
		['Trigger BG Ghouls', "Should be used only in \"schoolEvil\" Stage!"],
		['Play Animation', "Plays an animation on a Character,\nonce the animation is completed,\nthe animation changes to Idle\n\nValue 1: Animation to play.\nValue 2: Character (Dad, BF, GF)"],
		['Camera Follow Pos', "Value 1: X\nValue 2: Y\n\nThe camera won't change the follow point\nafter using this, for getting it back\nto normal, leave both values blank."],
		['Alt Idle Animation', "Sets a specified suffix after the idle animation name.\nYou can use this to trigger 'idle-alt' if you set\nValue 2 to -alt\n\nValue 1: Character to set (Dad, BF or GF)\nValue 2: New suffix (Leave it blank to disable)"],
		['Screen Shake', "Value 1: Camera shake\nValue 2: HUD shake\n\nEvery value works as the following example: \"1, 0.05\".\nThe first number (1) is the duration.\nThe second number (0.05) is the intensity."],
		['Change Character', "Value 1: Character to change (Dad, BF, GF)\nValue 2: New character's name"],
		['Change Scroll Speed', "Value 1: Scroll Speed Multiplier (1 is default)\nValue 2: Time it takes to change fully in seconds."],
		['Zoom In/Out', 'Zooms the camGame to the specified value.\nValue 1: value, duration. (EX: 2, 7)\nValue 2: Ease to use. (blank/default is quadOut)'],
		['Set Property', "Value 1: Variable name\nValue 2: New value"],
		//['Kill Shaders', "Value 1: Camera\nClears all the shaders of the specified camera"],
		['Rainbow Eyesore', "Value 1: Step to end at\nValue 2: Speed"],
		['Popup', "Value 1: Title\nValue 2: Message\nMakes a window popup with a message in it."],
		['Popup (No Pause)', "Value 1: Title\nValue 2: Message\nSame as popup but without a pause."],
		['\"Screw you!\" Text Change', "Value 1: Text\n\nChanges the \"Screw you!\" text."],
		//['Random Text Change', "\n\n\nValue 1: Step to end at\nValue 2: List of words seperated with ^\nChanges the \"Screw you!\" text through\na list of words you put.\nChanges on a step hit."],
		['Deactivate CPU LIGHT', "Disables the CPU STRUM to be lighted.\nUseful for songs that use a lot of\nnotes."],
		['Activate CPU LIGHT', "The opposite of the earlier one"],
		['Deactivate PLAYER LIGHT', "The same but for player"],
		['Activate PLAYER LIGHT', "The opposite of the earlier one"],
		['(SOURCE ONLY) Add GlitchEffect', 'Adds a Glitch effect to the FlxSprite.\nValue 1: tag (name) of the FlxSprite.\n\n<b><r>YOU SHOULD ALWAYS USE\n<i>"addEventObject(tag, object)"<i>\nAFTER CREATING THE FLXSPRITE<r><b>']
	];

	var pressing7Events:Array<String> = [
		'---',
		'None',
		'Game Over',
		'Go to Song',
		'Close Game',
		'Play Video',
		'Rainbow Eyesore',
		'Chromatic Aberration',
		'Nothing' // why?
	];

	var boldFormat:FlxTextFormat;
	var italicFormat:FlxTextFormat;
	var strongFormat:FlxTextFormat;
	var redFormat:FlxTextFormat;
	var blackFormat:FlxTextFormat;

	var colorSwap:ColorSwap;

	var _file:FileReference;

	var UI_box:FlxUITabMenu;

	public static var goToPlayState:Bool = false;
	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	public static var curSec:Int = 0;
	public static var lastSection:Int = 0;
	private static var lastSong:String = '';

	var bpmTxt:FlxText;


	var camPos:FlxObject;
	var strumLine:FlxSprite;
	var quant:AttachedSprite;
	var strumLineNotes:FlxTypedGroup<StrumNote>;
	var curSong:String = 'Test';
	var amountSteps:Int = 0;
	var bullshitUI:FlxGroup;

	var highlight:FlxSprite;

	public static inline final GRID_SIZE:Int = 40;
	var CAM_OFFSET:Int = 360;

	var dummyArrow:FlxSprite;

	var curRenderedSustains:FlxTypedGroup<FlxSprite>;
	var curRenderedNotes:FlxTypedGroup<Note>;
	var curRenderedNoteType:FlxTypedGroup<FlxText>;

	var nextRenderedSustains:FlxTypedGroup<FlxSprite>;
	var nextRenderedNotes:FlxTypedGroup<Note>;

	var gridBG:FlxSprite;
	var nextGridBG:FlxSprite;

	var daquantspot = 0;
	var curEventSelected:Int = 0;
	var curUndoIndex:Int = 0;
	var _song:SwagSong;
	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:Array<Dynamic> = null;

	var playbackSpeed:Float = 1;

	var vocals:FlxSound = null;

	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;

	var value1InputText:FlxUIInputText;
	var value2InputText:FlxUIInputText;
	var currentSongName:String;

	var zoomTxt:FlxText;
	/**
	 A strange way to implement zoom

	 * ITS A `FLOAT` VALUE
	 */
	var manualZoomInput:FlxUINumericStepper;
	var resetZoomText:FlxText;

	var debugWaveform:FlxUICheckBox;
	var waveformLeftActiveLeft:FlxUICheckBox;
	var waveformLeftActiveRight:FlxUICheckBox;
	var waveformRightActiveLeft:FlxUICheckBox;
	var waveformRightActiveRight:FlxUICheckBox;
	var waveformLeftMin:FlxUICheckBox;
	var waveformLeftMax:FlxUICheckBox;
	var waveformRightMin:FlxUICheckBox;
	var waveformRightMax:FlxUICheckBox;

	var zoomList:Array<Float> = [
		0.25,
		0.5,
		1,
		1.5,
		2,
		3,
		4,
		6,
		7,
		7.5,
		8,
		12,
		16,
		19,
		24,
		30,
		48,
		51.2
	];
	var oldZoomList:Array<Float> = [
		0.25,
		0.5,
		1,
		1.5,
		2,
		3,
		4,
		6,
		7,
		7.5,
		8,
		12,
		16,
		19,
		24,
		30,
		48,
		51.2
	];
	var curZoom:Int = 2;

	private var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	private var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];
	private var blockPressWhileScrolling:Array<FlxUIDropDownMenuCustom> = [];

	var waveformSprite:FlxSprite;
	var gridLayer:FlxTypedGroup<FlxSprite>;

	public static var quantization:Int = 16;
	public static var curQuant = 3;

	public var quantizations:Array<Int> = [
		4,
		8,
		12,
		16,
		20,
		24,
		32,
		48,
		64,
		96,
		128,
		192,
		256,
		384,
		512,
		768,
		1024,
		1536
	];

	#if LUA_ALLOWED
	private static var debugGroup:FlxTypedGroup<DebugLuaText>;
	#end

	var text:LanguageString = {s: ""};
	public static var vortex:Bool = false;
	public var mouseQuant:Bool = false;

	public static var instance:ChartingState = null;

	override function create()
	{
		if (PlayState.SONG != null)
			_song = PlayState.SONG;
		else
		{
			CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();

			_song = {
				song: 'Test',
				notes: [],
				events: [],
				bpm: 150.0,
				needsVoices: true,
				arrowSkin: '',
				playerArrowSkin: '',
				splashSkin: 'noteSplashes',//idk it would crash if i didn't
				player1: 'bf',
				player2: 'dad',
				gfVersion: 'gf',
				speed: 1,
				stage: 'stage',
				screwYou: '',
				credit: '',
				ghostTappingAllowed: true,
				event7: '',
				event7Value: ''
			};
			addSection();
			PlayState.SONG = _song;
		}

		var normalColor:FlxColor = FlxColor.WHITE;
		boldFormat = new FlxTextFormat(normalColor, true, false);
		italicFormat = new FlxTextFormat(normalColor, false, true);
		strongFormat = new FlxTextFormat(normalColor, true, true);
		redFormat = new FlxTextFormat(FlxColor.RED);
		blackFormat = new FlxTextFormat(FlxColor.BLACK);

		PlayState.chartingMode = true;
		instance = this;

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Chart Editor", StringTools.replace(_song.song, '-', ' '));
		#end

		vortex = FlxG.save.data.chart_vortex;
		ignoreWarnings = FlxG.save.data.ignoreWarnings;
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF222222;
		add(bg);

		gridLayer = new FlxTypedGroup<FlxSprite>();
		add(gridLayer);

		waveformSprite = new FlxSprite(GRID_SIZE, 0).makeGraphic(FlxG.width, FlxG.height, 0x00FFFFFF);
		add(waveformSprite);

		var eventIcon:FlxSprite = new FlxSprite(-GRID_SIZE - 5, -90).loadGraphic(Paths.image('eventArrow'));
		leftIcon = new HealthIcon('bf');
		rightIcon = new HealthIcon('dad');
		eventIcon.scrollFactor.set(1, 1);
		leftIcon.scrollFactor.set(1, 1);
		rightIcon.scrollFactor.set(1, 1);

		eventIcon.setGraphicSize(30, 30);
		leftIcon.setGraphicSize(0, 45);
		rightIcon.setGraphicSize(0, 45);

		add(eventIcon);
		add(leftIcon);
		add(rightIcon);

		leftIcon.setPosition(GRID_SIZE + 10, -100);
		rightIcon.setPosition(GRID_SIZE * 5.2, -100);

		curRenderedSustains = new FlxTypedGroup<FlxSprite>();
		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedNoteType = new FlxTypedGroup<FlxText>();

		nextRenderedSustains = new FlxTypedGroup<FlxSprite>();
		nextRenderedNotes = new FlxTypedGroup<Note>();

		if(curSec >= _song.notes.length) curSec = _song.notes.length - 1;

		FlxG.mouse.visible = true;
		//FlxG.save.bind('funkin', CoolUtil.getSavePath());

		addSection();

		// sections = _song.notes;

		currentSongName = Paths.formatToSongPath(_song.song);
		loadSong();
		reloadGridLayer();
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

		bpmTxt = new FlxText(1000, 50, 0, "", 16);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(GRID_SIZE * 9), 4);
		add(strumLine);

		quant = new AttachedSprite('chart_quant','chart_quant');
		quant.animation.addByPrefix('q','chart_quant',0,false);
		quant.animation.play('q', true, false, 0);
		quant.sprTracker = strumLine;
		quant.xAdd = -32;
		quant.yAdd = 8;
		add(quant);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		for (i in 0...8) {
			var note:StrumNote = new StrumNote(GRID_SIZE * (i + 1), strumLine.y, i % 4, 0);
			note.setGraphicSize(GRID_SIZE, GRID_SIZE);
			note.updateHitbox();
			note.playAnim('static', true);
			strumLineNotes.add(note);
			note.scrollFactor.set(1, 1);
		}
		add(strumLineNotes);

		camPos = new FlxObject(0, 0, 1, 1);
		camPos.setPosition(strumLine.x + CAM_OFFSET, strumLine.y);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);

		var tabs = [
			{name: "Song", label: 'Song'},
			{name: "Section", label: 'Section'},
			{name: "Note", label: 'Note'},
			{name: "Events", label: 'Events'},
			{name: "Charting", label: 'Charting'},
		];

		UI_box = new FlxUITabMenu(null, tabs, true);

		UI_box.resize(300, 400);
		UI_box.x = 640 + GRID_SIZE / 2;
		UI_box.y = 25;
		UI_box.scrollFactor.set();

		var keyBonds = ClientPrefs.keyBinds;
		text = {s:
		"W/S or Mouse Wheel - Change Conductor's strum time
		\nA/D - Go to the previous/next section
		\nLeft/Right - Change Snap
		\nUp/Down - Change Conductor's Strum Time with Snapping
		\nLeft Bracket / Right Bracket - Change Song Playback Rate (SHIFT to go Faster)
		\nALT + Left Bracket / Right Bracket - Reset Song Playback Rate
		\nHold SHIFT to move 4x faster
		\nHold CONTROL and click on an arrow to select it
		\n" + keyBonds["zoom+"][0].toString() + /*keyBonds["zoom+"][1] == NONE ? "" : keyBonds["zoom+"][1].toString() + ")" +*/ "/" + keyBonds["zoom-"][0].toString() + " - Zoom in/out
		\n" + keyBonds["save"][0].toString() + " - Save Chart (Autosave it)
		\nHold C - Drawing
		\nESC - Test your chart inside Chart Editor
		\nENTER - Play your chart
		\n" + keyBonds["decrease"][0].toString() + "/" + keyBonds["increase"][0].toString() + " - Decrease/Increase Note Sustain Length
		\nSPACE - Stop/Resume song",
		spanish:
		'W/S o Rueda del Mouse - Cambiar tiempo de la canción.
		\nA/D - Ir a la anterior/siguiente sección.
		\nIzquierda/Derecha - Cambiar "Snap".
		\nArriba/Abajo - Cambiar tiempo de la canción con "Snap".
		\n"Bracket" Izquierdo / "Bracket" Derecho - Cambiar Playback Rate (pulsa SHIFT para ir más rápido)
		\nALT + "Bracket" Izquierdo / "Bracket" - Reiniciar Playback Rate.
		\nMantén SHIFT para mover 4 veces más rápido.
		\nMantén CONTROL y haz CLICK IZQUIERDO en una nota para seleccionarla.
		\n' /*+ "("*/ + keyBonds['zoom+'][0].toString() + /*keyBonds["zoom+"][1] == NONE ? "" : keyBonds["zoom+"][1].toString() + ")" +*/ "/" + keyBonds['zoom-'][0].toString() + ' - Incrementar/Decrecer Zoom.
		\n' + keyBonds['save'][0].toString() + ' - Guardar "Chart" (Autoguardarlo)
		\nMantener C - "Dibujo"
		\nESC - Prueba tu "chart" con el Editor de Charts.
		\nENTER - Jugar al "chart".
		\n' + keyBonds["decrease"][0].toString() + "/" + keyBonds["increase"][0].toString() + ' - Decrecer/Incrementar Largo de la Nota.
		\nESPACIO - Parar/Resumir canción.'};

		var tipTextArray:Array<String> = Language.getString(text).split('\n');
		for (i in 0...tipTextArray.length) {
			var tipText:FlxText = new FlxText(UI_box.x, UI_box.y + UI_box.height + 7, 0, tipTextArray[i], 17);
			tipText.y += i * 11;
			tipText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT/*, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK*/);
			//tipText.borderSize = 2;
			//tipText.width -= 1;
			tipText.scrollFactor.set();
			add(tipText);
		}
		add(UI_box);

		addSongUI();
		addSectionUI();
		addNoteUI();
		addEventsUI();
		addChartingUI();
		updateHeads();
		updateWaveform();
		//UI_box.selected_tab = 4;

		add(curRenderedSustains);
		add(curRenderedNotes);
		add(curRenderedNoteType);
		add(nextRenderedSustains);
		add(nextRenderedNotes);

		if(lastSong != currentSongName) {
			changeSection();
		}
		lastSong = currentSongName;

		zoomTxt = new FlxText(10, 20, 0, "Zoom: 1 / 1", 16);
		zoomTxt.scrollFactor.set();
		add(zoomTxt);

		manualZoomInput = new FlxUINumericStepper(zoomTxt.x + 20, zoomTxt.y + 200, 0.1, zoomList[curZoom], zoomList[0], zoomList[zoomList.length - 1], 2);
		manualZoomInput.setScrollFactor(0, 0);
		manualZoomInput.value = zoomList[curZoom];
		manualZoomInput.name = 'manual_zoom';
		manualZoomInput.onPlus = function(newValue) {
			if(newValue > manualZoomInput.max)
				addTextToDebug('Exceeded maximum zoom!!', FlxColor.RED);
		};
		manualZoomInput.onMinus = function(newValue) {
			if(newValue < manualZoomInput.min)
				addTextToDebug('Exceeded minimum zoom!!', FlxColor.RED);
		};
		blockPressWhileTypingOnStepper.push(manualZoomInput);
		add(manualZoomInput);

		var manualZoomTxt:FlxText = new FlxText(manualZoomInput.x, manualZoomInput.y - 20, -1, Language.getString({s: 'Manual Zoom:', spanish: 'Zoom Manual:'}), 10);
		manualZoomTxt.scrollFactor.set();
		add(manualZoomTxt);

		resetZoomText = new FlxText(manualZoomInput.x, manualZoomInput.y + 20, 0, Language.getString({s: "Press G to reset Manual Zoom", spanish: "Pulsa G para reinicial el Zoom Manual"}), 10);
		resetZoomText.scrollFactor.set();
		resetZoomText.visible = false;
		add(resetZoomText);

		debugWaveform = new FlxUICheckBox(resetZoomText.x, resetZoomText.y + 50, null, null, "Debug Waveform (BETA)", 200);
		debugWaveform.checked = false;
		debugWaveform.callback = function() {
			createWaveformThings();
			debugWaveform.destroy();
		};
		debugWaveform.scrollFactor.set();
		add(debugWaveform);

		#if LUA_ALLOWED
		debugGroup = new FlxTypedGroup<DebugLuaText>();
		add(debugGroup);
		#end

		colorSwap = new ColorSwap();

		updateGrid();
		super.create();
	}

	function createWaveformThings() {
		//#if debug
		var size2 = 200;
		waveformLeftActiveLeft = new FlxUICheckBox(resetZoomText.x, resetZoomText.y + 80, null, null, 'Waveform Blue Active left', 500);
		waveformLeftActiveRight = new FlxUICheckBox(resetZoomText.x, waveformLeftActiveLeft.y + 20, null, null, 'Waveform Blue Active right', 500);
		waveformRightActiveLeft = new FlxUICheckBox(resetZoomText.x, waveformLeftActiveRight.y + 20, null, null, 'Waveform Red Active left', 500);
		waveformRightActiveRight = new FlxUICheckBox(resetZoomText.x, waveformRightActiveLeft.y + 20, null, null, 'Waveform Red Active right', 500);
		waveformLeftMax = new FlxUICheckBox(resetZoomText.x, waveformRightActiveRight.y + 40, null, null, 'Waveform Maximum left', size2);
		waveformLeftMin = new FlxUICheckBox(waveformLeftMax.x, waveformLeftMax.y + 20, null, null, 'Waveform Minimum left', size2);
		waveformRightMax = new FlxUICheckBox(waveformLeftMin.x, waveformLeftMin.y + 20, null, null, 'Waveform Maximum right', size2);
		waveformRightMin = new FlxUICheckBox(waveformRightMax.x, waveformRightMax.y + 20, null, null, 'Waveform Minimum right', size2);

		for(thing in [ // WHAT IT COULD BE ABOUT 70 LINES LONG, THIS TURNS THEM INTO LESS THAN 14!!!!!!!!!!
			waveformLeftActiveLeft,
			waveformLeftActiveRight,
			waveformRightActiveLeft,
			waveformRightActiveRight,
			waveformLeftMin,
			waveformLeftMax,
			waveformRightMin,
			waveformRightMax])
		{
			thing.checked = true;
			thing.callback = function() {
				updateWaveform();
			};
			thing.scrollFactor.set();
			add(thing);
		}
		//#end
	}

	var maxBpm = 1000;
	var minBpm = 50;
	var maxScrollSpeed = 15;
	var minScrollSpeed = 0.1;

	var check_mute_inst:FlxUICheckBox = null;
	var check_vortex:FlxUICheckBox = null;
	var check_warnings:FlxUICheckBox = null;
	var playSoundBf:FlxUICheckBox = null;
	var playSoundDad:FlxUICheckBox = null;
	var UI_songTitle:FlxUIInputText;
	var creditInputText:FlxUIInputText;
	var screwYouInputText:FlxUIInputText;
	var noteSkinInputText:FlxUIInputText;
	var notePlayerSkinInputText:FlxUIInputText;
	var noteSplashesInputText:FlxUIInputText;
	var stageDropDown:FlxUIDropDownMenuCustom;
	var sliderRate:FlxUISlider;
	function addSongUI():Void
	{
		UI_songTitle = new FlxUIInputText(10, 10, 70, _song.song, 8);
		blockPressWhileTypingOn.push(UI_songTitle);

		var check_voices = new FlxUICheckBox(10, 25, null, null, Language.getString({s: "Has voice track", spanish: "Tiene sonido (Voces)"}), 100);
		check_voices.checked = _song.needsVoices;
		// _song.needsVoices = check_voices.checked;
		check_voices.callback = function()
		{
			_song.needsVoices = check_voices.checked;
			//trace('CHECKED!');
		};

		//if(_song.ghostTappingAllowed == null) _song.ghostTappingAllowed = true;

		var ghostTappingAllowed = new FlxUICheckBox(check_voices.x, 45, null, null, Language.getString({s: "Ghost Tap", spanish: "Activar Spameo:"}), 100);
		ghostTappingAllowed.checked = _song.ghostTappingAllowed;
		ghostTappingAllowed.callback = function()
		{
			_song.ghostTappingAllowed = ghostTappingAllowed.checked;
			addTextToDebug("ghost tapping: " + ghostTappingAllowed.checked);
		};

		var saveButton:FlxButton = new FlxButton(110, 8, Language.getString({s: "Save", spanish: "Guardar"}), function()
		{
			saveLevel();
		});

		var reloadSong:FlxButton = new FlxButton(saveButton.x + 90, saveButton.y, Language.getString({s: "Reload Audio", spanish: "Recargar Audio"}), function()
		{
			currentSongName = Paths.formatToSongPath(UI_songTitle.text);
			loadSong();
			updateWaveform();
		});

		var reloadSongJson:FlxButton = new FlxButton(reloadSong.x, saveButton.y + 30, Language.getString({s: "Reload JSON", spanish: "Recargar JSON"}), function()
		{
			openSubState(new Prompt(Language.getString({s: 'This action will clear current progress.\n\nProceed?', spanish: 'Esta acción borrará el progreso actual.\n\n¿Proceder?'}), 0, function() {
				loadJson(_song.song.toLowerCase());
			}, null, ignoreWarnings));
		});

		var loadAutosaveBtn:FlxButton = new FlxButton(reloadSongJson.x, reloadSongJson.y + 30, Language.getString({s: 'Load Autosave', spanish: "Cargar Autoguardado"}), function()
		{
			openSubState(new Prompt(Language.getString({s: 'This action will add the last saved changes to\nthe current progress.\n\nProceed?', spanish: 'Esta acción añadirá los últimos cambios guardados\nal progreso actual.\n\n¿Proceder?'}), 0, function() {
				PlayState.SONG = Song.parseJSONshit(FlxG.save.data.autosave);
				MusicBeatState.resetState();
			}, null, ignoreWarnings));
		});

		var loadEventJson:FlxButton = new FlxButton(loadAutosaveBtn.x, loadAutosaveBtn.y + 30, Language.getString({s: 'Load Events', spanish: 'Cargar Eventos'}), function()
		{
			loadEvents();
		});

		var saveEvents:FlxButton = new FlxButton(110, reloadSongJson.y, Language.getString({s: 'Save Events', spanish: 'Guardar Eventos'}), function ()
		{
			saveEvents();
		});

		var clear_events:FlxButton = new FlxButton(320, 310, Language.getString({s: 'Clear events', spanish: 'Eliminar Eventos'}), function()
		{
			openSubState(new Prompt(Language.getString({s: "This action will clear current progress's events.\n\nProceed?", spanish: 'Esta acción quitará todos los eventos actuales.\n\n¿Proceder?'}), 0, clearEvents, null, ignoreWarnings));
		});
		clear_events.color = FlxColor.RED;
		clear_events.label.color = FlxColor.WHITE;

		var clear_notes:FlxButton = new FlxButton(320, clear_events.y + 30, Language.getString({s: 'Clear notes', spanish: 'ELIMINAR notas'}), function()
		{
			openSubState(new Prompt(Language.getString({s: 'This action will clear current progress.\n\nProceed?', spanish: 'Esta acción quitará TODO el progreso actual.\n\n¿Proceder?'}), 0, function()
			{
				for (sec in 0..._song.notes.length) {
					_song.notes[sec].sectionNotes = [];
				}
				updateGrid();
			}, null, ignoreWarnings));
		});
		clear_notes.color = FlxColor.RED;
		clear_notes.label.color = FlxColor.WHITE;


		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 80, 1, 1, 1, maxBpm, 1);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';
		blockPressWhileTypingOnStepper.push(stepperBPM);


		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, stepperBPM.y + 35, 0.1, 1, 0.1, maxScrollSpeed, 1);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';
		blockPressWhileTypingOnStepper.push(stepperSpeed);

		#if MODS_ALLOWED
		var directories:Array<String> = [Paths.mods('characters/'), Paths.mods(Paths.currentModDirectory + '/characters/'), Paths.getPreloadPath('characters/')];
		for(mod in Paths.getGlobalMods())
 			directories.push(Paths.mods(mod + '/characters/'));
		#else
		var directories:Array<String> = [Paths.getPreloadPath('characters/')];
		#end

		var tempMap:Map<String, Bool> = new Map<String, Bool>();
		var characters:Array<String> = CoolUtil.coolTextFile(Paths.txt('characterList'));
		for (i in 0...characters.length) {
			tempMap.set(characters[i], true);
		}

		#if MODS_ALLOWED
		for (i in 0...directories.length) {
			var directory:String = directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.json')) {
						var charToCheck:String = file.substr(0, file.length - 5);
						if(!charToCheck.endsWith('-dead') && !tempMap.exists(charToCheck)) {
							tempMap.set(charToCheck, true);
							characters.push(charToCheck);
						}
					}
				}
			}
		}
		#end

		var player1DropDown = new FlxUIDropDownMenuCustom(10, stepperSpeed.y + 45, FlxUIDropDownMenuCustom.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player1 = characters[Std.parseInt(character)];
			updateHeads();
		});
		player1DropDown.selectedLabel = _song.player1;
		blockPressWhileScrolling.push(player1DropDown);

		var gfVersionDropDown = new FlxUIDropDownMenuCustom(player1DropDown.x, player1DropDown.y + 40, FlxUIDropDownMenuCustom.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.gfVersion = characters[Std.parseInt(character)];
			updateHeads();
		});
		gfVersionDropDown.selectedLabel = _song.gfVersion;
		blockPressWhileScrolling.push(gfVersionDropDown);

		var player2DropDown = new FlxUIDropDownMenuCustom(player1DropDown.x, gfVersionDropDown.y + 40, FlxUIDropDownMenuCustom.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player2 = characters[Std.parseInt(character)];
			updateHeads();
		});
		player2DropDown.selectedLabel = _song.player2;
		blockPressWhileScrolling.push(player2DropDown);

		#if MODS_ALLOWED
		var directories:Array<String> = [Paths.mods('stages/'), Paths.mods(Paths.currentModDirectory + '/stages/'), Paths.getPreloadPath('stages/')];
		for(mod in Paths.getGlobalMods())
 			directories.push(Paths.mods(mod + '/stages/'));
		#else
		var directories:Array<String> = [Paths.getPreloadPath('stages/')];
		#end

		tempMap.clear();
		var stageFile:Array<String> = CoolUtil.coolTextFile(Paths.txt('stageList'));
		var stages:Array<String> = [];
		for (i in 0...stageFile.length) { //Prevent duplicates
			var stageToCheck:String = stageFile[i];
			if(!tempMap.exists(stageToCheck)) {
				stages.push(stageToCheck);
			}
			tempMap.set(stageToCheck, true);
		}
		#if MODS_ALLOWED
		for (i in 0...directories.length) {
			var directory:String = directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.json')) {
						var stageToCheck:String = file.substr(0, file.length - 5);
						if(!tempMap.exists(stageToCheck)) {
							tempMap.set(stageToCheck, true);
							stages.push(stageToCheck);
						}
					}
				}
			}
		}
		#end

		if(stages.length < 1) stages.push('stage');

		stageDropDown = new FlxUIDropDownMenuCustom(player1DropDown.x + 140, player1DropDown.y, FlxUIDropDownMenuCustom.makeStrIdLabelArray(stages, true), function(character:String)
		{
			_song.stage = stages[Std.parseInt(character)];
		});
		stageDropDown.selectedLabel = _song.stage;
		blockPressWhileScrolling.push(stageDropDown);

		creditInputText = new FlxUIInputText(10, 300, 125, _song.credit, 8);
		blockPressWhileTypingOn.push(creditInputText);

		screwYouInputText = new FlxUIInputText(creditInputText.x + 140, creditInputText.y, 125, _song.screwYou, 8);
		blockPressWhileTypingOn.push(screwYouInputText);

		var tab_group_song = new FlxUI(null, UI_box);
		tab_group_song.name = "Song";
		tab_group_song.add(UI_songTitle);

		tab_group_song.add(check_voices);
		tab_group_song.add(ghostTappingAllowed);
		tab_group_song.add(clear_events);
		tab_group_song.add(clear_notes);
		tab_group_song.add(saveButton);
		tab_group_song.add(saveEvents);
		tab_group_song.add(reloadSong);
		tab_group_song.add(reloadSongJson);
		tab_group_song.add(loadAutosaveBtn);
		tab_group_song.add(loadEventJson);
		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperSpeed);
		tab_group_song.add(creditInputText);
		tab_group_song.add(screwYouInputText);
		tab_group_song.add(new FlxText(stepperBPM.x, stepperBPM.y - 15, 0, Language.getString({s: 'Song BPM:', spanish: 'BPM de canción:'})));
		tab_group_song.add(new FlxText(stepperBPM.x + 100, stepperBPM.y - 15, 0, Language.getString({s: 'Song Offset:', spanish: 'Offset:'})));
		tab_group_song.add(new FlxText(stepperSpeed.x, stepperSpeed.y - 15, 0, 'Song Speed:'));
		tab_group_song.add(new FlxText(player2DropDown.x, player2DropDown.y - 15, 0, 'Opponent:'));
		tab_group_song.add(new FlxText(gfVersionDropDown.x, gfVersionDropDown.y - 15, 0, 'Girlfriend:'));
		tab_group_song.add(new FlxText(player1DropDown.x, player1DropDown.y - 15, 0, 'Boyfriend:'));
		tab_group_song.add(new FlxText(stageDropDown.x, stageDropDown.y - 15, 0, 'Stage:'));
		tab_group_song.add(new FlxText(creditInputText.x, creditInputText.y - 15, 0, 'Song Credit:'));
		tab_group_song.add(new FlxText(screwYouInputText.x, screwYouInputText.y - 15, 0, 'Screw You Text:'));
		tab_group_song.add(player2DropDown);
		tab_group_song.add(gfVersionDropDown);
		tab_group_song.add(player1DropDown);
		tab_group_song.add(stageDropDown);

		UI_box.addGroup(tab_group_song);

		FlxG.camera.follow(camPos);
	}

	var stepperBeats:FlxUINumericStepper;
	var check_mustHitSection:FlxUICheckBox;
	var check_gfSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var check_altAnim:FlxUICheckBox;

	var sectionToCopy:Int = 0;
	var notesCopied:Array<Dynamic>;

	function addSectionUI():Void
	{
		var tab_group_section = new FlxUI(null, UI_box);
		tab_group_section.name = 'Section';

		check_mustHitSection = new FlxUICheckBox(10, 15, null, null, "Must hit section", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = _song.notes[curSec].mustHitSection;

		check_gfSection = new FlxUICheckBox(10, check_mustHitSection.y + 22, null, null, "GF section", 100);
		check_gfSection.name = 'check_gf';
		check_gfSection.checked = _song.notes[curSec].gfSection;
		// _song.needsVoices = check_mustHit.checked;

		check_altAnim = new FlxUICheckBox(check_gfSection.x + 120, check_gfSection.y, null, null, "Alt Animation", 100);
		check_altAnim.checked = _song.notes[curSec].altAnim;

		stepperBeats = new FlxUINumericStepper(10, 100, 1, 4, 1, 6, 2);
		stepperBeats.value = getSectionBeats();
		stepperBeats.name = 'section_beats';
		blockPressWhileTypingOnStepper.push(stepperBeats);
		check_altAnim.name = 'check_altAnim';

		check_changeBPM = new FlxUICheckBox(10, stepperBeats.y + 30, null, null, 'Change BPM', 100);
		check_changeBPM.checked = _song.notes[curSec].changeBPM;
		check_changeBPM.name = 'check_changeBPM';

		stepperSectionBPM = new FlxUINumericStepper(10, check_changeBPM.y + 20, 1, Conductor.bpm, 0, 999, 1);
		if(check_changeBPM.checked) {
			stepperSectionBPM.value = _song.notes[curSec].bpm;
		} else {
			stepperSectionBPM.value = Conductor.bpm;
		}
		stepperSectionBPM.name = 'section_bpm';
		blockPressWhileTypingOnStepper.push(stepperSectionBPM);


		var check_eventsSec:FlxUICheckBox = null;
		var check_notesSec:FlxUICheckBox = null;
		var copyButton:FlxButton = new FlxButton(10, 190, "Copy Section", function()
		{
			notesCopied = [];
			sectionToCopy = curSec;
			for (i in 0..._song.notes[curSec].sectionNotes.length)
			{
				var note:Array<Dynamic> = _song.notes[curSec].sectionNotes[i];
				notesCopied.push(note);
			}

			var startThing:Float = sectionStartTime();
			var endThing:Float = sectionStartTime(1);
			for (event in _song.events)
			{
				var strumTime:Float = event[0];
				if(endThing > event[0] && event[0] >= startThing)
				{
					var copiedEventArray:Array<Dynamic> = [];
					for (i in 0...event[1].length)
					{
						var eventToPush:Array<Dynamic> = event[1][i];
						copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2], eventToPush[3]]);
					}
					notesCopied.push([strumTime, -1, copiedEventArray]);
				}
			}
		});

		var pasteButton:FlxButton = new FlxButton(copyButton.x + 100, copyButton.y, "Paste Section", function()
		{
			if(notesCopied == null || notesCopied.length < 1)
			{
				return;
			}

			var addToTime:Float = Conductor.stepCrochet * (getSectionBeats() * 4 * (curSec - sectionToCopy));
			//trace('Time to add: ' + addToTime);

			for (note in notesCopied)
			{
				var copiedNote:Array<Dynamic> = [];
				var newStrumTime:Float = note[0] + addToTime;
				if(note[1] < 0)
				{
					if(check_eventsSec.checked)
					{
						var copiedEventArray:Array<Dynamic> = [];
						for (i in 0...note[2].length)
						{
							var eventToPush:Array<Dynamic> = note[2][i];
							copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2], eventToPush[3]]);
						}
						_song.events.push([newStrumTime, copiedEventArray]);
					}
				}
				else
				{
					if(check_notesSec.checked)
					{
						if(note[4] != null) {
							copiedNote = [newStrumTime, note[1], note[2], note[3], note[4]];
						} else {
							copiedNote = [newStrumTime, note[1], note[2], note[3]];
						}
						_song.notes[curSec].sectionNotes.push(copiedNote);
					}
				}
			}
			updateGrid();
		});

		var clearSectionButton:FlxButton = new FlxButton(pasteButton.x + 100, pasteButton.y, "Clear", function()
		{
			if(check_notesSec.checked)
			{
				_song.notes[curSec].sectionNotes = [];
			}

			if(check_eventsSec.checked)
			{
				var i:Int = _song.events.length - 1;
				var startThing:Float = sectionStartTime();
				var endThing:Float = sectionStartTime(1);
				while(i > -1) {
					var event:Array<Dynamic> = _song.events[i];
					if(event != null && endThing > event[0] && event[0] >= startThing)
					{
						_song.events.remove(event);
					}
					--i;
				}
			}
			updateGrid();
			updateNoteUI();
		});
		clearSectionButton.color = FlxColor.RED;
		clearSectionButton.label.color = FlxColor.WHITE;


		check_notesSec = new FlxUICheckBox(10, clearSectionButton.y + 25, null, null, "Notes", 100);
		check_notesSec.checked = true;
		check_eventsSec = new FlxUICheckBox(check_notesSec.x + 100, check_notesSec.y, null, null, "Events", 100);
		check_eventsSec.checked = true;

		var swapSection:FlxButton = new FlxButton(10, check_notesSec.y + 40, "Swap section", function()
		{
			for (i in 0..._song.notes[curSec].sectionNotes.length)
			{
				var note:Array<Dynamic> = _song.notes[curSec].sectionNotes[i];
				note[1] = (note[1] + 4) % 8;
				_song.notes[curSec].sectionNotes[i] = note;
			}
			updateGrid();
		});

		var stepperCopy:FlxUINumericStepper = null;
		var copyLastButton:FlxButton = new FlxButton(10, swapSection.y + 30, "Copy last section", function()
		{
			var value:Int = Std.int(stepperCopy.value);
			if(value == 0) return;

			var daSec = FlxMath.maxInt(curSec, value);

			if(check_notesSec.checked) {
				for (note in _song.notes[daSec - value].sectionNotes)
				{
					var strum = note[0] + Conductor.stepCrochet * (getSectionBeats(daSec) * 4 * value);


					var copiedNote:Array<Dynamic> = [strum, note[1], note[2], note[3]];
					_song.notes[daSec].sectionNotes.push(copiedNote);
				}
			}

			var startThing:Float = sectionStartTime(-value);
			var endThing:Float = sectionStartTime(-value + 1);
			if(check_eventsSec.checked) {
				for (event in _song.events)
				{
					var strumTime:Float = event[0];
					if(endThing > event[0] && event[0] >= startThing)
					{
						strumTime += Conductor.stepCrochet * (getSectionBeats(daSec) * 4 * value);
						var copiedEventArray:Array<Dynamic> = [];
						for (i in 0...event[1].length)
						{
							var eventToPush:Array<Dynamic> = event[1][i];
							copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
						}
						_song.events.push([strumTime, copiedEventArray]);
					}
				}
			}
			updateGrid();
		});
		copyLastButton.setGraphicSize(80, 30);
		copyLastButton.updateHitbox();

		stepperCopy = new FlxUINumericStepper(copyLastButton.x + 100, copyLastButton.y, 1, 1, -999, 999, 0);
		blockPressWhileTypingOnStepper.push(stepperCopy);

		var duetButton:FlxButton = new FlxButton(10, copyLastButton.y + 45, "Duet Notes", function()
		{
			var duetNotes:Array<Array<Dynamic>> = [];
			for (note in _song.notes[curSec].sectionNotes)
			{
				var boob = note[1];
				if (boob > 3) {
					boob -= 4;
				} else {
					boob += 4;
				}

				var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
				duetNotes.push(copiedNote);
			}

			for (duetNote in duetNotes) {
				_song.notes[curSec].sectionNotes.push(duetNote);

			}

			updateGrid();
		});
		var mirrorButton:FlxButton = new FlxButton(duetButton.x + 100, duetButton.y, "Mirror Notes", function()
		{
			var duetNotes:Array<Array<Dynamic>> = [];
			for (note in _song.notes[curSec].sectionNotes)
			{
				var boob = note[1] % 4;
				boob = 3 - boob;
				if (note[1] > 3) boob += 4;

				note[1] = boob;
				var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
				//duetNotes.push(copiedNote);
			}

			for (duetNote in duetNotes) {
				//_song.notes[curSec].sectionNotes.push(duetNote);
	
			}

			updateGrid();
		});

		tab_group_section.add(new FlxText(stepperBeats.x, stepperBeats.y - 15, 0, 'Beats per Section:'));
		tab_group_section.add(stepperBeats);
		tab_group_section.add(stepperSectionBPM);
		tab_group_section.add(check_mustHitSection);
		tab_group_section.add(check_gfSection);
		tab_group_section.add(check_altAnim);
		tab_group_section.add(check_changeBPM);
		tab_group_section.add(copyButton);
		tab_group_section.add(pasteButton);
		tab_group_section.add(clearSectionButton);
		tab_group_section.add(check_notesSec);
		tab_group_section.add(check_eventsSec);
		tab_group_section.add(swapSection);
		tab_group_section.add(stepperCopy);
		tab_group_section.add(copyLastButton);
		tab_group_section.add(duetButton);
		tab_group_section.add(mirrorButton);

		UI_box.addGroup(tab_group_section);
	}

	var stepperSusLength:FlxUINumericStepper;
	var strumTimeInputText:FlxUIInputText; //I wanted to use a stepper but we can't scale these as far as i know :(
	var noteTypeDropDown:FlxUIDropDownMenuCustom;
	var currentType:Int = 0;
	var stepperSpamCloseness:FlxUINumericStepper;
	var stepperSpamLength:FlxUINumericStepper;
	var spamLength:Float = 5;
	var spamCloseness:Float = 2;

	function addNoteUI():Void
	{
		var tab_group_note = new FlxUI(null, UI_box);
		tab_group_note.name = 'Note';

		var skin = PlayState.SONG.arrowSkin;
		if(skin == null) skin = '';
		var skinP = PlayState.SONG.playerArrowSkin;
		if(skinP == null) skinP = '';
		noteSkinInputText = new FlxUIInputText(10, 250, 150, skin, 8);
		blockPressWhileTypingOn.push(noteSkinInputText);

		notePlayerSkinInputText = new FlxUIInputText(10, noteSkinInputText.y + 35, 150, skinP, 8);
		blockPressWhileTypingOn.push(notePlayerSkinInputText);

		noteSplashesInputText = new FlxUIInputText(10, noteSkinInputText.y + 75, 150, _song.splashSkin, 8);
		blockPressWhileTypingOn.push(noteSplashesInputText);

		var reloadNotesButton:FlxButton = new FlxButton(10 + 5, noteSplashesInputText.y + 20, 'Reload Skin', function() {
			if(noteSkinInputText.text.endsWith('.png'))
				noteSkinInputText.text.replace('.png', '');

			_song.arrowSkin = noteSkinInputText.text;
			if(notePlayerSkinInputText.text.endsWith('.png'))
				notePlayerSkinInputText.text.replace('.png', '');

			_song.playerArrowSkin = notePlayerSkinInputText.text;
			updateGrid();
		});

		stepperSusLength = new FlxUINumericStepper(10, 25, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 64);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';
		blockPressWhileTypingOnStepper.push(stepperSusLength);

		strumTimeInputText = new FlxUIInputText(10, 65, 180, "0");
		tab_group_note.add(strumTimeInputText);
		blockPressWhileTypingOn.push(strumTimeInputText);

		var key:Int = 0;
		var displayNameList:Array<String> = [];
		while (key < noteTypeList.length) {
			displayNameList.push(noteTypeList[key]);
			noteTypeMap.set(noteTypeList[key], key);
			noteTypeIntMap.set(key, noteTypeList[key]);
			key++;
		}

		#if LUA_ALLOWED
		var directories:Array<String> = [];
		#if MODS_ALLOWED
		directories.push(Paths.mods('custom_notetypes/'));
		directories.push(Paths.mods(Paths.currentModDirectory + '/custom_notetypes/'));
		for(mod in Paths.getGlobalMods())
 			directories.push(Paths.mods(mod + '/custom_notetypes/'));
		#end
		for (i in 0...directories.length) {
			var directory:String =  directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.lua')) {
						var fileToCheck:String = file.substr(0, file.length - 4);
						if(!noteTypeMap.exists(fileToCheck)) {
							displayNameList.push(fileToCheck);
							noteTypeMap.set(fileToCheck, key);
							noteTypeIntMap.set(key, fileToCheck);
							key++;
						}
					}
				}
			}
		}
		#end

		for (i in 1...displayNameList.length) {
			displayNameList[i] = i + '. ' + displayNameList[i];
		}

		noteTypeDropDown = new FlxUIDropDownMenuCustom(10, 105, FlxUIDropDownMenuCustom.makeStrIdLabelArray(displayNameList, true), function(character:String)
		{
			currentType = Std.parseInt(character);
			if(curSelectedNote != null && curSelectedNote[1] > -1) {
				curSelectedNote[3] = noteTypeIntMap.get(currentType);
				updateGrid();
			}
		});
		blockPressWhileScrolling.push(noteTypeDropDown);

		var spamButton:FlxButton = new FlxButton(noteTypeDropDown.x, noteTypeDropDown.y + 40, "Add Notes", function()
		{
			if (curSelectedNote != null) {
				for(i in 0...Std.int(spamLength)) {
					addNote(curSelectedNote[0] + (15000/_song.bpm)/spamCloseness, curSelectedNote[1], curSelectedNote[2], false);
				}
				updateGrid();
				updateNoteUI();
			}
		});
		
		stepperSpamCloseness = new FlxUINumericStepper(spamButton.x + 90, spamButton.y + 5, 2, 2, 2, 64);
		stepperSpamCloseness.value = spamCloseness;
		stepperSpamCloseness.name = 'note_spamthing';
		blockPressWhileTypingOnStepper.push(stepperSpamCloseness);

		stepperSpamLength = new FlxUINumericStepper(stepperSpamCloseness.x + 90, stepperSpamCloseness.y, 5, 5, 1, 8192);
		stepperSpamLength.value = spamLength;
		stepperSpamLength.name = 'note_spamamount';
		blockPressWhileTypingOnStepper.push(stepperSpamLength);

		tab_group_note.add(new FlxText(10, 10, 0, 'Sustain length:'));
		tab_group_note.add(new FlxText(stepperSpamCloseness.x, stepperSpamCloseness.y - 15, 0, 'Note Density:'));
		tab_group_note.add(new FlxText(10, 50, 0, 'Strum time (in miliseconds):'));
		tab_group_note.add(new FlxText(10, 90, 0, 'Note type:'));
		tab_group_note.add(new FlxText(noteSkinInputText.x, noteSkinInputText.y - 15, 0, 'Opponent Note Texture:'));
		tab_group_note.add(new FlxText(noteSplashesInputText.x, noteSplashesInputText.y - 15, 0, 'Note Splashes Texture:'));
		tab_group_note.add(new FlxText(notePlayerSkinInputText.x, notePlayerSkinInputText.y - 15, 0, 'Player Note Texture:'));
		tab_group_note.add(spamButton);
		tab_group_note.add(stepperSpamCloseness);
		tab_group_note.add(stepperSpamLength);
		tab_group_note.add(stepperSusLength);
		tab_group_note.add(noteSkinInputText);
		tab_group_note.add(notePlayerSkinInputText);
		tab_group_note.add(noteSplashesInputText);
		tab_group_note.add(reloadNotesButton);
		tab_group_note.add(stepperSusLength);
		tab_group_note.add(strumTimeInputText);
		tab_group_note.add(noteTypeDropDown);

		UI_box.addGroup(tab_group_note);
	}

	var eventDropDown:FlxUIDropDownMenuCustom;
	var event7DropDown:FlxUIDropDownMenuCustom;
	var event7InputText:FlxUIInputText;
	var descText:FlxText;
	var selectedEventText:FlxText;
	var untilTheEnd:FlxText;
	function addEventsUI():Void
	{
		var tab_group_event = new FlxUI(null, UI_box);
		tab_group_event.name = 'Events';

		if(_song.event7 == null || !pressing7Events.contains(_song.event7)) // fix crash
			_song.event7 = pressing7Events[0];

		event7DropDown = new FlxUIDropDownMenuCustom(160, 300, FlxUIDropDownMenuCustom.makeStrIdLabelArray(pressing7Events, true), function(pressed:String) {
			var arraySelectedShit:String = pressing7Events[Std.parseInt(pressed)];
			_song.event7 = arraySelectedShit;
			if(untilTheEnd != null)
				untilTheEnd.visible = _song.event7 == 'Rainbow Eyesore';
		});
		event7DropDown.selectedLabel = _song.event7;
		event7DropDown.active = true;
		blockPressWhileScrolling.push(event7DropDown); // maybe?
		var event7Text:FlxText = new FlxText(160, 280, 0, "7 Event:");
		tab_group_event.add(event7Text);
		var text:FlxText = new FlxText(300, 200, 0, "NOTE: YOU HAVE TO\nENTER THE DEBUG\nMENU AGAIN TO\nSEE PRESETS RELOAD");
		tab_group_event.add(text);
		untilTheEnd = new FlxText(event7Text.x, event7Text.y - 50, event7Text.fieldWidth + 50, "UNTIL THE SONG ENDS");
		untilTheEnd.color = FlxColor.RED;
		untilTheEnd.borderColor = 0x7C0000;
		untilTheEnd.borderSize = 3;
		untilTheEnd.visible = false;
		tab_group_event.add(untilTheEnd);
		if(_song.event7 == 'Rainbow Eyesore')
			untilTheEnd.visible = true;

		event7InputText = new FlxUIInputText(160, event7DropDown.y + 40, 100, _song.event7Value);
		blockPressWhileTypingOn.push(event7InputText);
		tab_group_event.add(event7InputText);

		#if LUA_ALLOWED
		var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
		var directories:Array<String> = [];

		#if MODS_ALLOWED
		directories.push(Paths.mods('custom_events/'));
		directories.push(Paths.mods(Paths.currentModDirectory + '/custom_events/'));
		for(mod in Paths.getGlobalMods())
 			directories.push(Paths.mods(mod + '/custom_events/'));
		#end
		for (i in 0...directories.length) {
			var directory:String =  directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file != 'readme.txt' && file.endsWith('.txt')) {
						var fileToCheck:String = file.substr(0, file.length - 4);
						if(!eventPushedMap.exists(fileToCheck)) {
							eventPushedMap.set(fileToCheck, true);
							eventStuff.push([fileToCheck, File.getContent(path)]);
						}
					}
				}
			}
		}
		eventPushedMap.clear();
		eventPushedMap = null;
		#end

		descText = new FlxText(20, 200, 0, eventStuff[0][0]);

		var leEvents:Array<String> = [];
		for (i in 0...eventStuff.length) {
			leEvents.push(eventStuff[i][0]);
		}

		var text:FlxText = new FlxText(20, 30, 0, "Event:");
		tab_group_event.add(text);
		eventDropDown = new FlxUIDropDownMenuCustom(20, 50, FlxUIDropDownMenuCustom.makeStrIdLabelArray(leEvents, true), function(pressed:String) {
			var selectedEvent:Int = Std.parseInt(pressed);
			descText.text = eventStuff[selectedEvent][1];
			descText.applyMarkup(eventStuff[selectedEvent][1], [
				new FlxTextFormatMarkerPair(boldFormat, '<b>'),
				new FlxTextFormatMarkerPair(italicFormat, '<i>'),
				new FlxTextFormatMarkerPair(strongFormat, '<strong>'),
				new FlxTextFormatMarkerPair(redFormat, '<r>'),
				new FlxTextFormatMarkerPair(blackFormat, '<bl>')
			]);
			if (curSelectedNote != null && eventStuff != null) {
				if (curSelectedNote != null && curSelectedNote[2] == null) {
					curSelectedNote[1][curEventSelected][0] = eventStuff[selectedEvent][0];
				}
				updateGrid();
			}
		});
		blockPressWhileScrolling.push(eventDropDown);

		var text:FlxText = new FlxText(20, 90, 0, "Value 1:");
		tab_group_event.add(text);
		value1InputText = new FlxUIInputText(20, 110, 100, "");
		blockPressWhileTypingOn.push(value1InputText);

		var text:FlxText = new FlxText(20, 130, 0, "Value 2:");
		tab_group_event.add(text);
		value2InputText = new FlxUIInputText(20, 150, 100, "");
		blockPressWhileTypingOn.push(value2InputText);

		/*var text:FlxText = new FlxText(20, 170, 0, "Value 3:"); // no 3 event :'(
		tab_group_event.add(text);*/

		// New event buttons
		var removeButton:FlxButton = new FlxButton(eventDropDown.x + eventDropDown.width + 10, eventDropDown.y, '-', function()
		{
			if(curSelectedNote != null && curSelectedNote[2] == null) //Is event note
			{
				if(curSelectedNote[1].length < 2)
				{
					_song.events.remove(curSelectedNote);
					curSelectedNote = null;
				}
				else
				{
					curSelectedNote[1].remove(curSelectedNote[1][curEventSelected]);
				}

				var eventsGroup:Array<Dynamic>;
				--curEventSelected;
				if(curEventSelected < 0) curEventSelected = 0;
				else if(curSelectedNote != null && curEventSelected >= (eventsGroup = curSelectedNote[1]).length) curEventSelected = eventsGroup.length - 1;

				changeEventSelected();
				updateGrid();
			}
		});
		removeButton.setGraphicSize(Std.int(removeButton.height), Std.int(removeButton.height));
		removeButton.updateHitbox();
		removeButton.color = FlxColor.RED;
		removeButton.label.color = FlxColor.WHITE;
		removeButton.label.size = 12;
		setAllLabelsOffset(removeButton, -30, 0);
		tab_group_event.add(removeButton);

		var addButton:FlxButton = new FlxButton(removeButton.x + removeButton.width + 10, removeButton.y, '+', function()
		{
			if(curSelectedNote != null && curSelectedNote[2] == null) //Is event note
			{
				var eventsGroup:Array<Dynamic> = curSelectedNote[1];
				eventsGroup.push(['', '', '', '']);

				changeEventSelected(1);
				updateGrid();
			}
		});
		addButton.setGraphicSize(Std.int(removeButton.width), Std.int(removeButton.height));
		addButton.updateHitbox();
		addButton.color = FlxColor.GREEN;
		addButton.label.color = FlxColor.WHITE;
		addButton.label.size = 12;
		setAllLabelsOffset(addButton, -30, 0);
		tab_group_event.add(addButton);

		var moveLeftButton:FlxButton = new FlxButton(addButton.x + addButton.width + 20, addButton.y, '<', function()
		{
			changeEventSelected(-1);
		});
		moveLeftButton.setGraphicSize(Std.int(addButton.width), Std.int(addButton.height));
		moveLeftButton.updateHitbox();
		moveLeftButton.label.size = 12;
		setAllLabelsOffset(moveLeftButton, -30, 0);
		tab_group_event.add(moveLeftButton);

		var moveRightButton:FlxButton = new FlxButton(moveLeftButton.x + moveLeftButton.width + 10, moveLeftButton.y, '>', function()
		{
			changeEventSelected(1);
		});
		moveRightButton.setGraphicSize(Std.int(moveLeftButton.width), Std.int(moveLeftButton.height));
		moveRightButton.updateHitbox();
		moveRightButton.label.size = 12;
		setAllLabelsOffset(moveRightButton, -30, 0);
		tab_group_event.add(moveRightButton);

		selectedEventText = new FlxText(addButton.x - 100, addButton.y + addButton.height + 6, (moveRightButton.x - addButton.x) + 186, 'Selected Event: None');
		selectedEventText.alignment = CENTER;
		tab_group_event.add(selectedEventText);

		tab_group_event.add(descText);
		tab_group_event.add(value1InputText);
		tab_group_event.add(value2InputText);
		tab_group_event.add(eventDropDown);
		tab_group_event.add(event7DropDown);

		UI_box.addGroup(tab_group_event);
	}

	function changeEventSelected(change:Int = 0)
	{
		if(curSelectedNote != null && curSelectedNote[2] == null) //Is event note
		{
			curEventSelected += change;
			if(curEventSelected < 0) curEventSelected = Std.int(curSelectedNote[1].length) - 1;
			else if(curEventSelected >= curSelectedNote[1].length) curEventSelected = 0;
			selectedEventText.text = 'Selected Event: ' + (curEventSelected + 1) + ' / ' + curSelectedNote[1].length;
		}
		else
		{
			curEventSelected = 0;
			selectedEventText.text = 'Selected Event: None';
		}
		updateNoteUI();
	}

	function setAllLabelsOffset(button:FlxButton, x:Float, y:Float)
	{
		for (point in button.labelOffsets)
		{
			point.set(x, y);
		}
	}

	var mouseScrollingQuant:FlxUICheckBox;
	var metronome:FlxUICheckBox;
	var metronomeStepper:FlxUINumericStepper;
	var metronomeOffsetStepper:FlxUINumericStepper;
	var disableAutoScrolling:FlxUICheckBox;
	#if desktop
	var waveformUseInstrumental:FlxUICheckBox;
	var waveformUseVoices:FlxUICheckBox;
	#end
	var instVolume:FlxUINumericStepper;
	var voicesVolume:FlxUINumericStepper;
	function addChartingUI() {
		var tab_group_chart = new FlxUI(null, UI_box);
		tab_group_chart.name = 'Charting';

		#if desktop
		if (FlxG.save.data.chart_waveformInst == null) FlxG.save.data.chart_waveformInst = false;
		if (FlxG.save.data.chart_waveformVoices == null) FlxG.save.data.chart_waveformVoices = false;

		waveformUseInstrumental = new FlxUICheckBox(10, 90, null, null, "Waveform for Instrumental", 100);
		waveformUseInstrumental.checked = FlxG.save.data.chart_waveformInst;
		waveformUseInstrumental.callback = function()
		{
			waveformUseVoices.checked = false;
			FlxG.save.data.chart_waveformVoices = false;
			FlxG.save.data.chart_waveformInst = waveformUseInstrumental.checked;
			updateWaveform();
		};

		waveformUseVoices = new FlxUICheckBox(waveformUseInstrumental.x + 120, waveformUseInstrumental.y, null, null, "Waveform for Voices", 100);
		waveformUseVoices.checked = FlxG.save.data.chart_waveformVoices;
		waveformUseVoices.callback = function()
		{
			waveformUseInstrumental.checked = false;
			FlxG.save.data.chart_waveformInst = false;
			FlxG.save.data.chart_waveformVoices = waveformUseVoices.checked;
			updateWaveform();
		};
		#end

		check_mute_inst = new FlxUICheckBox(10, 310, null, null, "Mute Instrumental (in editor)", 100);
		check_mute_inst.checked = false;
		check_mute_inst.callback = function()
		{
			var vol:Float = instVolume.value;

			if (check_mute_inst.checked)
				vol = 0;

			FlxG.sound.music.volume = vol;
		};

		mouseScrollingQuant = new FlxUICheckBox(10, 200, null, null, "Mouse Scrolling Quantization", 100);
		if(FlxG.save.data.mouseScrollingQuant == null) FlxG.save.data.mouseScrollingQuant = false;
		mouseScrollingQuant.checked = FlxG.save.data.mouseScrollingQuant;

		mouseScrollingQuant.callback = function()
		{
			FlxG.save.data.mouseScrollingQuant = mouseScrollingQuant.checked;
			mouseQuant = FlxG.save.data.mouseScrollingQuant;
		};

		check_vortex = new FlxUICheckBox(10, 160, null, null, "Vortex Editor (BETA)", 100);
		if (FlxG.save.data.chart_vortex == null) FlxG.save.data.chart_vortex = false;
		check_vortex.checked = FlxG.save.data.chart_vortex;

		check_vortex.callback = function()
		{
			FlxG.save.data.chart_vortex = check_vortex.checked;
			vortex = FlxG.save.data.chart_vortex;
			reloadGridLayer();
		};

		check_warnings = new FlxUICheckBox(10, 120, null, null, "Ignore Progress Warnings", 100);
		if (FlxG.save.data.ignoreWarnings == null) FlxG.save.data.ignoreWarnings = false;
		check_warnings.checked = FlxG.save.data.ignoreWarnings;

		check_warnings.callback = function()
		{
			FlxG.save.data.ignoreWarnings = check_warnings.checked;
			ignoreWarnings = FlxG.save.data.ignoreWarnings;
		};

		var check_mute_vocals = new FlxUICheckBox(check_mute_inst.x + 120, check_mute_inst.y, null, null, "Mute Vocals (in editor)", 100);
		check_mute_vocals.checked = false;
		check_mute_vocals.callback = function()
		{
			if(vocals != null) {
				var vol:Float = voicesVolume.value;

				if (check_mute_vocals.checked)
					vol = 0;

				vocals.volume = vol;
			}
		};

		playSoundBf = new FlxUICheckBox(check_mute_inst.x, check_mute_vocals.y + 30, null, null, 'Play Sound (Boyfriend notes)', 100,
			function() {
				FlxG.save.data.chart_playSoundBf = playSoundBf.checked;
			}
		);
		if (FlxG.save.data.chart_playSoundBf == null) FlxG.save.data.chart_playSoundBf = false;
		playSoundBf.checked = FlxG.save.data.chart_playSoundBf;

		playSoundDad = new FlxUICheckBox(check_mute_inst.x + 120, playSoundBf.y, null, null, 'Play Sound (Opponent notes)', 100,
			function() {
				FlxG.save.data.chart_playSoundDad = playSoundDad.checked;
			}
		);
		if (FlxG.save.data.chart_playSoundDad == null) FlxG.save.data.chart_playSoundDad = false;
		playSoundDad.checked = FlxG.save.data.chart_playSoundDad;

		metronome = new FlxUICheckBox(10, 15, null, null, "Metronome Enabled", 100, function() {
			FlxG.save.data.chart_metronome = metronome.checked;
		});
		if (FlxG.save.data.chart_metronome == null) FlxG.save.data.chart_metronome = false;
		metronome.checked = FlxG.save.data.chart_metronome;

		metronomeStepper = new FlxUINumericStepper(15, 55, 5, _song.bpm, 1, 1500, 1);
		metronomeOffsetStepper = new FlxUINumericStepper(metronomeStepper.x + 100, metronomeStepper.y, 25, 0, 0, 1000, 1);
		blockPressWhileTypingOnStepper.push(metronomeStepper);
		blockPressWhileTypingOnStepper.push(metronomeOffsetStepper);

		disableAutoScrolling = new FlxUICheckBox(metronome.x + 120, metronome.y, null, null, "Disable Autoscroll (Not Recommended)", 120,
			function() {
				FlxG.save.data.chart_noAutoScroll = disableAutoScrolling.checked;
			}
		);
		if (FlxG.save.data.chart_noAutoScroll == null) FlxG.save.data.chart_noAutoScroll = false;
		disableAutoScrolling.checked = FlxG.save.data.chart_noAutoScroll;

		instVolume = new FlxUINumericStepper(metronomeStepper.x, 270, 0.1, 1, 0, 1, 1);
		instVolume.value = FlxG.sound.music.volume;
		instVolume.name = 'inst_volume';
		blockPressWhileTypingOnStepper.push(instVolume);

		voicesVolume = new FlxUINumericStepper(instVolume.x + 100, instVolume.y, 0.1, 1, 0, 1, 1);
		voicesVolume.value = vocals.volume;
		voicesVolume.name = 'voices_volume';
		blockPressWhileTypingOnStepper.push(voicesVolume);

		sliderRate = new FlxUISlider(this, 'playbackSpeed', 120, 120, 0.5, 3, 150, null, 5, FlxColor.WHITE, FlxColor.BLACK);
		sliderRate.nameLabel.text = 'Playback Rate';
		tab_group_chart.add(sliderRate); // some BeastlyGhost here. Thanks Gabi!

		tab_group_chart.add(new FlxText(metronomeStepper.x, metronomeStepper.y - 15, 0, 'BPM:'));
		tab_group_chart.add(new FlxText(metronomeOffsetStepper.x, metronomeOffsetStepper.y - 15, 0, 'Offset (ms):'));
		tab_group_chart.add(new FlxText(instVolume.x, instVolume.y - 15, 0, 'Inst Volume'));
		tab_group_chart.add(new FlxText(voicesVolume.x, voicesVolume.y - 15, 0, 'Voices Volume'));
		tab_group_chart.add(metronome);
		tab_group_chart.add(disableAutoScrolling);
		tab_group_chart.add(metronomeStepper);
		tab_group_chart.add(metronomeOffsetStepper);
		#if desktop
		tab_group_chart.add(waveformUseVoices);
		tab_group_chart.add(waveformUseInstrumental);
		#end
		tab_group_chart.add(instVolume);
		tab_group_chart.add(voicesVolume);
		tab_group_chart.add(check_mute_inst);
		tab_group_chart.add(check_mute_vocals);
		tab_group_chart.add(check_vortex);
		tab_group_chart.add(check_warnings);
		tab_group_chart.add(mouseScrollingQuant);
		tab_group_chart.add(playSoundBf);
		tab_group_chart.add(playSoundDad);
		UI_box.addGroup(tab_group_chart);
	}

	function loadEvents():Void
	{
		var songName:String = Paths.formatToSongPath(_song.song);
		var file:String = Paths.json(songName + '/events');
		#if sys
		if (#if MODS_ALLOWED FileSystem.exists(Paths.modsJson(songName + '/events')) || #end FileSystem.exists(file))
		#else
		if (OpenFlAssets.exists(file))
		#end
		{
			clearEvents();
			var events:SwagSong = Song.loadFromJson('events', songName);
			_song.events = events.events;
			changeSection(curSec);
		}
	}

	function loadSong():Void
	{
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		var file:Dynamic = Paths.voices(currentSongName);
		vocals = new FlxSound();
		if (Std.isOfType(file, Sound) || OpenFlAssets.exists(file)) {
			vocals.loadEmbedded(file);
			FlxG.sound.list.add(vocals);
		}
		generateSong();
		FlxG.sound.music.pause();
		Conductor.songPosition = sectionStartTime();
		FlxG.sound.music.time = Conductor.songPosition;
	}

	function generateSong() {
		FlxG.sound.playMusic(Paths.inst(currentSongName), 0.6/*, false*/);
		if (instVolume != null) FlxG.sound.music.volume = instVolume.value;
		if (check_mute_inst != null && check_mute_inst.checked) FlxG.sound.music.volume = 0;

		FlxG.sound.music.onComplete = function()
		{
			FlxG.sound.music.pause();
			Conductor.songPosition = 0;
			if(vocals != null) {
				vocals.pause();
				vocals.time = 0;
			}
			changeSection();
			curSec = 0;
			updateGrid();
			updateSectionUI();
			vocals.play();
		};
	}

	function generateUI():Void
	{
		while (bullshitUI.members.length > 0)
		{
			bullshitUI.remove(bullshitUI.members[0], true);
		}

		// general shit
		var title:FlxText = new FlxText(UI_box.x + 20, UI_box.y + 20, 0);
		bullshitUI.add(title);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUICheckBox.CLICK_EVENT)
		{
			var check:FlxUICheckBox = cast sender;
			if (check != null) {
				if (!check.destroyed) {
					var label = check.getLabel().text;
					switch (label)
					{
						case 'Must hit section':
							_song.notes[curSec].mustHitSection = check.checked;

							updateGrid();
							updateHeads();

						case 'GF section':
							_song.notes[curSec].gfSection = check.checked;

							updateGrid();
							updateHeads();

						case 'Change BPM':
							_song.notes[curSec].changeBPM = check.checked;
							addTextToLog('changed bpm shit');
						case "Alt Animation":
							_song.notes[curSec].altAnim = check.checked;
					}
				}
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			addTextToLog(wname, FlxColor.BLUE);
			if (wname == 'section_beats')
			{
				_song.notes[curSec].sectionBeats = nums.value;
				reloadGridLayer();
			}
			if (wname == 'song_speed')
			{
				_song.speed = nums.value;
			}
			if (wname == 'song_bpm')
			{
				_song.bpm = nums.value;
				Conductor.mapBPMChanges(_song);
				Conductor.changeBPM(nums.value);
			}
			if (wname == 'note_susLength')
			{
				if(curSelectedNote != null && curSelectedNote[2] != null) {
					curSelectedNote[2] = nums.value;
					updateGrid();
				}
			}
			if (wname == 'section_bpm')
			{
				_song.notes[curSec].bpm = nums.value;
				updateGrid();
			}
			if (wname == 'inst_volume')
			{
				FlxG.sound.music.volume = nums.value;
			}
			if (wname == 'voices_volume')
			{
				vocals.volume = nums.value;
			}
			if (wname == 'manual_zoom') // some good coding here
			{
				var oldZoomFloat = zoomList[curZoom];
				var oldZoom = curZoom;
				if(!zoomList.contains(nums.value)) {
					zoomList.push(nums.value);
					zoomList.sort(function(a:Float, b:Float) {
						return FlxSort.byValues(FlxSort.ASCENDING, a, b);
					});
				}
				curZoom = zoomList.indexOf(nums.value);
				if(oldZoomFloat != zoomList[curZoom]) {
					updateZoom();
				}
			}
			if (wname == 'note_spamthing') {
			spamCloseness = nums.value;
			}
			if(wname == 'note_spamamount') {
			spamLength = nums.value;
			}
		}
		else if(id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)) {
			if(sender == noteSplashesInputText) {
				_song.splashSkin = noteSplashesInputText.text;
			}
			if(curSelectedNote != null)
			{
				if(sender == value1InputText) {
					if(curSelectedNote[1][curEventSelected] != null)
					{
						curSelectedNote[1][curEventSelected][1] = value1InputText.text;
						updateGrid();
					}
				}
				else if(sender == value2InputText) {
					if(curSelectedNote[1][curEventSelected] != null)
					{
						curSelectedNote[1][curEventSelected][2] = value2InputText.text;
						updateGrid();
					}
				}
				else if(sender == strumTimeInputText) {
					var value:Float = Std.parseFloat(strumTimeInputText.text);
					if(Math.isNaN(value)) value = 0;
					curSelectedNote[0] = value;
					updateGrid();
				}
			}
			if(sender == event7InputText) {
				_song.event7Value = event7InputText.text;
			} else if(sender == screwYouInputText) {
				_song.screwYou = screwYouInputText.text;
			} else if(sender == creditInputText) {
				_song.credit = creditInputText.text;
			}
		}
		else if (id == FlxUISlider.CHANGE_EVENT && (sender is FlxUISlider))
		{
			switch (sender)
			{
				case 'playbackSpeed':
					playbackSpeed = Std.int(sliderRate.value);
			}
		}

		// FlxG.log.add(id + " WEED " + sender + " WEED " + data + " WEED " + params);
	}

	var updatedSection:Bool = false;

	function sectionStartTime(add:Int = 0):Float
	{
		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...curSec + add)
		{
			if(_song.notes[i] != null)
			{
				if (_song.notes[i].changeBPM)
				{
					daBPM = _song.notes[i].bpm;
				}
				daPos += getSectionBeats(i) * (1000 * 60 / daBPM);
			}
		}
		return daPos;
	}

	var lastConductorPos:Float;
	var colorSine:Float = 0;
	override function update(elapsed:Float)
	{
		if(colorSwap != null && !ClientPrefs.lowQuality)
			colorSwap.hue += elapsed * 0.1;

		curStep = recalculateSteps();

		if(FlxG.sound.music.time < 0) {
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		}
		else if(FlxG.sound.music.time > FlxG.sound.music.length) {
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		_song.song = UI_songTitle.text;

		strumLineUpdateY();
		for (i in 0...8) {
			strumLineNotes.members[i].y = strumLine.y;
		}

		FlxG.mouse.visible = true; // cause reasons. trust me 
		camPos.y = strumLine.y;
		if(!disableAutoScrolling.checked) {
			if (Math.ceil(strumLine.y) >= gridBG.height)
			{
				if (_song.notes[curSec + 1] == null)
				{
					addSection();
				}

				changeSection(curSec + 1, false);
			} else if(strumLine.y < -10) {
				changeSection(curSec - 1, false);
			}
		}
		FlxG.watch.addQuick('daBeat', curBeat);
		FlxG.watch.addQuick('daStep', curStep);


		if (FlxG.mouse.x > gridBG.x
			&& FlxG.mouse.x < gridBG.x + gridBG.width
			&& FlxG.mouse.y > gridBG.y
			&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
		{
			dummyArrow.visible = true;
			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y;
			else
			{
				var gridmult = GRID_SIZE / (quantization / 16);
				dummyArrow.y = Math.floor(FlxG.mouse.y / gridmult) * gridmult;
			}
		} else {
			dummyArrow.visible = false;
		}

		if (FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.overlaps(curRenderedNotes))
			{
				curRenderedNotes.forEachAlive(function(note:Note)
				{
					if (FlxG.mouse.overlaps(note))
					{
						if (FlxG.keys.pressed.CONTROL || FlxG.keys.pressed.ALT)
						{
							addTextToLog('note selected ID: ' + note.ID);
							selectNote(note);
							if(FlxG.keys.pressed.ALT) {
								curSelectedNote[3] = noteTypeIntMap.get(currentType);
								updateGrid();
							}
						}
						else
						{
							addTextToLog('deleted note');
							deleteNote(note);
						}
					}
				});
			}
			else
			{
				if (FlxG.mouse.x > gridBG.x
					&& FlxG.mouse.x < gridBG.x + gridBG.width
					&& FlxG.mouse.y > gridBG.y
					&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom]
					&& !FlxG.mouse.overlaps(manualZoomInput))
				{
					addTextToLog('added note id: ' + addNote(null, null, null, true));
					addNote();
				}
			}
		}

		var blockInput:Bool = false;
		for (inputText in blockPressWhileTypingOn) {
			if(inputText.hasFocus) {
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				blockInput = true;
				break;
			}
		}

		if(!blockInput) {
			for (stepper in blockPressWhileTypingOnStepper) {
				@:privateAccess
				var leText:Dynamic = stepper.text_field;
				var leText:FlxUIInputText = leText;
				if(leText.hasFocus) {
					FlxG.sound.muteKeys = [];
					FlxG.sound.volumeDownKeys = [];
					FlxG.sound.volumeUpKeys = [];
					blockInput = true;
					break;
				}
			}
		}

		if(!blockInput) {
			FlxG.sound.muteKeys = TitleState.muteKeys;
			FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
			for (dropDownMenu in blockPressWhileScrolling) {
				if(dropDownMenu.dropPanel.visible) {
					blockInput = true;
					break;
				}
			}
		}

		if (!blockInput)
		{
			if(FlxG.keys.anyJustPressed(ClientPrefs.copyKey(ClientPrefs.keyBinds.get('save')))) {
				autosaveSong();
			}
			if (FlxG.keys.justPressed.ESCAPE)
			{
				autosaveSong();
				LoadingState.loadAndSwitchState(new editors.EditorPlayState(sectionStartTime()));
			} else if (FlxG.keys.justPressed.ENTER) // it will fuck up if not
			{
				autosaveSong();
				FlxG.mouse.visible = false;
				PlayState.SONG = _song;
				FlxG.sound.music.stop();
				if(vocals != null) vocals.stop();

				//if(_song.stage == null) _song.stage = stageDropDown.selectedLabel;
				StageData.loadDirectory(_song);
				LoadingState.loadAndSwitchState(new PlayState());
			}

			if(curSelectedNote != null && curSelectedNote[1] > -1) {
				if (FlxG.keys.anyJustPressed(ClientPrefs.copyKey(ClientPrefs.keyBinds.get('increase'))))
				{
					changeNoteSustain(Conductor.stepCrochet);
				}
				if (FlxG.keys.anyJustPressed(ClientPrefs.copyKey(ClientPrefs.keyBinds.get('decrease'))))
				{
					changeNoteSustain(-Conductor.stepCrochet);
				}
			}


			if (FlxG.keys.justPressed.BACKSPACE) {
				var mustReturn:Bool = false;
				openSubState(new Prompt("You haven't saved your progress\n\nProceed?", 0, function() {
					PlayState.chartingMode = false;
					MusicBeatState.switchState(new editors.MasterEditorMenu());
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					FlxG.mouse.visible = false;
					mustReturn = true;
				}, null, ignoreWarnings));
				if(mustReturn) return;
			}

			if(FlxG.keys.anyJustPressed(ClientPrefs.copyKey(ClientPrefs.keyBinds.get('zoom-'))) && curZoom > 0) {
				var shit:Int = 1;
				if(FlxG.keys.pressed.SHIFT && curZoom > 3) {
					shit = 3;
				}
				curZoom -= shit;
				updateZoom();
			}
			if(FlxG.keys.anyJustPressed(ClientPrefs.copyKey(ClientPrefs.keyBinds.get('zoom+'))) && curZoom < zoomList.length-1) {
				var shit:Int = 1;
				if(FlxG.keys.pressed.SHIFT && curZoom < zoomList.length-4) {
					shit = 3;
				}
				curZoom++;
				updateZoom();
			}
			if (FlxG.keys.pressed.C && !FlxG.keys.pressed.CONTROL) {
				if (!FlxG.mouse.overlaps(curRenderedNotes)) { //lmao cant place notes when your cursor already overlaps one
					if (FlxG.mouse.x > gridBG.x
						&& FlxG.mouse.x < gridBG.x + gridBG.width
						&& FlxG.mouse.y > gridBG.y
						&& FlxG.mouse.y < gridBG.y + gridBG.height)
					{
						if (!FlxG.keys.pressed.CONTROL) {//stop crashing
							addNote(); //allows you to draw notes by holding left click
						}
					}
				}
			}
			if(FlxG.keys.justPressed.G) {
				zoomList = oldZoomList;
				updateZoom();
			}

			if (FlxG.keys.justPressed.TAB)
			{
				if (FlxG.keys.pressed.SHIFT)
				{
					UI_box.selected_tab -= 1;
					if (UI_box.selected_tab < 0)
						UI_box.selected_tab = 2;
				}
				else
				{
					UI_box.selected_tab += 1;
					if (UI_box.selected_tab >= 3)
						UI_box.selected_tab = 0;
				}
			}

			if (FlxG.keys.justPressed.SPACE)
			{
				if (FlxG.sound.music.playing)
				{
					FlxG.sound.music.pause();
					if(vocals != null) vocals.pause();
				}
				else
				{
					if(vocals != null) {
						vocals.play();
						vocals.pause();
						vocals.time = FlxG.sound.music.time;
						vocals.play();
					}
					FlxG.sound.music.play();
				}
			}

			if (!FlxG.keys.pressed.ALT && FlxG.keys.justPressed.R)
			{
				resetSection(FlxG.keys.pressed.SHIFT);
			}

			if (FlxG.mouse.wheel != 0) // i dont recommend the fucking mouse
			{
				FlxG.sound.music.pause();
				if (!mouseQuant)
					FlxG.sound.music.time -= (FlxG.mouse.wheel * Conductor.stepCrochet * 0.8);
				else
				{
					var time:Float = FlxG.sound.music.time;
					var beat:Float = curDecBeat;
					var snap:Float = quantization / 4;
					var increase:Float = 1 / snap;
					var fuck:Float = CoolUtil.quantize(beat, snap) + (FlxG.mouse.wheel > 0 ? -increase : increase);
					FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
				}
				if(vocals != null) {
					vocals.pause();
					vocals.time = FlxG.sound.music.time;
				}
			}

			//ARROW VORTEX SHIT NO DEADASS



			if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
			{
				FlxG.sound.music.pause();

				var holdingShift:Float = 1;
				if (FlxG.keys.pressed.CONTROL) holdingShift = 0.25;
				else if (FlxG.keys.pressed.SHIFT) holdingShift = 4;

				var daTime:Float = 700 * FlxG.elapsed * holdingShift;

				FlxG.sound.music.time += FlxG.keys.pressed.W ? -daTime : daTime;

				if(vocals != null) {
					vocals.pause();
					vocals.time = FlxG.sound.music.time;
				}
			}

			if(!vortex) {
				if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN)
				{
					FlxG.sound.music.pause();
					updateCurStep();
					var time:Float = FlxG.sound.music.time;
					var beat:Float = curDecBeat;
					var snap:Float = quantization / 4;
					var increase:Float = 1 / snap;
					var fuck:Float = CoolUtil.quantize(beat, snap) + (FlxG.keys.pressed.UP ? -increase : increase); //(Math.floor((beat+snap) / snap) * snap);
					FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
				}
			}


			var style = currentType;

			if (FlxG.keys.pressed.SHIFT) {
				style = 3;
			}

			var conductorTime = Conductor.songPosition; //+ sectionStartTime(); Conductor.songPosition / Conductor.stepCrochet;

			if(!blockInput) {
				if(FlxG.keys.justPressed.RIGHT) {
					curQuant++;
					if(curQuant > quantizations.length-1)
						curQuant = 0;

					quantization = quantizations[curQuant];
				}

				if(FlxG.keys.justPressed.LEFT) {
					curQuant--;
					if(curQuant < 0)
						curQuant = quantizations.length-1;

					quantization = quantizations[curQuant];
				}
				quant.animation.play('q', true, false, curQuant);
			}
			if(vortex && !blockInput) {
				var controlArray:Array<Bool> = [
					FlxG.keys.justPressed.ONE,
					FlxG.keys.justPressed.TWO,
					FlxG.keys.justPressed.THREE,
					FlxG.keys.justPressed.FOUR,
					FlxG.keys.justPressed.FIVE,
					FlxG.keys.justPressed.SIX,
					FlxG.keys.justPressed.SEVEN,
					FlxG.keys.justPressed.EIGHT
				];

				if(controlArray.contains(true))
				{
					for (i in 0...controlArray.length)
					{
						if(controlArray[i])
							doANoteThing(conductorTime, i, style);
					}
				}

				var feces:Float;
				if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN)
				{
					FlxG.sound.music.pause();


					updateCurStep();
					//FlxG.sound.music.time = (Math.round(curStep / quants[curQuant]) * quants[curQuant]) * Conductor.stepCrochet;

					//(Math.floor((curStep + quants[curQuant] * 1.5 / (quants[curQuant] / 2)) / quants[curQuant]) * quants[curQuant]) * Conductor.stepCrochet; // snap into quantization
					var time:Float = FlxG.sound.music.time;
					var beat:Float = curDecBeat;
					var snap:Float = quantization / 4;
					var increase:Float = 1 / snap;
					var fuck:Float = CoolUtil.quantize(beat, snap) + (FlxG.keys.pressed.UP ? -increase : increase); //(Math.floor((beat + snap) / snap) * snap);
					feces = Conductor.beatToSeconds(fuck);
					FlxTween.tween(FlxG.sound.music, {time:feces}, 0.1, {ease:FlxEase.circOut});
					if(vocals != null) {
						vocals.pause();
						vocals.time = FlxG.sound.music.time;
					}

					var dastrum = 0;

					if (curSelectedNote != null) {
						dastrum = curSelectedNote[0];
					}

					var secStart:Float = sectionStartTime();
					var datime = (feces - secStart) - (dastrum - secStart); //idk math find out why it doesn't work on any other section other than 0
					if (curSelectedNote != null)
					{
						var controlArray:Array<Bool> = [ // this doesnt let you to put all the notes at the same time :'(
							(FlxG.keys.pressed.ONE && !FlxG.keys.justPressed.ONE),
							(FlxG.keys.pressed.TWO && !FlxG.keys.justPressed.TWO),
							(FlxG.keys.pressed.THREE && !FlxG.keys.justPressed.THREE),
							(FlxG.keys.pressed.FOUR && !FlxG.keys.justPressed.FOUR),
							(FlxG.keys.pressed.FIVE && !FlxG.keys.justPressed.FIVE),
							(FlxG.keys.pressed.SIX && !FlxG.keys.justPressed.SIX),
							(FlxG.keys.pressed.SEVEN && !FlxG.keys.justPressed.SEVEN),
							(FlxG.keys.pressed.EIGHT && !FlxG.keys.justPressed.EIGHT)
						];

						if(controlArray.contains(true))
						{
							for (i in 0...controlArray.length)
							{
								if(controlArray[i] && curSelectedNote[i] == i)
									curSelectedNote[2] += datime - curSelectedNote[2] - Conductor.stepCrochet;
							}
							updateGrid();
							updateNoteUI();
						}
					}
				}
			}
			var shiftThing:Int = 1;
			if (FlxG.keys.pressed.SHIFT)
				shiftThing = 4;

			if (FlxG.keys.justPressed.D)
				changeSection(curSec + shiftThing);

			if (FlxG.keys.justPressed.A) {
				changeSection((curSec <= 0) ? (_song.notes.length-1) : (curSec - shiftThing));
			}
		} else if (FlxG.keys.justPressed.ENTER) {
			for (i in 0...blockPressWhileTypingOn.length) {
				if(blockPressWhileTypingOn[i].hasFocus) {
					blockPressWhileTypingOn[i].hasFocus = false;
				}
			}
		}

		strumLineNotes.visible = quant.visible = vortex;

		if(FlxG.sound.music.time < 0) {
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		}
		else if(FlxG.sound.music.time > FlxG.sound.music.length) {
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		strumLineUpdateY();
		camPos.y = strumLine.y;
		for (i in 0...8) {
			strumLineNotes.members[i].y = strumLine.y;
			strumLineNotes.members[i].alpha = FlxG.sound.music.playing ? 1 : 0.35;
		}

		// PLAYBACK SPEED CONTROLS //
		var holdingShift = FlxG.keys.pressed.SHIFT;
		var holdingLB = FlxG.keys.pressed.LBRACKET; // WHICH FUCKING KEY IS THIS!? I CANT FIND IT!!
		var holdingRB = FlxG.keys.pressed.RBRACKET;
		var pressedLB = FlxG.keys.justPressed.LBRACKET;
		var pressedRB = FlxG.keys.justPressed.RBRACKET;

		if (!holdingShift && pressedLB || holdingShift && holdingLB)
			playbackSpeed -= 0.01;
		if (!holdingShift && pressedRB || holdingShift && holdingRB)
			playbackSpeed += 0.01;
		if (FlxG.keys.pressed.ALT && (pressedLB || pressedRB || holdingLB || holdingRB))
			playbackSpeed = 1;

		if (playbackSpeed <= 0.5)
			playbackSpeed = 0.5;
		if (playbackSpeed >= 3)
			playbackSpeed = 3;

		if(FlxG.sound.music.pitch != playbackSpeed)
			FlxG.sound.music.pitch = playbackSpeed;
		if(vocals.pitch != playbackSpeed)
			vocals.pitch = playbackSpeed;

		bpmTxt.text =
			Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2)) + " / " + Std.string(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2)) +
			"\nSection: " + curSec +
			"\n\nBeat: " + Std.string(curDecBeat).substring(0,4) +
			"\n\nStep: " + curStep +
			"\n\nBeat Snap: " + quantization + 'th';

		var playedSound:Array<Bool> = [false, false, false, false]; //Prevents ouchy GF sex sounds
		curRenderedNotes.forEachAlive(function(note:Note)
		{
			if(note.noteType == 'Rainbow Note' && note.shader == null && colorSwap != null && !ClientPrefs.lowQuality)
				note.shader = colorSwap.shader;

			note.alpha = 1;
			if(!ClientPrefs.lowQuality && curSelectedNote != null) { // less interactions, less lag
				var noteDataToCheck:Int = note.noteData;
				if(noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += 4;

				if (curSelectedNote[0] == note.strumTime && ((curSelectedNote[2] == null && noteDataToCheck < 0) || (curSelectedNote[2] != null && curSelectedNote[1] == noteDataToCheck)))
				{
					colorSine += elapsed;
					var colorVal:Float = 0.7 + Math.sin(Math.PI * colorSine) * 0.3;
					note.color = FlxColor.fromRGBFloat(colorVal, colorVal, colorVal, 0.999); //Alpha can't be 100% or the color won't be updated for some reason, guess i will die
				}
			}

			if(note.strumTime <= Conductor.songPosition) {
				note.alpha = 0.4;
				if(note.strumTime > lastConductorPos && FlxG.sound.music.playing && note.noteData > -1) {
					var data:Int = note.noteData % 4;
					var noteDataToCheck:Int = note.noteData;
					if(noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += 4;

					strumLineNotes.members[noteDataToCheck].playAnim('confirm', true);
					strumLineNotes.members[noteDataToCheck].resetAnim = ((note.sustainLength / 1000) + 0.15) / playbackSpeed;

					if(!playedSound[data])
					{
						if((playSoundBf.checked && note.mustPress) || (playSoundDad.checked && !note.mustPress))
						{
							var soundToPlay = 'hitsound';
							if(_song.player1.startsWith('gf')) { //Easter egg
								soundToPlay = 'GF_' + Std.string(data + 1);
							}

							FlxG.sound.play(Paths.sound(soundToPlay)).pan = note.noteData < 4 ? -0.3 : 0.3; //would be coolio
							playedSound[data] = true;
						}

						data = note.noteData;
						if(note.mustPress != _song.notes[curSec].mustHitSection)
						{
							data += 4;
						}
					}
				}
			}
		});

		if(metronome.checked && lastConductorPos != Conductor.songPosition)
		{
			var metroInterval:Float = 60 / metronomeStepper.value;
			var metroStep:Int = Math.floor(((Conductor.songPosition + metronomeOffsetStepper.value) / metroInterval) / 1000);
			var lastMetroStep:Int = Math.floor(((lastConductorPos + metronomeOffsetStepper.value) / metroInterval) / 1000);
			if(metroStep != lastMetroStep) {
				FlxG.sound.play(Paths.sound('Metronome_Tick'));
				//trace('Ticked');
			}
		}
		lastConductorPos = Conductor.songPosition;
		super.update(elapsed);
	}

	function updateZoom() {
		if(curZoom >= zoomList.length) curZoom = zoomList.indexOf(1);
		var daZoom:Float = zoomList[curZoom];
		var zoomThing:String = '1 / ' + daZoom;
		if(daZoom < 1) zoomThing = Math.round(1 / daZoom) + ' / 1';
		zoomTxt.text = 'Zoom: ' + zoomThing;
		manualZoomInput.value = zoomList[curZoom];
		resetZoomText.visible = zoomList != oldZoomList;

		reloadGridLayer();
	}

	var lastSecBeats:Float = 0;
	var lastSecBeatsNext:Float = 0;
	var strumNotesLength:Int = 4;
	function reloadGridLayer() {
		gridLayer.clear();
		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 9, Std.int(GRID_SIZE * getSectionBeats() * 4 * zoomList[curZoom]));

		#if desktop
		if(FlxG.save.data.chart_waveformInst || FlxG.save.data.chart_waveformVoices) {
			updateWaveform();
		}
		#end

		var leHeight:Int = Std.int(gridBG.height);
		var foundNextSec:Bool = false;
		if(sectionStartTime(1) <= FlxG.sound.music.length)
		{
			nextGridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 9, Std.int(GRID_SIZE * getSectionBeats(curSec + 1) * 4 * zoomList[curZoom]));
			leHeight = Std.int(gridBG.height + nextGridBG.height);
			foundNextSec = true;
		}
		else nextGridBG = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
		nextGridBG.y = gridBG.height;

		gridLayer.add(nextGridBG);
		gridLayer.add(gridBG);

		if(foundNextSec)
		{
			var gridBlack:FlxSprite = new FlxSprite(0, gridBG.height).makeGraphic(Std.int(GRID_SIZE * 9), Std.int(nextGridBG.height), FlxColor.BLACK);
			gridBlack.alpha = 0.4;
			gridLayer.add(gridBlack);
		}

		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + gridBG.width - (GRID_SIZE * 4)).makeGraphic(2, leHeight, FlxColor.BLACK);
		gridLayer.add(gridBlackLine);

		for (i in 1...strumNotesLength) {
			var beatsep1:FlxSprite = new FlxSprite(gridBG.x, (GRID_SIZE * (4 * curZoom)) * i).makeGraphic(Std.int(gridBG.width), 1, 0x44FF0000);
			if(vortex)
			{
				gridLayer.add(beatsep1);
			}
		}

		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + GRID_SIZE).makeGraphic(2, leHeight, FlxColor.BLACK);
		gridLayer.add(gridBlackLine);
		updateGrid();

		lastSecBeats = getSectionBeats();
		if(sectionStartTime(1) > FlxG.sound.music.length) lastSecBeatsNext = 0;
		else getSectionBeats(curSec + 1);
	}

	function strumLineUpdateY()
	{
		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) / zoomList[curZoom] % (Conductor.stepCrochet * 16)) / (getSectionBeats() / 4);
	}

	var waveformPrinted:Bool = true;
	var wavData:Array<Array<Array<Float>>> = [[[0], [0]], [[0], [0]]];
	function updateWaveform() {
		#if desktop
		if(waveformPrinted) {
			waveformSprite.makeGraphic(Std.int(GRID_SIZE * 8), Std.int(gridBG.height), 0x00FFFFFF);
			waveformSprite.pixels.fillRect(new Rectangle(0, 0, gridBG.width, gridBG.height), 0x00FFFFFF);
		}
		waveformPrinted = false;

		if(!FlxG.save.data.chart_waveformInst && !FlxG.save.data.chart_waveformVoices) {
			addTextToLog('Epic fail on the waveform lol', FlxColor.RED);
			return;
		}

		wavData[0][0] = [];
		wavData[0][1] = [];
		wavData[1][0] = [];
		wavData[1][1] = [];

		var steps:Int = Math.round(getSectionBeats() * 4);
		var st:Float = sectionStartTime();
		var et:Float = st + (Conductor.stepCrochet * steps);

		if (FlxG.save.data.chart_waveformInst) {
			var sound:FlxSound = FlxG.sound.music;
			if (sound._sound != null && sound._sound.__buffer != null) {
				var bytes:Bytes = sound._sound.__buffer.data.toBytes();

				wavData = waveformData(
					sound._sound.__buffer,
					bytes,
					st,
					et,
					1,
					wavData,
					Std.int(gridBG.height)
				);
			}
		}

		if (FlxG.save.data.chart_waveformVoices) {
			var sound:FlxSound = vocals;
			if (sound._sound != null && sound._sound.__buffer != null) {
				var bytes:Bytes = sound._sound.__buffer.data.toBytes();

				wavData = waveformData(
					sound._sound.__buffer,
					bytes,
					st,
					et,
					1,
					wavData,
					Std.int(gridBG.height)
				);
			}
		}

		// Draws
		var gSize:Int = Std.int(GRID_SIZE * 8);
		var hSize:Int = Std.int(gSize / 2);

		var lmin:Float = 0;
		var lmax:Float = 0;

		var rmin:Float = 0;
		var rmax:Float = 0;

		var size:Float = 1;

		var leftLength:Int = (
			wavData[0][0].length > wavData[0][1].length ? wavData[0][0].length : wavData[0][1].length
		);

		var rightLength:Int = (
			wavData[1][0].length > wavData[1][1].length ? wavData[1][0].length : wavData[1][1].length
		);

		var length:Int = leftLength > rightLength ? leftLength : rightLength;

		var index:Int;
		for (i in 0...length) {
			index = i;

			function thing(j:Int, k:Int) {
				return (FlxMath.bound(
					((index < wavData[j][k].length && index >= 0) ? wavData[j][k][index] : 0) * (gSize / 1.12),
					-hSize,
					hSize)) / 2;
			}

			lmin = thing(0, 0);
			lmax = thing(0, 1);

			rmin = thing(1, 0);
			rmax = thing(1, 1);

			var leftActiveLeft = true;
			if(waveformLeftActiveLeft != null)
				leftActiveLeft = waveformLeftActiveLeft.checked;
			var leftActiveRight = true;
			if(waveformLeftActiveRight != null)
				leftActiveRight = waveformLeftActiveRight.checked;
			var rightActiveLeft = true;
			if(waveformRightActiveLeft != null)
				rightActiveLeft = waveformRightActiveLeft.checked;
			var rightActiveRight = true;
			if(waveformRightActiveRight != null)
				rightActiveRight = waveformRightActiveRight.checked;

			var leftMax = true;
			if(waveformLeftMax != null)
				leftMax = waveformLeftMax.checked;
			var leftMin = true;
			if(waveformLeftMin != null)
				leftMin = waveformLeftMin.checked;
			var rightMax = true;
			if(waveformRightMax != null)
				rightMax = waveformRightMax.checked;
			var rightMin = true;
			if(waveformRightMin != null)
				rightMin = waveformRightMin.checked;

			// left
			waveformSprite.pixels.fillRect(new Rectangle(hSize - ((leftActiveLeft ? lmin : 0) + (leftActiveRight ? rmin : 0)), (i * size), (
				(leftMin ? lmin : 0) +
				(rightMin ? rmin : 0) +
				(leftMax ? lmax : 0) +
				(rightMax ? rmax : 0) +
			0), size), FlxColor.BLUE);

			// right
			waveformSprite.pixels.fillRect(new Rectangle(hSize - ((rightActiveLeft ? lmin : 0) + (rightActiveRight ? rmin : 0)), (i * size), (
				(leftMin ? lmin : 0) +
				(rightMin ? rmin : 0) +
				(leftMax ? lmax : 0) +
				(rightMax ? rmax : 0) +
			0), size), FlxColor.RED);
		}

		waveformPrinted = true;
		#end
	}

	function waveformData(buffer:AudioBuffer, bytes:Bytes, time:Float, endTime:Float, multiply:Float = 1, ?array:Array<Array<Array<Float>>>, ?steps:Float):Array<Array<Array<Float>>>
	{
		#if (lime_cffi && !macro)
		if (buffer == null || buffer.data == null) return [[[0], [0]], [[0], [0]]];

		var khz:Float = (buffer.sampleRate / 1000); // MY GOD!!!! IS THIS FOR AUTO CHART!!????
		var channels:Int = buffer.channels;

		var index:Int = Std.int(time * khz);

		var samples:Float = ((endTime - time) * khz);

		if (steps == null) steps = 1280;

		var samplesPerRow:Float = (samples / steps);
		var samplesPerRowI:Int = Std.int(samplesPerRow);

		var gotIndex:Int = 0;

		var lmin:Float = 0;
		var lmax:Float = 0;

		var rmin:Float = 0;
		var rmax:Float = 0;

		var rows:Float = 0;

		var simpleSample:Bool = true; // samples > 17200;
		var v1:Bool = false;

		if (array == null) array = [[[0], [0]], [[0], [0]]];

		while (index < (bytes.length - 1)) {
			if (index >= 0) {
				var byte:Int = bytes.getUInt16(index * channels * 2);

				if (byte > 65535 / 2) byte -= 65535;

				var sample:Float = (byte / 65535);

				if (sample > 0) {
					if (sample > lmax) lmax = sample;
				} else if (sample < 0 && sample < lmin) {
					lmin = sample;
				}

				if (channels >= 2) {
					byte = bytes.getUInt16((index * channels * 2) + 2);

					if (byte > 65535 / 2) byte -= 65535;

					sample = (byte / 65535);

					if (sample > 0) {
						if (sample > rmax) rmax = sample;
					} else if (sample < 0 && sample < rmin) {
						rmin = sample;
					}
				}
			}

			v1 = samplesPerRowI > 0 ? (index % samplesPerRowI == 0) : false;
			while (simpleSample ? v1 : rows >= samplesPerRow) {
				v1 = false;
				rows -= samplesPerRow;

				gotIndex++;

				var lRMin:Float = (Math.abs(lmin) * multiply);
				var lRMax:Float = (lmax * multiply);

				var rRMin:Float = (Math.abs(rmin) * multiply);
				var rRMax:Float = (rmax * multiply);

				if (gotIndex > array[0][0].length)
					array[0][0].push(lRMin);
				else
					array[0][0][gotIndex - 1] = (array[0][0][gotIndex - 1] + lRMin);

				if (gotIndex > array[0][1].length)
					array[0][1].push(lRMax);
				else
					array[0][1][gotIndex - 1] = (array[0][1][gotIndex - 1] + lRMax);

				if (channels >= 2) {
					if (gotIndex > array[1][0].length)
						array[1][0].push(rRMin);
					else
						array[1][0][gotIndex - 1] = (array[1][0][gotIndex - 1] + rRMin);
	
					if (gotIndex > array[1][1].length)
						array[1][1].push(rRMax);
					else
						array[1][1][gotIndex - 1] = (array[1][1][gotIndex - 1] + rRMax);
				}
				else {
					if (gotIndex > array[1][0].length)
						array[1][0].push(lRMin);
					else
						(array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + lRMin);

					if (gotIndex > array[1][1].length)
						array[1][1].push(lRMax);
					else
						array[1][1][gotIndex - 1] = (array[1][1][gotIndex - 1] + lRMax);
				}

				lmin = 0;
				lmax = 0;

				rmin = 0;
				rmax = 0;
			}

			index++;
			rows++;
			if(gotIndex > steps) break;
		}

		return array;
		#else
		return [[[0], [0]], [[0], [0]]];
		#end
	}

	function changeNoteSustain(value:Float):Void
	{
		if (curSelectedNote != null && curSelectedNote[2] != null)
		{
			curSelectedNote[2] += value;
			curSelectedNote[2] = Math.max(curSelectedNote[2], 0);
		}

		updateNoteUI();
		updateGrid();
	}

	function recalculateSteps(add:Float = 0):Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		};

		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = (lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime + add) / Conductor.stepCrochet));
		updateBeat();

		return curStep;
	}

	function resetSection(songBeginning:Bool = false):Void
	{
		updateGrid();

		FlxG.sound.music.pause();
		// Basically old shit from changeSection???
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning)
		{
			FlxG.sound.music.time = 0;
			curSec = 0;
		}

		if(vocals != null) {
			vocals.pause();
			vocals.time = FlxG.sound.music.time;
		}
		updateCurStep();

		updateGrid();
		updateSectionUI();
		updateWaveform();
	}

	function changeSection(sec:Int = 0, updateMusic:Bool = true):Void
	{
		if (_song.notes[sec] != null)
		{
			curSec = sec;
			if (updateMusic)
			{
				FlxG.sound.music.pause();

				FlxG.sound.music.time = sectionStartTime();
				if(vocals != null) {
					vocals.pause();
					vocals.time = FlxG.sound.music.time;
				}
				updateCurStep();
			}

			var blah1:Float = getSectionBeats();
			var blah2:Float = getSectionBeats(curSec + 1);
			if(sectionStartTime(1) > FlxG.sound.music.length) blah2 = 0;

			if(blah1 != lastSecBeats || blah2 != lastSecBeatsNext)
			{
				reloadGridLayer();
			}
			else
			{
				updateGrid();
			}
			updateSectionUI();
		}
		else
		{
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		updateWaveform();
	}

	function updateSectionUI():Void
	{
		var sec = _song.notes[curSec];

		stepperBeats.value = getSectionBeats();
		check_mustHitSection.checked = sec.mustHitSection;
		check_gfSection.checked = sec.gfSection;
		check_altAnim.checked = sec.altAnim;
		check_changeBPM.checked = sec.changeBPM;
		stepperSectionBPM.value = sec.bpm;

		updateHeads();
	}

	function updateHeads():Void
	{
		var healthIconP1:String = loadHealthIconFromCharacter(_song.player1);
		var healthIconP2:String = loadHealthIconFromCharacter(_song.player2);

		leftIcon.changeIcon(_song.notes[curSec].mustHitSection ? healthIconP1 : healthIconP2);
		rightIcon.changeIcon(_song.notes[curSec].mustHitSection ? healthIconP2 : healthIconP1);
		
		if (_song.notes[curSec].gfSection) leftIcon.changeIcon('gf');
	}

	function loadHealthIconFromCharacter(char:String) {
		var characterPath:String = 'characters/' + char + '.json';
		#if MODS_ALLOWED
		var path:String = Paths.modFolders(characterPath);
		if (!FileSystem.exists(path)) {
			path = Paths.getPreloadPath(characterPath);
		}

		if (!FileSystem.exists(path))
		#else
		var path:String = Paths.getPreloadPath(characterPath);
		if (!OpenFlAssets.exists(path))
		#end
		{
			path = Paths.getPreloadPath('characters/' + Character.DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
		}

		#if MODS_ALLOWED
		var rawJson = File.getContent(path);
		#else
		var rawJson = OpenFlAssets.getText(path);
		#end

		var json:Character.CharacterFile = cast Json.parse(rawJson);
		return json.healthicon;
	}

	function updateNoteUI():Void
	{
		if (curSelectedNote != null) {
			if(curSelectedNote[2] != null) {
				stepperSusLength.value = curSelectedNote[2];
				if(curSelectedNote[3] != null) {
					currentType = noteTypeMap.get(curSelectedNote[3]);
					noteTypeDropDown.selectedLabel = (currentType <= 0 ? '' : currentType + '. ' + curSelectedNote[3]);
				}
			} else {
				eventDropDown.selectedLabel = curSelectedNote[1][curEventSelected][0];
				var selected:Int = Std.parseInt(eventDropDown.selectedId);
				if(selected > 0 && selected < eventStuff.length) {
					descText.text = eventStuff[selected][1];
				}
				value1InputText.text = curSelectedNote[1][curEventSelected][1];
				value2InputText.text = curSelectedNote[1][curEventSelected][2];
			}
			strumTimeInputText.text = '' + curSelectedNote[0];
		}
	}

	function updateGrid():Void
	{
		curRenderedNotes.clear();
		curRenderedSustains.clear();
		curRenderedNoteType.clear();
		nextRenderedNotes.clear();
		nextRenderedSustains.clear();

		if (_song.notes[curSec].changeBPM && _song.notes[curSec].bpm > 0)
		{
			Conductor.changeBPM(_song.notes[curSec].bpm);
			//trace('BPM of this section:');
		}
		else
		{
			// get last bpm
			var daBPM:Float = _song.bpm;
			for (i in 0...curSec) {
				if (_song.notes[i].changeBPM)
					daBPM = _song.notes[i].bpm;
			}
			Conductor.changeBPM(daBPM);
		}

		// CURRENT SECTION
		var beats:Float = getSectionBeats();
		for (daNotes in _song.notes[curSec].sectionNotes)
		{
			var note:Note = setupNoteData(daNotes, false);
			curRenderedNotes.add(note);
			if (note.sustainLength > 0)
			{
				curRenderedSustains.add(setupSusNote(note, beats));
			}

			if(daNotes[3] != null && note.noteType != null && note.noteType.length > 0) {
				var typeInt:Null<Int> = noteTypeMap.get(daNotes[3]);
				var theType:String = '' + typeInt;
				if(typeInt == null) theType = '?';

				var daText:AttachedFlxText = new AttachedFlxText(0, 0, 100, theType, 24);
				daText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				daText.xAdd = -32;
				daText.yAdd = 6;
				daText.borderSize = 1;
				curRenderedNoteType.add(daText);
				daText.sprTracker = note;
			}
			note.mustPress = _song.notes[curSec].mustHitSection;
			if(daNotes[1] > 3) note.mustPress = !note.mustPress;
		}

		// CURRENT EVENTS
		var startThing:Float = sectionStartTime();
		var endThing:Float = sectionStartTime(1);
		for (daEvent in _song.events)
		{
			if(endThing > daEvent[0] && daEvent[0] >= startThing)
			{
				var note:Note = setupNoteData(daEvent, false);
				curRenderedNotes.add(note);

				var text:String = 'Event: ' + note.eventName + ' (' + Math.floor(note.strumTime) + ' ms)\nValue 1: ' + note.eventVal1 + '\nValue 2: ' + note.eventVal2;
				if(note.eventLength > 1) text = note.eventLength + ' Events:\n' + note.eventName;

				var daText:AttachedFlxText = new AttachedFlxText(0, 0, 400, text, 12);
				daText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
				daText.xAdd = -410;
				daText.borderSize = 1;
				if(note.eventLength > 1) daText.yAdd += 8;
				curRenderedNoteType.add(daText);
				daText.sprTracker = note;
				//addTextToLog('test: ' + i[0], 'startThing: ' + startThing, 'endThing: ' + endThing);
			}
		}

		// NEXT SECTION
		var beats:Float = getSectionBeats(1);
		if(curSec < _song.notes.length-1) {
			for (thisNotes in _song.notes[curSec + 1].sectionNotes)
			{
				var note:Note = setupNoteData(thisNotes, true);
				note.alpha = 0.6;
				nextRenderedNotes.add(note);
				if (note.sustainLength > 0)
				{
					nextRenderedSustains.add(setupSusNote(note, beats));
				}
			}
		}

		// NEXT EVENTS
		var startThing:Float = sectionStartTime(1);
		var endThing:Float = sectionStartTime(2);
		for (daEvent in _song.events)
		{
			if(endThing > daEvent[0] && daEvent[0] >= startThing)
			{
				var note:Note = setupNoteData(daEvent, true);
				note.alpha = 0.6;
				nextRenderedNotes.add(note);
			}
		}
	}

	function setupNoteData(i:Array<Dynamic>, isNextSection:Bool):Note
	{
		var daNoteInfo = i[1];
		var daStrumTime = i[0];
		var daSus:Dynamic = i[2];

		var note:Note = new Note(daStrumTime, daNoteInfo % 4, null, null, true);
		if(daSus != null) { // Common note
			if(!Std.isOfType(i[3], String)) //Convert old note type to new note type format
			{
				i[3] = noteTypeIntMap.get(i[3]);
			}
			if(i.length > 3 && (i[3] == null || i[3].length < 1))
			{
				i.remove(i[3]);
			}
			note.sustainLength = daSus;
			note.noteType = i[3];
		} else { // Event note
			note.loadGraphic(Paths.image('eventArrow'));
			note.eventName = getEventName(i[1]);
			note.eventLength = i[1].length;
			if(i[1].length < 2 /* or is it 3? */) // testing
			{
				note.eventVal1 = i[1][0][1];
				note.eventVal2 = i[1][0][2];
			}
			note.noteData = -1;
			daNoteInfo = -1;
		}

		note.setGraphicSize(GRID_SIZE, GRID_SIZE);
		note.updateHitbox();
		note.x = Math.floor(daNoteInfo * GRID_SIZE) + GRID_SIZE;
		if(isNextSection && _song.notes[curSec].mustHitSection != _song.notes[curSec + 1].mustHitSection) {
			if(daNoteInfo > 3) {
				note.x -= GRID_SIZE * 4;
			} else if(daSus != null) {
				note.x += GRID_SIZE * 4;
			}
		}

		var beats:Float = getSectionBeats(isNextSection ? 1 : 0);
		note.y = getYfromStrumNotes(daStrumTime - sectionStartTime(), beats);
		//if(isNextSection) note.y += gridBG.height;
		if(note.y < -150) note.y = -150;
		return note;
	}

	function getEventName(names:Array<Dynamic>):String
	{
		var retStr:String = '';
		var addedOne:Bool = false;
		for (i in 0...names.length)
		{
			if(addedOne) retStr += ', ';
			retStr += names[i][0];
			addedOne = true;
		}
		return retStr;
	}

	function setupSusNote(note:Note, beats:Float):FlxSprite {
		var height:Int = Math.floor(FlxMath.remapToRange(note.sustainLength, 0, Conductor.stepCrochet * 16, 0, GRID_SIZE * 16 * zoomList[curZoom]) + (GRID_SIZE * zoomList[curZoom]) - GRID_SIZE / 2);
		var minHeight:Int = Std.int((GRID_SIZE * zoomList[curZoom] / 2) + GRID_SIZE / 2);
		if(height < minHeight) height = minHeight;
		if(height < 1) height = 1; //Prevents error of invalid height

		var spr:FlxSprite = new FlxSprite(note.x + (GRID_SIZE * 0.5) - 4, note.y + GRID_SIZE / 2).makeGraphic(8, height);
		return spr;
	}

	private function addSection(sectionBeats:Float = 4):Void
	{
		var sec:SwagSection = {
			sectionBeats: sectionBeats,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: true,
			gfSection: false,
			sectionNotes: [],
			typeOfSection: 0,
			altAnim: false
		};

		_song.notes.push(sec);
	}

	function selectNote(note:Note):Void
	{
		var noteDataToCheck:Int = note.noteData;

		if(noteDataToCheck > -1)
		{
			if(note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += 4;
			for (daNotes in _song.notes[curSec].sectionNotes)
			{
				if (daNotes != curSelectedNote && daNotes.length > 2 && daNotes[0] == note.strumTime && daNotes[1] == noteDataToCheck)
				{
					curSelectedNote = daNotes;
					break;
				}
			}
		}
		else
		{
			for (daEvent in _song.events)
			{
				if(daEvent != curSelectedNote && daEvent[0] == note.strumTime)
				{
					curSelectedNote = daEvent;
					curEventSelected = Std.int(curSelectedNote[1].length) - 1;
					
					break;
				}
			}
		}
		changeEventSelected();

		updateGrid();
		updateNoteUI();
	}

	function deleteNote(note:Note):Void
	{
		var noteDataToCheck:Int = note.noteData;
		if(noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += 4;

		if(note.noteData > -1) //Normal Notes
		{
			for (daNotes in _song.notes[curSec].sectionNotes)
			{
				if (daNotes[0] == note.strumTime && daNotes[1] == noteDataToCheck)
				{
					if(daNotes == curSelectedNote) curSelectedNote = null;
					//FlxG.log.add('FOUND EVIL NOTE');
					_song.notes[curSec].sectionNotes.remove(daNotes);
					break;
				}
			}
		}
		else //Events
		{
			for (daEvent in _song.events)
			{
				if(daEvent[0] == note.strumTime)
				{
					if(daEvent == curSelectedNote)
					{
						curSelectedNote = null;
						changeEventSelected();
					}
					//FlxG.log.add('FOUND EVIL EVENT');
					_song.events.remove(daEvent);
					break;
				}
			}
		}

		updateGrid();
	}

	public function doANoteThing(cs, d, style) {
		var delnote = false;
		if(strumLineNotes.members[d].overlaps(curRenderedNotes))
		{
			curRenderedNotes.forEachAlive(function(note:Note)
			{
				if (note.overlapsPoint(new FlxPoint(strumLineNotes.members[d].x + 1, strumLine.y + 1)) && note.noteData == d % 4)
				{
					//addTextToLog('tryin to delete note...');
					if(!delnote) deleteNote(note);
					delnote = true;
				}
			});
		}

		if (!delnote) {
			addNote(cs, d, style);
		}
	}
	function clearSong():Void
	{
		for (daSection in 0..._song.notes.length)
		{
			_song.notes[daSection].sectionNotes = [];
		}

		updateGrid();
	}

	private function addNote(strum:Null<Float> = null, data:Null<Int> = null, type:Null<Int> = null, returnValue:Bool = false)
	{
		var noteStrum = getStrumTime(dummyArrow.y * (getSectionBeats() / 4), false) + sectionStartTime();
		var noteData = Math.floor((FlxG.mouse.x - GRID_SIZE) / GRID_SIZE);
		var noteSus = 0;
		var daAlt = false;
		var daType = currentType;

		if (strum != null) noteStrum = strum;
		if (data != null) noteData = data;
		if (type != null) daType = type;

		if(!returnValue) {
			//curUndoIndex++;
			//var newsong = _song.notes;
			//undos.push(newsong);

			if(noteData > -1)
			{
				_song.notes[curSec].sectionNotes.push([noteStrum, noteData, noteSus, noteTypeIntMap.get(daType)]);
				curSelectedNote = _song.notes[curSec].sectionNotes[_song.notes[curSec].sectionNotes.length - 1];
			}
			else
			{
				var event = eventStuff[Std.parseInt(eventDropDown.selectedId)][0];
				var text1 = value1InputText.text;
				var text2 = value2InputText.text;
				_song.events.push([noteStrum, [[event, text1, text2]]]);
				curSelectedNote = _song.events[_song.events.length - 1];
				curEventSelected = 0;
			}
			changeEventSelected();

			if (FlxG.keys.pressed.CONTROL && noteData > -1)
			{
				_song.notes[curSec].sectionNotes.push([noteStrum, (noteData + 4) % 8, noteSus, noteTypeIntMap.get(daType)]);
			}
			strumTimeInputText.text = '' + curSelectedNote[0];

			updateGrid();
			updateNoteUI();
		}
		return noteData;
	}

	function undo()
	{
		undos.pop();
	}

	function getStrumTime(yPos:Float, doZoomCalc:Bool = true):Float
	{
		var leZoom:Float = zoomList[curZoom];
		if(!doZoomCalc) leZoom = 1;
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height * leZoom, 0, 16 * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float, doZoomCalc:Bool = true):Float
	{
		var leZoom:Float = zoomList[curZoom];
		if(!doZoomCalc) leZoom = 1;
		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, gridBG.y, gridBG.y + gridBG.height * leZoom);
	}

	function getYfromStrumNotes(strumTime:Float, beats:Float):Float
	{
		var value:Float = (strumTime / (beats * 4 * Conductor.stepCrochet));
		return (GRID_SIZE * beats * 4 * zoomList[curZoom] * value + gridBG.y);
	}

	function getNotes():Array<Dynamic>
	{
		var noteData:Array<Dynamic> = [];

		for (aSection in _song.notes)
		{
			noteData.push(aSection.sectionNotes);
		}

		return noteData;
	}

	function loadJson(song:String):Void
	{
		try {
			//make it look sexier if possible
			if (CoolUtil.difficulties[PlayState.storyDifficulty] != CoolUtil.defaultDifficulty /* 'Normal' */
			    && CoolUtil.difficulties[PlayState.storyDifficulty] != null)
			{
				PlayState.SONG = Song.loadFromJson(song.toLowerCase() + "-" + CoolUtil.difficulties[PlayState.storyDifficulty], song.toLowerCase());
			} else {
				PlayState.SONG = Song.loadFromJson(song.toLowerCase(), song.toLowerCase());
			}
			MusicBeatState.resetState();
		} catch(e) {
			trace(e);
		}
	}

	function autosaveSong():Void
	{
		FlxG.save.data.autosave = Json.stringify({
			"song": _song
		});
		if(!FlxG.save.flush()) {
			addTextToDebug("Problem saving song, trying again", FlxColor.RED);
			autosaveSong(); // lol
		} else {
			FlxG.save.flush();
			addTextToDebug("Saved completed", FlxColor.GREEN);
		}
	}

	function clearEvents() {
		_song.events = [];
		updateGrid();
	}

	private function saveLevel()
	{
		if(_song.events != null && _song.events.length > 1) _song.events.sort(sortByTime);
		var json = {
			"song": _song
		};

		var data:String = Json.stringify(json, "\t");

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), Paths.formatToSongPath(_song.song) + ".json");
		}
	}

	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	private function saveEvents()
	{
		if(_song.events != null && _song.events.length > 1) _song.events.sort(sortByTime);
		var eventsSong:Dynamic = {
			events: _song.events
		};
		var json = {
			"song": eventsSong
		};

		var data:String = Json.stringify(json, "\t");

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), "events.json");
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		addTextToDebug("Successfully saved SONG DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		addTextToDebug("Problem saving Song data", FlxColor.RED);
	}

	function getSectionBeats(?section:Null<Int>)
	{
		if (section == null) section = curSec;
		var val:Null<Float> = null;

		if(_song.notes[section] != null) val = _song.notes[section].sectionBeats;
		return val != null ? val : 4;
	}

	/**
	 * Use this instead of `trace()` when alerting the player
	 * @param text 
	 * @param color 
	 */
	public static function addTextToDebug(text:String, color:FlxColor = 0xFFFFFFFF) { // thanks Raltyro
		#if LUA_ALLOWED
		if (debugGroup == null)
			return;

		if (debugGroup != null){
			debugGroup.forEachAlive(function(spr:DebugLuaText) {
				if (spr != null)
					spr.y += 20;
			});
		}

		if(debugGroup != null && debugGroup.members.length > 34) {
			var blah = debugGroup.members[34];
			blah.destroy();
			debugGroup.remove(blah);
		}
		if (debugGroup != null)
			debugGroup.insert(0, new DebugLuaText(text, debugGroup, color));

		#end
		#if debug
		FlxG.log.notice(text);
		#else
		trace(text);
		#end
	}
	/**
	 * Use this instead
	 * @param text 
	 * @param color 
	 */
	public static function addTextToLog(text:String, color:FlxColor = FlxColor.WHITE) {
		FlxG.log.add(text);
		#if debug
		addTextToDebug(text, color);
		#end
	}

	override function updateCurStep():Void 
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	override function destroy(){
		instance = null;
		
		return super.destroy();
	}
}

class AttachedFlxText extends FlxText
{
	public var sprTracker:FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;

	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true) {
		super(X, Y, FieldWidth, Text, Size, EmbeddedFont);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null) {
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			angle = sprTracker.angle;
			alpha = sprTracker.alpha;
		}
	}
}
