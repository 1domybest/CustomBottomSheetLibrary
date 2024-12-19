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
    
    var bottomSheetList: [(CustomUIKitBottomSheet, UUID, UUID?)] = [] // (시트 옵션, 시트 Pk, 호출하는 viwePk)
    
    public var topViewController:UIViewController?
    private var bottomsheetQueue: DispatchQueue? = DispatchQueue(label: "bottomsheet.queue")
    
    public func updateSheetHeight(pk: UUID, height:CGFloat) {
        // 필터링을 위해 for-in 루프와 enumerated()를 사용하여 인덱스와 요소를 동시에 가져옴
        for (index, (bottomSheetViewController, bottomSheetUUID, viewPk)) in bottomSheetList.enumerated().reversed() {
            if bottomSheetUUID == pk {
                bottomSheetViewController.updateSheetHeight(newHeight: height)
            }
        }
    }
    
    public func findBottomSheetOption(pk: UUID?) -> CustomUIKitBottomSheetOption? {
        guard let sheetPk = pk else { return nil }
        
        for (index, (bottomSheetViewController, bottomSheetUUID, viewPk)) in self.bottomSheetList.enumerated().reversed() {
            if bottomSheetUUID == sheetPk {
                return bottomSheetViewController.customUIKitBottomSheetOption
            }
        }
        
        return nil
    }
    
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
                print("바텀시트 \(self.bottomSheetList)")
                // 배열이 비어 있으면 nil로 설정
                
                if self.bottomSheetList.isEmpty {
                    self.bottomSheetList = []
                    self.topViewController = nil
                }
            }
        }
       
        
    }
    
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
                print("바텀시트 \(self.bottomSheetList)")
            }
        }
    }
    
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
    
    public func hideAll(viewPk: UUID?, animated: Bool = true) {
        print("방송종료 시트 호출됨")
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
