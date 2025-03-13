import AppKit
import Combine
import SwiftUI
import KeyboardShortcuts

extension NSTextField {
    open override var focusRingType: NSFocusRingType {
        get { .none }
        set {}
    }
}

struct Labelled: View {
    let label: String

    @ViewBuilder let content: () -> any View

    var body: some View {
        HStack {
            Text(label)
            AnyView(content())
        }
    }
}

// This view will prevent dragging when the user clicks on it.
struct NonDraggableView<Content: View>: NSViewRepresentable {
    typealias NSViewType = NSHostingView<Content>

    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeNSView(context: Context) -> NSHostingView<Content> {
        NSHostingView(rootView: content)
    }

    func updateNSView(_ nsView: NSHostingView<Content>, context: Context) {
        nsView.rootView = content
    }
}

/// A generic view that provides fuzzy search functionality with keyboard navigation.
/// It displays a search bar at the top, and the child closure
/// can define how to layout the bottom portion (e.g. a list, details, etc.).
struct FuzzySearchableView<Item, Content: View>: View {
    @State private var searchText = ""
    @State private var focusedIndex: Int = 0
    @FocusState private var isSearchFieldFocused: Bool

    /// The full list of items to search.
    let items: [Item]

    /// A fuzzy matching function. Returns `true` if `item`
    /// should appear for the given `query`.
    func fuzzyMatch(_ item: String, _ query: String) -> Bool {
        let lowerItem = item.lowercased()
        let lowerQuery = query.lowercased()

        var queryIndex = lowerQuery.startIndex
        for char in lowerItem {
            if char == lowerQuery[queryIndex] {
                queryIndex = lowerQuery.index(after: queryIndex)
                if queryIndex == lowerQuery.endIndex {
                    return true
                }
            }
        }
        return false
    }

    let fuzzyMatchKey: (Item) -> String

    /// Optional callback triggered when the item is selected.
    let onItemSelected: ((Item) -> Void)?

    /// The child closure that defines how to layout the
    /// bottom portion of the view (list, details, etc.).
    @ViewBuilder let content:
        (_ filteredItems: [Item], _ selectedItem: Item?, _ focusedIndex: Binding<Int>) -> Content

    /// Returns only the items that pass the fuzzyMatch filter.
    var filteredItems: [Item] {
        guard !searchText.isEmpty else { return items }
        return items.filter { fuzzyMatch(fuzzyMatchKey($0), searchText) }
    }

    var selectedItem: Item? {
        if focusedIndex < filteredItems.count {
            return filteredItems[focusedIndex]
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // A search bar at the top with keyboard handling
            TextField("", text: $searchText, prompt: Text("Search"))
                .font(.system(size: 20))
                .textFieldStyle(.automatic)
                .padding()
                .focused($isSearchFieldFocused)
                .onAppear {
                    isSearchFieldFocused = true
                    focusedIndex = 0
                }
                .onDisappear {
                    focusedIndex = 0
                }
                .onKeyPress(.upArrow) {
                    focusedIndex = max(0, focusedIndex - 1)
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    focusedIndex = min(filteredItems.count - 1, focusedIndex + 1)
                    return .handled
                }
                .onKeyPress(.return) {
                    if let selectedItem = selectedItem {
                        if let onItemSelected = onItemSelected {
                            onItemSelected(selectedItem)
                        }
                    }
                    return .handled
                }

            // Child closure decides how to layout the filtered items and selected item details
            content(filteredItems, selectedItem, $focusedIndex)
        }
        .onChange(of: filteredItems.count) { _, newCount in
            // Reset focused index when the filtered results change
            focusedIndex = newCount == 0 ? 0 : min(focusedIndex, newCount - 1)
        }
    }
}

// FIXME: Refactor this to share code with FuzzySearchableView, this is _essentially_ the same
//        struct with `filteredItems` overridden, but we can't do inheritance with structs.
struct ExternalSearchableView<Item, Content: View>: View {
    @State private var searchText = ""
    @State private var focusedIndex: Int = 0
    @FocusState private var isSearchFieldFocused: Bool

    var initialItems: [Item] = []
    let performSearch: (String) -> [Item]

    /// Optional callback triggered when the item is selected.
    let onItemSelected: ((Item) -> Void)?

    /// The child closure that defines how to layout the
    /// bottom portion of the view (list, details, etc.).
    @ViewBuilder let content:
        (_ filteredItems: [Item], _ selectedItem: Item?, _ focusedIndex: Binding<Int>) -> Content


    init(
        performSearch: @escaping (String) -> [Item],
        onItemSelected: ((Item) -> Void)?,
        @ViewBuilder content: @escaping (_ filteredItems: [Item], _ selectedItem: Item?, _ focusedIndex: Binding<Int>) -> Content
    ) {
        self.initialItems = performSearch("")
        self.performSearch = performSearch
        self.onItemSelected = onItemSelected
        self.content = content
    }

    @State private var filteredItems: [Item] = []

    var selectedItem: Item? {
        if focusedIndex < filteredItems.count {
            return filteredItems[focusedIndex]
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // A search bar at the top with keyboard handling
            TextField("", text: $searchText, prompt: Text("Search"))
                .font(.system(size: 20))
                .textFieldStyle(.automatic)
                .padding()
                .focused($isSearchFieldFocused)
                .onAppear {
                    isSearchFieldFocused = true
                    focusedIndex = 0
                    // FIXME: Calling performSearch() here causes the focus to be lost... not sure why,
                    //        but it doesn't happen if we have pre-populated items.
                    filteredItems = initialItems
                }
                .onDisappear {
                    focusedIndex = 0
                }
                .onKeyPress(.upArrow) {
                    focusedIndex = max(0, focusedIndex - 1)
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    focusedIndex = min(filteredItems.count - 1, focusedIndex + 1)
                    return .handled
                }
                .onKeyPress(.return) {
                    if let selectedItem = selectedItem {
                        if let onItemSelected = onItemSelected {
                            onItemSelected(selectedItem)
                        }
                    }
                    return .handled
                }

            // Child closure decides how to layout the filtered items and selected item details
            content(filteredItems, selectedItem, $focusedIndex)
        }
        .onChange(of: searchText) { _, newSearchText in
            filteredItems = performSearch(newSearchText)
            focusedIndex = 0
        }
    }
}

struct ScrollingSelectionList<Item>: View {
    /// This will get passed in the filtered items, the selected item, and the focused index
    let items: [Item]
    var focusedIndex: Binding<Int>
    var onItemClicked: ((Item) -> Void)?
    var onItemSelected: ((Item) -> Void)?
    let highlightColor: Color = Color.blue.opacity(0.2)
    @State private var hoveredIndex: Int? = nil
    @State private var isKeyboardNavigation: Bool = true

    @State private var lastTapTime: Date? = nil
    let tapThreshold: TimeInterval = 0.3 // Adjust as needed

    let elem: (Item) -> any View
    var body: some View {
        ScrollViewReader { scrollProxy in
            List {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    ZStack {
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())  // This makes the entire area interactive

                        AnyView(elem(item))
                            .font(.system(size: 16))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(5)
                    }
                    .background(
                        index == focusedIndex.wrappedValue
                            ? highlightColor
                            : index == hoveredIndex ? highlightColor.opacity(0.5) : Color.clear
                    )
                    .cornerRadius(5)
                    .id(index)  // Add ID for ScrollViewReader
                    .onTapGesture {
                        focusedIndex.wrappedValue = index
                        isKeyboardNavigation = false
                        onItemClicked?(item)

                        // Check if the double tap is within the threshold
                        let now = Date()
                        if let lastTap = lastTapTime, now.timeIntervalSince(lastTap) < tapThreshold {
                            onItemSelected?(item)
                        }
                        lastTapTime = now
                    }
                    .onKeyPress(.upArrow) {
                        focusedIndex.wrappedValue = max(0, focusedIndex.wrappedValue - 1)
                        return .ignored
                    }
                    .onKeyPress(.downArrow) {
                        focusedIndex.wrappedValue = min(items.count - 1, focusedIndex.wrappedValue + 1)
                        return .ignored
                    }
                    .onHover { hovering in
                        hoveredIndex = hovering ? index : nil
                    }
                }
            }
            .onChange(of: focusedIndex.wrappedValue) { _, newIndex in
                // Only scroll enough to ensure the item is visible
                if isKeyboardNavigation && items.indices.contains(newIndex) {
                    withAnimation {
                        scrollProxy.scrollTo(newIndex, anchor: .leading)
                    }
                }
                isKeyboardNavigation = true
            }
        }
        .frame(maxWidth: .infinity)
    }
}
