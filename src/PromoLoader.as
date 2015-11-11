package
{
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeApplication;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.LoaderInfo;
	import flash.display.NativeMenuItem;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowType;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.NativeWindowBoundsEvent;
	import flash.filesystem.File;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	import flash.system.LoaderContext;
	
	import axl.utils.ConnectPHP;
	import axl.utils.Ldr;
	import axl.utils.U;
	import axl.utils.binAgent.BinAgent;
	import axl.xdef.xLiveAranger;
	
	import fl.controls.Button;
	import fl.controls.CheckBox;
	import fl.controls.NumericStepper;
	import fl.controls.TextInput;
	import fl.events.ComponentEvent;
	
	public class PromoLoader extends Sprite
	{
		private var btnLoad:Button;
		
		private var f:File;
		private var btnReload:Button;
		private var currentName:String;
		private var currentUrl:String;
		
		private var swfLoaderInfo:LoaderInfo;
		private var tfMember:TextInput;
		
		private var overlap:String;
		private var tfCompVal:TextInput;
		private var bar:Sprite = new Sprite();
		private var dates:DateComponent
		private var liveAranger:xLiveAranger;
		private var LOADABLEURL:URLRequest;
		private var btnConsole:Button;
		private var consoleWindow:NativeWindow;
		private var tracking:String = null;//'https://axldns.com/promoloader/gateway.php'
		private var appUrl:String;
		private var VERSION:String = '0.0.5';
		private var userAgentData:String;
		private var netObject:Object;
		private var session:Number;
		private var exit:ConnectPHP;
		private var exitObject:Object;
		private var btnRecent:Button;
		private var recentWindow:NativeWindow;
		private var syncWindow:NativeWindow;
		private var recentContainer:Recent;
		private var configProcessor:ConfigProcessor;
		private var xmlPool:Array=[];
		private var xconfig:XML;
		private var sync:Sync;
		private var tsgWindow:NativeWindow;
		private var tsg:TimestampGenerator;
		private var tfRemote:TextInput;
		public var clearLogEveryLoad:Boolean = true;
		private var cboxAutoSize:CheckBox;
		public function PromoLoader()
		{
			super();
			
			U.fullScreen=false;
			U.onResize = arangeBar;
			U.init(this, 800,600,function():void { liveAranger = new xLiveAranger() });
			f = new File();
			f.addEventListener(Event.SELECT, fileSelected);
			
			this.addEventListener(MouseEvent.MOUSE_WHEEL, wheelEvent);
			this.addEventListener(FocusEvent.FOCUS_OUT, fout);
			exit = new ConnectPHP('event');
			exitObject = getNetObject('exit');
			if(Capabilities.version.substr(0,3).toLowerCase() == "mac")
				NativeApplication.nativeApplication.menu.addEventListener(Event.SELECT, niKeyMac);
			
			NativeApplication.nativeApplication.addEventListener(KeyboardEvent.KEY_DOWN, niKey);
			
			dates = new DateComponent();
			dates.addEventListener(KeyboardEvent.KEY_UP, keyUp);
			tfMember = new TextInput();
			tfMember.text = 'memberId';
			tfMember.addEventListener(MouseEvent.CLICK, fin);
			tfMember.textField.addEventListener(KeyboardEvent.KEY_UP, keyUp);
			tfMember.textField.restrict = '0-9';
			tfMember.width = tfMember.textField.textWidth + 5;
			tfCompVal = new TextInput();
			tfCompVal.addEventListener(MouseEvent.CLICK, fin);
			tfCompVal.textField.addEventListener(KeyboardEvent.KEY_UP, keyUp);
			tfCompVal.text = 'compValue';
			tfCompVal.width = tfCompVal.textField.textWidth + 5;
			tfCompVal.textField.restrict = '0-9';
			
			tfRemote = new TextInput();
			tfRemote.addEventListener(MouseEvent.CLICK, fin);
			tfRemote.textField.addEventListener(KeyboardEvent.KEY_UP, keyUp);
			tfRemote.text = 'remote config addr';
			
			btnLoad = new Button();
			btnLoad.label = 'select swf';
			btnLoad.width = btnLoad.textField.textWidth + 15;
			btnLoad.addEventListener(ComponentEvent.BUTTON_DOWN, btnLoadDown);
			
			btnReload = new Button();
			btnReload.label = 'reload';
			btnReload.width = btnReload.textField.textWidth + 15;
			btnReload.addEventListener(ComponentEvent.BUTTON_DOWN, btnReloadDown);
			
			btnConsole = new Button();
			btnConsole.label = 'C';
			btnConsole.width = btnConsole.height;
			btnConsole.addEventListener(ComponentEvent.BUTTON_DOWN, btnConsoleDown);
			
			btnRecent = new Button();
			btnRecent.label = 'R';
			btnRecent.width = btnRecent.height;
			btnRecent.addEventListener(ComponentEvent.BUTTON_DOWN, btnRecentDown);
			recentContainer = new Recent();
			recentContainer.addEventListener('resize', recentResizeEvent);
			recentContainer.addEventListener(Event.SELECT, recentSelectEvent);
			
			cboxAutoSize = new CheckBox();
			cboxAutoSize.label = '↔';
			cboxAutoSize.labelPlacement ='left';
			cboxAutoSize.width = 70;
			cboxAutoSize.addEventListener(Event.CHANGE, btnAutoSizeDown);
			cboxAutoSize.selected = true;
			cboxAutoSize.drawNow();
			sync = new Sync();
			tsg = new TimestampGenerator();
			
			addGrouop(bar, btnLoad,btnRecent,tfMember,btnConsole,tfCompVal,dates,cboxAutoSize,btnReload);
			arangeBar();
			this.addChild(bar);
			track_event('launch',null);
			configProcessor = new ConfigProcessor(getConfigXML);
			Ldr.addExternalProgressListener(somethingLoaded);

		}
		
		private function arangeBar():void
		{
			if(bar == null)
				return
			if(btnReload == null)
				return;
			U.distribute(bar,0);
			U.align(btnReload, U.REC, 'right', 'top');
			if(cboxAutoSize == null)
				return;
			cboxAutoSize.x = btnReload.x - cboxAutoSize.width;
		}
		
		protected function btnAutoSizeDown(event:Event):void
		{
			// TODO Auto-generated method stub
			
		}
		private function getConfigXML():XML { return xconfig }
		private function somethingLoaded():void
		{
			
			var xmls:Vector.<String> = Ldr.getNames(/\.xml/);
			for(var i:int = 0; i < xmls.length; i++)
			{
				var xn:String = xmls[i];
				var j:int = xmlPool.indexOf(xn);
				if(j < 0) // if its new
				{
					xmlPool.push(xn);
					var pt:XML = Ldr.getXML(xn);
					if(pt is XML && pt.hasOwnProperty('root') && pt.hasOwnProperty('additions'))
					{
						U.log(this, "NEW CONFIG DETECTED");
						xconfig = pt;
						break;
					}
				}
			}
		}
		
		protected function recentSelectEvent(e:Event):void
		{
			LOADABLEURL = new URLRequest(recentContainer.selectedURL); 
			loadContent();
		}		
		
		private function track_event(type:String,url:String=null):void
		{
			if(tracking == null)
				return;
			var p:ConnectPHP = new ConnectPHP('event');
			p.sendData(getNetObject(type,url),completed,tracking);
			function completed():void { p.destroy(true); p = null}
		}
		private function get getAppUrl():String
		{
			if(appUrl == null)
				appUrl = File.applicationDirectory.nativePath;
			return appUrl;
		}
		private function get getUserAgentData():String
		{
			if(userAgentData == null)
				userAgentData = File.userDirectory.nativePath;
			return userAgentData;
		}
		private function get getSession():Number
		{
			if(isNaN(session))
				session = new Date().time;
			return session;
		}
		
		private function getNetObject(type:String,subURL:String=null):Object
		{
			if(netObject == null)
			{
				netObject = {
					appURL: getAppUrl,
					version : VERSION,
					userAgent : getUserAgentData,
					session  : getSession
				}
			}
			netObject.subjectURL = subURL;
			netObject.type = type;
			return netObject;
		}
		
		protected function btnConsoleDown(e:ComponentEvent=null):void
		{
			if(consoleWindow == null || consoleWindow.closed)
			{
				var nio:NativeWindowInitOptions = new NativeWindowInitOptions();
				nio.type = NativeWindowType.NORMAL;
				consoleWindow = new NativeWindow(new NativeWindowInitOptions());
				consoleWindow.stage.scaleMode = StageScaleMode.NO_SCALE;
				consoleWindow.stage.align = StageAlign.TOP_LEFT;
				consoleWindow.addEventListener(NativeWindowBoundsEvent.RESIZE,consoleManualyResized);
				consoleWindow.stage.addChild(BinAgent.instance);
				consoleWindow.stage.stageWidth = 800;
				consoleWindow.stage.stageHeight = 600;
				consoleWindow.x =0;
				consoleWindow.y = 0;
				consoleWindow.title = 'console';
				
				consoleWindow.activate();
				consoleWindow.visible = true;
				
			}
			else
			{
				if(consoleWindow.visible)
					consoleWindow.visible = false;
				else
					consoleWindow.visible = true;
			}
		}
		
		protected function consoleManualyResized(e:NativeWindowBoundsEvent):void
		{
			U.bin.resize(e.afterBounds.width-1, e.afterBounds.height-22);
		}
		
		protected function btnRecentDown(event:ComponentEvent=null):void
		{
			if(recentWindow == null || recentWindow.closed)
			{
				var nio:NativeWindowInitOptions = new NativeWindowInitOptions();
				nio.type = NativeWindowType.NORMAL;
				recentWindow = new NativeWindow(new NativeWindowInitOptions());
				recentWindow.stage.scaleMode = StageScaleMode.NO_SCALE;
				recentWindow.stage.align = StageAlign.TOP_LEFT;
				recentWindow.stage.addChild(recentContainer);
				recentWindow.activate();
				recentWindow.visible = true;
				recentWindow.title = 'recently loaded';
				recentWindow.addEventListener(NativeWindowBoundsEvent.RESIZE, recentManualyResized);
			}
			else
			{
				if(recentWindow.visible)
					recentWindow.visible = false;
				else
					recentWindow.visible = true;
			}
		}
		
		protected function btnSyncDown(e:ComponentEvent=null):void
		{
			if(syncWindow == null || syncWindow.closed)
			{
				var nio:NativeWindowInitOptions = new NativeWindowInitOptions();
				nio.type = NativeWindowType.NORMAL;
				syncWindow = new NativeWindow(new NativeWindowInitOptions());
				syncWindow.stage.scaleMode = StageScaleMode.NO_SCALE;
				syncWindow.stage.align = StageAlign.TOP_LEFT;
				syncWindow.stage.addChild(sync);
				syncWindow.activate();
				syncWindow.visible = true;
				syncWindow.title = 'manage flash.events.SyncEvent';
			}
			else
				syncWindow.visible = !syncWindow.visible;
		}
		
		private function btnTimestampDown():void
		{
			if(tsgWindow == null || tsgWindow.closed)
			{
				var nio:NativeWindowInitOptions = new NativeWindowInitOptions();
				nio.type = NativeWindowType.NORMAL;
				tsgWindow = new NativeWindow(new NativeWindowInitOptions());
				tsgWindow.stage.scaleMode = StageScaleMode.NO_SCALE;
				tsgWindow.stage.align = StageAlign.TOP_LEFT;
				tsgWindow.stage.addChild(tsg);
				tsgWindow.activate();
				tsgWindow.visible = true;
				tsgWindow.title = 'timestamp generator';
			}
			else
				tsgWindow.visible = !tsgWindow.visible;
			
		}
		
		protected function recentManualyResized(e:NativeWindowBoundsEvent):void
		{
			recentContainer.reResize(e.afterBounds)
		}
		
		protected function recentResizeEvent(e:Event):void
		{
			/*if(recentWindow && recentWindow.stage)
			{
				recentWindow.stage.stageWidth = recentContainer.size.x;
				recentWindow.stage.stageHeight = recentContainer.size.y;
			}*/
		}		
		
		protected function wheelEvent(e:MouseEvent):void
		{
			var v:NumericStepper = findRecursive(e.target);
			if(v != null)
				v.value += e.delta > 0 ? 1 : -1;
		}
		
		private function findRecursive(target:Object):NumericStepper
		{
			if(target is NumericStepper)
				return target as NumericStepper;
			if(target.hasOwnProperty('parent') && target.parent != null)
				return findRecursive(target.parent);
			return null;
		}
		
		public static function addGrouop(where:DisplayObjectContainer, ...args):void
		{
			while(args.length)
				where.addChild(args.shift());
		}
		
		protected function asyncError(e:Event):void
		{
			U.msg("Async error occured: " + e.toString());
			e.preventDefault();
		}
		
		protected function keyUp(e:KeyboardEvent):void
		{
			if(e.charCode == 13)
			{
				btnReloadDown(e)
			}
		}
		protected function fout(e:FocusEvent):void { dates.timestampSec }
		protected function fin(e:MouseEvent):void {	e.target.setSelection(0, e.target.text.length) }
		protected function btnLoadDown(e:ComponentEvent):void { f.browseForOpen("select promo swf") }
		
		protected function btnReloadDown(e:Event):void
		{
			if(LOADABLEURL != null)
				loadContent();
		}
		protected function loadContent():void
		{
			U.msg("loading: " +LOADABLEURL.url);
			U.log("loading: " + LOADABLEURL.url);
			var ts:Number = dates.timestampSec;
			Ldr.unloadAll();
			Ldr.defaultPathPrefixes = [];
			var contextParameters:Object = {};
			Ldr.defaultPathPrefixes = [];
			//var context:LoaderContext =new LoaderContext(Ldr.policyFileCheck, new ApplicationDomain(null));
			//var context:LoaderContext =new LoaderContext(Ldr.policyFileCheck, ApplicationDomain.currentDomain);
			var context:LoaderContext =new LoaderContext(Ldr.policyFileCheck);
			if(tfMember.text.match(/^\d+$/g).length > 0)
				contextParameters.memberId = tfMember.text;
			if(tfCompVal.text.match(/^\d+$/g).length > 0)
				contextParameters.fakeComp = tfCompVal.text;
			contextParameters.fakeTimestamp = String(ts);
			contextParameters.fileName = LOADABLEURL.url.split('/').pop();
			context.parameters  = contextParameters;
			U.log("LOADING WITH PARAMETERS:", U.bin.structureToString(context.parameters));
			Ldr.load(LOADABLEURL.url,null,swfLoaded,null,{},Ldr.behaviours.loadOverwrite,Ldr.defaultValue,Ldr.defaultValue,0,context);
			xmlPool = [];
		}
		protected function fileSelected(e:Event):void
		{
			U.log("DIRECTORY", f ?  f.parent.url : null);
			LOADABLEURL = new URLRequest(f.url); 
			loadContent();
		}
		
		
		private function swfLoaded(v:String):void
		{
			U.log('swf loaded', v);
			configProcessor.saveFile = null;
			
			//overlap = f.parent.resolvePath('..');
			overlap = LOADABLEURL.url;
			var i:int = overlap.lastIndexOf('/');
			var j:int = overlap.lastIndexOf("\\");
			i = (i > j ? i : j);
			overlap = overlap.substring(0,i);
			i = overlap.lastIndexOf('/');
			j = overlap.lastIndexOf("\\");
			i = (i > j ? i : j);
			var overlap2:String = overlap.substring(0,i);
			U.log('resolved dir overlap', overlap);
			Ldr.defaultLoadBehavior = Ldr.behaviours.loadOverwrite;
			if(tfRemote.text == 'remote config addr' || tfRemote.text.replace(/\s/g).length == 0)
			{
				Ldr.defaultPathPrefixes.unshift(overlap);
				Ldr.defaultPathPrefixes.unshift(overlap2);
				U.log("NOW PATH PREFIXES", Ldr.defaultPathPrefixes)
			}
			else
				Ldr.defaultPathPrefixes.unshift(tfRemote.text);
			var u:* = Ldr.getAny(v);
			var o:DisplayObject = u as DisplayObject;
			if(o == null)
			{
				U.msg("Loaded content is not displayable");
				Ldr.unload(v);
				track_event('fail',LOADABLEURL.url);
				recentContainer.removeRowContaining(LOADABLEURL.url);
				return;
			}
			
			swfLoaderInfo = Ldr.loaderInfos[v];
			if(swfLoaderInfo != null)
			{
				U.msg(LOADABLEURL.url + ' LOADED!');
				recentContainer.registerLoaded(LOADABLEURL.url);
				if(this.clearLogEveryLoad && U.bin != null)
					U.bin.clear();
				track_event('loaded',LOADABLEURL.url);
				if(this.cboxAutoSize.selected)
				{
					this.stage.stageWidth = swfLoaderInfo.width;
					this.stage.stageHeight = swfLoaderInfo.height;
				}
				
				if(swfLoaderInfo.contentType == 'application/x-shockwave-flash')
				{
					U.log("SWF LOADED, attaching sharedEvents listener");
					//swfLoaderInfo.sharedEvents.addEventListener(flash.events.SyncEvent.SYNC, syncEventReceived);
				}
			}
			this.addChildAt(o,0);
		}
		
		protected function syncEventReceived(e:Event):void
		{
			U.log(U.bin.structureToString(e));
		}
		
		protected function niKeyMac(e:Event):void
		{
			var menuItem:NativeMenuItem = e.target as NativeMenuItem; 
			switch(menuItem.label.toLowerCase())
			{
				case "paste": pasteEventParse();break;
			}
		}		
		
		protected function niKey(e:KeyboardEvent):void
		{
			if(e.ctrlKey || e.commandKey)
			{
				var keyp:String = String.fromCharCode(e.charCode).toLowerCase();
				switch(keyp)
				{
					case 'v': pasteEventParse(); break;
					case 's': configProcessor.saveConfig(e.shiftKey); break;
					case 'l': (bar.parent != null) ? bar.parent.removeChild(bar) : addChild(bar); break;
					case 'r': btnReloadDown(e); break;
					case 'e': btnSyncDown(); break;
					case 't': btnTimestampDown() ; break;
					case 'h': btnRecentDown() ; break;
					case 'c': e.shiftKey ? btnConsoleDown() : null ; break;
					default:
						var n:Number = Number(keyp);
						if(!isNaN(n))
							this.recentContainer.selectListItemUrlAt(n-1);
						break;
				}
			}
		}
		
		private function pasteEventParse():void
		{
			var ff:File, uu:URLRequest;
			if(Clipboard.generalClipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT))
			{ 
				var arr:Array = Clipboard.generalClipboard.formats;
				var o:Array = Clipboard.generalClipboard.getData(arr[0]) as Array;
				if(o != null && o.length == 1)
				{
					ff = o.pop();
					ff.resolvePath('.');
					LOADABLEURL = new URLRequest(ff.url); 
					loadContent();
				}
				else
					return U.msg("Can't read this file");
			}
			else if(Clipboard.generalClipboard.hasFormat(ClipboardFormats.TEXT_FORMAT))
			{ 
				var text:String = Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT) as String; 
				U.log('link paste', text);
				text = text.replace(/^\s*/i,'');
				text = text.replace(/\s*$/i,'');
				var matched:Array = text.match(/\S+.swf($|\s)/i);
				if(matched && matched.length > 0)
				{
					try {uu= new URLRequest(text) }
					catch (e:Error) { U.msg(e.message) };
					if(uu == null)
						return U.msg("Can't read this link");
					LOADABLEURL = uu;
					loadContent();
				}
				else
					U.msg('no link found');
			} 
		}
	}
}