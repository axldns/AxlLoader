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
	import com.axlloader.core.AxlLoader;
	
	import flash.events.Event;
	import flash.events.NativeWindowBoundsEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Rectangle;
	import flash.media.StageWebView;

	public class WindowInfo extends CoreWindow
	{
		private var text:String;
		private var margin:Number = 20;
		private var artefactsAddress:String =  AxlLoader.remoteAssetsURL;
		private var htmlFileName:String = 'info.html';
		private var template:String;
		private var U:Class;
		private var swv:StageWebView;
		private var viewPort:Rectangle;
		public function WindowInfo(windowTitle:String)
		{
			super(windowTitle);
			U = AxlLoader.classDict.U;
			swv = new StageWebView();
			addEventListener(Event.ADDED_TO_STAGE,ats);
			load();
		}
		
		protected function ats(e:Event):void
		{
			swv.stage = stage;
			viewPort = new Rectangle(0,0, stage.stageWidth, stage.stageHeight);
		}
		
		override protected function onWindowCreated():void
		{
			window.addEventListener(NativeWindowBoundsEvent.RESIZE,onResize);
			window.stage.stageWidth  = 600;
			window.stage.stageHeight = 300;
		}
		
		override public function wappear():void
		{
			super.wappear();
			if(template)
				swv.loadString(template);
		}
		
		protected function onResize(e:NativeWindowBoundsEvent):void
		{
			viewPort.setTo(0,0,stage.stageWidth, stage.stageHeight);
			swv.viewPort = viewPort;
		}
		
		public function load():void
		{
			
			var f:File = File.applicationStorageDirectory.resolvePath(htmlFileName);
			if(f.exists)
				readTemplate();
			else
				updateArtefacts(readTemplate);
			
			function readTemplate():void
			{
				U.log("read template");
				var fs:FileStream = new FileStream();
				try {
					fs.open(f, FileMode.READ);
					template = fs.readUTFBytes(fs.bytesAvailable);
					U.log("template file read", f.nativePath);
					replaceTemplateVariables();
					onTemplateReady();
				}
				catch(e:Object) {
					U.log("html template could not be read", e);
				}
			}
		}
		
		private function onTemplateReady():void
		{
			U.log("onTemplateReady");
			swv.loadString(template);
		}
		
		public function updateArtefacts(onComplete:Function=null):void
		{
			U.log("updateArtefacts");
			AxlLoader.classDict.Ldr.load([htmlFileName], onComplete,null,null,artefactsAddress,AxlLoader.classDict.Ldr.behaviours.downloadOnly,/.*/);
		}
		
		private function replaceTemplateVariables():void
		{
			
			template = template.replace('{version}', AxlLoader.instance.VERSION);
			template = template.replace(/(\r\n|\n\r|\n|\r)/g, "");
		}
	}
}