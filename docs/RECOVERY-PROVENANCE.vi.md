# Nguồn gốc bằng chứng khôi phục — 1.0.0

> 🌐 Language / Ngôn ngữ: [English](RECOVERY-PROVENANCE.md) | **Tiếng Việt**
## Khả năng chứng minh

Việc có database backup chưa chứng minh hệ thống có thể phục hồi. Cần xác minh checksum, giải mã lớp bọc, restore vào database riêng và giải mã thành công một **canary giả có giá trị chính xác đã biết** bằng KEK phục hồi được quản lý độc lập.

Những công cụ có trong mã nguồn cung cấp kiểm tra backup, tải offsite, restore an toàn và ghi kết quả. Bằng chứng trên môi trường test không thể tự trở thành nghiệm thu một host production mới.

## Lưu trữ bằng chứng

Lưu archive backup, KEK, age identity, cấu hình và báo cáo chứa dữ liệu nhạy cảm bên ngoài Git. Chỉ công bố thông tin tổng hợp và checksum phù hợp. Đọc [backup và phục hồi](BACKUP-RESTORE.vi.md) cùng [checklist production](PRODUCTION-CHECKLIST.vi.md).
