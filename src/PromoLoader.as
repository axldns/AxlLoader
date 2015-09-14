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
	import flash.net.SharedObject;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.Capabilities;
	import flash.system.LoaderContext;
	import flash.text.TextField;
	
	import axl.utils.ConnectPHP;
	import axl.utils.Ldr;
	import axl.utils.LiveAranger;
	import axl.utils.Req;
	import axl.utils.U;
	import axl.utils.binAgent.BinAgent;
	
	import fl.controls.BaseButton;
	import fl.controls.Button;
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
		//private var tfTimestamp:TextInput;
		private var tfRemote:TextInput;
		private var bar:Sprite = new Sprite();
		private var dates:Sprite = new Sprite();
		private var yyyy:NumericStepper;
		private var time:Date;
		private var mm:NumericStepper;
		private var dd:NumericStepper;
		private var hh:NumericStepper;
		private var min:NumericStepper;
		private var sec:NumericStepper;
		private var liveAranger:LiveAranger;
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
		private var cookie:SharedObject;
		private var btnRecent:Button;
		private var recentWindow:NativeWindow;
		private var recentContainer:Recent;
		public function PromoLoader()
		{
			super();
			cookie = SharedObject.getLocal('recent');
			if(!(cookie.data.recent is Array))
				cookie.data.recent = [];
			U.fullScreen=false;
			U.init(this, 800,600,function():void { liveAranger = new LiveAranger() });
			f = new File();
			f.addEventListener(Event.SELECT, fileSelected);
			
			this.addEventListener(MouseEvent.MOUSE_WHEEL, wheelEvent);
			this.addEventListener(FocusEvent.FOCUS_OUT, fout);
			exit = new ConnectPHP('event');
			exitObject = getNetObject('exit');
			if(Capabilities.version.substr(0,3).toLowerCase() == "mac")
				NativeApplication.nativeApplication.menu.addEventListener(Event.SELECT, niKeyMac);
			else
				NativeApplication.nativeApplication.addEventListener(KeyboardEvent.KEY_DOWN, niKey);
		
			dates.addEventListener(KeyboardEvent.KEY_UP, keyUp);
			tfMember = new TextInput();
			tfMember.text = 'memberId';
			tfMember.addEventListener(MouseEvent.CLICK, fin);
			tfMember.textField.addEventListener(KeyboardEvent.KEY_UP, keyUp);
			tfMember.textField.restrict = '0-9';
			tfMember.width = tfMember.textField.textWidth + 15;
			tfCompVal = new TextInput();
			tfCompVal.addEventListener(MouseEvent.CLICK, fin);
			tfCompVal.textField.addEventListener(KeyboardEvent.KEY_UP, keyUp);
			tfCompVal.text = 'comp value';
			tfCompVal.width = tfCompVal.textField.textWidth + 15;
			tfCompVal.textField.restrict = '0-9';
			
			
			time = new Date();
			yyyy = new NumericStepper();
			yyyy.maximum = 2020;
			yyyy.minimum = 2010;
			yyyy.value = time.getUTCFullYear();
			yyyy.width = 40;
			yyyy.textField.restrict = '0-9';
			yyyy.textField.maxChars = 4;
			
			mm = new NumericStepper();
			mm.minimum=1;
			mm.maximum=12;
			mm.value = time.getUTCMonth() + 1;
			mm.width = 30;
			mm.textField.restrict = '0-9';
			mm.textField.maxChars = 4;
			
			dd = new NumericStepper();
			dd.minimum = 1;
			dd.maximum = 31;
			dd.value = time.getUTCDate();
			dd.textField.restrict = '0-9';
			dd.textField.maxChars = 2;
			dd.width = 30;
			var tf:TextField = new TextField();
			tf.defaultTextFormat = dd.textField.textField.defaultTextFormat;
			tf.text = '-';
			tf.width = tf.textWidth+5;
			hh = new NumericStepper();
			hh.minimum = 0;
			hh.maximum = 23;
			hh.value = time.getUTCHours();
			hh.textField.restrict = '0-9';
			hh.textField.maxChars = 2;
			hh.width = 30;
			
			min = new NumericStepper();
			min.minimum = 0;
			min.maximum = 59;
			min.value = time.getUTCMinutes();
			min.textField.restrict = '0-9';
			min.textField.maxChars = 2;
			min.width = 30;
			
			sec = new NumericStepper();
			sec.minimum = 0;
			sec.maximum = 59;
			sec.value = time.getUTCSeconds();
			sec.textField.restrict = '0-9';
			sec.textField.maxChars = 2;
			sec.width = 30;
			this.sizeStepperButtons([yyyy,mm,dd,hh,min,sec])
			
			tfRemote = new TextInput();
			tfRemote.addEventListener(MouseEvent.CLICK, fin);
			tfRemote.textField.addEventListener(KeyboardEvent.KEY_UP, keyUp);
			tfRemote.text = 'remote config addr';
			
			btnLoad = new Button();
			btnLoad.label = 'select swf';
			btnLoad.width = btnLoad.textField.textWidth + 25;
			btnLoad.addEventListener(ComponentEvent.BUTTON_DOWN, btnLoadDown);
			
			btnReload = new Button();
			btnReload.label = 'reload';
			btnReload.width = btnReload.textField.textWidth + 25;
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
			updateRecentList();
			
			this.addGrouop(dates,yyyy,mm,dd,tf,hh,min,sec);
			U.distribute(dates,0);
			this.addGrouop(bar, btnLoad,btnRecent,tfMember,btnConsole,tfCompVal,dates,btnReload);
			U.distribute(bar,0);
			U.align(btnReload, U.REC, 'right', 'top');
			fakeDateFetch();
			this.addChild(bar);
			track_event('launch',null);
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
		
		protected function btnConsoleDown(e:ComponentEvent):void
		{
			if(consoleWindow == null || consoleWindow.closed)
			{
				var nio:NativeWindowInitOptions = new NativeWindowInitOptions();
				nio.type = NativeWindowType.NORMAL;
				consoleWindow = new NativeWindow(new NativeWindowInitOptions());
				consoleWindow.stage.scaleMode = StageScaleMode.NO_SCALE;
				consoleWindow.stage.align = StageAlign.TOP_LEFT;
				consoleWindow.stage.stageWidth = 800;
				consoleWindow.stage.stageHeight = 600;
				consoleWindow.x =0;
				consoleWindow.y = 0;
				consoleWindow.title = 'console';
				consoleWindow.stage.addChild(BinAgent.instance);
				U.bin.resize(800,600);
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
		
		protected function btnRecentDown(event:ComponentEvent):void
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
		
		private function addGrouop(where:DisplayObjectContainer, ...args):void
		{
			while(args.length)
				where.addChild(args.shift());
		}
		
		private function sizeStepperButtons(v:Array, wid:Number=10):void{
			for(var j:int =0; j < v.length; j++)
				for(var i:int = 0; i < v[j].numChildren; i++)
					if( v[j].getChildAt(i) is BaseButton)
						v[j].getChildAt(i).width = wid;
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
		protected function fout(e:FocusEvent):void {fakeDateFetch() }
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
			var ts:Number = fakeDateFetch();
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
			if(tfRemote.text != 'remote config addr')
				contextParameters.remote = tfRemote.text;
			contextParameters.fileName = LOADABLEURL.url.split('/').pop();
			context.parameters  = contextParameters;
			U.log("LOADING WITH PARAMETERS:", U.bin.structureToString(context.parameters));
			Ldr.load(LOADABLEURL.url,null,swfLoaded,null,{},Ldr.behaviours.loadOverwrite,Ldr.defaultValue,Ldr.defaultValue,0,context);
		}
		protected function fileSelected(e:Event):void
		{
			U.log("DIRECTORY", f ?  f.parent.url : null);
			LOADABLEURL = new URLRequest(f.url); 
			loadContent();
		}
		
		private function fakeDateFetch():Number
		{
			var d:Date = new Date(yyyy.value, mm.value -1, dd.value, hh.value, min.value, sec.value);
			d.minutes -= d.getTimezoneOffset();
			yyyy.value = d.getUTCFullYear();
			mm.value = d.getUTCMonth() +1;
			dd.value =d.getUTCDate();
			hh.value = d.getUTCHours();
			min.value = d.getUTCMinutes();
			sec.value =d.getUTCSeconds();
			
			return Math.round(d.getTime()/1000);
		}
		private function swfLoaded(v:String):void
		{
			U.log('swf loaded', v);
			
			//overlap = f.parent.resolvePath('..');
			overlap = LOADABLEURL.url;
			var i:int = overlap.lastIndexOf('/');
			var j:int = overlap.lastIndexOf("\\");
			i = (i > j ? i : j);
			overlap = overlap.substring(0,i);
			i = overlap.lastIndexOf('/');
			j = overlap.lastIndexOf("\\");
			i = (i > j ? i : j);
			overlap = overlap.substring(0,i);
			U.log('resolved dir overlap', overlap);
			Ldr.defaultLoadBehavior = Ldr.behaviours.loadOverwrite;
			if(tfRemote.text == 'remote config addr' || tfRemote.text.replace(/\s/g).length == 0)
			{
				Ldr.defaultPathPrefixes.unshift(overlap);
				U.log("NOW PATH PREFIXES", Ldr.defaultPathPrefixes)
			}
			else
				Ldr.defaultPathPrefixes.unshift(tfRemote.text);
			var u:* = Ldr.getAny(v);
			var o:DisplayObject = u  as DisplayObject;
			if(o == null)
			{
				U.msg("Loaded content is not displayable");
				Ldr.unload(v);
				track_event('fail',LOADABLEURL.url);
				i = cookie.data.recent.indexOf(LOADABLEURL.url);
				if(i > -1)
					cookie.data.recent.shift(i,1);
			}
			
			swfLoaderInfo = Ldr.loaderInfos[v];
			if(swfLoaderInfo != null)
			{
				U.msg(LOADABLEURL.url + ' LOADED!');
				i = cookie.data.recent.indexOf(LOADABLEURL.url);
				if(i < 0)
					cookie.data.recent.push(LOADABLEURL.url);
				else
					cookie.data.recent.unshift(cookie.data.recent.splice(i,1)[0]);
				cookie.flush();
				updateRecentList();
				track_event('loaded',LOADABLEURL.url);
				this.stage.stageWidth = swfLoaderInfo.width;
				this.stage.stageHeight = swfLoaderInfo.height;
			}
			this.addChildAt(o,0);
			U.align(btnReload, U.REC, 'right', 'top');
			
			
			this.addChild(bar);
		}
		
		private function updateRecentList():void
		{
			recentContainer.reRead(cookie.data.recent);
		}
		
		//---------------- cpy ----------------- ///
		
		protected function niKeyMac(e:Event):void
		{
			trace(e);
			var menuItem:NativeMenuItem = e.target as NativeMenuItem; 
			
			switch(menuItem.label.toLowerCase())
			{
				case "cut":
				case "copy":
					break;
				case "paste":
					pasteEventParse();
					break;
			}
		}		
		
		protected function niKey(e:KeyboardEvent):void
		{
			if((e.ctrlKey || e.commandKey) && String.fromCharCode(e.charCode).toLowerCase() == 'v')
				pasteEventParse();
		}
		
		private function pasteEventParse():void
		{
			var ff:File, uu:URLRequest;
			if(Clipboard.generalClipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT))
			{ 
				U.log('file paste');
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