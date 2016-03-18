package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	import fl.controls.BaseButton;
	import fl.controls.NumericStepper;
	
	public class DateComponent extends Sprite
	{
		private var time:Date;
		private var yyyy:NumericStepper;
		private var dd:NumericStepper;
		private var mm:NumericStepper;
		private var hh:NumericStepper;
		private var min:NumericStepper;
		private var sec:NumericStepper;
		private var eventChange:Event;
		
		public function DateComponent()
		{
			super();
			
			time = new Date();
			yyyy = new NumericStepper();
			yyyy.maximum = 2020;
			yyyy.minimum = 2010;
			yyyy.value = time.getUTCFullYear();
			yyyy.width = 40;
			yyyy.textField.restrict = '0-9';
			yyyy.textField.maxChars = 4;
			this.addEventListener(flash.events.MouseEvent.MOUSE_UP, dispatchChange);
			this.addEventListener(flash.events.KeyboardEvent.KEY_UP, dispatchChange);
			
			mm = new NumericStepper();
			mm.minimum=1;
			mm.maximum=12;
			mm.value = time.getUTCMonth() + 1;
			mm.width = 30;
			mm.textField.restrict = '0-9';
			mm.textField.maxChars = 4;
			
			dd = new NumericStepper();
			dd.minimum = 1;
			dd.maximum = 31;
			dd.value = time.getUTCDate();
			dd.textField.restrict = '0-9';
			dd.textField.maxChars = 2;
			dd.width = 30;
			var tf:TextField = new TextField();
			tf.defaultTextFormat = dd.textField.textField.defaultTextFormat;
			tf.text = '-';
			tf.width = tf.textWidth+5;
			hh = new NumericStepper();
			hh.minimum = 0;
			hh.maximum = 23;
			hh.value = time.getUTCHours();
			hh.textField.restrict = '0-9';
			hh.textField.maxChars = 2;
			hh.width = 30;
			
			min = new NumericStepper();
			min.minimum = 0;
			min.maximum = 59;
			min.value = time.getUTCMinutes();
			min.textField.restrict = '0-9';
			min.textField.maxChars = 2;
			min.width = 30;
			
			sec = new NumericStepper();
			sec.minimum = 0;
			sec.maximum = 59;
			sec.value = time.getUTCSeconds();
			sec.textField.restrict = '0-9';
			sec.textField.maxChars = 2;
			sec.width = 30;
			sizeStepperButtons([yyyy,mm,dd,hh,min,sec]);
			
			this.addChild(yyyy);
			this.addChild(mm);
			this.addChild(dd);
			this.addChild(tf);
			this.addChild(hh);
			this.addChild(min);
			this.addChild(sec);
			eventChange = new Event(flash.events.Event.CHANGE)
			PromoLoader.classDict.U.distribute(this,0);
			this.addEventListener(MouseEvent.MOUSE_WHEEL, wheelEvent);
		}
		
		protected function dispatchChange(e:Object=null):void
		{
			this.dispatchEvent(eventChange);
			
		}
		
		public static function sizeStepperButtons(v:Array, wid:Number=10):void{
			for(var j:int =0; j < v.length; j++)
				for(var i:int = 0; i < v[j].numChildren; i++)
					if( v[j].getChildAt(i) is BaseButton)
						v[j].getChildAt(i).width = wid;
		}
		
		public function get timestampSec():Number
		{
			var d:Date = new Date(yyyy.value, mm.value -1, dd.value, hh.value, min.value, sec.value);
			d.minutes -= d.getTimezoneOffset();
			yyyy.value = d.getUTCFullYear();
			mm.value = d.getUTCMonth() +1;
			dd.value =d.getUTCDate();
			hh.value = d.getUTCHours();
			min.value = d.getUTCMinutes();
			sec.value =d.getUTCSeconds();
			
			return Math.round(d.getTime()/1000);
		}
		
		public function set timestampSec(v:Number):void
		{
			var d:Date = new Date();
				d.setTime(v * 1000);
				//d.time += ((d.timezoneOffset * -1) * 60 * 1000);
			yyyy.value = d.getUTCFullYear();
			mm.value = d.getUTCMonth() +1;
			dd.value =d.getUTCDate();
			hh.value = d.getUTCHours();
			min.value = d.getUTCMinutes();
			sec.value =d.getUTCSeconds();
		}
		
		protected function wheelEvent(e:MouseEvent):void
		{
			var v:NumericStepper = findRecursive(e.target);
			if(v != null)
				v.value += e.delta > 0 ? 1 : -1;
		}
		
		private function findRecursive(target:Object):NumericStepper
		{
			if(target is NumericStepper)
				return target as NumericStepper;
			if(target.hasOwnProperty('parent') && target.parent != null)
				return findRecursive(target.parent);
			return null;
		}
		
	}
}