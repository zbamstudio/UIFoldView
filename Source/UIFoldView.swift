//
//  UIFoldView.swift
//  UIFoldViewExample
//
//  Created by Emrah Ozer on 05/04/2017.
//  Copyright © 2017 Emrah Ozer. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

enum ComponentLayout {
    case horizontal
    case vertical
}

enum FoldDirection {
    case leftToRight
    case rightToLeft
    case topToBottom
    case bottomToTop
}

class FoldView: UIView {
    
    let foldJointCount: UInt8
    let viewToFold: UIView
    let foldDirection: FoldDirection




    var imageComponents: [UIImage] = []
    var joints: [CATransformLayer]  = []
    var shadows: [CALayer] = []

    var componentWidth: CGFloat = 0.0
    var componentHeight: CGFloat = 0.0
    var perspectiveLayer: CALayer!
    var animationKeyPath: (x: CGFloat, y: CGFloat, z: CGFloat)!
    
    let maxShadowDensity = 0.8
    var tempBounds: CGRect

    var componentLayout: ComponentLayout
    {
        get
        {
            if (self.foldDirection == .topToBottom || self.foldDirection == .bottomToTop)
            {
                return .vertical

            } else if (self.foldDirection == .leftToRight || self.foldDirection == .rightToLeft){
                return .horizontal
            }else{
                return .horizontal
            }
        }
    }


    var angle: Double = 0 {
        
        didSet {
            var index = 0
            
            for joint in joints {
                let angleValue = (index == 0 ? -angle : ((index % 2 == 1) ? (2 * angle) : (-2 * angle))) * (Double.pi / 180)
                joint.transform = CATransform3DMakeRotation(CGFloat(angleValue), animationKeyPath.x, animationKeyPath.y, animationKeyPath.z)
                index += 1
            }
            
            for shadowLayer in shadows {
                shadowLayer.opacity = Float(abs(maxShadowDensity * (abs(angle) / 90)))
            }
            
            let fullTransform: CATransform3D = joints[0].transform
            let affine: CGAffineTransform = CGAffineTransform(a: fullTransform.m11, b: fullTransform.m12, c: fullTransform.m21, d: fullTransform.m22, tx: fullTransform.m41, ty: fullTransform.m42);
            let bounds = self.bounds
            let width = bounds.width * affine.a
            let height = bounds.height * affine.d
            tempBounds = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: width, height: height)
            
        }
    }

    var perspective: CGFloat = 700 {
        didSet {
            var transform = CATransform3DIdentity
            transform.m34 = -1.0 / perspective
            perspectiveLayer.sublayerTransform = transform;
        }
    }

    var unfoldLength:Double = 0{
        didSet {
            if componentLayout == ComponentLayout.horizontal {
                let angleDecreases = (Double(tempBounds.size.width) < unfoldLength)

                if angleDecreases {

                    while (Double(tempBounds.size.width) < unfoldLength) {
                        self.angle -= 0.5
                    }

                } else {

                    while (Double(tempBounds.size.width) > unfoldLength) {
                        self.angle += 0.5
                    }
                }

            } else {
                let angleDecreases = (Double(tempBounds.size.height) < unfoldLength)

                if angleDecreases {
                    while (Double(tempBounds.size.height) < unfoldLength) {
                        self.angle -= 0.5
                    }

                } else {
                    while (Double(tempBounds.size.height) > unfoldLength) {
                        self.angle += 0.5
                    }
                }
            }
        }
    }
    
    init(fromView view: UIView, jointCount: UInt8, foldDirection: FoldDirection) {
        
        self.foldJointCount = jointCount
        self.viewToFold = view
        self.foldDirection = foldDirection

        tempBounds = view.frame
        
        super.init(frame: view.frame)
        
        createImageComponents()
        createLayers()
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func createImageComponents() {
        let screenShot = renderImage(fromView: viewToFold)
        
        // there should be jointCount + 1 components
        
        for i in 0 ... foldJointCount {
            
            let width = screenShot.size.width
            let height = screenShot.size.height
            
            if componentLayout == .horizontal {
                componentWidth = CGFloat(width) / (CGFloat(foldJointCount + 1))
                componentHeight = CGFloat(height)
                let componentImage = crop(image:screenShot, withRect: CGRect(x: CGFloat(i) * componentWidth, y: 0, width: componentWidth, height: componentHeight));
                
                imageComponents.append(componentImage)
                
            } else {
                
                componentWidth = CGFloat(width)
                componentHeight = CGFloat(height) / (CGFloat(foldJointCount + 1))
                
                let componentImage = crop(image:screenShot, withRect: CGRect(x: 0, y: CGFloat(i) * componentHeight, width: componentWidth, height: componentHeight));
                
                imageComponents.append(componentImage)
                
            }
            
        }
        
    }
    
    fileprivate func createLayers() {

        let disabledActions = ["sublayerTransform": NSNull(), "transform": NSNull(), "opacity": NSNull()]

        createPerspectiveLayer(withDisabledActions: disabledActions)

        for i in 0 ..< imageComponents.count {
            
            let jointLayer = CATransformLayer()
            jointLayer.actions = disabledActions
            let subLayer = CALayer()
            subLayer.actions = disabledActions
            
            (joints.count == 0 ? perspectiveLayer : joints.last)?.addSublayer(jointLayer)
            
            subLayer.frame = CGRect(x: 0, y: 0, width: componentWidth, height: componentHeight)
            jointLayer.frame = CGRect(x: 0, y: 0, width: componentWidth, height: componentHeight)
            
            if componentLayout == .horizontal {
                animationKeyPath = (0, 1, 0);
                
                if foldDirection == .leftToRight {
                    jointLayer.anchorPoint = CGPoint(x: 0, y: 0.5)
                    jointLayer.position = CGPoint(x: (i == 0 ? 0 : componentWidth), y: componentHeight / 2)
                    subLayer.contents = imageComponents[i].cgImage
                    
                    
                } else if foldDirection == .rightToLeft {
                    
                    jointLayer.anchorPoint = CGPoint(x: 1, y: 0.5)
                    jointLayer.position = CGPoint(x: (i == 0 ? componentWidth * CGFloat(imageComponents.count) : 0), y: componentHeight / 2)
                    subLayer.contents = imageComponents[i].cgImage
                    
                    let targetImageIndex = imageComponents.count - (i + 1)
                    subLayer.contents = imageComponents[targetImageIndex].cgImage
                }
                
                
            } else if componentLayout == .vertical {
                animationKeyPath = (1, 0, 0);
                
                if foldDirection == .topToBottom {
                    jointLayer.anchorPoint = CGPoint(x: 0.5, y: 0)
                    jointLayer.position = CGPoint(x: componentWidth / 2, y: (i == 0 ? 0 : componentHeight))
                    subLayer.contents = imageComponents[i].cgImage
                    
                } else if foldDirection == .bottomToTop {
                    
                    jointLayer.anchorPoint = CGPoint(x: 0.5, y: 1)
                    jointLayer.position = CGPoint(x: componentWidth / 2, y: (i == 0 ? componentHeight * CGFloat(imageComponents.count) : 0))
                    subLayer.contents = imageComponents[i].cgImage
                    
                    let targetImageIndex = imageComponents.count - (i + 1)
                    subLayer.contents = imageComponents[targetImageIndex].cgImage
                    
                }
                
            }
            
            jointLayer.addSublayer(subLayer)
            
            
            // create shadow
            
            if (i % 2 == 1) {
                let shadowLayer = CALayer()
                shadowLayer.actions = ["opacity": NSNull(), "transform": NSNull()]
                shadowLayer.frame = CGRect(x: 0, y: 0, width: componentWidth, height: componentHeight)
                shadowLayer.backgroundColor = UIColor.black.cgColor
                shadowLayer.opacity = 0.0
                shadows.append(shadowLayer)
                
                subLayer.addSublayer(shadowLayer)
                
            }
            
            joints.append(jointLayer)
            
            
        }
        
        self.layer.addSublayer(perspectiveLayer)
        
    }
    
    
    fileprivate func renderImage(fromView view: UIView) -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0.0);
        view.layer.render(in: UIGraphicsGetCurrentContext()!);
        
        let returnImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return returnImage!;
        
    }

    private func createPerspectiveLayer(withDisabledActions actions:[String : CAAction]?) {

        perspectiveLayer = CALayer()
        perspectiveLayer.frame = CGRect(x: 0,
                y: 0,
                width: componentLayout == .horizontal ? componentWidth * CGFloat(imageComponents.count) : componentWidth,
                height: componentLayout == .horizontal ? componentHeight : CGFloat(imageComponents.count) * componentHeight)

        var transform = CATransform3DIdentity
        transform.m34 = -1.0 / perspective
        perspectiveLayer.actions = actions
        perspectiveLayer.sublayerTransform = transform;
    }

    fileprivate func crop(image: UIImage,withRect rect: CGRect) -> UIImage {
        
        let scale = image.scale
        let scaledRect = CGRect(x: rect.origin.x * scale, y: rect.origin.y * scale, width: rect.size.width * scale, height: rect.size.height * scale)
        let imageRef = (image.cgImage)?.cropping(to: scaledRect)
        let returnImage = UIImage(cgImage: imageRef!, scale: scale, orientation: image.imageOrientation)
        
        return returnImage;
        
    }
    
}
