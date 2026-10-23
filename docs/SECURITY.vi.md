# Chính sách bảo mật — 1.0.0

> 🌐 Language / Ngôn ngữ: [English](SECURITY.md) | **Tiếng Việt**
## Phạm vi hỗ trợ

**1.0.0** là bản công bố mã nguồn đầu tiên. Kiểm thử ở môi trường độc lập không đảm bảo an toàn cho một bản cài đặt production.

## Báo cáo lỗ hổng

Gửi báo cáo riêng tư tới **Đăng Khoa** qua địa chỉ i.am@dangkhoa.dev, kèm ví dụ tái hiện bằng dữ liệu giả. Không công khai token, mật khẩu, KEK, mã khôi phục, cookie, URL database hoặc dữ liệu vault thật trên GitHub.

## Mô hình bảo mật

- Mỗi phiên bản bí mật dùng AES-256-GCM và DEK riêng, có cơ chế kiểm tra toàn vẹn.
- KEK được lưu bên ngoài PostgreSQL và Git.
- MFA, xác thực lại, rate limit, thu hồi session và audit log bổ sung cho lớp mã hóa.
- Hệ thống mã hóa phía máy chủ, **không phải zero knowledge**. Một Rails host bị chiếm quyền và có quyền giải mã vẫn có thể truy xuất bí mật.

## Trước khi chạy production

Phải xác minh TLS, lưu KEK độc lập, backup offsite, phục hồi canary và cảnh báo vận hành. Xem [checklist production](PRODUCTION-CHECKLIST.vi.md), [mô hình đe dọa](THREAT-MODEL.vi.md) và [Ma trận kiểm chứng](qualification.vi.md).
