package
{
	import flash.display.DisplayObject;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.external.ExternalInterface;
	import flash.system.LoaderContext;
	import flash.text.TextField;
	import flash.utils.setTimeout;
	
	import axl.utils.Ldr;
	import axl.utils.LiveAranger;
	import axl.utils.U;
	import axl.utils.binAgent.BinAgent;
	
	public class Bridge extends Sprite
	{
		private var t:TextField;
		private var swfLoaderInfo:LoaderInfo;
		public function Bridge()
		{
			super();
			var b:BinAgent = new BinAgent(this);
			b.externalTrace = function(s:String):void { 
				if(ExternalInterface.available)
				{
					ExternalInterface.call("console.log", s);
				}
			}
			t= new TextField();
			t.text = 'bridge 0.1';
			this.graphics.beginFill(0xff0ff0);
			this.graphics.drawRect(0,0,100,100);
			this.addChild(t);
			U.log("[Bridge]WELCOME BRIDGE API");
			if(ExternalInterface.available)
				ExternalInterface.addCallback('bridgeAPI', apiInterpreter);
			if(ExternalInterface.available)
				ExternalInterface.addCallback('bridgeMessage', messageInc);
			flash.utils.setTimeout(makeReady,20);
			U.init(this,800,600, onReady);
			
		}
		
		private function onReady():void	{ new LiveAranger() }
		
		private function messageInc(...args):void
		{
			t.text = String(args.shift());
		}
		
		private function makeReady():void
		{
			if(ExternalInterface.available)
			{
				ExternalInterface.call('promoloaderAPI.message', '[Bridge][ready]');
				t.text = 'ready';
			}
		}
		
		private function apiInterpreter(...args):void
		{
			var type:String = args.shift();
			var f:Function = this[type] as Function;
			if(f == null)
			{
				U.log("[Bridge] invalid api call: "+ type);
			}
			else
			{
				f.apply(null, args);
			}
		}
		public function loadSwf(v:String, params:String):void
		{
			U.log("[Bridge][loadSwf]:",v,params);
			var ctx:LoaderContext = new LoaderContext();
			var par:Object = JSON.parse(params);
			ctx.parameters = par;
			Ldr.load(v,complete,null,null,Ldr.defaultValue,Ldr.defaultValue,Ldr.defaultValue,Ldr.defaultValue,0,ctx);
			function complete():void
			{
				var fn:String = U.fileNameFromUrl(v);
				var obj:DisplayObject = Ldr.getAny(fn) as DisplayObject;
				U.log("[Bridge]LOADED:" + fn, 'AS:', String(obj));
				if(obj is DisplayObject)
				{
					U.log("[Bridge]ADDING TO dl",obj);
					addChild(obj);
					swfLoaderInfo = Ldr.loaderInfos[v];
					var dims:Object = {w:swfLoaderInfo.width, h:swfLoaderInfo.height};
					
					stage.stageWidth = dims.w;
					stage.stageHeight = dims.h;
					ExternalInterface.call('promoloaderAPI.message', "dimensions", JSON.stringify(dims));
				}
			}
		}
		
		public function openAgent(v:Boolean):void
		{
			U.log("[Bridge][openAgent]:",v);
			U.bin.isOpen = v;
		}
		
	}
}