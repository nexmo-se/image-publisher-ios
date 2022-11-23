//
//  ViewController.swift
//  publish-image-to-video
//
//  Created by iujie on 21/11/2022.
//

import UIKit
import OpenTok

// Replace with your OpenTok API key
let kApiKey = ""
// Replace with your generated session ID
let kSessionId = ""
// Replace with your generated token
let kToken = ""


let kWidgetHeight = 240
let kWidgetWidth = 320
let screenSize: CGRect = UIScreen.main.bounds;
let screenWidth = screenSize.width;
let screenHeight = screenSize.height;

class ViewController: UIViewController {
    lazy var session: OTSession = {
        return OTSession(apiKey: kApiKey, sessionId: kSessionId, delegate: self)!
    }()

    var publisher: OTPublisher?
    var subscriber: OTSubscriber?
    var capturer: ImageCapturer?
    var imageLoaded: UIImage?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageLoaded = loadImageFromDocumentDirectory(fileName: "vonage-image")
        addImageView()
        doConnect()
    }
    
    /**
     * Add image to UIImageView
     */
    private func addImageView() {
        let imageView = UIImageView(image: imageLoaded!)
                
        imageView.frame = CGRect(x: Int(screenWidth) - kWidgetWidth - 20, y: Int(screenHeight) - kWidgetHeight - 20, width: kWidgetWidth, height: kWidgetHeight)
        view.addSubview(imageView)
    }
    
    /**
     * Asynchronously begins the session connect process. Some time later, we will
     * expect a delegate method to call us back with the results of this action.
     */
    private func doConnect() {
        var error: OTError?
        defer {
            process(error: error)
        }
        session.connect(withToken: kToken, error: &error)
    }
    
    /**
     * Sets up an instance of OTPublisher to use with this session. OTPubilsher
     * binds to the device camera and microphone, and will provide A/V streams
     * to the OpenTok session.
     */
    fileprivate func doPublish() {
        var error: OTError? = nil
        defer {
            process(error: error)
        }
        let settings = OTPublisherSettings()
        settings.name = UIDevice.current.name
        publisher = OTPublisher(delegate: self, settings: settings)
        publisher?.videoType = .screen
        publisher?.audioFallbackEnabled = false
        publisher?.publishAudio = false

        capturer = ImageCapturer(image: imageLoaded!)
        publisher?.videoCapture = capturer
        
        session.publish(publisher!, error: &error)
    }
    
    fileprivate func doSubscribe(_ stream: OTStream) {
        var error: OTError?
        defer {
            process(error: error)
        }
        subscriber = OTSubscriber(stream: stream, delegate: self)
        
        session.subscribe(subscriber!, error: &error)
    }
    
    fileprivate func process(error err: OTError?) {
        if let e = err {
            showAlert(errorStr: e.localizedDescription)
        }
    }
    
    fileprivate func showAlert(errorStr err: String) {
        DispatchQueue.main.async {
            let controller = UIAlertController(title: "Error", message: err, preferredStyle: .alert)
            controller.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    fileprivate func loadImageFromDocumentDirectory(fileName: String) -> UIImage? {
        if let path = Bundle.main.path(forResource:fileName, ofType: "png") {
            let fileUrl = URL.init(fileURLWithPath: path)
            print("path", path)
            print("fileUrl", fileUrl)

            do {

                let imageData = try Data(contentsOf: fileUrl)
                print("image data", imageData)
                return UIImage(data: imageData)
            } catch {
                print("here", error)
            }
        }
  
        return nil
    }
    
}

extension ViewController: OTSessionDelegate {
    func sessionDidConnect(_ session: OTSession) {
        print("Session connected")
        doPublish()
    }
    
    func sessionDidDisconnect(_ session: OTSession) {
        print("Session disconnected")
    }
    
    func session(_ session: OTSession, streamCreated stream: OTStream) {
        print("Session streamCreated: \(stream.streamId)")
        doSubscribe(stream)
    }
    
    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        print("Session streamDestroyed: \(stream.streamId)")
    }
    
    func session(_ session: OTSession, didFailWithError error: OTError) {
        print("session Failed to connect: \(error.localizedDescription)")
    }
}

// MARK: - OTPublisher delegate callbacks
extension ViewController: OTPublisherDelegate {
    func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
    }
    
    func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
    }
    
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        print("Publisher failed: \(error.localizedDescription)")
    }
}

// MARK: - OTSubscriber delegate callbacks
extension ViewController: OTSubscriberDelegate {
    func subscriberDidConnect(toStream subscriberKit: OTSubscriberKit) {
        if let subsView = subscriber?.view {
            subsView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
            view.addSubview(subsView)
            view.sendSubviewToBack(subsView);
        }
    }

    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("Subscriber failed: \(error.localizedDescription)")
    }

    func subscriberVideoDataReceived(_ subscriber: OTSubscriber) {
    }
}
