# Đóng góp — 1.0.0

> 🌐 Language / Ngôn ngữ: [English](CONTRIBUTING.md) | **Tiếng Việt**
Cảm ơn bạn đã xem xét Rails 8 Envelope Encryption Vault. Hãy mở issue để trao đổi về thay đổi lớn trước khi gửi pull request.

## Nguyên tắc kỹ thuật

1. Giữ mô hình envelope AES-256-GCM, DEK độc lập và ranh giới lưu KEK.
2. Không commit credential, vault thật, backup, KEK, KMS token hoặc bằng chứng riêng tư.
3. Giữ phiên bản mã nguồn 1.0.0 cho đến khi quy trình phát hành tạo bản mới chính thức.
4. Mọi tài liệu được sửa cần cập nhật cả bản tiếng Anh và tiếng Việt.
5. Nêu rõ lệnh tái hiện, kết quả mong đợi và trường hợp lỗi.
6. Chia thay đổi thành phần nhỏ dễ review; không trộn refactor không liên quan vào sửa bảo mật.

## Trước khi gửi PR

Chạy Rails tests, phân tích tĩnh và bộ kiểm tra tài liệu song ngữ phù hợp. Với thay đổi nhạy cảm, mô tả ranh giới tin cậy bị ảnh hưởng cùng ví dụ tổng hợp độc lập.

Sử dụng [mẫu pull request](PULL_REQUEST_TEMPLATE.vi.md) và tuân thủ [quy tắc ứng xử](CODE_OF_CONDUCT.vi.md).
