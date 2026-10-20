# Kế hoạch nghiệm thu accessibility — v1.0.0

> 🌐 Language / Ngôn ngữ: [English](ACCESSIBILITY-TEST-PLAN.md) | **Tiếng Việt**

## Phạm vi và điều kiện

Kiểm tra **đúng SHA phát hành** trên các màn hình đăng nhập, MFA, dashboard, danh sách vault, tạo/sửa, reveal, lịch sử phiên bản, cài đặt tài khoản và session. Dùng tài khoản tạm, bí mật giả. Ghi trình duyệt/OS/thiết bị, viewport và phiên bản assistive technology.

Đây là checklist người review, **không** khẳng định đã nghiệm thu thủ công hoặc đạt chứng nhận WCAG.

## Tình huống nghiệm thu

| ID | Tình huống | Kết quả mong đợi |
| --- | --- | --- |
| A01 | Login và MFA chỉ bằng bàn phím | Điều khiển theo thứ tự logic; lỗi rõ; không mắc focus |
| A02 | Focus và xử lý lỗi | Focus nhìn thấy và được phục hồi đúng sau submit/chuyển trang |
| A03 | Label cho screen reader | Input/nút có accessible name; thông báo lỗi được nhận biết |
| A04 | Danh sách/tìm kiếm/bộ lọc | Hiểu mục đích điều khiển, kết quả thay đổi và trạng thái rỗng |
| A05 | Reveal/ẩn lại secret | Trạng thái rõ; không vô tình đưa plaintext vào evidence |
| A06 | Modal và scroll | Nội dung và nút thao tác dùng được ở độ rộng 320–390px |
| A07 | Mobile touch | Không chặn nút, cắt input hoặc tràn ngang |
| A08 | Reduced motion/contrast | Nội dung và focus vẫn nhận biết rõ với OS preferences |
| A09 | Thu hồi session và phục hồi MFA | Hành động nhạy cảm vẫn dùng được, nhãn rõ |
| A10 | Zoom và responsive | Thu phóng và thu hẹp màn hình không mất tính năng chính |

## Cách thực hiện

1. Ghi SHA và ma trận thiết bị/trình duyệt/môi trường.
2. Chạy từng mục bằng keyboard, rồi screen reader và mobile touch khi cần.
3. Ghi **PASS**, **FAIL**, **PENDING** theo ID; chỉ lưu screenshot đã che bí mật.
4. Mở defect có bước tái hiện, người phụ trách; thử lại sau fix ở SHA mới.
5. Người vận hành phải xác nhận độc lập trước khi coi một triển khai cụ thể đạt nghiệm thu.

Không đổi nhãn manual test của source candidate cũ thành bằng chứng cho bản này. Xem [Accessibility](ACCESSIBILITY.vi.md) và [Qualification](qualification.vi.md).
