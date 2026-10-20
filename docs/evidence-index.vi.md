# Chỉ mục bằng chứng và cách diễn giải — v1.0.0

> 🌐 Language / Ngôn ngữ: [English](evidence-index.md) | **Tiếng Việt**

## Mục đích

Chỉ mục này cho biết **bằng chứng có thể kiểm tra nằm ở đâu**, chúng chứng minh được điều gì và không chứng minh được điều gì. Repository không cần chứa KEK cá nhân, thông tin production, log riêng tư hay báo cáo chứng nhận để được đánh giá minh bạch.

## Nguồn bằng chứng

| Bằng chứng | Vị trí | Chứng minh | Không chứng minh |
| --- | --- | --- | --- |
| Mã nguồn có phiên bản | `app/`, `db/`, `lib/` | Có thể kiểm tra mật mã, phân quyền và lưu dữ liệu | Bảo mật máy đang chạy hay mọi tình huống ngoài test |
| Automated tests | `test/` | Hành vi với dữ liệu và điều kiện được kiểm soát | Bao phủ toàn diện hoặc kiểm toán độc lập |
| Source CI | [CI workflow](../.github/workflows/ci.yml) | Lint, security scan, Rails, ma trận Ruby và Docker | Production hay cam kết SLA |
| Tài liệu | [Docs workflow](../.github/workflows/docs.yml), `script/doc-quality-check` | Cặp EN/VI và liên kết nội bộ | Mọi giả định vận hành đều đúng |
| Vòng đời khóa | `lib/tasks/vault_keys.rake`, `script/kek-recovery-check` | Câu lệnh và kiểm tra kho phục hồi độc lập | Phục hồi được KEK production đã mất |
| Backup và DR | `script/backup-db`, `script/verify-backup`, `script/dr-rehearsal` | Có quy trình backup mã hóa và phục hồi canary | Download offsite và restore thành công trên host chưa thử |
| Nghiệm thu host | `script/live-host-acceptance`, `script/production-acceptance` | Điều kiện nghiệp vụ kiểm tra | Đã chạy kiểm tra trên máy của người dùng |
| Accessibility | `test/system/`, [Test plan](ACCESSIBILITY-TEST-PLAN.vi.md) | Kiểm tra tự động và bước manual cần thực hiện | Chứng nhận WCAG chính thức |

## Cách xác minh tuyên bố CI

1. Lấy SHA của bản phát hành: `git rev-parse HEAD` và `git rev-parse v1.0.0^{}`.
2. Mở [GitHub Actions](https://github.com/dangkhoa2016/Rails-8-Envelope-Encryption-Vault/actions), xác định job đã hoàn tất trên **đúng SHA**.
3. Đọc log, các lần rerun, bước bị skip và điều kiện môi trường.
4. Chạy lại sau khi rewrite Git history; workflow cũ vẫn thuộc commit object cũ.
5. Ghi đúng trạng thái **PASS**, **FAIL**, **NOT RUN**, hoặc **PENDING**; không lấy giả định thay bằng chứng.

Lần review công bố mã nguồn đầu tiên ghi nhận **6/6 job CI PASS** và docs workflow PASS cho commit ở thời điểm đó. Đây là bằng chứng lịch sử, không phải cam kết cho SHA sau rewrite.

## Bằng chứng phục hồi dữ liệu giả

Một DR rehearsal đáng tin cần:

- Archive mã hóa có định danh, kiểm SHA-256 và giải mã wrapper thành công.
- Tải archive từ đúng remote offsite, không chỉ mở lại file cục bộ.
- Restore vào database mới có kiểm soát; database nguồn không đổi.
- Lấy age identity và mọi KEK liên quan từ các nơi quản lý độc lập.
- Giải mã thành công **canary giả cụ thể** và dọn môi trường diễn tập.
- Log đã che dữ liệu riêng tư và kết luận operator phù hợp với bằng chứng.

Chỉ kiểm checksum và `pg_restore --list` là kiểm tra một phần, **chưa phải DR PASS đầy đủ**.

## Không công bố trong bằng chứng

- Vault KEK thô, AWS credential, API token, age identity và mật khẩu.
- Archive ciphertext cá nhân, database thật và thông tin đăng nhập.
- Địa chỉ hạ tầng riêng, log sự cố và dữ liệu tài khoản chưa được phép công bố.
- Tuyên bố đã được audit, pentest, chứng nhận hoặc promote khi chưa có bằng chứng kiểm tra độc lập.

Xem [Ma trận kiểm chứng](qualification.vi.md), [Tái lập](reproducibility.vi.md) và [Ma trận kiểm chứng](qualification.vi.md).

## Checklist người review

```text
Revision/tag và SHA:
Trạng thái CI, URL run:
Phạm vi test / ma trận phiên bản:
Tài liệu, cặp ngôn ngữ và link:
Synthetic DR reference (không chứa secret):
Bằng chứng host hoặc PENDING:
Ngoại lệ, rủi ro và phê duyệt vận hành:
```

Không đăng artifact nhạy cảm lên issue công khai chỉ để chứng minh PASS.
