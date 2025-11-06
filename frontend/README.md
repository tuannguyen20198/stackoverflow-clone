# 🚀 Next.js Monorepo with Turborepo

Một dự án **quản lý nhiều ứng dụng (web, admin, API, UI library, …)** trong cùng một repo bằng **[Turborepo](https://turbo.build/repo)**.  
Cấu trúc được tối ưu cho phát triển hệ thống web hiện đại — dễ mở rộng, chia sẻ code, và CI/CD nhanh.

---

## 🏗️ Cấu trúc thư mục

.
├── apps/
│ ├── web/ # Ứng dụng chính (Next.js cho khách hàng)
│ ├── admin/ # Ứng dụng quản trị (Next.js dashboard)
│ └── api/ # API service (nếu có)
│
├── packages/
│ ├── ui/ # Thư viện component dùng chung (React + Tailwind)
│ ├── config/ # Cấu hình ESLint, Tailwind, TS dùng chung
│ └── utils/ # Hàm helper, logic tái sử dụng
│
├── turbo.json # Cấu hình pipeline của Turborepo
├── package.json
└── README.md

yaml
Copy code

---

## ⚙️ Yêu cầu môi trường

- **Node.js** ≥ 18  
- **pnpm** ≥ 8 (khuyên dùng thay npm/yarn)  
- **Git** để clone và quản lý version

Cài pnpm nếu chưa có:
```bash
npm install -g pnpm
🚀 Cài đặt & chạy dự án
1️⃣ Clone project
bash
Copy code
git clone https://github.com/your-username/your-repo-name.git
cd your-repo-name
2️⃣ Cài dependencies
bash
Copy code
pnpm install
3️⃣ Chạy tất cả ứng dụng (dev mode)
bash
Copy code
pnpm dev
Turbo sẽ tự chạy song song tất cả app trong thư mục apps/*.
Mặc định:

web: http://localhost:3000

admin: http://localhost:3001

🧩 Cấu hình Turborepo (turbo.json)
json
Copy code
{
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": [".next/**", "dist/**"]
    },
    "dev": {
      "cache": false
    },
    "lint": {},
    "test": {}
  }
}
dependsOn: đảm bảo build theo đúng thứ tự giữa các package.

outputs: định nghĩa output để cache build thông minh.

cache: false cho dev giúp hot reload nhanh hơn.

🧱 Thêm app hoặc package mới
➕ Thêm ứng dụng (Next.js)
bash
Copy code
pnpm create next-app apps/new-app --typescript --tailwind
➕ Thêm package dùng chung
bash
Copy code
mkdir packages/logger
pnpm init -y
🧰 Lệnh hữu ích
Lệnh	Mô tả
pnpm dev	Chạy tất cả app ở chế độ development
pnpm build	Build toàn bộ app & package
pnpm lint	Kiểm tra eslint toàn repo
pnpm test	Chạy test toàn repo
turbo run dev --filter=web	Chạy riêng app web
turbo run build --filter=admin	Build riêng admin

🧠 Mở rộng
Dùng Vercel để deploy dễ nhất (tự nhận Turborepo)

Có thể thêm backend bằng NestJS, Express, hoặc Next.js API Routes

Tích hợp CI/CD: GitHub Actions + Turbo Remote Cache

📜 Giấy phép
MIT License © 2025 — Tác giả: Your Name

❤️ Đóng góp
Pull requests, issues và ý tưởng mới luôn được hoan nghênh!
Hãy giúp dự án này ngày càng tốt hơn 🚀

yaml
Copy code

---

Bạn có muốn mình **tùy chỉnh README này theo project cụ thể của bạn** không (ví dụ: tên project, có web + admin, dùng API riêng, hay chỉ 1 app)?  
Mình có thể viết lại gọn hơn, có logo và hướng dẫn deploy luôn.