# DevOverflow - Tài Liệu Database Schema

> **Phiên bản**: 2.0 (Đã tối ưu hóa)  
> **Cập nhật lần cuối**: 2024  
> **Database**: PostgreSQL 14+  
> **Extensions**: LTREE

## 📋 Mục Lục

1. [Tổng Quan](#tổng-quan)
2. [Sơ Đồ Database](#sơ-đồ-database)
3. [Quyết Định Thiết Kế Chính](#quyết-định-thiết-kế-chính)
4. [Chi Tiết Các Bảng](#chi-tiết-các-bảng)
5. [Tối Ưu Hóa](#tối-ưu-hóa)
6. [Mối Quan Hệ](#mối-quan-hệ)
7. [Các Mẫu Query Phổ Biến](#các-mẫu-query-phổ-biến)
8. [Chiến Lược Index](#chiến-lược-index)
9. [Cân Nhắc Khi Scale](#cân-nhắc-khi-scale)
10. [Hướng Dẫn Migration](#hướng-dẫn-migration)

---

## 📊 Tổng Quan

Database DevOverflow được thiết kế cho nền tảng hỏi đáp (Q&A) tương tự Stack Overflow, bao gồm:

- ✅ Câu hỏi, Câu trả lời, và Bình luận lồng nhau (không giới hạn độ sâu)
- ✅ Hệ thống voting (upvote/downvote)
- ✅ Điểm danh tiếng và gamification (huy hiệu)
- ✅ Tính năng xã hội (follow người dùng, follow tags)
- ✅ Bộ sưu tập và lưu bài viết
- ✅ Thông báo real-time
- ✅ Theo dõi hoạt động

**Tổng số bảng**: 16  
**Database Engine**: PostgreSQL 14+  
**Quy mô dự kiến**: Hàng triệu bài viết, hàng nghìn người dùng đồng thời

---

## 🎨 Sơ Đồ Database

File DBML để visualize trên https://dbdiagram.io/d

```
Tệp: database/schema.dbml
Paste vào: https://dbdiagram.io/d để xem diagram
```

**Nhóm bảng chính**:
- **Core (Cốt lõi)**: users, posts, tags
- **Social (Xã hội)**: followers, following, tag_follows
- **Engagement (Tương tác)**: votes, saved_posts, collections
- **Gamification (Trò chơi hóa)**: badges, user_badges, activities
- **System (Hệ thống)**: notifications

---

## 🎯 Quyết Định Thiết Kế Chính

### 1. **LTREE Cho Bài Viết Lồng Nhau** ⭐

**Vấn đề**: Cách tiếp cận truyền thống dùng 3 bảng riêng:
```
Bảng questions (câu hỏi)
Bảng answers (câu trả lời)
Bảng comments (bình luận)
```

**Hạn chế**:
- ❌ Không có replies lồng nhau (answer → reply → reply)
- ❌ Query phức tạp với nhiều JOINs
- ❌ Khó thêm loại post mới
- ❌ Khó hiển thị thread có cấu trúc

**Giải pháp**: Dùng 1 bảng `posts` với LTREE (Materialized Path)

```sql
Bảng posts {
  post_type: 'question' | 'answer' | 'comment'
  path: LTREE  -- '001.002.003'
  parent_id: UUID
  depth: INTEGER
}
```

**Lợi ích**:
- ✅ Độ sâu lồng nhau không giới hạn
- ✅ Query ancestor/descendant cực nhanh
- ✅ 1 bảng = schema đơn giản hơn
- ✅ Linh hoạt cho các loại post tương lai

**Ví dụ LTREE Path**:
```
Câu hỏi (root):
  path: '001'
  depth: 0

Câu trả lời 1:
  path: '001.001'
  depth: 1
  
  Reply 1.1:
    path: '001.001.001'
    depth: 2
    
    Reply 1.1.1:
      path: '001.001.001.001'
      depth: 3  ← Không giới hạn!
      
Câu trả lời 2:
  path: '001.002'
  depth: 1
```

**Queries với LTREE**:
```sql
-- Lấy tất cả replies của 1 post
SELECT * FROM posts WHERE path <@ '001.001';

-- Lấy tất cả ancestors của 1 post
SELECT * FROM posts WHERE path @> '001.001.003';

-- Lấy các post cùng level (siblings)
SELECT * FROM posts WHERE nlevel(path) = 2 AND path ~ '001.*{1}';

-- Lấy chỉ direct children
SELECT * FROM posts WHERE parent_id = 'some-uuid';

-- Đếm tổng số replies trong thread
SELECT COUNT(*) FROM posts WHERE path <@ '001' AND id != 'question-id';

-- Lấy toàn bộ thread theo thứ tự
SELECT * FROM posts WHERE path <@ '001' ORDER BY path;
```

**LTREE Operators**:
- `<@` : is descendant of (là con cháu của)
- `@>` : is ancestor of (là tổ tiên của)
- `~` : matches pattern
- `nlevel()` : độ sâu của path

**So sánh hiệu năng**:

| Phương pháp | Read Speed | Write Speed | Độ phức tạp | Giới hạn độ sâu |
|-------------|-----------|-------------|-------------|-----------------|
| Adjacency List (parent_id) | 🐌 Chậm (Recursive CTE) | ⚡ Nhanh | Đơn giản | Không |
| Nested Sets | ⚡ Nhanh | 🐌 Chậm (phải rebuild) | Phức tạp | Không |
| Closure Table | ⚡ Nhanh | Trung bình | Phức tạp | Không |
| **LTREE** ✅ | ⚡⚡ Rất nhanh | ⚡ Nhanh | Trung bình | ~65K bytes |

---

### 2. **Tách Followers/Following Thành 2 Bảng** ⭐

**Vấn đề**: Thiết kế truyền thống dùng 1 bảng:
```sql
Bảng follows {
  follower_id    -- Người follow
  following_id   -- Người được follow
}
```

**Hạn chế**:
- ❌ **Lock contention cao** - Cả 2 chiều đều query cùng 1 bảng
- ❌ **Index conflict** - Cần index theo cả 2 cột
- ❌ **Hot partition** - User nổi tiếng có nhiều followers gây bottleneck
- ❌ **Query chậm** - Phải dùng WHERE khác nhau cho mỗi use case

**Use cases thực tế**:
```sql
-- Lấy danh sách người follow mình (FOLLOWERS)
SELECT follower_id FROM follows WHERE following_id = 'my_id';

-- Lấy danh sách người mình follow (FOLLOWING)
SELECT following_id FROM follows WHERE follower_id = 'my_id';
```

**Giải pháp**: Tách thành 2 bảng riêng biệt

```sql
-- Bảng 1: Tối ưu cho "Ai đang follow tôi?"
Bảng followers {
  user_id      -- Người ĐƯỢC follow (index chính)
  follower_id  -- Người follow
}

-- Bảng 2: Tối ưu cho "Tôi đang follow ai?"
Bảng following {
  user_id       -- Người FOLLOW (index chính)
  following_id  -- Người được follow
}
```

**Lợi ích**:
- ✅ **Giảm lock contention** - 2 bảng riêng = lock riêng
- ✅ **Query nhanh hơn** - Mỗi bảng có index tối ưu cho 1 chiều
- ✅ **Scale tốt hơn** - Có thể shard riêng theo user_id
- ✅ **Dễ cache** - Cache riêng cho followers và following

**So sánh hiệu năng**:

| Aspect | 1 Bảng | 2 Bảng (Tối ưu) |
|--------|--------|-----------------|
| Storage | 1x | 2x ⚠️ |
| Read Speed | 🐌 Chậm hơn | ⚡ Nhanh hơn |
| Lock Contention | 🔴 Cao | 🟢 Thấp |
| Write Complexity | Đơn giản | Trung bình (2 INSERTs) |
| Consistency | Dễ | Cần transaction |
| Scalability | Hạn chế | 🚀 Tuyệt vời |

**Logic Follow/Unfollow**:
```javascript
// User A follow User B
async function followUser(userA, userB) {
  await db.transaction(async (tx) => {
    // INSERT vào 2 bảng cùng lúc
    await tx.following.create({
      user_id: userA,
      following_id: userB
    });
    
    await tx.followers.create({
      user_id: userB,
      follower_id: userA
    });
    
    // Update denormalized counts
    await tx.users.update({
      where: { id: userA },
      data: { following_count: { increment: 1 } }
    });
    
    await tx.users.update({
      where: { id: userB },
      data: { follower_count: { increment: 1 } }
    });
  });
}

// User A unfollow User B
async function unfollowUser(userA, userB) {
  await db.transaction(async (tx) => {
    // DELETE từ 2 bảng
    await tx.following.deleteMany({
      where: { user_id: userA, following_id: userB }
    });
    
    await tx.followers.deleteMany({
      where: { user_id: userB, follower_id: userA }
    });
    
    // Update counts
    await tx.users.update({
      where: { id: userA },
      data: { following_count: { decrement: 1 } }
    });
    
    await tx.users.update({
      where: { id: userB },
      data: { follower_count: { decrement: 1 } }
    });
  });
}
```

---

## 📋 Chi Tiết Các Bảng

### 1. **users** - Bảng Người Dùng

Lưu trữ thông tin người dùng và metrics.

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  name VARCHAR(100) NOT NULL,
  bio TEXT,
  avatar_url VARCHAR(500),
  location VARCHAR(100),
  portfolio_url VARCHAR(500),
  
  -- Denormalized metrics
  reputation INTEGER DEFAULT 0,
  follower_count INTEGER DEFAULT 0,
  following_count INTEGER DEFAULT 0,
  
  joined_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**Các trường quan trọng**:
- `reputation`: Điểm danh tiếng, tăng khi nhận upvote, answer được accept
- `follower_count`: Số người follow (denormalized từ bảng followers)
- `following_count`: Số người đang follow (denormalized từ bảng following)

**Indexes**:
```sql
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_reputation ON users(reputation DESC); -- Leaderboard
CREATE INDEX idx_users_follower_count ON users(follower_count DESC);
```

**Business Rules**:
- Username phải unique, 3-50 ký tự
- Email phải unique và valid format
- Password phải hash (bcrypt/argon2)
- Reputation không được âm

---

### 2. **posts** - Bảng Bài Viết (Questions/Answers/Comments)

Bảng unified cho tất cả loại content với LTREE hierarchy.

```sql
CREATE TABLE posts (
  id UUID PRIMARY KEY,
  author_id UUID NOT NULL REFERENCES users(id),
  
  -- Content
  title VARCHAR(255),  -- Chỉ cho questions
  content TEXT NOT NULL,
  content_type VARCHAR(20) DEFAULT 'markdown',
  
  -- Hierarchy (LTREE)
  post_type VARCHAR(20) NOT NULL, -- 'question', 'answer', 'comment'
  path LTREE NOT NULL,
  parent_id UUID REFERENCES posts(id),
  question_id UUID REFERENCES posts(id),
  depth INTEGER DEFAULT 0,
  
  -- Metrics (Denormalized)
  views INTEGER DEFAULT 0,
  upvotes INTEGER DEFAULT 0,
  downvotes INTEGER DEFAULT 0,
  reply_count INTEGER DEFAULT 0,     -- Direct replies
  total_replies INTEGER DEFAULT 0,   -- All descendants
  
  -- Question specific
  is_answered BOOLEAN DEFAULT FALSE,
  accepted_answer_id UUID REFERENCES posts(id),
  
  -- Answer specific
  is_accepted BOOLEAN DEFAULT FALSE,
  
  -- Metadata
  is_deleted BOOLEAN DEFAULT FALSE,
  deleted_at TIMESTAMP,
  edited_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  CHECK (
    (post_type = 'question' AND title IS NOT NULL AND parent_id IS NULL) OR
    (post_type IN ('answer', 'comment') AND parent_id IS NOT NULL)
  )
);
```

**Post Types**:
- `question`: Câu hỏi (root, depth=0)
- `answer`: Câu trả lời (depth=1)
- `comment`: Bình luận/Reply (depth≥2)

**LTREE Path Format**:
```
'001'           → Question
'001.001'       → Answer 1 của question
'001.001.001'   → Reply 1 của answer 1
'001.001.001.001' → Reply của reply (nested)
```

**Indexes**:
```sql
-- LTREE indexes (CỰC KỲ QUAN TRỌNG!)
CREATE INDEX idx_posts_path_gist ON posts USING GIST(path);
CREATE INDEX idx_posts_path_btree ON posts USING BTREE(path);

-- Regular indexes
CREATE INDEX idx_posts_author_id ON posts(author_id);
CREATE INDEX idx_posts_post_type ON posts(post_type);
CREATE INDEX idx_posts_parent_id ON posts(parent_id);
CREATE INDEX idx_posts_question_id ON posts(question_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);

-- Composite indexes
CREATE INDEX idx_posts_question_answers 
  ON posts(question_id, post_type, upvotes DESC)
  WHERE post_type IN ('answer', 'comment');
```

**Business Rules**:
- Question phải có title
- Question không có parent
- Answer/Comment phải có parent
- path tự động generate qua trigger
- Upvote → author +5 reputation (question) hoặc +10 (answer)
- Accepted answer → author +15 reputation

---

### 3. **tags** - Bảng Tags

Phân loại questions theo chủ đề.

```sql
CREATE TABLE tags (
  id UUID PRIMARY KEY,
  name VARCHAR(50) UNIQUE NOT NULL,
  description TEXT,
  question_count INTEGER DEFAULT 0,  -- Denormalized
  follower_count INTEGER DEFAULT 0,  -- Denormalized
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE post_tags (
  id UUID PRIMARY KEY,
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(post_id, tag_id)
);
```

**Indexes**:
```sql
CREATE INDEX idx_tags_name ON tags(name);
CREATE INDEX idx_tags_question_count ON tags(question_count DESC);
CREATE INDEX idx_post_tags_post_id ON post_tags(post_id);
CREATE INDEX idx_post_tags_tag_id ON post_tags(tag_id);
```

**Ví dụ tags**: `react`, `javascript`, `typescript`, `nextjs`, `database`

---

### 4. **votes** - Bảng Voting

Lưu tất cả upvote/downvote.

```sql
CREATE TABLE votes (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  vote_type VARCHAR(10) NOT NULL CHECK (vote_type IN ('upvote', 'downvote')),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, post_id)  -- User chỉ vote 1 lần
);
```

**Indexes**:
```sql
CREATE INDEX idx_votes_user_id ON votes(user_id);
CREATE INDEX idx_votes_post_id ON votes(post_id);
```

**Reputation Rules**:
```
Upvote question   → author +5
Downvote question → author -2
Upvote answer     → author +10
Downvote answer   → author -2
Accepted answer   → author +15
```

---

### 5. **followers** - Bảng Followers (Ai Follow Tôi)

Tối ưu cho query "Lấy danh sách followers của tôi".

```sql
CREATE TABLE followers (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id),      -- Người ĐƯỢC follow
  follower_id UUID NOT NULL REFERENCES users(id),  -- Người follow
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, follower_id),
  CHECK (user_id != follower_id)
);
```

**Indexes**:
```sql
CREATE INDEX idx_followers_user_id ON followers(user_id);      -- PRIMARY
CREATE INDEX idx_followers_follower_id ON followers(follower_id);
```

**Query Example**:
```sql
-- Lấy tất cả người follow tôi
SELECT u.* 
FROM users u
JOIN followers f ON f.follower_id = u.id
WHERE f.user_id = 'my-user-id';
```

---

### 6. **following** - Bảng Following (Tôi Follow Ai)

Tối ưu cho query "Lấy danh sách người tôi đang follow".

```sql
CREATE TABLE following (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id),       -- Người FOLLOW
  following_id UUID NOT NULL REFERENCES users(id),  -- Người được follow
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, following_id),
  CHECK (user_id != following_id)
);
```

**Indexes**:
```sql
CREATE INDEX idx_following_user_id ON following(user_id);         -- PRIMARY
CREATE INDEX idx_following_following_id ON following(following_id);
```

**Query Example**:
```sql
-- Lấy tất cả người tôi đang follow
SELECT u.*
FROM users u
JOIN following f ON f.following_id = u.id
WHERE f.user_id = 'my-user-id';
```

---

### 7. **tag_follows** - Follow Tags

User theo dõi tags để nhận thông báo.

```sql
CREATE TABLE tag_follows (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, tag_id)
);
```

**Use case**: User follow tag "react" → nhận notification khi có question mới về React

---

### 8. **saved_posts** - Lưu Bài Viết

User bookmark posts để đọc sau.

```sql
CREATE TABLE saved_posts (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, post_id)
);
```

---

### 9. **collections** - Bộ Sưu Tập

User tổ chức saved posts thành collections.

```sql
CREATE TABLE collections (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  is_public BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE collection_posts (
  id UUID PRIMARY KEY,
  collection_id UUID NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  added_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(collection_id, post_id)
);
```

**Ví dụ collections**:
- "React Learning Resources"
- "Interview Prep Questions"
- "Algorithm Problems"

---

### 10. **badges** - Huy Hiệu

Định nghĩa các loại badges.

```sql
CREATE TABLE badges (
  id UUID PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  badge_type VARCHAR(20) NOT NULL CHECK (badge_type IN ('gold', 'silver', 'bronze')),
  icon_url VARCHAR(500),
  criteria TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE user_badges (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  badge_id UUID NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
  earned_at TIMESTAMP DEFAULT NOW()
);
```

**Ví dụ badges**:
- 🥉 **"First Question"** (Bronze): Đặt câu hỏi đầu tiên
- 🥈 **"Notable Question"** (Silver): Câu hỏi đạt 2,500 views
- 🥇 **"Great Answer"** (Gold): Câu trả lời có 100+ upvotes

---

### 11. **activities** - Theo Dõi Hoạt Động

Lưu lịch sử tất cả hoạt động của user.

```sql
CREATE TABLE activities (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  action_type VARCHAR(50) NOT NULL, -- 'asked', 'answered', 'voted', 'followed', etc
  post_id UUID REFERENCES posts(id),
  reputation_change INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);
```

**Indexes**:
```sql
CREATE INDEX idx_activities_user_id ON activities(user_id);
CREATE INDEX idx_activities_created_at ON activities(created_at DESC);
CREATE INDEX idx_activities_user_created ON activities(user_id, created_at DESC);
```

**Use cases**:
- Timeline hoạt động của user
- Tính tổng reputation
- Hiển thị "Recent Activity"

---

### 12. **notifications** - Thông Báo

```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL, -- 'answer', 'comment', 'vote', 'badge', 'follow'
  content TEXT NOT NULL,
  related_post_id UUID REFERENCES posts(id),
  related_user_id UUID REFERENCES users(id),
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);
```

**Indexes**:
```sql
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(user_id, is_read);
CREATE INDEX idx_notifications_user_created 
  ON notifications(user_id, is_read, created_at DESC);
```

**Notification Types**:
- `answer`: Có người trả lời câu hỏi của bạn
- `comment`: Có người comment
- `vote`: Nhận upvote
- `badge`: Đạt được badge mới
- `follow`: Có người follow bạn
- `mention`: Được @ mention

---

## 🔗 Mối Quan Hệ

### User-Centric Relationships
```
users (1) ──→ (many) posts (author)
users (1) ──→ (many) votes
users (1) ──→ (many) followers (được follow)
users (1) ──→ (many) following (follow người khác)
users (1) ──→ (many) saved_posts
users (1) ──→ (many) collections
users (1) ──→ (many) activities
users (1) ──→ (many) notifications
users (many) ←→ (many) badges (qua user_badges)
users (many) ←→ (many) tags (qua tag_follows)
```

### Post-Centric Relationships
```
posts (1) ──→ (many) posts (parent-child qua LTREE)
posts (1) ──→ (many) votes
posts (many) ←→ (many) tags (qua post_tags)
posts (1) ──→ (many) saved_posts
posts (1) ──→ (many) notifications
```

### Many-to-Many Relationships
```
users ←→ users (qua followers & following)
users ←→ tags (qua tag_follows)
users ←→ badges (qua user_badges)
posts ←→ tags (qua post_tags)
collections ←→ posts (qua collection_posts)
```
