# Danh sách kiểm tra bảo mật production — 1.0.0

> 🌐 Language / Ngôn ngữ: [English](PRODUCTION-CHECKLIST.md) | **Tiếng Việt**
**Trước khi lưu bí mật thật trên máy chủ kết nối Internet, mọi hạng mục liên quan phải PASS.**

## Mã nguồn và môi trường

- [ ] Ruby, Bundler và Gemfile.lock tương thích; chạy bundle install thành công.
- [ ] PostgreSQL 17 và bin/rails db:prepare thành công.
- [ ] Rails tests, script/crypto-self-test, script/security-self-test, Brakeman, bundler-audit và Docker cold build PASS.
- [ ] APP_HOSTS chỉ chứa hostname hợp lệ; FORCE_SSL=true; script/production-smoke PASS qua HTTPS thật.
- [ ] ALLOW_SIGNUPS=false, DEMO_MODE=false, REQUIRE_MFA=true, REAUTH_ON_REVEAL=true.
- [ ] Owner đăng ký TOTP và giữ recovery code ngoại tuyến.

## Khóa và dữ liệu

- [ ] KEK đúng 32 byte, quyền 0600/0400, lưu ngoài Git/database; tiến trình ứng dụng đọc được mà không mở quyền thế giới.
- [ ] Có bản sao KEK phục hồi độc lập cho mọi backup còn sử dụng; bin/rails vault:keys:verify PASS.
- [ ] Tạo canary giả và chạy script/prove-no-plaintext thành công.
- [ ] Thử luân chuyển KEK ở dry-run rồi rewrap thực tế trước khi ngừng sử dụng KEK cũ.

## Sao lưu và phục hồi

- [ ] Backup PostgreSQL mã hóa age, checksum hợp lệ và không chứa KEK.
- [ ] script/dr-rehearsal xác minh, phục hồi vào database sạch, giải mã đúng canary và dọn database tạm.
- [ ] script/ops-check và chế độ yêu cầu backup/HTTPS nghiêm ngặt PASS.
- [ ] script/ops-report được giám sát nội bộ, không tiết lộ chi tiết nhạy cảm qua endpoint readiness.
- [ ] script/ops-maintenance hoặc tác vụ tương đương được lên lịch; retention chạy dry-run trước khi áp dụng.
- [ ] Giữ tối thiểu hai backup; lỗi checksum, decrypt, canary hoặc cleanup là lỗi nghiêm trọng.

## Offsite và scheduler

- [ ] script/offsite-roundtrip dùng remote rclone thực, tải lên rồi tải lại và xác minh SHA-256.
- [ ] Không coi local/memory/alias là offsite thực.
- [ ] script/offsite-dr-rehearsal phục hồi backup tải từ remote vào database mới, đối chiếu canary, xóa staging.
- [ ] Scheduler systemd/cron chạy script/scheduled-ops daily và dr theo lịch.
- [ ] OPS_STATE_DIR, OPS_EVIDENCE_DIR, age identity và RCLONE_CONFIG có quyền hạn chế, nằm ngoài Git.
- [ ] script/ops-scheduler-doctor PASS; thử báo động bằng lỗi giả có kiểm soát.
- [ ] Kiểm tra session hết hạn, rotation session ID, xác thực lại và MFA trên host thực.

## Giới hạn nghiệm thu

Quick Tunnel hoặc môi trường Kaggle chỉ phù hợp cho thử nghiệm HTTP, không đủ làm bằng chứng host production. Luôn yêu cầu bảo vệ KEK độc lập và lần khôi phục decrypt thành công trước khi đánh dấu production PASS.
