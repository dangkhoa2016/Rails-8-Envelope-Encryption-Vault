# Ma trận kiểm chứng — v1.0.0

> 🌐 Language / Ngôn ngữ: [English](qualification.md) | **Tiếng Việt**

## Cách đọc ma trận

Kết quả nghiệm thu luôn gắn với **SHA Git và môi trường cụ thể**. Một phép kiểm PASS nghĩa là hợp đồng kiểm tra tương ứng đã chạy thành công; không chứng minh máy chủ production an toàn tuyệt đối, mọi lỗi đều được bao phủ hoặc đã qua pentest độc lập.

| Hạng mục | Kiểm tra mã nguồn tự động | Điều kiện còn phải nghiệm thu |
| --- | --- | --- |
| Rails | `bin/rails test`, request/service tests | Chính sách tài khoản và quy trình thật trên máy đích |
| Trình duyệt | `bin/rails test:system` | Trình duyệt/thiết bị và accessibility thực tế |
| Mật mã xác thực | `script/crypto-self-test`, crypto tests | Lưu KEK, xoay khóa và quyền phục hồi |
| Bảo mật truy cập | `script/security-self-test`, request tests | MFA, session, origin và reverse proxy production |
| Ruby/dependency | RuboCop, Brakeman, bundler-audit | Theo dõi lỗ hổng và phản ứng sự cố liên tục |
| Tương thích | CI Ruby 3.4 và 4.0 | Hệ điều hành, kernel và runtime thực tế |
| Database | PostgreSQL 17 trong CI | Backup, phân quyền và theo dõi máy DB |
| Docker | `docker build --pull --no-cache` | Triển khai image, TLS, network và secret injection |
| Tài liệu | `script/doc-quality-check` | Review quy trình và thay đổi riêng của người vận hành |
| Phục hồi | Script tests và synthetic rehearsals | Tải lại từ offsite, age/KEK độc lập, canary sau restore |
| Accessibility | Kiểm tra UI/keyboard tự động | Screen reader, cảm ứng, contrast và focus thủ công |

## Workflow tham chiếu

[Cấu hình CI](../.github/workflows/ci.yml) xác định chính xác các lệnh và ma trận chạy. Ví dụ đợt nghiệm thu ban đầu: [GitHub Actions run 39538635309](https://github.com/dangkhoa2016/Rails-8-Envelope-Encryption-Vault/actions/runs/39538635309), kèm [workflow tài liệu](../.github/workflows/docs.yml). Sau khi rewrite Git history, phải xác minh lại SHA: liên kết run cũ **không** tự động chứng minh commit SHA mới đã PASS.


## Danh sách kiểm tra mã nguồn

1. Xác nhận branch, tag và commit SHA định phát hành.
2. Xác minh CI, documentation và security jobs gắn với đúng SHA.
3. Chạy kiểm tra link/cặp bản dịch và review tuyên bố bảo mật chưa có bằng chứng.
4. Rà soát diff Git, MIT attribution, repository policy và các file bí mật bất thường.
5. Xác minh package hoặc Docker build nếu là một phần sản phẩm phát hành.
6. Ghi nhận giới hạn ảnh hưởng đến nhu cầu sử dụng; xem Checklist production trước khi dùng dữ liệu thật.

## Điều kiện bổ sung trước khi chạy production

- Kiểm tra TLS/reverse proxy, host/origin/CSRF trên **endpoint thật**.
- Chứng minh quyền truy cập KEK và bản sao phục hồi quản lý độc lập.
- Tải archive đã mã hóa từ offsite; restore vào DB mới có chốt an toàn; giải mã canary giả.
- Xác minh MFA, cách ly theo chủ sở hữu, thu hồi phiên và lọc log trên máy triển khai.
- Nghiệm thu accessibility thủ công và có chấp thuận của người vận hành.
- Kiểm tra lại sau thay đổi mã nguồn, cấu hình hoặc hạ tầng cuối cùng.

## Phân loại bằng chứng

| Phân loại | Ý nghĩa |
| --- | --- |
| **SOURCE PASS** | Kiểm tra có thể chạy lại trên repository/package với SHA cố định |
| **SYNTHETIC PASS** | Thử nghiệm với bí mật giả và môi trường cách ly |
| **HOST PASS** | Người vận hành chạy kiểm tra có tài liệu trên một host cụ thể |
| **PENDING** | Chưa có bằng chứng đáp ứng đúng điều kiện nghiệm thu đó |
| **NOT CLAIMED** | Ngoài phạm vi: zero-knowledge, kiểm toán chính thức, SLA hay chứng nhận |

Chỉ sử dụng bằng chứng gắn với đúng revision và môi trường đang đánh giá. Đọc [Bằng chứng](evidence-index.vi.md), [Tái lập](reproducibility.vi.md) và [Triển khai](deployment.vi.md).
