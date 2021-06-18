//
//  MCMapPointAttachmentViewController.swift
//  mapcache-ios
//
//  Created by Tyler Burgett on 5/14/21.
//  Copyright © 2021 NGA. All rights reserved.
//

import Foundation
import UIKit

protocol MCPointAttachmentDelegate: AnyObject {
    func deleteAttachment()
}


class MCMapPointAttachmentViewController: NGADrawerViewController, UITableViewDelegate, UITableViewDataSource, MCDualButtonCellDelegate {
    var cellArray: Array<UITableViewCell> = []
    var tableView: UITableView = UITableView()
    var haveScrolled: Bool = false
    var contentOffset: CGFloat = 0.0
    var imageCell: MCImageCell?
    let shareAction = "share"
    let deleteAction = "delete"
    @objc var image: UIImage?
    var buttonsCell: MCDualButtonCell?
    var row: GPKGUserRow?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let bounds: CGRect = self.view.bounds
        let insetBounds: CGRect = CGRect.init(x: bounds.origin.x, y: bounds.origin.y + 32, width: bounds.size.width, height: bounds.size.height)
        self.tableView = UITableView.init(frame: insetBounds, style: UITableView.Style.plain)
        self.tableView.autoresizingMask.insert(.flexibleWidth)
        self.tableView.autoresizingMask.insert(.flexibleHeight)
        self.tableView.separatorStyle = .none
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.estimatedRowHeight = 140
        self.tableView.rowHeight = UITableView.automaticDimension
        self.extendedLayoutIncludesOpaqueBars = false
        self.haveScrolled = false
        
        addAndConstrainSubview(self.tableView)
        registerCellTypes()
        initCellArray()
        addDragHandle()
        addCloseButton()
    }
    
    
    func registerCellTypes() {
        self.tableView.register(UINib.init(nibName: "MCImageCell", bundle: nil), forCellReuseIdentifier: "image")
        self.tableView.register(UINib.init(nibName: "MCDualButtonCell", bundle: nil), forCellReuseIdentifier: "dualButtons")
    }
    
    
    func initCellArray() {
        self.cellArray.removeAll()
        self.imageCell = (self.tableView.dequeueReusableCell(withIdentifier: "image") as! MCImageCell)
        self.imageCell?.mediaView.image = self.image
        self.imageCell?.mediaView.contentMode = .scaleAspectFit
        self.cellArray.append(self.imageCell!)
        
        self.buttonsCell = (self.tableView.dequeueReusableCell(withIdentifier: "dualButtons") as! MCDualButtonCell)
        self.buttonsCell?.setLeftButtonLabel("")
        self.buttonsCell?.leftButtonAction = shareAction
        self.buttonsCell?.leftButtonUseClearBackground()
        self.buttonsCell?.leftButton?.setImage(UIImage.init(named: "Share"), for: .normal)
        self.buttonsCell?.setRightButtonLabel("")
        self.buttonsCell?.rightButtonAction = deleteAction
        self.buttonsCell?.rightButtonUseClearBackground()
        self.buttonsCell?.rightButton?.setImage(UIImage.init(named: "Delete"), for: .normal)
        self.buttonsCell?.rightButton?.tintColor = .systemRed
        self.buttonsCell?.dualButtonDelegate = self
        self.cellArray.append(self.buttonsCell!)
        
        self.tableView.reloadData()
    }
    
    
    override func closeDrawer() {
        self.drawerViewDelegate.popDrawer()
    }
    
    
    // MARK: UITableViewDataSource and UITableViewDelegate methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cellArray.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self.cellArray[indexPath.row]
    }
    

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }

    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (self.cellArray[indexPath.row]) is MCImageCell {
            return self.tableView.frame.width / (self.image?.getCropRatio())!
        }
        
        return UITableView.automaticDimension
    }
    
    
    // MARK: MCDualButtonCellDelegate
    func performDualButtonAction(_ action: String) {
        if (action == self.shareAction) {
            print(self.shareAction)
        } else if (action == self.deleteAction) {
            print(self.deleteAction)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.haveScrolled {
            self.rollUpPanGesture(scrollView.panGestureRecognizer, with: scrollView)
        }
    }
    
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.haveScrolled = true
        
        if (!self.isFullView) {
            scrollView.isScrollEnabled = false
            scrollView.isScrollEnabled = true
        } else {
            scrollView.isScrollEnabled = true
        }
    }
}


extension UIImage {
    func getCropRatio() -> CGFloat {
        let widthRatio = CGFloat(self.size.width / self.size.height)
        return widthRatio
    }
}
