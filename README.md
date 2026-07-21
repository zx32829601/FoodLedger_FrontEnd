# FoodLedger Frontend

FoodLedger 的跨平台前端，使用 Flutter 建立 Web、Android 與 iOS 共用介面。專案目前先以可操作的 UI Prototype 與 Mock Repository 推進，後續透過 OpenAPI 契約串接 ASP.NET Core 後端。

## 專案目標

- 提供使用者首頁、飲食紀錄與會員資料頁面。
- 提供管理員 Dashboard、使用者、食物資料與稽核紀錄管理頁面。
- 使用同一套 Flutter 程式碼支援 Web 與手機端。
- 以 Repository 抽象隔離 Mock Data 與正式 API，避免後端尚未完成時阻塞 UI 設計。
- 配合 ASP.NET Core Identity、PostgreSQL、OpenAPI 與 OpenTelemetry 建立完整前後端作品。

## 技術選型

### Frontend

- Flutter / Dart
- Material 3
- Riverpod：狀態管理與依賴注入
- GoRouter：路由、登入狀態與角色導向
- Dio：HTTP Client 與認證攔截器
- Freezed、json_serializable：不可變資料模型與 JSON 轉換
- flutter_secure_storage：手機端敏感資料儲存
- fl_chart：營養與管理統計圖表
- intl：日期、數字與多語系格式

### Backend integration

- ASP.NET Core Web API
- ASP.NET Core Identity
- PostgreSQL / Entity Framework Core
- OpenAPI
- .NET Aspire / OpenTelemetry
- Docker / Docker Compose

## 開發環境

- Flutter 3.44.7（Stable channel）
- Dart 3.12.2
- Chrome 或 Edge：執行 Flutter Web
- Android Studio、Android SDK 與模擬器：執行 Android
- macOS 與 Xcode：建置及執行 iOS

確認環境：

```powershell
flutter --version
flutter doctor -v
flutter devices
```

## 快速開始

安裝套件：

```powershell
flutter pub get
```

使用 Chrome 啟動 Web：

```powershell
flutter run -d chrome
```

建立 Web release build：

```powershell
flutter build web
```

## 品質檢查

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

完整 Coding Style、測試與 Git 規範請參考 [`AGENTS.md`](AGENTS.md)。

## 頁面與資訊架構

```text
FoodLedger
├─ Authentication
│  ├─ Login
│  ├─ Register
│  └─ Forgot Password
├─ User App
│  ├─ Home
│  ├─ Records
│  └─ Profile
└─ Admin
   ├─ Dashboard
   ├─ Users
   ├─ Foods
   ├─ Audit Logs
   └─ Search / Observability
```

### 使用者前台

- **首頁**：今日熱量與營養素摘要、各餐紀錄、七日趨勢、快速新增紀錄。
- **紀錄**：日期切換、日曆與列表模式、餐別篩選、新增、編輯、刪除及複製紀錄。
- **會員**：基本資料、身高體重、營養目標、偏好設定、密碼與登入狀態管理。

手機版使用 Bottom Navigation，桌面 Web 使用 Navigation Rail 或 Sidebar。

### 管理後台

- 系統與使用狀況 Dashboard
- 使用者搜尋、分頁、角色與狀態管理
- 食物、分類、份量單位與營養資料管理
- 管理操作 Audit Log
- 未來透過 ASP.NET Core Admin API 查詢 Elasticsearch，不讓 Flutter 直接連線 ELK

## 建議專案結構

```text
lib/
├─ app/
│  ├─ app.dart
│  ├─ router.dart
│  └─ theme.dart
├─ core/
│  ├─ api/
│  ├─ auth/
│  ├─ errors/
│  ├─ storage/
│  └─ widgets/
├─ features/
│  ├─ authentication/
│  ├─ home/
│  ├─ records/
│  ├─ profile/
│  └─ admin/
└─ main.dart
```

每個 feature 原則上包含：

```text
feature/
├─ data/          # API、DTO、Service、Repository 實作
├─ domain/        # Domain model、Repository interface；Use case 視複雜度加入
└─ presentation/  # Page、Widget、ViewModel / Provider
```

不為簡單功能強制建立 Use Case；當邏輯需要跨多個 Repository、會重用或明顯複雜時再加入 Domain layer。

## 資料流

```text
Page / Widget
    ↓
ViewModel / Riverpod Provider
    ↓
Repository interface
    ├─ Mock Repository（UI Prototype）
    └─ API Repository（正式串接）
          ↓
       Dio / Generated OpenAPI Client
          ↓
       ASP.NET Core API
```

## 實作順序

採用「後端核心先行、前後端垂直切片同步開發」，不等待所有後端完成，也不先做完所有靜態頁面。

### Phase 1：前端骨架與 UI Prototype

1. 建立 Flutter Web、Android、iOS 專案。
2. 建立 Material 3 Theme 與 Design Tokens。
3. 建立手機 Bottom Navigation 與桌面 Navigation Rail。
4. 定義 Loading、Empty、Error、Disabled 等共用狀態。
5. 建立 Repository interfaces 與 Mock repositories。
6. 完成登入、首頁、紀錄、會員頁面的可操作 Prototype。
7. 建立 Admin Shell、Dashboard 與管理列表 Prototype。

### Phase 2：第一個端到端垂直切片

優先完成以下最小可用流程：

```text
註冊 / 登入
→ 搜尋食物
→ 新增今日飲食紀錄
→ 首頁顯示今日營養總計
```

每一個功能都依序完成：

```text
資料模型 → API DTO / OpenAPI → 後端測試 → Flutter 串接 → 端到端驗證
```

### Phase 3：核心功能

1. 飲食紀錄查詢、修改、刪除與使用者資料隔離。
2. 食物關鍵字、分類與語系搜尋。
3. 每日營養彙總與七日／三十日趨勢。
4. 會員 Profile 與營養目標。
5. 完整表單驗證與統一 Problem Details 錯誤處理。
6. Token / Cookie session、登出、過期與刷新流程。

### Phase 4：管理與維運

1. Admin role 與路由保護。
2. 使用者與食物資料管理 API／頁面。
3. Audit Log。
4. Docker Compose 與 CI/CD。
5. Structured Logs、Traces、Metrics 與 Trace ID。
6. 實際需求成立後再導入 Elasticsearch / Kibana。

## 預計 API 契約

```http
GET    /api/users/me
PUT    /api/users/me/profile

GET    /api/foods
GET    /api/foods/{id}

GET    /api/daily-records?date=2026-07-21
POST   /api/daily-records
PUT    /api/daily-records/{id}
DELETE /api/daily-records/{id}

GET    /api/nutrition/daily?date=2026-07-21
GET    /api/nutrition/trends?from=...&to=...

GET    /api/admin/dashboard
GET    /api/admin/users
GET    /api/admin/foods
GET    /api/admin/audit-logs
GET    /api/admin/search
```

所有列表 API 應採一致的分頁、排序與篩選格式；錯誤回應使用 Problem Details 並包含可供追查的 `traceId`。

## 測試策略

- Flutter unit / widget tests
- Flutter integration tests
- ASP.NET Core service unit tests
- `WebApplicationFactory` API integration tests
- Testcontainers + PostgreSQL 資料庫整合測試
- CI 執行 analyze、build、test、migration verification 與 container build

## 開發原則

- Widget 不放商業邏輯。
- Repository 是前端資料來源的抽象邊界。
- 使用者只能操作自己的紀錄，前端不得傳入或信任 `UserId`。
- 管理權限必須由後端 Admin policy 驗證，前端路由保護不是安全邊界。
- 時間以 UTC 傳輸，顯示時轉換為使用者時區。
- 不因履歷展示而過早加入微服務、Redis、訊息佇列或 Elasticsearch。
- 優先交付可測試的端到端功能，再逐步增加架構複雜度。

## 專案狀態

目前處於 Phase 1：前端骨架與 UI Prototype。

- [x] 建立 Flutter Web、Android、iOS 專案骨架
- [x] 建立最小 FoodLedger Material 3 啟動畫面
- [x] 建立基礎 Widget Test
- [ ] 建立 Design Tokens 與完整 Theme
- [ ] 導入 Riverpod 與 GoRouter
- [ ] 建立手機／桌面響應式 App Shell
- [ ] 建立 Mock Repositories
- [ ] 完成首頁、紀錄、會員與管理後台 Prototype
