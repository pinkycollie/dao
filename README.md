# MBTQ DAO SaaS Starter Kit

![Vercel](https://img.shields.io/badge/deploy-vercel-blue) ![Next.js](https://img.shields.io/badge/Next.js-13-black) ![Supabase](https://img.shields.io/badge/Supabase-Postgres-green) ![TypeScript](https://img.shields.io/badge/TypeScript-4.9-blue)

Modular, web3-ready DAO platform scaffold for Vercel + Next.js. Manage members, proposals, treasury, and reputation in one dashboard. Fully TypeScript-ready, Tailwind-styled, and serverless-friendly.

---

## Demo Screenshots

### Dashboard Landing
![Dashboard Screenshot](public/screenshots/dashboard.png)

### Members & Reputation
![Members Screenshot](public/screenshots/members.png)

### Proposals & Voting
![Proposals Screenshot](public/screenshots/proposals.png)

### Treasury Overview
![Treasury Screenshot](public/screenshots/treasury.png)

---

## Features

- DAO Members: directory with roles, reputation, and badges  
- Proposals: create, display, and vote  
- Voting: interactive, wallet-enabled  
- Treasury: off-chain balances, ready for blockchain integration  
- Wallet login: MetaMask / WalletConnect  
- Serverless API routes: members, proposals, voting, treasury  
- Paused mode: project can be deployed but inactive  
- Vercel-ready: deploy immediately

---

mbtq-dao-starter/
├─ public/
│  ├─ screenshots/
│  └─ placeholders/
├─ src/
│  ├─ pages/
│  │  ├─ index.tsx
│  │  └─ api/
│  ├─ components/
│  ├─ hooks/
│  ├─ utils/
│  └─ services/
├─ styles/
├─ package.json
├─ tsconfig.json
├─ tailwind.config.js
└─ README.md
