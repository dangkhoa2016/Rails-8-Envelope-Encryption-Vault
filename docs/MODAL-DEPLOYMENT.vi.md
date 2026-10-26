# Triển khai Modal: demo công khai và vault riêng tư

> 🌐 Language / Ngôn ngữ: [English](MODAL-DEPLOYMENT.md) | **Tiếng Việt**

Tài liệu này mô tả **ứng viên triển khai từ nhánh phát triển**, không khẳng định hệ thống cá nhân đã nghiệm thu production/DR. Cả hai cùng chạy Rails với `RAILS_ENV=production`, nhưng phải tách Modal Environment, App, Secret, tài khoản PostgreSQL và khóa mã hóa.

## Hai chế độ

| Chính sách | Demo công khai | Vault riêng tư |
| --- | --- | --- |
| Chọn chế độ | `REVAULT_MODAL_MODE=demo` | `REVAULT_MODAL_MODE=private` |
| Modal Environment | `rails-8-envelope-encryption-vault` | `ruby-envelope-private` |
| Modal App | `vault-demo` | `ruby-envelope-vault-private` |
| `PRODUCTION_POSTGRES_URL` | Không được có | Bắt buộc |
| Database | PostgreSQL khởi động trong container | PostgreSQL bên ngoài do chủ sở hữu cung cấp, kết nối TLS |
| Container restart/cold start | Có thể mất toàn bộ dữ liệu | Database ngoài vẫn giữ dữ liệu |
| Fixture | Chỉ `demo:fixture` dữ liệu giả | Không bao giờ tự thêm demo fixture |
| Tài khoản | Demo dùng chung, không cho đăng ký, có thể bỏ MFA | Chủ sở hữu riêng, không cho đăng ký, bắt buộc MFA |
| KEK | Secret chỉ dành cho demo | Secret riêng và bản phục hồi độc lập |

Nếu private thiếu URL, chương trình **từ chối khởi động**, không tự tạo PostgreSQL tạm. Demo nếu nhận URL bên ngoài cũng **từ chối khởi động**, phòng trường hợp kết nối nhầm database cá nhân. Mỗi App `max_containers=1`. PostgreSQL local chỉ nghe `127.0.0.1`; demo không dùng Modal Volume, không tạo snapshot lưu trữ và không bảo đảm dữ liệu qua cold start. `min_containers=0` cho phép scale-to-zero.

## Cấu hình Modal

Tạo hai Modal Environments độc lập, không dùng lại `ruby-envelope-staging`:

```sh
modal environment create rails-8-envelope-encryption-vault
modal environment create ruby-envelope-private
```

Tạo Secret tách riêng cho từng Environment thông qua UI Modal hoặc `modal secret create --from-dotenv` với file quyền 0600 **ngoài Git**. Không truyền mật khẩu hoặc khóa làm đối số lệnh, không commit giá trị thật:

| Modal Secret | Biến cần thiết |
| --- | --- |
| `rails-8-envelope-encryption-vault-crypto` | `VAULT_KEK_B64` (base64 của khóa ngẫu nhiên đúng 32 byte), `VAULT_ACTIVE_KEK_ID` |
| `rails-8-envelope-encryption-vault-runtime` | `SECRET_KEY_BASE` (từ 64 byte), `APP_HOSTS` (hostname demo chính xác), `DEMO_PASSWORD` (ít nhất 14 ký tự, mật khẩu chỉ dùng cho demo dữ liệu giả) |
| `ruby-envelope-private-crypto` | `VAULT_KEK_B64` khác hoàn toàn, `VAULT_ACTIVE_KEK_ID` riêng |
| `ruby-envelope-private-runtime` | `SECRET_KEY_BASE` riêng, `APP_HOSTS` (hostname private), **`PRODUCTION_POSTGRES_URL`** |

Không dùng chung KEK giữa staging/demo/private. KEK của vault cá nhân phải có bản sao bảo quản độc lập. URL database phải dùng tài khoản riêng, TLS; chương trình tự thêm `sslmode=require` nếu chưa có và từ chối `disable/prefer/allow`. Nên ưu tiên `sslmode=verify-full` với CA của nhà cung cấp nếu có thể.

`APP_HOSTS` phải chứa hostname đúng với endpoint Modal hoặc domain riêng. Lần đầu có thể deploy để nhận URL, sau đó cập nhật Secret theo hostname và deploy lại. Không tắt Rails Host Authorization hoặc CSRF để khắc phục cấu hình hostname sai.

## Lệnh deploy

Chạy trong thư mục gốc repository đã kiểm toán:

```sh
python3 -m unittest discover -s ops/modal/tests -v
REVAULT_MODAL_MODE=demo modal deploy -e rails-8-envelope-encryption-vault ops/modal/app.py
REVAULT_MODAL_MODE=private modal deploy -e ruby-envelope-private ops/modal/app.py
```

**Chưa deploy private** khi chưa có PostgreSQL ngoài, kế hoạch khởi tạo tài khoản chủ sở hữu, Secret ổn định, backup, phục hồi offsite và cấu hình phân quyền. Private chỉ chạy `db:migrate` (không dùng `db:prepare` hay `demo:fixture`), không tự tạo database. Khởi tạo chủ sở hữu sau bằng quy trình `vault:owner:create` được kiểm soát.

URL database là giá trị thuộc Modal Secret: không đưa vào Git, notebook, địa chỉ trình duyệt hay log. Thay đổi `PRODUCTION_POSTGRES_URL` đồng nghĩa chuyển database, **không phải** di chuyển dữ liệu. Khi đổi khóa phải bảo quản KEK lịch sử và nghiệm thu giải mã/phục hồi.

## Nghiệm thu

Demo: kiểm tra `/ready`, `/session/new`, đăng nhập tài khoản giả `showcase@example.test`, Vault/Audit/Sessions, mobile và reset database sau cold start. Khách dùng chung tài khoản, tuyệt đối không nhập bí mật thật.

Private: kiểm tra HTTPS, host/CSRF, TOTP MFA, session revocation, reauthentication trước khi xem secret, security checks, `script/production-acceptance`, backup age mã hóa offsite và khôi phục database sạch + giải mã canary, monitoring. URL PostgreSQL ngoài **chỉ giải quyết khả năng lưu database**; không tự bảo đảm KEK recovery hay disaster recovery. Xem [Checklist production](PRODUCTION-CHECKLIST.vi.md).

Chỉ cập nhật tag `v1.0.0` sau khi source đã nghiệm thu CI; không thay đổi tag khi quá trình kiểm thử chưa hoàn tất.
