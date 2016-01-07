package nativeWindows
{
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	
	import fl.controls.Button;
	import fl.controls.Label;
	import fl.controls.NumericStepper;
	import fl.controls.TextInput;
	
	public class WindowTimestamp extends WindowOwner
	{
		private var start:DateComponent;
		private var end:DateComponent;
		private var out:TextInput;
		private var lstart:Label;
		private var lend:Label;
		private var rStart:TextInput;
		private var rEnd:TextInput;
		private var gen:Button;
		private var linterval:Label;
		private var interval:NumericStepper;
		private var outputIntervalArray:Array;
		private var timeContainersString:String;
		private var sample:String = "<!-- CONTAINER [ {index} ][ {timestamp} ][ {date} ] -->"+
			"\n<div name='timeContainer{index}'  alpha='0' meta='{\"addedToStage\":[0.5,{\"alpha\":1,\"delay\":0.5}],\"removeChild\":[0.5,{\"alpha\":0}]}'>"
			+ '{user}'
			+"\n</div>\n\n";
		private var resizeListenerAdded:Boolean;
		public function WindowTimestamp(windowTitle:String)
		{
			super(windowTitle);
			lstart= new Label();
			lstart.text = "start time";
			lstart.width = 80;
			
			lend = new Label();	
			lend.y = lstart.height;
			lend.text = 'end time';
			lend.width = 80;
			
			linterval = new Label();
			linterval.y = lend.y + lend.height;
			linterval.text = 'interval (hours)';
			linterval.width = 80;
			
			
			interval = new NumericStepper();
			interval.minimum = 0;
			interval.value = 24;
			interval.textField.restrict = '0-9';
			interval.textField.maxChars = 4;
			interval.width = 40;
			interval.y = linterval.y;
			interval.x = linterval.width;
			interval.addEventListener(Event.CHANGE, dateChange);
			interval.addEventListener(KeyboardEvent.KEY_UP, dateChange);
			DateComponent.sizeStepperButtons([interval]);

			
			start = new DateComponent();
			end = new DateComponent();
			start.addEventListener(flash.events.Event.CHANGE, dateChange);
			end.addEventListener(flash.events.Event.CHANGE, dateChange);
			
			start.x = lstart.width;
			start.y = 0;
			
			end.x = lstart.width;
			end.y = lend.y;
			
				
			rStart = new TextInput();
			rStart.textField.restrict = '0-9'
			rStart.addEventListener(KeyboardEvent.KEY_UP, timestampChangeS);
			rStart.maxChars = 11;
			
			rEnd = new TextInput();
			rEnd.addEventListener(KeyboardEvent.KEY_UP, timestampChangeE);
			rEnd.textField.restrict = '0-9';
			rEnd.maxChars = 11;
			
			rStart.x  = 295;
			rEnd.x  = 295;
			rEnd.y = end.y;
			
			updateRightTimeStamps();
			
			this.addChild(lstart);
			this.addChild(lend);
			this.addChild(start);
			this.addChild(end)
			this.addChild(rStart);
			this.addChild(rEnd);
			this.addChild(linterval);
			this.addChild(interval);
			
			gen = new Button();
			
			out = new TextInput();
			out.y = 70;
			out.width = this.width;
			out.height = 120;
			this.addChild(out);
			
			this.addEventListener(Event.ADDED_TO_STAGE, ats);
			
		}
		
		protected function ats(event:Event):void
		{
			if(!resizeListenerAdded)
				this.stage.addEventListener(Event.RESIZE, resize);
		}
		
		protected function resize(e:Event):void
		{
			out.height = stage.stageHeight - out.y - 10;
			out.width = stage.stageWidth - out.x - 10;
		}
		
		protected function timestampChangeS(event:KeyboardEvent):void
		{
			start.timestampSec = int(rStart.text);
			updateOutput();
		}
		
		protected function timestampChangeE(event:KeyboardEvent):void
		{
			end.timestampSec = int(rEnd.text);
			updateOutput();
		}
		
		protected function dateChange(e:Event):void
		{
			updateRightTimeStamps();
			updateOutput();
		}
		
		private function updateOutput():void
		{
			updateIntervalData();
			var o:String;
			o = "promoStartTimestamp='_sts_' promoEndTimestamp='_ets_'\n\n";
			o+= '"timing":[_tarr_]\n\n';
			o+= '_timeContainers_';
			
			o = o.replace('_sts_', rStart.text);
			o = o.replace('_ets_', rEnd.text);
			o = o.replace('_tarr_',outputIntervalArray.join(','));
			o = o.replace('_timeContainers_',timeContainersString);
			out.text = o;
		}
		
		private function updateRightTimeStamps():void
		{
			rStart.text = String(start.timestampSec);
			rEnd.text = String(end.timestampSec);
		}
		
		private function updateIntervalData():void
		{
			var ss:int = int(rStart.text);
			var es:int = int(rEnd.text);
			
			outputIntervalArray =[];
			var ts:int = ss;
			var intervalVal:Number = (interval.value) * 60 * 60;
			if(intervalVal == 0)
				intervalVal = es-ts;
			
			var howMany:int = (es-ts)/intervalVal;
			if(howMany > 200)
			{
				timeContainersString = "You're requesting to create over two hundred time containers. e?";
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
			// TRACING
			var d:Date = new Date();
			timeContainersString = '';
			
			for(var i:int =0; i < outputIntervalArray.length; i++)
			{
				d.time = Number(String(outputIntervalArray[i]) + '000');
				d.time += ((d.timezoneOffset * -1) * 60 * 1000);
				ts = Math.floor(d.time / 1000);
				
				var s:String = sample.replace(/\{timestamp\}/g, String(ts));
				s = s.replace(/\{date\}/g, d.toUTCString());
				s = s.replace(/\{index\}/g, i);
				s = s.replace(/\{user\}/g, /*user(i)*/ '');
				timeContainersString += s;
			}
		}
	}
}