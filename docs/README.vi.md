# Hướng dẫn tài liệu — Ruby Envelope Vault v1.0.0

> 🌐 Language / Ngôn ngữ: [English](README.md) | **Tiếng Việt**

## Nên bắt đầu từ đâu?

[README chính](../README.vi.md) giới thiệu Vault, mã hóa phong bì và cách chạy demo an toàn. Chỉ mục này sắp xếp theo **mục tiêu người đọc**, không phải số lượng file.

| Đối tượng / mục tiêu | Đọc trước | Đọc tiếp |
| --- | --- | --- |
| Người đánh giá lần đầu | [README](../README.vi.md) | [Tổng quan kỹ thuật](engineering-overview.vi.md) |
| Reviewer bảo mật | [Mô hình đe dọa](THREAT-MODEL.vi.md) | [Quản lý khóa](KEY-MANAGEMENT.vi.md), [Kiến trúc](ARCHITECTURE.vi.md) |
| Lập trình viên | [Kiến trúc](ARCHITECTURE.vi.md) | [Tái lập](reproducibility.vi.md), [Xử lý lỗi](troubleshooting.vi.md) |
| Người chạy demo | [Notebook](KAGGLE-SETUP.vi.md) | [Accessibility](ACCESSIBILITY.vi.md) |
| Operator production | [Triển khai](deployment.vi.md) | [Checklist production](PRODUCTION-CHECKLIST.vi.md) |
| Reviewer DR | [Backup/restore](BACKUP-RESTORE.vi.md) | [Nguồn gốc phục hồi](RECOVERY-PROVENANCE.vi.md) |
| Reviewer phát hành | [Ma trận kiểm chứng](qualification.vi.md) | [Bằng chứng](evidence-index.vi.md), [Checklist production](PRODUCTION-CHECKLIST.vi.md) |

## Kiến trúc và kỹ thuật

- [Kiến trúc](ARCHITECTURE.vi.md): ranh giới Rails/database/KeyProvider và vòng đời envelope.
- [Tổng quan kỹ thuật](engineering-overview.vi.md): các thành phần, dịch vụ và quyết định vận hành.
- [Audit Activity Center](AUDIT-ACTIVITY.vi.md): ranh giới sự kiện tài khoản, kết quả, bộ lọc và giới hạn bằng chứng bảo mật.
- [Mô hình đe dọa](THREAT-MODEL.vi.md): tác nhân, tài sản, kiểm soát và giới hạn.
- [Quản lý khóa](KEY-MANAGEMENT.vi.md): tạo KEK, xoay, rollback và phục hồi độc lập.

## Cài đặt, vận hành và DR

- [Notebook](KAGGLE-SETUP.vi.md): bootstrap Kaggle/Colab tạm thời dùng dữ liệu giả.
- [Triển khai](deployment.vi.md): tách môi trường, tiền kiểm và nghiệm thu host riêng.
- [Checklist production](PRODUCTION-CHECKLIST.vi.md): biện pháp bảo vệ trước go-live.
- [Backup/restore](BACKUP-RESTORE.vi.md): dump mã hóa age, checksum, restore và canary.
- [Nguồn gốc phục hồi](RECOVERY-PROVENANCE.vi.md): yêu cầu đối với bằng chứng phục hồi.
- [Khắc phục sự cố](troubleshooting.vi.md): chẩn đoán an toàn, không làm lộ secret.

## Kiểm thử, accessibility và phát hành

- [Tái lập](reproducibility.vi.md): clean checkout, CI và test tại máy.
- [Ma trận kiểm chứng](qualification.vi.md): phân biệt PASS mã nguồn và host.
- [Bằng chứng](evidence-index.vi.md): artifact có thể review, giới hạn và mẫu báo cáo.
- [Accessibility](ACCESSIBILITY.vi.md), [Kế hoạch manual](ACCESSIBILITY-TEST-PLAN.vi.md): phạm vi và điều kiện còn thiếu.
- [Ma trận kiểm chứng](qualification.vi.md), [Checklist production](PRODUCTION-CHECKLIST.vi.md): bằng chứng kiểm thử và yêu cầu nghiệm thu riêng từng host.
- [Hướng dẫn cộng đồng](COMMUNITY.vi.md): quy trình đóng góp, hỗ trợ, bảo mật, issue và pull request.
- [Changelog](CHANGELOG.vi.md), [Bảo mật](SECURITY.vi.md), [Đóng góp](../.github/CONTRIBUTING.vi.md).

## Quy ước bảo mật và bằng chứng

Chỉ dùng dữ liệu giả trong ví dụ, screenshot công khai hoặc issue. Ghi **SHA nguồn**, không chỉ tên phiên bản. Nếu chưa chạy test, ghi **PENDING / NOT RUN**; không dùng CI xanh để tuyên bố đã nghiệm thu production.

Mỗi tài liệu Markdown đều có bản tiếng Anh/Việt và link đổi ngôn ngữ.
