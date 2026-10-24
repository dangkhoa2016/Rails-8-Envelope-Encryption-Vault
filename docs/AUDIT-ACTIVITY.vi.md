# Audit Activity Center — phạm vi bảo mật và kiểm chứng

> 🌐 Language / Ngôn ngữ: [English](AUDIT-ACTIVITY.md) | **Tiếng Việt**

## Phạm vi tính năng

Security Activity Center là **cải tiến sau v1.0.0**, dự kiến phát hành sau khi nghiệm thu; **không thuộc tag v1.0.0 đã công khai**.

- Bốn chỉ số đúng phạm vi: số sự kiện tài khoản, thao tác nhạy cảm, lần kiểm tra thất bại và thời điểm sự kiện mới nhất **trong khoảng thời gian được chọn**.
- Lọc 7, 30 (mặc định), 90 ngày hoặc toàn bộ dữ liệu đang lưu; kết hợp Category, Action và Outcome (Completed / Failed / Recorded) cùng phân trang.
- Timeline nhóm theo ngày trong múi giờ ứng dụng; mỗi sự kiện có nhãn, loại, kết quả và thời gian.
- Chi tiết mở rộng chỉ hiển thị metadata được presenter cho phép và mã tham chiếu đã rút gọn, không lộ secret.
- Form GET và `details` HTML vẫn hoạt động khi không có JavaScript; Stimulus chỉ tăng cường lựa chọn Action khi thay Category.

## Đúng đắn của số liệu bảo mật

**Đây là Audit theo tài khoản, không phải công cụ giám sát toàn hệ thống (SIEM).** Toàn bộ timeline, thống kê và bộ đếm chỉ lấy từ `user.audit_events` của tài khoản xác thực. Mã nguồn hiện tại ghi các lần đăng nhập thất bại không xác định danh tính với `user_id` rỗng; các sự kiện key rotation thuộc phạm vi hệ thống. Những sự kiện này **không nằm** trong timeline của một người dùng thông thường. Vì vậy, “0 Failed checks” không chứng minh không hề có đăng nhập thất bại ẩn danh.

Kết quả được phân loại thận trọng theo action ID được nhận diện: action thất bại là `Failed`, thao tác đã hoàn thành là `Completed`, action chưa biết hoặc vừa bắt đầu rotation là `Recorded`. Không tự biến dữ liệu thiếu thành thành công. Chỉ số thống kê không bị ảnh hưởng bởi lọc Category/Action/Outcome nhưng tuân theo Time range.

**Không tự gán lần đăng nhập thất bại cho người dùng chỉ từ email do người chưa đăng nhập nhập vào.** Xem Audit toàn hệ thống cần thiết kế phân quyền quản trị riêng; tuyệt đối không lộ sự kiện của người khác trên trang cá nhân.

## Bảo mật và quyền riêng tư

Model từ chối khóa metadata nhạy cảm, presenter còn giới hạn danh sách thuộc tính được hiển thị. Không hiển thị metadata tùy ý, tiêu đề bí mật đã giải mã, khóa mã hóa, token phiên, địa chỉ IP đầy đủ hoặc thông tin xác thực. Request ID và item reference được rút gọn để đối chiếu, không chứng minh được danh tính.

Model AuditEvent cấm sửa bản ghi đã lưu theo Active Record thông thường, nhưng **chưa phải log chống giả mạo bằng mật mã**. Trang này chưa có hash chain, chữ ký, xuất log an toàn, nguồn lưu offsite bất biến, dashboard quản trị toàn hệ thống hoặc cam kết retention. Những cơ chế đó cần được thiết kế và nghiệm thu riêng.

## Kiểm thử

Các test gồm thời gian hợp lệ, cách ly giữa người dùng, loại trừ sự kiện vô danh/toàn hệ thống, phân loại outcome, kết hợp bộ lọc, phân trang, hành vi trình duyệt và metadata an toàn. Cần Rails/Selenium cùng kiểm thử bàn phím/Android thủ công trước khi phát hành. Tham khảo [ma trận kiểm chứng](qualification.vi.md), [mô hình đe dọa](THREAT-MODEL.vi.md), [accessibility](ACCESSIBILITY.vi.md), [production checklist](PRODUCTION-CHECKLIST.vi.md).
