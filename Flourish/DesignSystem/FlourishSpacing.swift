import CoreGraphics

// MARK: - Flourish Spacing
// Base unit: 4pt. All values are multiples of 4.

enum FS {
    // Base units
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 16
    static let xl:  CGFloat = 20
    static let xxl: CGFloat = 24

    // Corner radii
    static let radiusSm:   CGFloat = 6   // chips, tags, small buttons
    static let radiusMd:   CGFloat = 10  // sidebar items, dropdown rows
    static let radiusLg:   CGFloat = 14  // hero cards, overlay panel

    // Overlay
    static let overlayWidth:            CGFloat = 640
    static let overlayInputMinHeight:   CGFloat = 56
    static let overlayInputPaddingH:    CGFloat = 20
    static let overlayInputPaddingV:    CGFloat = 16
    static let overlayToolbarPaddingH:  CGFloat = 16
    static let overlayToolbarPaddingV:  CGFloat = 8

    // Loader
    static let loaderWidth:        CGFloat = 80
    static let loaderHeight:       CGFloat = 30
    static let loaderDockGap:      CGFloat = 8   // gap above the dock
    static let loaderDotSize:      CGFloat = 6
    static let loaderDotSpacing:   CGFloat = 6
    static let loaderCornerRadius: CGFloat = 20  // pill shape

    // Main window
    static let mainWindowWidth:  CGFloat = 1060
    static let mainWindowHeight: CGFloat = 700
    static let heroCardHeight:   CGFloat = 160

    // Sidebar
    static let sidebarWidth:          CGFloat = 210
    static let sidebarItemPaddingH:   CGFloat = 12
    static let sidebarItemPaddingV:   CGFloat = 7

    // Settings panel
    static let settingsWindowWidth:  CGFloat = 520
    static let settingsWindowHeight: CGFloat = 440

    // History / detail
    static let historyWindowMinWidth:  CGFloat = 700
    static let historyWindowMinHeight: CGFloat = 460
    static let historySidebarMinWidth: CGFloat = 240
    static let historySidebarMaxWidth: CGFloat = 300
    static let historyDetailMinWidth:  CGFloat = 380

    // Borders
    static let borderWidth: CGFloat = 1

    // Shadows
    static let overlayShadowRadius:  Double = 24
    static let overlayShadowY:       CGFloat = 6
    static let overlayShadowOpacity: Double = 0.14
    static let loaderShadowRadius:   Double = 10
    static let loaderShadowY:        CGFloat = 2
    static let loaderShadowOpacity:  Double = 0.08
}
