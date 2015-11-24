package nativeWindows
{
	import flash.display.DisplayObject;
	import flash.events.NativeWindowBoundsEvent;
	
	import axl.utils.U;
	import axl.utils.binAgent.BinAgent;

	public class WindowConsole extends WindowOwner
	{
		public function WindowConsole(windowTitle:String)
		{
			super(windowTitle);
		}
		
		override protected function setInitialContent(v:DisplayObject):void
		{
			super.setInitialContent(axl.utils.binAgent.BinAgent.instance);
		}
		
		override protected function onWindowCreated():void
		{
			window.stage.addChild(BinAgent.instance);
			window.addEventListener(NativeWindowBoundsEvent.RESIZE,consoleManualyResized);
			window.stage.stageWidth = 800;
			window.stage.stageHeight = 600;
		}
		
		
		
		protected function consoleManualyResized(e:NativeWindowBoundsEvent=null):void
		{
			U.bin.resize(e.afterBounds.width-1, e.afterBounds.height-22);
		}
	}
}