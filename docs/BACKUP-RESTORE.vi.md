# Sao lưu và khôi phục sau sự cố — 1.0.0

> 🌐 Language / Ngôn ngữ: [English](BACKUP-RESTORE.md) | **Tiếng Việt**
## Backup PostgreSQL được mã hóa age

Đặt database URL và người nhận mã hóa `age`, rồi chạy:

```bash
export DATABASE_URL='postgresql://...'
export BACKUP_AGE_RECIPIENT='age1...'
BACKUP_DIR=/secure/backups script/backup-db
```

Tác vụ tạo bản sao lưu `ruby-envelope-vault-<UTC>.dump.age` cùng file `.sha256`.

KEK **không nằm trong backup**. Bản sao KEK phục hồi phải được quản lý độc lập với kho lưu trữ database.

Kiểm tra môi trường triển khai:

```bash
script/ops-check
OPS_REQUIRE_BACKUP_CONFIG=1 OPS_REQUIRE_HTTPS_SMOKE=1 script/ops-check
```

Chế độ nghiêm ngặt yêu cầu `BACKUP_AGE_RECIPIENT` và `APP_URL` từ môi trường vận hành.

Nếu không có BACKUP_AGE_RECIPIENT, script từ chối tạo dump plaintext theo mặc định vì dump vẫn có thông tin tài khoản, hash mật khẩu, ciphertext và audit. Chỉ chủ động sử dụng ALLOW_PLAINTEXT_BACKUP=1 khi có phương án bảo vệ riêng.

## Xác minh backup

Cung cấp `BACKUP_AGE_IDENTITY` để xác minh SHA-256, giải mã và danh mục `pg_restore`:

```bash
BACKUP_AGE_IDENTITY=/secure/recovery.agekey script/verify-backup /secure/backups/ruby-envelope-vault-YYYYMMDDTHHMMSSZ.dump.age
```

**Xác minh backup không thay thế kiểm tra restore và giải mã canary.**

## Phục hồi có kiểm soát

Chỉ phục hồi vào database riêng, tuyệt đối không dùng database nguồn:

```bash
TARGET_DATABASE_URL='postgresql://.../ruby_envelope_vault_dr_test' BACKUP_AGE_IDENTITY=/secure/recovery.agekey script/restore-db /secure/backups/ruby-envelope-vault-YYYYMMDDTHHMMSSZ.dump.age
```

## Nghiệm thu restore và giải mã

Chuẩn bị Vault item giả và chạy:

```bash
TARGET_DATABASE_URL='postgresql://.../ruby_envelope_vault_dr_test' BACKUP_AGE_IDENTITY=/secure/recovery.agekey USER_EMAIL='owner@example.com' ITEM_ID='fake-canary-item-uuid' script/dr-verify /secure/backups/ruby-envelope-vault-YYYYMMDDTHHMMSSZ.dump.age
```

Ứng dụng cần đúng KEK phục hồi. Chỉ khi giải mã canary thành công mới coi phục hồi đạt yêu cầu.

## Diễn tập DR lặp lại được

Chạy diễn tập trên database mới có kiểm soát:

```bash
BACKUP_AGE_IDENTITY=/secure/recovery.agekey USER_EMAIL='owner@example.com' ITEM_ID='fake-canary-item-uuid' EXPECTED_CANARY_FIELD='notes' EXPECTED_CANARY_VALUE='CANARY-FAKE-SECRET-123' script/dr-rehearsal /secure/backups/ruby-envelope-vault-YYYYMMDDTHHMMSSZ.dump.age
```

Script kiểm tra backup, tạo database với tiền tố `ruby_envelope_vault_dr_`, restore, giải mã canary rồi mặc định xóa database diễn tập.

Quy tắc an toàn:

- Database đích bắt buộc có tiền tố DR được cấu hình; từ chối database nguồn.
- Bắt buộc nhập đúng tên trường canary và giá trị mong đợi.
- Quyền tạo/xóa database dùng tài khoản PostgreSQL OS hoặc DR_ADMIN_DATABASE_URL được cấp riêng.
- KEEP_DR_DATABASE=1 chỉ dành cho thao tác điều tra có chủ đích.

## Vận hành và bảo trì theo lịch

`script/ops-report` cung cấp trạng thái cho hệ thống giám sát, không xuất thông tin vận hành qua endpoint HTTP:

```bash
script/ops-report

BACKUP_DIR=/secure/backups BACKUP_AGE_RECIPIENT='age1...' BACKUP_AGE_IDENTITY=/secure/recovery.agekey script/ops-maintenance
```

RUN_DR_REHEARSAL=1 chỉ được sử dụng cùng biến canary giả để thêm diễn tập DR. Báo cáo JSON chỉ nên chứa timestamp, duration, status, tên file/SHA-256 và tình trạng DR/retention.

Retention mặc định dry-run và giữ ít nhất hai backup. Xem trước trước khi áp dụng:

```bash
BACKUP_DIR=/secure/backups RETENTION_KEEP=7 script/backup-retention
BACKUP_DIR=/secure/backups RETENTION_KEEP=7 RETENTION_APPLY=1 script/backup-retention
```

Chỉ bật `RETENTION_APPLY=1` sau khi kiểm tra. Lỗi cleanup phải được báo thất bại.

## Offsite roundtrip

OFFSITE_DRIVER=filesystem và OFFSITE_DEST_DIR chỉ dùng để kiểm tra hành vi trong máy. Kho lưu trữ offsite thực cần OFFSITE_DRIVER=rclone và OFFSITE_RCLONE_DEST trỏ đến remote đã cấu hình.

Dùng filesystem chỉ để kiểm tra cục bộ:

```bash
OFFSITE_DRIVER=filesystem OFFSITE_DEST_DIR=/separate/test/path script/offsite-roundtrip /secure/backups/ruby-envelope-vault-YYYYMMDDTHHMMSSZ.dump.age
```

Với remote rclone đã cấu hình:

```bash
OFFSITE_DRIVER=rclone OFFSITE_RCLONE_DEST='remote:vault-backups' script/offsite-roundtrip /secure/backups/ruby-envelope-vault-YYYYMMDDTHHMMSSZ.dump.age
```

Tác vụ tải lên rồi tải lại backup và sidecar, đối chiếu SHA-256. `REQUIRE_REAL_OFFSITE=1` không chấp nhận filesystem, memory hoặc alias.

## Khôi phục offsite trên host độc lập

Sidecar checksum mới dùng basename, không dùng đường dẫn tuyệt đối từ máy nguồn. script/verify-backup xác minh đúng file do người vận hành cung cấp.

Diễn tập phục hồi từ remote:

```bash
OFFSITE_RCLONE_DEST='remote:vault-backups' BACKUP_AGE_IDENTITY=/secure/recovery.agekey USER_EMAIL='owner@example.com' ITEM_ID='fake-canary-item-uuid' EXPECTED_CANARY_FIELD='notes' EXPECTED_CANARY_VALUE='CANARY-FAKE-SECRET-123' script/offsite-dr-rehearsal ruby-envelope-vault-YYYYMMDDTHHMMSSZ.dump.age
```

Lệnh tải backup/sidecar vào staging mới, kiểm tra dữ liệu, phục hồi database sạch và mặc định xóa staging.

KEEP_OFFSITE_DR_STAGE=1 chỉ dành cho kiểm tra chủ động. Không dùng remote local/memory/alias làm bằng chứng phục hồi offsite thực tế.

## Phân biệt source release và production

Bài kiểm thử synthetic trong notebook không chứng minh host production đã được nghiệm thu. Mọi lần triển khai thực cần chứng minh độc lập quyền KEK, TLS, backup, offsite và giải mã canary; xem [checklist production](PRODUCTION-CHECKLIST.vi.md).
