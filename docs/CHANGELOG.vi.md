# Changelog — 1.0.0

> 🌐 Language / Ngôn ngữ: [English](CHANGELOG.md) | **Tiếng Việt**
## 1.0.0 — Bản phát hành mã nguồn đầu tiên cho cộng đồng

Bản release đầu tiên bao gồm Rails 8, quy trình nghiệm thu có thể tái lập và tài liệu song ngữ Anh/Việt.

### Điểm nổi bật
- Audit lọc tức thời và Vault Search giữ trạng thái, không đưa tiêu đề/tag plaintext vào URL.
- Favorite/Unfavorite cập nhật tại trang chi tiết, không reload, giữ focus.
- Toast thông báo thành công/lỗi dùng chung, có accessibility và hỗ trợ Turbo Stream.
- Thư viện `crass` 1.0.8 xử lý GHSA-pq4g-8rxf-4g29.
- Một notebook Kaggle/Colab ghim commit ứng dụng và Git tree.

Rails 8 Envelope Encryption Vault là ứng dụng Rails 8 dùng PostgreSQL, mã hóa phong bì AES-256-GCM, các nhà cung cấp KEK, MFA, lịch sử bí mật bất biến và audit event.

Mã nguồn có bộ kiểm thử Rails, quét bảo mật Ruby, kiểm tra Docker/CI và các script backup, khôi phục có kiểm soát.

Công bố mã nguồn không có nghĩa hệ thống đã được triển khai và nghiệm thu production. Không tuyên bố tồn tại bản phát hành mã nguồn công khai nào trước 1.0.0.
