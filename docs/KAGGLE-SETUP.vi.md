# Demo đầy đủ trên Kaggle / Google Colab — Ruby Envelope Vault v1.0.0

> 🌐 Language / Ngôn ngữ: [English](KAGGLE-SETUP.md) | **Tiếng Việt**

## Chạy ứng dụng Rails hoàn chỉnh trực tiếp từ GitHub

**[Mở notebook Kaggle / Colab song ngữ](../notebooks/Ruby_Envelope_Vault_v1_Kaggle_Colab_Full_Demo.ipynb)**

Demo chạy trên **CPU**, không cần Docker và lấy mã nguồn trực tiếp từ tag của GitHub. Không cần Kaggle Dataset riêng, database có sẵn hoặc dịch vụ production.

Notebook cài Ruby 3.4.11, Rails 8.1.4, PostgreSQL 17, Redis, tạo KEK LocalFile chỉ dùng trong phiên demo và schema database. Sau đó chạy kiểm tra crypto/security, toàn bộ Rails/Selenium tests, tạo sáu nhóm bản ghi giả đã mã hóa, kiểm tra HTTP, tùy chọn chụp mười ảnh giao diện thật và đóng gói showcase có checksum.

## Điều kiện trước khi chạy

- Tạo Kaggle notebook chạy **CPU**, bật **Internet**, hoặc mở Google Colab CPU có kết nối Internet. Cần môi trường Ubuntu/Debian và quyền cài package.
- Có vài GB dung lượng trống; Selenium/Chrome chạy trên CPU, không cần GPU.
- **Quyền truy cập GitHub:** repository hiện là **Private**. Chỉ người được cấp quyền mới có thể clone. Họ cần tạo fine-grained token giới hạn đúng repository và quyền **Contents: Read**, rồi lưu vào Kaggle Secrets hoặc Colab Secrets dưới tên `GH_READ_TOKEN`. Token không thể thay thế quyền truy cập repo.
- Nếu repo được chuyển thành Public sau này, notebook sẽ thử clone ẩn danh trước và **không yêu cầu token**.
- Tùy chọn email do người chạy sở hữu để bật Cloudflare Quick Tunnel bảo vệ bằng OTP. Mặc định không mở tunnel.

## Hướng dẫn Run All

1. Mở [file notebook](../notebooks/Ruby_Envelope_Vault_v1_Kaggle_Colab_Full_Demo.ipynb) từ GitHub, tải `.ipynb` và import vào **Kaggle Code** hoặc **Google Colab**.
2. Chọn **CPU**, bật Internet. Nếu repo vẫn Private, tạo secret `GH_READ_TOKEN` với quyền đọc và đảm bảo tài khoản GitHub được cấp phép vào repo.
3. Ở cell cấu hình, có thể điền `ACCESS_EMAIL = "your-email@example.com"` để mở URL qua Cloudflare OTP, hoặc để trống để chỉ truy cập localhost. Giữ `CAPTURE_SCREENSHOTS = True` và `MAKE_SHOWCASE_PACKAGE = True` nếu muốn nghiệm thu đầy đủ.
4. Chọn **Run All**. Notebook tải đúng tag `v1.0.0`, kiểm tra checkout khớp tag cùng hash Git của các file nguồn cốt lõi, cài dịch vụ, kiểm thử đầy đủ, sinh dữ liệu giả và mở Rails.
5. Nếu bật tunnel, đăng nhập Cloudflare bằng OTP gửi tới email đã khai báo. Sau đó đăng nhập Rails bằng `showcase@example.test` và mật khẩu demo được sinh riêng, hiện trong **output notebook cá nhân**.
6. Thử dashboard, Vault, các loại item, version history, audit, MFA/security và session. Notebook tạo 10 ảnh Selenium desktop/mobile cùng manifest/checksum và gói showcase đã kiểm tra tính toàn vẹn.
7. Khi kết thúc, chạy cell shutdown nếu cần. Xóa output trước khi chia sẻ notebook; không upload password, KEK, `.env`, log riêng tư hay DB lên GitHub.

## Bằng chứng và giới hạn

Trong **phiên nghiệm thu Kaggle CPU được chạy riêng ngày 22/10/2026**, chúng ta xác nhận:

| Hạng mục | Kết quả quan sát |
| --- | --- |
| Rails unit/integration | 216 tests / 2.127 assertions / 0 lỗi |
| Selenium system | 21 tests / 223 assertions / 0 lỗi |
| Dữ liệu mã hóa giả | 6 items / 7 versions / 7 audit events |
| HTTP nội bộ | `/up` và `/session/new`: 200 |
| Ảnh giao diện Selenium | 10/10 PASS |
| Kiểm tra gói showcase | 307 liên kết/tham chiếu, 10 ảnh, 59 file ở gốc package — PASS |

**Ranh giới bằng chứng:** Những kết quả trên là từ quá trình cài Kaggle mới và các lệnh đã chạy độc lập. **Chưa có bản ghi chứng minh một phiên notebook mới chạy nguyên file `.ipynb` theo chế độ Run All từ đầu đến cuối.** Phải nghiệm thu bước đó trước khi tuyên bố notebook đã đạt reproducibility hoàn toàn.

### Lỗi tương thích test với umask

Mã nguồn tag v1.0.0 có một test giả định thư mục tạo bằng `Dir.mkdir(path, 0o755)` luôn mang mode `0755`. Bootstrap cố tình dùng `umask=077` để bảo vệ secret, nên thư mục tạo ra thực tế là `0700` và một assertion thất bại. Đây là lỗi phụ thuộc môi trường của **test**, không phải lỗi mã hóa.

Notebook dùng `START_SERVER=0 RUN_TESTS=0` khi chuẩn bị hệ thống nhưng **vẫn chạy crypto/security self-tests và project doctor**. Ngay sau đó, nó chạy **đầy đủ Rails và Selenium tests** trong pha riêng với `umask=022`. KEK và file môi trường vẫn được giữ mode `0600`. Việc sửa test để không phụ thuộc `umask` nên đưa vào bản mã nguồn sau.

## An toàn và xử lý lỗi

Chỉ dùng dữ liệu giả trên notebook tạm thời. Cloudflare Quick Tunnel không phải môi trường production. Giữ toàn bộ artifact và log nhạy cảm ngoài Git. Nếu chạy lỗi, kiểm tra log theo từng pha tại runtime cá nhân, không gửi token, mật khẩu, KEK hoặc database thật vào issue. Đọc thêm [bảo mật](SECURITY.vi.md), [tái lập môi trường](reproducibility.vi.md), [khắc phục lỗi](troubleshooting.vi.md) và [Ma trận kiểm chứng](qualification.vi.md).

Tag `v1.0.0` tiếp tục đại diện mã nguồn đã nghiệm thu; notebook mới là lớp demo được commit bổ sung, không thay thế mã nguồn tại tag.
