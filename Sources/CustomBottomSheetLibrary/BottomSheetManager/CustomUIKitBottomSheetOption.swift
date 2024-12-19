//
//  BottomSheetModel.swift
//  HypyG
//
//  Created by 온석태 on 9/9/24.
//

import Foundation
import SwiftUI
import UIKit

@MainActor
public struct CustomUIKitBottomSheetOption: Sendable {
    public var pk: UUID
    public var someView: AnyView
    public var sheetMode: UIModalPresentationStyle = .custom
    // 핸들 가능 모드 custom, automatic , popover, pageSheet, formSheet
    // 핸들 불가능 모드 currentContext, fullScreen, overCurrentContext, overFullScreen,
    
    public var sheetHeight: CGFloat = UIScreen.main.bounds.height / 2
    public var dragAvailable: Bool = true
    public var availableOutTouchClose: Bool = true
    public var showHandler: Bool = true
    
    public var backgroundColor: Color = Color.black.opacity(0.5)
    public var handlerColor: Color = Color.gray
    public var sheetColor: Color = Color.white
    public var sheetShadowColor: Color = Color.gray
    
    
    public var minimumHeight:CGFloat = 100
    public var maximumHeight:CGFloat = UIScreen.main.bounds.height
    
    public var hasKeyboard: Bool = false
    
    public var availableHasHandle: Bool {
        return showHandler && (sheetMode == .custom ||
                               sheetMode == .automatic ||
                               sheetMode == .popover ||
                               sheetMode == .pageSheet ||
                               sheetMode == .formSheet )
    }
    
    public var onScrolling: ((Double) -> Void)? = { _ in }
    public var onEndTouchScrolling: ((Double, Bool) -> Void)? = { _,_ in }
    
    public var onDismiss: (() -> Void)? = {}
    
    
    public init(pk: UUID, someView: AnyView) {
        self.pk = pk
        self.someView = someView
    }
}
