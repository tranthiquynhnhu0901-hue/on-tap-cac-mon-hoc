# Hệ thống trắc nghiệm - Quản trị học

Bản nền tảng này đã có Chương 4 với 40 câu lấy nguyên văn từ tài liệu nguồn.

## Cấu trúc
- `index.html`: Trang chủ → Môn học → Chương.
- `quiz.html`: Nhập Họ tên + Lớp, làm bài, nộp rồi mới xem đáp án/giải thích/nội dung thuộc.
- `admin.html`: Trang giáo viên xem kết quả sau khi cấu hình Supabase Auth.
- `data/chapter4.json`: dữ liệu Chương 4 dùng cho chế độ xem thử cục bộ.
- `supabase_schema.sql`: tạo database, hàm lưu bài, chấm bài, nhật ký giám sát và seed 40 câu Chương 4.
- `config.js`: điền URL và Anon/Publishable Key của Supabase.

## Logic đã cài
1. Bắt buộc nhập Họ tên + Lớp trước khi làm.
2. Tự lưu từng đáp án vào database khi chọn.
3. Nếu thoát/tải lại khi bài chưa nộp, mở lại bằng cùng Họ tên + Lớp sẽ tiếp tục lượt đang dở.
4. Chỉ cho nộp khi đủ 40/40 câu.
5. Chỉ sau khi nộp mới trả về đáp án đúng, giải thích, nội dung thuộc và meme theo điểm.
6. Mỗi lần nộp xong rồi làm lại tạo một lượt mới; lịch sử cũ không bị ghi đè.
7. Từ lượt thứ 3 của cùng người + lớp + chương: bật ghi nhật ký rời tab, mất focus, thoát fullscreen, reload/rời trang, và phát hiện hai phiên trình duyệt cùng hoạt động thông qua heartbeat.
8. Nhật ký giám sát chỉ hiện trong phần kết quả sau khi nộp.

## Quan trọng về giới hạn trình duyệt
Website không thể đọc trực tiếp danh sách ứng dụng/trình duyệt khác trên máy. Cơ chế giám sát dùng các tín hiệu website được phép truy cập: `visibilitychange`, `blur`, `fullscreenchange`, `pagehide`, và heartbeat để phát hiện phiên đồng thời. Đây là ghi nhận tín hiệu, không phải bằng chứng tuyệt đối về hành vi gian lận.

## Cấu hình Supabase
1. Tạo project tại Supabase.
2. SQL Editor → dán toàn bộ `supabase_schema.sql` → Run.
3. Project Settings / API → lấy Project URL và Anon/Publishable Key.
4. Điền vào `config.js`.
5. Authentication → Users → tạo tài khoản giáo viên.
6. Copy UUID user, chạy:
   `insert into teacher_profiles(user_id) values ('UUID-CUA-GIAO-VIEN');`
7. Upload toàn bộ thư mục này lên repository GitHub Pages.

## GitHub Pages
Repository hiện tại của bạn: `tranthiquynhnhu0901-hue/cau-hoi-trac-nghiem`
- Upload các file ở thư mục gốc.
- Settings → Pages → Deploy from a branch → `main` → `/ (root)` → Save.
- Link dự kiến: `https://tranthiquynhnhu0901-hue.github.io/cau-hoi-trac-nghiem/`

## Chế độ xem thử
Nếu `config.js` chưa có Supabase, hệ thống chạy `DEMO_FALLBACK` bằng localStorage để bạn kiểm tra giao diện. Chế độ này KHÔNG phải lưu dữ liệu tập trung. Khi dùng thật cho lớp, phải cấu hình Supabase.
