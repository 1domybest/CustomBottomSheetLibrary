//
//  CustomPresentationController.swift
//  HypyG
//
//  Created by 온석태 on 9/9/24.
//

import Foundation
import UIKit

// Custom PresentationController 정의
class CustomModalPresentationController: UIPresentationController {
    
    // 추가적인 파라미터
    var bottomSheetModel: CustomUIKitBottomSheetOption?
    var keyboardHeight: CGFloat = .zero
    
    // 초기화 메서드
    init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?, bottomSheetModel: CustomUIKitBottomSheetOption?) {
        self.bottomSheetModel = bottomSheetModel
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }
    
    deinit {
        print("CustomModalPresentationController deinit")
    }
    
    func unreference () {
        self.bottomSheetModel = nil;
    }
    
    func setKeyboardHeight(keyboardHeight: CGFloat) {
        self.keyboardHeight = keyboardHeight
    }
    
    // 바텀 시트 스타일을 위한 높이 설정
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { return .zero }
        let height: CGFloat = self.bottomSheetModel?.sheetHeight ?? .zero
        return CGRect(
            x: 0,
            y: containerView.bounds.height - (height + keyboardHeight),
            width: containerView.bounds.width,
            height: height
        )
    }
    
    // 배경을 어둡게 만드는 처리
    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else { return }
        if self.bottomSheetModel?.backgroundColor == .clear { return }
        if self.bottomSheetModel?.sheetMode != .custom { return }
        
        let dimmingView = UIView(frame: containerView.bounds)
        dimmingView.backgroundColor = self.bottomSheetModel?.backgroundColor.getUIColor()
        dimmingView.alpha = 0 // 처음에는 투명하게 설정
        
        // 탭 제스처 인식기 추가
        if self.bottomSheetModel?.availableOutTouchClose ?? false {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dimmingViewTapped))
            dimmingView.addGestureRecognizer(tapGesture)
        }
        
        containerView.insertSubview(dimmingView, at: 0)
        
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            dimmingView.alpha = 1.0
        }, completion: nil)
    }

    @objc func dimmingViewTapped() {
        // 탭 이벤트가 발생했을 때 수행할 동작 (예: 바텀 시트 닫기)
        CustomBottomSheetSingleTone.shared.hide(pk: self.bottomSheetModel?.pk)
    }

    
    override func dismissalTransitionWillBegin() {
        guard let dimmingView = containerView?.subviews.first else { return }
        
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            dimmingView.alpha = 0.0
        }, completion: { _ in
            dimmingView.removeFromSuperview()
        })
    }
    
    
    func setSheetHeight(sheetHeight: CGFloat) {
         // Update the height in the model
        DispatchQueue.main.async {
            self.bottomSheetModel?.sheetHeight = sheetHeight
            
            // Notify that the layout should be updated
            if let containerView = self.containerView {
                UIView.animate(withDuration: 0.3) {
                    self.presentedView?.frame = self.frameOfPresentedViewInContainerView
                    containerView.setNeedsLayout()
                    containerView.layoutIfNeeded()
                    

                }
            }
        }
     }
}
