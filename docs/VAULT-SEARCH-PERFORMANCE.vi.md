# Vault Search — độ chính xác và hiệu năng

> 🌐 Language / Ngôn ngữ: [English](VAULT-SEARCH-PERFORMANCE.md) | **Tiếng Việt**

## Thay đổi

Bản trước chỉ tìm trong 250 item ứng viên gần nhất/ưu tiên, nên có thể bỏ sót title/tag mã hóa ở ngoài giới hạn. Mã mới loại bỏ giới hạn này; tìm kiếm vẫn **giới hạn theo chủ sở hữu đang đăng nhập**.

Khi không tìm title/tag, PostgreSQL đếm và phân trang metadata **trước khi giải mã**. Trang mặc định sáu item chỉ giải mã tối đa sáu item. Trường tag có thể nhập tự do và gợi ý tag của trang hiện tại; tag ở trang khác vẫn tìm được.

## Giới hạn hiệu năng

Tìm theo title/tag mã hóa phải giải mã mọi item ứng viên phù hợp metadata: O(N). Với AWS KMS, mỗi lần mở DEK thường là một lời gọi KMS, nên tìm trên Vault lớn có thể chậm và tốn phí. Không lưu chỉ mục plaintext của title/tag. Chưa có benchmark độ trễ hay chi phí AWS KMS ở bản này.

Blind index dùng HMAC trong tương lai cần threat model, quản lý khóa chỉ mục, quy tắc chuẩn hóa, migration và kế hoạch rotation riêng.

## Benchmark với dữ liệu giả

Dùng PostgreSQL test và KEK LocalFile giả:

    RAILS_ENV=test VAULT_KEY_PROVIDER=local_file VAULT_BENCH_ITEMS=260 bin/rails runner script/benchmark-vault-search

Script tạo item giả trong transaction, đo thời gian create/list/title/tag rồi rollback. Nên chạy nhiều lần và ghi CPU, Ruby và PostgreSQL. Test tự động cũng xác minh chỉ giải mã item của trang khi không lọc text, và vẫn tìm được item ngoài giới hạn 250 cũ.

**Đây không phải benchmark AWS KMS.** Không sử dụng dữ liệu hoặc khóa production.
