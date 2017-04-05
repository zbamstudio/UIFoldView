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
    let componentLayout: ComponentLayout
    let foldDirection: FoldDirection
    var imageComponents: [UIImage]
    
    var joints: [CATransformLayer]
    var shadows: [CALayer]
    var componentWidth: CGFloat
    var componentHeight: CGFloat
    var perspectiveLayer: CALayer!
    var animationKeyPath: (x: CGFloat, y: CGFloat, z: CGFloat)!
    
    let maxShadowDensity = 0.8
    
    var tempBounds: CGRect
    var angle: Double {
        
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
    
    
    var perspective: CGFloat {
        didSet {
            var transform = CATransform3DIdentity
            transform.m34 = -1.0 / perspective
            perspectiveLayer.sublayerTransform = transform;
        }
    }
    
    
    init(fromView view: UIView, jointCount: UInt8, componentLayout: ComponentLayout, foldDirection: FoldDirection, frame: CGRect) {
        
        self.foldJointCount = jointCount
        self.viewToFold = view
        self.componentLayout = componentLayout
        self.foldDirection = foldDirection
        self.componentWidth = 0.0
        self.componentHeight = 0.0
        self.imageComponents = [UIImage]()
        self.perspective = 700.0
        self.joints = [CATransformLayer]()
        self.shadows = [CALayer]()
        self.angle = 0.0
        tempBounds = frame
        
        super.init(frame: frame)
        
        if (self.foldDirection == .topToBottom || self.foldDirection == .bottomToTop) && componentLayout == .horizontal {
            NSException(name: NSExceptionName(rawValue: "Wrong type of fold direction"), reason: "TopToBottom and BottomToTop can't be used in Horizontal layout", userInfo: nil).raise()
            
            
        } else if (self.foldDirection == .leftToRight || self.foldDirection == .rightToLeft) && componentLayout == .vertical {
            NSException(name: NSExceptionName(rawValue: "Wrong type of fold direction"), reason: "LeftToRight and RightToLeft can't be used in Vertical layout", userInfo: nil).raise()
            
        }
        
        createImageComponents()
        createLayers()
        
        
        //        angleProperty = POPAnimatableProperty.property(withName:"foldView.angle") { (prop) in
        //
        //
        //            prop!.readBlock = {
        //                obj, values
        //                in
        //                values![0] = CGFloat((obj as! FoldView).angle)
        //            }
        //
        //            prop!.writeBlock = {
        //                obj, values
        //                in
        //                (obj as! FoldView).angle = Double(values![0])
        //            }
        //
        //
        //            } as! POPAnimatableProperty;
        
    }
    
    func openToDistance(_ distance: Double) {
        
        if componentLayout == ComponentLayout.horizontal {
            let angleDecreases = (Double(tempBounds.size.width) < distance)
            
            if angleDecreases {
                
                while (Double(tempBounds.size.width) < distance) {
                    self.angle -= 0.5
                }
                
            } else {
                
                while (Double(tempBounds.size.width) > distance) {
                    self.angle += 0.5
                }
            }
            
        } else {
            let angleDecreases = (Double(tempBounds.size.height) < distance)
            
            if angleDecreases {
                while (Double(tempBounds.size.height) < distance) {
                    self.angle -= 0.5
                }
                
            } else {
                while (Double(tempBounds.size.height) > distance) {
                    self.angle += 0.5
                }
            }
            
        }
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func createImageComponents() {
        let screenShot = imageFromView(viewToFold)
        
        // there should be jointCount + 1 components
        
        for i in 0 ... foldJointCount {
            
            let width = screenShot.size.width
            let height = screenShot.size.height
            
            if componentLayout == .horizontal {
                componentWidth = CGFloat(width) / (CGFloat(foldJointCount + 1))
                componentHeight = CGFloat(height)
                let componentImage = cropImageWithRect(screenShot, rect: CGRect(x: CGFloat(i) * componentWidth, y: 0, width: componentWidth, height: componentHeight));
                
                imageComponents.append(componentImage)
                
            } else {
                
                componentWidth = CGFloat(width)
                componentHeight = CGFloat(height) / (CGFloat(foldJointCount + 1))
                
                let componentImage = cropImageWithRect(screenShot, rect: CGRect(x: 0, y: CGFloat(i) * componentHeight, width: componentWidth, height: componentHeight));
                
                imageComponents.append(componentImage)
                
            }
            
        }
        
    }
    
    fileprivate func createLayers() {
        
        let disabledActions = ["sublayerTransform": NSNull(), "transform": NSNull(), "opacity": NSNull()]
        
        let imageCount = imageComponents.count;
        perspectiveLayer = CALayer()
        perspectiveLayer.frame = CGRect(x: 0,
                                        y: 0,
                                        width: componentLayout == .horizontal ? componentWidth * CGFloat(imageCount) : componentWidth,
                                        height: componentLayout == .horizontal ? componentHeight : CGFloat(imageCount) * componentHeight)
        
        var transform = CATransform3DIdentity
        transform.m34 = -1.0 / perspective
        perspectiveLayer.actions = disabledActions
        perspectiveLayer.sublayerTransform = transform;
        
        
        for i in 0 ..< imageCount {
            
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
                    jointLayer.position = CGPoint(x: (i == 0 ? componentWidth * CGFloat(imageCount) : 0), y: componentHeight / 2)
                    subLayer.contents = imageComponents[i].cgImage
                    
                    let targetImageIndex = imageCount - (i + 1)
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
                    jointLayer.position = CGPoint(x: componentWidth / 2, y: (i == 0 ? componentHeight * CGFloat(imageCount) : 0))
                    subLayer.contents = imageComponents[i].cgImage
                    
                    let targetImageIndex = imageCount - (i + 1)
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
    
    
    fileprivate func imageFromView(_ view: UIView) -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0.0);
        view.layer.render(in: UIGraphicsGetCurrentContext()!);
        
        let returnImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return returnImage!;
        
    }
    
    
    fileprivate func cropImageWithRect(_ image: UIImage, rect: CGRect) -> UIImage {
        
        let scale = image.scale
        let scaledRect = CGRect(x: rect.origin.x * scale, y: rect.origin.y * scale, width: rect.size.width * scale, height: rect.size.height * scale)
        let imageRef = (image.cgImage)?.cropping(to: scaledRect)
        let returnImage = UIImage(cgImage: imageRef!, scale: scale, orientation: image.imageOrientation)
        
        return returnImage;
        
    }
    
}
