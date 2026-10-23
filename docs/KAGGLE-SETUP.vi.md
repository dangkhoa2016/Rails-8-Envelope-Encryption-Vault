# Demo đầy đủ trên Kaggle / Google Colab — Ruby Envelope Vault v1.0.0

> 🌐 Language / Ngôn ngữ: [English](KAGGLE-SETUP.md) | **Tiếng Việt**

## Chạy ứng dụng Rails hoàn chỉnh trực tiếp từ GitHub

**[Mở notebook Kaggle / Colab song ngữ](../notebooks/Ruby_Envelope_Vault_v1_Kaggle_Colab_Full_Demo.ipynb)**

Demo chạy trên **CPU**, không cần Docker và lấy mã nguồn trực tiếp từ tag của GitHub. Không cần Kaggle Dataset riêng, database có sẵn hoặc dịch vụ production.

Notebook cài Ruby 3.4.11, Rails 8.1.4, PostgreSQL 17, Redis, tạo KEK LocalFile chỉ dùng trong phiên demo và schema database. Sau đó chạy kiểm tra crypto/security, toàn bộ Rails/Selenium tests, tạo bảy nhóm bản ghi giả đã mã hóa, kiểm tra HTTP, tùy chọn chụp mười ảnh giao diện thật và đóng gói showcase có checksum.

## Điều kiện trước khi chạy

- Tạo Kaggle notebook chạy **CPU**, bật **Internet**, hoặc mở Google Colab CPU có kết nối Internet. Cần môi trường Ubuntu/Debian và quyền cài package.
- Có vài GB dung lượng trống; Selenium/Chrome chạy trên CPU, không cần GPU.
- **Quyền truy cập GitHub:** repository hiện là **Private**. Chỉ người được cấp quyền mới có thể clone. Họ cần tạo fine-grained token giới hạn đúng repository và quyền **Contents: Read**, rồi lưu vào Kaggle Secrets hoặc Colab Secrets dưới tên `GH_READ_TOKEN`. Token không thể thay thế quyền truy cập repo.
- Nếu repo được chuyển thành Public sau này, notebook sẽ thử clone ẩn danh trước và **không yêu cầu token**.
- **Cloudflare Quick Tunnel công khai tạm thời được bật mặc định** (Rails vẫn yêu cầu đăng nhập), **không hỏi email/OTP Cloudflare**. Người biết URL có thể truy cập trang đăng nhập Rails. Chỉ dùng dữ liệu giả và giữ kín mật khẩu demo; chủ động tắt tunnel nếu chỉ kiểm thử localhost.

## Hướng dẫn Run All

1. Mở [file notebook](../notebooks/Ruby_Envelope_Vault_v1_Kaggle_Colab_Full_Demo.ipynb) từ GitHub, tải `.ipynb` và import vào **Kaggle Code** hoặc **Google Colab**.
2. Chọn **CPU**, bật Internet. Nếu repo vẫn Private, tạo secret `GH_READ_TOKEN` với quyền đọc và đảm bảo tài khoản GitHub được cấp phép vào repo.
3. Giữ `ENABLE_CLOUDFLARE_TUNNEL = True` để notebook tự mở URL trình duyệt **sau khi** Rails trả `/up=200` và `/session/new=200`. Không cần nhập email hay OTP. Đặt `False` nếu chỉ thử localhost; nên giữ phần chụp ảnh Selenium và đóng gói showcase.
4. Chọn **Run All**. Notebook tải annotated tag `v1.0.0`, xác minh tag trỏ đến commit đã checkout, kiểm tra Git object bằng `git fsck`, đối chiếu version và working tree sạch, không hard-code SHA từng file; sau đó cài dịch vụ, kiểm thử đầy đủ, sinh dữ liệu giả và mở Rails.
5. Sau thông báo `CLOUDFLARE_TUNNEL=READY`, bấm `BROWSER_DEMO_URL` để mở trang đăng nhập Rails. Dùng tài khoản giả `showcase@example.test` và mật khẩu demo ngẫu nhiên trong **output notebook riêng tư**; không chia sẻ mật khẩu.
6. Thử dashboard, Vault, các loại item, version history, audit, MFA/security và session. Notebook tạo 10 ảnh Selenium desktop/mobile cùng manifest/checksum và gói showcase đã kiểm tra tính toàn vẹn.
7. Khi kết thúc, chạy cell shutdown nếu cần. Xóa output trước khi chia sẻ notebook; không upload password, KEK, `.env`, log riêng tư hay DB lên GitHub.

**Dữ liệu demo hiện tại (v1.0.0):** seed tạo **28 item giả đã mã hóa**, mỗi loại trong bảy nhóm có bốn ví dụ, gồm **29 phiên bản mã hóa** và **29 sự kiện audit tạo/cập nhật** nếu chạy trên tài khoản demo sạch. Trang Vault hiển thị **6 item/trang**, đủ năm trang để kiểm thử Previous/Next, bộ lọc loại và tag. Nếu chạy lại mà không đặt `DEMO_RESET`, seed chỉ thêm ví dụ còn thiếu; tài khoản demo cũ có sáu item sẽ được bổ sung 22 item mới. Bảng nghiệm thu bên dưới vẫn giữ số liệu **lịch sử ngày 22/10/2026**, trước khi tăng dữ liệu demo.

**Phân trang GET (Pagy 43):** Vault hiển thị sáu item/trang. Search gửi POST riêng tư và cập nhật danh sách bằng Turbo Stream không reload; khi submit, URL đổi sang `/vault_items?filter=<mã-ngẫu-nhiên>&kind=login&page=1` (các tham số `status`/`favorite` được thêm khi áp dụng). Tiêu đề `q` và tên tag không bao giờ xuất hiện trong URL; chúng được lưu trong phiên Rails mã hóa, tham chiếu bằng mã lọc riêng cho từng lần tìm kiếm (tối đa bốn bộ lọc gần nhất trong cùng phiên). Refresh và liên kết phân trang GET giữ nguyên bộ lọc; khi không có JavaScript, POST → 303 → GET. Audit Log sử dụng mười sự kiện/trang; Category cập nhật danh sách Action ngay lập tức và phân trang GET giữ nguyên bộ lọc. Dùng **Clear filters** để xóa bộ lọc đang áp dụng.

**Giới hạn tin cậy Git:** Các bước kiểm tra xác minh sự nhất quán của checkout/Git object, không chứng minh tính xác thực của release. Tag chưa ký có thể bị thay thế; để xác thực độc lập cần chữ ký release tag với khóa tin cậy hoặc cơ chế tương đương.

**Chạy lại trên Colab/Kaggle:** Mỗi lần chạy toàn bộ notebook tạo một checkout Git mới, sạch và độc lập. Các thư mục checkout từ phiên trước không bị xóa tự động; reset runtime nếu cần thu hồi dung lượng. Sau bước seed, notebook kiểm tra ít nhất bốn item trong mỗi loại (bảy loại) và ít nhất 29 phiên bản mã hóa để khớp bộ demo hiện tại; không còn yêu cầu 6 item cũ.

**Chạy lại notebook và xác thực database:** Mỗi Run All tạo PostgreSQL role, database development/test và cổng HTTP Rails riêng. Server Rails cũ không thể vượt qua health check của lượt chạy mới, và không đổi mật khẩu database role của phiên trước. Trước khi công bố URL Cloudflare, notebook kiểm tra truy vấn PostgreSQL SELECT 1 đã xác thực thay vì chỉ kiểm tra HTTP /up. Đây là database demo dùng dữ liệu giả; reset runtime khi cần thu hồi dung lượng và kết thúc tiến trình cũ.

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

**Ranh giới bằng chứng:** Các kết quả Kaggle đã nghiệm thu và phiên Run All Colab người dùng cung cấp xác nhận luồng Rails nội bộ. Nhánh Quick Tunnel đơn giản (Rails trước, tunnel sau) hiện đã qua kiểm tra source nhưng **vẫn cần một phiên thử truy cập và đăng nhập thực tế từ trình duyệt ngoài Colab**.

### Lỗi tương thích test với umask

Mã nguồn tag v1.0.0 có một test giả định thư mục tạo bằng `Dir.mkdir(path, 0o755)` luôn mang mode `0755`. Bootstrap cố tình dùng `umask=077` để bảo vệ secret, nên thư mục tạo ra thực tế là `0700` và một assertion thất bại. Đây là lỗi phụ thuộc môi trường của **test**, không phải lỗi mã hóa.

Notebook dùng `START_SERVER=0 RUN_TESTS=0` khi chuẩn bị hệ thống nhưng **vẫn chạy crypto/security self-tests và project doctor**. Ngay sau đó, nó chạy **đầy đủ Rails và Selenium tests** trong pha riêng với `umask=022`. KEK và file môi trường vẫn được giữ mode `0600`. Việc sửa test để không phụ thuộc `umask` nên đưa vào bản mã nguồn sau.

## An toàn và xử lý lỗi

Chỉ dùng dữ liệu giả trên notebook tạm thời. Cloudflare Quick Tunnel không phải môi trường production. Giữ toàn bộ artifact và log nhạy cảm ngoài Git. Nếu chạy lỗi, kiểm tra log theo từng pha tại runtime cá nhân, không gửi token, mật khẩu, KEK hoặc database thật vào issue. Đọc thêm [bảo mật](SECURITY.vi.md), [tái lập môi trường](reproducibility.vi.md), [khắc phục lỗi](troubleshooting.vi.md) và [Ma trận kiểm chứng](qualification.vi.md).

Tag `v1.0.0` tiếp tục đại diện mã nguồn đã nghiệm thu; notebook mới là lớp demo được commit bổ sung, không thay thế mã nguồn tại tag.
