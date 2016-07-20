package com.axlloader.core
{
	import flash.display.Bitmap;

	public class Updater
	{
		public static function updateFunction():void
		{
			AxlLoader.classDict.Ldr.load('http://axldns.com/wp-content/uploads/2016/misc/cat.jpg',loaded);
			function loaded():void
			{
				
				var img:Bitmap = AxlLoader.classDict.Ldr.getBitmap('cat.jpg');
				if(img)
				{
					AxlLoader.classDict.Messages.bgColour = 0x0f0f0f;
					AxlLoader.instance.stage.stageWidth =736;
					message();
					img.y = AxlLoader.classDict.Messages.textfield.height;
					AxlLoader.instance.stage.stageHeight = 600 + img.y;
					AxlLoader.instance.stage.addChild(img);
				}
				else
				{
					message();
				}
				function message():void
				{
					AxlLoader.classDict.U.msg('PromoLoader has been updated to version '+AxlLoader.instance.VERSION+'<br>' +
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