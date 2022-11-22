//
//  VideoRender.swift
//  publish-image-to-video
//
//  Created by iujie on 22/11/2022.
//

import OpenTok
import GLKit

protocol VideoRenderDelegate {
    func renderer(_ renderer: VideoRender, didReceiveFrame videoFrame: OTVideoFrame)
}

class VideoRender: NSObject, OTVideoRender {
    var delegate: VideoRenderDelegate?

    func renderVideoFrame(_ frame: OTVideoFrame) {
        if let format = frame.format {
        var lastVideoFrame = OTVideoFrame(format: format)
             lastVideoFrame.timestamp = frame.timestamp
             
             let planeSize = calculatePlaneSize(forFrame: frame)
             let yPlane = UnsafeMutablePointer<GLubyte>.allocate(capacity: planeSize.ySize)
             let uPlane = UnsafeMutablePointer<GLubyte>.allocate(capacity: planeSize.uSize)
             let vPlane = UnsafeMutablePointer<GLubyte>.allocate(capacity: planeSize.vSize)
             
             memcpy(yPlane, frame.planes?.pointer(at: 0), planeSize.ySize)
             memcpy(uPlane, frame.planes?.pointer(at: 1), planeSize.uSize)
             memcpy(vPlane, frame.planes?.pointer(at: 2), planeSize.vSize)
             
             lastVideoFrame.planes?.addPointer(yPlane)
             lastVideoFrame.planes?.addPointer(uPlane)
             lastVideoFrame.planes?.addPointer(vPlane)
             
             
             if let delegate = delegate {
                 delegate.renderer(self, didReceiveFrame: frame)
             }
        }
    }
}
    
fileprivate func calculatePlaneSize(forFrame frame: OTVideoFrame) -> (ySize: Int, uSize: Int, vSize: Int) {
        guard let frameFormat = frame.format
            else {
                return (0, 0 ,0)
        }
        let baseSize = Int(frameFormat.imageWidth * frameFormat.imageHeight) * MemoryLayout<GLubyte>.size
        return (baseSize, baseSize / 4, baseSize / 4)
}



