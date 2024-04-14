//
//  GameButton.swift
//  HelloAR
//
//  Created by paku on 2024/04/14.
//

import UIKit

class GameButton: UIButton {
    
    private var completion: () -> Void
    private var timer: Timer!
    
    init(frame: CGRect, completion: @escaping () -> Void) {
        self.completion = completion
        super.init(frame: frame)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { [weak self] timer in
            self?.completion()
        })
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.timer.invalidate()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
