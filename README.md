# WakeMission

> **Báo thức không chỉ để tắt. Muốn tắt, bạn phải thực sự thức dậy.**

WakeMission là app báo thức có giao diện giống app Đồng hồ. Khi báo thức reo, bạn phải hoàn thành các nhiệm vụ (gõ chữ, giải toán, chụp ảnh); chưa xong thì chuông vẫn quay lại, kể cả khi đóng app.

- Hành vi chi tiết: [`docs/SPEC.md`](docs/SPEC.md) · Kế hoạch: [`docs/PLAN.md`](docs/PLAN.md) · Quy ước cho dev/AI: [`CLAUDE.md`](CLAUDE.md)
- Yêu cầu **iOS 26+ / Xcode 26** (AlarmKit). Mã chưa được biên dịch trên Mac trước đây - build và chạy test đầu tiên.

## Chạy dự án (macOS)
```bash
brew install xcodegen
xcodegen generate
open WakeMission.xcodeproj
```
Chạy trên iPhone thật (chọn Development Team trong Signing).

## Sử dụng
1. Mở app và cấp quyền Báo thức (và Camera nếu dùng nhiệm vụ Ảnh).
2. Thêm báo thức ở tab **Báo thức**.
3. Chọn nhiệm vụ và nhịp reo lại ở tab **Cài đặt**.
4. Thử nhanh bằng nút **Test Wake-Up Flow** trong tab Cài đặt.
