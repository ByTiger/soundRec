package  
{
	import de.popforge.audio.output.SoundFactory;	
	import de.popforge.format.wav.WavFormat;	
	
	import org.tiger.network.PostFormDataEvent;
	import org.tiger.network.PostFormData;
	import org.tiger.sound.MicrophoneRecEvent;
	import org.tiger.sound.MicrophoneRec;
	
	import flash.media.Sound;	
	import flash.media.SoundChannel;	
	import flash.events.MouseEvent;	
	import flash.display.StageScaleMode;
	import flash.events.FocusEvent;
	import flash.system.SecurityPanel;
	import flash.system.Security;
	import flash.external.ExternalInterface;
	import flash.utils.ByteArray;
	import flash.events.Event;
	import flash.display.StageAlign;
	import flash.display.Sprite;
	
	[SWF (width="215", height="138", frameRate="16", backgrouondColor="#ffffff")]
	
	/**
	 * @author Tiger
	 */
	public class soundRec extends Sprite 
	{
		[Embed(source="sc_button.png")] private var _buttonClass : Class;
		private var _microphoneRec : MicrophoneRec = new MicrophoneRec();
		private var _useEcho : Boolean = true;
		private var _postForm : PostFormData = new PostFormData();
		private var _url : String = "";
		private var _post : String = "";
		private var _header : String = "";
		private var _fileField : String = "";
		private var _button : Sprite = null;
		
		public function soundRec()
		{
			Security.allowDomain("*");
			Security.allowInsecureDomain("*");
			
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.showDefaultContextMenu = true;
			stage.focus = this;
			
			_button = new Sprite();
			_button.addChild(new _buttonClass);
			addChild(_button);
			_button.buttonMode = true;
			
			PrepareBack(215,138);
			
			_microphoneRec.addEventListener(MicrophoneRecEvent.RECORD_START, onStart);
			_microphoneRec.addEventListener(MicrophoneRecEvent.RECORD_TIME, OnRecordTime);
			_microphoneRec.addEventListener(MicrophoneRecEvent.RECORD_PAUSE, onPause);
			_microphoneRec.addEventListener(MicrophoneRecEvent.RECORD_RESTORE, onRestore);
			_microphoneRec.addEventListener(MicrophoneRecEvent.RECORD_STOP, onStop);
			_microphoneRec.addEventListener(MicrophoneRecEvent.CLEARED, onRecordCleared);
			_microphoneRec.addEventListener(MicrophoneRecEvent.ENCODE_START, OnEncodeStart);
			_microphoneRec.addEventListener(MicrophoneRecEvent.ENCODE_PROGRESS, OnEncodeProgress);
			_microphoneRec.addEventListener(MicrophoneRecEvent.ENCODE_ERROR, OnEncodeError);
			_microphoneRec.addEventListener(MicrophoneRecEvent.ENCODE_COMPLETE, OnEncodeComplete);
			_microphoneRec.addEventListener(MicrophoneRecEvent.SETTING_WINDOW, OnSettingWindowShown);
			
			_postForm.addEventListener(PostFormDataEvent.POST_START, OnPostStart);
			_postForm.addEventListener(PostFormDataEvent.PROGRESS, OnPostProgress);
			_postForm.addEventListener(PostFormDataEvent.COMPLETE, OnPostComplete);
			_postForm.addEventListener(PostFormDataEvent.ERROR, OnPostError);
			
			_button.addEventListener(MouseEvent.CLICK, onClick);
			stage.addEventListener(Event.RESIZE, onResize);
			
			if(!ExternalInterface.available) return;
			ExternalInterface.addCallback("StartRecord", StartRecord);
			ExternalInterface.addCallback("PauseRecord", PauseRecord);
			ExternalInterface.addCallback("StopRecord", StopRecord);
			ExternalInterface.addCallback("DeleteRecorded", DeleteRecorded);
			ExternalInterface.addCallback("ShowSettings", ShowSettings);
			ExternalInterface.addCallback("SetPostData", SetPostData);
			ExternalInterface.addCallback("Echo", Echo);
			ExternalInterface.addCallback("Encode", Encode);
			ExternalInterface.addCallback("PlayRecord", Play);
			ExternalInterface.addCallback("StopPlaingRecord", PlayStop);
		}
		
		private function onResize(e : Event) : void
		{
			var ww : int = stage.stageWidth;
			var hh : int = stage.stageHeight;
			if(ww > 0 && hh > 0) PrepareBack(ww,hh);
		}
		
		private function PrepareBack(ww : int, hh : int) : void
		{
			this.graphics.beginFill(0xffffff,1);
			this.graphics.drawRect(0, 0, ww, hh);
			this.graphics.endFill();
			_button.x = (ww - _button.width) / 2;
			_button.y = (hh - _button.height) / 2;
		}
		
		private function onClick(e : Event) : void
		{
			Post();//"https://api.soundcloud.com/tracks.json", "track[title]=Quick_Fox_Jump_Over_the&track[sharing]=public&oauth_token=1-3168-7336574-8318efa19958fe582", "", "track[asset_data]");
			
//			if(!_microphoneRec.isRecording)
//			{
//				StartRecord();
//				return;
//			}
//			StopRecord();
//			//_microphoneRec.EncodeToMP3();
//			Play();
		}
		
		
		
		/****************************************************************************
		 * control functions
		 ****************************************************************************/
		public function StartRecord() : void
		{
			_microphoneRec.Record();
		}
		
		public function StopRecord() : void
		{
			_microphoneRec.Stop();
		}
		
		public function PauseRecord() : void
		{
			_microphoneRec.Pause();
		}
		
		public function DeleteRecorded() : void
		{
			_microphoneRec.Clear();
		}
		
		public function Echo(b : String) : void
		{
			if(b == "1" || b == "true")
				_microphoneRec.loopBack = true;
			else
				_microphoneRec.loopBack = false;
		}
		
		public function Encode() : void
		{
			_microphoneRec.EncodeToMP3();
		}
		
		public function ShowSettings() : void
		{
			stage.focus = this;
			var onSetClose : Function = function(event : FocusEvent):void
			{
				stage.removeEventListener(FocusEvent.FOCUS_IN, onSetClose);
				OnSettingWndClose();
			};
			stage.addEventListener(FocusEvent.FOCUS_IN, onSetClose);
			Security.showSettings(SecurityPanel.MICROPHONE);
		}
		
		public function SetPostData(url : String, post : String = null, header : String = null, fileField : String = "filedata") : void
		{
			_url = url;
			_post = post;
			_header = header;
			_fileField = fileField;
		}
		
		public function Post() : void
		{
			if(_microphoneRec.mp3output == null || _microphoneRec.mp3output.length <= 0 || _url == "")
			{
				this.onNoDataToPost();
				return;
			}
			
			var tmp : Array;
			var hinfo : Array;
			var qq : int;
			
			tmp = _post.split("&");
			for(qq = 0; qq < tmp.length; qq++)
			{
				hinfo = String(tmp[qq]).split("=",2);
				if(String(hinfo[0]).length > 0)
					_postForm.addParam(hinfo[0], hinfo[1]);
			}
			
			var fileName : String = this.GenerateFileName();
			_postForm.addParam("Filename", fileName);
			_postForm.addFile(fileName, _microphoneRec.mp3output, _fileField);
			_postForm.Post(_url, _header);
		}
		
		private function GenerateFileName():String
		{
			var fn : String = "";
			
			for (var i:int = 0; i < 0x12; i++ )
			{
				fn += String.fromCharCode( int( 97 + Math.random() * 25 ) );
			}
			fn += ".mp3";
			return fn;
		}
		
		private var _wav_data : ByteArray = null;
		private var _sound : Sound = null;
		private var _chanel : SoundChannel = null;
		
		public function Play() : void
		{
			if(_chanel) PlayStop();
			_sound = null;
			if(_wav_data)
			{
				_wav_data.clear();
				_wav_data = null;
			}
			
			_wav_data = new ByteArray();
			_microphoneRec.output.position = 0;
			_wav_data.writeBytes(_microphoneRec.output, 0, _microphoneRec.output.length);
			_wav_data.position = 0;
			
			var wavformat : WavFormat = WavFormat.decode(_wav_data);
			SoundFactory.fromArray(wavformat.samples, wavformat.channels, wavformat.bits, wavformat.rate, onSoundFactoryComplete);
			CallJSFunction("mr_onPlayStart");
		}
		
		private function onSoundFactoryComplete(sound : Sound) : void
		{
			_sound = sound;
			_chanel = _sound.play();
			_chanel.addEventListener(Event.SOUND_COMPLETE, PlayStop);
		}		

		public function PlayStop(e : Event = null) : void
		{
			if(_chanel)
			{
				_chanel.removeEventListener(Event.SOUND_COMPLETE, PlayStop);
				_chanel.stop();
				_chanel = null;
				CallJSFunction("mr_onPlayStop");
			}
			_sound = null;
			if(_wav_data)
			{
				_wav_data.clear();
				_wav_data = null;
			}
		}
		
		
		
		
		/****************************************************************************
		 * event's function
		 ****************************************************************************/
		
		private function onStart(e : Event) : void
		{
			_microphoneRec.loopBack = _useEcho;
			CallJSFunction("mr_onRecordStart");
		}
		
		private function OnRecordTime(e : MicrophoneRecEvent) : void
		{
			CallJSFunction("mr_onRecordTime", e.percent.toString());
		}

		private function onPause(e : Event) : void
		{
			_microphoneRec.loopBack = false;
			CallJSFunction("mr_onRecordPause");
		}

		private function onRestore(e : Event) : void
		{
			_microphoneRec.loopBack = true;
			CallJSFunction("mr_onRecordRestore");
		}
		
		private function onStop(e : Event) : void
		{
			_microphoneRec.loopBack = false;
			CallJSFunction("mr_onRecordStop", _microphoneRec.recordTime.toString());
		}
		
		private function onRecordCleared(e : Event) : void
		{
			CallJSFunction("mr_onRecordCleared");
		}
		
		private function OnEncodeStart(e : Event) : void
		{
			CallJSFunction("mr_onEncodeStart");
		}
		
		private function OnEncodeProgress(e : MicrophoneRecEvent) : void
		{
			CallJSFunction("mr_onEncodeProgress", e.percent.toString());
		}

		private function OnEncodeError(e : MicrophoneRecEvent) : void
		{
			CallJSFunction("mr_onEncodeError", e.errorText);
		}

		private function OnEncodeComplete(e : Event) : void
		{
			CallJSFunction("mr_onEncodeComplete");
//			var ba : ByteArray = _microphoneRec.mp3output;
//			ba.position = 0;
			//(new FileReference()).save(ba, "recorded.mp3");
			
//			Post("https://api.soundcloud.com/tracks.json", "track[title]=Quick_Fox_Jump_Over_the&track[sharing]=public&oauth_token=1-3168-7336574-8318efa19958fe582", "", "track[asset_data]");
		}
		
		private function OnSettingWindowShown(e : Event) : void
		{
			var onSetClose : Function = function(event : FocusEvent):void
			{
				stage.removeEventListener(FocusEvent.FOCUS_IN, onSetClose);
				OnSettingWndClose();
			};
			stage.addEventListener(FocusEvent.FOCUS_IN, onSetClose);
			CallJSFunction("mr_onSettingWindowShown");
		}
		
		private function OnSettingWndClose() : void
		{
			CallJSFunction("mr_onSettingClose");
		}
		
		private function onNoDataToPost() : void
		{
			CallJSFunction("mr_onNoDataToPost");
		}
		
		private function OnPostStart(e : Event) : void
		{
			CallJSFunction("mr_onPostStart");
		}
		
		private function OnPostProgress(e : PostFormDataEvent) : void
		{
			CallJSFunction("mr_onPostProgress", e.loaded.toString(), e.total.toString());
		}

		private function OnPostComplete(e : PostFormDataEvent) : void
		{
			CallJSFunction("mr_onPostComplete", e.result.toString(), e.data);
		}

		private function OnPostError(e : PostFormDataEvent) : void
		{
			CallJSFunction("mr_onPostError", e.result.toString());
		}
		
		
		
		
		/********************************************************************************
		 * call JS function for callback
		 ********************************************************************************/
		static public function CallJSFunction(func : String, prm1 : String = null, prm2 : String = null, prm3 : String = null) : String
		{
			trace(func,prm1,prm2);
			
			if(!ExternalInterface.available)
			{
				return "";
			}
			
			var res : String ="";
			if(prm3 != null)
			{
				res = String(ExternalInterface.call(func, prm1, prm2, prm3));
			}
			else if(prm2 != null)
			{
				res = String(ExternalInterface.call(func, prm1, prm2));
			}
			else if(prm1 != null)
			{
				res = String(ExternalInterface.call(func, prm1));
			}
			else
			{
				res = String(ExternalInterface.call(func));
			}
			return res;
		}
	}
}
