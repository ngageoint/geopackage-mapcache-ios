//
//  UIImage+RotateImage.swift
//  mapcache-ios
//
//  Created by Tyler Burgett on 5/25/21.
//  Copyright © 2021 NGA. All rights reserved.
//

import Foundation

extension UIImage {
    func rotateImage()-> UIImage?  {
        if (self.imageOrientation == UIImage.Orientation.up ) {
            return self
        }
        UIGraphicsBeginImageContext(self.size)
        self.draw(in: CGRect(origin: CGPoint.zero, size: self.size))
       let copy = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return copy
    }
}
