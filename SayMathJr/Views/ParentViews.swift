import SwiftUI

/// Simple grown-up check so kids don't wander into settings.
struct ParentGateView: View {
    let onPass: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var a = Int.random(in: 6...9)
    @State private var b = Int.random(in: 6...9)
    @State private var answer = ""
    @State private var wrong = false

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.blue)
            Text("Grown-ups only")
                .font(.kid(26, .heavy))
                .foregroundStyle(Theme.ink)
            Text("What is \(a) × \(b)?")
                .font(.kid(22, .semibold))
                .foregroundStyle(Theme.inkSoft)
            TextField("Answer", text: $answer)
                .keyboardType(.numberPad)
                .font(.kid(28, .bold))
                .multilineTextAlignment(.center)
                .padding(12)
                .frame(maxWidth: 200)
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.sky.opacity(0.6)))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(wrong ? Theme.red : .clear, lineWidth: 3))
            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }
                    .font(.kid(18, .bold))
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Capsule().fill(Theme.sky))
                Button("Continue") { check() }
                    .font(.kid(18, .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Capsule().fill(Theme.blue))
            }
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: 360)
        }
        .padding(28)
    }

    private func check() {
        if Int(answer.trimmingCharacters(in: .whitespaces)) == a * b {
            onPass()
        } else {
            wrong = true
            answer = ""
            a = Int.random(in: 6...9)
            b = Int.random(in: 6...9)
        }
    }
}

struct ParentView: View {
    @EnvironmentObject private var store: ProgressStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var grade: Grade = .k
    @State private var confirmReset = false
    @State private var confirmNewPlayer = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Player") {
                    TextField("Name", text: $name)
                    Picker("Grade", selection: $grade) {
                        ForEach(Grade.allCases) { Text($0.title).tag($0) }
                    }
                }

                Section {
                    ForEach(Skill.skills(for: store.grade)) { skill in
                        let p = store.progress(for: skill)
                        HStack {
                            Text(skill.emoji)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(skill.title).font(.body.weight(.semibold))
                                Text(p.lessonsDone == 0
                                     ? "Not started"
                                     : "\(p.lessonsDone) lesson\(p.lessonsDone == 1 ? "" : "s") · \(Int((p.accuracy * 100).rounded()))% first-try")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(String(repeating: "★", count: p.bestStars) + String(repeating: "☆", count: 3 - p.bestStars))
                                .foregroundStyle(Theme.orange)
                        }
                    }
                } header: {
                    Text("Progress · \(store.grade.title)")
                } footer: {
                    Text("“First-try” means the answer was right without a hint. Skills with low first-try scores are good ones to practice together.")
                }

                Section("Settings") {
                    Toggle("Read questions out loud", isOn: Binding(
                        get: { store.settings.readAloud },
                        set: { v in store.updateSettings { $0.readAloud = v } }))
                    Toggle("Vibration feedback", isOn: Binding(
                        get: { store.settings.haptics },
                        set: { v in store.updateSettings { $0.haptics = v } }))
                }

                Section {
                    Button("Reset stars and stickers", role: .destructive) { confirmReset = true }
                    Button("New player (erase everything)", role: .destructive) { confirmNewPlayer = true }
                }

                Section("About") {
                    LabeledContent("App", value: "Say Math Jr.")
                    LabeledContent("Version", value: Bundle.main.appVersion)
                    Text("No ads, no accounts, no data collection. All progress is stored only on this device.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("© Say Studios LLC · SayStudiosllc@yahoo.com")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Grown-ups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { save(); dismiss() }
                }
            }
            .onAppear {
                name = store.profile?.name ?? ""
                grade = store.grade
            }
            .confirmationDialog("Reset all stars and stickers?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset", role: .destructive) { store.resetProgress() }
            }
            .confirmationDialog("Erase this player and start over?", isPresented: $confirmNewPlayer, titleVisibility: .visible) {
                Button("Erase", role: .destructive) {
                    store.resetEverything()
                    dismiss()
                }
            }
        }
    }

    private func save() {
        guard var profile = store.profile else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.name = trimmed.isEmpty ? profile.name : trimmed
        profile.grade = grade
        store.saveProfile(profile)
    }
}

extension Bundle {
    var appVersion: String {
        let v = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}
