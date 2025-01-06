# ``CustomBottomSheetLibrary``

SwiftUI 에서 사용할수있는 UIKit를 베이스를둔 바텀시트입니다.
SwiftUI에서 제공해주는 sheet에서는 받을수없는 디테일한 콜백들이 포함되어있습니다.
또한 시트의 높이를 동적으로 변경할수있고
뒷 배경색, 시트의 색, 핸들의 색, 터치가능 유무, 키보드 사용시 동적 크기변화 등 여러가지 옵션이 담겨있습니다.


## Overview

위에서 설명한것과 같이 이 오픈 프로젝트는 
UIKit를 베이스로 제작되었습니다.
이 프로젝스에서 사용한 라이브러리는 아래와 같습니다.

``CustomUIKitBottomSheet``

[UIPresentationController](https://developer.apple.com/documentation/uikit/uipresentationcontroller)

[KeyboardManagerLibrary](https://github.com/1domybest/KeyboardManagerLibrary)


# PreView
___
## 기본동작
![샘플1](sample1.gif)

## 시트 안에 시트 열기
![샘플2](sample2.gif)

## 시트 높이 동적으로 변경하기
![샘플3](sample3.gif)


___

## 사용 방법

> 🔴 **Important**:  ``CustomUIKitBottomSheetOption`` 이 객체안에있는 옵션을 커스터마이징하여 사용하시면 됩니다.


### SingleCamera
> ⚠️ **Warning**: "바텀시트를 사용한후에 부모뷰를 pop했을때 ``CustomBottomSheetSingleTone/hide(pk:)`` 
이전에 사용한 바텀시트를 꼭 내려주세요 그렇지않으면 계속 화면에 남아있을수도있습니다."


```swift

import CustomBottomSheetLibrary

func openSwiftUIBottomSheet() {
    let bottomSheetPk = UUID() // 바텀시트 고유 pk
    let parentPk = self.pk // 이 시트를 사용하는 부모의 pk
    
    let view:AnyView = AnyView(
        CustomBottomSheetView(pk: bottomSheetPk) // 바텀시트 내부에 사용할 SwiftUI View
    )
    
    var bottomSheetOption = CustomUIKitBottomSheetOption(pk: bottomSheetPk, someView: view)
    bottomSheetOption.sheetColor = .white // 시트 컬러
    bottomSheetOption.handlerColor = .black // 손잡이 컬러
    bottomSheetOption.dragAvailable = true // 드레그 가능여부
    bottomSheetOption.hasKeyboard = true // 위에 사용하는 SwiftUIView인 CustomBottomSheetView에 키보드가 있는지 여부
    bottomSheetOption.sheetHeight = 604.getHeightScaledDiagonal() // 시트 기본높이
    bottomSheetOption.sheetMode = .custom // 시트 모드
    
    CustomBottomSheetSingleTone.shared.show(customUIKitBottomSheetOption: bottomSheetOption, sheetPk: bottomSheetOption.pk, viewPk: parentPk) // 제공된 싱글톤 CustomBottomSheetSingleTone 을 사용하여 시트 오픈
}

```

> 🔴 **Important**:  위 샘플 코드 이외에도 추가 옵션을 확인하시려면 ``CustomUIKitBottomSheetOption`` 를 확인하시면됩니다.



## 샘플 코드
[CustomBottomSheet_example](https://github.com/1domybest/CustomBottomSheet_example)


## 이 프로젝트에서 사용한 다른 라이브러리

프로젝트 기본구조 ["SwiftUI + UIKit"]
[UIKit-SwiftUI_Project](https://github.com/1domybest/UIKit-SwiftUI_Project)


키보드 매니저
[KeyboardManagerLibrary](https://github.com/1domybest/KeyboardManagerLibrary)



