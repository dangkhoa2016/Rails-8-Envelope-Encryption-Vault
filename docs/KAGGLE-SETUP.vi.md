# Thiết lập Kaggle / Colab — 1.0.0

> 🌐 Language / Ngôn ngữ: [English](KAGGLE-SETUP.md) | **Tiếng Việt**
Mã nguồn có thể được khởi động trong notebook/container mà không cần Docker hoặc systemd. Đây là workflow phát triển và demo, **không phải triển khai production**.

## Bắt đầu

Bật Internet để cài phụ thuộc, clone repo dangkhoa2016/Rails-8-Envelope-Encryption-Vault, mở terminal tại thư mục dự án và chạy bootstrap.sh sau khi cấp quyền thực thi.

Để chỉ cài đặt mà không tự khởi động Rails, đặt START_SERVER=0. Có thể xem trạng thái qua bootstrap.sh status và chẩn đoán qua bootstrap.sh doctor.

Runtime có thư mục ghi dữ liệu riêng ở vùng làm việc Kaggle/Colab, không nên đưa vào Git. Ở terminal mới, nạp activate-runtime.sh.

Chỉ demo bằng dữ liệu giả. Không commit .env.kaggle, database dump, KEK, age identity, token hay nội dung vault thật.

Trước khi triển khai ra ngoài notebook, đọc [quản lý khóa](KEY-MANAGEMENT.vi.md) và [checklist production](PRODUCTION-CHECKLIST.vi.md).

## Kế hoạch notebook

Demo CPU sử dụng cơ sở dữ liệu Rails tạm và dữ liệu giả đã mã hóa. Notebook được công bố sau khi hoàn tất các kiểm tra nguồn và bảo mật.
