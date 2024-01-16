//
//  WheelView.swift
//  test_wheelGame
//
//  Created by Anton on 11.01.2024.
//

import UIKit


class WheelView: UIView {
    // MARK: - Properties
    
    var wheelSize: CGFloat = 100 {
        didSet {
            updateSize()
        }
    }
    
    private let indicatorDot = UIView()
    private var rotationAnimation: CABasicAnimation?
    
    init() {
        super.init(frame: .zero)
        setupWheel()
        addIndicatorDot()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // MARK: - Wheel Methods
    
    func startRotating() {
        rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation?.fromValue = 0
        rotationAnimation?.toValue = 2 * Double.pi
        rotationAnimation?.duration = 0.5
        rotationAnimation?.repeatCount = Float.infinity
        self.layer.add(rotationAnimation!, forKey: "rotation")
    }
    
    func changeSize(by delta: CGFloat) {
        wheelSize += delta
        wheelSize = max(10, wheelSize)
        
        UIView.animate(withDuration: 0.1,
                       delay: 0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.9,
                       options: [.curveEaseInOut, .allowUserInteraction],
                       animations: {
            self.updateSize()
            self.layoutIfNeeded()
        }, completion: nil)
    }
    
    // MARK: - Private Methods

    private func setupWheel() {
        self.backgroundColor = .red
        self.layer.cornerRadius = wheelSize / 2
        updateSize()
    }
    
    
    private func updateSize() {
        let currentCenter = self.center
        self.frame = CGRect(x: 0, y: 0, width: wheelSize, height: wheelSize)
        self.layer.cornerRadius = wheelSize / 2
        self.center = currentCenter
        updateIndicatorDot()
    }
    
    
    private func addIndicatorDot() {
        indicatorDot.backgroundColor = .white
        indicatorDot.layer.opacity = 0.3
        indicatorDot.layer.shadowColor = UIColor.white.cgColor
        indicatorDot.layer.shadowOffset = CGSize.zero
        indicatorDot.layer.shadowRadius = 7
        indicatorDot.layer.shadowOpacity = 0.8
        self.addSubview(indicatorDot)
        updateIndicatorDot()
    }
    
    private func updateIndicatorDot() {
        let dotSize: CGFloat = wheelSize * 0.25
        let dotPosition = CGPoint(x: wheelSize / 2 - dotSize / 2, y: 5)
        indicatorDot.frame = CGRect(x: dotPosition.x, y: dotPosition.y, width: dotSize, height: dotSize)
        indicatorDot.layer.cornerRadius = dotSize / 2
    }
}

