//
//  CustomPresentationController.swift
//  HypyG
//
//  Created by 온석태 on 9/9/24.
//

import Foundation
import UIKit
import KeyboardManager

/**
    ``UIPresentationController``
 
    UIKit 의 기본 [`UIPresentationController`](https://developer.apple.com/documentation/uikit/uipresentationcontroller) 를 사용하여
    뒷배경 터치와 바텀시트가 present 되었을때 이벤트를 호출받아 공유
 */
class CustomModalPresentationController: UIPresentationController {
    
    /**
     바텀시트의 옵션을 담은 객체 ``CustomUIKitBottomSheetOption``
     */
    var bottomSheetModel: CustomUIKitBottomSheetOption?
    
    /**
     키보드의 높이
     */
    var keyboardHeight: CGFloat = .zero

    /**
     초기화 메서드
     */
    init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?, bottomSheetModel: CustomUIKitBottomSheetOption?) {
        self.bottomSheetModel = bottomSheetModel
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }
    
    deinit {
        print("CustomModalPresentationController deinit")
    }
    
    /**
     참조 해제해주는 함수 [메모리 관리]
     */
    func unreference () {
        self.bottomSheetModel = nil;
    }
    
    /**
     키보드 높이 업데이트 해주는 함수
     
     단 ``CustomUIKitBottomSheetOption/hasKeyboard`` 가 ``True`` 일시에 적용된다.
     */
    func setKeyboardHeight(keyboardHeight: CGFloat) {
        self.keyboardHeight = keyboardHeight
    }
    
    /**
     sheet의 애니메이션이 종료되는 시점에 호출되는 변수
     
     이때 최종높이를 계산해서 업데이트 해준다.
     */
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
    
    /**
     sheet가 present 될때 받는 이벤트
     
     이때 뒷배경 색이 ``CustomUIKitBottomSheetOption/backgroundColor`` 에 포함되어있다면
     뒷배경색 추가
     */
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

    /// 시트 뒷배경 터치시  -> 싱글톤에 서 hide호출하여 현재 시트 닫기 실행
    @objc func dimmingViewTapped() {
        CustomBottomSheetSingleTone.shared.hide(pk: self.bottomSheetModel?.pk)
    }

    /**
     sheet가 dissmiss가 시작될때 이벤트를 호출받음
        
     dissmiss가 될때 뒷배경의 알파를 0으로 만들어 사라지게해주고 애니메이션을 추가해줌
     */
    override func dismissalTransitionWillBegin() {
        guard let dimmingView = containerView?.subviews.first else { return }
        
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            dimmingView.alpha = 0.0
        }, completion: { _ in
            dimmingView.removeFromSuperview()
        })
    }
    
    /**
     현재 sheet 높이를 update해주는 함수
     
     - Parameters:
       - sheetHeight: CGFloat
     */
    func setSheetHeight(sheetHeight: CGFloat) {
        DispatchQueue.main.async {
            self.bottomSheetModel?.sheetHeight = sheetHeight
            
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
