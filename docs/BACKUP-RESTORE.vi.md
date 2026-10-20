# Sao lưu và khôi phục sau sự cố — 1.0.0

> 🌐 Language / Ngôn ngữ: [English](BACKUP-RESTORE.md) | **Tiếng Việt**
## Backup PostgreSQL được mã hóa age

Cấu hình DATABASE_URL, BACKUP_AGE_RECIPIENT (age recipient) và BACKUP_DIR tại môi trường riêng, sau đó chạy script/backup-db. Lệnh tạo file database có phần mở rộng .dump.age và sidecar .sha256.

KEK **không nằm trong backup**. Bản sao KEK phục hồi phải được quản lý độc lập với kho lưu trữ database.

Để kiểm tra môi trường triển khai, chạy script/ops-check. Chế độ nghiêm ngặt sử dụng OPS_REQUIRE_BACKUP_CONFIG=1 và OPS_REQUIRE_HTTPS_SMOKE=1; APP_URL và age recipient được truyền bằng biến môi trường, không in giá trị nhạy cảm.

Nếu không có BACKUP_AGE_RECIPIENT, script từ chối tạo dump plaintext theo mặc định vì dump vẫn có thông tin tài khoản, hash mật khẩu, ciphertext và audit. Chỉ chủ động sử dụng ALLOW_PLAINTEXT_BACKUP=1 khi có phương án bảo vệ riêng.

## Xác minh backup

Dùng BACKUP_AGE_IDENTITY trỏ tới recovery identity và chạy script/verify-backup với file .dump.age. Script kiểm tra SHA-256, khả năng giải mã và danh sách mục pg_restore. **Đây chưa phải DR PASS.**

## Phục hồi có kiểm soát

Đặt TARGET_DATABASE_URL tới một database thử nghiệm riêng và BACKUP_AGE_IDENTITY, sau đó gọi script/restore-db với file backup. Không dùng database nguồn làm đích.

## Nghiệm thu restore và giải mã

Chuẩn bị một vault item **giả** đã biết, USER_EMAIL, ITEM_ID, BACKUP_AGE_IDENTITY và TARGET_DATABASE_URL; chạy script/dr-verify. Ứng dụng phải có đúng KEK phục hồi tương ứng. Chỉ khi giải mã canary thành công mới đánh dấu recovery PASS.

## Diễn tập DR lặp lại được

script/dr-rehearsal nhận BACKUP_AGE_IDENTITY, USER_EMAIL, ITEM_ID, EXPECTED_CANARY_FIELD và EXPECTED_CANARY_VALUE. Script xác minh backup, tạo database mới có tiền tố ruby_envelope_vault_dr_, restore, kiểm tra decrypt và mặc định xóa database diễn tập.

Quy tắc an toàn:

- Database đích bắt buộc có tiền tố DR được cấu hình; từ chối database nguồn.
- Bắt buộc nhập đúng tên trường canary và giá trị mong đợi.
- Quyền tạo/xóa database dùng tài khoản PostgreSQL OS hoặc DR_ADMIN_DATABASE_URL được cấp riêng.
- KEEP_DR_DATABASE=1 chỉ dành cho thao tác điều tra có chủ đích.

## Vận hành và bảo trì theo lịch

script/ops-report xuất báo cáo máy đọc được, tránh lộ chi tiết qua endpoint HTTP. script/ops-maintenance có thể tạo backup age và xác minh checksum/catalog.

RUN_DR_REHEARSAL=1 chỉ được sử dụng cùng biến canary giả để thêm diễn tập DR. Báo cáo JSON chỉ nên chứa timestamp, duration, status, tên file/SHA-256 và tình trạng DR/retention.

Retention mặc định chạy dry-run, giữ ít nhất hai bản sao. Xem trước bằng script/backup-retention với BACKUP_DIR và RETENTION_KEEP; chỉ khi đã duyệt mới đặt RETENTION_APPLY=1. Lỗi cleanup là lỗi nghiêm trọng, không được báo PASS.

## Offsite roundtrip

OFFSITE_DRIVER=filesystem và OFFSITE_DEST_DIR chỉ dùng để kiểm tra hành vi trong máy. Kho lưu trữ offsite thực cần OFFSITE_DRIVER=rclone và OFFSITE_RCLONE_DEST trỏ đến remote đã cấu hình.

script/offsite-roundtrip tải lên backup age và sidecar checksum, tải về cả hai và đối chiếu SHA-256. REQUIRE_REAL_OFFSITE=1 không chấp nhận filesystem, memory hoặc alias.

## Khôi phục offsite trên host độc lập

Sidecar checksum mới dùng basename, không dùng đường dẫn tuyệt đối từ máy nguồn. script/verify-backup xác minh đúng file do người vận hành cung cấp.

Chạy script/offsite-dr-rehearsal với OFFSITE_RCLONE_DEST, BACKUP_AGE_IDENTITY, USER_EMAIL, ITEM_ID, EXPECTED_CANARY_FIELD và EXPECTED_CANARY_VALUE. Lệnh tải từ rclone vào staging mới, xác minh byte, chạy diễn tập database sạch rồi xóa staging theo mặc định.

KEEP_OFFSITE_DR_STAGE=1 chỉ dành cho kiểm tra chủ động. Không dùng remote local/memory/alias làm bằng chứng phục hồi offsite thực tế.

## Phân biệt source release và production

Bài kiểm thử synthetic trong notebook không chứng minh host production đã được nghiệm thu. Mọi lần triển khai thực cần chứng minh độc lập quyền KEK, TLS, backup, offsite và giải mã canary; xem [checklist production](PRODUCTION-CHECKLIST.vi.md).
