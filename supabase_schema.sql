
-- HỆ THỐNG TRẮC NGHIỆM - Supabase/PostgreSQL
-- Chạy toàn bộ file này trong Supabase > SQL Editor một lần.
create extension if not exists pgcrypto;

create table if not exists subjects(id uuid primary key default gen_random_uuid(), slug text unique not null, name text not null, created_at timestamptz default now());
create table if not exists chapters(id uuid primary key default gen_random_uuid(), subject_id uuid not null references subjects(id) on delete cascade, slug text unique not null, title text not null, sort_order int not null default 0, is_active boolean not null default true, created_at timestamptz default now());
create table if not exists questions(id uuid primary key default gen_random_uuid(), chapter_id uuid not null references chapters(id) on delete cascade, question_no int not null, section_label text, question_text text not null, option_a text not null, option_b text not null, option_c text not null, option_d text not null, correct_option text not null check(correct_option in('A','B','C','D')), explanation text, topic text, unique(chapter_id,question_no));
create table if not exists attempts(id uuid primary key default gen_random_uuid(), chapter_id uuid not null references chapters(id), full_name text not null, class_name text not null, identity_key text not null, browser_id text, attempt_number int not null, status text not null default 'active' check(status in('active','submitted')), monitoring_required boolean not null default false, started_at timestamptz not null default now(), submitted_at timestamptz, score int, total_questions int, percent numeric(5,2), active_session_token text, active_session_seen_at timestamptz, concurrent_detected boolean not null default false);
create index if not exists attempts_identity_idx on attempts(identity_key,chapter_id,status);
create table if not exists attempt_answers(attempt_id uuid not null references attempts(id) on delete cascade, question_id uuid not null references questions(id), selected_option text not null check(selected_option in('A','B','C','D')), is_correct boolean, updated_at timestamptz default now(), primary key(attempt_id,question_id));
create table if not exists monitor_events(id bigserial primary key, attempt_id uuid not null references attempts(id) on delete cascade, session_token text, event_type text not null, event_detail jsonb not null default '{}'::jsonb, occurred_at timestamptz not null default now());
create table if not exists teacher_profiles(user_id uuid primary key references auth.users(id) on delete cascade, created_at timestamptz default now());

alter table subjects enable row level security; alter table chapters enable row level security; alter table questions enable row level security; alter table attempts enable row level security; alter table attempt_answers enable row level security; alter table monitor_events enable row level security; alter table teacher_profiles enable row level security;

-- Không cấp SELECT trực tiếp questions cho anon để tránh lộ đáp án.
revoke all on subjects,chapters,questions,attempts,attempt_answers,monitor_events from anon;


insert into subjects(slug,name) values('quan-tri-hoc','Quản trị học') on conflict(slug) do update set name=excluded.name;
insert into chapters(subject_id,slug,title,sort_order,is_active) select id,'chuong-4','Chương 4. Văn hóa với quản trị của tổ chức',4,true from subjects where slug='quan-tri-hoc' on conflict(slug) do update set title=excluded.title,is_active=true;
delete from questions where chapter_id=(select id from chapters where slug='chuong-4');
insert into questions(chapter_id,question_no,section_label,question_text,option_a,option_b,option_c,option_d,correct_option,explanation,topic)
SELECT c.id, 1, '', 'Văn hóa dân tộc được hiểu phù hợp nhất là:', 'Tính cách giống nhau của mọi công dân', 'Hệ thống những giá trị, niềm tin và chuẩn mực được chia sẻ tương đối phổ biến trong một xã hội', 'Chỉ những truyền thống lễ hội', 'Hệ thống pháp luật của một quốc gia', 'B', 'Văn hóa dân tộc phản ánh những khuynh hướng giá trị, niềm tin và chuẩn mực được chia sẻ ở cấp độ xã hội, chứ không có nghĩa tất cả cá nhân đều giống nhau.', 'Mục 1.1. Khái niệm văn hóa dân tộc.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 2, '', 'Mô hình sáu chiều cạnh văn hóa quốc gia gắn với học giả nào?', 'Edgar Schein', 'Geert Hofstede', 'Peter Drucker', 'Frederick Taylor', 'B', 'Geert Hofstede phát triển mô hình nổi tiếng dùng để so sánh văn hóa quốc gia theo các chiều cạnh khác nhau.', 'Mục 1.4. Các chiều cạnh văn hóa dân tộc.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 3, '', 'Chiều cạnh phản ánh mức độ chấp nhận sự phân phối quyền lực không đồng đều là:', 'Individualism', 'Power Distance', 'Indulgence', 'Long-Term Orientation', 'B', 'Power Distance – khoảng cách quyền lực – liên quan đến mức độ những thành viên ít quyền lực hơn chấp nhận và kỳ vọng sự khác biệt quyền lực.', 'Mục 1.5. Khoảng cách quyền lực.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 4, '', 'Văn hóa thiên về tập thể thường nhấn mạnh:', 'Thành tích cá nhân tuyệt đối', 'Tính độc lập hoàn toàn', 'Nhóm và sự gắn kết', 'Loại bỏ quan hệ xã hội', 'C', 'Collectivism nhấn mạnh bản sắc nhóm, quan hệ và trách nhiệm tập thể.', 'Mục 1.6. Chủ nghĩa cá nhân và chủ nghĩa tập thể.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 5, '', 'Ai là học giả nổi bật với mô hình ba cấp độ văn hóa tổ chức?', 'Edgar Schein', 'Max Weber', 'Henri Fayol', 'Elton Mayo', 'A', 'Schein phân tích văn hóa qua artifacts, espoused values và basic underlying assumptions.', 'Mục 2.2. Ba cấp độ văn hóa tổ chức.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 6, '', 'Yếu tố nào thuộc cấp độ Artifacts?', 'Giả định sâu xa', 'Logo và nghi lễ', 'Niềm tin vô thức', 'Quan niệm nền tảng', 'B', 'Logo, biểu tượng, trang phục và nghi lễ là những biểu hiện hữu hình có thể quan sát.', 'Mục 2.2.1. Artifacts.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 7, '', 'Loại văn hóa nào trong Competing Values Framework nhấn mạnh đổi mới và thử nghiệm?', 'Clan', 'Adhocracy', 'Market', 'Hierarchy', 'B', 'Adhocracy Culture tập trung vào linh hoạt, đổi mới, thử nghiệm và thích nghi.', 'Mục 2.9. Văn hóa sáng tạo.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 8, '', 'Loại văn hóa nào nhấn mạnh quy trình, ổn định và kiểm soát?', 'Hierarchy', 'Clan', 'Adhocracy', 'Market', 'A', 'Hierarchy Culture ưu tiên trật tự, quy trình, độ tin cậy và kiểm soát.', 'Mục 2.11. Văn hóa thứ bậc.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 9, '', 'Quá trình giúp nhân viên mới học giá trị và chuẩn mực của tổ chức được gọi là:', 'Xã hội hóa tổ chức', 'Phân công lao động', 'Hoạch định', 'Chuyên môn hóa', 'A', 'Organizational socialization giúp thành viên mới học cách hành động phù hợp với tổ chức.', 'Mục 2.4.4. Xã hội hóa tổ chức.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 10, '', 'Một chức năng quan trọng của văn hóa là:', 'Loại bỏ hoàn toàn nhu cầu quản trị', 'Định hướng hành vi thành viên', 'Xóa bỏ sự khác biệt cá nhân', 'Thay thế mọi quy trình', 'B', 'Văn hóa tạo ra chuẩn mực chung và giúp thành viên nhận biết hành vi nào được chấp nhận.', 'Mục 3.1. Bản chất của tác động.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 11, 'PHẦN II. 5 CÂU TRẮC NGHIỆM MỨC KHÁ', 'Một tổ chức tuyên bố “sáng tạo là giá trị cốt lõi” nhưng mọi đề xuất mới đều phải qua nhiều cấp phê duyệt. Điều này cho thấy:', 'Sự phù hợp hoàn toàn giữa văn hóa và cơ cấu', 'Khoảng cách giữa giá trị tuyên bố và thực tiễn', 'Văn hóa Clan rất mạnh', 'Không tồn tại văn hóa tổ chức', 'B', 'Giá trị được tuyên bố chỉ trở thành văn hóa thực sự khi được thể hiện trong hành vi và hệ thống quản trị.', 'Mục 2.2 và Mục 3.4.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 12, 'PHẦN II. 5 CÂU TRẮC NGHIỆM MỨC KHÁ', 'Điểm khác nhau quan trọng giữa văn hóa mạnh và văn hóa phù hợp là:', 'Văn hóa mạnh luôn phù hợp', 'Văn hóa phù hợp luôn yếu', 'Văn hóa mạnh nói về mức độ chia sẻ, còn văn hóa phù hợp nói về sự tương thích với chiến lược và môi trường', 'Hai khái niệm hoàn toàn giống nhau', 'C', 'Một văn hóa có thể được chia sẻ rất mạnh nhưng nếu các giá trị không phù hợp với môi trường thì vẫn có thể làm giảm hiệu quả.', 'Mục 2.5 và 3.12.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 13, 'PHẦN II. 5 CÂU TRẮC NGHIỆM MỨC KHÁ', 'Trong một tổ chức, phòng R&D thích thử nghiệm trong khi phòng tài chính đề cao quy trình chặt chẽ. Đây là biểu hiện của:', 'Văn hóa dân tộc', 'Các văn hóa bộ phận', 'Không có văn hóa', 'Chỉ có văn hóa yếu', 'B', 'Các bộ phận có chức năng khác nhau có thể phát triển những subculture khác nhau trong cùng một tổ chức.', 'Mục 2.6. Văn hóa chủ đạo và văn hóa bộ phận.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 14, 'PHẦN II. 5 CÂU TRẮC NGHIỆM MỨC KHÁ', 'Một doanh nghiệp hoạt động trong ngành công nghệ biến động cao nhưng có văn hóa cực kỳ cứng nhắc và tránh thử nghiệm. Vấn đề lớn nhất là:', 'Văn hóa quá mạnh', 'Văn hóa không phù hợp với yêu cầu môi trường', 'Nhân viên có quá nhiều quyền', 'Doanh nghiệp không có giá trị', 'B', 'Hiệu quả văn hóa phụ thuộc vào mức độ phù hợp giữa văn hóa, chiến lược và môi trường.', 'Mục 3.12. Tác động đến hiệu quả tổ chức.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 15, 'PHẦN II. 5 CÂU TRẮC NGHIỆM MỨC KHÁ', 'Nếu doanh nghiệp muốn xây dựng văn hóa làm việc nhóm nhưng phần thưởng chỉ dựa vào cạnh tranh cá nhân, tổ chức đang gặp vấn đề gì?', 'Hệ thống nhân sự không phù hợp với giá trị văn hóa mong muốn', 'Khoảng cách quyền lực thấp', 'Văn hóa quốc gia quá mạnh', 'Thiếu cơ cấu thứ bậc', 'A', 'Văn hóa phải được hỗ trợ bằng hệ thống đánh giá và khen thưởng tương thích.', 'Mục 3.6. Động lực và quản trị nhân lực.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 16, 'PHẦN III. 5 CÂU TRẮC NGHIỆM MỨC KHÓ', 'Một công ty có tỷ lệ nghỉ việc thấp, nhân viên rất trung thành và chia sẻ mạnh giá trị “không thay đổi khi chưa thật cần thiết”. Khi công nghệ ngành thay đổi nhanh, công ty phản ứng rất chậm. Nhận định phù hợp nhất là:', 'Văn hóa mạnh luôn tạo lợi thế', 'Văn hóa mạnh có thể trở thành rào cản nếu giá trị không còn phù hợp', 'Công ty có văn hóa yếu', 'Công ty cần tăng thêm nghi lễ', 'B', 'Mức độ chia sẻ mạnh không bảo đảm hiệu quả. Nếu các giá trị hỗ trợ sự ổn định trong khi môi trường yêu cầu thay đổi nhanh, văn hóa mạnh có thể làm giảm khả năng thích nghi.', 'Mục 2.5 và 3.10.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 17, 'PHẦN III. 5 CÂU TRẮC NGHIỆM MỨC KHÓ', 'Một nhà quản trị nước ngoài áp dụng phong cách tranh luận trực tiếp và yêu cầu nhân viên thường xuyên phản biện cấp trên. Nhân viên tại chi nhánh lại rất ít phát biểu. Phân tích hợp lý nhất là:', 'Nhân viên chắc chắn thiếu năng lực', 'Có thể tồn tại khác biệt về khoảng cách quyền lực và chuẩn mực văn hóa', 'Công ty không có văn hóa', 'Đây chỉ là vấn đề tiền lương', 'B', 'Kỳ vọng về việc phản biện người có quyền lực có thể khác nhau giữa các nền văn hóa. Nhà quản trị cần xem xét bối cảnh trước khi kết luận về năng lực hay động lực cá nhân.', 'Mục 1.5 và 1.3.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 18, 'PHẦN III. 5 CÂU TRẮC NGHIỆM MỨC KHÓ', 'Một công ty ghi “khách hàng là số một” trong mọi tài liệu nhưng thường khen thưởng nhân viên tiết kiệm chi phí ngay cả khi việc đó làm giảm chất lượng phục vụ. Theo mô hình Schein, điều nào quan trọng nhất để đánh giá văn hóa thực tế?', 'Chỉ đọc tuyên bố giá trị', 'Quan sát hành vi và những giả định thực sự thể hiện trong quyết định', 'Chỉ nhìn logo', 'Chỉ hỏi người sáng lập', 'B', 'Espoused values có thể khác với những giả định và hành vi thực tế. Muốn hiểu văn hóa phải phân tích sâu hơn những gì tổ chức thực sự làm.', 'Mục 2.2. Ba cấp độ văn hóa tổ chức.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 19, 'PHẦN III. 5 CÂU TRẮC NGHIỆM MỨC KHÓ', 'Một công ty muốn đổi từ văn hóa kiểm soát sang văn hóa đổi mới. Công ty chỉ thay slogan thành “Hãy sáng tạo hơn”. Kết quả gần như không thay đổi. Nguyên nhân hợp lý nhất là:', 'Văn hóa chỉ cần thay bằng khẩu hiệu khác', 'Các hệ thống, hành vi lãnh đạo và cơ chế khen thưởng chưa được thay đổi', 'Tổ chức không nên thay đổi văn hóa', 'Mọi nhân viên đều chống đổi mới', 'B', 'Thay đổi văn hóa đòi hỏi sự nhất quán giữa lãnh đạo, hệ thống nhân sự, quy trình và hành vi, chứ không chỉ là thông điệp truyền thông.', 'Mục 3.13. Quản trị và thay đổi văn hóa.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 20, 'PHẦN III. 5 CÂU TRẮC NGHIỆM MỨC KHÓ', 'Một nền văn hóa “kết quả bằng mọi giá” giúp doanh số tăng nhanh nhưng đồng thời xuất hiện hành vi che giấu sai phạm. Kết luận phù hợp nhất là:', 'Văn hóa càng cạnh tranh càng tốt', 'Văn hóa có thể tạo động lực mạnh nhưng cũng có thể khuyến khích hành vi phi đạo đức nếu giá trị bị lệch', 'Văn hóa không ảnh hưởng đạo đức', 'Chỉ cần tăng mục tiêu bán hàng', 'B', 'Văn hóa tạo ra chuẩn mực về điều được coi là chấp nhận được. Nếu tổ chức chỉ khen thưởng kết quả mà bỏ qua phương thức đạt kết quả, hành vi sai có thể được củng cố.', 'Mục 3.11. Tác động đến đạo đức.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 21, 'PHẦN IV. 20 CÂU TRẮC NGHIỆM TÌNH HUỐNG THỰC TẾ', 'Một công ty đa quốc gia nhận thấy nhân viên ở chi nhánh A thường chờ trưởng phòng quyết định, trong khi nhân viên ở chi nhánh B chủ động tranh luận với cấp trên. Sự khác biệt này có thể liên quan rõ nhất đến:', 'Khoảng cách quyền lực', 'Quản trị khoa học', 'Phân công lao động', 'Văn hóa Market', 'A', 'Power Distance ảnh hưởng đến mức độ chấp nhận chênh lệch quyền lực và kỳ vọng về quan hệ cấp trên – cấp dưới.', 'Mục 1.5. Khoảng cách quyền lực.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 22, 'PHẦN IV. 20 CÂU TRẮC NGHIỆM TÌNH HUỐNG THỰC TẾ', 'Một doanh nghiệp muốn tăng động lực bằng thưởng cá nhân rất cao, nhưng nhân viên lại coi trọng thành tích của nhóm và cảm thấy hệ thống này gây cạnh tranh nội bộ. Yếu tố văn hóa nào cần được xem xét?', 'Individualism – Collectivism', 'Power Distance', 'Long-Term Orientation', 'Indulgence', 'A', 'Trong môi trường thiên về tập thể, hệ thống khen thưởng chỉ dựa trên cá nhân có thể không phù hợp với các giá trị nhóm.', 'Mục 1.6. Chủ nghĩa cá nhân – tập thể.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 23, 'PHẦN IV. 20 CÂU TRẮC NGHIỆM TÌNH HUỐNG THỰC TẾ', 'Một công ty rất khó triển khai cách làm mới vì nhân viên luôn yêu cầu quy trình chi tiết trước khi thử nghiệm. Điều này có thể liên quan đến:', 'Mức né tránh bất định cao', 'Khoảng cách quyền lực thấp', 'Văn hóa Clan', 'Chủ nghĩa cá nhân cao', 'A', 'Né tránh bất định cao thường đi kèm nhu cầu lớn hơn đối với sự rõ ràng, quy tắc và khả năng dự đoán.', 'Mục 1.8. Né tránh bất định.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 24, 'PHẦN IV. 20 CÂU TRẮC NGHIỆM TÌNH HUỐNG THỰC TẾ', 'Một doanh nghiệp chấp nhận lợi nhuận thấp trong vài năm để đầu tư mạnh vào công nghệ và năng lực tương lai. Điều này gần với:', 'Định hướng dài hạn', 'Khoảng cách quyền lực', 'Né tránh bất định', 'Văn hóa Hierarchy', 'A', 'Định hướng dài hạn nhấn mạnh khả năng chuẩn bị cho tương lai, kiên trì và đầu tư vào kết quả lâu dài.', 'Mục 1.9. Định hướng dài hạn – ngắn hạn.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 25, 'PHẦN IV. 20 CÂU TRẮC NGHIỆM TÌNH HUỐNG THỰC TẾ', 'Một nhân viên mới nhận thấy mọi người đều gọi tổng giám đốc bằng tên riêng, văn phòng không có phòng riêng cho lãnh đạo và nhân viên thường xuyên tranh luận trực tiếp trong họp. Những dấu hiệu quan sát được này thuộc:', 'Artifacts', 'Basic Assumptions', 'Môi trường kinh tế', 'Văn hóa dân tộc duy nhất', 'A', 'Cách bố trí không gian, cách xưng hô và hành vi trong cuộc họp là những biểu hiện hữu hình của văn hóa.', 'Mục 2.2.1. Artifacts.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 26, 'PHẦN IV. 20 CÂU TRẮC NGHIỆM TÌNH HUỐNG THỰC TẾ', 'Một công ty tuyên bố “an toàn là số một”, nhưng quản lý thường yêu cầu nhân viên bỏ qua bước kiểm tra để giao hàng nhanh hơn. Điều này thể hiện:', 'Sự nhất quán cao', 'Khoảng cách giữa giá trị tuyên bố và hành vi thực tế', 'Văn hóa mạnh tích cực', 'Xã hội hóa hiệu quả', 'B', 'Giá trị tuyên bố chỉ có ý nghĩa nếu hành vi quản lý và quyết định thực tế phù hợp với nó.', 'Mục 2.2.2 và 3.11.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 27, 'PHẦN IV. 20 CÂU TRẮC NGHIỆM TÌNH HUỐNG THỰC TẾ', 'Một câu chuyện về người sáng lập từng tự mình giao sản phẩm cho khách giữa đêm thường xuyên được kể cho nhân viên mới để nhấn mạnh tinh thần phục vụ. Đây là:', 'Một phương tiện truyền văn hóa', 'Một yếu tố kinh tế', 'Một chính sách tài chính', 'Một loại cơ cấu', 'A', 'Câu chuyện về người sáng lập có thể truyền tải những giá trị mà tổ chức coi trọng.', 'Mục 2.3. Các biểu hiện của văn hóa tổ chức.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 28, 'PHẦN IV. 20 CÂU TRẮC NGHIỆM TÌNH HUỐNG THỰC TẾ', 'Một doanh nghiệp tuyển người có chuyên môn tốt nhưng đồng thời đánh giá rất kỹ mức độ phù hợp với giá trị “hợp tác và minh bạch”. Hoạt động này góp phần:', 'Duy trì văn hóa thông qua tuyển chọn', 'Loại bỏ văn hóa', 'Giảm xã hội hóa', 'Làm văn hóa yếu đi', 'A', 'Tuyển chọn người phù hợp với các giá trị quan trọng là một cách duy trì văn hóa tổ chức.', 'Mục 2.4.3. Tuyển chọn nhân viên.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 29, 'PHẦN IV. 20 CÂU TRẮC NGHIỆM TÌNH HUỐNG THỰC TẾ', 'Một công ty tổ chức chương trình hội nhập một tháng để nhân viên mới học lịch sử, giá trị, cách phối hợp và những hành vi được mong đợi. Đây là:', 'Xã hội hóa tổ chức', 'Market Culture', 'Power Distance', 'Kiểm soát tài chính', 'A', 'Chương trình giúp thành viên mới học cách hành động và thích nghi với tổ chức chính là quá trình organizational socialization.', 'Mục 2.4.4. Xã hội hóa tổ chức.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 30, 'PHẦN IV. 20 CÂU TRẮC NGHIỆM TÌNH HUỐNG THỰC TẾ', 'Một công ty coi nhân viên như thành viên trong gia đình, nhấn mạnh cố vấn, hợp tác và phát triển con người. Văn hóa này gần nhất với:', 'Clan', 'Market', 'Hierarchy', 'Adhocracy', 'A', 'Clan Culture chú trọng quan hệ, cam kết, làm việc nhóm và phát triển con người.', 'Mục 2.8. Văn hóa gia đình.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 31, 'PHẦN IV. 20 CÂU TRẮC NGHIỆM TÌNH HUỐNG THỰC TẾ', 'Một startup khuyến khích nhân viên thử ý tưởng mới, chấp nhận một số thất bại và thường xuyên điều chỉnh sản phẩm. Đây là:', 'Adhocracy Culture', 'Hierarchy Culture', 'Market Culture thuần túy', 'Văn hóa yếu', 'A', 'Adhocracy ưu tiên đổi mới, linh hoạt, thử nghiệm và thích nghi.', 'Mục 2.9. Văn hóa sáng tạo.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 32, 'PHẦN IV. 20 CÂU TRẮC NGHIỆM TÌNH HUỐNG THỰC TẾ', 'Một công ty yêu cầu từng bộ phận đạt chỉ tiêu thị phần, liên tục so sánh thành tích với đối thủ và thưởng cao cho kết quả vượt mục tiêu. Đây gần nhất với:', 'Market Culture', 'Clan Culture', 'Hierarchy Culture', 'Văn hóa bộ phận', 'A', 'Market Culture tập trung mạnh vào cạnh tranh, thành tích và kết quả bên ngoài.', 'Mục 2.10. Văn hóa thị trường.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 33, 'PHẦN IV. 20 CÂU TRẮC NGHIỆM TÌNH HUỐNG THỰC TẾ', 'Một bệnh viện quy định rất rõ quy trình dùng thuốc, lưu hồ sơ và kiểm soát an toàn. Văn hóa phù hợp với hoạt động này có nhiều đặc điểm của:', 'Hierarchy Culture', 'Adhocracy Culture', 'Clan Culture duy nhất', 'Không cần văn hóa', 'A', 'Hierarchy Culture phù hợp với những hoạt động đòi hỏi độ chính xác, quy trình và tính ổn định cao.', 'Mục 2.11. Văn hóa thứ bậc.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 34, 'PHẦN IV. 20 CÂU TRẮC NGHIỆM TÌNH HUỐNG THỰC TẾ', 'Một công ty khuyến khích làm việc nhóm nhưng trưởng phòng luôn tự quyết mọi vấn đề và hiếm khi cho nhân viên phát biểu. Điều này sẽ:', 'Củng cố văn hóa tham gia', 'Làm giảm tính tin cậy của thông điệp văn hóa', 'Không ảnh hưởng gì', 'Tự động tạo văn hóa Clan', 'B', 'Hành vi lãnh đạo có vai trò mạnh trong việc hình thành văn hóa. Nếu lời nói và hành động mâu thuẫn, nhân viên thường tin vào hành động.', 'Mục 2.4.2 và 3.5.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 35, 'PHẦN IV. 20 CÂU TRẮC NGHIỆM TÌNH HUỐNG THỰC TẾ', 'Một công ty nói rằng “chất lượng quan trọng hơn tốc độ” nhưng nhân viên chỉ được thưởng theo số lượng sản phẩm hoàn thành. Hệ quả có khả năng nhất là:', 'Nhân viên ưu tiên số lượng hơn chất lượng', 'Văn hóa tự động trở nên mạnh', 'Nhân viên không quan tâm phần thưởng', 'Hệ thống đánh giá không liên quan văn hóa', 'A', 'Những hành vi được đo lường và khen thưởng thường gửi tín hiệu rất mạnh về điều tổ chức thực sự coi trọng.', 'Mục 3.6. Tác động đến động lực và quản trị nhân lực.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 36, 'PHẦN IV. 20 CÂU TRẮC NGHIỆM TÌNH HUỐNG THỰC TẾ', 'Một nhân viên phát hiện lỗi nghiêm trọng nhưng không báo cáo vì những người báo lỗi trước đây thường bị quản lý trách mắng. Vấn đề chính nằm ở:', 'Văn hóa giao tiếp và an toàn khi nêu vấn đề', 'Môi trường kinh tế', 'Định hướng dài hạn', 'Văn hóa quốc gia duy nhất', 'A', 'Nếu văn hóa trừng phạt người đưa tin xấu, thông tin quan trọng có thể bị che giấu, làm giảm chất lượng quyết định quản trị.', 'Mục 3.7. Tác động đến giao tiếp.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 37, 'PHẦN IV. 20 CÂU TRẮC NGHIỆM TÌNH HUỐNG THỰC TẾ', 'Một doanh nghiệp không có người giám sát trực tiếp tại mọi vị trí nhưng nhân viên vẫn tuân thủ rất tốt nguyên tắc an toàn vì “ở đây ai cũng làm vậy”. Điều này thể hiện:', 'Văn hóa đang thực hiện chức năng kiểm soát xã hội', 'Không tồn tại quản trị', 'Nhân viên không có tự chủ', 'Văn hóa yếu', 'A', 'Các chuẩn mực được chia sẻ mạnh có thể khiến thành viên tự điều chỉnh hành vi mà không cần kiểm soát trực tiếp liên tục.', 'Mục 3.8. Tác động đến kiểm soát.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 38, 'PHẦN IV. 20 CÂU TRẮC NGHIỆM TÌNH HUỐNG THỰC TẾ', 'Một công ty muốn đổi mới nhưng nhân viên sợ thử nghiệm vì mọi sai sót đều bị ghi vào đánh giá cuối năm. Biện pháp phù hợp nhất là:', 'Chỉ yêu cầu nhân viên sáng tạo hơn', 'Điều chỉnh cơ chế đánh giá và cách xử lý sai lầm hợp lý', 'Tăng hình phạt', 'Giảm trao đổi thông tin', 'B', 'Muốn xây dựng văn hóa đổi mới, hệ thống đánh giá phải không khiến nhân viên sợ mọi thử nghiệm.', 'Mục 3.9 và 3.13.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 39, 'PHẦN IV. 20 CÂU TRẮC NGHIỆM TÌNH HUỐNG THỰC TẾ', 'Một công ty thay CEO và muốn xây dựng văn hóa minh bạch. CEO mới công khai sai lầm của chính mình, khuyến khích phản biện và thay đổi hệ thống thưởng để ghi nhận người phát hiện vấn đề. Điều này thể hiện:', 'Thay đổi văn hóa bằng hành vi lãnh đạo và hệ thống hỗ trợ', 'Chỉ thay đổi khẩu hiệu', 'Không liên quan văn hóa', 'Chỉ thay đổi cơ cấu', 'A', 'Thay đổi văn hóa cần sự nhất quán giữa hành vi lãnh đạo và các hệ thống quản trị.', 'Mục 3.13. Quản trị và thay đổi văn hóa.' FROM chapters c WHERE c.slug='chuong-4'
UNION ALL
SELECT c.id, 40, 'PHẦN IV. 20 CÂU TRẮC NGHIỆM TÌNH HUỐNG THỰC TẾ', 'Một công ty rất thành công trong nhiều năm nhờ văn hóa chú trọng quy trình. Khi ngành chuyển sang công nghệ mới, chính văn hóa đó làm nhân viên phản đối thay đổi. Bài học quan trọng nhất là:', 'Một văn hóa từng tạo lợi thế vẫn có thể trở thành rào cản khi môi trường thay đổi', 'Văn hóa mạnh luôn tốt', 'Công ty không nên có văn hóa', 'Quy trình luôn làm tổ chức thất bại', 'A', 'Văn hóa chỉ tạo lợi thế khi còn phù hợp với chiến lược và môi trường. Giá trị từng giúp tổ chức thành công có thể trở thành lực cản nếu điều kiện thay đổi.', 'Mục 3.10 và 3.12.' FROM chapters c WHERE c.slug='chuong-4';


create or replace function norm_text(v text) returns text language sql immutable as $$ select lower(trim(regexp_replace(coalesce(v,''),'\s+',' ','g'))) $$;

create or replace function start_or_resume_attempt(p_chapter_slug text,p_full_name text,p_class_name text,p_browser_id text,p_session_token text)
returns table(attempt_id uuid,attempt_number int,monitoring_required boolean) language plpgsql security definer set search_path=public as $$
declare ch uuid; ik text; a attempts%rowtype; n int;
begin
 if length(trim(p_full_name))<2 or length(trim(p_class_name))<1 then raise exception 'Thiếu họ tên hoặc lớp'; end if;
 select id into ch from chapters where slug=p_chapter_slug and is_active=true; if ch is null then raise exception 'Chương chưa khả dụng'; end if;
 ik:=encode(digest(norm_text(p_full_name)||'|'||norm_text(p_class_name),'sha256'),'hex');
 select * into a from attempts where chapter_id=ch and identity_key=ik and status='active' order by started_at desc limit 1;
 if a.id is null then
   select count(*)+1 into n from attempts where chapter_id=ch and identity_key=ik and status='submitted';
   insert into attempts(chapter_id,full_name,class_name,identity_key,browser_id,attempt_number,monitoring_required,active_session_token,active_session_seen_at)
   values(ch,trim(p_full_name),trim(p_class_name),ik,p_browser_id,n,n>=3,p_session_token,now()) returning * into a;
 else
   update attempts set browser_id=coalesce(browser_id,p_browser_id) where id=a.id;
 end if;
 return query select a.id,a.attempt_number,a.monitoring_required;
end$$;

grant execute on function start_or_resume_attempt(text,text,text,text,text) to anon,authenticated;

create or replace function get_quiz_questions(p_chapter_slug text)
returns table(question_id uuid,question_no int,section_label text,question_text text,option_a text,option_b text,option_c text,option_d text)
language sql security definer set search_path=public as $$ select q.id,q.question_no,q.section_label,q.question_text,q.option_a,q.option_b,q.option_c,q.option_d from questions q join chapters c on c.id=q.chapter_id where c.slug=p_chapter_slug and c.is_active=true order by q.question_no $$;
grant execute on function get_quiz_questions(text) to anon,authenticated;

create or replace function get_saved_answers(p_attempt_id uuid)
returns table(question_id uuid,selected_option text) language sql security definer set search_path=public as $$ select question_id,selected_option from attempt_answers where attempt_id=p_attempt_id $$;
grant execute on function get_saved_answers(uuid) to anon,authenticated;

create or replace function save_answer(p_attempt_id uuid,p_question_id uuid,p_selected_option text)
returns void language plpgsql security definer set search_path=public as $$
begin
 if p_selected_option not in('A','B','C','D') then raise exception 'Đáp án không hợp lệ'; end if;
 if not exists(select 1 from attempts a join questions q on q.chapter_id=a.chapter_id where a.id=p_attempt_id and a.status='active' and q.id=p_question_id) then raise exception 'Lượt làm hoặc câu hỏi không hợp lệ'; end if;
 insert into attempt_answers(attempt_id,question_id,selected_option,is_correct,updated_at) values(p_attempt_id,p_question_id,p_selected_option,null,now()) on conflict(attempt_id,question_id) do update set selected_option=excluded.selected_option,is_correct=null,updated_at=now();
end$$;
grant execute on function save_answer(uuid,uuid,text) to anon,authenticated;

create or replace function log_monitor_event(p_attempt_id uuid,p_session_token text,p_event_type text,p_event_detail jsonb default '{}'::jsonb)
returns void language plpgsql security definer set search_path=public as $$
begin
 if exists(select 1 from attempts where id=p_attempt_id and status='active' and monitoring_required=true) then insert into monitor_events(attempt_id,session_token,event_type,event_detail) values(p_attempt_id,p_session_token,left(p_event_type,80),coalesce(p_event_detail,'{}'::jsonb)); end if;
end$$;
grant execute on function log_monitor_event(uuid,text,text,jsonb) to anon,authenticated;

create or replace function touch_attempt_session(p_attempt_id uuid,p_session_token text)
returns void language plpgsql security definer set search_path=public as $$
declare old_token text; old_seen timestamptz; mon boolean; already boolean;
begin
 select active_session_token,active_session_seen_at,monitoring_required,concurrent_detected into old_token,old_seen,mon,already from attempts where id=p_attempt_id and status='active' for update;
 if not found then return; end if;
 if mon and old_token is not null and old_token<>p_session_token and old_seen>now()-interval '30 seconds' and not already then
   insert into monitor_events(attempt_id,session_token,event_type,event_detail) values(p_attempt_id,p_session_token,'concurrent_session',jsonb_build_object('previous_session',old_token));
   update attempts set concurrent_detected=true where id=p_attempt_id;
 end if;
 update attempts set active_session_token=p_session_token,active_session_seen_at=now() where id=p_attempt_id;
end$$;
grant execute on function touch_attempt_session(uuid,text) to anon,authenticated;

create or replace function submit_attempt(p_attempt_id uuid,p_session_token text)
returns table(score int,total int,percent numeric,correct_count int,wrong_count int,attempt_number int,monitoring_required boolean,review jsonb,monitor_summary jsonb)
language plpgsql security definer set search_path=public as $$
declare a attempts%rowtype; qtotal int; acount int; sc int; rev jsonb; mon jsonb;
begin
 select * into a from attempts where id=p_attempt_id for update; if a.id is null then raise exception 'Không tìm thấy lượt làm'; end if; if a.status='submitted' then raise exception 'Bài này đã được nộp'; end if;
 select count(*) into qtotal from questions where chapter_id=a.chapter_id; select count(*) into acount from attempt_answers where attempt_id=a.id; if acount<>qtotal then raise exception 'Bạn chưa trả lời đủ tất cả câu hỏi'; end if;
 update attempt_answers aa set is_correct=(aa.selected_option=q.correct_option) from questions q where aa.attempt_id=a.id and q.id=aa.question_id;
 select count(*) into sc from attempt_answers where attempt_id=a.id and is_correct=true;
 update attempts set status='submitted',submitted_at=now(),score=sc,total_questions=qtotal,percent=round(sc*100.0/qtotal,2),active_session_seen_at=null where id=a.id;
 select jsonb_agg(jsonb_build_object('question_no',q.question_no,'question_text',q.question_text,'selected_option',aa.selected_option,'correct_option',q.correct_option,'options',jsonb_build_object('A',q.option_a,'B',q.option_b,'C',q.option_c,'D',q.option_d),'explanation',q.explanation,'topic',q.topic,'is_correct',aa.is_correct) order by q.question_no) into rev from attempt_answers aa join questions q on q.id=aa.question_id where aa.attempt_id=a.id;
 select jsonb_build_object('tab_hidden',count(*) filter(where event_type='tab_hidden'),'window_blur',count(*) filter(where event_type='window_blur'),'fullscreen_exit',count(*) filter(where event_type='fullscreen_exit'),'page_leave',count(*) filter(where event_type='page_leave'),'concurrent_session',count(*) filter(where event_type='concurrent_session'),'total_away_seconds',coalesce(sum(case when event_type='tab_visible' then coalesce((event_detail->>'away_seconds')::int,0) else 0 end),0)) into mon from monitor_events where attempt_id=a.id;
 return query select sc,qtotal,round(sc*100.0/qtotal,2),sc,qtotal-sc,a.attempt_number,a.monitoring_required,rev,mon;
end$$;
grant execute on function submit_attempt(uuid,text) to anon,authenticated;

create or replace function is_teacher() returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from teacher_profiles where user_id=auth.uid()) $$;
revoke all on function is_teacher() from public; grant execute on function is_teacher() to authenticated;

create or replace function admin_attempts()
returns table(full_name text,class_name text,chapter_title text,attempt_number int,score int,total_questions int,percent numeric,monitoring_required boolean,monitor_event_count bigint,submitted_at timestamptz)
language plpgsql security definer set search_path=public as $$
begin
 if not is_teacher() then raise exception 'Không có quyền quản trị'; end if;
 return query select a.full_name,a.class_name,c.title,a.attempt_number,a.score,a.total_questions,a.percent,a.monitoring_required,(select count(*) from monitor_events m where m.attempt_id=a.id),a.submitted_at from attempts a join chapters c on c.id=a.chapter_id where a.status='submitted' order by a.submitted_at desc;
end$$;
grant execute on function admin_attempts() to authenticated;

-- SAU KHI tạo tài khoản giáo viên trong Supabase Authentication > Users,
-- chạy câu lệnh dưới với UUID của tài khoản đó:
-- insert into teacher_profiles(user_id) values ('UUID-TAI-KHOAN-GIAO-VIEN');
