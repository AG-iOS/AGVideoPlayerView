//
//  ViewController.swift
//
//  Created by Andrey Golovin on 17.02.17.
//  Copyright © 2017 Andrey Golovin. All rights reserved.
//

import UIKit

class MediaCell: UITableViewCell {
    @IBOutlet weak var playerView: AGVideoPlayerView!
}

class ViewController: UIViewController {

    var items: [URL]!
    var images: [URL?]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        items = [URL(string: "http://www.sample-videos.com/video/mp4/720/big_buck_bunny_720p_1mb.mp4")!,
            URL(string: "http://yt-dash-mse-test.commondatastorage.googleapis.com/media/car-20120827-85.mp4")!,
        URL(string: "http://yt-dash-mse-test.commondatastorage.googleapis.com/media/oops-20120802-85.mp4")!,
        URL(string: "http://yt-dash-mse-test.commondatastorage.googleapis.com/media/motion-20120802-85.mp4")!]
        
        images = [URL(string: "https://i.ytimg.com/vi/aqz-KE-bpKQ/maxresdefault.jpg"),
                  URL(string: "http://www.bialystok.pl/resource/video-thumb/192/334/6102/14724/750x415.jpg"),
                  nil,
                  nil]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MediaCell", for: indexPath) as! MediaCell
        let index = indexPath.row % 4
        let video = items[index]
        let image = images[index]
        
        cell.playerView.videoUrl = video
        cell.playerView.previewImageUrl = image
        cell.playerView.shouldAutoplay = true
        cell.playerView.shouldAutoRepeat = true
        cell.playerView.showsCustomControls = false
        cell.playerView.shouldAutofullscreen = true
        return cell
    }
}
