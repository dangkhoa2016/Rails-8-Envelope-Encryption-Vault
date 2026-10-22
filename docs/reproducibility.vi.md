# Tái lập và kiểm chứng độc lập — v1.0.0

> 🌐 Language / Ngôn ngữ: [English](reproducibility.md) | **Tiếng Việt**

## Mục tiêu

Một phép thử có thể tái lập phải ghi rõ **revision mã nguồn**, **runtime**, **môi trường**, **lệnh** và **output thực tế**. Kết quả PASS của SHA khác không chứng minh commit đang review đạt yêu cầu. Test dùng tài khoản giả không đồng nghĩa đã được phép triển khai production.

## Mốc tham chiếu

| Thành phần | Thông tin |
| --- | --- |
| Revision | `git rev-parse HEAD` và tag annotated `v1.0.0` |
| Ruby | `.ruby-version` (3.4.11) |
| Rails | Khóa trong `Gemfile.lock`, Rails 8.1.4 trong `Gemfile` |
| PostgreSQL | 17 trong CI |
| KEK cục bộ | Khóa 32 byte giả, thư mục riêng chỉ dành cho test |
| Dữ liệu | Database test, không dùng dữ liệu cá nhân/production |
| Browser tests | Selenium/Capybara và các dependency theo CI |

## Cách A — kiểm chứng bằng GitHub Actions

1. Đọc [CI](../.github/workflows/ci.yml) và [kiểm tra tài liệu](../.github/workflows/docs.yml).
2. Đối chiếu SHA của mỗi workflow run; badge theo branch không phải bằng chứng bất biến.
3. Xác minh Rails, lint, security, compatibility và Docker jobs thuộc revision cần kiểm tra.
4. Ghi lại job lỗi/rerun, giới hạn môi trường và liên kết log đầy đủ.
5. Chạy lại workflow sau khi đổi docs, code, CI hoặc Git history.

## Cách B — kiểm thử trên máy phát triển

Bắt đầu bằng checkout sạch. Cấu hình PostgreSQL test database dùng một lần và KEK **giả** riêng biệt. Không load biến môi trường production để chạy test.

```bash
git clone https://github.com/dangkhoa201/Rails-8-Envelope-Encryption-Vault.git
cd Rails-8-Envelope-Encryption-Vault
git checkout v1.0.0
git rev-parse HEAD
ruby --version
bundle install
```

Khai báo `TEST_DATABASE_URL` riêng và tạo KEK trong thư mục hạn chế quyền. CI đặt rõ `VAULT_KEY_PROVIDER=local_file`, `VAULT_ACTIVE_KEK_ID`, `VAULT_KEK_DIR`. Dùng cấu hình tương tự để tái lập mà không chạm tới kho khóa cá nhân.

```bash
export RAILS_ENV=test
# Cần có TEST_DATABASE_URL và các giá trị VAULT_* giả trước.
script/crypto-self-test
script/security-self-test
bin/rails zeitwerk:check
bin/rails db:prepare
bin/rails test
bin/rails test:system
python3 script/doc-quality-check
script/repository-policy
```

Kiểm tra lint/security với gem đã khóa:

```bash
bundle exec rubocop
bundle exec brakeman --no-pager -q
bundle exec bundle-audit check --update
```

Các lệnh này cần công cụ trên host và database test. YAML của CI là đặc tả thực thi. Nếu máy hiện tại không đủ điều kiện chạy, ghi **NOT RUN**, không tự ghi PASS.

## Cách C — demo trên notebook tạm thời

[Thiết lập Kaggle/Colab](KAGGLE-SETUP.vi.md) dùng bootstrap không cần Docker. Lần chạy đầu không mở server:

```bash
START_SERVER=0 ./bootstrap.sh
./bootstrap.sh doctor
```

Bootstrap cài runtime tách khỏi Git nhưng notebook và dữ liệu có thể bị mất khi restart. Cách này chứng minh hành vi ứng dụng, không xác nhận hạ tầng bền vững, backup offsite hoặc quyền quản lý KEK production.

## Mẫu nhật ký bằng chứng

```text
Tag / SHA mã nguồn:
Môi trường / Ruby / PostgreSQL:
Key provider (chỉ tên và ID khóa giả):
Các lệnh đã thực hiện:
Kết quả từng lệnh (PASS, FAIL, NOT RUN):
Link CI / đường dẫn log:
Khác biệt môi trường và điều kiện host còn thiếu:
```

**Không đưa KEK, token, bí mật người dùng, dump database hoặc age identity riêng tư vào báo cáo.** Chỉ ghi lệnh, trạng thái chạy, checksum phù hợp và log đã che dữ liệu nhạy cảm.

## Điều không thể suy ra

CI/local PASS không tự chứng minh offsite restore, TLS production, KEK phục hồi độc lập, bảo mật metadata, accessibility thủ công hay kiểm toán mật mã ngoài dự án.

Đọc tiếp [Ma trận kiểm chứng](qualification.vi.md), [Bằng chứng](evidence-index.vi.md) và [Ma trận kiểm chứng](qualification.vi.md).
