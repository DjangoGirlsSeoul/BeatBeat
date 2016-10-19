//
// Copyright 2016 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
import UIKit
import AVFoundation
import googleapis
import Alamofire
import SwiftyJSON
import NVActivityIndicatorView
import BusyNavigationBar
import AudioToolbox

let SAMPLE_RATE = 16000
let SOUNDCLOUD_API_URL = "https://api.soundcloud.com/tracks"
let SOUNDCLOUD_CLIENT_ID = "47a689f09f10188a86a416728f91cf5a"
let SOCKET_SERVER_IP = "10.10.5.198"
let SONGS_NOT_FOUND = "Keep trying! (◕‿◕)"

private var progressViewKVOContext = 0

class ViewController : UIViewController, AudioControllerDelegate, StreamDelegate,UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Outlets
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var languageControl: UISegmentedControl!
    
    @IBOutlet weak var songTableView: UITableView!
    
    @IBOutlet weak var speakingTimeProgress: UIProgressView!
    
    @IBOutlet weak var speakButton: UIButton!
    
    @IBOutlet weak var countDownButton: UIButton!
    

    @IBOutlet weak var searchSongActivityIndicator: NVActivityIndicatorView!
    
     // MARK: - properties
    
    var testIndicator : NVActivityIndicatorView!
    
    var audioData: NSMutableData!
    var trackUrl: String?
    var player: AVPlayer! = nil
    
    var inputStream: InputStream?
    var outputStream : OutputStream?
    var isPlaying: Bool = false
    var locale:String = "en-US"
    var stopAudio: Bool = false
    var songTitleArray : [String?] = []
    var artWorkURLArray : [String] = []
    var waveFormURLArray : [String] = []
    var trackURIArray : [String] = []
    var searchTerms : String = ""
    var oldPlayButton : UIButton?
    var options = BusyNavigationBarOptions()
    var SOCKET_PORT: Int!
    
    let defaults = UserDefaults.standard
    var BYTES_PER_SAMPLE:Int = 8  // original = 2
    var debugMode : Bool = false
    private let progress = Progress(totalUnitCount: 60)
    private var updateTimer: Timer?
    
    
    // MARK: - Initialization
    
    deinit {
        // Unregister as an observer of the `NSProgress`'s `fractionCompleted` property.
        progress.removeObserver(self, forKeyPath: "fractionCompleted")
    }

    
     // MARK: - ViewController Lifecycle
    
    override func viewDidAppear(_ animated: Bool) {
        
        print("viewDidAppear")
        
        let orientationValue = UIInterfaceOrientation.landscapeLeft.rawValue
        UIDevice.current.setValue(orientationValue, forKey: "orientation")
        
        if (defaults.bool(forKey:SettingsViewController.SOCKET_KEY )) {
            if let ipAdress = self.defaults.string(forKey: SettingsViewController.IPADDRESS_KEY) {
                self.initNetworkCommunication(ipAddress: ipAdress)
            }
        }
        if (defaults.integer(forKey: SettingsViewController.BYTES_PER_SAMPLE_KEY) == 0) {
            defaults.set(8, forKey: SettingsViewController.BYTES_PER_SAMPLE_KEY)
            BYTES_PER_SAMPLE = 8
        } else {
            
            BYTES_PER_SAMPLE = defaults.integer(forKey: SettingsViewController.BYTES_PER_SAMPLE_KEY)
        }
        
        if(defaults.integer(forKey: SettingsViewController.PORT_NUMBER_KEY) == 0) {
            defaults.set(10001, forKey: SettingsViewController.PORT_NUMBER_KEY)
            SOCKET_PORT = 10001
        } else {
            SOCKET_PORT = defaults.integer(forKey: SettingsViewController.PORT_NUMBER_KEY)
        }
        
        debugMode = defaults.bool(forKey: SettingsViewController.DEBUG_KEY)

    }
    
  override func viewDidLoad() {
    super.viewDidLoad()
    AudioController.sharedInstance.delegate = self

    configureLanguageSegmentControl()
    testIndicator = NVActivityIndicatorView(frame: CGRect(x: 400, y: 160, width: 80, height: 60), type: .audioEqualizer, color: UIColor.red, padding: 0.0)
    
    NVActivityIndicatorView.DEFAULT_TYPE = .audioEqualizer
    NVActivityIndicatorView.DEFAULT_COLOR = UIColor.red
    options.animationType = .Bars
    options.color = UIColor.white
    options.alpha = 1.0
    options.barWidth = 20
    options.gapWidth = 30
    options.speed = 1
    options.transparentMaskEnabled = true

    self.view.addSubview(testIndicator)
    self.textView.bringSubview(toFront: searchSongActivityIndicator)
  }

  @IBAction func recordAudio(_ sender: NSObject) {
    
    if(stopAudio) {
        
        print("stopAudio by user")
        _ = AudioController.sharedInstance.stop()
        SpeechRecognitionService.sharedInstance.stopStreaming()
        stopAudioUI()
        return
    }
    
    recordAudioUI()
    print("record Audio")
    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setCategory(AVAudioSessionCategoryRecord)
    } catch {

    }
    audioData = NSMutableData()
    _ = AudioController.sharedInstance.prepare(specifiedSampleRate: SAMPLE_RATE)
    SpeechRecognitionService.sharedInstance.sampleRate = SAMPLE_RATE
    _ = AudioController.sharedInstance.start()
    stopAudio = true
  }
    
    
    
  func processSampleData(_ data: Data) -> Void {
    audioData.append(data)

    // We recommend sending samples in 100ms chunks
    let chunkSize : Int /* bytes/chunk */ = Int(0.1 /* seconds/chunk */
      * Double(SAMPLE_RATE) /* samples/second */
      * Double(BYTES_PER_SAMPLE) /* bytes/sample */);

    print("chunk_size :\(chunkSize)")
    
    if (audioData.length > chunkSize) {
      SpeechRecognitionService.sharedInstance.streamAudioData(audioData,
                                                              completion:
        { (response, error) in
          if let error = error {
            if(self.debugMode) {
                
                self.textView.text = error.localizedDescription
            } else {
                print("error : \(error.localizedDescription) error_code : \(error.code)")
            }
          } else if let response = response {
            var finished = false
//            print(response)
            let arrayCount = response.resultsArray_Count
            print("array_count \(arrayCount)")
            for result in response.resultsArray! {
              if let result = result as? StreamingRecognitionResult {
                
                let alternativeArray = result.alternativesArray! as NSArray as! [SpeechRecognitionAlternative]
                print("single_result : \(alternativeArray[0].transcript)")
                
                if result.isFinal {
                    finished = true
                    print("single_result_is_final : \(alternativeArray[0].transcript!)")
                    self.searchTerms += " \(alternativeArray[0].transcript!)"
                }
              }
            }
            if(self.debugMode) {
                self.textView.text = response.description
            }
            
            print("speech_response : \(response.description)")
            //TODO:
        
               print("response_endPointerType : \(response.endpointerType.rawValue)")
            
                switch(response.endpointerType.rawValue) {
                
                    case 1: //START_OF_SPEECH
                        print("START_OF_SPEECH")
                        break
                    
                    case 2:  //END_OF_SPEECH
                    print("END_OF_SPEECH")
                    break
                    case 3:// END_OF_AUDIO
                         print("END_OF_AUDIO")
                        break
                    case 4: break // END_OF_UTTERANCE
                    
                    default: break
                
                }

            if finished {
                if (self.searchTerms.isEmpty) {
                    self.textView.text = "Searching a 🎵 for you"
                    self.getTracksFromSoundCloud(query:"game of thrones")
                    
                } else {
                    self.textView.text = "You searched 🎵 : \(self.searchTerms)"
                    self.getTracksFromSoundCloud(query:self.searchTerms)
                    
                }
            }
          }
      })
      self.audioData = NSMutableData()
    }
  }
    
    func getTracksFromSoundCloud(query: String) {
        
        print("search sound cloud with q: \(query)")
        let parameters = ["q": query,
                          "order" : "hotness",
                          "limit" : 3,
                          "client_id" : SOUNDCLOUD_CLIENT_ID] as Parameters!
        
        

        Alamofire.request(SOUNDCLOUD_API_URL, parameters: parameters).responseJSON { response in
            switch response.result {
                
            case .success(let value):
                let tracks = JSON(value)
//                print("json : \(json)")
                self.songTitleArray = [String]()
                self.artWorkURLArray = [String]()
                self.waveFormURLArray = [String]()
                self.trackURIArray = [String]()
                self.searchSongActivityIndicator.stopAnimating()
                if(tracks.count == 0) {
                    self.textView.text = SONGS_NOT_FOUND
                    return;
                }
                for i in 0...(tracks.count-1) {
                    
                    self.songTitleArray.append(tracks[i]["title"].stringValue)
                    self.artWorkURLArray.append(tracks[i]["artwork_url"].stringValue)
                    
                    self.waveFormURLArray.append(tracks[i]["waveform_url"].stringValue)
                    
                    self.trackURIArray.append(tracks[i]["uri"].stringValue)
                }
                
                self.songTableView.reloadData()
                
            case .failure(let error):
                print(error)
            }        }
    }
    
    func playSong(track_url : String?) {
    
    
        if let track_url = track_url  {
            do {
                let url = URL(string: track_url)
                let playerItem = AVPlayerItem(url: url!)
                self.player = try AVPlayer(playerItem:playerItem)
                self.player!.volume = 1.0
                self.player!.play()
                self.isPlaying = true
                print("playSong - started")
            } catch let error as NSError {
                self.player = nil
                print(error.localizedDescription)
            } catch {
                print("AVAudioPlayer init failed")
            }
        }
 
        
    }
    
    func stopSong() {
    
        
        if (self.isPlaying && self.player != nil) {
            self.player!.pause()
            self.isPlaying = false
            return
        }
    
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("viewWillDisappear")
        

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        print("viewDidDisappear")
        
        stopSong()
        
        // Stop the timer from firing.
        updateTimer?.invalidate()
        
        // Close streams 
        
        inputStream?.close()
        outputStream?.close()
    }
    
    // MARK: - Key Value Observing (KVO)
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        // Check if this is the KVO notification for our `NSProgress` object.
        if context == &progressViewKVOContext && keyPath == "fractionCompleted" && object as! NSObject === progress {
            // Update the progress views.
            speakingTimeProgress.setProgress(Float(progress.fractionCompleted), animated: true)
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change , context: context)
        }
        
    }
    
    func initNetworkCommunication(ipAddress : String) {
     
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
//        
     CFStreamCreatePairWithSocketToHost(nil,  ipAddress as CFString!, UInt32(SOCKET_PORT), &readStream, &writeStream)
    
        inputStream = readStream!.takeRetainedValue()
        outputStream = writeStream!.takeRetainedValue()
        
        inputStream?.delegate = self
        outputStream?.delegate = self
        
        inputStream?.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        outputStream?.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        
        inputStream?.open()
        outputStream?.open()
        
        
    }

    // MARK StreamDelegate method
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        
        print("Stream : \(aStream) handle eventCode: \(eventCode) ")
        
        switch (eventCode) {
            
        case Stream.Event.openCompleted:
            print("openCompleted")
            break;
            
        case Stream.Event.hasBytesAvailable:
            print("hasBytesAvailable")
            break;
        case Stream.Event.errorOccurred:
            print("errorOccurred")
            break;
            
        default:
            break;
        
        
        }
        
    }
    
    // MARK TableView Delegate methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if(self.songTitleArray.count != 0) {
            return self.songTitleArray.count
        } else  {
            return 1;
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
            print("touched row at : \(indexPath.row)")
        
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        print("deselect row at : \(indexPath.row)")
        let cell = tableView.cellForRow(at: indexPath) as! SongTableViewCell
        cell.playButton.imageView?.image = UIImage(named: "play_circle")
        
        if(debugMode) {
            stopSong()
        } else {
            if (self.isPlaying) {
                self.isPlaying = false
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:SongTableViewCell = tableView.dequeueReusableCell(withIdentifier: "songcell") as! SongTableViewCell
        
        cell.playButton.imageView?.tintColor  = UIColor.red
        
        if(self.songTitleArray.count != 0) {
        
            cell.playButton.tag = indexPath.row
            cell.playButton.addTarget(self, action: #selector(ViewController.didTouchPlay(sender:)), for: UIControlEvents.touchUpInside)
            
            if let title = self.songTitleArray[indexPath.row] {
 
                cell.songTitle.text = title
            }
    
            let artWorkURL = NSURL(string:self.artWorkURLArray[indexPath.row])
            let waveFormURL = NSURL(string:self.waveFormURLArray[indexPath.row])
            
            DispatchQueue.main.async(execute: {
                if(artWorkURL != nil) {
                
                    if let imageData = NSData(contentsOf: artWorkURL as! URL) {
                        cell.artWorkImage.image  = UIImage(data: imageData as Data)
                    }
                }
                
                if(waveFormURL != nil) {
                    
                    if let imageData = NSData(contentsOf: waveFormURL as! URL) {
                        cell.waveFormImage.image  = UIImage(data: imageData as Data)
                    }
                }
            })
        }
    
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return "Songs List"
    }
    
    func updateProgressBar() {
    
        /*
         Reset the `completedUnitCount` of the `NSProgress` object and create
         a repeating timer to increment it over time.
         */
        speakingTimeProgress.setProgress(0.0, animated: false)
        progress.completedUnitCount = 0
        updateTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ViewController.timerDidFire), userInfo: nil, repeats: true)
    
    }
    
    // MARK: - Timer
    
    func timerDidFire() {
        /*
         Update the `completedUnitCount` of the `NSProgress` object if it's
         not completed. Otherwise, stop the timer.
         */
        if progress.completedUnitCount < progress.totalUnitCount {
            progress.completedUnitCount += 1
            countDownButton.setTitle("\(60 - progress.completedUnitCount)", for: UIControlState.normal)
        }
        else {
            updateTimer?.invalidate()
            // Stop timer
            self.recordAudio(self)
            self.textView.text = "Press 🎙 button to search ♫!"
            self.textView.textColor = UIColor.blue
            countDownButton.setTitle("60", for: UIControlState.normal)
        }
    }

    func resgiterObserverForProgress () {
    
        // Register as an observer of the `NSProgress`'s `fractionCompleted` property.
        progress.addObserver(self, forKeyPath: "fractionCompleted", options: [.new], context: &progressViewKVOContext)
    }
    
    func unRegisterObserverForProgress () {
    
        // Unregister as an observer of the `NSProgress`'s `fractionCompleted` property.
        progress.removeObserver(self, forKeyPath: "fractionCompleted")
    }
    
    func configureLanguageSegmentControl() {
        
        languageControl.addTarget(self, action: #selector(ViewController.selectedSegmentDidChange(segmentedControl:)), for: .valueChanged)
    
        if (defaults.bool(forKey: SettingsViewController.LANGUAGE_KEY)) {
            languageControl.selectedSegmentIndex = 1
            
        } else {
            languageControl.selectedSegmentIndex = 0
            print("English selected")
            
        }
    }
    
    
    func selectedSegmentDidChange(segmentedControl: UISegmentedControl) {
        NSLog("The selected segment changed for : \(segmentedControl.selectedSegmentIndex))")
        
        if (segmentedControl.selectedSegmentIndex == 1) {
            defaults.set(true, forKey: SettingsViewController.LANGUAGE_KEY)
        } else {
            defaults.set(false, forKey: SettingsViewController.LANGUAGE_KEY)
        }
    }
    
    //MARK : Uitility methods
    
    func stopAudioUI() {
    
        searchSongActivityIndicator.stopAnimating()
        testIndicator.stopAnimating()
        speakButton.setImage(UIImage(named: "mic"), for: UIControlState.normal)
        stopAudio = false
        updateTimer?.invalidate()
        unRegisterObserverForProgress()
        if(!searchTerms.isEmpty) {
            self.textView.text = "You searched : \(searchTerms)"
            self.searchTerms = ""
        } else  {
            self.textView.text = "Press 🎙 button to search ♫"
        }
        countDownButton.setTitle("60", for: UIControlState.normal)
        speakingTimeProgress.setProgress(0.0, animated: true)
    }
    
    func recordAudioUI() {
        
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        searchSongActivityIndicator.startAnimating()
        testIndicator.startAnimating()
        self.textView.text = "Processing...."
        updateProgressBar()
        resgiterObserverForProgress()
        speakButton.setImage(UIImage(named: "StopButton"), for: UIControlState.normal)
    
    }
    
    func didTouchPlay(sender: UIButton) {
        
        if(self.songTitleArray.count == 0) {
            return
        }
        
        if let button = oldPlayButton {
            button.setImage(UIImage(named: "play_circle"), for: UIControlState.normal)
            oldPlayButton = nil
        } else {
            oldPlayButton = sender
        }
        
        print("play button selected at index :\(sender.tag)")
        
        if(self.songTitleArray.count != 0) {
            
            let track_uri = self.trackURIArray[sender.tag]
            self.trackUrl = track_uri + "/stream?client_id=\(SOUNDCLOUD_CLIENT_ID)"
            if(self.isPlaying) {
                sender.setImage(UIImage(named: "play_circle"), for: UIControlState.normal)
                if(debugMode) {
                    self.stopSong()
                }
                self.isPlaying = false
                //                self.recordAudio(self)
                let data = "stop".data(using: String.Encoding.utf8)! as Data
                let bytesWritten = data.withUnsafeBytes { self.outputStream?.write($0, maxLength: data.count) }
                print("bytesWritten - stop: \(bytesWritten)")
                // Stop animation
                self.navigationController?.navigationBar.stop()
            } else {
                sender.setImage(UIImage(named: "pause_circle"), for: UIControlState.normal)

                if(debugMode) {
                    self.playSong(track_url: self.trackUrl)
                } else {
                    self.isPlaying = true
                }
                if(stopAudio) {
                    self.recordAudio(self)
                }
                self.textView.text = "Now Playing : \(songTitleArray[sender.tag]!) ♫ "
                let data = self.trackUrl!.data(using: String.Encoding.utf8)! as Data
                let bytesWritten = data.withUnsafeBytes { self.outputStream?.write($0, maxLength: data.count) }
                print("bytesWritten - play: \(bytesWritten)")
                // Start animation
                self.navigationController?.navigationBar.start(options: options)

            }
            print("track_uri : \(self.trackUrl)")
            
        }
        
    }
    
    @IBAction func didTouchRefreshSocket(_ sender: UIBarButtonItem) {
        
        // Close streams
        
        inputStream?.close()
        outputStream?.close()
        
        if (defaults.bool(forKey:SettingsViewController.SOCKET_KEY )) {
            if let ipAdress = self.defaults.string(forKey: SettingsViewController.IPADDRESS_KEY) {
                self.initNetworkCommunication(ipAddress: ipAdress)
            }
        }
    }
    
    

}
