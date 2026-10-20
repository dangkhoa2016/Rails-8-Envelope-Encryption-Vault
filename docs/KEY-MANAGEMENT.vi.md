# Quản lý khóa — 1.0.0

> 🌐 Language / Ngôn ngữ: [English](KEY-MANAGEMENT.md) | **Tiếng Việt**
Mỗi phiên bản bí mật bất biến có DEK 32 byte mới. Payload được mã hóa AES-256-GCM; DEK được bọc bởi KEK riêng thông qua KeyProvider. Nhà cung cấp mặc định là local_file; có thêm AWS KMS.

**Không** dùng RAILS_MASTER_KEY, SECRET_KEY_BASE, mật khẩu database hoặc mật khẩu người dùng làm Vault KEK. KEK 32 byte phải nằm ngoài PostgreSQL và Git.

## Tạo và xác minh

Tạo khóa bằng tác vụ bin/rails vault:keys:generate với ID rõ ràng và VAULT_KEK_DIR trỏ tới thư mục an toàn. Tác vụ tạo file mới theo quyền 0600, không ghi đè, không in byte khóa. Xác minh bằng bin/rails vault:keys:verify sau khi đặt VAULT_ACTIVE_KEK_ID và VAULT_KEK_DIR.

## Luân chuyển / bọc lại DEK

Tạo KEK đích trước. Chạy bin/rails vault:keys:rotate với FROM, TO và DRY_RUN=1 để kiểm tra thử, sau đó mới thực thi khi đã có quyền vận hành.

Với mỗi phiên bản vault hoặc MFA seed thuộc khóa cũ, tác vụ giải bọc DEK bằng FROM, bọc lại cùng DEK bằng TO cùng nonce mới, rồi giải bọc và so sánh constant-time. Nó chỉ thay wrapped_dek và kek_id; ciphertext, nonce, authentication tag của payload giữ nguyên.

Khóa cũ chuyển sang decrypt_only, không tự bị xóa.

## Quy tắc phục hồi

Giữ bản sao KEK ngoại tuyến độc lập cho mọi KEK vẫn cần để giải mã bản sao lưu. PostgreSQL dump đơn lẻ không đủ để giải mã bí mật.

Chỉ cân nhắc ngừng sử dụng khóa cũ sau khi backup mới được phục hồi vào database sạch và canary giả được giải mã thành công.

## Kiểm tra khả năng lưu giữ khóa phục hồi

Chạy script/kek-recovery-check với RECOVERY_KEK_DIR trỏ tới thư mục độc lập. Script so sánh danh sách KEK đang được tham chiếu, fingerprint của bản sao 32 byte và quyền 0400/0600.

Thư mục khác trên cùng máy chỉ có giá trị kiểm thử. Production cần lưu giữ độc lập về vật lý hoặc quyền quản trị.
