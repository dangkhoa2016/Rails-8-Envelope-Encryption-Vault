# Khắc phục sự cố — v1.0.0

> 🌐 Language / Ngôn ngữ: [English](troubleshooting.md) | **Tiếng Việt**

## Nguyên tắc chẩn đoán

Trước hết xác định môi trường (CI, development, Kaggle/Colab hay ứng viên production), SHA nguồn, phiên bản Ruby và **lỗi đầu tiên thực sự xuất hiện**. Không sửa quá nhiều biến cùng lúc. Không gửi nội dung `.env`, database URL có mật khẩu, KEK, AWS token hoặc dữ liệu vault đã giải mã.

## Sự cố thường gặp

| Triệu chứng | Vùng cần kiểm tra | Bước đầu an toàn |
| --- | --- | --- |
| Ruby/Bundler không khớp | `.ruby-version`, Bundler, native gems | `ruby -v`; `bundle check` |
| Không kết nối PostgreSQL | Process, socket/port, `DATABASE_URL` | `./bootstrap.sh status` trên notebook; `pg_isready` trên host |
| Lỗi Rails migration | Sai DB/environment hoặc thiếu quyền | `bin/rails db:prepare` **chỉ trên DB dùng thử** |
| Không truy cập được KEK/provider | `VAULT_KEY_PROVIDER`, KEK ID/dir, IAM KMS | `script/key-provider-status`; [Quản lý khóa](KEY-MANAGEMENT.vi.md) |
| Giải mã/xác thực thất bại | KEK, ngữ cảnh AAD hoặc envelope bị sửa | Ngừng ghi; giữ backup; kiểm tra mapping version/khóa |
| Không đăng nhập được | Owner chưa tạo, MFA, mật khẩu hoặc policy | Kiểm tra tạo owner và policy, không in mật khẩu |
| Rails chặn CSRF/host | Proxy, danh sách host, origin | Kiểm tra tên miền thật và proxy settings |
| Giao diện/asset lỗi | Asset build, Rails environment, proxy path | `./bootstrap.sh doctor` hoặc tiền kiểm asset |
| Kiểm tra backup lỗi | File không đủ, checksum sai hoặc age identity | `script/verify-backup` trên **bản sao** |
| DR rehearsal bị từ chối | Chốt tên DB mới và quyền create/drop | Xem [Backup/restore](BACKUP-RESTORE.vi.md) |
| CI xanh, production vẫn lỗi | Cấu hình/host nằm ngoài kiểm thử CI | [Qualification](qualification.vi.md), [Deployment](deployment.vi.md) |

## Quy trình xử lý từng bước

1. **Giữ bằng chứng.** Ghi SHA, thời gian UTC, môi trường, thông báo lỗi đã che bí mật.
2. **Khoanh vùng.** Lỗi cài đặt, xác thực, mật mã, storage, network hay recovery?
3. **Chạy kiểm tra không phá dữ liệu.** Dùng `./bootstrap.sh status`, `./bootstrap.sh doctor` hoặc `script/ops-check` trong môi trường phù hợp.
4. **Kiểm tra sự tồn tại của cấu hình**, không in giá trị nhạy cảm. Xác minh tên biến, quyền file, ID khóa mà không đọc key bytes ra log.
5. **Tái hiện với dữ liệu giả** trên database và thư mục KEK phát triển tách biệt.
6. **Thu log đã che bí mật**, mã thoát lệnh và so sánh SHA còn hoạt động / SHA bị lỗi.
7. **Báo cáo đúng kênh.** Nếu nghi lộ khóa hoặc bypass quyền, đọc [chính sách bảo mật riêng tư](SECURITY.vi.md).

## Khôi phục notebook sau restart

Kaggle/Colab có thể restart bất ngờ. Bootstrap để runtime ngoài Git, trong `/kaggle/working` hoặc `/content` nếu có. Nếu filesystem vẫn còn, vào repository rồi chạy:

```bash
source ./activate-runtime.sh
./bootstrap.sh status
./bootstrap.sh doctor
```

Nếu runtime đã bị xóa thì cần provision lại bằng dữ liệu **giả**. Container mới không tự lấy lại database mã hóa hoặc KEK cũ; phải dùng backup và quy trình phục hồi đã kiểm chứng, không tạo khóa mới để giải mã ciphertext cũ.

## An toàn khi recovery và xoay khóa

- DEK đã bọc cần đúng KEK lịch sử. **Không** xóa KEK cũ chỉ vì đã có KEK active mới.
- `script/verify-backup` chỉ chứng minh tính toàn vẹn wrapper/metadata; DR đầy đủ cần restore DB mới **và giải mã canary**.
- Không trỏ lệnh restore vào database nguồn production hoặc tắt chốt tên database mới để ép test PASS.
- Khi AES-GCM authentication lỗi, cần phân tích context, khả năng chỉnh sửa dữ liệu và mapping khóa; không bỏ qua exception.

## Tài liệu hữu ích

[Notebook setup](KAGGLE-SETUP.vi.md) · [Quản lý khóa](KEY-MANAGEMENT.vi.md) · [Sao lưu và phục hồi](BACKUP-RESTORE.vi.md) · [Tái lập](reproducibility.vi.md) · [Chính sách bảo mật](SECURITY.vi.md)

Khi báo bug, cung cấp thông báo lỗi đầu tiên đã che bí mật, bước tái hiện với dữ liệu giả, lệnh ảnh hưởng và commit SHA.
