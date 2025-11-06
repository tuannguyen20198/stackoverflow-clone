# 🚀 Fullstack Monorepo – Next.js + NestJS (Turbo + Nx)

Dự án fullstack hiện đại gồm:
- **Frontend:** [Next.js](https://nextjs.org) được quản lý bằng **Turborepo**
- **Backend:** [NestJS](https://nestjs.com) được quản lý bằng **Nx**
- Dễ mở rộng, build nhanh, chia sẻ code chung giữa FE & BE

---

## 🏗️ Cấu trúc thư mục

.
├── backend
│   ├── api-gateway
│   ├── api-gateway-e2e
│   ├── dist
│   ├── eslint.config.js
│   ├── jest.config.ts
│   ├── jest.preset.js
│   ├── node_modules
│   ├── nx.json
│   ├── package-lock.json
│   ├── package.json
│   ├── pnpm-lock.yaml
│   └── tsconfig.base.json
├── CONTRIBUTING.md
├── docs
│   ├── development-guide.md
│   ├── overview-guide.md
│   ├── requestapibackend-guild.md
│   └── role
├── frontend
│   ├── apps
│   ├── node_modules
│   ├── package.json
│   ├── packages
│   ├── pnpm-lock.yaml
│   ├── pnpm-workspace.yaml
│   ├── README.md
│   └── turbo.json
├── infra
│   ├── docker
│   ├── k8s
│   └── scripts
├── node_modules
│   ├── concurrently -> .pnpm/concurrently@9.2.1/node_modules/concurrently
│   └── rimraf -> .pnpm/rimraf@6.1.0/node_modules/rimraf
├── package.json
├── pnpm-lock.yaml
├── pnpm-workspace.yaml
└── Readme.md

yaml
Copy code

---

## ⚙️ Yêu cầu môi trường

- **Node.js ≥ 18**
- **pnpm ≥ 8**
- **Git** để quản lý mã nguồn

Cài `pnpm` nếu chưa có:
```bash
npm install -g pnpm
🚀 Cài đặt & chạy dự án
1️⃣ Clone repository
bash
Copy code
git clone https://github.com/your-username/your-repo-name.git
cd your-repo-name
2️⃣ Cài dependencies
bash
Copy code
pnpm install
3️⃣ Chạy song song frontend + backend
bash
Copy code
pnpm dev
Turborepo sẽ chạy cả 2 app cùng lúc:

Frontend (Next.js) → http://localhost:3000

Backend (NestJS) → http://localhost:3001

🧩 File cấu hình chính
pnpm-workspace.yaml
yaml
Copy code
packages:
  - "apps/*"
  - "packages/*"
turbo.json
json
Copy code
{
  "$schema": "https://turbo.build/schema.json",
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": [".next/**", "dist/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "lint": {},
    "test": {}
  }
}
package.json (scripts)
json
Copy code
{
  "scripts": {
    "dev": "turbo run dev --parallel",
    "build": "turbo run build",
    "lint": "turbo run lint"
  }
}
🧠 Hướng dẫn phát triển
➕ Thêm app mới
Frontend khác: pnpm create next-app apps/admin --typescript

Backend khác: pnpm dlx create-nx-workspace@latest apps/another-api --preset=nest

⚡ Chạy riêng từng phần
bash
Copy code
# Chạy riêng FE
turbo run dev --filter=web

# Chạy riêng BE
pnpm nx serve api
📦 Dùng chung code giữa FE & BE
Tạo file trong packages/utils/:

ts
Copy code
export const formatDate = (date: Date) => date.toISOString().split('T')[0];
Import ở cả FE & BE:

ts
Copy code
import { formatDate } from '@repo/utils';
🧰 Lệnh hữu ích
Lệnh	Mô tả
pnpm dev	Chạy cả Next.js & NestJS song song
turbo run dev --filter=web	Chạy riêng frontend
pnpm nx serve api	Chạy riêng backend
pnpm build	Build toàn bộ hệ thống
pnpm lint	Kiểm tra lint toàn repo
pnpm test	Chạy test toàn repo

🌍 Deploy gợi ý
Frontend (Next.js): Vercel / Netlify / Docker

Backend (NestJS): Render / Railway / Docker / AWS ECS

Cache & CI/CD: Turbo Remote Cache + GitHub Actions

📜 Giấy phép
MIT License © 2025 

