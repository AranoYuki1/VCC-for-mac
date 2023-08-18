//
//  FileHandler+Strea.swift
//  CoreUtil
//
//  Created by yuki on 2023/01/07.
//

import Foundation
import Promise

extension FileHandle {
    public final class Stream {
        public enum StreamError: Error {
            case decodeError
        }
        
        private var subscribers = [(Data)->()]()
        
        internal func receiveData(_ data: Data) {
            for subscriber in subscribers { subscriber(data) }
        }
        
        public func readToEnd() -> Promise<Data, Never> {
            var buffer = Data()
            let promise = Promise<Data, Never>()
            self.subscribers.append{
                if $0.isEmpty { promise.resolve(buffer) }
                buffer += $0
            }
            return promise
        }
        
        public func bytesPublisher() -> some Publisher<UInt8, Never> {
            let publisher = PassthroughSubject<UInt8, Never>()
            self.subscribers.append{ for c in $0 { publisher.send(c) } }
            return publisher
        }
        
        public func characterPublisher(using encoding: String.Encoding) -> some Publisher<Character, Error> {
            let publisher = PassthroughSubject<Character, Error>()
            
            self.subscribers.append{ data in
                guard let string = String(data: data, encoding: encoding) else {
                    return publisher.send(completion: .failure(StreamError.decodeError))
                }
                for c in string { publisher.send(c) }
            }
            
            return publisher
        }
        
        public func linePublisher(using encoding: String.Encoding, skipEmptyLine: Bool = true) -> some Publisher<String, Error> {
            let publisher = PassthroughSubject<String, Error>()
            var buffer = [Unicode.Scalar]()
            
            func sendBuffer() {
                var line = ""; line.unicodeScalars.append(contentsOf: buffer)
                if skipEmptyLine && line.isEmpty { return }
                publisher.send(line)
                buffer.removeAll(keepingCapacity: true)
            }
            
            self.subscribers.append{ data in
                if data.isEmpty {
                    sendBuffer()
                }
                
                guard let string = String(data: data, encoding: encoding) else {
                    return publisher.send(completion: .failure(StreamError.decodeError))
                }
                
                for scalar in string.unicodeScalars {
                    if CharacterSet.newlines.contains(scalar) {
                        sendBuffer()
                    } else {
                        buffer.append(scalar)
                    }
                }
            }
            
            return publisher
        }
    }
    
    public func stream() -> Stream {
        enum __ { static var key = 0 }
        return objc_getAssociatedObject(self, &__.key) as? Stream ?? Stream() => { stream in
            self.setDataCallback{ stream.receiveData($0) }
            objc_setAssociatedObject(self, &__.key, stream, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private func setDataCallback(_ body: @escaping (Data) -> ()) {
        self._streamQueue.async {
            var data: Data
            repeat {
                data = self.availableData
                body(data)
            } while (data.count > 0)
        }
    }
    
    private var _streamQueue: DispatchQueue {
        enum __ { static var key = 0 }
        return objc_getAssociatedObject(self, &__.key) as? DispatchQueue ?? DispatchQueue(label: "filehandle.read") => {
            objc_setAssociatedObject(self, &__.key, $0, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
