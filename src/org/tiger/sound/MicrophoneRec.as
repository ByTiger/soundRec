﻿package org.tiger.sound 
{
	import fr.kikko.lab.ShineMP3Encoder;	
	
	import flash.events.TimerEvent;	
	import flash.utils.Timer;	
	
	import flash.events.ErrorEvent;	
	import flash.events.ProgressEvent;	
	import flash.events.Event;	
	import flash.utils.Endian;	
	import flash.utils.ByteArray;	
	import flash.events.SampleDataEvent;	
	import flash.events.StatusEvent;	
	import flash.media.Microphone;	
	import flash.events.IEventDispatcher;	
	import flash.events.EventDispatcher;
import flash.utils.getTimer;	
	/**
	 * @author Tiger
	 */
	public class MicrophoneRec extends EventDispatcher 
	{
		private var _microphone : Microphone = null;
		private var _gain : uint = 50;
		private var _rate : uint = 44;
		private var _silenceLevel : uint = 0;
		private var _timeOut : uint = 2000;
		private var _buffer : ByteArray = null;
		private var _output : ByteArray;
		private var _loopBack : Boolean = false;
		private var _isRecording : Boolean = false;
		private var _isPausing : Boolean = false;
		private var mp3Encoder : ShineMP3Encoder = null;
		private var _startTime : uint = 0;
		private var _fullTime : uint = 0;
		private var _timer : Timer = null;
		
		// for WAV encoder functions
//		private var _wavBytes : ByteArray = new ByteArray();
//		private var _wavBuffer : ByteArray = new ByteArray();
		private var _wavVolume : Number = 1;
		
		
		
		public function MicrophoneRec(target : IEventDispatcher = null)
		{
			super(target);
			_buffer = new ByteArray();
			_timer = new Timer(300);
		}
		
		
		
		/****************************************************************************
		 * public function
		 ****************************************************************************/
		
		public function set loopBack(b : Boolean) : void
		{
			_loopBack = b;
			if(_microphone) _microphone.setLoopBack(b);
		}
		
		public function get output():ByteArray
		{
			return _output;
		}
		
		public function get isRecording() : Boolean
		{
			return _isRecording;
		}
		
		public function get gain() : uint
		{
			return _gain;
		}
		
		public function set gain(value : uint) : void
		{
			_gain = value;
		}
		
		public function get rate() : uint
		{
			return _rate;
		}
		
		public function set rate(value : uint) : void
		{
			_rate = value;
		}
		
		public function get silenceLevel() : uint
		{
			return _silenceLevel;
		}
		
		public function set silenceLevel(value : uint) : void
		{
			_silenceLevel = value;
		}
		
		public function get recordTime() : uint
		{
			if(_isRecording && !_isPausing)
				return _fullTime + (getTimer() - _startTime);
			return _fullTime;
		}

		
		
		/****************************************************************************
		 * public function
		 ****************************************************************************/
		
		public function Record() : void
		{
			if(_microphone == null)
			{
				_microphone = Microphone.getMicrophone();
				_microphone.addEventListener(StatusEvent.STATUS, onStatus);
			}
			_microphone.setSilenceLevel(_silenceLevel, _timeOut);
			_microphone.gain = _gain;
			_microphone.rate = _rate;
			_microphone.encodeQuality = 10;
			_microphone.setLoopBack(_loopBack);

			_isRecording = true;
			_isPausing = false;
			_startTime = getTimer();
			_microphone.addEventListener(StatusEvent.STATUS, onStatus);
			_microphone.addEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
			dispatchEvent(new MicrophoneRecEvent(MicrophoneRecEvent.RECORD_START));
			if(_microphone.muted)
				dispatchEvent(new MicrophoneRecEvent(MicrophoneRecEvent.SETTING_WINDOW));
			else
				this.startTimer();
		}
		
		public function Pause() : void
		{
			if(!_isRecording) return;
			if(_isPausing)
			{
				_startTime = getTimer();
				_microphone.addEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
				_isPausing = false;
				dispatchEvent(new MicrophoneRecEvent(MicrophoneRecEvent.RECORD_RESTORE));
				this.startTimer();
			}
			else
			{
				_microphone.removeEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
				_isPausing = true;
				_fullTime += getTimer() - _startTime;
				dispatchEvent(new MicrophoneRecEvent(MicrophoneRecEvent.RECORD_PAUSE));
				this.stopTimer();
			}
		}
		
		public function Stop() : void
		{
			if(!_isPausing) _fullTime += getTimer() - _startTime;
			
			if(_microphone.hasEventListener(SampleDataEvent.SAMPLE_DATA))
				_microphone.removeEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
			if(_microphone.hasEventListener(StatusEvent.STATUS))
				_microphone.removeEventListener(StatusEvent.STATUS, onStatus);
			_buffer.position = 0;
			
			_output = this.createWAVFileData(_buffer, 1);
			_isRecording = false;
			_isPausing = false;
			
			dispatchEvent(new MicrophoneRecEvent(MicrophoneRecEvent.RECORD_STOP));
			this.stopTimer();
		}
		
		public function Clear() : void
		{
			_startTime = _fullTime = 0;
			_buffer.clear();
			if(mp3Encoder)
			{
				mp3Encoder.mp3Data.clear();
				mp3Encoder.mp3Data = null;
				mp3Encoder.wavData.clear();
				mp3Encoder.wavData = null;
				mp3Encoder = null;
			}
			dispatchEvent(new MicrophoneRecEvent(MicrophoneRecEvent.CLEARED));
		}
		
		
		
		
		/****************************************************************************
		 * private function
		 ****************************************************************************/
		
		private function startTimer() : void
		{
			_timer.addEventListener(TimerEvent.TIMER, OnRecTimer);
			_timer.start();
		}
		
		private function stopTimer() : void
		{
			_timer.stop();
			_timer.removeEventListener(TimerEvent.TIMER, OnRecTimer);
		}
		
		private function OnRecTimer(event : TimerEvent) : void
		{
			dispatchEvent(new MicrophoneRecEvent(MicrophoneRecEvent.RECORD_TIME,false,false,"",this.recordTime));
		}
		
		private function onStatus(event : StatusEvent) : void
		{
			if(event.code == "Microphone.Unmuted" && !_timer.running) startTimer();
			if(event.code == "Microphone.Muted" && _timer.running) stopTimer();
			
			//ExternalInterface.call("window.console.log", onStatus);
			trace("onStatus : " + event);
		}
		
		private function onSampleData(event : SampleDataEvent) : void
		{
			while(event.data.bytesAvailable > 0)
			{
				_buffer.writeFloat(event.data.readFloat());
			}
			dispatchEvent(new MicrophoneRecEvent(MicrophoneRecEvent.NEW_DATA_AVAIBLE));
		}
		
		// prepare WAV file data
		private function CreateWavFile(bytes:ByteArray) : ByteArray
		{
			var _wavBuffer : ByteArray = new ByteArray();
			_wavBuffer.endian = Endian.LITTLE_ENDIAN;
			_wavBuffer.length = 0;
			bytes.position = 0;
			
			while(bytes.bytesAvailable)
			{
				_wavBuffer.writeShort(bytes.readFloat() * (0x7fff * _wavVolume));
			}
			return _wavBuffer;
		}

		// create WAV-file structured data
		private function createWAVFileData(samples : ByteArray, channels : int = 2, bits : int = 16, rate : int = 44100) : ByteArray
		{
			var data : ByteArray = this.CreateWavFile(samples);
			var _wavBytes : ByteArray = new ByteArray();
			_wavBytes.length = 0;
			_wavBytes.endian = Endian.LITTLE_ENDIAN;
			_wavBytes.writeUTFBytes("RIFF");
			_wavBytes.writeInt(uint(data.length + 44 ));
			_wavBytes.writeUTFBytes("WAVE");
			_wavBytes.writeUTFBytes("fmt ");
			_wavBytes.writeInt(uint(16));
			_wavBytes.writeShort(uint(1));
			_wavBytes.writeShort(channels);
			_wavBytes.writeInt(rate);
			_wavBytes.writeInt(uint(rate * channels * ( bits >> 3 )));
			_wavBytes.writeShort(uint(channels * ( bits >> 3 )));
			_wavBytes.writeShort(bits);
			_wavBytes.writeUTFBytes("data");
			_wavBytes.writeInt(data.length);
			_wavBytes.writeBytes(data);
			_wavBytes.position = 0;
			
			return _wavBytes;
		}
		
		public function EncodeToMP3() : void
		{
			if(mp3Encoder) mp3Encoder = null;
			
			mp3Encoder = new ShineMP3Encoder(this.output);
			mp3Encoder.addEventListener(Event.COMPLETE, mp3EncodeComplete);
			mp3Encoder.addEventListener(ProgressEvent.PROGRESS, mp3EncodeProgress);
			mp3Encoder.addEventListener(ErrorEvent.ERROR, mp3EncodeError);
			mp3Encoder.start();
			dispatchEvent(new MicrophoneRecEvent(MicrophoneRecEvent.ENCODE_START));
		}
		
		public function get mp3output() : ByteArray
		{
			return mp3Encoder ? mp3Encoder.mp3Data : null;
		}
		
		private function mp3EncodeProgress(event : ProgressEvent) : void
		{
//			trace("mp3EncodeProgress ", event.bytesLoaded);
			event.stopPropagation();
			dispatchEvent(new MicrophoneRecEvent(MicrophoneRecEvent.ENCODE_PROGRESS,false,false,"",event.bytesLoaded));
		}
		
		private function mp3EncodeError(event : ErrorEvent) : void
		{
//			trace("mp3EncodeError ", event.text);
			event.stopPropagation();
			dispatchEvent(new MicrophoneRecEvent(MicrophoneRecEvent.ENCODE_ERROR,false,false,event.text));
		}
		
		private function mp3EncodeComplete(event : Event) : void
		{
//			trace("mp3EncodeComplete");
			event.stopPropagation();
			dispatchEvent(new MicrophoneRecEvent(MicrophoneRecEvent.ENCODE_COMPLETE));
		}
	}
}