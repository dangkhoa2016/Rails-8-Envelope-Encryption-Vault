# Kỹ thuật và nghiệm thu accessibility — v1.0.0

> 🌐 Language / Ngôn ngữ: [English](ACCESSIBILITY.md) | **Tiếng Việt**

## Phạm vi và giới hạn phát hành

Giao diện Vault gồm đăng nhập, MFA, reveal, chỉnh sửa item, lịch sử phiên bản và quản lý session. Khả năng tiếp cận đặc biệt quan trọng vì lỗi UI có thể ngăn người dùng truy cập hoặc quản lý dữ liệu nhạy cảm một cách an toàn.

System tests kiểm tra một số khía cạnh keyboard, focus, responsive/mobile và UX. Tuy nhiên, **không tuyên bố chứng nhận WCAG hoặc nghiệm thu accessibility thủ công cho bản v1.0.0**. Bằng chứng thủ công cũ chỉ áp dụng cho source candidate tương ứng; không đổi nhãn.

## Ma trận đánh giá

| Phạm vi | Điều cần kiểm tra | Cách lấy bằng chứng |
| --- | --- | --- |
| Keyboard | Thứ tự Tab, Enter/Space, không mắc focus | Thao tác thủ công và Rails system tests |
| Focus | Hiển thị rõ sau submit, đóng dialog, chuyển trang | Quan sát trình duyệt và ảnh không chứa secret |
| Screen reader | Name, role, label, form error, thông báo | Narrator/NVDA/VoiceOver trên bản đang review |
| Contrast | Chữ, nút, trạng thái và viền focus | Đo và quan sát trên từng theme hỗ trợ |
| Reduced motion | Không chuyển động khó chịu hoặc dời focus bất ngờ | Bật OS preference và test browser |
| Responsive/touch | Form, scroll modal, overflow và nút cảm ứng | Mobile thật và test layout tự động |
| UI bảo mật | Reveal, MFA, recovery code | End-to-end dùng người dùng và secret giả |

## Quy trình nghiệm thu thủ công

1. Ghi chính xác SHA, trình duyệt, OS, thiết bị và zoom.
2. Dùng **chỉ bàn phím** cho login, MFA, dashboard, danh sách, tạo/sửa mục, reveal và lịch sử.
3. Kiểm tra label, focus, thông báo lỗi có ý nghĩa và khả năng sửa dữ liệu nhập sai.
4. Lặp lại với screen reader và màn hình mobile hẹp.
5. Kiểm tra high-contrast/reduced-motion; không chụp ảnh plaintext bí mật.
6. Ghi issue, mức độ nghiêm trọng, bước tái hiện và bằng chứng đã che nhạy cảm.
7. Đánh dấu từng mục **PASS**, **FAIL**, **PENDING**; không tự kết luận chứng nhận chỉ từ vài trường hợp.

Xem [Kế hoạch kiểm thử](ACCESSIBILITY-TEST-PLAN.vi.md) và [Ma trận kiểm chứng](qualification.vi.md).

## Trạng thái bằng chứng

Nghiệm thu thủ công của bản công bố mã nguồn đầu tiên vẫn là **PENDING** nếu chưa có file bằng chứng hiện tại được review độc lập theo host. Công cụ có thể nhận đường dẫn `UX_ACCESSIBILITY_MANUAL_EVIDENCE_FILE`; chỉ khai báo biến này **không** bảo đảm bằng chứng hợp lệ.

Khi phát hiện vấn đề nhạy cảm, theo [Chính sách bảo mật](SECURITY.vi.md).
