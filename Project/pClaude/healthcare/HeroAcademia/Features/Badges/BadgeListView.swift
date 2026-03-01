import SwiftUI

struct BadgeListView: View {
    @Bindable var viewModel: BadgeViewModel

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Summary
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)
                    Text("\(viewModel.earnedBadges.count)/\(viewModel.allBadgeTypes.count) 獲得済み")
                        .font(.headline)
                }
                .padding(.horizontal)

                // Badge grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.allBadgeTypes, id: \.self) { badgeType in
                        BadgeCardView(
                            badgeType: badgeType,
                            isEarned: viewModel.isEarned(badgeType),
                            earnedDate: viewModel.earnedDate(for: badgeType)
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("バッジ")
        .task {
            await viewModel.loadBadges()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}
