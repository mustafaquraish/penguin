extension NSTextField {
        open override var focusRingType: NSFocusRingType {
                get { .none }
                set { }
        }
}


/// A generic view that provides fuzzy search functionality with keyboard navigation.
/// It displays a search bar at the top, and the child closure
/// can define how to layout the bottom portion (e.g. a list, details, etc.).
struct SearchableView<Item: Hashable, Content: View>: View {
    @State private var searchText = ""
    @State private var selectedItem: Item? = nil
    @State private var focusedIndex: Int = 0
    @FocusState private var isSearchFieldFocused: Bool


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
    @ViewBuilder let content: (_ filteredItems: [Item], _ selectedItem: Binding<Item?>, _ focusedIndex: Int) -> Content

    /// Returns only the items that pass the fuzzyMatch filter.
    var filteredItems: [Item] {
        guard !searchText.isEmpty else { return items }
        return items.filter { fuzzyMatch(fuzzyMatchKey($0), searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // A search bar at the top with keyboard handling
            TextField("Search...", text: $searchText)
                .font(.system(size: 17))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .focused($isSearchFieldFocused)
                .onAppear {
                    isSearchFieldFocused = true
                    print("isSearchFieldFocused: \(isSearchFieldFocused)")
                }
                .onSubmit {
                    if !filteredItems.isEmpty && focusedIndex < filteredItems.count {
                        selectedItem = filteredItems[focusedIndex]
                    }
                }
                .onKeyPress(.upArrow) {
                    print("upArrow")
                    focusedIndex = max(0, focusedIndex - 1)
                    if !filteredItems.isEmpty && focusedIndex < filteredItems.count {
                        selectedItem = filteredItems[focusedIndex]
                    }
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    print("downArrow")
                    focusedIndex = min(filteredItems.count - 1, focusedIndex + 1)
                    if !filteredItems.isEmpty && focusedIndex < filteredItems.count {
                        selectedItem = filteredItems[focusedIndex]
                    }
                    return .handled
                }
                .onKeyPress(.return) {
                    print("return")
                    if let selectedItem = selectedItem {
                        if let onItemSelected = onItemSelected {
                            onItemSelected(selectedItem)
                        }
                    }
                    return .handled
                }


            // Child closure decides how to layout the filtered items and selected item details
            content(filteredItems, $selectedItem, focusedIndex)
        }
        .onChange(of: filteredItems) { _, newItems in
            // Reset focused index when the filtered results change
            focusedIndex = newItems.isEmpty ? 0 : min(focusedIndex, newItems.count - 1)
        }
    }
}

/// An example usage of `SearchableView` that displays a list of fruits with keyboard navigation
struct ContentView2: View {
    let items = ["Apple", "Banana", "Orange", "Grapes", "Peach", "Strawberry", "Blueberry", "Pineapple","Apple", "Banana", "Orange", "Grapes", "Peach", "Strawberry", "Blueberry", "Pineapple"]

    /// A simple fuzzy matching function: each character of `query`
    /// must appear in the item's text in the same order.
    func fuzzyMatchKey(_ item: String) -> String {
        return item
    }

    func onItemSelected(_ item: String) {
        print("git " + item)
//        let notification = NSUserNotification()
//        notification.title = item + "!"
//        notification.informativeText = "You selected \(item)"
//        NSUserNotificationCenter.default.deliver(notification)
    }

    var body: some View {
        SearchableView(items: items,
                       fuzzyMatchKey: fuzzyMatchKey,
                       onItemSelected: onItemSelected) { filteredItems, selectedItem, focusedIndex in
            ScrollViewReader { scrollProxy in
                List {
                    ForEach(Array(filteredItems.enumerated()), id: \.offset) { index, item in
                        Text(item)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(5)
                            .background(index == focusedIndex ? Color.blue.opacity(0.2) : Color.clear)
                            .cornerRadius(5)
                            .id(index) // Add ID for scrolling
                            .onTapGesture {
                                selectedItem.wrappedValue = item
                            }
                    }
                }
                .frame(maxWidth: .infinity)
                .onChange(of: focusedIndex) { _, newIndex in
                    // Scroll to focused index when it changes
                    withAnimation {
                        scrollProxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
        }
    }
}

/// An example usage of `SearchableView` that displays a list of fruits on the left
/// and a details section on the right when an item is selected.
struct ContentView: View {
    let items = ["Apple", "Banana", "Orange", "Grapes", "Peach", "Strawberry", "Blueberry", "Pineapple","Apple", "Banana", "Orange", "Grapes", "Peach", "Strawberry", "Blueberry", "Pineapple"]

    /// A simple fuzzy matching function: each character of `query`
    /// must appear in the item's text in the same order.
    func fuzzyMatchKey(_ item: String) -> String {
        return item
    }

    @State private var searchText = ""

    var body: some View {
        SearchableView(items: items,
                       fuzzyMatchKey: fuzzyMatchKey) { filteredItems, selectedItem, focusedIndex in
            HStack {
                // Left side: List of filtered items with keyboard focus highlight
                ScrollViewReader { scrollProxy in
                    List {
                        ForEach(Array(filteredItems.enumerated()), id: \.offset) { index, item in
                            Text(item)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(5)
                                .background(index == focusedIndex ? Color.blue.opacity(0.2) : Color.clear)
                                .cornerRadius(5)
                                .id(index) // Add ID for scrolling
                                .onTapGesture {
                                    selectedItem.wrappedValue = item
                                }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .onChange(of: focusedIndex) { _, newIndex in
                        // Scroll to focused index when it changes
                        withAnimation {
                            scrollProxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }

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
            .navigationTitle("Fuzzy Search")
        }
    }
}

//#Preview {
////    ContentView2()
//     ContentView()
//} 