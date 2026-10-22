# Quản lý khóa — 1.0.0

> 🌐 Language / Ngôn ngữ: [English](KEY-MANAGEMENT.md) | **Tiếng Việt**
Mỗi phiên bản bí mật bất biến có DEK 32 byte mới. Payload được mã hóa AES-256-GCM; DEK được bọc bởi KEK riêng thông qua KeyProvider. Nhà cung cấp mặc định là local_file; có thêm AWS KMS.

**Không** dùng RAILS_MASTER_KEY, SECRET_KEY_BASE, mật khẩu database hoặc mật khẩu người dùng làm Vault KEK. KEK 32 byte phải nằm ngoài PostgreSQL và Git.

## Tạo khóa

Tạo KEK 32 byte trong thư mục được bảo vệ:

```bash
VAULT_KEK_DIR=/secure/vault/keks bin/rails vault:keys:generate ID=kek-2026-01
```

Tác vụ dùng quyền 0600, từ chối ghi đè và chỉ xuất ID, đường dẫn, fingerprint — không in byte khóa.

## Xác minh

```bash
VAULT_ACTIVE_KEK_ID=kek-2026-01 VAULT_KEK_DIR=/secure/vault/keks bin/rails vault:keys:verify
```

## Luân chuyển / bọc lại DEK

Tạo KEK đích trước, sau đó chạy thử:

```bash
VAULT_ACTIVE_KEK_ID=kek-2027-01 bin/rails vault:keys:rotate FROM=kek-2026-01 TO=kek-2027-01 DRY_RUN=1
```

Khi đã xác nhận bản sao khóa và phương án phục hồi:

```bash
VAULT_ACTIVE_KEK_ID=kek-2027-01 bin/rails vault:keys:rotate FROM=kek-2026-01 TO=kek-2027-01
```

Với mỗi phiên bản vault hoặc MFA seed thuộc khóa cũ, tác vụ giải bọc DEK bằng FROM, bọc lại cùng DEK bằng TO cùng nonce mới, rồi giải bọc và so sánh constant-time. Nó chỉ thay wrapped_dek và kek_id; ciphertext, nonce, authentication tag của payload giữ nguyên.

Khóa cũ chuyển sang decrypt_only, không tự bị xóa.

## Quy tắc phục hồi

Giữ bản sao KEK ngoại tuyến độc lập cho mọi KEK vẫn cần để giải mã bản sao lưu. PostgreSQL dump đơn lẻ không đủ để giải mã bí mật.

Chỉ cân nhắc ngừng sử dụng khóa cũ sau khi backup mới được phục hồi vào database sạch và canary giả được giải mã thành công.

## Kiểm tra khả năng lưu giữ khóa phục hồi

Xác minh bản sao KEK độc lập:

```bash
RECOVERY_KEK_DIR=/independent/recovery/keks script/kek-recovery-check
```

Script đối chiếu KEK đang được phiên bản Vault và MFA tham chiếu, fingerprint bản sao 32 byte cùng quyền 0400/0600.

Thư mục khác trên cùng máy chỉ có giá trị kiểm thử. Production cần lưu giữ độc lập về vật lý hoặc quyền quản trị.
