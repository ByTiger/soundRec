package org.tiger.network 
{
	import flash.external.ExternalInterface;	
	import flash.utils.ByteArray;	
	import flash.net.URLRequestHeader;	
	import flash.events.IOErrorEvent;	
	import flash.events.Event;	
	import flash.events.HTTPStatusEvent;	
	import flash.events.ProgressEvent;	
	import flash.events.SecurityErrorEvent;	
	import flash.net.URLRequestMethod;	
	import flash.net.URLRequest;	
	import flash.net.URLLoader;	
	import flash.events.IEventDispatcher;	
	import flash.events.EventDispatcher;
	
	/**
	 * @author Tiger
	 */
	public class PostFormData extends EventDispatcher 
	{
		private var _loader : URLLoader = null;
		private var _data : PostDataHelper = null;
		private var _httpStatusText : String = "";
		private var _httpStatus : int = 0;
		
		public function PostFormData(target : IEventDispatcher = null)
		{
			super(target);
			_loader = new URLLoader();
			_data = new PostDataHelper();
			addLoaderListeners();
		}
		
		public function Clear() : void
		{
			removeLoaderListeners();
			_loader = null;
			_data.data.clear();
			_data = null;
			
			_loader = new URLLoader();
			addLoaderListeners();
			_data = new PostDataHelper();
		}
		
		public function addParam(param : String, value : String) : void
		{
			_data.addParam(param, value);
		}
		
		public function addFile(fileName : String, byteArray : ByteArray, uploadDataFieldName : String = "Filedata") : void
		{
			_data.addFile(fileName, byteArray, uploadDataFieldName);
		}
		
		public function Post(url : String, header : String) : void
		{
			var urlRequest : URLRequest = new URLRequest();
			urlRequest.url = url;
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.contentType = _data.GetContentType();
			_data.data.position = 0;
			urlRequest.data = _data.data;
			
			var tmp : Array;
			var qq : int;
			var hinfo : Array;
			if(header)
			{
				tmp = header.split("&");
				for(qq = 0; qq < tmp.length; qq++)
				{
					hinfo = String(tmp[qq]).split(":",2);
					urlRequest.requestHeaders.push(new URLRequestHeader(hinfo[0]?hinfo[0]:"", hinfo[1]?hinfo[1]:""));
				}
			}
			
			//_loader.dataFormat = URLLoaderDataFormat.BINARY;
//			ExternalInterface.call("window.console.log", JSON.encode(_loader));
//			ExternalInterface.call("window.console.log", JSON.encode(urlRequest));
			_loader.load(urlRequest);
//			ExternalInterface.call("window.console.log", "9");
			onSendStart();
//			ExternalInterface.call("window.console.log", "7");
		}
		
		private function addLoaderListeners() : void
		{
            _loader.addEventListener(Event.COMPLETE, onLoadComplete);
            _loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatusChange);
            _loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
            _loader.addEventListener(ProgressEvent.PROGRESS, onUploadProgress);
            _loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
		}
		
		private function removeLoaderListeners() : void
		{
            _loader.removeEventListener(Event.COMPLETE, onLoadComplete);
            _loader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatusChange);
            _loader.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
            _loader.removeEventListener(ProgressEvent.PROGRESS, onUploadProgress);
            _loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
		}
		
		private function onUploadProgress(e : ProgressEvent) : void
		{
			dispatchEvent(new PostFormDataEvent(PostFormDataEvent.PROGRESS,false,false,e.bytesLoaded, e.bytesTotal));
		}
		
		private function onSendStart(e : Event = null) : void
		{
			dispatchEvent(new PostFormDataEvent(PostFormDataEvent.POST_START,false,false,0,0));
		}
		
		private function onHttpStatusChange(event : HTTPStatusEvent) : void
		{
			_httpStatus = int(event.status);
			if(event.status != 0 && event.status < 400) return;
			
			var msg:String;
			switch(event.status)
			{
				case 400:
					msg = "Bad Request";
					break;
				case 401:
					msg = "Unauthorized";
					break;
				case 403:
					msg = "Forbidden";
					break;
				case 404:
					msg = "Not Found";
					break;
				case 405:
					msg = "Method Not Allowed";
					break;
				case 406:
					msg = "Not Acceptable";
					break;
				case 407:
					msg = "Proxy Authentication Required";
					break;
				case 408:
					msg = "Request Timeout";
					break;
				case 409:
					msg = "Conflict";
					break;
				case 410:
					msg = "Gone";
					break;
				case 411:
					msg = "Length Required";
					break;
				case 412:
					msg = "Precondition Failed";
					break;
				case 413:
					msg = "Request Entity Too Large";
					break;
				case 414:
					msg = "Request-URI Too Long";
					break;
				case 415:
					msg = "Unsupported Media Type";
					break;
				case 416:
					msg = "Requested Range Not Satisfiable";
					break;
				case 417:
					msg = "Expectation Failed";
					break;
				case 500:
					msg = "Internal Server Error";
					break;
				case 501:
					msg = "Not Implemented";
					break;
				case 502:
					msg = "Bad Gateway";
					break;
				case 503:
					msg = "Service Unavailable";
					break;
				case 504:
					msg = "Gateway Timeout";
					break;
				case 505:
					msg = "HTTP Version Not Supported";
					break;
				default:
					msg = "Unhandled HTTP status";
			}
			_httpStatusText = msg;
		}
		
		private function onLoadComplete(event : Event) : void
		{
			dispatchEvent(new PostFormDataEvent(PostFormDataEvent.COMPLETE,false,false,0,0,_httpStatus,String((event.target as URLLoader).data)));
		}
		
		private function onIOError(e : IOErrorEvent) : void
		{
			dispatchEvent(new PostFormDataEvent(PostFormDataEvent.ERROR,false,false,0,0,_httpStatus));
		}
		
		private function onSecurityError(e : IOErrorEvent) : void
		{
			ExternalInterface.call("window.console.log", e.text);
			dispatchEvent(new PostFormDataEvent(PostFormDataEvent.ERROR,false,false,0,0,_httpStatus));
		}
	}
}
