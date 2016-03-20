package com.promoloader.nativeWindows
{
	import flash.display.DisplayObject;
	import flash.events.NativeWindowBoundsEvent;
	import com.promoloader.core.PromoLoader;
	

	public class WindowConsole extends WindowOwner
	{
		public function WindowConsole(windowTitle:String)
		{
			super(windowTitle);
		}
		
		override protected function setInitialContent(v:DisplayObject):void
		{
			super.setInitialContent(PromoLoader.classDict.BinAgent.instance);
		}
		
		override protected function onWindowCreated():void
		{
			window.addEventListener(NativeWindowBoundsEvent.RESIZE,consoleManualyResized);
			window.stage.stageWidth = 800;
			window.stage.stageHeight = 600;
		}
		
		override public function wappear():void
		{
			super.wappear();
			var bi:* = PromoLoader.classDict.BinAgent.instance;
			if(bi && window && window.stage && !window.stage.contains(bi))
			{
				bi.allowKeyboardOpen = false;
				bi.allowGestureOpen = false;
				bi.autoResize = false;
				window.stage.addChild(PromoLoader.classDict.BinAgent.instance);
			}
		}
		
		protected function consoleManualyResized(e:NativeWindowBoundsEvent=null):void
		{
			PromoLoader.classDict.U.bin.resize( window.stage.stageWidth-1,window.stage.stageHeight-1);
		}
	}
}