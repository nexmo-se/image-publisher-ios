//
//  VideoCapturer.swift
//  publish-image-to-video
//
//  Created by iujie on 21/11/2022.
//

import OpenTok
import AVFoundation

extension AVCaptureSession.Preset {
    func dimensionForCapturePreset() -> (width: UInt32, height: UInt32) {
        switch self {
        case AVCaptureSession.Preset.cif352x288: return (352, 288)
        case AVCaptureSession.Preset.vga640x480, AVCaptureSession.Preset.high: return (640, 480)
        case AVCaptureSession.Preset.low: return (192, 144)
        case AVCaptureSession.Preset.medium: return (480, 360)
        case AVCaptureSession.Preset.hd1280x720: return (1280, 720)
        default: return (352, 288)
        }
    }
}

protocol FrameCapturerMetadataDelegate {
    func finishPreparingFrame(_ videoFrame: OTVideoFrame?)
}

class VideoCapturer: NSObject, OTVideoCapture {
    var videoCaptureConsumer: OTVideoCaptureConsumer?
    var videoContentHint: OTVideoContentHint = .none
    var captureSession: AVCaptureSession?
    var imageLoaded: UIImage?
    var delegate: FrameCapturerMetadataDelegate?
    
    fileprivate var captureWidth: UInt32
    fileprivate var captureHeight: UInt32
    fileprivate var capturing = false
    fileprivate let videoFrame: OTVideoFrame
    
    func initCapture() {
        print("init capture")
        self.imageLoaded = self.loadImageFromDocumentDirectory(fileName: "vonage-image")
        // show ui image
        print(self.imageLoaded as Any)
    }
    
    func releaseCapture() {
        print("release capture")
    }
    
    func start() -> Int32 {
        self.capturing = true
        self.newFrame()
        return 0
    }
    
    func stop() -> Int32 {
        capturing = false
        return 0
    }
    
    func isCaptureStarted() -> Bool {
        return capturing && (captureSession != nil)
    }
    
    func captureSettings(_ videoFormat: OTVideoFormat) -> Int32 {
        return 0
    }
    
    
//    var videoCaptureConsumer: OTVideoCaptureConsumer?
//
//    var videoContentHint: OTVideoContentHint
//    fileprivate let videoFrame: OTVideoFrame
    
    override init() {
        // Read image file
        self.captureWidth = 640
        self.captureHeight = 320
        videoFrame = OTVideoFrame(format: OTVideoFormat(argbWithWidth: captureWidth, height: captureHeight))
         
        // change to image width and image height
//        videoFrame = OTVideoFrame(format: OTVideoFormat(nv12WithWidth: captureWidth, height: captureHeight))
    }
    
    
    fileprivate func newFrame() {
        if (self.imageLoaded !== nil) {

            videoFrame.timestamp = CMTime(seconds: 60, preferredTimescale: 1000000)

            videoFrame.format?.imageWidth = UInt32((self.imageLoaded?.size.width)!)
            videoFrame.format?.imageHeight =  UInt32((self.imageLoaded?.size.height)!)

            videoFrame.format?.estimatedFramesPerSecond = 1
            videoFrame.format?.estimatedCaptureDelay = 100
            videoFrame.orientation = .left

            videoFrame.clearPlanes()
            
            let imageBuffer = buffer(from: imageLoaded!)
            print("image buffer", imageBuffer)
            CVPixelBufferLockBaseAddress(imageBuffer!, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))

            if (imageBuffer == nil) {return;}
            print("planar", CVPixelBufferIsPlanar(imageBuffer!) )

            if !CVPixelBufferIsPlanar(imageBuffer!) {
                videoFrame.planes?.addPointer(CVPixelBufferGetBaseAddress(imageBuffer!))
            } else {
                print("plane count", CVPixelBufferGetPlaneCount(imageBuffer!) )

                for idx in 0..<CVPixelBufferGetPlaneCount(imageBuffer!) {
                    print("pointer", CVPixelBufferGetBaseAddressOfPlane(imageBuffer!, idx))

                    videoFrame.planes?.addPointer(CVPixelBufferGetBaseAddressOfPlane(imageBuffer!, idx))
                }
            }
//            videoFrame.format?.pixelFormat = OTPixelFormatARGB
            print("video frame height", UInt32((self.imageLoaded?.size.height)!))
            print("video frame width", UInt32((self.imageLoaded?.size.width)!))

            print("video frame orientation", videoFrame.orientation)
            print("video frame timestamp", videoFrame.timestamp)
            print("video frame planes", CVPixelBufferGetBaseAddress(imageBuffer!))

            
            if let delegate = delegate {
                  delegate.finishPreparingFrame(videoFrame)
              }
            
            videoCaptureConsumer!.consumeFrame(videoFrame)
//            print("video frame", videoCaptureConsumer)
            CVPixelBufferUnlockBaseAddress(imageBuffer!, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)));

        }
    }
    
    fileprivate func buffer(from image: UIImage) -> CVPixelBuffer? {
      let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
      var pixelBuffer : CVPixelBuffer?
      let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
      guard (status == kCVReturnSuccess) else {
        return nil
      }

      CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
      let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

      let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
      let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

      context?.translateBy(x: 0, y: image.size.height)
      context?.scaleBy(x: 1.0, y: -1.0)

      UIGraphicsPushContext(context!)
      image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
      UIGraphicsPopContext()
      CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

      return pixelBuffer
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

