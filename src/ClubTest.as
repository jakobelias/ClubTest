package
{
	import com.rainbowcreatures.FWVideoEncoder;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.StageVideoAvailabilityEvent;
	import flash.events.StageVideoEvent;
	import flash.events.StatusEvent;
	import flash.geom.Rectangle;
	import flash.media.Camera;
	import flash.media.CameraPosition;
	import flash.media.StageVideo;
	import flash.media.StageVideoAvailability;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	
	[SWF(frameRate="20", width="1364", height="768", backgroundColor="0xffffff")]
	public class ClubTest extends Sprite
	{
	
		private var animatedTextfield:TextField;	
		private var camera:Camera;       
		private var myEncoder:FWVideoEncoder;   
		private var phase:String;
		private var video:Video;
		private var videoContainer:Sprite;
		private var ns:NetStream;
		
		private var stageVideoAvail:Boolean;
		private var svYou:StageVideo;
		private var svMille:StageVideo;
		
		// Used to save video captured with camera
		private var encodedVideo:ByteArray;
		
		private var startButton:MovieClip;
		private var playbackButton:MovieClip;
		private var saveButton:MovieClip;
	
		public function ClubTest()
			{
				super();
				stage.align = StageAlign.TOP_LEFT;
				stage.scaleMode = StageScaleMode.NO_SCALE;
				
				drawScene();
			}
		
		private function drawScene():void
		{
			startButton = new MovieClip();
			startButton.graphics.beginFill(0xcccccc);
			startButton.graphics.drawRect(0, 0, 600, 100);
			startButton.graphics.endFill();
			var tf:TextField = new TextField();
			tf.width = 600;
			var tfm:TextFormat = new TextFormat();
			tf.text = "START OPTAGELSE";
			tfm.color = 0x00aaaa;
			tfm.size = 60;
			tf.setTextFormat(tfm);
			startButton.addChild(tf);
			tf.y = 20;
			addChild(startButton);
			startButton.x = 200;
			startButton.y = 150;
			startButton.addEventListener(MouseEvent.CLICK, startRecordingWithMusicVideo);
		}
	
		// recording while showing music video in full screen and yourself in small area
		private function startRecordingWithMusicVideo(event:MouseEvent):void
		{
			trace("ClubTest.startRecordingWithMusicVideo(event)");
			removeChild(startButton);
			
			animatedTextfield = new TextField();
			animatedTextfield.width = 500;

			var tfm:TextFormat = new TextFormat();
			animatedTextfield.text = "Ramasjang Club";
			tfm.color = 0xff9966;
			tfm.size = 60;
			animatedTextfield.setTextFormat(tfm);

			this.addChild(animatedTextfield);
			animatedTextfield.x = -100;
			animatedTextfield.y = 200;
			
			setTimeout(function(){
				playMusicVideo();
				createVideoCameraStuff();
				initFlashyWrapper();
			}, 1000);
		}
		
		private function playMusicVideo():void
		{
			trace("ClubTest.playMusicVideo()");
			stage.addEventListener(StageVideoAvailabilityEvent.STAGE_VIDEO_AVAILABILITY, onAvail);
		}
		
		
		private function onAvail(e:StageVideoAvailabilityEvent):void
		{
			stageVideoAvail = (e.availability == StageVideoAvailability.AVAILABLE);
			initMusicVideo();
		}
		
		private function initMusicVideo():void
		{
			var nc:NetConnection = new NetConnection();
			nc.connect(null);
			ns = new NetStream(nc);
			var customClient:Object = new Object(); 
			customClient.onMetaData = onMetaData; 
			customClient.onMXPData = onMXPData; 
			ns.client = customClient; 

			// true on mobile
			if(stageVideoAvail)
			{
				svMille = stage.stageVideos[0];
				svMille.addEventListener(StageVideoEvent.RENDER_STATE, onRenderMille);
				svMille.attachNetStream(ns);
				trace('stageVideo available');
			}
			// true on desktop
			else
			{
				var vid:Video = new Video(1024, 768);
				addChild(vid);
				vid.attachNetStream(ns);
				trace('stageVideo not available');
			}
			ns.play('assets/music_video_test.mp4');
			
			// These methods are requiered, but don't have to be implemented
			function onMetaData(infoObject:Object):void 
			{ 
				var key:String; 
				for (key in infoObject) 
				{ 
					trace(key + ": " + infoObject[key]); 
				} 
			}
			
			function onMXPData(infoObject:Object):void 
			{ 
				var key:String; 
				for (key in infoObject) 
				{ 
					trace(key + ": " + infoObject[key]); 
				} 
			}
		}
		
		// create viewport for StageVideo
		private function onRenderYou(e:StageVideoEvent):void
		{
			svYou.viewPort = new Rectangle(0, 0, 1024, 768);
		}
		
		private function onRenderMille(e:StageVideoEvent):void
		{
			svMille.viewPort = new Rectangle(0, 0, 1364, 768);
		}
		
		
		private function createVideoCameraStuff():void
		{
			trace("Camera.names: " + Camera.names);
			
			camera = tryGetFrontCamera();   
			
			if (camera == null)
			{
				trace ("No camera is installed.");
			} 
			else 
			{
				trace("Camera is installed.");
				camera.setMode( 1024, 768, 60, true );
			}
			
			videoContainer = new Sprite();
			this.addChild(videoContainer);
			
			video = new Video(camera.width, camera.height);
			video.attachCamera(camera);
			videoContainer.addChild(video);
			videoContainer.width = 512;
			videoContainer.height = 384;
			videoContainer.x = 500;
			videoContainer.y = 300;
		}
		
		public function tryGetFrontCamera():Camera {
			var numCameras:uint = (Camera.isSupported) ? Camera.names.length : 0;
			for (var i:uint = 0; i < numCameras; i++) {
				var cam = Camera.getCamera(String(i));
				if (cam && cam.position == CameraPosition.FRONT) {
					return cam;
				}
			} 
			return null;
		}
		
		private function initFlashyWrapper():void
		{
			// Flasy Wrapper code
			phase = "record";
			myEncoder = FWVideoEncoder.getInstance(this); 
			
			setTimeout(function(){
				myEncoder.addEventListener(StatusEvent.STATUS, onStatus);
				myEncoder.load();
			}, 3000);
			
			setTimeout(function(){
				phase = "recordStage";
			}, 7000);
			
			// stop recording - FlashyWrappers trial version allows only 18 seconds of recording
			setTimeout(function(){
				phase = "recording_finished";
			}, 22000);
		}
		

		
		private function onStatus(e:StatusEvent):void { // FW is ready!
			trace("ClubTest.onStatus(e)");
			trace("e.code: " + e.code);
			
			// Experimenting with different settings for FWVideoEncoder instance
			if (e.code == "ready") {
//				myEncoder.setFps(24); // configure FW before calling start() 
//				myEncoder.start(24, FWVideoEncoder.AUDIO_MICROPHONE, false);
				
				myEncoder.start(24, "audioOn", false, videoContainer.width, videoContainer.height); 
//				myEncoder.forcePTSMode(FWVideoEncoder.PTS_REALTIME); 
//				myEncoder.forceFramedropMode(FWVideoEncoder.FRAMEDROP_ON);
				
//				myEncoder.start(20);				
				
			}
			
			// encoder started, start capturing frames as soon as possible
			if (e.code == "started") {
				addEventListener(Event.ENTER_FRAME, onFrame);
			}
			
			// video is ready!
			if (e.code == "encoded") {
				
				encodedVideo = myEncoder.getVideo();
//				trace("encoding done - encodedVideo: " + encodedVideo);
				
				trace("myEncoder.mergedFilePath: " + myEncoder.mergedFilePath);
				trace("myEncoder.mergedFile.nativePath: " + myEncoder.mergedFile.nativePath);
				trace("myEncoder.mergedFile.name: " + myEncoder.mergedFile.name);
				
				// Path to ByteArray to use with NetStream
				trace("myEncoder.mergedFile.url: " + myEncoder.mergedFile.url);
				
				showMenu();				
			} 
		}
		
		private function showMenu():void
		{
			removeChild(videoContainer);
			ns.close();
			
			// Make Playback button
			playbackButton = new MovieClip();
			playbackButton.graphics.beginFill(0xcccccc);
			playbackButton.graphics.drawRect(0, 0, 600, 100);
			playbackButton.graphics.endFill();
			var tf:TextField = new TextField();
			tf.width = 600;
			var tfm:TextFormat = new TextFormat();
			tf.text = "AFSPIL VIDEO";
			tfm.color = 0x00aaaa;
			tfm.size = 60;
			tf.setTextFormat(tfm);
			playbackButton.addChild(tf);
			tf.y = 20;
			addChild(playbackButton);
			playbackButton.x = 200;
			playbackButton.y = 50;
			playbackButton.addEventListener(MouseEvent.CLICK, playbackButtonListener);

			// Make save button
			saveButton = new MovieClip();
			saveButton.graphics.beginFill(0xcccccc);
			saveButton.graphics.drawRect(0, 0, 600, 100);
			saveButton.graphics.endFill();
			var tf:TextField = new TextField();
			tf.width = 600;
			var tfm:TextFormat = new TextFormat();
			tf.text = "GEM VIDEO";
			tfm.color = 0x00aaaa;
			tfm.size = 60;
			tf.setTextFormat(tfm);
			saveButton.addChild(tf);
			tf.y = 20;
			addChild(saveButton);
			saveButton.x = 200;
			saveButton.y = 200;
			saveButton.addEventListener(MouseEvent.CLICK, saveButtonListener);

			
		}		
		
		protected function saveButtonListener(event:MouseEvent):void
		{
			ns.close();
			removeChild(playbackButton);
			removeChild(saveButton);
			myEncoder.saveToGallery();
		}
		
		protected function playbackButtonListener(event:MouseEvent):void
		{
			ns.close();
			removeChild(playbackButton);
			removeChild(saveButton);
			playbackRecordedVideo(myEncoder.mergedFile.url);
		}		
		
		private function playbackRecordedVideo(path:String):void
		{
			trace("ClubTest.playbackRecordedVideo()");

			
			var nc:NetConnection = new NetConnection();
			nc.connect(null);
			var ns:NetStream = new NetStream(nc);
	
			var customClient:Object = new Object(); 
			customClient.onMetaData = onMetaData; 
			customClient.onMXPData = onMXPData; 
			ns.client = customClient; 
			
			
			svYou = stage.stageVideos[0];
			svYou.addEventListener(StageVideoEvent.RENDER_STATE, onRenderYou);
			svYou.attachNetStream(ns);
			
			// play original and recently recorded videos interchangeably
			ns.play(path);
			
			setTimeout(function(){
				ns.play('assets/music_video_test.mp4');
				trace("ns.time before seek: " + ns.time);
				ns.seek(ns.time + 5);
				trace("ns.time after seek: " + ns.time);
			}, 5000);
			
			setTimeout(function(){
				ns.play(path, 20);
			}, 20000);
			
		
			function onMetaData(infoObject:Object):void 
			{ 
				trace("ClubTest.onMetaData(infoObject)");
				
				var key:String; 
				for (key in infoObject) 
				{ 
					trace(key + ": " + infoObject[key]); 
				} 
			}
			
			function onMXPData(infoObject:Object):void 
			{ 
				trace("ClubTest.onMXPData(infoObject)");
				
				var key:String; 
				for (key in infoObject) 
				{ 
					trace(key + ": " + infoObject[key]); 
				} 
			}
		}
		
		private function onFrame(e:Event):void {			
			// capture camera input each frame
			if (phase == "record") {
				myEncoder.capture(videoContainer);
				
				// no args - capture whole stage
//				myEncoder.capture();
			}
			
			// capture the whole stage each frame
			if (phase == "recordStage") {
				myEncoder.capture(videoContainer);
//				myEncoder.capture();
			}

			// finished the recording, so call finish
			if (phase == "recording_finished") {
				myEncoder.finish(); // now wait for 'encoded' status event
				removeEventListener(Event.ENTER_FRAME, onFrame);
			}
			
			animatedTextfield.x++;
		}
	}
}