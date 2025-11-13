DevOverflow Database Schema - Giải Thích Chi Tiết
📋 Tổng Quan
Database này được thiết kế cho một nền tảng Q&A (hỏi đáp) giống Stack Overflow, bao gồm 16 bảng chính với đầy đủ chức năng tương tác xã hội, gamification và quản lý nội dung.

1️⃣ CORE TABLES (Bảng Cốt Lõi)
👤 users - Bảng Người Dùng
Lưu trữ toàn bộ thông tin người dùng.
Các trường quan trọng:

id (PK): Mã định danh duy nhất (UUID)
username: Tên đăng nhập (unique)
email: Email (unique, để đăng nhập)
password: Mật khẩu đã mã hóa
bio: Giới thiệu bản thân
avatar_url: Link ảnh đại diện
location: Vị trí địa lý
portfolio_url: Website cá nhân
reputation: Điểm danh tiếng (tăng khi nhận upvote, câu trả lời được chấp nhận)
joined_at: Ngày tham gia

Indexes:

username, email: Tìm kiếm nhanh
reputation: Sắp xếp theo ranking

Ví dụ:
John Doe
- username: johndoe
- email: john@example.com
- reputation: 2,450 điểm
- joined_at: 2024-01-15

❓ questions - Bảng Câu Hỏi
Lưu tất cả câu hỏi được đăng.
Các trường quan trọng:

id (PK): Mã câu hỏi
author_id (FK → users): Người đặt câu hỏi
title: Tiêu đề câu hỏi (max 255 ký tự)
content: Nội dung chi tiết (Markdown/HTML)
views: Số lượt xem
upvotes: Số vote tích cực
downvotes: Số vote tiêu cực
is_answered: Có câu trả lời được chấp nhận chưa?

Relationships:

1 user → nhiều questions (1-to-many)
1 question → nhiều answers

Ví dụ:
Question #123:
- title: "How to implement JWT in React?"
- author: John Doe
- views: 1,234
- upvotes: 45
- answers: 7
- is_answered: true

💬 answers - Bảng Câu Trả Lời
Lưu câu trả lời cho từng câu hỏi.
Các trường quan trọng:

question_id (FK → questions): Thuộc câu hỏi nào
author_id (FK → users): Ai trả lời
content: Nội dung trả lời
is_accepted: Câu trả lời được chấp nhận (người hỏi chọn)
upvotes/downvotes: Điểm vote

Business Logic:

Mỗi question chỉ có 1 accepted answer
Khi answer được accept: questions.is_answered = true
Author của accepted answer nhận +15 reputation

Ví dụ:
Answer #456 cho Question #123:
- author: Jane Smith
- content: "You can use jwt-decode library..."
- is_accepted: true ✓
- upvotes: 23

🏷️ tags - Bảng Thẻ Tag
Phân loại câu hỏi theo chủ đề.
Các trường quan trọng:

name: Tên tag (unique): "React", "JavaScript"
description: Mô tả về tag
question_count: Số câu hỏi có tag này (denormalized)
follower_count: Số người theo dõi tag

Ví dụ:
Tag: "React"
- description: "A JavaScript library for building UIs"
- question_count: 12,450
- follower_count: 3,200

🔗 question_tags - Bảng Liên Kết (Many-to-Many)
Kết nối questions và tags.
Tại sao cần bảng này?

1 question có nhiều tags: ["React", "JavaScript", "Authentication"]
1 tag thuộc nhiều questions
→ Cần bảng junction table

Unique constraint: (question_id, tag_id) - Không được trùng lặp
Ví dụ:
Question #123 có tags:
- React (tag_id: 1)
- JavaScript (tag_id: 2)
- JWT (tag_id: 15)

→ 3 records trong question_tags

💭 comments - Bảng Bình Luận
Bình luận ngắn cho questions hoặc answers.
Đặc điểm:

question_id hoặc answer_id: Chỉ 1 trong 2 có giá trị (nullable)
content: Nội dung ngắn gọn
upvotes: Có thể vote comment

Ví dụ:
Comment trên Question #123:
- author: Alice
- content: "Have you tried using useContext?"
- upvotes: 5

Comment trên Answer #456:
- author: Bob
- content: "This solution worked for me!"
- upvotes: 2

2️⃣ ENGAGEMENT TABLES (Bảng Tương Tác)
👍 votes - Bảng Vote
Lưu tất cả upvote/downvote.
Cấu trúc:

user_id: Ai vote
question_id/answer_id/comment_id: Vote cái gì (1 trong 3)
vote_type: "upvote" hoặc "downvote"

Unique Constraints:

User chỉ vote 1 lần cho mỗi item
(user_id, question_id) unique
(user_id, answer_id) unique

Business Logic:
Upvote question → author +5 reputation
Downvote question → author -2 reputation
Upvote answer → author +10 reputation
Accepted answer → author +15 reputation

❤️ follows - Bảng Theo Dõi Users
User theo dõi user khác.
Self-referential relationship:

follower_id → người follow
following_id → người được follow
Cả 2 đều reference users.id

Ví dụ:
John follows Jane
- follower_id: john_id
- following_id: jane_id

→ John sẽ thấy hoạt động của Jane trong feed

🔖 tag_follows - Theo Dõi Tags
User theo dõi tags để nhận thông báo.
Use case:
Alice follows tag "React"
→ Có question mới về React
→ Alice nhận notification

💾 saved_questions - Lưu Câu Hỏi
User bookmark câu hỏi để đọc sau.
Khác với collections:

saved_questions: Lưu đơn giản
collections: Tổ chức thành nhóm


3️⃣ GAMIFICATION (Trò Chơi Hóa)
🏅 badges - Bảng Huy Hiệu
Định nghĩa các loại huy hiệu.
Loại badges:

Gold 🥇: Khó đạt nhất
Silver 🥈: Trung bình
Bronze 🥉: Dễ đạt

Ví dụ badges:
Badge: "First Question"
- type: bronze
- criteria: "Ask your first question"

Badge: "Great Answer"
- type: gold
- criteria: "Answer scored 100+ upvotes"

Badge: "Enlightened"
- type: silver
- criteria: "First accepted answer with +10 upvotes"

🎖️ user_badges - Huy Hiệu Của User
Ghi lại user nào có badge nào.
Đặc điểm:

User có thể có nhiều badge giống nhau
earned_at: Thời điểm đạt được

Ví dụ:
John's badges:
- Bronze: "First Question" (2024-01-15)
- Silver: "Notable Question" (2024-02-20)
- Gold: "Famous Question" (2024-03-10)

📊 activities - Bảng Hoạt Động
Lưu lịch sử tất cả hành động.
Action types:

asked: Đặt câu hỏi
answered: Trả lời
voted: Vote
commented: Bình luận
accepted: Answer được accept

Reputation tracking:

reputation_change: +10, -2, +15...
Dùng để tính tổng reputation và hiển thị timeline

Ví dụ:
Activity log của John:
1. Asked question #123 → +5 rep
2. Received upvote → +10 rep
3. Answer accepted → +15 rep
Total: +30 reputation today

4️⃣ ORGANIZATION (Tổ Chức)
📚 collections - Bộ Sưu Tập
User tạo folder để nhóm questions.
Use case:
Collection: "React Learning"
- Questions về Hooks
- Questions về Context
- Questions về Performance

Collection: "Interview Prep"
- Algorithm questions
- System design questions
Đặc điểm:

is_public: Chia sẻ collection với người khác
Private: Chỉ mình user thấy


🗂️ collection_questions - Junction Table
Kết nối collections với questions (many-to-many).

5️⃣ SYSTEM TABLES
🔔 notifications - Bảng Thông Báo
Thông báo cho user về các hoạt động liên quan.
Notification types:

answer: Có người trả lời question của bạn
comment: Có người comment
vote: Nhận upvote
badge: Đạt được badge mới
follow: Có người follow bạn
mention: Được @ mention

Các trường liên quan:

related_question_id: Link đến question
related_answer_id: Link đến answer
related_user_id: User gây ra notification
is_read: Đã đọc chưa

Ví dụ:
Notification:
"Jane Smith answered your question 'How to implement JWT?'"
- type: answer
- related_question_id: 123
- related_answer_id: 456
- related_user_id: jane_id
- is_read: false

🔗 KEY RELATIONSHIPS (Mối Quan Hệ Chính)
1. User-Centric (Tập trung vào User)
users (1) → (many) questions
users (1) → (many) answers
users (1) → (many) comments
users (1) → (many) votes
users (1) → (many) notifications
users (1) → (many) activities
2. Question-Centric (Tập trung vào Question)
questions (1) → (many) answers
questions (1) → (many) comments
questions (1) → (many) votes
questions (many) ↔ (many) tags [through question_tags]
3. Many-to-Many Relationships
users ↔ users [through follows]
users ↔ tags [through tag_follows]
users ↔ questions [through saved_questions]
users ↔ badges [through user_badges]
collections ↔ questions [through collection_questions]

📈 DENORMALIZATION (Tối Ưu Hóa)
Một số trường được denormalize để tăng performance:
1. questions.views

Không cần join với bảng views riêng
Tăng trực tiếp mỗi lần xem

2. questions.upvotes/downvotes

Không cần COUNT(*) từ bảng votes
Update khi có vote mới

3. tags.question_count

Không cần COUNT(*) từ question_tags
Update khi thêm/xóa tag

4. users.reputation

Tổng hợp từ activities
Update real-time

Trade-off:

✅ Read nhanh hơn (không cần JOIN nhiều)
❌ Write phức tạp hơn (phải update nhiều chỗ)


🎯 USE CASES (Các Tình Huống Sử Dụng)
Use Case 1: User Đặt Câu Hỏi
sql1. INSERT vào questions
2. INSERT vào question_tags (cho mỗi tag)
3. UPDATE tags.question_count (+1)
4. INSERT vào activities (action_type = 'asked')
5. Gửi notifications cho followers của tags
Use Case 2: User Upvote Câu Hỏi
sql1. INSERT vào votes (vote_type = 'upvote')
2. UPDATE questions.upvotes (+1)
3. UPDATE users.reputation (+5 cho author)
4. INSERT vào activities
5. INSERT vào notifications (cho author)
Use Case 3: Accept Answer
sql1. UPDATE answers.is_accepted = true
2. UPDATE questions.is_answered = true
3. UPDATE users.reputation (+15 cho answerer)
4. INSERT vào activities
5. INSERT vào notifications
6. Check và award badges nếu đủ điều kiện
Use Case 4: Hiển Thị Question Detail
sql1. SELECT question JOIN users (author)
2. SELECT answers JOIN users (answerers)
3. SELECT tags FROM question_tags
4. SELECT comments
5. SELECT user's vote status
6. UPDATE questions.views (+1)

🔒 DATA INTEGRITY (Toàn Vẹn Dữ Liệu)
Foreign Key Constraints
Tất cả FK đều có ON DELETE rules:
sqlquestions.author_id → users.id
  ON DELETE CASCADE (xóa user → xóa questions)

answers.question_id → questions.id
  ON DELETE CASCADE (xóa question → xóa answers)

votes.user_id → users.id
  ON DELETE CASCADE (xóa user → xóa votes)
Unique Constraints
sql- users.username UNIQUE
- users.email UNIQUE
- tags.name UNIQUE
- (user_id, question_id) UNIQUE trong votes
- (user_id, question_id) UNIQUE trong saved_questions
Check Constraints
sql- vote_type IN ('upvote', 'downvote')
- badge_type IN ('gold', 'silver', 'bronze')
- reputation >= 0

🚀 SCALING CONSIDERATIONS (Mở Rộng)
Indexes Strategy
sql1. Primary Keys: Tự động indexed
2. Foreign Keys: Indexed cho JOINs nhanh
3. Composite indexes:
   - (user_id, created_at) trong activities
   - (question_id, is_accepted) trong answers
4. Text search: Full-text index trên questions.title, content
Partitioning (Phân vùng)
sql- activities: Partition by created_at (monthly)
- notifications: Partition by created_at (weekly)
- votes: Partition by created_at (yearly)
Caching Strategy
sql- Cache: Top questions (views, upvotes)
- Cache: User profile (reputation, badges)
- Cache: Tag list với question_count
- Redis: Real-time notification count

📝 SUMMARY (Tóm Tắt)
16 Tables tổng quan:
Core (5): users, questions, answers, tags, question_tags
Engagement (4): votes, follows, tag_follows, saved_questions
Gamification (3): badges, user_badges, activities
Organization (2): collections, collection_questions
System (2): notifications, comments
Key Features:

✅ Q&A platform đầy đủ
✅ Reputation system
✅ Badge/Achievement system
✅ Social features (follow, vote, save)
✅ Notification system
✅ Collections để organize
✅ Scalable design

Performance Optimizations:

Denormalized counts
Strategic indexes
Efficient JOINs