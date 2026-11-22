# Firmware Olympus cho Xteink X4 Pro

File: `crosspoint-2.0.0-olympus-x4pro.bin`
SHA-256: `264f0ff089ed31a1f7896e6569e104383ee7fe19ffdce7693857781e1a5c1400`

Đây là CrossPoint 2.0.0 chính thức, cộng tính năng % tiến độ đọc trong Thư viện (bản trước), cộng trò chơi Olympus theo RULES.md.

> **Lưu ý quan trọng:** bản này mới chỉ được build thành công và chạy qua bộ test trên máy tính (908/908 test đạt). Nó **chưa được thử trên máy X4 Pro thật**. Hãy sao lưu trước khi flash và đọc phần "Quay lại bản cũ" bên dưới.

## Có gì mới

- **Màn hình chính** có thêm mục **Olympus** (ngay dưới Thư viện), ví dụ `Olympus · 2 trứng · 12/90`. Dấu `•` ở cuối nghĩa là có nhân vật mới chưa xem.
- **Thư viện → tab Gần đây → giữ OK trên một cuốn sách → "Đặt vào lò ấp"**. Sách đang ấp hiện `Đang ấp N%` thay cho phần trăm đọc.
- **Màn hình ngủ Olympus** tự bật khi bạn đặt quả trứng đầu tiên vào lò ấp. Ngoài ra, trong Olympus, mở hồ sơ một nhân vật đã nở và chạm "Đặt làm màn chờ" (hoặc bấm OK): nhân vật đó thành bạn đồng hành trên màn hình ngủ. Muốn bật ngay sau khi cài: vào Cài đặt → Hiển thị → Màn hình ngủ và chọn "Olympus".
- **Cảm ứng:** chạm vào ô Lò ấp, Đền thờ, quả trứng hoặc nhân vật để mở; chạm ô trống trong Lò ấp để sang Thư viện chọn sách; nhấn giữ một ô Lò ấp để bỏ trứng; trong Đền thờ vuốt lên/xuống để lật trang, chạm tab Đất sét/Bạc/Vàng để đổi bậc; trong hồ sơ vuốt trái/phải để xem nhân vật kế tiếp; vuốt từ mép trái để quay lại, nút tròn để về Home. Lò ấp, Đền thờ và hồ sơ có nút "Quay lại" ở giữa phía dưới (cạnh nút hành động nếu có); "Quay lại" từ hồ sơ luôn về Đền thờ. Màn Olympus chính dùng nút tròn để về Home.
- **Truyện tranh (XTC) không có mục lục:** bấm OK hoặc chạm mở menu sẽ hiện thanh kéo % để nhảy tới trang bất kỳ.
- **Ngôn ngữ:** Olympus theo ngôn ngữ trong Cài đặt. Chọn Tiếng Việt thì Olympus hiện tiếng Việt; chọn bất kỳ ngôn ngữ nào khác thì Olympus hiện tiếng Anh (cả 90 hồ sơ nhân vật). Tên nhân vật giữ nguyên.
- Mọi thứ khác giữ nguyên, kể cả % tiến độ đọc.

## Cách chơi (tóm tắt)

**Giai đoạn 1: sưu tập 90 nhân vật**
- Lò ấp có 3 ô. Đặt một cuốn sách vào ô trống (phần đã đọc trước đó được tính luôn cho trứng), trứng sẽ là Đất sét (≤200 trang), Bạc (201–499) hoặc Vàng (≥500).
- % của trứng đi theo vị trí đang đọc: kéo tới đâu trứng theo tới đó, kéo lùi thì trứng lùi theo. Tới 95% cuốn sách thì trứng nở ngay trong lúc đọc (không cần lật qua chú thích, credit ở cuối); bấm Back để quay lại sách.
- Trứng không được đọc 7 ngày sẽ thành trứng nguội. Bỏ trứng lúc nào cũng được (giữ OK hoặc nhấn giữ ô trong Lò ấp); nhân vật trong trứng được giữ chỗ cho quả sau.
- Đền thờ hiển thị 3 tầng × 30 nhân vật (chạm tab hoặc giữ Trái/Phải để đổi tầng).

**Bạn đồng hành** (có ngay khi đã nở nhân vật đầu tiên)
- Nhân vật đặt làm màn chờ là bạn đồng hành: mở hồ sơ và chạm "Đặt làm màn chờ" (hoặc bấm OK). Chỉ sách cùng độ dày với bậc của nhân vật mới được tính.
- Khi đủ 90/90, lò ấp đóng lại và chỉ còn nuôi bạn đồng hành.
- Mục tiêu mỗi ngày: 5 / 10 / 20 trang theo tầng; sinh vật đọc đủ 5 trang là được ăn cho ngày hôm đó.
- Đất sét bỏ đi sau 3 ngày không đọc; Bạc và Vàng chuyển sang trạng thái tàn lửa.

## Dữ liệu trên thẻ SD

- Mọi dữ liệu Olympus nằm trong `/.crosspoint/olympus/` (`state.bin` và thư mục `pages/`).
- Không đụng tới file vị trí đọc, file tiến độ hay cài đặt hiện có. Muốn chơi lại từ đầu thì xoá thư mục `/.crosspoint/olympus/`.
- Hình nhân vật nằm sẵn trong firmware, không cần chép gì vào thẻ.

## Trước khi flash

1. Chép thư mục `.crosspoint` trên thẻ SD sang máy tính để sao lưu.
2. Sạc pin trên 50%.
3. Giữ sẵn file bản cũ để quay lại: `/mnt/project-files/reading-progress/crosspoint-2.0.0-reading-progress-x4pro.bin`, hoặc bản CrossPoint 2.0.0 chính thức.
4. (Tuỳ chọn) Trong web flasher, chọn **Full flash controls → Save full flash** để sao lưu toàn bộ máy (khoảng 25 phút).

## Flash từ thẻ SD (khuyên dùng)

1. Chép `crosspoint-2.0.0-olympus-x4pro.bin` vào thư mục gốc thẻ SD rồi lắp lại vào máy.
2. Trên máy: **Cài đặt → Hệ thống → Cập nhật firmware từ thẻ SD**.
3. Chọn file `.bin`. Máy sẽ kiểm tra file trước khi ghi và từ chối nếu file không dành cho X4 Pro.
4. Chờ máy ghi xong và khởi động lại. Không tắt máy khi đang ghi.

## Flash qua USB (cách khác)

1. Nối X4 Pro với máy tính qua bộ chuyển USB chân pogo, đánh thức máy về màn hình chính.
2. Mở https://crosspointreader.com/#flash-tools bằng Chrome hoặc Edge.
3. Chọn **Xteink X4Pro → Custom .bin**, chọn `crosspoint-2.0.0-olympus-x4pro.bin`.
4. Bấm Flash và chọn máy trong danh sách cổng serial.
5. Xong thì bấm **Reset**, rồi giữ **Nguồn** 3–5 giây để bật máy.

## Kiểm tra sau khi flash

1. Màn hình chính có mục Olympus; mở nó thấy Lò ấp, Đền thờ.
2. Thư viện vẫn hiện % đọc như trước.
3. Đặt một cuốn ngắn vào lò ấp, đọc vài trang, quay ra: Thư viện hiện `Đang ấp N%`.
4. Mở một cuốn sách cũ: vị trí đọc vẫn còn.

## Quay lại bản cũ

- **Về bản % tiến độ đọc (không có Olympus):** làm như bước flash từ thẻ SD nhưng chọn `crosspoint-2.0.0-reading-progress-x4pro.bin`.
- **Về CrossPoint 2.0.0 chính thức:** tải file `.bin` cho X4 Pro ở trang Releases của github.com/crosspoint-reader/crosspoint-reader, chép vào thẻ SD và chọn trong **Cập nhật firmware từ thẻ SD**; hoặc qua USB chọn bản CrossPoint chính thức cho Xteink X4Pro thay vì Custom .bin.
- **Nếu máy không khởi động bình thường:** giữ **Xuống** rồi bấm **Nguồn**, máy sẽ vào thẳng trình chọn firmware trên thẻ SD.
- Dữ liệu Olympus vẫn nằm trên thẻ khi quay về bản cũ (bản cũ chỉ bỏ qua nó). Nếu đã chọn màn hình ngủ "Olympus", bản cũ sẽ tự trở về màn hình ngủ mặc định.

Không dùng Xteink Unlocker cho file này.

## Giới hạn đã biết

- Cả 90 nhân vật đều có hình. 18 hình lấy từ bộ thiết kế v5-ui; 72 hình còn lại được vẽ thêm cùng phong cách, nằm trong `reading-game/v6-sprites/`.
- Số trang EPUB là ước tính (khoảng 2 KB chữ mỗi trang), nên có thể khác số trang hiện trên máy. XTC dùng số trang thật.
- Trứng nở khi vị trí đọc tới 95% (hoặc khi tới màn hình hết sách), không kiểm tra số trang đã xem.
- "Đặt vào lò ấp" chỉ có ở tab Gần đây của Thư viện (sách phải được mở ít nhất một lần).
- Màu xám được vẽ bằng chấm (dither), không phải xám thật.
- Nếu đồng hồ của máy chưa được đặt giờ (chưa từng nối Wi-Fi), ngày không được tính.
- Chưa thử trên máy thật.

## Dành cho người build

- `olympus-on-reading-progress-2.0.0.patch`: áp sau `reading-progress-2.0.0.patch` trên tag 2.0.0.
- `crosspoint-2.0.0-olympus-full.patch`: áp thẳng lên tag 2.0.0 (gồm cả % tiến độ đọc).
- Build: `pio run -e x4pro-gh_release`. Firmware 5,75 MB / 6,25 MB phân vùng app (87,7%), RAM 34,2%.
- Hình nhân vật: `python3 scripts/olympus_sprites.py <v5-ui/sprites>:<v6-sprites/sprites> src/olympus/OlympusSprites.h`.
- `previews/`: ảnh mô phỏng các màn hình (vẽ trên máy tính, không phải ảnh chụp máy thật).
