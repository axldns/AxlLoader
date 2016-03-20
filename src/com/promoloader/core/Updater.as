package com.promoloader.core
{
	import flash.display.Bitmap;

	public class Updater
	{
		public static function updateFunction():void
		{
			PromoLoader.classDict.Ldr.load('http://axldns.com/wp-content/uploads/2016/misc/cat.jpg',loaded);
			function loaded():void
			{
				
				var img:Bitmap = PromoLoader.classDict.Ldr.getBitmap('cat.jpg');
				if(img)
				{
					PromoLoader.classDict.Messages.bgColour = 0x0f0f0f;
					PromoLoader.instance.stage.stageWidth =736;
					message();
					img.y = PromoLoader.classDict.Messages.textfield.height;
					PromoLoader.instance.stage.stageHeight = 600 + img.y;
					PromoLoader.instance.stage.addChild(img);
				}
				else
				{
					message();
				}
				function message():void
				{
					PromoLoader.classDict.U.msg('PromoLoader has been updated to version '+PromoLoader.instance.VERSION+'<br>' +
						'<font size="+10"><b>Now it can load regular flash projects too!</b></font><br><br>' +
						'Click <b><a href="event:Close">here</a></b> to be awesome',null,remove,true);
				}
				function remove():void 
				{ 
					if(img && img.parent)
					{
						img.parent.removeChild(img);
						img.bitmapData.dispose();
						img = null;
					}
				}
			}
		}
	}
}