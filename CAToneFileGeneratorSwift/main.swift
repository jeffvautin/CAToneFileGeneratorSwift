//
//  main.swift
//  CAToneFileGeneratorSwift
//
//  Created by Jeff Vautin on 12/23/15.
//  Copyright © 2015 Jeff Vautin. All rights reserved.
//

import Foundation
import AudioToolbox

let SAMPLE_RATE = 44100.0
let DURATION = 5.0
let FILENAME_FORMAT = "%0.3f-square.aif"

if (Process.argc < 2) {
    print("Usage: CAToneFileGenerator n\n(where n is tone in Hz)")
    exit(1)
}

let hz = (Process.arguments[1] as NSString).doubleValue
assert(hz > 0)
print("generating %f hz tone", hz)

let fileName = NSString(format: FILENAME_FORMAT, hz)
let filePath = (NSFileManager.defaultManager().currentDirectoryPath as NSString).stringByAppendingPathComponent(fileName as String)
let fileURL = NSURL.fileURLWithPath(filePath)

// Prepare the format
var asbd = AudioStreamBasicDescription()
asbd.mSampleRate = SAMPLE_RATE
asbd.mFormatID = kAudioFormatLinearPCM
asbd.mFormatFlags = kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
asbd.mBitsPerChannel = 16
asbd.mChannelsPerFrame = 1
asbd.mFramesPerPacket = 1
asbd.mBytesPerFrame = 2
asbd.mBytesPerPacket = 2

// Set up the file
var audioFile = AudioFileID()
var audioErr = noErr
audioErr = AudioFileCreateWithURL(fileURL,
    kAudioFileAIFFType,
    &asbd,
    .EraseFile,
    &audioFile)
assert(audioErr == noErr)

// Start writing samples
let maxSampleCount = Int(SAMPLE_RATE * DURATION)
var sampleCount = 0
var bytesToWrite: UInt32 = 2
let wavelengthInSamples = SAMPLE_RATE / hz

while (sampleCount < maxSampleCount) {
    for index in 0 ... Int(wavelengthInSamples) {
        // Square wave
        var sample: Int16
        if (index < Int(wavelengthInSamples/2)) {
            sample = Int16.max.bigEndian
        } else {
            sample = Int16.min.bigEndian
        }
        
        audioErr = AudioFileWriteBytes(audioFile,
            false,
            Int64(sampleCount * 2),
            &bytesToWrite,
            &sample)
        assert(audioErr == noErr)
        sampleCount += 1
    }
}

audioErr = AudioFileClose(audioFile)
assert(audioErr == noErr)
print("wrote %ld samples", sampleCount)