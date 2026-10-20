# Mô hình đe dọa — 1.0.0

> 🌐 Language / Ngôn ngữ: [English](THREAT-MODEL.md) | **Tiếng Việt**
## Tài sản được bảo vệ

Bí mật plaintext, biến môi trường, DEK, KEK cục bộ/cloud, mật khẩu, session, TOTP seed, recovery code, database mã hóa và các bản sao lưu.

## Ranh giới tin cậy

Trình duyệt → HTTPS/reverse proxy → Rails/Puma → PostgreSQL. Rails truy cập KeyProvider hoặc KEK file qua ranh giới riêng. Nơi giữ backup ngoại tuyến và nơi giữ KEK phục hồi phải độc lập.

## Những tình huống được giảm thiểu rủi ro

- Chỉ bị đọc database hoặc bị đánh cắp pg_dump mà không có KEK.
- Thay đổi ciphertext, tag, nonce, AAD hoặc tráo dữ liệu giữa các bản ghi.
- Session bị đánh cắp tồn tại lâu hơn giới hạn hết hạn.
- Tấn công dò mật khẩu tập trung nhờ rate limit.
- Chiếm tài khoản bằng mật khẩu đơn lẻ khi MFA đã bật.
- Đọc TOTP seed ở trạng thái plaintext trong database hoặc recovery code chưa băm.

## Rủi ro còn lại

Đây **không phải zero knowledge**. Kẻ tấn công kiểm soát toàn bộ Rails host và có quyền KeyProvider có thể giải mã dữ liệu. Dự án không đảm bảo chống máy người dùng bị xâm nhập, keylogger, extension độc hại, Rails process bị thay mã, đồng thời chiếm database và KEK, hoặc quản trị viên có quyền truy cập tiến trình.

## Bất biến mã hóa

- AES-256-GCM, DEK ngẫu nhiên 32 byte cho từng version.
- Nonce mã hóa 12 byte, tag xác thực 16 byte.
- AAD liên kết user/item/version; chỉ lưu DEK đã bọc.
- KEK ở ngoài database và Git; luân chuyển KEK chỉ bọc lại DEK.
- TOTP seed dùng cơ chế envelope; recovery code dùng bcrypt một chiều.

## Bất biến vận hành

Không mở đăng ký production trừ khi demo dữ liệu giả được cho phép. Khuyến nghị MFA, xác thực lại khi tiết lộ/xuất secret, HTTPS và host authorization. Backup không được xem là phục hồi được nếu chưa restore và giải mã canary.
