# Tổng quan kỹ thuật — v1.0.0

> 🌐 Language / Ngôn ngữ: [English](engineering-overview.md) | **Tiếng Việt**

## Mục tiêu và những điều không cam kết

Ruby Envelope Vault là ứng dụng Rails tự lưu trữ, minh họa cách bảo vệ bí mật do ứng dụng quản lý bằng mã hóa phong bì **phía máy chủ**. Dự án giúp kiểm tra đồng thời mã nguồn, ranh giới quản lý khóa, kiểm thử và phục hồi thảm họa; **không** tuyên bố zero-knowledge, chứng nhận bảo mật, high availability hay nghiệm thu vận hành production.

Ứng dụng quản lý thông tin đăng nhập, API key, biến môi trường, kết nối database, ghi chú riêng tư, tài khoản server/SSH và bí mật tùy chỉnh. Rails có thể giải mã cho người dùng hợp lệ: cơ chế này giảm tác động của việc **chỉ lộ database**, không bảo vệ trước trường hợp máy chủ Rails cùng quyền truy cập KEK bị chiếm hoàn toàn.

## Trách nhiệm các thành phần

| Thành phần | Vị trí mã nguồn | Trách nhiệm và ranh giới |
| --- | --- | --- |
| Giao diện và điều khiển Rails | `app/controllers/`, `app/views/` | Xác thực, MFA, thao tác vault theo chủ sở hữu, cài đặt, audit |
| Bản ghi lâu dài | `app/models/`, `db/` | Metadata, phiên bản bất biến, ciphertext, DEK đã bọc |
| Mật mã | `app/services/crypto/` | DEK/nonce mới cho mỗi phiên bản, AES-256-GCM, AAD |
| Nhà cung cấp khóa | `app/services/key_providers/` | Bọc/giải bọc DEK bằng KEK cục bộ hoặc AWS KMS |
| Nghiệp vụ vault | `app/services/vault/` | Tạo, sửa, reveal, liệt kê, khôi phục và bọc lại DEK |
| Bảo vệ tài khoản | `app/services/mfa/`, `app/services/security/` | TOTP, yếu tố phục hồi và xác minh liên quan |
| Vận hành | `script/`, `ops/` | Backup, xác minh, restore có kiểm soát, tiền kiểm và lịch chạy |
| Chất lượng | `test/`, `.github/workflows/` | Test, kiểm tra tĩnh, Ruby và Docker |

### Luồng yêu cầu và ghi dữ liệu

1. Request đã xác thực đi tới controller Rails tương ứng.
2. Controller kiểm tra quyền và yêu cầu xác thực lại cho các hành động nhạy cảm.
3. Dịch vụ vault dựng payload, ngữ cảnh gồm định danh người dùng, item và phiên bản.
4. Envelope encryptor tạo DEK 256-bit và nonce GCM 96-bit mới; AES-256-GCM mã hóa payload; provider được chọn bọc DEK.
5. PostgreSQL lưu phiên bản đã mã hóa và metadata được phép, **không** chứa KEK dạng plaintext.
6. Reveal chỉ thành công nếu được cấp quyền, giải bọc DEK thành công và xác thực ciphertext hợp lệ; lỗi không được làm lộ khóa hay plaintext.

`Vault::RestoreVersion` giải mã phiên bản cũ có quyền truy cập rồi gọi `Vault::UpdateItem` tạo **phiên bản hiện hành mới**; không sửa lại ciphertext lịch sử trong quá trình restore thông thường.

## Ranh giới dữ liệu và tin cậy

```text
Trình duyệt ─ HTTPS ─ Rails/Puma ── dịch vụ Vault đã xác thực
                         │                  │
                         │                  ├─ AES-256-GCM (payload)
                         │                  └─ KeyProvider ─ kho KEK riêng
                         └─ PostgreSQL ─ ciphertext + DEK bọc + metadata

Backup: PostgreSQL → archive mã hóa age → lưu trữ độc lập
Restore: archive tải lại + age identity riêng + KEK liên quan
         → database mới có kiểm soát → giải mã canary giả
```

HTTPS, lưu trữ và ranh giới KEK trong sơ đồ mô tả **triển khai đúng cấu hình**. Checkout mã nguồn hoặc CI xanh chưa biến các điều kiện này thành hệ thống production thực tế.

## Các quyết định kỹ thuật chính

- **Khóa theo phiên bản:** Lộ một DEK không nhất thiết làm lộ toàn bộ phiên bản; KEK vẫn là tài sản bảo mật quan trọng.
- **Ngữ cảnh xác thực:** AAD gắn payload vào người dùng/item/version; di chuyển sang ngữ cảnh khác phải bị từ chối xác thực.
- **Metadata không hoàn toàn bí mật:** Tiêu đề, loại, thời gian và audit metadata vẫn cần kiểm soát truy cập database.
- **Xoay khóa:** Có thể bọc lại DEK bằng KEK mới mà không đổi ciphertext AES-GCM. Các backup cũ vẫn cần khả năng truy cập KEK lịch sử.
- **Phục hồi:** Có checksum và giải mã được archive chưa đủ; cần restore vào database mới và giải mã canary giả.
- **Giới hạn bằng chứng:** Unit/system test và CI xác minh mã nguồn chứ không chứng nhận an toàn cho một máy chủ production cụ thể.

## Hướng đọc cho người review

Bắt đầu từ [Kiến trúc](ARCHITECTURE.vi.md), [Mô hình đe dọa](THREAT-MODEL.vi.md), [Quản lý khóa](KEY-MANAGEMENT.vi.md), [Tái lập](reproducibility.vi.md), [Ma trận kiểm chứng](qualification.vi.md) và [Bằng chứng](evidence-index.vi.md). Trước khi vận hành thực tế, hoàn thành [Checklist production](PRODUCTION-CHECKLIST.vi.md).

Đây là **hợp đồng thiết kế**; hành vi runtime cần đối chiếu trực tiếp với mã nguồn.
