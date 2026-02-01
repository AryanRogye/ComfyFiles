//
//  SidebarSplit.swift
//  ComfyFiles
//
//  Created by Aryan Rogye on 1/30/26.
//

import SwiftUI

struct SidebarSplit<Sidebar: View, Content: View>: View {
    
    @Binding var showSidebar: Bool
    let sidebar: Sidebar
    let content: Content
    
    init(
        showSidebar: Binding<Bool>,
        @ViewBuilder sidebar: @escaping () -> Sidebar,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._showSidebar = showSidebar
        self.sidebar = sidebar()
        self.content = content()
    }
    
    // MARK: - State
    @State private var lastWidth: CGFloat = 200
    @State private var width: CGFloat = 150
    @State private var isDragging: Bool = false
    
    /// True only when the current open state was initiated by the left-edge hover.
    /// Hover-exit should close ONLY if this stays true (i.e., user didn’t “commit” via toggle).
    @State private var hoverOpened: Bool = false
    
    /// When the sidebar was opened by hover, we snapshot the cursor state.
    /// If the user manually toggles while it’s hover-open, we “commit” and prevent hover-exit close.
    @State private var ignoreNextHoverExit: Bool = false
    @State private var edgeHovering = false

    // MARK: - Tuning
    private let minWidth: CGFloat = 150
    private let maxWidth: CGFloat = 400
    private let rememberThreshold: CGFloat = 50
    private let edgeWidth: CGFloat = 14
    
    private func clampWidth(_ w: CGFloat) -> CGFloat {
        min(max(w, minWidth), maxWidth)
    }
    
    /// Manual open means “user committed” (don’t auto-close on hover exit)
    private func openSidebar(manual: Bool) {
        if manual {
            if hoverOpened { ignoreNextHoverExit = true }
            hoverOpened = false
        }
        
        showSidebar = true
        if width < minWidth {
            width = clampWidth(lastWidth)
        }
    }
    
    private func closeSidebar() {
        if width > rememberThreshold { lastWidth = width }
        showSidebar = false
        hoverOpened = false
        ignoreNextHoverExit = false
    }
    
    /// Call this when you detect *any* user intent that should “commit” the sidebar open.
    private func commitSidebarOpenIfHoverOpened() {
        if hoverOpened {
            // We were opened by hover; user interacted -> commit
            hoverOpened = false
            ignoreNextHoverExit = true
        }
    }
    
    var body: some View {
        GeometryReader { _ in
            HStack(spacing: 0) {
                
                if showSidebar || width > 1 {
                    sidebar
                        .frame(width: max(width, 0))
                        .frame(maxHeight: .infinity, alignment: .top)
                        .clipped()
                        .overlay(alignment: .trailing) {
                            if showSidebar {
                                SidebarDivider(
                                    showSidebar: $showSidebar,
                                    sidebarWidth: $width,
                                    isDragging: $isDragging,
                                    minWidth: minWidth,
                                    maxWidth: maxWidth,
                                    onCollapse: {
                                        closeSidebar()
                                    },
                                    onUserInteraction: {
                                        // Resizing is a manual commitment; don't auto-close on hover exit.
                                        commitSidebarOpenIfHoverOpened()
                                    }
                                )
                                .transition(.opacity)
                            }
                        }
                }
                
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: width)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showSidebar)
        
        // External toggle behavior (binding changes from outside)
        .onChange(of: showSidebar) { oldValue, newValue in
            if newValue {
                // If someone manually opened it (e.g. toggle button), commit.
                // NOTE: When hover opens, hoverOpened is true, so we *don’t* overwrite it here.
                if !hoverOpened {
                    // Normal manual open, restore width if needed
                    if width <= 1 {
                        width = clampWidth(lastWidth)
                    }
                    ignoreNextHoverExit = false
                } else {
                    // Hover open: ensure width is restored, but keep hoverOpened=true
                    if width <= 1 {
                        width = clampWidth(lastWidth)
                    }
                }
            } else {
                // Closed externally
                width = 0
                hoverOpened = false
                ignoreNextHoverExit = false
            }
        }
        
        // Save width after drag ends
        .onChange(of: isDragging) { _, dragging in
            if !dragging, width > rememberThreshold {
                lastWidth = width
            }
        }
        
        // Left-edge hover overlay
        .overlay(alignment: .leading) {
            LeftEdgeHoverTracker(
                enabled: (!showSidebar) || hoverOpened,
                padding: 24,
                verticalSlack: 8,
                width: $width,
                onHoverChange: { hovering in
                    guard !isDragging else {
                        return
                    }
                    if hovering {
                        // Enter edge: open only if currently closed
                        if !showSidebar {
                            hoverOpened = true
                            ignoreNextHoverExit = false
                            openSidebar(manual: false) // restores width + opens
                        }
                    } else {
                        // Exit edge: collapse ONLY if we were hover-open AND user didn't commit via toggle
                        if hoverOpened {
                            // If user manually committed while hover-open, ignore this exit once
                            if ignoreNextHoverExit {
                                ignoreNextHoverExit = false
                            } else {
                                closeSidebar()
                            }
                        }
                    }
                }
            )
            .frame(width: 1)
            .frame(maxHeight: .infinity)
            .allowsHitTesting(false)
        }
        
        // Optional: if the user clicks anywhere in the sidebar area, that’s also a “commit”
        // Uncomment if you want clicking inside the sidebar to prevent hover-exit collapse.
        /*
         .simultaneousGesture(
         TapGesture().onEnded {
         if showSidebar { commitSidebarOpenIfHoverOpened() }
         }
         )
         */
    }
}

// MARK: - Divider

private struct SidebarDivider: View {
    
    @State private var hoveringOverDivider = false
    
    @Binding var showSidebar: Bool
    @Binding var sidebarWidth: CGFloat
    @Binding var isDragging: Bool
    
    let minWidth: CGFloat
    let maxWidth: CGFloat
    
    let onCollapse: () -> Void
    let onUserInteraction: () -> Void
    
    @State private var dragStartWidth: CGFloat = 0
    
    private var dividerWidth: CGFloat { (hoveringOverDivider || isDragging) ? 2 : 1 }
    
    var body: some View {
        Rectangle()
            .foregroundStyle(.secondary.opacity((hoveringOverDivider || isDragging) ? 0.8 : 0.3))
            .frame(width: dividerWidth)
            .frame(maxHeight: .infinity)
            .padding(.top, 12)
            .overlay(
                Rectangle()
                    .fill(.clear)
                    .frame(width: 16)
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            dragStartWidth = sidebarWidth
                            onUserInteraction()
                        }
                        
                        let rawWidth = dragStartWidth + value.translation.width
                        
                        if rawWidth >= minWidth {
                            let clamped = min(max(rawWidth, minWidth), maxWidth)
                            sidebarWidth = clamped
                        } else if rawWidth <= 40 {
                            showSidebar = false
                            isDragging = false
                            //                            sidebarWidth = 0
                        } else {
                            // dead-zone: do nothing
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                        
                        if sidebarWidth < 0 {
                            sidebarWidth = 0
                            onCollapse()
                        } else {
                            sidebarWidth = min(max(sidebarWidth, minWidth), maxWidth)
                        }
                    }
            )
            .onHover { hover in
                hoveringOverDivider = hover
                if hover { NSCursor.resizeLeftRight.push() } else { NSCursor.pop() }
            }
            .animation(.easeOut(duration: 0.15), value: hoveringOverDivider)
            .animation(.easeOut(duration: 0.15), value: isDragging)
    }
}

// MARK: - Left Edge Hover Tracker (Tracking Area)



struct LeftEdgeHoverTracker: NSViewRepresentable {
    let enabled: Bool
    let padding: CGFloat
    let verticalSlack: CGFloat
    @Binding var width: CGFloat
    let onHoverChange: (Bool) -> Void
    
    func makeNSView(context: Context) -> TrackingStrip {
        let v = TrackingStrip()
        v.onHoverChange = onHoverChange
        v.configure(enabled: enabled, padding: padding, verticalSlack: verticalSlack)
        return v
    }
    
    func updateNSView(_ nsView: TrackingStrip, context: Context) {
        nsView.updateWidthOfTracker(width)
        nsView.onHoverChange = onHoverChange
        nsView.configure(enabled: enabled, padding: padding, verticalSlack: verticalSlack)
    }
}

final class TrackingStrip: NSView {
    var onHoverChange: ((Bool) -> Void)?
    
    private var tracker: HoverTracker?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        tracker = HoverTracker(view: self)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(enabled: Bool, padding: CGFloat, verticalSlack: CGFloat) {
        tracker?.enabled = enabled
        tracker?.padding = padding
        tracker?.verticalSlack = verticalSlack
        
        if enabled, window != nil {
            tracker?.startTracking { [weak self] inside in
                self?.onHoverChange?(inside)
            }
        } else {
            tracker?.stop()
        }
    }
    
#if DEBUG
    private var debugWindow: NSWindow?
    private func showDebugOverlay(rects: [(NSRect, NSColor)]) {
        debugWindow?.orderOut(nil)
        debugWindow = nil
        
        // Cover the whole screen area that contains all rects (simplest: use main screen frame)
        let screenFrame = NSScreen.main?.frame ?? .zero
        
        let win = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        win.isOpaque = false
        win.backgroundColor = .clear
        win.hasShadow = false
        win.ignoresMouseEvents = true
        win.level = .statusBar
        win.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        let container = NSView(frame: win.contentView!.bounds)
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.clear.cgColor
        win.contentView = container
        
        for (r, color) in rects {
            let v = NSView(frame: r)
            v.wantsLayer = true
            v.layer?.backgroundColor = color.withAlphaComponent(0.15).cgColor
            v.layer?.borderColor = color.cgColor
            v.layer?.borderWidth = 2
            container.addSubview(v)
        }
        
        win.orderFrontRegardless()
        debugWindow = win
    }
#endif
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil { tracker?.stop() }
        else if tracker?.enabled == true {
            tracker?.startTracking { [weak self] inside in
                self?.onHoverChange?(inside)
            }
        }
    }
    
    deinit { tracker?.stop() }
    
    public func updateWidthOfTracker(_ width: CGFloat) {
        guard let tracker else { return }
        if width != tracker.exitPadding {
            tracker.exitPadding = width + (tracker.enterPadding * 2)
        }
    }
    
    final class HoverTracker {
        typealias Token = Any
        
        weak var view: TrackingStrip?
        
        var enabled: Bool = true
        var padding: CGFloat = 24
        var verticalSlack: CGFloat = 8
        
        let enterPadding : CGFloat = 24
        var exitPadding : CGFloat = 300
        
        private var monitor: Token?
        private var isInside = false
        
        init(view: TrackingStrip?) { self.view = view }
        
        func startTracking(completion: @escaping (Bool) -> Void) {
            guard monitor == nil else { return }
            
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] e in
                guard let self, self.enabled,
                      let view = self.view,
                      let window = view.window else { return e }
                
                let mouse = NSEvent.mouseLocation
                let baseRect = window.convertToScreen(view.convert(view.bounds, to: nil))
                
                let pad = isInside ? exitPadding : enterPadding
                
                let band = NSRect(
                    x: isInside ? baseRect.minX - enterPadding : baseRect.minX - pad,
                    y: baseRect.minY - verticalSlack,
                    width: pad,
                    height: baseRect.height + 2 * verticalSlack
                )
                
//#if DEBUG
//                DispatchQueue.main.async {
//                    view.showDebugOverlay(rects: [
//                        (baseRect, .systemBlue),
//                        (band, .systemGreen)
//                    ])
//                }
//#endif
                
                let effective = baseRect.contains(mouse) || band.contains(mouse)
                
                if effective != isInside {
                    isInside = effective
                    DispatchQueue.main.async {
                        completion(effective)
                    }
                }

                
                return e
            }
        }
        
        func stop() {
            if let m = monitor { NSEvent.removeMonitor(m) }
            monitor = nil
            isInside = false
        }
    }
}
