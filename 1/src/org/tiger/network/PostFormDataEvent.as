package org.tiger.network 
{
	import flash.events.Event;
	
	/**
	 * @author Tiger
	 */
	public class PostFormDataEvent extends Event 
	{
		static public var PROGRESS : String = "PROGRESS";
		static public var POST_START : String = "POST_START";
		static public var COMPLETE : String = "COMPLETE";
		static public var ERROR : String = "ERROR";
		public var loaded : int = 0;
		public var total : int = 0;
		public var result : int = 0;
		public var data : String = "";
		
		public function PostFormDataEvent(type : String, bubbles : Boolean = false, cancelable : Boolean = false, _loaded : int = 0, _total : int = 0, _result : int = 0, _data : String = "")
		{
			super(type, bubbles, cancelable);
			loaded = _loaded;
			total = _total;
			result = _result;
			data = _data;
		}
	}
}
