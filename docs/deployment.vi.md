# Triển khai và nghiệm thu vận hành — v1.0.0

> 🌐 Language / Ngôn ngữ: [English](deployment.md) | **Tiếng Việt**

## Phát hành mã nguồn khác với triển khai

Tag `v1.0.0` định danh mã nguồn, **không có nghĩa được phép lưu bí mật thật trên Internet**. Mỗi môi trường cần xây dựng và kiểm tra TLS, quản lý khóa, backup, phục hồi, chính sách tài khoản và bảo trì riêng.

## Tách biệt môi trường

| Môi trường | Mục đích | Quy định dữ liệu và khóa |
| --- | --- | --- |
| Development | Viết code, UI, debugging | Bí mật giả và KEK dùng thử có thể thay thế |
| CI/test | Kiểm thử Rails/system/security lặp lại | Database tạm và KEK test mới |
| Notebook demo | Thử trên Kaggle/Colab | Dữ liệu giả, giả định runtime có thể biến mất |
| Triển khai tự quản | Hạ tầng do người vận hành quản lý | HTTPS, quản lý KEK và phục hồi age độc lập, xác minh theo môi trường |

`../ops/production.env.example` và `../config/deploy.yml` chỉ là **template có placeholder**, không phải credential sẵn dùng hay kiến trúc production đã phê duyệt.

## Trước khi provision

1. Ghim SHA/tag đã review, Ruby runtime và PostgreSQL 17.
2. Tạo danh tính database riêng; hạn chế quyền storage và backup.
3. Chọn chủ động provider `local_file` hoặc AWS KMS; ghi rõ bên giữ KEK phục hồi, tách quyền quản trị database.
4. Chuẩn bị TLS public, reverse proxy, Rails hosts/origin/CSRF đúng thực tế.
5. Quy định đăng ký tài khoản, MFA, reauthentication, hết hạn session, rate limit.
6. Có log, monitoring, cảnh báo, cập nhật bảo mật và phương án rollback đã kiểm tra.
7. Lập lịch backup database **mã hóa bằng age** và kiểm tra truy xuất từ offsite độc lập.
8. Đảm bảo KEK, recovery identity, credential thật không nằm trong mã nguồn.

## Triển khai và xác minh

Sử dụng script phù hợp hạ tầng; không copy nguyên file ví dụ vào production. Đọc kỹ `script/production-*`, `script/ops-*` và `script/live-host-acceptance` trước khi chạy trên máy thật.

Tối thiểu phải xác minh:

- Rails khởi động đúng môi trường và truy cập đúng database.
- KeyProvider giải mã được **canary giả** với KEK ID dự kiến.
- TLS, host authorization, origin và chống giả mạo request hoạt động đúng qua reverse proxy thật.
- Đăng nhập, MFA, xác thực lại, thu hồi session và reveal có quyền hoạt động với người dùng giả.
- Error/audit logs không in secret, mật khẩu, KEK hoặc recovery identity.
- Lịch backup và vận hành dùng quyền tối thiểu, báo lỗi rõ ràng.

Lệnh chẩn đoán sơ bộ không thay đổi dữ liệu (sau khi load biến môi trường bảo vệ):

```bash
script/ops-check

# Chốt kiểm tra nghiêm ngặt khi đã cấu hình đủ tính năng:
OPS_REQUIRE_BACKUP_CONFIG=1 OPS_REQUIRE_HTTPS_SMOKE=1 script/ops-check
```

Các lệnh này chỉ kiểm tra cấu hình cục bộ; cần xác minh thêm HTTPS, đăng nhập và phục hồi trên môi trường triển khai thực tế. Xem tham số yêu cầu của từng script trước khi chạy.

## Nghiệm thu phục hồi thảm họa

1. Tạo backup PostgreSQL đã mã hóa age bằng `script/backup-db`.
2. Lưu checksum và tải archive **từ nơi offsite** về một cách độc lập.
3. Kiểm tra archive bằng `script/verify-backup`.
4. Phục hồi age identity và các KEK cần thiết **từ những nơi lưu giữ độc lập**.
5. Restore vào database mới được bảo vệ bằng `script/restore-db` hoặc orchestrator.
6. Giải mã canary giả với `script/dr-verify` / `script/dr-rehearsal`.
7. Đảm bảo database nguồn không bị thay đổi, lưu lại bằng chứng đã che dữ liệu nhạy cảm.

**Checksum PASS không phải DR PASS.** Đọc [Sao lưu và phục hồi](BACKUP-RESTORE.vi.md) để biết tham số và giới hạn an toàn.

## Kiểm tra trước khi sử dụng production

| Điều kiện | Bằng chứng bắt buộc |
| --- | --- |
| Tài khoản | Đăng nhập giả, MFA, vòng đời session |
| Mật mã | KEK unwrap và reveal canary trên máy thực |
| Vận chuyển | HTTPS, proxy header và Rails host/origin |
| Lưu trữ | PostgreSQL phân quyền và nơi chứa backup mã hóa |
| Phục hồi | Archive tải từ offsite → DB mới → giải mã canary |
| Theo dõi | Cảnh báo, lịch chạy, che log và xử lý lỗi |
| Accessibility | Review keyboard, focus, contrast, screen reader, cảm ứng |
| Vận hành | SHA, thông tin host và phương án rollback hoặc phục hồi |

Không tuyên bố production PASS trước khi có đủ bằng chứng cho chính máy đó. Khi mã nguồn, khóa, backup hoặc hạ tầng thay đổi, phải đánh giá lại biện pháp liên quan.

## Tài liệu liên quan

[Checklist production](PRODUCTION-CHECKLIST.vi.md) · [Bảo mật](SECURITY.vi.md) · [Quản lý khóa](KEY-MANAGEMENT.vi.md) · [Ma trận kiểm chứng](qualification.vi.md) · [Xử lý lỗi](troubleshooting.vi.md)
