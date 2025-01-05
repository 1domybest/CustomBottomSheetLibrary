//
//  CustomBottomSheetSingleTone.swift
//  HypyG
//
//  Created by 온석태 on 9/9/24.
//

import Foundation
import UIKit

@MainActor
public class CustomBottomSheetSingleTone {
    /// 싱글톤
    public static var shared = CustomBottomSheetSingleTone()
    
    /// 멀티 바텀시트를 위한 시트르 목록 [(시트 옵션, 시트 고유넘버, 부모의 pk)]
    var bottomSheetList: [(CustomUIKitBottomSheet, UUID, UUID?)] = []
    
    /// 최상위 viewController
    public var topViewController:UIViewController?
    
    /// queue
    private var bottomsheetQueue: DispatchQueue? = DispatchQueue(label: "bottomsheet.queue")
    
    /// 높이 업데이트시 호출하는 함수
    public func updateSheetHeight(pk: UUID, height:CGFloat) {
        // 필터링을 위해 for-in 루프와 enumerated()를 사용하여 인덱스와 요소를 동시에 가져옴
        for (index, (bottomSheetViewController, bottomSheetUUID, viewPk)) in bottomSheetList.enumerated().reversed() {
            if bottomSheetUUID == pk {
                bottomSheetViewController.updateSheetHeight(newHeight: height)
            }
        }
    }
    
    /// bottomSheetList 애서 pk 로 해당 바텀시트를 찾을때 사용하는 함수
    public func findBottomSheet(pk: UUID?) -> CustomUIKitBottomSheet? {
        guard let sheetPk = pk else { return nil }
        
        for (index, (bottomSheetViewController, bottomSheetUUID, viewPk)) in self.bottomSheetList.enumerated().reversed() {
            if bottomSheetUUID == sheetPk {
                return bottomSheetViewController
            }
        }
        
        return nil
    }
    
    /// 특정 pk 를 가진 바텀시트 닫을때 사용
    public func hide(pk: UUID?) {
        bottomsheetQueue?.async {
            guard let sheetPk = pk else { return }
            DispatchQueue.main.async {
                // 필터링을 위해 for-in 루프와 enumerated()를 사용하여 인덱스와 요소를 동시에 가져옴
                for (index, (bottomSheetViewController, bottomSheetUUID, viewPk)) in self.bottomSheetList.enumerated().reversed() {
                    if bottomSheetUUID == sheetPk {
                        
                        // 배열에서 해당 요소를 제거
                        if self.bottomSheetList.indices.contains(index) {
                            // Alert를 dismiss 처리
                            self.bottomSheetList[index].0.dismissPresent()
                            self.bottomSheetList.remove(at: index)
                        } else {
                            print("Index \(index) is out of bounds.")
                        }
                    }
                }
                
                if self.bottomSheetList.isEmpty {
                    self.bottomSheetList = []
                    self.topViewController = nil
                }
            }
        }
       
        
    }
    
    /// 특정 pk 를 가진 바텀시트 닫을때 사용 단 닫혔을때 애니메이션을 포함한 함수
    public func hide(sheetPk: UUID?, completion: @escaping @Sendable () -> Void) {
        
        bottomsheetQueue?.async {
            guard let sheetPk = sheetPk else { return }
            
            DispatchQueue.main.async {
                for (index, (bottomSheetViewController, bottomSheetUUID, viewPk)) in self.bottomSheetList.enumerated().reversed() {
                    if bottomSheetUUID == sheetPk {
                        // Alert를 dismiss 처리
                        bottomSheetViewController.dismissPresent(completion: {
                            completion()
                        })
                        
                        // 배열에서 해당 요소를 제거
                        if self.bottomSheetList.indices.contains(index) {
                            self.bottomSheetList.remove(at: index)
                        } else {
                            print("Index \(index) is out of bounds.")
                        }
                    }
                }
                
                if self.bottomSheetList.isEmpty {
                    self.bottomSheetList = []
                    self.topViewController = nil
                }
            }
        }
    }
    
    /// bottomSheetList 에있는 모든 바텀시트를 닫을때 사용
    public func hideAll(animated: Bool = true) {
        bottomsheetQueue?.async {
            DispatchQueue.main.async {
                for (index, (bottomSheetViewController, bottomSheetUUID, viewPk)) in self.bottomSheetList.enumerated().reversed() {
                    bottomSheetViewController.dismissPresent(animated: animated, completion: {
                    })
                }
                
                if self.bottomSheetList.isEmpty {
                    self.bottomSheetList = []
                    self.topViewController = nil
                }
            }
        }
    }
    
    /// 특정 viewPk(시트를 호출할 부모의 pk) 를 가진 바텀시트들만 한번에 닫을때 사용
    public func hideAll(viewPk: UUID?, animated: Bool = true) {
        bottomsheetQueue?.async {
            guard let currentViewPk = viewPk else { return }
            
            DispatchQueue.main.async {
                for (index, (bottomSheetViewController, bottomSheetUUID, viewPk)) in self.bottomSheetList.enumerated().reversed() {
                    guard let viewPk = viewPk else { return }
                    if viewPk == currentViewPk {
                        bottomSheetViewController.dismissPresent(animated: animated, completion: {
                            if self.bottomSheetList.indices.contains(index) {
                                self.bottomSheetList.remove(at: index)
                            } else {
                                print("Index \(index) is out of bounds.")
                            }
                        })
                    }
                }
                
                if self.bottomSheetList.isEmpty {
                    self.bottomSheetList = []
                    self.topViewController = nil
                }
                
            }
        }
    }
    
    /// 바텀시트 노출시 호출
    public func show(customUIKitBottomSheetOption: CustomUIKitBottomSheetOption, sheetPk: UUID, viewPk: UUID?) {
        bottomsheetQueue?.async {
            DispatchQueue.main.async {
                let bottomSheetViewController = CustomUIKitBottomSheet(bottomSheetModel: customUIKitBottomSheetOption)
                
                guard let topController = self.getTopViewController() else { return }
                if self.bottomSheetList.isEmpty { self.topViewController = topController }
                
                topController.present(bottomSheetViewController, animated: true)
                self.bottomSheetList.append((bottomSheetViewController, sheetPk, viewPk))
            }
        }
    }
    

    private func getTopViewController() -> UIViewController? {
        guard let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows
                .filter({ $0.isKeyWindow }).first?.rootViewController else {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                     _ = self.getTopViewController()
                 }
            
            return nil
        }
        
        return getTopViewController(from: rootViewController)
    }
    
    /// 최상위 viewController를 찾을때 사용
    private func getTopViewController(from rootViewController: UIViewController) -> UIViewController? {
        if let presentedViewController = rootViewController.presentedViewController {
            // rootViewController가 다른 뷰 컨트롤러를 표시 중이면, 그 뷰 컨트롤러를 최상단으로 확인
            return getTopViewController(from: presentedViewController)
        }
        
        // Navigation Controller가 있는 경우
        if let navigationController = rootViewController as? UINavigationController {
            return navigationController.visibleViewController
        }
        
        // Tab Bar Controller가 있는 경우
        if let tabBarController = rootViewController as? UITabBarController {
            if let selectedViewController = tabBarController.selectedViewController {
                return getTopViewController(from: selectedViewController)
            }
        }
        
        return rootViewController
    }
}
