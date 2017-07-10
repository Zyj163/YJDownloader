//
//  ViewController.swift
//  YJDownloader
//
//  Created by Zyj163 on 06/23/2017.
//  Copyright (c) 2017 Zyj163. All rights reserved.
//

import UIKit
import Foundation
import YJDownloader

class ViewController: UIViewController {
	
	let downloaders = YJDownloaders.downloaders
	
	let url0 = URL(string: "http://160721.142.unicom.data.tv002.com:443/down/24ac8168eba1a6efe85400518eacc8ae-14080607/CloudMounter10%20Cr%20.dmg?cts=wt-f-D211A144A1A50&ctp=211A144A1A50&ctt=1498209275&limit=1&spd=200000&ctk=249a11509563164a52f6b530aee2db7a&chk=24ac8168eba1a6efe85400518eacc8ae-14080607")!
	
	let url2 = URL(string: "http://211.94.109.18:9999/sw.bos.baidu.com/sw-search-sp/software/447feea06f61e/QQ_mac_5.5.1.dmg")!
	
	let url3 = URL(string: "http://211.94.109.18:9999/sw.bos.baidu.com/sw-search-sp/software/28e3e9a56da44/BaiduNetdisk_mac_2.2.0.dmg")!
	
	let url4 = URL(string: "http://211.94.109.18:9999/sw.bos.baidu.com/sw-search-sp/software/f30aa450a6de9/QQMusicMac_5.0.dmg")!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		downloaders.maxRunningCount = 3
	}
	
	@IBOutlet weak var progress: UIProgressView!
	@IBOutlet weak var progress2: UIProgressView!
	@IBOutlet weak var progress3: UIProgressView!
	@IBOutlet weak var progress4: UIProgressView!
	
	
	@IBOutlet weak var label: UILabel!
	@IBOutlet weak var label2: UILabel!
	@IBOutlet weak var label3: UILabel!
	@IBOutlet weak var label4: UILabel!
	
	@IBAction func download(_ sender: UIButton) {
		
        downloaders.yj_download(url(for: sender.tag), stateChanged: {[weak self]  (state: YJDownloaderState, newState: YJDownloaderState) in
			switch newState {
			case .paused:
				print("pause")
				self?.setLabel(sender.tag, color: .purple)
			case .downloading:
				self?.setLabel(sender.tag, color: .green)
			case .success(let filePath):
				print("success tag:\(sender.tag), filePath: \(filePath)")
				self?.setLabel(sender.tag, color: .black)
			case .failed(let error):
				print("failed tag:\(sender.tag), error: \(String(describing: error))")
			case .cancelled(let downloadingPath, let downloadedPath):
				print("cancelled tag:\(sender.tag), downloadingPath: \(downloadingPath), downloadedPath: \(downloadedPath)")
				self?.setLabel(sender.tag, color: .red)
			case .waitting:
				print("waitting tag:\(sender.tag)")
				self?.setLabel(sender.tag, color: .yellow)
			default:
				print("unknown tag:\(sender.tag)")
				self?.setLabel(sender.tag, color: .red)
			}
		}, progressChanged: {[weak self] (progress: Double) in
			self?.setProgress(sender.tag, value: progress)
			self?.setLabel(sender.tag, color: .green, value: String(format: "%.2f", progress))
        }, receiveTotalSize: { (totalSize: UInt64) in
			print("totalSize: \(totalSize), tag:\(sender.tag)")
		})
		
	}

	@IBAction func pause(_ sender: UIButton) {
		downloaders.yj_pause(url(for: sender.tag))
	}
	@IBAction func cancel(_ sender: UIButton) {
		downloaders.yj_cancel(url(for: sender.tag))
	}
	@IBAction func resume(_ sender: UIButton) {
		downloaders.yj_resume(url(for: sender.tag))
	}
	@IBAction func remove(_ sender: UIButton) {
		downloaders.yj_removeTmpFiles([url(for: sender.tag)])
	}
	@IBAction func removecache(_ sender: UIButton) {
		downloaders.yj_removeCacheFiles([url(for: sender.tag)])
	}
	
	
	func url(for tag: Int) -> URL {
		switch tag {
		case 0:
			return url0
		case 1:
			return url2
		case 2:
			return url3
		case 3:
			return url4
		default:
			return URL(string: "http:")!
		}
	}
	
	func setLabel(_ tag: Int, color: UIColor, value: String? = nil) {
		DispatchQueue.main.async {
			switch tag  {
			case 0:
				self.label.textColor = color
				self.label.text = value ?? self.label.text
			case 1:
				self.label2.textColor = color
				self.label2.text = value ?? self.label2.text
			case 2:
				self.label3.textColor = color
				self.label3.text = value ?? self.label3.text
			case 3:
				self.label4.textColor = color
				self.label4.text = value ?? self.label4.text
			default:
				break
			}
		}
	}
	
	func setProgress(_ tag: Int, value: Double) {
		DispatchQueue.main.async {
			let v = Float(value)
			switch tag  {
			case 0:
				self.progress.progress = Float(v)
			case 1:
				self.progress2.progress = Float(v)
			case 2:
				self.progress3.progress = Float(v)
			case 3:
				self.progress4.progress = Float(v)
			default:
				break
			}
		}
	}
	
	@IBAction func remove_tmp(_ sender: Any) {
		downloaders.yj_removeTmp()
	}
	
	@IBAction func remove_cache(_ sender: Any) {
		downloaders.yj_removeCache()
	}
	
}

