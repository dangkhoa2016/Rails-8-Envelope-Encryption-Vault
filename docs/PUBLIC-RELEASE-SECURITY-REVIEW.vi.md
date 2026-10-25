# Rà soát bảo mật trước khi công bố công khai — phạm vi mã nguồn

> 🌐 Language / Ngôn ngữ: [English](PUBLIC-RELEASE-SECURITY-REVIEW.md) | **Tiếng Việt**

## Phạm vi và bằng chứng

Việc rà soát được thực hiện trên checkout cô lập của mã nguồn v1.0.0 và các thay đổi tìm kiếm/tài liệu, trước khi đổi trạng thái truy cập repository. Đã đọc các đường mã hóa chính, key provider, đăng nhập, phân quyền Vault theo chủ sở hữu, session và MFA, Audit, CI, cấu hình môi trường và tài liệu phát hành.

Sau khi fetch **đầy đủ** lịch sử Git, kiểm tra heuristic trên 82 commit có thể truy cập, khoảng 1.549.009 byte Git patch dạng text. Không phát hiện đường dẫn file nhạy cảm được track hoặc dòng thêm mới có mẫu định dạng PEM private key, GitHub token, AWS access key ID, token Hugging Face/Slack. Không in nội dung secret. Đây **chỉ là kết quả âm tính của kiểm tra heuristic**, không chứng minh lịch sử không có credential. Các object bị rewrite không còn reachable, artifact ngoài repo, cache, file môi trường và máy production không thuộc phạm vi xác minh sạch.

## Giới hạn và các yêu cầu còn lại

- Mã hóa thực hiện **phía server**, không phải zero-knowledge; Rails host bị chiếm nhưng có quyền KeyProvider có thể giải mã dữ liệu.
- Chưa xác minh độc lập IAM/cấu hình AWS KMS production, latency hoặc phí; CI sử dụng KEK LocalFile giả.
- Đã xử lý lỗi giới hạn tìm kiếm 250 item và giảm số item giải mã khi xem danh sách thường; tìm title/tag riêng tư vẫn cần giải mã O(N) và phải đánh giá khả năng tải khi triển khai lớn.
- AuditEvent có cơ chế readonly ở tầng ứng dụng, không phải log chống sửa đổi bằng mật mã tại database.
- Chưa chứng nhận việc restore backup offsite thực, KEK recovery tách biệt, HTTPS production, retention/quyền riêng tư hoặc pentest bên ngoài.
- Phải kiểm tra dữ liệu ví dụ trong README, screenshot, log CI và release notes trước khi public; không công bố session cookie, credential, khóa hoặc backup thật.
- Giữ repository **Private** cho đến khi có chỉ thị cụ thể cho phép chuyển sang Public.

## Điều kiện công bố

1. Chạy lại CI, kiểm tra tài liệu, Brakeman, dependency audit và test tìm kiếm trên **commit ứng viên chính xác**.
2. Quét toàn bộ lịch sử Git bằng công cụ chuyên dụng như Gitleaks/TruffleHog, phân tích các cảnh báo nhưng không dán secret vào issue. Lần rà soát này mới chạy heuristic.
3. Kiểm tra GitHub Actions history/artifacts, release, tag, asset và secrets/settings của repo, bao gồm SHA cũ sau rewrite.
4. Kiểm tra clone ẩn danh và khả năng truy cập link **sau khi** có chấp thuận công khai.
5. Nghiệm thu host production, backup/restore và quyền sở hữu KEK riêng trước khi lưu credential thật.

**Kết luận: chưa tự động thông qua việc chuyển Public hoặc lưu secret production.** Đây là báo cáo có giới hạn, không phải chứng nhận pentest độc lập.
