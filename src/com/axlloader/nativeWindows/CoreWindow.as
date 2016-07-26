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
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowType;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	
	public class CoreWindow extends Sprite
	{
		private var xwindow:NativeWindow;
		private var wop:NativeWindowInitOptions;
		public var title:String;
		private var content:DisplayObject;
		
		public function CoreWindow(windowTitle:String)
		{
			title = windowTitle;
			setInitialContent(this);
			super();
		}
		protected function setInitialContent(v:DisplayObject):void { content = this }
		
		public function wappear():void
		{
			if(window == null || window.closed)
			{
				if(wop == null)
					wop = new NativeWindowInitOptions();
				wop.type = NativeWindowType.NORMAL;
				xwindow = new NativeWindow(new NativeWindowInitOptions());
				window.stage.scaleMode = StageScaleMode.NO_SCALE;
				window.stage.align = StageAlign.TOP_LEFT;
				window.stage.addChild(content);
				window.activate();
				window.visible = true;
				window.title = title || '';
				onWindowCreated();
			}
			else
				window.visible = !window.visible;
		}
		
		protected function onWindowCreated():void
		{
			// TODO Auto Generated method stub
			
		}
		
		public function wclose():void
		{
			
		}

		public function get window():NativeWindow
		{
			return xwindow;
		}
	}
}