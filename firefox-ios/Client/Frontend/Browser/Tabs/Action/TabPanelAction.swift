// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Storage

class TabDisplayModelContext: ActionContext {
    let tabDisplayModel: TabDisplayModel
    init(tabDisplayModel: TabDisplayModel, windowUUID: WindowUUID) {
        self.tabDisplayModel = tabDisplayModel
        super.init(windowUUID: windowUUID)
    }
}

class BoolValueContext: ActionContext {
    let boolValue: Bool
    init(boolValue: Bool, windowUUID: WindowUUID) {
        self.boolValue = boolValue
        super.init(windowUUID: windowUUID)
    }
}

class FloatValueContext: ActionContext {
    let floatValue: Float
    init(floatValue: Float, windowUUID: WindowUUID) {
        self.floatValue = floatValue
        super.init(windowUUID: windowUUID)
    }
}

class DidTapNewTabContext: ActionContext {
    let didTapAddTab: Bool
    let isPrivate: Bool
    let urlRequest: URLRequest?
    init(didTapAddTab: Bool, isPrivate: Bool, urlRequest: URLRequest?, windowUUID: WindowUUID) {
        self.didTapAddTab = didTapAddTab
        self.urlRequest = urlRequest
        self.isPrivate = isPrivate
        super.init(windowUUID: windowUUID)
    }
}

class AddNewTabContext: ActionContext {
    let urlRequest: URLRequest?
    let isPrivate: Bool
    init(urlRequest: URLRequest?, isPrivate: Bool, windowUUID: WindowUUID) {
        self.urlRequest = urlRequest
        self.isPrivate = isPrivate
        super.init(windowUUID: windowUUID)
    }
}

class URLRequestContext: ActionContext {
    let urlRequest: URLRequest
    init(urlRequest: URLRequest, windowUUID: WindowUUID) {
        self.urlRequest = urlRequest
        super.init(windowUUID: windowUUID)
    }
}

class URLContext: ActionContext {
    let url: URL
    init(url: URL, windowUUID: WindowUUID) {
        self.url = url
        super.init(windowUUID: windowUUID)
    }
}

class TabUUIDContext: ActionContext {
    let tabUUID: TabUUID
    init(tabUUID: TabUUID, windowUUID: WindowUUID) {
        self.tabUUID = tabUUID
        super.init(windowUUID: windowUUID)
    }
}

class MoveTabContext: ActionContext {
    let originIndex: Int
    let destinationIndex: Int
    let isPrivate: Bool
    init(originIndex: Int, destinationIndex: Int, isPrivate: Bool, windowUUID: WindowUUID) {
        self.originIndex = originIndex
        self.destinationIndex = destinationIndex
        self.isPrivate = isPrivate
        super.init(windowUUID: windowUUID)
    }
}

class ToastTypeContext: ActionContext {
    let toastType: ToastType
    init(toastType: ToastType, windowUUID: WindowUUID) {
        self.toastType = toastType
        super.init(windowUUID: windowUUID)
    }
}

class KeyboardContext: ActionContext {
    let showOverlay: Bool
    init(showOverlay: Bool, windowUUID: WindowUUID) {
        self.showOverlay = showOverlay
        super.init(windowUUID: windowUUID)
    }
}

class RefreshTabContext: ActionContext {
    let tabDisplayModel: TabDisplayModel
    init(tabDisplayModel: TabDisplayModel, windowUUID: WindowUUID) {
        self.tabDisplayModel = tabDisplayModel
        super.init(windowUUID: windowUUID)
    }
}

class RefreshInactiveTabsContext: ActionContext {
    let inactiveTabModels: [InactiveTabsModel]
    init(tabModels: [InactiveTabsModel], windowUUID: WindowUUID) {
        self.inactiveTabModels = tabModels
        super.init(windowUUID: windowUUID)
    }
}

enum TabPanelAction: Action {
    case tabPanelDidLoad(BoolValueContext)
    case tabPanelDidAppear(BoolValueContext)
    case didTapAddTab(DidTapNewTabContext)
    case addNewTab(AddNewTabContext)
    case closeTab(TabUUIDContext)
    case undoClose(ActionContext)
    case closeAllTabs(ActionContext)
    case confirmCloseAllTabs(ActionContext)
    case undoCloseAllTabs(ActionContext)
    case moveTab(MoveTabContext)
    case toggleInactiveTabs(ActionContext)
    case closeInactiveTabs(TabUUIDContext)
    case undoCloseInactiveTab(ActionContext)
    case closeAllInactiveTabs(ActionContext)
    case undoCloseAllInactiveTabs(ActionContext)
    case learnMorePrivateMode(URLRequestContext)
    case selectTab(TabUUIDContext)
    case showToast(ToastTypeContext)
    case hideUndoToast(ActionContext)
    case showShareSheet(URLContext)

    // Middleware actions
    case didLoadTabPanel(TabDisplayModelContext)
    case didChangeTabPanel(TabDisplayModelContext)
    case refreshTab(RefreshTabContext) // Response to all user actions involving tabs ex: add, close and close all tabs
    case refreshInactiveTabs(RefreshInactiveTabsContext)

    var windowUUID: UUID {
        switch self {
        case .tabPanelDidLoad(let context as ActionContext),
                .tabPanelDidAppear(let context as ActionContext),
                .didTapAddTab(let context as ActionContext),
                .addNewTab(let context as ActionContext),
                .closeTab(let context as ActionContext),
                .undoClose(let context),
                .closeAllTabs(let context),
                .confirmCloseAllTabs(let context),
                .undoCloseAllTabs(let context),
                .moveTab(let context as ActionContext),
                .toggleInactiveTabs(let context),
                .closeInactiveTabs(let context as ActionContext),
                .undoCloseInactiveTab(let context),
                .closeAllInactiveTabs(let context),
                .undoCloseAllInactiveTabs(let context),
                .learnMorePrivateMode(let context as ActionContext),
                .selectTab(let context as ActionContext),
                .showToast(let context as ActionContext),
                .hideUndoToast(let context),
                .showShareSheet(let context as ActionContext),
                .didLoadTabPanel(let context as ActionContext),
                .didChangeTabPanel(let context as ActionContext),
                .refreshTab(let context as ActionContext),
                .refreshInactiveTabs(let context as ActionContext):
            return context.windowUUID
        }
    }
}
