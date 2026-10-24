# Rails 8 Envelope Encryption Vault — Demo tương tác Kaggle / Google Colab

> 🌐 Language / Ngôn ngữ: [English](KAGGLE-SETUP.md) | **Tiếng Việt**

## Trải nghiệm ứng dụng Rails thực tế

**[Mở notebook demo song ngữ](../notebooks/Rails_8_Envelope_Encryption_Vault_Kaggle_Colab_Demo.ipynb)**

Đây là **notebook Kaggle/Colab duy nhất được hỗ trợ chính thức**. Notebook chạy ứng dụng Rails 8 Envelope Encryption Vault thực tế với **28 bản ghi giả đã mã hóa** thuộc bảy nhóm, Dashboard, tìm kiếm/phân trang, Favorites, Archive, lịch sử bất biến và bộ lọc Security Activity. Không cần GPU. Notebook lấy mã nguồn trực tiếp từ GitHub, không phụ thuộc Kaggle Dataset.

Notebook có **hai chế độ trong cùng một file**:

| Chế độ | Đối tượng | Công việc |
| --- | --- | --- |
| **Explore** (mặc định) | Người dùng lần đầu | Xác minh Git source, kiểm tra crypto/security khi cài đặt, tạo tài khoản/dữ liệu giả, mở website Rails, kiểm tra metadata envelope đã mã hóa |
| **Verify** | Người review kỹ thuật | Toàn bộ Explore, **cộng thêm** Rails/Selenium tests đầy đủ, mặc định chụp mười ảnh desktop/mobile, kiểm tra checksum và đóng gói bằng chứng đã lọc dữ liệu nhạy cảm |

Verify vẫn chạy **toàn bộ bộ test** sau khi website đã mở; việc chụp ảnh Selenium lỗi không có nghĩa là không thể dùng demo.

## Hướng dẫn chạy

1. Import [notebook chính thức](../notebooks/Rails_8_Envelope_Encryption_Vault_Kaggle_Colab_Demo.ipynb) vào **Kaggle CPU** (bật Internet) hoặc **Google Colab CPU**. Cần Linux runtime có quyền cài package và vài GB dung lượng trống.
2. Để **DEMO_EXPERIENCE = "explore"** (mặc định), hoặc chọn **"verify"** nếu muốn chạy kiểm thử và xuất evidence đầy đủ. Giữ **ENABLE_CLOUDFLARE_TUNNEL = True** chỉ nếu bạn chấp nhận một trang đăng nhập tạm có thể truy cập công khai. Đặt False để chỉ dùng localhost.
3. Notebook clone mã nguồn đã được review ẩn danh từ GitHub chính thức, không yêu cầu GitHub token hoặc Kaggle/Colab Secret. Không đưa thông tin đăng nhập vào code cell hoặc Git URL.
4. Chạy **Run All**. Các bước đầu cài môi trường, xác minh mã nguồn, chuẩn bị database riêng, tạo account mẫu. Khi Rails/PostgreSQL sẵn sàng, cell trình duyệt hiện liên kết **Open Rails 8 Envelope Encryption Vault**.
5. Mở liên kết, đăng nhập email **showcase@example.test**, dùng **mật khẩu ngẫu nhiên trong output riêng tư tại Bước 4**. Trải nghiệm Search, phân trang, Favorites, Archive, phiên bản và Security Activity.
6. Với Verify, xem thêm Rails/Selenium tests, gallery và evidence. Khi xong, bấm **Stop Rails 8 Envelope Encryption Vault** ở cell cuối; Run All **không tự đóng website**. Nếu widget không hỗ trợ, đặt **STOP_DEMO_NOW = True** và chạy riêng cell cuối.

**An toàn:** Cloudflare Quick Tunnel không yêu cầu email/OTP, nhưng Rails vẫn yêu cầu đăng nhập. **Ai có URL đều có thể truy cập trang login**. Chỉ dùng dữ liệu giả, giữ kín mật khẩu, khóa và xóa execution outputs trước khi chia sẻ. Binary tunnel được ghim bản phát hành Cloudflare chính thức **2026.10.3** (linux-amd64), kiểm tra SHA-256 công bố trước khi chạy.

## Xác minh mã nguồn và khả năng tái lập

Notebook clone lịch sử **main** từ GitHub chính thức và checkout **toàn bộ source của annotated tag `v1.0.0`**, không chạy một snapshot ứng dụng cũ. Notebook xác minh release thuộc lịch sử main, tính toàn vẹn Git objects (`git fsck`), `VERSION` và detached checkout sạch, rồi in ra commit SHA và Git tree SHA chính xác. Khi main có thêm tính năng chưa phát hành, notebook vẫn chạy bản `v1.0.0` được người dùng lựa chọn, không tự ý thực thi code chưa phát hành. Git tag không thay thế chữ ký số tác giả; demo tuyệt đối không dùng thông tin bí mật thật.

Mỗi Run All dùng checkout, PostgreSQL role/database, cổng HTTP và thư mục bằng chứng riêng. **Mật khẩu mới theo lần chạy** nằm ngoài Git trong file **0600**. Bootstrap crypto/security được chạy ở cả hai chế độ; Explore kiểm tra metadata envelope đã lưu mà không in secret dạng rõ. Verify chạy đủ Rails/Selenium tests với **umask 022 riêng cho test**; các file khóa/log vẫn được bảo vệ nghiêm ngặt.

Chụp ảnh gồm **10 trang thật**, có manifest và SHA-256; đóng gói ảnh/bằng chứng theo chế độ Verify. Explore mặc định không chụp và không xuất package. Không phát hành notebook có output nhạy cảm, token, KEK, log riêng tư hoặc database dump.

## Giới hạn kết quả và tài liệu liên quan

Git SHA/tree kiểm tra tính nhất quán nội dung, **không tự chứng minh danh tính nhà phát hành hoặc chứng nhận an toàn**. Kiểm thử synthetic và GitHub CI không thay thế phục hồi KEK/KMS production hoặc kiểm tra bảo mật độc lập.

Đọc thêm [bảo mật](SECURITY.vi.md), [qualification](qualification.vi.md), [reproducibility](reproducibility.vi.md), [troubleshooting](troubleshooting.vi.md), [production checklist](PRODUCTION-CHECKLIST.vi.md). Đối chiếu [CI workflow](https://github.com/dangkhoa2016/Rails-8-Envelope-Encryption-Vault/actions/workflows/ci.yml) với SHA release thực tế.
