//
//  MyViewController.swift
//  HypyG
//
//  Created by 온석태 on 9/9/24.
//

import UIKit
import SwiftUI
import KeyboardManager

/**
  실제 바텀시트의 UI를 담당하는 ``CustomUIKitBottomSheet``
 */
public class CustomUIKitBottomSheet: UIViewController {
    /**
     사용될 바텀시트 옵션
     
     ``CustomUIKitBottomSheetOption``
     */
    public var customUIKitBottomSheetOption: CustomUIKitBottomSheetOption?
    
    /**
     시트 딜리게이트
     
     UIKit 의 기본 [`UIPresentationController`](https://developer.apple.com/documentation/uikit/uipresentationcontroller)
     를 참조하여 만든 객체
     */
    var customModalPresentationController: CustomModalPresentationController?
    
    /** 터치되는 Point 초기화시 사용  */
    private var initialTouchPoint: CGPoint?
    
    /** 손잡이 View  */
    var handlerView: UIView?
    
    /** safeArea top padding 사이즈  */
    var topSafeAreaSize: CGFloat = .zero
    
    /** 스크롤뷰 [시트가 화면을 넘어갔을때 주로 사용]  */
    var scrollView: UIScrollView?
    
    /** SwiftUI View -> UiKit에서 사용할수있도록 호스팅뷰를 사용 */
    var hostingController: UIHostingController<AnyView>?
    
    /** SwiftUI에서 받아온 AnyView(View()) 에 키보드가 존재할시 사용하는 키보드 매니저 */
    var keyboardManager: KeyboardManager?
    
    /** 키보드 높이 저장 변수 */
    var keyboardHeight: CGFloat = .zero
    
    /** 키보드 노출 유무 */
    var isKeyboardOpen: Bool = false
    
    /** 마지막 ScrollView 내부 콘텐트 높이 사이즈 */
    var lastSizeOfScrollViewContentHeight: CGFloat = .zero
    
    /** 현재 ScrollView 내부 콘텐트 높이 사이즈 */
    var currentSizeOfScrollViewContentHeight: CGFloat = .zero
    
    /** 드레그 제스처 */
    var dragGesture: UIPanGestureRecognizer?
    
    /** 스크롤링중인지 여부 */
    var isScrolling: Bool = false
    
    /** 스크롤 위치 변수 [현재 가장 최상단 인지] */
    var isTop: Bool = true
    
    /** 스크롤 위치 변수 [현재 가장 최하단 인지] */
    var isBottom: Bool = false
    
    /** 드레깅 종료상태 변수 */
    var isFinishedDragging: Bool = false
    
    /** 내부 시트가 화면을 넘었는지에대한 상태 변수 */
    var isOverScreen: Bool = false
    
    public init(bottomSheetModel: CustomUIKitBottomSheetOption) {
        self.customUIKitBottomSheetOption = bottomSheetModel
        // 핸들 가능 모드 custom, automatic , popover, pageSheet, formSheet
        // 핸들 불가능 모드 currentContext, fullScreen, overCurrentContext, overFullScreen,
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = self.customUIKitBottomSheetOption?.sheetMode ?? .custom
        
        if self.customUIKitBottomSheetOption?.sheetMode == .custom {
            self.transitioningDelegate = self
        }
        
        if self.customUIKitBottomSheetOption?.hasKeyboard ?? false {
            self.keyboardManager = KeyboardManager()
            self.keyboardManager?.setCallback(callback: self)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("CustomUIKitBottomSheet deinit")
    }
    
    /** 참조 해제 변수 */
    func unreference () {
        self.customUIKitBottomSheetOption = nil
        self.customModalPresentationController = nil
        
        if dragGesture != nil {
            view.removeGestureRecognizer(dragGesture!)
            dragGesture = nil
        }
        
        self.scrollView = nil
        self.hostingController = nil
        self.handlerView = nil
        
        if self.keyboardManager != nil {
            self.keyboardManager?.removeCallback()
            self.keyboardManager = nil
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setView()
        
        if self.customUIKitBottomSheetOption?.dragAvailable ?? false && self.customUIKitBottomSheetOption?.sheetMode == .custom {
            addGestureRecognizers()
        }
        
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            let safeAreaInsets = rootViewController.view.safeAreaInsets
            topSafeAreaSize = safeAreaInsets.top
         }
    }
    
    /** View 초기화 함수 */
    func setView () {
        if self.customUIKitBottomSheetOption?.sheetMode == .custom {
            setSheetView()
            setupScrollView()
        } else {
            setHostingView()
        }
        
        if self.customUIKitBottomSheetOption?.showHandler ?? false || self.customUIKitBottomSheetOption?.availableHasHandle ?? false {
            setHandlerView()
        }
    }
    
    /** 제스처 등록 함수 */
    func addGestureRecognizers() {
         let dragGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
         view.addGestureRecognizer(dragGesture)
        self.dragGesture = dragGesture
     }
    
    /** 스크롤뷰 등록 함수 */
    func setupScrollView() {
        let scrollView = CustomScrollView()
        scrollView.backgroundColor = self.customUIKitBottomSheetOption?.sheetColor.getUIColor()
        scrollView.isScrollEnabled = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.delegate = self
        view.addSubview(scrollView)
        
        var topPadding = self.customUIKitBottomSheetOption?.showHandler ?? false ? 40.0 : 28.0
        
        if self.customUIKitBottomSheetOption?.sheetMode != .custom {
            topPadding = 0
        }
        
        // 오토레이아웃 설정
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: topPadding),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.widthAnchor.constraint(equalTo: view.widthAnchor)  // 가로 스크롤 방지
        ])
        
        // SwiftUI View를 AnyView로 감싸서 사용
        let swiftUIView = self.customUIKitBottomSheetOption?.someView
        
        let hostingController = UIHostingController(rootView: AnyView(swiftUIView))
        hostingController.view.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: self.customUIKitBottomSheetOption?.sheetHeight ?? .zero)
        
        scrollView.addSubview(hostingController.view)
    
        addChild(hostingController)
        hostingController.didMove(toParent: self)
        hostingController.view.backgroundColor = self.customUIKitBottomSheetOption?.sheetColor.getUIColor()
        self.hostingController = hostingController
        
        self.scrollView = scrollView
    }
    
    /** SwifrtUI View 등록함수 */
    func setHostingView () {
        // SwiftUI View를 AnyView로 감싸서 사용
        let swiftUIView = self.customUIKitBottomSheetOption?.someView
        
        let hostingController = UIHostingController(rootView: AnyView(swiftUIView))
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(hostingController.view)
        
        var topPadding = self.customUIKitBottomSheetOption?.showHandler ?? false ? 40.0 : 28.0
        
        if self.customUIKitBottomSheetOption?.sheetMode != .custom {
            topPadding = 0
        }
        
        // 오토레이아웃 설정
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor, constant: topPadding),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.widthAnchor.constraint(equalTo: view.widthAnchor)  // 가로 스크롤 방지
        ])
        

        addChild(hostingController)
        hostingController.didMove(toParent: self)
        self.hostingController = hostingController

    }
    
    /** 시트 View 등록함수 */
    func setSheetView () {
        if self.customUIKitBottomSheetOption?.sheetHeight == UIScreen.main.bounds.height { return }
        view.backgroundColor = self.customUIKitBottomSheetOption?.sheetColor.getUIColor()
        
        let radius: CGFloat = 20.0 // 원하는 radius 값으로 변경
        let corners: UIRectCorner = [.topLeft, .topRight]
        let path = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        
        self.view.layer.mask = maskLayer
    }
    
    /** 시트 손잡이 View 등록 함수 */
    func setHandlerView() {
        let handlerView = UIView()
        handlerView.backgroundColor = self.customUIKitBottomSheetOption?.handlerColor.getUIColor()
        handlerView.layer.cornerRadius = 2

        view.addSubview(handlerView)
        handlerView.translatesAutoresizingMaskIntoConstraints = false
        
        var topPadding = 8.0
        if self.customUIKitBottomSheetOption?.sheetMode != .custom ?? .custom {
            topPadding = 12.0
        }
        
        NSLayoutConstraint.activate([
            handlerView.widthAnchor.constraint(equalToConstant: 36),
            handlerView.heightAnchor.constraint(equalToConstant: 4),
            handlerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            handlerView.topAnchor.constraint(equalTo: view.topAnchor, constant: topPadding)
        ])
        
        self.handlerView = handlerView
    }
    
    /** 시트 내리기 함수 */
    func dismissPresent () {
        self.dismiss(animated: true, completion: {
            self.customUIKitBottomSheetOption?.onDismiss?()
            self.unreference()
        })
    }
    
    /** 시트 내리기 함수 [콜백 포함] */
    func dismissPresent (animated: Bool = true, completion: @escaping () -> Void) {
        self.dismiss(animated: animated, completion: {
            self.customUIKitBottomSheetOption?.onDismiss?()
            self.unreference()
            completion()
        })
    }

    /** 시트 높이 업데이트 함수 */
    func updateSheetHeight(newHeight: CGFloat) {
        self.currentSizeOfScrollViewContentHeight = newHeight
        var newHeight = newHeight
        
        // 이곳에서 max확인해야함
        let topPadding = self.customUIKitBottomSheetOption?.showHandler ?? false ? 40.0 : 28.0
        newHeight += topPadding
        
        var adjustedLength = min(max(newHeight, self.customUIKitBottomSheetOption?.minimumHeight ?? .zero), self.customUIKitBottomSheetOption?.maximumHeight ?? .zero)
        
        var contentSize:CGFloat = adjustedLength
        
        if newHeight > UIScreen.main.bounds.height - (keyboardHeight) {
            // 넘어섰을때
            adjustedLength = UIScreen.main.bounds.height
            if keyboardHeight > 0 {
                adjustedLength = UIScreen.main.bounds.height - (keyboardHeight)
            }
            
            contentSize = newHeight
            self.isOverScreen = true
            self.scrollView?.isScrollEnabled = true
        } else {
            self.isOverScreen = false
            self.scrollView?.isScrollEnabled = false
        }

        DispatchQueue.main.async {
            self.customModalPresentationController?.setSheetHeight(sheetHeight: adjustedLength)
            self.scrollView?.contentSize = CGSize(width: self.view.frame.width, height: contentSize) // 테스트를 위한 고정된 크기
            self.hostingController?.view.frame.size = CGSize(width: self.view.frame.width, height: contentSize)
        }
    }
}

extension CustomUIKitBottomSheet:UIViewControllerTransitioningDelegate {
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        self.customModalPresentationController = CustomModalPresentationController(presentedViewController: presented, presenting: presenting, bottomSheetModel: self.customUIKitBottomSheetOption)
        return self.customModalPresentationController
    }
}

/** 키보드 매니저 딜리게이트 */
extension CustomUIKitBottomSheet:@preconcurrency KeyboardManangerProtocol {
    public func keyBoardWillShow(notification: NSNotification, keyboardHeight: CGFloat) {
        DispatchQueue.main.async {
            self.isKeyboardOpen = true
            self.lastSizeOfScrollViewContentHeight = self.currentSizeOfScrollViewContentHeight
            self.initialTouchPoint = self.view.frame.origin
            self.keyboardHeight = keyboardHeight
            self.customModalPresentationController?.setKeyboardHeight(keyboardHeight: keyboardHeight)
            self.updateSheetHeight(newHeight: self.lastSizeOfScrollViewContentHeight)
        }
        
    }
    
    public func keyBoardWillHide(notification: NSNotification) {
        DispatchQueue.main.async {
            self.keyboardHeight = 0
            self.customModalPresentationController?.setKeyboardHeight(keyboardHeight: self.keyboardHeight)
            self.updateSheetHeight(newHeight: self.lastSizeOfScrollViewContentHeight)
            self.isKeyboardOpen = false
            self.scrollToTop()
            self.dragGesture?.isEnabled = true
        }
        
    }
}

/** UIScrollView */
class CustomScrollView: UIScrollView {
    // 스크롤뷰가 스크롤이 비활성화된 상태에서 터치 이벤트를 하위 뷰로 전달하도록 설정
    override  func touchesShouldCancel(in view: UIView) -> Bool {
        return true
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 스크롤이 비활성화된 상태에서는 스크롤뷰 자체가 아닌 내부의 뷰가 이벤트를 받을 수 있도록 처리
        if !self.isScrollEnabled {
            return self.subviews.first?.hitTest(point, with: event)
        }
        return super.hitTest(point, with: event)
    }
}


/** 스크롤뷰 딜리게이트 */
extension CustomUIKitBottomSheet: UIScrollViewDelegate {
    /** 핸들 제스처 콜백함수 */
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let containerView = self.view else { return }

      
        let translation = gesture.translation(in: containerView)
        let velocity = gesture.velocity(in: containerView)
        
        if self.isKeyboardOpen {
            self.dragGesture?.isEnabled = false
            self.keyboardManager?.hideKeyboard()
            return
        }
        
        switch gesture.state {
        case .began:
            // 초기 터치 포인트와 시작 위치 저장
            DispatchQueue.main.async {
                self.initialTouchPoint = containerView.frame.origin
            }
            isFinishedDragging = false
            
        case .changed:
            DispatchQueue.main.async {
                if self.isKeyboardOpen { return }
                // 바텀 시트의 새로운 y 위치를 계산
                if self.isFinishedDragging && self.isOverScreen {
                    self.scrollView?.isScrollEnabled = true
                    self.dragGesture?.isEnabled = false
                } else {
                    self.scrollView?.isScrollEnabled = false
                    if let initialTouchPoint = self.initialTouchPoint, translation.y > 0 {
                        // 드래그에 따라 y 위치를 업데이트 (최초 위치 + 드래그 이동 거리)
                        containerView.frame.origin.y = initialTouchPoint.y + translation.y
                    }
                }
                
            }
           

        case .ended, .cancelled:
            DispatchQueue.main.async {
                if self.isKeyboardOpen { return }
                let velocityThreshold: CGFloat = 1000 // 속도 기준 값 설정 (점프 스냅에 사용)
                let dismissThreshold: CGFloat = containerView.frame.height / 2 // 화면 하단으로 내려갈 기준 높이
                // 빠르게 드래그하면 바텀 시트를 아래로 dismiss
                if velocity.y > velocityThreshold {
                    CustomBottomSheetSingleTone.shared.hide(pk: self.customUIKitBottomSheetOption?.pk)
                }
                // 느리게 드래그했을 때는 특정 위치(1/3 지점)를 넘으면 dismiss
                else if translation.y > dismissThreshold {
                    CustomBottomSheetSingleTone.shared.hide(pk: self.customUIKitBottomSheetOption?.pk)
                }
                // 그렇지 않으면 다시 제자리로 돌아가도록 애니메이션 처리
                else {
                    UIView.animate(withDuration: 0.3) {
                        containerView.frame.origin.y = self.initialTouchPoint?.y ?? 0
                    }
                }
                
                if self.isOverScreen {
                    self.scrollView?.isScrollEnabled = true
                }
                self.isFinishedDragging = true
            }
           

        default:
            break
        }
        
    }
    
    /** 스크롤링 애니매이션이 끝났을때 */
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.isScrolling = false
        if self.isTop {
            if self.scrollView?.bounces ?? false {
                self.scrollView?.isScrollEnabled = false
                self.dragGesture?.isEnabled = true
                self.scrollView?.bounces = false
            }
        }
    }

    /** 사용자가 손을 땠을때 */
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        let offset = scrollView.contentOffset.y
        self.customUIKitBottomSheetOption?.onEndTouchScrolling?(offset, decelerate)
        
        if self.isTop {
            if (self.scrollView?.bounces ?? false) {
                self.scrollView?.isScrollEnabled = false
                self.dragGesture?.isEnabled = true
                self.scrollView?.bounces = false
            }
        }
      
    }
    
    /** 스크롤을 시작했을때 */
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
         let offset = scrollView.contentOffset.y
         let contentHeight = scrollView.contentSize.height
         let scrollViewHeight = scrollView.frame.size.height
         let distanceFromBottom = contentHeight - scrollView.contentOffset.y
         
         
         if contentHeight < scrollViewHeight {
             // 콘텐트가 너무 작으면 스크롤 못하도록 금지
             self.scrollView?.isScrollEnabled = false
             self.dragGesture?.isEnabled = true
             return
         }
         
         self.customUIKitBottomSheetOption?.onScrolling?(offset)
         
         if scrollView.contentOffset.y <= 0 {
             // 상단
             self.isTop = true
             self.isBottom = false
         } else if distanceFromBottom <= scrollViewHeight {
             // 하단
             self.isTop = false
             self.isBottom = true

             if !(self.scrollView?.bounces ?? false) {
                 self.scrollView?.bounces = true
             }
         } else {
             if !(self.scrollView?.bounces ?? false) {
                 self.scrollView?.bounces = true
             }
             self.isTop = false
             self.isBottom = false
             
         }
     }

    /** 드레깅 시작시 */
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.isScrolling = true
    }
    
    /** 상단 클릭시 자동으로 상단으로 스크롤 할지에대한 함수 */
    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
     }
    
    /**
     스크롤 뷰를  스크롤
    
     - Parameters:
         - offset: CGFloat
         - animation: Bool
     - Returns:
    */
    public func scrollTo(offset: CGFloat, animation: Bool) {
        DispatchQueue.main.async {
            self.scrollView?.setContentOffset(CGPoint(x: 0, y: offset), animated: animation)
        }
    }
    
    /**
     스크롤 뷰를 최하단으로 스크롤
    
     - Parameters:
         - animated: Bool [애니메이션 여부] 기본값 True
    */
    public func scrollToBottom(animated: Bool = true) {
        DispatchQueue.main.async {
            let offset = self.scrollView?.contentOffset.y ?? .zero
            let contentSize = self.scrollView?.contentSize.height ?? .zero
            let scrollViewSize = self.scrollView?.frame.size.height ?? .zero
            let scrollViewBottomOffset = self.scrollView?.contentInset.bottom ?? .zero
            
            // 내부 콘텐트가 스크롤한만큼 충분히 있을때 자동 스크롤 가능
            let bottomOffset = CGPoint(x: 0, y: max(contentSize - scrollViewSize + scrollViewBottomOffset, 0))
            
            self.scrollView?.setContentOffset(bottomOffset, animated: animated)
        }
    }
    
    /**
     스크롤 뷰를 최상단으로 스크롤
    
     - Parameters:
         - animated:Bool [애니메이션 여부] 기본값 True
    */
    public func scrollToTop(animated: Bool = true) {
        
        DispatchQueue.main.async {
            self.scrollView?.setContentOffset(CGPoint(x: 0, y: -(self.scrollView?.contentInset.top ?? .zero)), animated: animated)
        }
        
    }
}
