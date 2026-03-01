# Lessons Learned

## SwiftUI TextField Focus in Forms

**Problem:** Multiple TextFields with identical placeholders (`"0.0"`) and `.decimalPad` keyboard in the same Form Section can cause SwiftUI to misroute keyboard input — typing in one field fills both.

**Fix — always apply this pattern:**
1. Add `@FocusState` with a `Field` enum to distinguish each field
2. Give each TextField a unique title label (first param) + use `prompt:` for shared placeholder text
3. Attach `.focused($focusedField, equals: .specificField)` to each TextField

```swift
private enum Field: Hashable {
    case weight
    case bodyFat
}
@FocusState private var focusedField: Field?

// ✅ Correct
TextField("体重", text: $viewModel.inputWeight, prompt: Text("0.0"))
    .focused($focusedField, equals: .weight)

TextField("体脂肪率", text: $viewModel.inputBodyFat, prompt: Text("0.0"))
    .focused($focusedField, equals: .bodyFat)

// ❌ Wrong — identical labels cause focus confusion
TextField("0.0", text: $viewModel.inputWeight)
TextField("0.0", text: $viewModel.inputBodyFat)
```

**Rule:** Any time you have 2+ TextFields in the same Form Section with `.decimalPad`, use `@FocusState`. No exceptions.

**Files fixed:** `MeasurementInputView.swift`, `GoalSettingView.swift`
