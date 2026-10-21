import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var appState: AppState
    @State private var path: [ManifestCategory] = []
    @State private var showPaywall = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                AppBackground()
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(ManifestCategory.allCases) { category in
                            Button {
                                if appState.isCategoryAvailable(category) {
                                    path.append(category)
                                } else {
                                    showPaywall = true
                                }
                            } label: {
                                CategoryTile(category: category,
                                             isLocked: !appState.isCategoryAvailable(category))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Library")
            .navigationDestination(for: ManifestCategory.self) { CategoryDetailView(category: $0) }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }
}

struct CategoryDetailView: View {
    @EnvironmentObject private var appState: AppState
    let category: ManifestCategory
    @State private var page = 0

    private var items: [Affirmation] { AffirmationLibrary.items(in: category) }

    private var inRotation: Binding<Bool> {
        Binding(get: { appState.data.focusAreas.contains(category) },
                set: { on in
                    if on { appState.data.focusAreas.insert(category) }
                    else if appState.data.focusAreas.count > 1 { appState.data.focusAreas.remove(category) }
                })
    }

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 16) {
                TabView(selection: $page) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        AffirmationCard(affirmation: item)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 6)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 380)

                HStack(spacing: 6) {
                    ForEach(items.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Theme.ink : Theme.hairline)
                            .frame(width: i == page ? 18 : 6, height: 6)
                    }
                }
                .animation(.snappy, value: page)
                .accessibilityLabel("\(page + 1) of \(items.count)")

                Card {
                    Toggle(isOn: inRotation) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Include in my daily rotation")
                                .font(Theme.text(16, weight: .medium))
                                .foregroundStyle(Theme.ink)
                            Text("Today and your reminders draw from these.")
                                .font(Theme.text(13))
                                .foregroundStyle(Theme.secondary)
                        }
                    }
                    .tint(Theme.accent)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                Spacer()
            }
            .padding(.top, 8)
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
