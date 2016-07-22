package com.axlloader.core
{
	public class Updater
	{
		public static function updateFunction():void
		{
			AxlLoader.classDict.U.msg('AxlLoader has been updated to version '+AxlLoader.instance.VERSION+'<br>');
		}
	}
}