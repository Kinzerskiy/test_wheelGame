//
//  GameViewModel.swift
//  test_wheelGame
//
//  Created by Anton on 11.01.2024.
//

import UIKit
import AudioToolbox


class GameViewModel {
    
    // MARK: - Properties
    var wheelSize: CGFloat = 100
    var collisionCount: Int = 5
    var isGameOver: Bool = false
    var stripes: [UIView] = []
    var stripeYRange: ClosedRange<CGFloat> = 0...0
    let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    // Callbacks for UI updates
    var onWheelSizeChanged: ((CGFloat) -> Void)?
    var onGameOver: (() -> Void)?
    var onAddStripe: ((UIView) -> Void)?
    var onRemoveStripe: ((UIView) -> Void)?
    
    // Timers
    private var changeSizeTimer: Timer?
    private var stripeTimer: Timer?
    
    // MARK: - Game Control Methods
    func startGame() {
        setupTimers()
        resetGame()
    }
    
    func stopGame() {
        isGameOver = true
        invalidateTimers()
        triggerVibration()
        onGameOver?()
    }
    
    func resetGame() {
        isGameOver = false
        wheelSize = 100
        onWheelSizeChanged?(wheelSize)
        stripes.removeAll()
    }
    
    func changeWheelSize(isIncreasing: Bool) {
        let delta: CGFloat = isIncreasing ? 15 : -15
        let newWheelSize = max(10, wheelSize + delta)
        if newWheelSize != wheelSize {
            wheelSize = newWheelSize
            onWheelSizeChanged?(wheelSize)
        }
    }
    
    func startChangingWheelSize(isIncreasing: Bool) {
        changeSizeTimer?.invalidate()
        changeSizeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            self?.changeWheelSize(isIncreasing: isIncreasing)
        }
    }
    
    func stopChangingWheelSize() {
        changeSizeTimer?.invalidate()
        changeSizeTimer = nil
    }
    
    func addStripe(stripe: UIView) {
        stripes.append(stripe)
        onAddStripe?(stripe)
    }
    
    func removeStripe(stripe: UIView) {
        stripes.removeAll { $0 === stripe }
        onRemoveStripe?(stripe)
    }
    
    func setStripeYRange(top: CGFloat, bottom: CGFloat) {
        stripeYRange = top...bottom
    }
    
    func triggerVibration() {
        impactFeedbackGenerator.impactOccurred()
    }
    
    // MARK: - Private Methods
    private func setupTimers() {
        stripeTimer = Timer.scheduledTimer(timeInterval: 0.8, target: self, selector: #selector(addMovingStripe), userInfo: nil, repeats: true)
    }
    
    @objc private func addMovingStripe() {
        let stripeHeight: CGFloat = 7
        let stripeWidth: CGFloat = 50
        let yPosition = CGFloat.random(in: stripeYRange)
        
        let stripe = UIView()
        stripe.backgroundColor = .green
        stripe.frame = CGRect(x: UIScreen.main.bounds.width, y: yPosition, width: stripeWidth, height: stripeHeight)
        addStripe(stripe: stripe)
    }
    
    private func updateWheelSize() {
        guard !isGameOver else { return }
        onWheelSizeChanged?(wheelSize)
    }
    
    private func invalidateTimers() {
        changeSizeTimer?.invalidate()
        changeSizeTimer = nil
        stripeTimer?.invalidate()
        stripeTimer = nil
    }
}

