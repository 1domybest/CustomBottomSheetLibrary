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
    /// 바텀시트의 고유 아이디
    public var pk: UUID
    
    /// 바텀시트 내부에 사용한 SwiftUIView
    public var someView: AnyView
    
    /// 바텀시트 모드
    /// 핸들 가능 모드 custom, automatic , popover, pageSheet, formSheet
    /// 핸들 불가능 모드 currentContext, fullScreen, overCurrentContext, overFullScreen,
    public var sheetMode: UIModalPresentationStyle = .custom
    
    /// 시트 높이
    public var sheetHeight: CGFloat = UIScreen.main.bounds.height / 2
    
    /// 드레그 가능 여부
    public var dragAvailable: Bool = true
    
    /// 외부 뒷배경 터치시 닫힘유무
    public var availableOutTouchClose: Bool = true
    
    /// 시트 상단에 손잡이 노출 여부
    public var showHandler: Bool = true
    
    /// 뒷배경 색
    public var backgroundColor: Color = Color.black.opacity(0.5)
    
    /// 시트 상단 손잡이 색
    public var handlerColor: Color = Color.gray
    
    /// 시트 컬러
    public var sheetColor: Color = Color.white
    
    /// 시트 그림자 컬러
    public var sheetShadowColor: Color = Color.gray
    
    /// 최소 높이
    public var minimumHeight:CGFloat = 100
    
    /// 최대 높이
    public var maximumHeight:CGFloat = UIScreen.main.bounds.height
    
    /// someView내부에 키보드 사용유무
    public var hasKeyboard: Bool = false
    
    /// 커스텀 핸들 노출유무 아래 나머지 조건은 전체모드임
    public var availableHasHandle: Bool {
        return showHandler && (sheetMode == .custom ||
                               sheetMode == .automatic ||
                               sheetMode == .popover ||
                               sheetMode == .pageSheet ||
                               sheetMode == .formSheet )
    }
    
    /// 스크롤링시 콜백 함수
    public var onScrolling: ((Double) -> Void)? = { _ in }
    
    /// 스크롤링 종료시 콜백함수
    public var onEndTouchScrolling: ((Double, Bool) -> Void)? = { _,_ in }
    
    /// 시트가 닫혔을시 콜백함수
    public var onDismiss: (() -> Void)? = {}
    
    
    public init(pk: UUID, someView: AnyView) {
        self.pk = pk
        self.someView = someView
    }
}
