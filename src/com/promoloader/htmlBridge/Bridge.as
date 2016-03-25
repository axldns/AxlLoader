package com.promoloader.htmlBridge
{
	
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.external.ExternalInterface;
	import flash.text.TextField;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	import axl.ui.controllers.BoundBox;
	import axl.utils.LibraryLoader;
	import axl.utils.LiveAranger;
	import axl.utils.NetworkSettings;
	import axl.utils.U;
	import axl.utils.binAgent.BinAgent;
	
	public class Bridge extends Sprite
	{
		public static const version:String = '0.11';
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
			U.bin =  new BinAgent(this);
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
				U.bin.externalTrace = logToConsole;
				ExternalInterface.addCallback('bridgeAPI', onIncomingMessage);
				ExternalInterface.call("init");
			}
			else
			{
				U.log(tname, "ExternalInterface not available");
			}
		}
		
		private function logToConsole(v:String):void
		{
			try { ExternalInterface.call("console.log", v); }
			catch(e:*)
			{
				
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
				ExternalInterface.call('api_promoloader.message', s);
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
		
		
		
		private function setupLoader(url:String,params:Object=null):void
		{
			U.log(tname,"[setupLoader]:",url, params);
			loadParamsFromJS = ExternalInterface.call('getBridgeLoadingParams');
			if(params && params is String)
			{
				U.log(tname, "converting string params to object");
				params = JSON.parse(params as String);
			}
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
		
		public function bridge_load(v:String, params:Object=null):void
		{
			setupLoader(v,params);
			load(v);
		}
	}
}
