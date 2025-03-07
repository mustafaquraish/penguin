import AppKit
import Combine
import SwiftUI

extension NSTextField {
    open override var focusRingType: NSFocusRingType {
        get { .none }
        set {}
    }
}

/// A generic view that provides fuzzy search functionality with keyboard navigation.
/// It displays a search bar at the top, and the child closure
/// can define how to layout the bottom portion (e.g. a list, details, etc.).
struct SearchableView<Item, Content: View>: View {
    @State private var searchText = ""
    @State private var selectedItem: Item? = nil
    @State private var focusedIndex: Int = 0
    @FocusState private var isSearchFieldFocused: Bool
    @State private var eventMonitor: Any? = nil

    // FIXME: This is huge spaghetti. No idea what the difference between `let`, `var` and `@ViewBuilder` is
    //        here and why the AI overlords picked them. Need to learn more.

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
    var onItemSelected: ((Item) -> Void)?

    /// The child closure that defines how to layout the
    /// bottom portion of the view (list, details, etc.).
    ///
    /// - Parameters:
    ///   - filteredItems: The list of items that match the current search text.
    ///   - selectedItem: A binding to the currently selected item.
    ///   - focusedIndex: The index of the item currently focused by keyboard navigation.
    @ViewBuilder let content:
        (_ filteredItems: [Item], _ selectedItem: Binding<Item?>, _ focusedIndex: Binding<Int>) -> Content

    /// Returns only the items that pass the fuzzyMatch filter.
    var filteredItems: [Item] {
        guard !searchText.isEmpty else { return items }
        return items.filter { fuzzyMatch(fuzzyMatchKey($0), searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // A search bar at the top with keyboard handling
            TextField("", text: $searchText, prompt: Text("Search"))
                .font(.system(size: 17))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .focused($isSearchFieldFocused)
                .onAppear {
                    isSearchFieldFocused = true
                    // Set up event monitor when view appears
                    eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [
                        .leftMouseDown, .rightMouseDown,
                    ]) { event in
                        // Small delay to let the click process first
                        DispatchQueue.main.async {
                            isSearchFieldFocused = true
                        }
                        return event
                    }
                    focusedIndex = 0
                }
                .onDisappear {
                    // Clean up event monitor when view disappears
                    if let monitor = eventMonitor {
                        NSEvent.removeMonitor(monitor)
                        eventMonitor = nil
                    }
                    focusedIndex = 0
                }
                // Keep focus when window becomes active
                .onReceive(
                    NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)
                ) { _ in
                    isSearchFieldFocused = true
                    focusedIndex = 0
                }
                // Keep focus when window is activated
                // .onReceive(
                //     NotificationCenter.default.publisher(for: NSWindow.didBecomeMainNotification)
                // ) { _ in
                //     isSearchFieldFocused = true
                //     focusedIndex = 0
                // }
                .onSubmit {
                    if !filteredItems.isEmpty && focusedIndex < filteredItems.count {
                        selectedItem = filteredItems[focusedIndex]
                    }
                }
                .onKeyPress(.upArrow) {
                    focusedIndex = max(0, focusedIndex - 1)
                    if !filteredItems.isEmpty && focusedIndex < filteredItems.count {
                        selectedItem = filteredItems[focusedIndex]
                    }
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    focusedIndex = min(filteredItems.count - 1, focusedIndex + 1)
                    if !filteredItems.isEmpty && focusedIndex < filteredItems.count {
                        selectedItem = filteredItems[focusedIndex]
                    }
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
            content(filteredItems, $selectedItem, $focusedIndex)
        }
        .onChange(of: filteredItems.count) { _, newCount in
            // Reset focused index when the filtered results change
            focusedIndex = newCount == 0 ? 0 : min(focusedIndex, newCount - 1)
        }
    }
}

struct ScrollingSelectionList<Item>: View {
    /// This will get passed in the filtered items, the selected item, and the focused index
    let items: [Item]
    var selectedItem: Binding<Item?>
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
                        selectedItem.wrappedValue = item
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

/// An example usage of `SearchableView` that displays a list of fruits with keyboard navigation
struct ContentViewSimple: View {
    let items = [
        "Apple", "Banana", "Orange", "Grapes", "Peach", "Strawberry", "Blueberry", "Pineapple",
        "Apple", "Banana", "Orange", "Grapes", "Peach", "Strawberry", "Blueberry", "Pineapple",
    ]

    func onItemSelected(_ item: String) {
        print("got item: \(item)")
    }

    var body: some View {
        SearchableView(
            items: items,
            fuzzyMatchKey: { item in item },
            onItemSelected: onItemSelected
        ) { filteredItems, selectedItem, focusedIndex in
            ScrollingSelectionList(
                items: filteredItems,
                selectedItem: selectedItem,
                focusedIndex: focusedIndex,
                onItemClicked: { _ in },
                onItemSelected: onItemSelected,
                elem: { item in Text(item) })
        }
    }
}

struct GlobalSearchView: View {
    let items: [Command]
    let onItemSelected: (Command) -> Void

    var body: some View {
        SearchableView(
            items: items,
            fuzzyMatchKey: { item in item.title },
            onItemSelected: onItemSelected
        ) { filteredItems, selectedItem, focusedIndex in
            ScrollingSelectionList(
                items: filteredItems,
                selectedItem: selectedItem,
                focusedIndex: focusedIndex,
                onItemClicked: onItemSelected,
                onItemSelected: onItemSelected,
                elem: { item in Text(item.title) })
        }
    }
}

/// An example usage of `SearchableView` that displays a list of fruits on the left
/// and a details section on the right when an item is selected.
struct ContentView: View {
    let items = [
        "Apple", "Banana", "Orange", "Grapes", "Peach", "Strawberry", "Blueberry", "Pineapple",
        "Apple", "Banana", "Orange", "Grapes", "Peach", "Strawberry", "Blueberry", "Pineapple",
    ]

    func onItemSelected(_ item: String) {
        print("selected item: \(item)")
    }

    var body: some View {
        SearchableView(
            items: items,
            fuzzyMatchKey: { item in item },
            onItemSelected: onItemSelected
        ) { filteredItems, selectedItem, focusedIndex in
            HStack {
                ScrollingSelectionList(
                    items: filteredItems,
                    selectedItem: selectedItem,
                    focusedIndex: focusedIndex,
                    onItemClicked: { _ in },
                    onItemSelected: onItemSelected,
                    elem: { item in
                        HStack(spacing: 8) {
                            Text(item)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Spacer()
                            Text("Shortcut not set")
                                .foregroundColor(.gray)
                        }
                    })

                Divider()

                // Right side: Details for the selected item
                VStack {
                    if let current = selectedItem.wrappedValue {
                        Text("Details for \(current)")
                            .font(.headline)
                            .padding()
                    } else {
                        Text("Select an item for details")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    //    ContentViewSimple()
    ContentView()
}  //}
