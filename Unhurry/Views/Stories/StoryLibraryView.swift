//
//  StoryLibraryView.swift
//  Unhurry
//

import SwiftUI

/// 故事/冥想列表——按分类展示故事卡片。
struct StoryLibraryView: View {

    let viewModel: StoryPlayerViewModel

    private let accentColor = Color(red: 0.941, green: 0.902, blue: 0.824)
    private let bgColor = Color(red: 0.216, green: 0.184, blue: 0.322)

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(StoryCategory.allCases) { category in
                        let items = viewModel.stories.filter { $0.category == category }
                        if !items.isEmpty {
                            categorySection(category: category, stories: items)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .foregroundStyle(accentColor)
        .navigationTitle("睡前陪伴")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Category Section

    private func categorySection(category: StoryCategory, stories: [StoryItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(category.displayName, systemImage: category.iconName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(accentColor.opacity(0.6))

            ForEach(stories) { story in
                storyCard(story)
            }
        }
    }

    // MARK: - Story Card

    private func storyCard(_ story: StoryItem) -> some View {
        NavigationLink(destination: StoryPlayerView(viewModel: viewModel, story: story)) {
            HStack(spacing: 14) {
                Image(systemName: story.category.iconName)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(accentColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(story.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(accentColor)

                    Text(story.summary)
                        .font(.caption)
                        .foregroundStyle(accentColor.opacity(0.55))
                        .lineLimit(2)

                    Text(formatDuration(story.estimatedDuration))
                        .font(.caption2)
                        .foregroundStyle(accentColor.opacity(0.35))
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.title3)
                    .foregroundStyle(accentColor.opacity(0.6))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(accentColor.opacity(0.06))
            )
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return "约 \(m) 分 \(s) 秒"
    }
}
