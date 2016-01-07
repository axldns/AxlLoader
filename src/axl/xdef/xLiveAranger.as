package axl.xdef
{
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.MouseEvent;
	
	import axl.utils.LiveAranger;
	
	public class xLiveAranger extends LiveAranger
	{
		private var lockUnderMouseEvents:Boolean;
		private var supportedProperties:Object =
			{
				x : 0,
				y : 0,
				z : 0,
				rotation:0,
				rotationX:0,
				rotationY:0,
				rotationZ:0,
				width:0,
				height:0,
				scaleX:1,
				scaleY:1
			}
			
		public function xLiveAranger()
		{
			super();
		}
		
		private function finishMovement():void
		{
			var v:Object = cTarget;
			if((v == null) || v is Stage || !(v.hasOwnProperty('def')) || !(v.def is XML))
				return;
			for(var s:String in supportedProperties)
			{
				if(v is Sprite && (s=='width' || s=='height'))
					continue;
				var n:Number = v[s];
				var d:Number = supportedProperties[s];
				if(n!=d)
					v.def.@[s] = n;
			}
		}
		
		override protected function mu(e:MouseEvent):void
		{
			finishMovement();
			super.mu(e);
			
		}
		
	}
}