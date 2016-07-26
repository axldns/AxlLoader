/**
 *
 * AxlLoader
 * Copyright 2015-2016 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package com.axlloader.nativeWindows
{
	import flash.display.DisplayObject;
	import flash.events.NativeWindowBoundsEvent;
	import com.axlloader.core.AxlLoader;
	

	public class WindowConsole extends CoreWindow
	{
		public function WindowConsole(windowTitle:String)
		{
			super(windowTitle);
		}
		
		override protected function setInitialContent(v:DisplayObject):void
		{
			super.setInitialContent(AxlLoader.classDict.BinAgent.instance);
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
			var bi:* = AxlLoader.classDict.BinAgent.instance;
			if(bi && window && window.stage && !window.stage.contains(bi))
			{
				bi.allowKeyboardOpen = false;
				bi.allowGestureOpen = false;
				bi.autoResize = false;
				window.stage.addChild(AxlLoader.classDict.BinAgent.instance);
			}
		}
		
		protected function consoleManualyResized(e:NativeWindowBoundsEvent=null):void
		{
			AxlLoader.classDict.U.bin.resize( window.stage.stageWidth-1,window.stage.stageHeight-1);
		}
	}
}