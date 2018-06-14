//
//  ViewController.swift
//  TCPSocketClient
//
//  Created by sanjingrihua on 17/6/20.
//  Copyright © 2017年 sanjingrihua. All rights reserved.
//

import UIKit
import Foundation
let PORT : UInt32 = 9000
let HOST :CFString = "127.0.0.1" as CFString
let BUFFER_SIZE = 1024
class ViewController: UIViewController,StreamDelegate {

    var flag = -1;//操作标志 0为发送 1为接收
    
    @IBOutlet var receiveLab: UILabel!
    @IBOutlet var sendTF: UITextField!
    
    var inputStream : InputStream?
    var outputStream : OutputStream?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    private func initNetWorkCommunication(){
        var readStream:Unmanaged<CFReadStream>?//声明变量类型 泛型类型 Unmanaged是非自动内存管理(非托管对象)，需要将非托管对象转换为托管对象
        var writeStream: Unmanaged<CFWriteStream>?
        
        //实现与服务器进行连接，并返回输入／输出流对象 参数：内存分配方式；服务器IP；服务器端口；返回输入流对象；返回输出流对象
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, HOST, PORT, &readStream, &writeStream)
        
        //takeUnretainedValue转换托管对象，但不保持内存对象，内存引用计数不变，不会转让对象所有权
        self.inputStream = readStream!.takeUnretainedValue()
        self.inputStream!.delegate = self
        self.inputStream!.schedule(in: RunLoop.current, forMode: RunLoopMode.commonModes)//设置runloop
        self.inputStream!.open()
        
        self.outputStream = writeStream!.takeUnretainedValue()
        self.outputStream!.delegate = self
        self.outputStream!.schedule(in: RunLoop.current, forMode: RunLoopMode.commonModes)
        self.outputStream!.open()//打开流对象
    }
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        
        var event: String?
        
        switch eventCode {
        case Stream.Event.openCompleted:
            event = "StreamEventOpenCompleted"
        case Stream.Event.hasBytesAvailable:
            event = "StreamEventHasBytesAvailable"
            if flag==1 && aStream == self.inputStream {
                var input = NSMutableData()
                
                var buf = UnsafeMutablePointer<UInt8>.allocate(capacity: BUFFER_SIZE)
                var len = 0
                
                while self.inputStream!.hasBytesAvailable {
                    len = self.inputStream!.read(buf, maxLength: BUFFER_SIZE)
                    if len>0 {
                        input.append(buf, length: len)
                    }
                }
                var resultstring = NSString(data:input as Data,encoding: String.Encoding.utf8.rawValue)
                print(resultstring!)
                
                self.receiveLab.text = resultstring! as String
            }
        case Stream.Event.hasSpaceAvailable:
            event = "StreamEventHasSpaceAvailable"
            
            if flag==0 && aStream == self.outputStream {
                //输出
                var sendString : String = self.sendTF.text!
                var data = sendString.data(using: String.Encoding.utf8, allowLossyConversion: true)
                var buffer = [UInt8](repeating:0,count:(data?.count)!)

//data?.bindMemory(to: UInt8.self, capacity: len)
                
                self.outputStream!.write(&buffer, maxLength: (data?.count)!)
                self.close()
                
                
            }
        case Stream.Event.errorOccurred:
            event = "StreamEventErrorOccurred"
            self.close()
        case Stream.Event.endEncountered:
            event = "StreamEventEndEncountered"
            print("Error:%d:%@",aStream.streamError!,aStream.streamError!.localizedDescription);
            
        default:
            self.close()
            event = "Unknown"
        }
        NSLog("event----------%@", event!)
    }
    private func close(){
        self.outputStream!.close()
        self.outputStream!.remove(from: RunLoop.current, forMode: RunLoopMode.commonModes)
        self.outputStream!.delegate = nil
        
        self.inputStream!.close()
        self.inputStream!.remove(from: RunLoop.current, forMode: RunLoopMode.commonModes)
        self.inputStream!.delegate = nil
        
    }
    
    
    
    @IBAction func sendData(_ sender: UIButton) {
        flag = 0
        self.initNetWorkCommunication()
    }
    @IBAction func receiveData(_ sender: Any) {
        flag = 1
        self.initNetWorkCommunication()
    }
    


}

