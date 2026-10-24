# Demo đầy đủ Kaggle / Google Colab — Ruby Envelope Vault

> 🌐 Language / Ngôn ngữ: [English](KAGGLE-SETUP.md) | **Tiếng Việt**

## Một notebook, một phiên bản ứng dụng đã kiểm tra

**[Mở notebook Kaggle / Colab song ngữ hoàn chỉnh](../notebooks/Ruby_Envelope_Vault_Kaggle_Colab_Full_Demo.ipynb)**

Đây là **notebook demo duy nhất được hỗ trợ trong repository**. Notebook tải lịch sử GitHub `main`, checkout dạng detached tại commit ứng dụng đã review `d0ffc2a15def747ca1b6b4e3a14cbab301663fc3` và kiểm tra Git tree chính xác `8fb2e8074714249d71d397949ab0a23c8d2807ba`. Toàn bộ lấy mã nguồn từ GitHub, không phụ thuộc Kaggle Dataset hay cơ sở dữ liệu chuẩn bị sẵn.

Demo bao gồm Audit lọc tức thời, Vault Search giữ trạng thái và không đưa tiêu đề/tag plaintext lên URL, Favorite tại chỗ, toast thông báo dùng chung, các item giả đã mã hóa và lịch sử phiên bản bất biến. Notebook cài Ruby 3.4, Rails 8, PostgreSQL 17, Redis; thực hiện kiểm tra crypto/security, đầy đủ bộ test Rails và Selenium, HTTP, chụp ảnh giao diện và đóng gói showcase tùy chọn.

**Nguồn gốc release:** Tag `v1.0.0` đại diện bản phát hành cộng đồng đầu tiên và bao gồm các cải tiến UX đã review. Notebook ghim commit ứng dụng ngay trước khi hoàn tất tài liệu song ngữ; commit này là tổ tiên của tag release. SHA/tree chứng minh nội dung nhất quán, không phải xác thực độc lập.

## Điều kiện và bảo mật

- Kaggle CPU có bật Internet hoặc Google Colab CPU có Internet, môi trường Ubuntu/Debian, quyền cài package và vài GB dung lượng ghi.
- Nếu repository **Public**, có thể clone ẩn danh và không cần token. Đối với repository hoặc mirror **Private**, người chạy cần được cấp quyền đọc và thiết lập secret `GH_READ_TOKEN` dạng fine-grained với quyền **Contents: Read** trong Colab/Kaggle. Token không tự tạo thêm quyền truy cập. Không chèn token vào source/output notebook.
- **Cloudflare Quick Tunnel** (tùy chọn) tạo URL development tạm thời. Rails vẫn xác thực đăng nhập, nhưng bất kỳ ai biết URL đều có thể mở trang login. Chỉ dùng dữ liệu giả, bảo vệ mật khẩu demo, và tắt `ENABLE_CLOUDFLARE_TUNNEL` nếu không cần truy cập ngoài.
- Không đưa output chứa thông tin nhạy cảm, token, KEK, backup database, log riêng tư hay ảnh chứa secret lên GitHub.

## Cách chạy Run All

1. Import [notebook chính thức](../notebooks/Ruby_Envelope_Vault_Kaggle_Colab_Full_Demo.ipynb) vào Kaggle Code hoặc Google Colab. Chọn **CPU** và bật Internet.
2. Nếu repo Private, cấu hình secret `GH_READ_TOKEN` chỉ đọc. Nếu Public thì clone ẩn danh; không ghi credential trong cell.
3. Giữ `ENABLE_CLOUDFLARE_TUNNEL = True` để thử website hoặc đặt `False` nếu chỉ dùng localhost.
4. Chạy **Run All theo thứ tự**. Kiểm tra `SOURCE_VERIFIED=PASS`, `SOURCE_TREE_VERIFIED=PASS`, toàn bộ Rails/Selenium tests và xác thực database. Notebook kiểm tra Git objects, từ chối source không khớp.
5. Sau `CLOUDFLARE_TUNNEL=READY`, mở `BROWSER_DEMO_URL`, đăng nhập bằng tài khoản demo giả từ **output riêng tư**, thử Dashboard, Vault search, Favorite, versions, Audit, MFA và Settings.
6. Kiểm tra screenshot Selenium và showcase có checksum nếu cần; kết thúc bằng dừng dịch vụ/reset runtime, xóa output trước khi chia sẻ.

## UX và dữ liệu giả

Fixture tạo **28 item giả đã mã hóa**, mỗi loại trong bảy nhóm có bốn ví dụ, ít nhất **29 phiên bản bất biến** và các audit event tương ứng. Mặc định danh sách Vault hiển thị sáu item mỗi trang; notebook kiểm tra bảy nhóm và hợp đồng mã nguồn.

Ứng dụng mới dùng Turbo Stream cập nhật Vault Search, token `filter` ngẫu nhiên gắn session thay vì đưa từ khóa giải mã lên URL, Audit Action tự đổi theo Category. Favorite/Unfavorite tại trang chi tiết cập nhật ngay và hiện toast dùng chung, không trở về danh sách.

## Kiểm chứng và giới hạn bằng chứng

Trên GitHub CI của cây mã nguồn UX đã nghiệm thu (24/10/2026), kết quả là **226 Rails tests / 2.303 assertions** và **28 Selenium tests / 346 assertions**, không có failures/errors/skips. Commit cuối sau rewrite vẫn phải được CI xác nhận trước khi cập nhật tag release.

Phiên nghiệm thu Kaggle CPU lịch sử 22/10/2026 đo 216 Rails tests / 2.127 assertions, 21 Selenium tests / 223 assertions, sáu item giả ban đầu và 10/10 screenshots. Đó là **phiên lịch sử độc lập**, không phải kết quả chứng minh cho commit mới. Người dùng đã nghiệm thu demo Global Toast trên Colab sau đó; chưa có chứng nhận production host độc lập.

### Umask trong tests

Bootstrap cố tình dùng `umask=077` bảo vệ file riêng tư. Một số assertion về permission cần `umask=022` trong **pha test duy nhất**. Notebook giữ KEK và file môi trường bảo vệ ở `0600`, không bỏ qua Rails/Selenium tests. Một assertion mode thư mục phụ thuộc vào umask trong pha test; không bỏ qua test và quyền file bí mật luôn được bảo vệ.

### Cô lập runtime và giới hạn an toàn

Mỗi Run All có checkout, PostgreSQL role/database và cổng Rails riêng, tránh nhầm tiến trình cũ. Notebook kiểm tra kết nối DB đã xác thực trước khi cấp URL tunnel; các runtime cũ chiếm dung lượng đến khi reset.

Kiểm tra SHA/tree chứng minh checkout nhất quán, **không** thay thế xác minh tính xác thực độc lập hay nghiệm thu production. Đọc thêm [chính sách bảo mật](SECURITY.vi.md), [ma trận kiểm chứng](qualification.vi.md), [tái lập](reproducibility.vi.md), [xử lý lỗi](troubleshooting.vi.md) và [production checklist](PRODUCTION-CHECKLIST.vi.md).
