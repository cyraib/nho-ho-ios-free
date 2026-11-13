# Build iOS miễn phí bằng Windows + iPhone

Luồng này **không yêu cầu bạn mua Mac hoặc đăng ký Apple Developer trả phí**: GitHub Actions dùng runner macOS để biên dịch; bạn ký/cài IPA bằng Apple Account của mình qua AltStore Classic trên Windows. Chưa có IPA cho tới khi workflow chạy thành công.

## 1. Chuẩn bị repository

Tạo lại gói nguồn sau mỗi lần sửa mã iOS bằng `npm run ios:package` trên Windows hoặc macOS.

- Dùng gói `output/ios-free/NhoHo-iOS-Free-source.zip`. Đây là **mã nguồn để build**, không phải IPA. Gói chỉ chứa mã host iOS, icon, cấu hình build và workflow; không có `.env`, API token, ảnh nhật ký, database, thư mục `.tools` hay mã backend.
- Tạo repo GitHub rồi đưa **nội dung bên trong ZIP** vào gốc repo; cần giữ `.github/workflows/ios-free.yml` và `ios/` ở đúng vị trí. Trang web GitHub có thể bỏ qua thư mục bắt đầu bằng dấu chấm khi kéo thả; nếu thiếu, tạo file `.github/workflows/ios-free.yml` riêng bằng **Add file → Create new file** và dán nội dung tương ứng.
- Runner tiêu chuẩn của repo công khai miễn phí. Chỉ chọn công khai nếu bạn đồng ý công khai mã nguồn trong gói.
- Repo riêng dùng hạn mức Actions đi kèm tài khoản. Kiểm tra hạn mức, giới hạn chi tiêu về 0/không cho vượt phí trước khi chạy. Workflow mặc định bỏ qua repo riêng; chỉ đánh dấu `allow_private_quota` sau khi kiểm tra. Không có lời hứa dùng repo riêng miễn phí vô hạn.
- Workflow chỉ chạy khi bạn bấm Run workflow; không tự chạy khi push/PR. Artifact được giữ một ngày để giảm sử dụng lưu trữ, nên tải xuống ngay.

## 2. Build IPA trên GitHub

1. Vào **Actions → iOS free development IPA → Run workflow**.
2. `app_origin` có thể để trống. Nếu đã có URL Nhớ Hộ, nhập địa chỉ gốc HTTPS, ví dụ `https://ten-app.vercel.app`, không kèm `/path`, query hay token.
3. Khi job thành công, tải artifact **NhoHo-Free-unsigned**, giải nén để lấy `NhoHo-Free-unsigned.ipa`.
4. IPA này chưa ký. Không thể chạm file để tự cài lên iPhone. Không nhập Apple ID/password/certificate vào GitHub.

## 3. Cài bằng Windows

1. Làm theo [hướng dẫn Windows chính thức của AltStore](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows): cài AltServer và các thành phần Apple mà hướng dẫn yêu cầu.
2. Kết nối iPhone với Windows, chọn Trust trên iPhone. Cài AltStore Classic bằng AltServer. Tự nhập Apple Account/2FA trong công cụ chính thức; không gửi mật khẩu vào chat hoặc repository.
3. Bật Developer Mode theo yêu cầu trên iPhone. Trong AltStore, dùng **My Apps → +** để chọn IPA đã tải về (chuyển file sang Files trên iPhone trước nếu cần).
4. Mở Nhớ Hộ và nhập URL HTTPS của ứng dụng nếu lúc build đã để trống. Giao diện/API mới phải được deploy lên URL đó trước.
5. Giữ AltServer khả dụng khi refresh. Tài khoản miễn phí có profile khoảng 7 ngày; cần refresh/cài lại theo giới hạn của Apple. Apple giới hạn ba app cài kiểu này trên một thiết bị; AltStore cũng dùng một chỗ.

## Phạm vi bản miễn phí

- Là ứng dụng iOS thật chứa WKWebView và giao diện web đã có; không phải bản viết lại toàn bộ bằng SwiftUI và không đóng gói sẵn HTML/JS vào IPA.
- Giữ lịch/nhật ký theo web triển khai, camera/thư viện ảnh, native share sheet xuất JSON/ICS, kho web riêng trong ứng dụng. Cần mạng để tải giao diện lần đầu. Chưa xác minh camera trên iPhone thật.
- Không có App Groups, widget màn hình chính, APNs hay iCloud trong target `NhoHoFree`. Xem trước widget trong web vẫn có. Mã widget cũ được giữ ở project khác; không bị nhúng vào IPA miễn phí.
- Web Push của Safari PWA không biến thành native push trong WKWebView. Chưa triển khai local notification/APNs cho host này.
- Safari/PWA và ứng dụng có kho riêng; xuất/nhập backup để chuyển lịch và nhật ký. Khóa kết nối bạn bè không nằm trong backup.
- Không phát hành App Store/TestFlight. Chưa có chữ ký, bản cài đã kiểm chứng hay dịch vụ build trả phí được kích hoạt.

## Build trực tiếp nếu sau này có Mac

```sh
brew install xcodegen
bash ios/build-free.sh
```

Để cài trực tiếp từ Xcode: mở `ios/NhoHoFree.xcodeproj`, chọn Personal Team, đổi Bundle Identifier nếu trùng, chọn iPhone rồi Run. Không thêm App Groups/Push capabilities vào target miễn phí.

Nguồn: [Apple Personal Team](https://developer.apple.com/help/account/basics/about-your-developer-account), [GitHub Actions billing](https://docs.github.com/en/actions/concepts/billing-and-usage), [AltStore và chu kỳ refresh](https://faq.altstore.io/altstore-classic/your-altstore).
