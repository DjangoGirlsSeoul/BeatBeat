//
//  SongTableViewCell.swift
//  BeatBeat
//
//  Created by Hassan Abid on 10/10/16.
//  Copyright © 2016 Google. All rights reserved.
//

import UIKit

class SongTableViewCell: UITableViewCell {

    @IBOutlet weak var artWorkImage: UIImageView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var songTitle: UILabel!
    @IBOutlet weak var waveFormImage: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
