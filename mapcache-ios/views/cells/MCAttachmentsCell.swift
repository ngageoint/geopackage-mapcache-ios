//
//  MCMediaCell.swift
//  mapcache-ios
//
//  Created by Tyler Burgett on 4/27/21.
//  Copyright © 2021 NGA. All rights reserved.
//

import Foundation

@objc protocol MCShowAttachmentDelegate: AnyObject {
    @objc func showAttachment(mediaRow:GPKGMediaRow)
    @objc func showAttachment(image:UIImage, index:NSNumber)
}

class MCAttachmentsCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet weak var collectionView: UICollectionView!
    var mediaArray = NSArray()
    @objc var attachmentDelegate:MCShowAttachmentDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.register(UINib.init(nibName: "MCMediaCell", bundle: nil), forCellWithReuseIdentifier: "mediaCell")
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 128, height: 128)
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 1)
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumInteritemSpacing = 0.0
        self.collectionView.collectionViewLayout = flowLayout
        
        self.backgroundColor = .clear
    }
    
    
    @objc func setContents(mediaArray:NSArray) {
        self.mediaArray = mediaArray
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.mediaArray.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "mediaCell", for: indexPath) as! MCMediaCell
        
        if let mediaRow:GPKGMediaRow = self.mediaArray.object(at: indexPath.row) as? GPKGMediaRow {
            if let image:UIImage = mediaRow.dataImage() {
                cell.imageView.image = image
            }
        } else if let image:UIImage = self.mediaArray.object(at: indexPath.row) as? UIImage {
            cell.imageView.image = image
        }
        
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let delegate = self.attachmentDelegate {
            if let mediaRow:GPKGMediaRow = self.mediaArray.object(at: indexPath.row) as? GPKGMediaRow {
                delegate.showAttachment(mediaRow: mediaRow)
            } else if let image:UIImage = self.mediaArray.object(at: indexPath.row) as? UIImage {
                delegate.showAttachment(image: image, index: indexPath.row as NSNumber)
            }
        }
    }
}
