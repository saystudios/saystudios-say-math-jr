# Say Math Jr.

Little steps. Big math! A math app for kids in **Kindergarten, Grade 1 and Grade 2**, the younger sibling of Say Math.
Native SwiftUI for iPhone and iPad (iOS 17+). © Say Studios LLC.

## What's in this MVP

- **Player setup**: pick a buddy, type a name, choose K / 1st / 2nd.
- **10 skill games**, picked automatically for the grade:

| Skill | K | 1 | 2 |
|---|---|---|---|
| 🍎 Counting (ten-frame rows) | to 10 | to 20 | |
| ⚖️ More or Less | picture groups | numbers to 20 | numbers to 100 |
| ➕ Adding | pictures, within 10 | within 20 | 2-digit |
| ➖ Taking Away | crossed-out pictures | within 20 | 2-digit |
| 🔟 Number Bonds | make 5 / 10 | make 10–20 | make 20 / 100 |
| 🔺 Shapes | 6 basic shapes | names + sides | names + sides |
| 🌈 Patterns | AB, AAB, ABB | + ABC, AABB | |
| 🐸 Skip Counting | | 2s, 5s, 10s | + 100s |
| 🧱 Tens & Ones | | base-ten blocks | + "how many tens" |
| ⏰ Telling Time | | o'clock, half past | 5-minute times |

- **Read-aloud**: every question, hint and cheer can be spoken (works with the ring switch off), so pre-readers can play alone.
- **Gentle mistakes**: a wrong tap wiggles, Pip the puppy gives a hint, and the child tries again. No timers, no game over.
- **Stars & rewards**: 5 questions per game, 1–3 stars, a sticker every 5 stars (20 stickers), daily streak.
- **Grown-ups area** behind a multiplication gate: per-skill progress with first-try accuracy, change grade/name, read-aloud and vibration toggles, reset.
- **Privacy**: no ads, no accounts, no network, no tracking. Progress is stored only on the device.
- All questions are generated fresh each time from original templates (no copied content), with unit tests checking every answer.

## Build without a Mac

The project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`project.yml`), so there's no `.xcodeproj` to manage by hand.

1. Put this folder in a GitHub repo (for example `saystudios/say-math-jr`).
2. The included workflow `.github/workflows/build.yml` runs on GitHub's cloud Macs: it generates the Xcode project, builds the app and runs the tests. Check the **Actions** tab for a green check.

On a Mac: `brew install xcodegen && xcodegen generate && open SayMathJr.xcodeproj`.

## Project layout

```
SayMathJr/
  App/        App entry, root view, mascot bubble
  Engine/     QuestionGenerator (all question templates, grade scaling)
  Models/     Grade, Skill, Question, shapes
  Services/   ProgressStore (local save, stars, stickers, streak), Speaker (read-aloud)
  Theme/      Colors, rounded fonts, card + button styles
  Views/      Onboarding, Home, Lesson, Result, Sticker Book, Grown-ups
  Views/Visuals/  Ten-frame objects, number bonds, shapes, clock, base-ten blocks
SayMathJrTests/   Generator + progress tests
```

## Next stages (ideas)

- TestFlight / App Store upload from GitHub Actions using the App Store Connect API key
- Custom Pip artwork and sound effects
- Multiple child profiles
- More skills: money (coins), measurement, even/odd, fact fluency mini-game
- Spanish / Lao voice option
