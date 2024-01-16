//
//  GameViewController.swift
//  test_wheelGame
//
//  Created by Anton on 11.01.2024.
//

import UIKit
import AVFoundation

class GameViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet weak var attemptsLabel: UILabel!
    
    // MARK: - Properties
    
    let viewModel = GameViewModel()
    let wheelView = WheelView()
    var displayLink: CADisplayLink?
    var audioPlayer: AVAudioPlayer?
    
    var isLongPressActive: Bool = false
    var isVibrationInProgress = false
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated:true)
        
        setupWheel()
        setupViewModelBindings()
        setupDisplayLink()
        viewModel.startGame()
        updateAttemptsLabel()
        setupAudioPlayer()
        
        addLongPressGestureToButton(plusButton, action: #selector(handleLongPressPlus))
        addLongPressGestureToButton(minusButton, action: #selector(handleLongPressMinus))
        
        DispatchQueue.main.async {
            self.setStripeYRange()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        audioPlayer?.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        displayLink?.invalidate()
    }
    
    // MARK: - Setup Methods
    
    func setupWheel() {
        wheelView.center = view.center
        view.addSubview(wheelView)
        wheelView.startRotating()
    }
    
    func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink))
        displayLink?.add(to: .current, forMode: .common)
        displayLink?.preferredFramesPerSecond = 60
    }
    
    func setupViewModelBindings() {
        viewModel.onWheelSizeChanged = { [weak self] newSize in
            if let strongSelf = self {
                let change = newSize - strongSelf.wheelView.wheelSize
                strongSelf.wheelView.changeSize(by: change)
            }
        }
        
        viewModel.onGameOver = { [weak self] in
            self?.showGameOverAlert()
        }
        
        viewModel.onAddStripe = { [weak self] stripe in
            self?.view.addSubview(stripe)
            self?.animateStripe(stripe)
        }
        
        viewModel.onRemoveStripe = { stripe in
            stripe.removeFromSuperview()
        }
    }
    
    func setupAudioPlayer() {
        audioPlayer?.delegate = self
        
        if let path = Bundle.main.path(forResource: "game_start", ofType: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                audioPlayer?.prepareToPlay()
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    
    // MARK: - Gesture Methods
    
    func addLongPressGestureToButton(_ button: UIButton, action: Selector) {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: action)
        longPressGesture.minimumPressDuration = 0.1
        button.addGestureRecognizer(longPressGesture)
    }
    
    @objc func handleLongPressPlus(gesture: UILongPressGestureRecognizer) {
        handleLongPress(gesture: gesture, isIncreasing: true)
    }
    
    @objc func handleLongPressMinus(gesture: UILongPressGestureRecognizer) {
        handleLongPress(gesture: gesture, isIncreasing: false)
    }
    
    func handleLongPress(gesture: UILongPressGestureRecognizer, isIncreasing: Bool) {
        if gesture.state == .began {
            isLongPressActive = true
            viewModel.startChangingWheelSize(isIncreasing: isIncreasing)
        } else if gesture.state == .ended || gesture.state == .cancelled {
            isLongPressActive = false
            viewModel.stopChangingWheelSize()
        }
    }
    
    // MARK: - Game Methods
    
    @objc func handleDisplayLink() {
        guard let wheelFrameInView = wheelView.superview?.convert(wheelView.frame, to: view) else { return }
        
        for stripe in viewModel.stripes {
            guard let stripePresentationFrame = stripe.layer.presentation()?.frame else { continue }
            let convertedStripeFrame = view.convert(stripePresentationFrame, from: stripe.superview)
            
            if convertedStripeFrame.intersects(wheelFrameInView) {
                viewModel.triggerVibration()
                viewModel.collisionCount -= 1
                viewModel.removeStripe(stripe: stripe)
                updateAttemptsLabel()
                
                if viewModel.collisionCount <= 0 {
                    gameOver()
                    break
                }
            }
        }
    }
    
    
    func updateAttemptsLabel() {
        attemptsLabel.text = "Attempts: \(viewModel.collisionCount)"
    }
    
    func animateStripe(_ stripe: UIView) {
        let stripeWidth: CGFloat = 100
        UIView.animate(withDuration: 1.0, delay: 0, options: .curveLinear, animations: {
            stripe.frame = stripe.frame.offsetBy(dx: -self.view.bounds.width - stripeWidth, dy: 0)
        }, completion: { [weak self] _ in
            self?.viewModel.removeStripe(stripe: stripe)
        })
    }
    
    func gameOver() {
        viewModel.stopGame()
        showGameOverAlert()
    }
    
    func showGameOverAlert() {
        let alert = UIAlertController(title: "Game Over", message: "Try again!", preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.viewModel.startGame()
            self?.viewModel.collisionCount = 5
            self?.updateAttemptsLabel()
        }
        alert.addAction(restartAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func setStripeYRange() {
        let superViewHeight = view.bounds.height
        let topLimitPercentage: CGFloat = 0.2
        let bottomLimitPercentage: CGFloat = 0.2
        
        let topLimit = superViewHeight * topLimitPercentage
        let bottomLimit = superViewHeight * (1 - bottomLimitPercentage)
        
        if topLimit < bottomLimit {
            viewModel.setStripeYRange(top: topLimit, bottom: bottomLimit)
        } else {
            print("Invalid stripe range: topLimit \(topLimit), bottomLimit \(bottomLimit)")
        }
    }
}


extension GameViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            audioPlayer?.currentTime = 0
            audioPlayer?.play()
        }
    }
}
