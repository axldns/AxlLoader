package
{
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.external.ExternalInterface;
	import flash.text.TextField;
	import flash.utils.clearInterval;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import axl.ui.controllers.BoundBox;
	import axl.utils.LibraryLoader;
	import axl.utils.LiveAranger;
	import axl.utils.NetworkSettings;
	import axl.utils.U;
	import axl.utils.binAgent.BinAgent;
	import flash.display.Loader;
	
	public class Bridge extends Sprite
	{
		public static const version:String = '0.10';
		private var tname:String = '[Bridge ' + version +']';
		private var t:TextField;
		private var swfLoaderInfo:LoaderInfo;
		private var loadParamsFromJS:Object;
		
		public var ll:LibraryLoader;
		private var loaderInfoIntervalId:uint;
		private var content:Loader;
		
		
		public function Bridge()
		{
			super();
			setup();
			U.init(this,800,600,onBridgeReady);
			
		}
		//------------------------------------ INITIAL SETUP ------------------------------- //
		private function setup():void
		{
			U.log(tname,"[SETUP]");
			//project
			NetworkSettings.defaultTimeout = 20000;
			axl.ui.controllers.BoundBox;
			var b:BinAgent = new BinAgent(this);
			b.externalTrace = function(s:String):void { 
				if(ExternalInterface.available)
				{
					ExternalInterface.call("console.log", s);
				}
			}
			//graphics
			t= new TextField();
			t.text = tname;
			this.graphics.beginFill(0xff0ff0);
			this.graphics.drawRect(0,0,100,100);
			this.addChild(t);
			//loader
			ll = new LibraryLoader(this,U.log);
			ll.onReady = swLoaded;
			//api
			if(ExternalInterface.available)
			{
				ExternalInterface.addCallback('bridgeAPI', onIncomingMessage);
				ExternalInterface.marshallExceptions = true;
				U.log(tname, "LOADING PARAMS", b.structureToString(loadParamsFromJS));
			}
		}
		private function onBridgeReady():void
		{
			U.log(tname,"[onBridgeReady]");
			new LiveAranger();
			t.text = tname + 'ready';
			sendToPromoLoader('[Bridge][ready]');
		}
		
		//------------------------------------ COMMUNICATION ------------------------------- //
		
		private function onIncomingMessage(...args):void
		{
			U.log(tname +'[onIncomingMessage]: ' + args)
			var type:String = args.shift();
			var f:Function = this[type] as Function;
			if(f == null)
			{
				U.log(tname,"invalid api call: "+ type);
			}
			else
			{
				f.apply(null, args);
			}
		}
		
		private function sendToPromoLoader(...args):void
		{
			U.log(tname,"[sendToPromoLoader]", args);
			var s:String='';
			for(var i:int = 0, j:int = args.length;i<j;i++)
				s += (args[i] != null ? args[i].toString() : 'null');
			if(ExternalInterface.available)
			{
				ExternalInterface.call('promoloaderAPI.message', s);
			}
		}
		
		private function sendToJS(...args):Object
		{
			U.log(tname,"[sendToJS]", args);
			if(ExternalInterface.available)
			{
				return ExternalInterface.call.apply(null, args);
			}
			return null;
		}
		// ---------------------------------------- SWF LOADING ---------------------------- //
		
	
		
		private function setupLoader(url:String,params:Object):void
		{
			U.log(tname,"[setupLoader]:",url);
			loadParamsFromJS = ExternalInterface.call('getBridgeLoadingParams');
			
			ll.contextParameters = params;
			ll.libraryURLs = [url];
			
			if(loadParamsFromJS)
			{
				U.asignProperties(ll,loadParamsFromJS);
			}
			else
			{
				ll.domainType = 1;
				ll.handleUncaughtErrors = false;
				ll.unloadOnErrors = false;
				ll.stopErrorPropagation = false;
				ll.preventErrorDefaults = false;
				U.asignProperties(ll.contextParameters, this.loaderInfo.parameters);
			}
			U.log(tname,"[setupLoader][CONTEXT]:",U.bin.structureToString(ll.contextParameters));
		}
		
		private function load(v:String):void
		{
			U.log(tname,"[LOAD]");
			ll.load();
		}
		
		private function swLoaded():void
		{
			if(ll.error)
			{
				U.log(tname,"[FAIL!]", ll.libraryURLs);
				sendToJS("bridgeCantTakeIt", ll.libraryURLs[0], ll.contextParameters);
			}
			else
			{
				U.log(tname,"[LOADED!]", ll.libraryURLs);
				content = ll.libraryLoader;
				if(content.loaderInfo == null)
					loaderInfoIntervalId = flash.utils.setInterval(tickForLoaderInfo,20);
				else
					tickForLoaderInfo();
				addChild(content);
			}
		}
		
		private function tickForLoaderInfo():void
		{
			if(content.loaderInfo != null)
			{
				U.log(tname,"[LOADER INFO AVAILABLE!]");
				flash.utils.clearInterval(loaderInfoIntervalId)
				swfLoaderInfo = content.loaderInfo;
				var dims:Object = {w:swfLoaderInfo.width, h:swfLoaderInfo.height};
				
				stage.stageWidth = dims.w;
				stage.stageHeight = dims.h;
				sendToPromoLoader("dimensions", JSON.stringify(dims))
			}
		}
		
		// -------------------------- PUBLIC API ------------------- //
		public function bridge_toggleConsole():void
		{
			U.bin.isOpen = !U.bin.isOpen;
		}
		
		public function bridge_load(v:String, params:Object):void
		{
			setupLoader(v,params);
			load(v);
		}
	}
}