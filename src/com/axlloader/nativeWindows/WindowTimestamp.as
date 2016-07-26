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
	import com.axlloader.core.DateComponent;
	
	import flash.events.Event;
	import flash.events.NativeWindowBoundsEvent;
	import flash.globalization.DateTimeFormatter;
	import flash.net.SharedObject;
	
	import fl.controls.ComboBox;
	import fl.controls.Label;
	import fl.controls.NumericStepper;
	import fl.controls.TextInput;
	import fl.data.DataProvider;
	
	public class WindowTimestamp extends CoreWindow
	{
		private var cookie:SharedObject;
		
		private var startComponent:DateComponent;
		private var endComponent:DateComponent;
		
		private var startTimestampInput:TextInput;
		private var endTimestampInput:TextInput;
		private var formatInput:TextInput;
		private var patternInput:TextInput;
		
		private var labelStart:Label;
		private var labelEnd:Label;
		private var labelInterval:Label;
		private var patternLabel:Label;
		private var formatLabel:Label;
		
		private var intervalStepper:NumericStepper;
		private var cboxLocale:ComboBox;
		
		private var out:TextInput;
		private var margin:int = 10;
		
		private var dateConvert:Date = new Date();
		private var dtf:DateTimeFormatter;
		private var localeIDs:Array;
		private var outputIntervalArray:Array;
		
		private var defaultPattern:String = "<!-- {index} || {timestamp} || {dateUTC} || {date} -->\n";
		private var defaultTimeFormat:String = "EEEE, dd MMMM yyyy @ HHH:mm:ss";
		private var userReplacedString:String;
		
		public function WindowTimestamp(windowTitle:String)
		{
			super(windowTitle);
			this.x = this.y =  margin;
			cookie = SharedObject.getLocal('timestamp');
			
			labelStart= new Label();
			labelStart.text = "start time";
			labelStart.width = 80;
			
			labelEnd = new Label();	
			labelEnd.y = labelStart.height;
			labelEnd.text = 'end time';
			labelEnd.width = 80;
			
			labelInterval = new Label();
			labelInterval.y = labelEnd.y + labelEnd.height;
			labelInterval.text = 'interval (hours)';
			labelInterval.width = 80;
			
			intervalStepper = new NumericStepper();
			intervalStepper.minimum = 0;
			intervalStepper.maximum = 9999;
			
			intervalStepper.value = 6;
			intervalStepper.textField.restrict = '0-9';
			intervalStepper.textField.maxChars = 4;
			intervalStepper.width = 40;
			intervalStepper.y = labelInterval.y;
			intervalStepper.x = labelInterval.width;
			DateComponent.sizeStepperButtons([intervalStepper]);
			//
			startComponent = new DateComponent();
			endComponent = new DateComponent();
			
			
			startComponent.x = labelStart.width;
			startComponent.y = 0;
			
			endComponent.x = labelStart.width;
			endComponent.y = labelEnd.y;
			
			//	
			startTimestampInput = new TextInput();
			startTimestampInput.textField.restrict = '0-9'
			startTimestampInput.maxChars = 11;
			startTimestampInput.x  = 295;
			
			//
			endTimestampInput = new TextInput();
			endTimestampInput.textField.restrict = '0-9';
			endTimestampInput.maxChars = 11;
			endTimestampInput.x  = 295;
			endTimestampInput.y = endComponent.y;
			endComponent.timestampSec += convertToUTC(25 * 60 * 60);
			
			localeIDs = [];
			var list:Vector.<String> = DateTimeFormatter.getAvailableLocaleIDNames();
			while(list.length)
				localeIDs.push({label : list.shift()});
			cboxLocale= new ComboBox();
			cboxLocale.dataProvider = new DataProvider(localeIDs);
			
			cboxLocale.width = 70;
			cboxLocale.dropdown.x = 10;//fake
			
			
			cboxLocale.y = intervalStepper.y;
			//cboxLocale.drawNow();
			cboxLocale.dropdown.rowCount  = 20;
			xcboxLocaleSaved = cookie.data.locale || "pl-PL";
			
			formatLabel = new Label();	
			formatLabel.y = cboxLocale.y+3;
			formatLabel.text = 'Format';
			formatLabel.width = 40;
			formatLabel.textField;
			
			formatInput = new TextInput();
			formatInput.y = cboxLocale.y;
			formatInput.maxChars = 90;
			formatInput.x = 200;
			formatInput.text = cookie.data.timeFormat || defaultTimeFormat;
			
			patternLabel = new Label();
			patternLabel.textField.multiline = true;
			patternLabel.textField.wordWrap = true;
			patternLabel.text = "Pattern variables:\n{index}, {timestamp} {date}, {dateUTC}";
			patternLabel.y = labelInterval.y + labelInterval.height;
			
			patternInput = new TextInput();
			patternInput.textField.multiline = true;
			patternInput.textField.wordWrap = true;
			patternInput.y = patternLabel.y;
			patternInput.x = cboxLocale.x;
			patternInput.text = cookie.data.pattern || defaultPattern;
			
			out = new TextInput();
			out.textField.wordWrap = true;
			out.textField.type = "dynamic";
			
			this.addChild(labelStart);
			this.addChild(startComponent);
			
			this.addChild(labelEnd);
			this.addChild(endComponent)
				
			this.addChild(startTimestampInput);
			this.addChild(endTimestampInput);
			
			this.addChild(labelInterval);
			this.addChild(intervalStepper);
			
			this.addChild(formatLabel);
			this.addChild(cboxLocale);
			this.addChild(formatInput);
			
			this.addChild(patternLabel);
			this.addChild(patternInput);
			
			this.addChild(out);
			
			dtf = new DateTimeFormatter(cboxLocale.selectedLabel);
			startTimestampInput.text = String(startComponent.timestampSec);
			endTimestampInput.text = String(endComponent.timestampSec);
			updateOutput();
			
			startComponent.addEventListener(Event.CHANGE, compomentChange);
			endComponent.addEventListener(Event.CHANGE, compomentChange);
			
			startTimestampInput.addEventListener(Event.CHANGE, timestampChange);
			endTimestampInput.addEventListener(Event.CHANGE, timestampChange);
			
			
			formatInput.addEventListener(Event.CHANGE, nonRelatedChange);
			patternInput.addEventListener(Event.CHANGE, nonRelatedChange);
			intervalStepper.addEventListener(Event.CHANGE, nonRelatedChange);
			cboxLocale.addEventListener(Event.CHANGE, nonRelatedChange);
			
		}
		
		override protected function onWindowCreated():void
		{
			window.addEventListener(NativeWindowBoundsEvent.RESIZE,onResize);
			window.stage.stageWidth =  480;
			window.stage.stageHeight = 317;
			alignLocaleDropDown();
		}
		
		protected function onResize(e:Event):void
		{
			var m:Number = margin * 2;
			patternInput.height = stage.stageHeight * 0.15;
			patternLabel.height = patternInput.height;
			out.y = patternInput.y + patternInput.height;
			out.height = stage.stageHeight - out.y -m;
			out.width = stage.stageWidth - out.x - m;
			startTimestampInput.width = stage.stageWidth - startTimestampInput.x -m;
			endTimestampInput.width = startTimestampInput.width;
			alignLocaleDropDown();
			patternInput.x = intervalStepper.x + intervalStepper.width;
			patternInput.width = stage.stageWidth- patternInput.x - m;
			if((stage.stageWidth - m) < 550)
			{
				formatInput.x = 250;
				formatInput.width = stage.stageWidth - formatInput.x - m;
			}
			else
			{
				formatInput.width = 280;
				formatInput.x =stage.stageWidth - formatInput.width - m;
			}
			
			cboxLocale.x = formatInput.x - cboxLocale.width;
			formatLabel.x = cboxLocale.x - formatLabel.width -10;
		}
		
		private function alignLocaleDropDown():void
		{
			var left:Number = (stage.stageHeight - cboxLocale.y + cboxLocale.height);
			var single:Number = cboxLocale.dropdown.rowHeight + 5;
			cboxLocale.dropdown.rowCount  = Math.floor(left / single);
		}
		
		protected function set xcboxLocaleSaved(v:String):void { 
			for(var i:int = localeIDs.length;i-->0;)
				if(localeIDs[i].label ==v)
					cboxLocale.selectedIndex = i;
		}
		
		protected function timestampChange(e:Event):void
		{
			// DateComponent accepts UTC timestamps and displays LOCAL time
			switch(e.target)
			{
				case startTimestampInput:
					startComponent.timestampSec = convertToUTC(Number(startTimestampInput.text));
					break
				case endTimestampInput:
					endComponent.timestampSec = convertToUTC(Number(endTimestampInput.text));
					break;
			}
			updateOutput();
		}
		
		protected function compomentChange(e:Event):void
		{
			switch(e.target)
			{
				case startComponent:
					startTimestampInput.text = String(startComponent.timestampSec);
					break
				case endComponent:
					endTimestampInput.text = String(endComponent.timestampSec);
					break;
			}
			
			startTimestampInput.text = String(startComponent.timestampSec);
			endTimestampInput.text = String(endComponent.timestampSec);
			updateOutput();
		}
		
		protected function nonRelatedChange(e:Event):void
		{
			if(e.target == this.cboxLocale)
				dtf = new DateTimeFormatter(cboxLocale.selectedLabel);
			updateOutput();
		}
		
		private function convertToUTC(v:Number):Number
		{
			this.dateConvert.setTime(v * 1000);
			return (dateConvert.time - (dateConvert.timezoneOffset * 60000))/1000;
		}
		
		protected function dateChange(e:Event=null):void
		{
			updateTimeStampsInput();
			updateOutput();
		}
		
		
		private function updateTimeStampsInput():void
		{
			startTimestampInput.text = String(startComponent.timestampSec);
			endTimestampInput.text = String(endComponent.timestampSec);
		}
		
		private function updateIntervalData():void
		{
			var ss:int = int(startTimestampInput.text);
			var es:int = int(endTimestampInput.text);
			
			outputIntervalArray =[];
			var ts:int = ss;
			var intervalVal:Number = (intervalStepper.value) * 60 * 60;
			if(intervalVal == 0)
				intervalVal = es-ts;
			
			var howMany:int = (es-ts)/intervalVal;
			if(howMany > 1000)
			{
				userReplacedString = "You're requesting to create over one thoused containers. e?";
				return;
			}
			while(ts < es)
			{
				outputIntervalArray.push(ts);
				ts+= intervalVal;
			}
			var last:int = outputIntervalArray[outputIntervalArray.length-1];
			if(last< es)
			{
				outputIntervalArray.push(es);
			}
			var userPattern:String = patternInput.text;
			userReplacedString = '';
			
			for(var i:int =0; i < outputIntervalArray.length; i++)
			{
				dateConvert.time = Number(String(outputIntervalArray[i]) + '000');
				
				ts = Math.floor(dateConvert.time / 1000);
				
				var s:String = userPattern;
				s = s.replace(/\{timestamp\}/g, String(ts));
				s = s.replace(/\{dateUTC\}/g, dateConvert.toUTCString());
				s = s.replace(/\{date\}/g, dtf.format(dateConvert));
				s = s.replace(/\{index\}/g, i);
				userReplacedString += s;
			}
		}
		
		
		private function updateOutput():void
		{
			dtf.setDateTimePattern(formatInput.text);
			updateIntervalData();
			var o:String="";
			o+= '"timing":[@]\n\n';
			o+= '@';
			
			o = o.replace('@',outputIntervalArray.join(','));
			o = o.replace('@',userReplacedString);
			out.text = o;
		}
		
		public function exiting():void
		{
			cookie.data.locale = this.cboxLocale.selectedLabel;
			cookie.data.timeFormat = formatInput.text;
			cookie.data.pattern = patternInput.text;
			cookie.flush();
		}
	}
}