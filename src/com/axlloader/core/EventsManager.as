/**
 *
 * AxlLoader
 * Copyright 2015-2016 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package com.axlloader.core
{
	import com.axlloader.nativeWindows.WindowConsole;
	import com.axlloader.nativeWindows.WindowRecent;
	
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeDragManager;
	import flash.display.NativeMenuItem;
	import flash.display.NativeWindow;
	import flash.events.Event;
	import flash.events.InvokeEvent;
	import flash.events.KeyboardEvent;
	import flash.events.NativeDragEvent;
	import flash.events.UncaughtErrorEvent;
	import flash.filesystem.File;
	import flash.net.URLRequest;
	import flash.system.Capabilities;

	public class EventsManager
	{
		private var pl:AxlLoader;
		private var bar:TopBar;
		private var windowConsole:WindowConsole;
		private var windowRecent:WindowRecent;
		private var mainWindow:NativeWindow;
		private var U:Class;
		
		
		public function EventsManager()
		{
			pl = AxlLoader.instance;
			bar = pl.bar;
			windowConsole = pl.windowConsole;
			windowRecent = pl.windowRecent;
			windowRecent.addEventListener(Event.SELECT, onHistoryElementSelected);
			mainWindow = pl.mainWindow;
			U = AxlLoader.classDict.U;
			addNativeAppListeners();
			setDefaultApp();
		}
		
		private function setDefaultApp():void
		{
			try {
				if(NativeApplication.supportsDefaultApplication())
					NativeApplication.nativeApplication.setAsDefaultApplication("swf");
			}
			catch(e:*){}
		}
		
		private function addNativeAppListeners():void
		{
			
			if(Capabilities.version.substr(0,3).toLowerCase() == "mac")
				NativeApplication.nativeApplication.menu.addEventListener(Event.SELECT, onNativeKeyDownMac);
			NativeApplication.nativeApplication.addEventListener(KeyboardEvent.KEY_DOWN, onNativeKeyDown);
			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvokeEvent);
			NativeApplication.nativeApplication.addEventListener(Event.EXITING, exitingEvent);
			
			pl.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onDragIn);
			pl.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, onDragDrop);
			pl.addEventListener(NativeDragEvent.NATIVE_DRAG_EXIT, onNativeDragExit);
		}
		
		protected function exitingEvent(e:Event):void
		{
			if(bar != null)
				bar.exiting();
			if(pl.windowParameters != null)
				pl.windowParameters.exiting();
			if(pl.windowTimestamp != null);
				pl.windowTimestamp.exiting();
		}
		
		private function onDragIn(e:NativeDragEvent):void
		{
			if(e.clipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT))
			{
				var files:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
				if(files.length == 1)
				{
					NativeDragManager.acceptDragDrop(pl);
					if(pl.htmlContent && pl.htmlContent.htmlloader.parent)
					{
						pl.addDragNDropOverlay();
					}
				}
			}
		}
		protected function onDragDrop(e:NativeDragEvent):void
		{
			var arr:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
			if(arr && arr.length > 0)
			{
				pl.setLoadableURL(new URLRequest(arr.pop().url)); 
				pl.loadContent();
			}
		}
		protected function onNativeDragExit(e:NativeDragEvent):void
		{
			if(e.stageX < 1 || e.stageX > pl.stage.stageWidth || e.stageY < 1 || e.stageY > (pl.stage.stageHeight-10))
				pl.removeDragNDropOverlay();
		}		
		
		protected function onNativeKeyDown(e:KeyboardEvent):void
		{
			if(e.ctrlKey || e.commandKey)
			{
				var keyp:String = String.fromCharCode(e.charCode).toLowerCase();
				switch(keyp)
				{
					case 'v': parsePasteEvent(); break;
					case 'l': (bar.parent != null) ? bar.parent.removeChild(bar) : pl.addChild(bar); break;
					case 'r': pl.loadContent(); break;
					case 't': bar.btnTimestampDown() ; break;
					case 'h': bar.btnHistoryDown() ; break;
					case 'f': bar.btnParametersDown() ; break;
					case 'c': e.shiftKey ? bar.btnConsoleDown() : null ; break;
					default:
						var n:Number = Number(keyp);
						if(!isNaN(n))
							windowRecent.selectListItemUrlAt(n-1);
						break;
				}
			}
		}
		
		protected function onNativeKeyDownMac(e:Event):void
		{
			var menuItem:NativeMenuItem = e.target as NativeMenuItem; 
			switch(menuItem.label.toLowerCase())
			{
				case "paste": parsePasteEvent();break;
			}
		}
		
		
		protected function onInvokeEvent(e:InvokeEvent):void
		{
			try { pl.setupMainWindow();} catch (e:*) { trace(e);}
			parseInvokeArguments(e);
		}
		
		private function parseInvokeArguments(e:InvokeEvent):void
		{
			var invokedFileUrlRequest:URLRequest, rawArgument:String;
			if(e.arguments.length > 0)
			{
				rawArgument = e.arguments.pop();
				try {
					var clickFile:File = new File(rawArgument);
					invokedFileUrlRequest = new URLRequest(clickFile.url);
				}
				catch (e:Error) { };
				if(invokedFileUrlRequest == null)
				{
					U.msg("Can't open " + rawArgument);
					return
				}
				pl.setLoadableURL(invokedFileUrlRequest);
				pl.loadContent()
			}
		}
		
		private function parsePasteEvent():void
		{
			if(Clipboard.generalClipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT))
			{ 
				parseFilePaste();
			}
			else if(Clipboard.generalClipboard.hasFormat(ClipboardFormats.TEXT_FORMAT))
			{ 
				parseLinkPaste();
			} 
		}
		
		private function parseLinkPaste():void
		{
			var text:String = Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT) as String; 
			U.log('link paste', text);
			text = text.replace(/^\s*/i,'').replace(/\s*$/i,'');
			if(text.match(/[:\/|:\\]/))
			{
				try {
					pl.setLoadableURL(new URLRequest(text))
					pl.loadContent()
				}
				catch (e:Error) { U.msg(e.message) };
			}
		}
		
		private function parseFilePaste():void
		{
			var arr:Array = Clipboard.generalClipboard.formats;
			var pastedFile:File;
			var o:Array = Clipboard.generalClipboard.getData(arr[0]) as Array;
			if(o != null && o.length == 1)
			{
				pastedFile = o.pop();
				pastedFile.resolvePath('.');
				pl.setLoadableURL(new URLRequest(pastedFile.url)); 
				pl.loadContent()
			}
			else
			{
				U.msg("Can't read this file");
			}
		}
		
		public function onFileSelected(e:Event):void
		{
			pl.setLoadableURL(new URLRequest(e.target.url))
			pl.loadContent();
		}
		
		private function onHistoryElementSelected(e:Event):void
		{
			pl.setLoadableURL(new URLRequest(windowRecent.selectedURL))
			pl.loadContent()
		}
		
		//--- r
		public function onLoaderError(e:UncaughtErrorEvent=null):void
		{
			var err:Error = e.error;
			U.log('onLoaderError',e, e.errorID, err.errorID);
			if(e && e.error && e.error is Error && e.error.errorID == 2067)
			{
				pl.switchToHTMLLoader();
			}
			else
			{
				U.msg("Problems with loaded content.<br>" +
					"<ul><li>Click on this bar to try alternative loader</li>" +
					"<li>Click outside to stay where you are </li><ul>", trace, pl.switchToHTMLLoader);
			}
		}
	}
}