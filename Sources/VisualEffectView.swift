//
//  VisualEffectView.swift
//  VisualEffectView
//
//  Created by Lasha Efremidze on 5/26/16.
//  Copyright © 2016 Lasha Efremidze. All rights reserved.
//

import UIKit

/// VisualEffectView is a dynamic background blur view.
open class VisualEffectView: UIVisualEffectView {
    
    /// Returns the instance of UIBlurEffect.
    private let blurEffect = (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init()
    
    /**
     Tint color.
     
     The default value is nil.
     */
    @IBInspectable
    open var colorTint: UIColor? {
        get {
            if #available(iOS 14, *) {
                return contentView.backgroundColor
            } else {
                return _value(forKey: "colorTint") as? UIColor
            }
        }
        set {
            if #available(iOS 14, *) {
                contentView.backgroundColor = newValue
            } else {
                _setValue(newValue, forKey: "colorTint")
            }
        }
    }
    
    /**
     Tint color alpha.
     
     The default value is 0.0.
     */
    @IBInspectable
    open var colorTintAlpha: CGFloat {
        get {
            if #available(iOS 14, *) {
                return contentView.alpha
            } else {
                return _value(forKey: "colorTintAlpha") as! CGFloat
            }
        }
        set {
            if #available(iOS 14, *) {
                contentView.alpha = newValue
            } else {
                _setValue(newValue, forKey: "colorTintAlpha")
            }
        }
    }
    
    /**
     Blur radius.
     
     The default value is 0.0.
     */
    @IBInspectable
    open var blurRadius: CGFloat {
        get {
            if #available(iOS 14, *) {
                return _blurRadius
            } else {
                return _value(forKey: "blurRadius") as! CGFloat
            }
        }
        set {
            if #available(iOS 14, *) {
                update(blurRadius: newValue)
            } else {
                _setValue(newValue, forKey: "blurRadius")
            }
        }
    }
    
    /**
     Scale factor.
     
     The scale factor determines how content in the view is mapped from the logical coordinate space (measured in points) to the device coordinate space (measured in pixels).
     
     The default value is 1.0.
     */
    @IBInspectable
    open var scale: CGFloat {
        get { return _value(forKey: "scale") as! CGFloat }
        set { _setValue(newValue, forKey: "scale") }
    }
    
    // MARK: - Initialization
    
    public override init(effect: UIVisualEffect?) {
        super.init(effect: effect)
        
        scale = 1
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        scale = 1
    }
    
    private var blurLayer: CALayer?
    private var _blurRadius: CGFloat = 0
    public override var bounds: CGRect {
        didSet {
            if #available(iOS 14.0, *) {
                update(blurRadius: _blurRadius)
                blurLayer?.frame = bounds
            }
        }
    }
}

// MARK: - Helpers

private extension VisualEffectView {
    
    /// Returns the value for the key on the blurEffect.
    func _value(forKey key: String) -> Any? {
        return blurEffect.value(forKeyPath: key)
    }
    
    /// Sets the value for the key on the blurEffect.
    func _setValue(_ value: Any?, forKey key: String) {
        blurEffect.setValue(value, forKeyPath: key)
        self.effect = blurEffect
    }
    
}

// ["grayscaleTintLevel", "grayscaleTintAlpha", "lightenGrayscaleWithSourceOver", "colorTint", "colorTintAlpha", "colorBurnTintLevel", "colorBurnTintAlpha", "darkeningTintAlpha", "darkeningTintHue", "darkeningTintSaturation", "darkenWithSourceOver", "blurRadius", "saturationDeltaFactor", "scale", "zoom"]

private extension VisualEffectView {
    @available(iOS 10.0, *)
    private func update(blurRadius: CGFloat) {
        _blurRadius = blurRadius

        if nil != effect {
            effect = nil
        }
        
        guard let window = window else { return }
        let rect = convert(frame, to: window)
        
        if nil == blurLayer {
            let blurLayer = CALayer()
            blurLayer.masksToBounds = true
            layer.addSublayer(blurLayer)
            self.blurLayer = blurLayer
        }

        blurLayer?.isHidden = true

        let image = window.snapshot(cropping: rect)
        let blurImage = image.blur(radius: blurRadius)
        blurLayer?.contents = blurImage.cgImage
        blurLayer?.isHidden = false
    }
}

extension UIView {
    @available(iOS 10.0, *)
    func snapshot(cropping: CGRect? = nil) -> UIImage {
        let rect = cropping ?? bounds
        let renderer = UIGraphicsImageRenderer(bounds: rect)
        return renderer.image { context in
            layer.render(in: context.cgContext)
        }
    }
}

extension UIImage {
    func blur(radius: CGFloat) -> UIImage {
        if let input = CIImage(image: self) {
            let output = input
                .applyingFilter("CIAffineClamp", parameters: [kCIInputTransformKey: CGAffineTransform.identity])
                .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: radius])
            if let cgImage = CIContext().createCGImage(output, from: input.extent) {
                return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
            }
        }
        return self
    }
}
