# WakeMission ⏰🔥

> **Báo thức không chỉ để tắt. Muốn tắt, bạn phải thực sự thức dậy.**

WakeMission là ứng dụng báo thức iOS thế hệ mới, ứng dụng hệ thống **Apple AlarmKit** kết hợp **App Intents** và chuỗi nhiệm vụ **Wake-up Missions** tuần tự (Typing, Math, Photo verification).

---

## 🛠 Tech Stack
- **Ngôn ngữ & Mode**: Swift 6 (Strict Concurrency `complete`)
- **UI Framework**: SwiftUI + Modern Dark Aesthetics
- **Persistence**: SwiftData (`AlarmItem`, `MissionItem`, `AlarmSessionRecord`)
- **Alarm System**: Apple [AlarmKit](https://developer.apple.com/documentation/alarmkit) (xuyên Silent/Focus mode, không cần hack background audio)
- **Action Triggers**: [App Intents](https://developer.apple.com/documentation/appintents) (`OpenAppFromAlarmIntent`)
- **Computer Vision**: Apple Vision (`VNClassifyImageRequest` / `VNGenerateImageFeaturePrintRequest`) & AVFoundation
- **Audio Engine**: AVFoundation `AVAudioSession` (.playback / .alarm mode)

---

## 📁 Cấu trúc thư mục

```
WakeMission/
├── App/
│   ├── WakeMissionApp.swift               # Entry point + ModelContainer + Ringing FullScreenCover
│   └── AppState.swift                     # Global state, AlarmKit observer, Audio triggers
├── Models/
│   ├── AlarmItem.swift                    # SwiftData model cho báo thức (time, repeat, label, sound)
│   ├── MissionItem.swift                  # SwiftData model cho nhiệm vụ (Typing, Math, Photo)
│   └── AlarmSessionRecord.swift           # Model lưu lịch sử thức dậy (streak, duration, snoozes)
├── Services/
│   ├── Alarm/
│   │   ├── AlarmServiceProtocol.swift     # Interface abstraction
│   │   └── AlarmService.swift             # Quản lý AlarmKit và AlarmManager.shared
│   ├── Intents/
│   │   ├── OpenAppFromAlarmIntent.swift   # AppIntent mở app từ Lock Screen
│   │   └── StopAlarmIntent.swift          # AppIntent dừng báo thức khi hoàn thành
│   ├── Audio/
│   │   └── AlarmAudioPlayer.swift         # Vòng lặp phát âm thanh + 10-phút safety cutoff
│   ├── Camera/
│   │   └── CameraService.swift            # AVCaptureSession lấy live frames
│   └── Vision/
│       └── VisionVerificationService.swift# Phân tích hình ảnh bồn rửa/vòi nước
└── Features/
    ├── AlarmList/
    │   ├── AlarmListView.swift            # Màn hình chính + đếm ngược + Milestone 0 test button
    │   └── AlarmRowView.swift             # Row hiển thị giờ, nhãn, ngày lặp & mission badges
    ├── AlarmEditor/
    │   ├── AlarmEditView.swift            # Tạo/sửa báo thức (Wheel picker, Sound, Snooze)
    │   ├── RepeatPicker.swift             # Chọn ngày trong tuần (M T W T F S S)
    │   └── MissionSelectorView.swift      # Thêm/xoá/kéo thả sắp xếp thứ tự missions
    ├── AlarmRinging/
    │   └── AlarmRingingContainerView.swift# Màn hình chuông reo + MissionCoordinator container
    └── Missions/
        ├── Common/
        │   ├── MissionHandler.swift       # Protocol chuẩn cho từng mission
        │   └── MissionCoordinator.swift   # Điều phối chuỗi nhiệm vụ 1 -> 2 -> 3
        ├── Typing/
        │   ├── TypingPhraseGenerator.swift# Kho trích dẫn động lực theo độ khó
        │   └── TypingMissionView.swift    # Kiểm tra gõ phím theo ký tự
        ├── Math/
        │   ├── MathProblemGenerator.swift # Sinh đề toán số học ngẫu nhiên
        │   ├── KeypadView.swift           # Bàn phím số cảm ứng lớn
        │   └── MathMissionView.swift      # Màn hình giải toán 1/3
        └── Photo/
            └── PhotoMissionView.swift     # Camera viewfinder + khung ngắm + độ tin cậy Vision
```

---

## 🚀 Hướng dẫn mở & Chạy dự án (trên macOS / Xcode)

### Bước 1: Cài đặt XcodeGen (nếu chưa có)
```bash
brew install xcodegen
```

### Bước 2: Tạo Xcode Project
Chạy lệnh sau tại thư mục gốc của project:
```bash
xcodegen generate
```
Lệnh trên sẽ tự động tạo file `WakeMission.xcodeproj` chuẩn chỉ 100%, sẵn sàng mở ngay bằng Xcode.

### Bước 3: Mở trong Xcode
```bash
open WakeMission.xcodeproj
```

---

## 🎯 Milestone 0: Kiểm chứng AlarmKit (Day 3-4 Week 1)

1. Build app lên **iPhone thật** chạy iOS tương thích (chọn Development Team của bạn trong Signing & Capabilities).
2. Khi mở app lần đầu, cấp quyền **AlarmKit** và **Camera**.
3. Tại màn hình chính, nhấn nút:
   👉 **"Test Alarm in 1 Minute"**
4. Sau khi lên lịch:
   - **Tắt hẳn app** (vuốt tắt trong App Switcher).
   - **Bật công tắc Silent (gạt rung)**.
   - **Bật chế độ Focus / Do Not Disturb**.
   - **Khoá màn hình iPhone**.
5. Sau đúng 60 giây:
   - Chuông AlarmKit sẽ xuất hiện trên Lock Screen & Dynamic Island, âm thanh xuyên qua Silent/Focus mode.
   - Nhấn **"Start Mission"** hoặc **"Wake Up"**: App WakeMission lập tức mở lên ở màn hình thực hiện nhiệm vụ.
   - Thực hiện gõ chữ (Typing) hoặc giải toán (Math).
   - Sau khi hoàn thành nhiệm vụ cuối cùng, âm thanh chuông lập tức dừng và ghi nhận thành công!
