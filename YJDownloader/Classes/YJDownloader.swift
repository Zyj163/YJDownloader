//
//  YJDownloader.swift
//  YJDownloader
//
//  Created by ddn on 2017/6/23.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import Foundation

public func == (left: YJDownloaderState, right: YJDownloaderState) -> Bool {
    return left.value == right.value
}

public func == (left: YJDownloaderState, right: (String)->YJDownloaderState) -> Bool {
    return left.value == right("").value
}

public func != (left: YJDownloaderState, right: (String)->YJDownloaderState) -> Bool {
    return left.value != right("").value
}

public func == (left: YJDownloaderState, right: (String, String)->YJDownloaderState) -> Bool {
    return left.value == right("", "").value
}

public func == (left: YJDownloaderState, right: (UInt64)->YJDownloaderState) -> Bool {
    return left.value == right(0).value
}

public func != (left: YJDownloaderState, right: (UInt64)->YJDownloaderState) -> Bool {
    return left.value == right(0).value
}

public func == (left: YJDownloaderState, right: (Error?)->YJDownloaderState) -> Bool {
    return left.value == right(nil).value
}

public func != (left: YJDownloaderState, right: YJDownloaderState) -> Bool {
    return left.value != right.value
}

public enum YJDownloaderState {
    case unknown
    case paused(String, String)
    case cancelled(String, String)
    case downloading(UInt64) //触发这个状态时正在接收的数据大小
    case failed(Error?)
    case success(String) //文件路径
    case waitting
    
    var value: String {
        switch self {
        case .unknown:
            return "unknown"
        case .paused:
            return "paused"
        case .cancelled:
            return "cancelled"
        case .downloading:
            return "downloading"
        case .failed:
            return "failed"
        case .success:
            return "success"
        case .waitting:
            return "waitting"
        }
    }
}

public class YJDownloaderItem {
    
    public var url: URL!
    
    public var stateChanged: ((YJDownloaderState, YJDownloaderState)->Void)?
    
    public var progressChanged: ((Double)->Void)?
    
    public var receiveTotalSize: ((UInt64)->Void)?
    
    public var destination: String?
    
    public var specRequest: ((NSMutableURLRequest)->Void)?
    
    public var getMimeType: ((String?)->Void)?
    
    public convenience init(_ url: URL) {
        self.init()
        self.url = url
    }
}

public class YJDownloader: NSObject {
    
    fileprivate weak var task: URLSessionDataTask?
    fileprivate var downloadPath: String?
    fileprivate var downloadingPath: String?
    
    fileprivate var tmpPath: String?
    fileprivate var cachePath: String?
    
    fileprivate var tmpSize: UInt64 = 0
    fileprivate var totalSize: UInt64 = 0
    fileprivate var output: OutputStream?
    
    fileprivate var session: URLSession?
    
    fileprivate var _state: YJDownloaderState = .unknown {
        didSet {
            downloadItem.stateChanged?(oldValue, _state)
        }
    }
    
    fileprivate var _progress: Double = 0 {
        didSet {
            if _progress == oldValue {
                return
            }
            downloadItem.progressChanged?(progress)
        }
    }
    
    fileprivate var downloadItem: YJDownloaderItem!
    
    fileprivate var _lastOffset: UInt64 = 0
    
    public var lastOffset: UInt64 {
        return _lastOffset
    }
    
    public var state: YJDownloaderState {
        return _state
    }
    
    public var progress: Double {
        return _progress
    }
}

extension YJDownloader {
    public convenience init(_ session: URLSession? = nil, tmpPath: String? = nil, cachePath: String? = nil) {
        self.init()
        self.session = session
        self.tmpPath = tmpPath
        self.cachePath = cachePath
        
        if self.tmpPath == nil {
            self.tmpPath = YJFileTool.tmp().appending("/yjdownloads")
        }
        if self.cachePath == nil {
            self.cachePath = YJFileTool.cache().appending("/yjdownloads")
        }
        
        YJFileTool.create(self.tmpPath)
        YJFileTool.create(self.cachePath)
    }
}

extension YJDownloader {
    
    public func yj_start() {
        let fileName = downloadItem.url!.lastPathComponent
        
        downloadingPath = tmpPath!.appending("/\(fileName)")
        
        if let destination = downloadItem.destination {
            downloadPath = destination
        } else {
            downloadPath = cachePath!.appending("/\(fileName)")
        }
        
        if self.downloadItem.url == task?.originalRequest?.url {
            
            switch state {
            case .paused:
                yj_resume()
                return
            case .downloading:
                return
            default:
                break
            }
        }
        
        yj_cancel()
        
        guard !YJFileTool.exists(downloadPath) else {
            _state = .success(downloadPath!)
            return
        }
        
        guard YJFileTool.exists(downloadingPath) else {
            download(downloadItem.url, specRequest: downloadItem.specRequest)
            return
        }
        
        tmpSize = YJFileTool.size(downloadingPath)
        download(downloadItem.url, offset: tmpSize, specRequest: downloadItem.specRequest)
    }
    
    public func yj_download(_ item: YJDownloaderItem, immediately: Bool = true) {
        self.downloadItem = item
        if immediately {
            yj_start()
        } else {
            _state = .waitting
        }
    }
    
    public func yj_cancel() {
        task?.cancel()
        _state = .cancelled(downloadingPath!, downloadPath!)
    }
    
    public func yj_resume() {
        if let task = task, _state == YJDownloaderState.paused || _state == YJDownloaderState.cancelled {
            task.resume()
            _state = .downloading(0)
        }
    }
    
    public func yj_pause() {
        switch state {
        case .downloading:
            task?.suspend()
            _state = .paused(downloadingPath!, downloadPath!)
        default:
            break
        }
    }
    
    public func yj_setWaitting() {
        switch state {
        case .downloading:
            return
        default:
            break
        }
        
        if let _ = task {
            _state = .waitting
        }
    }
    
    public func yj_destroy() {
        yj_cancel()
        YJFileTool.remove(downloadingPath)
    }
    
    public func yj_removeTmp() {
        yj_cancel()
        YJFileTool.remove(downloadingPath)
    }
    
    public func yj_removeCache() {
        YJFileTool.remove(downloadPath)
    }
}


extension YJDownloader {
    
    public func download(_ url: URL, offset: UInt64 = 0, specRequest: ((NSMutableURLRequest)->Void)? = nil) {
        if session == nil {
            let config = URLSessionConfiguration.default
            session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        }
        _lastOffset = offset
        let request = NSMutableURLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 0)
        request.setValue("bytes=\(offset)-", forHTTPHeaderField: "Range")
        specRequest?(request)
        task = session?.dataTask(with: request as URLRequest)
        yj_resume()
    }
}

extension YJDownloader: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        totalSize = UInt64((response as! HTTPURLResponse).allHeaderFields["Content-Length"] as? String ?? "0") ?? 0
        if let contentRangeStr = (response as! HTTPURLResponse).allHeaderFields["Content-Range"] as? String, contentRangeStr.characters.count != 0, let lastStr = contentRangeStr.components(separatedBy: "/").last {
            totalSize = UInt64(lastStr) ?? 0
        }
        
        downloadItem.getMimeType?(response.mimeType)
        downloadItem.receiveTotalSize?(totalSize)
        
        if tmpSize > 0, tmpSize == totalSize {
            YJFileTool.move(downloadingPath, toPath: downloadPath)
            completionHandler(.cancel)
            _state = .success(downloadPath!)
        } else if tmpSize > totalSize {
            YJFileTool.remove(downloadingPath)
            completionHandler(.cancel)
            yj_download(downloadItem)
            return
        }
        
        _state = .downloading(0)
        output = OutputStream(toFileAtPath: downloadingPath!, append: true)
        output?.open()
        completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        tmpSize = UInt64(data.count) + tmpSize
        
        _progress = Double(tmpSize) / Double(totalSize)
        
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        data.copyBytes(to: buffer, count: data.count)
        output?.write(buffer, maxLength: data.count)
        
        _state = .downloading(UInt64(data.count))
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error == nil {
            if YJFileTool.size(downloadingPath) == totalSize {
                YJFileTool.move(downloadingPath, toPath: downloadPath)
                _state = .success(downloadPath!)
            } else {
                YJFileTool.remove(downloadingPath)
                _state = .failed(error)
            }
        } else {
            if (error! as NSError).code == -999 {
                _state = .paused(downloadingPath!, downloadPath!)
            } else {
                YJFileTool.remove(downloadingPath)
                _state = .failed(error)
            }
        }
        switch state {
        case .success, .failed:
            output?.close()
        default:
            break
        }
    }
}







