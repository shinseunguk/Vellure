import SwiftUI
import VellureCore

/// 설정 화면의 "이름 + 선택" 한 줄.
/// 외형·테마·글자 크기처럼 값 하나를 고르는 항목이 같은 모양을 쓴다.
struct SettingsPickerRow<Option: Identifiable & Hashable>: View {
    let title: String
    /// 이름 아래 붙는 짧은 설명. 없으면 한 줄로 그린다.
    var hint: String?
    let options: [Option]
    let optionLabel: (Option) -> String
    let optionTag: (Option) -> String
    @Binding var selection: String

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .scaledFont(14)
                        .foregroundStyle(Theme.textPrimary)
                    if let hint {
                        Text(hint)
                            .scaledFont(12)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Spacer(minLength: 12)

                Picker("", selection: $selection) {
                    ForEach(options) { option in
                        Text(optionLabel(option)).tag(optionTag(option))
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.accent)
            }
            .padding(15)
        }
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.divider, lineWidth: 1)
        )
    }
}
