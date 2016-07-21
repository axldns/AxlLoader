package com.axlloader.nativeWindows
{
	import flash.events.NativeWindowBoundsEvent;

	public class WindowParameters extends CoreWindow
	{
		public function WindowParameters(windowTitle:String)
		{
			super(windowTitle);
		}
		
		override protected function onWindowCreated():void
		{
			window.addEventListener(NativeWindowBoundsEvent.RESIZE,consoleManualyResized);
			window.stage.stageWidth = 400;
			window.stage.stageHeight = 600;
		}
		
		protected function consoleManualyResized(event:NativeWindowBoundsEvent):void
		{
			// TODO Auto-generated method stub
			
		}
	}
}