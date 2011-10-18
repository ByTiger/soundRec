package org.tiger.network 
{
	import flash.utils.Endian;	
	import flash.utils.ByteArray;	
	
	/**
	 * @author Tiger
	 */
	public class PostDataHelper 
	{
		private var _boundary : String = "";
		private var postData : ByteArray = null;
		
		
		
		public function PostDataHelper()
		{
			postData = new ByteArray();
			postData.endian = Endian.BIG_ENDIAN;
		}
		
		
		
		
		/*****************************************************************************
		 * generate boundary for the post
		 *****************************************************************************/
		
		public function get boundary():String
		{
			if(_boundary.length == 0)
			{
				_boundary = "------------";
				for (var i:int = 0; i < 0x20; i++ )
				{
					_boundary += String.fromCharCode( int( 97 + Math.random() * 25 ) );
				}
			}
			return _boundary;
		}
		
		public function GetContentType() : String
		{
			return "multipart/form-data; boundary=" + boundary;
		}
		
		public function addParam(param : String, value : String) : void
		{
			postData = _Boundary(postData);
			postData = _LineBeak(postData);
			postData = _String(postData, 'Content-Disposition: form-data; name="' + param + '"');
			postData = _LineBeak(postData);
			postData = _LineBeak(postData);
			postData.writeUTFBytes(value);
			postData = _LineBeak(postData);
		}
		
		public function get data() : ByteArray
		{
			return postData;
		}
		
		public function addFile(fileName : String, byteArray : ByteArray, uploadDataFieldName : String = "Filedata") : void
		{
			//add Filedata to postData
			postData = _Boundary(postData);
			postData = _LineBeak(postData);
			postData = _String(postData, 'Content-Disposition: form-data; name="'+uploadDataFieldName+'"; filename="' + fileName + '"');
			postData = _LineBeak(postData);
			postData = _String(postData, 'Content-Type: application/octet-stream');
			postData = _LineBeak(postData);
//			postData = _String(postData, 'Content-Transfer-Encoding: binary');
//			postData = _LineBeak(postData);
			postData = _LineBeak(postData);
			byteArray.position = 0;
			postData.writeBytes(byteArray, 0, byteArray.length);
			postData = _LineBeak(postData);

			//add upload filed to postData
			postData = _LineBeak(postData);
			postData = _Boundary(postData);
			postData = _LineBeak(postData);
			postData = _String(postData, 'Content-Disposition: form-data; name="Upload"');
			postData = _LineBeak(postData);
			postData = _LineBeak(postData);
			postData = _String(postData, 'Submit Query');
			postData = _LineBeak(postData);

			//closing boundary
			postData = _Boundary(postData);
			postData = _DoubleDash(postData);
		}

		private function _Boundary(p : ByteArray) : ByteArray
		{
			var l:int = boundary.length;
			p=_DoubleDash(p);
			for(var i : int = 0; i < l; i++ )
				p.writeByte(boundary.charCodeAt(i));
			return p;
		}

		// Add one linebreak
		private function _LineBeak(p : ByteArray) : ByteArray
		{
			p.writeShort(0x0d0a);
			return p;
		}

		// add double dash
		private function _DoubleDash(p : ByteArray) : ByteArray
		{
			p.writeShort(0x2d2d);
			return p;
		}
		
		// add string to buffer
		private function _String(p : ByteArray, str : String) : ByteArray
		{
			for(var i : int = 0; i < str.length; i++)
			{
				p.writeByte(str.charCodeAt(i));
			}
			return p;
		}
	}
}
