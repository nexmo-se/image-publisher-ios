
# Publish an Image as a video stream

1. Run "pod install" to install opentok dependencies
2. Edit ViewController.swift and add the kToken, kSessionId id and kApiKey
3. Run the app and join from Vonage Video playground to see the published stream.

## How it works

1. This sample uses a preloaded image. vonage-image.png is added to the project resources
2. At run time, we convert this image into a Bitmap
3. We use this bitmap to publish as screen sharing using custom video capturer.
4. We have used frame rate = 1 as no motion is needed.