package org.tiger.sound 
{
	import flash.events.Event;
	
	/**
	 * @author Tiger
	 */
	public class MicrophoneRecEvent extends Event 
	{
		static public var RECORD_START : String = "RECORD_START";
		static public var RECORD_TIME : String = "RECORD_TIME";
		static public var RECORD_STOP : String = "RECORD_STOP";
		static public var NEW_DATA_AVAIBLE : String = "NEW_DATA_AVAIBLE";
		static public var ENCODE_ERROR : String = "ENCODE_ERROR";
		static public var ENCODE_START : String = "ENCODE_START";
		static public var ENCODE_PROGRESS : String = "ENCODE_PROGRESS";
		static public var ENCODE_COMPLETE : String = "ENCODE_COMPLETE";
//		static public var RECORD_RESTORE : String = "RECORD_RESTORE";
//		static public var RECORD_PAUSE : String = "RECORD_PAUSE";
		static public var CLEARED : String = "CLEARED";
		static public var SETTING_WINDOW : String = "SETTING_WINDOW";
		
		public var errorText : String = "";
		public var percent : Number = 0;
		
		public function MicrophoneRecEvent(type : String, bubbles : Boolean = false, cancelable : Boolean = false, text : String = "", perc : Number = 0)
		{
			super(type, bubbles, cancelable);
			errorText = text;
			percent = perc;
		}
	}
}
