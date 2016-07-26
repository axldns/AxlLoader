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
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.net.SharedObject;
	
	import fl.controls.Button;
	import fl.controls.ComboBox;
	import fl.data.DataProvider;
	import fl.events.ComponentEvent;
	
	public class TopBar extends Sprite
	{
		private var cookie:SharedObject;
		
		private var xbtnOpen:Button;
		private var xbtnConsole:Button;
		private var xbtnHistory:Button;
		private var xbtnParameters:Button;
		private var xdateComponent:DateComponent;
		private var xbtnTimestamp:Button;
		private var xbtnInfo:Button;
		private var xcboxAutoSize:ComboBox;
		private var xbtnReload:Button;
		
		private var scaleModes:Array = [{label : "auto"}, {label : "scale"}, {label: "free"}];
		
		public function TopBar()
		{
			super();
			cookie = SharedObject.getLocal('bar');
			
			xbtnOpen = new Button();
			xbtnOpen.label = 'Open';
			xbtnOpen.width = xbtnOpen.textField.textWidth + 15;

			xbtnConsole = new Button();
			xbtnConsole.label = 'Console';
			xbtnConsole.width = xbtnConsole.textField.textWidth + 15;
			
			xbtnHistory = new Button();
			xbtnHistory.label = 'History';
			xbtnHistory.width =  xbtnHistory.textField.textWidth + 15;
			
			xbtnParameters = new Button();
			xbtnParameters.label = 'FlashVars';
			xbtnParameters.width =  xbtnParameters.textField.textWidth + 15;
			
			xdateComponent = new DateComponent();
			
			xbtnTimestamp = new Button();
			xbtnTimestamp.label = 'T';
			xbtnTimestamp.width =  xbtnTimestamp.height;
			xbtnTimestamp.x=412;
			
			xbtnInfo = new Button();
			xbtnInfo.label = 'info';
			xbtnInfo.width =  xbtnInfo.textField.textWidth + 15;
			
			xcboxAutoSize = new ComboBox();
			xcboxAutoSize.dataProvider = new DataProvider(scaleModes);
			xcboxAutoSizeMode = cookie.data.autoSize || 'auto';
			xcboxAutoSize.width = 55;
			
			xbtnReload = new Button();
			xbtnReload.label = 'Reload';
			xbtnReload.width = xbtnReload.textField.textWidth + 15;
			
			addEventListeners();
			
			AxlLoader.classDict.U.addChildGroup(this, xbtnOpen,xbtnConsole,xbtnHistory,xbtnParameters,
				xdateComponent,xbtnTimestamp,xbtnInfo,xcboxAutoSize,xbtnReload);
		}
		
		private function addEventListeners():void
		{
			this.addEventListener(Event.ADDED_TO_STAGE, ats);
			this.addEventListener(FocusEvent.FOCUS_OUT, fout);
			
			xbtnOpen.addEventListener(ComponentEvent.BUTTON_DOWN, btnOpenDown);
			xbtnConsole.addEventListener(ComponentEvent.BUTTON_DOWN, btnConsoleDown);
			xbtnHistory.addEventListener(ComponentEvent.BUTTON_DOWN, btnHistoryDown);
			xbtnParameters.addEventListener(ComponentEvent.BUTTON_DOWN, btnParametersDown);
			xdateComponent.addEventListener(KeyboardEvent.KEY_UP, onDateKeyUp);
			xbtnTimestamp.addEventListener(ComponentEvent.BUTTON_DOWN, btnTimestampDown);
			xbtnInfo.addEventListener(ComponentEvent.BUTTON_DOWN, btnInfoDown);
			xcboxAutoSize.addEventListener(Event.CHANGE, onAutoSizeChange);
			xbtnReload.addEventListener(ComponentEvent.BUTTON_DOWN, btnReloadDown);
		}
		
		protected function onAutoSizeChange(e:Event):void
		{
			AxlLoader.instance.onResize();
		}
		
		protected function set xcboxAutoSizeMode(v:String):void { 
			for(var i:int = scaleModes.length;i-->0;)
				if(scaleModes[i].label ==v)
					xcboxAutoSize.selectedIndex = i;
		}
		
		// --------------------- EVENTS --------------------- //
		private function fout(e:FocusEvent):void {  dateComponent.timestampSec }
		protected function ats(event:Event):void { 	arangeBar()	}
		
		protected function onDateKeyUp(e:KeyboardEvent):void
		{
			if(e.charCode == 13)
				AxlLoader.instance.loadContent();
		}
		
		public function btnConsoleDown(e:*=null):void { AxlLoader.instance.windowConsole.wappear() }
		public function btnHistoryDown(e:*=null):void { AxlLoader.instance.windowRecent.wappear() }
		public function btnTimestampDown(e:*=null):void { AxlLoader.instance.windowTimestamp.wappear() }
		public function btnReloadDown(e:*=null):void { AxlLoader.instance.loadContent()}
		public function btnOpenDown(e:*=null):void { AxlLoader.instance.browseForFile(); }
		public function btnParametersDown(e:*=null):void { AxlLoader.instance.windowParameters.wappear() }
		public function btnInfoDown(e:ComponentEvent):void { AxlLoader.instance.windowInfo.wappear() }		
		
		// --------------------- public api --------------------- //
		
		public function arangeBar():void
		{
			if(btnReload == null)
				return;
			AxlLoader.classDict.U.distribute(this,0);
			AxlLoader.classDict.U.align(btnReload, AxlLoader.classDict.U.REC, 'right', 'top');
			if(cboxAutoSize == null)
				return;
			cboxAutoSize.x = btnReload.x - cboxAutoSize.width;
			xbtnInfo.x = cboxAutoSize.x - xbtnInfo.width;
			xbtnTimestamp.x=412;
		}

		public function get btnOpen():Button { return xbtnOpen}
		public function get btnConsole():Button { return xbtnConsole }
		public function get btnRecent():Button { return xbtnHistory }
		public function get btnFlashVars():Button { return xbtnParameters }
		public function get dateComponent():DateComponent {	return xdateComponent }
		public function get btnTimestamp():Button { return xbtnTimestamp }
		public function get btnInfo():Button { return xbtnInfo }
		public function get cboxAutoSize():ComboBox	{ return xcboxAutoSize }
		public function get btnReload():Button { return xbtnReload }

		public function exiting():void
		{
			cookie.data.autoSize = cboxAutoSize.selectedLabel;
			cookie.flush();
		}
	}
}