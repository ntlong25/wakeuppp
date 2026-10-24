# WakeMission

> **Báo thức không chỉ để tắt. Muốn tắt, bạn phải thực sự thức dậy.**

WakeMission không tạo báo thức riêng. Bạn dùng báo thức của app **Đồng hồ**; khi tắt báo thức, một automation trong **Shortcuts** chạy WakeMission. App sẽ bắt chuông hệ thống (AlarmKit) reo lại cho tới khi bạn hoàn thành các mission (Typing, Math, Photo).

- Hành vi chi tiết: [`docs/SPEC.md`](docs/SPEC.md) · Kế hoạch: [`docs/PLAN.md`](docs/PLAN.md) · Quy ước cho dev/AI: [`CLAUDE.md`](CLAUDE.md)
- Yêu cầu **iOS 26+ / Xcode 26** (AlarmKit). Mã chưa được biên dịch trên Mac trước đây - build và chạy test đầu tiên.

## Chạy dự án (macOS)
```bash
brew install xcodegen
xcodegen generate
open WakeMission.xcodeproj
```
Chạy trên iPhone thật (chọn Development Team trong Signing).

## Thiết lập sau khi cài
1. Mở app, cấp quyền Alarms (và Camera nếu dùng Photo mission).
2. Chọn missions trong màn hình chính.
3. Vào **Connect to the Clock app** và làm theo hướng dẫn tạo automation trong Shortcuts: *Alarm → Is Stopped → Run Immediately → Start Wake-up Missions*.
4. Thử nhanh bằng nút **Try it now** (chuông reo sau ~5 giây).
