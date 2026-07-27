# FoodLedger Frontend

FoodLedger 的跨平台前端，使用 Flutter 建立 Web、Android 與 iOS 共用介面。登入與註冊已有初版 ASP.NET Core Identity 串接，下一步將依後端已確認的 FoodLedger 自訂 Auth 契約遷移；尚未完成後端 API 的頁面由 Mock Repository 維持可操作 Prototype。

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

## 本機啟動

安裝套件：

```powershell
flutter pub get
```

使用 Chrome 啟動 Web：

```powershell
flutter run -d chrome --dart-define=FOOD_LEDGER_API_BASE_URL=http://localhost:5062
```

也可以指定 Edge：

```powershell
flutter run -d edge --dart-define=FOOD_LEDGER_API_BASE_URL=http://localhost:5062
```

Android Emulator 連線本機後端時，需將 API host 改為 `10.0.2.2`：

```powershell
flutter run -d emulator-5554 --dart-define=FOOD_LEDGER_API_BASE_URL=http://10.0.2.2:5062
```

若未提供 `FOOD_LEDGER_API_BASE_URL`，開發環境預設使用 `http://localhost:5062`。Flutter Web 與 API 使用不同 origin 時，後端必須允許前端開發網址的 CORS request。

Flutter 啟動後，可在終端機按 `r` Hot Reload、`R` Hot Restart、`q` 結束。

## 建置步驟

### 1. 建置前檢查

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

上述指令全部通過後再建立 release build。

### 2. Web

```powershell
flutter build web --release --dart-define=FOOD_LEDGER_API_BASE_URL=http://localhost:5062
```

輸出目錄：

```text
build/web/
```

`build/web` 是靜態網站產物，可部署到支援 SPA 的 Web Server 或靜態託管服務。正式部署時需讓未知路由回退至 `index.html`。

### 3. Docker / Docker Compose

先建立本機環境設定：

```powershell
Copy-Item .env.example .env
```

`.env` 的 `FOOD_LEDGER_API_BASE_URL` 必須是使用者瀏覽器可直接連線的 API URL。若要讓同一個 Wi-Fi 的其他電腦使用，不能填 `localhost`，例如：

```dotenv
FOOD_LEDGER_API_BASE_URL=http://192.168.0.177:5062
FOODLEDGER_WEB_HTTP_PORT=8080
FOODLEDGER_WEB_IMAGE=foodledger-web:local
```

建置並啟動 Nginx 容器：

```powershell
.\scripts\deploy-local.ps1
```

網站預設位於 `http://localhost:8080`。Nginx 已設定 Flutter Web SPA 路由回退與 `/health` 健康檢查。

`FOOD_LEDGER_API_BASE_URL` 會在 Docker build 時寫入 Web 產物；修改後必須重新 build，只有重啟容器不會生效。

### 4. Android APK

```powershell
flutter build apk --release
```

輸出檔案：

```text
build/app/outputs/flutter-apk/app-release.apk
```

### 5. Android App Bundle

Google Play 發布建議使用 App Bundle：

```powershell
flutter build appbundle --release
```

輸出檔案：

```text
build/app/outputs/bundle/release/app-release.aab
```

正式簽署前，不得將 keystore、密碼或 signing properties commit 到 Git。

### 6. iOS

iOS 僅能在安裝 Xcode 的 macOS 環境建置：

```bash
flutter build ios --release
```

上架前需在 Xcode 設定 Signing、Bundle Identifier 與 Provisioning Profile。

### 7. 清除建置快取

遇到套件、平台或建置快取問題時，可重新產生：

```powershell
flutter clean
flutter pub get
```

## 品質檢查

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

完整 Coding Style、測試與 Git 規範請參考 [`AGENTS.md`](AGENTS.md)。

## CI/CD

GitHub Actions 的 [`.github/workflows/flutter-web-ci.yml`](.github/workflows/flutter-web-ci.yml) 會在 `main` 的 push 與 pull request 執行：

1. `dart format` 格式檢查。
2. `flutter analyze` 靜態分析。
3. `flutter test` 自動化測試。
4. Flutter Web release build。
5. Production Docker image build。

Jenkins 會依 `Jenkinsfile` 輪詢 Git，驗證 Compose、建立 Docker image，並在 `RUN_LOCAL_DEPLOY=true` 時部署到 Jenkins 主機。`FOOD_LEDGER_API_BASE_URL` 參數留空時會沿用 Jenkins workspace 未提交的 `.env`；手動填值時才會覆寫 `.env`。若網站要提供區網其他裝置使用，請在部署主機的 `.env` 設定：

```text
FOOD_LEDGER_API_BASE_URL=http://<Jenkins 主機的區網 IP>:5062
FOODLEDGER_WEB_HTTP_PORT=8080
```

後端也必須在 Production 設定完全相同的前端 Origin，例如 `http://<Jenkins 主機的區網 IP>:8080`；協定、主機與連接埠任一不同都視為不同 Origin。

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

## API 串接與 Mock Prototype

後端已確認 Auth、統一錯誤、DefinedCode、DailyRecord 與 Nutrition Summary 契約。完整前端對接規則、DTO 欄位與目前待遷移項目請參考：

- [`docs/specs/backend_api_contract_index.md`](docs/specs/backend_api_contract_index.md)

目前前端 Auth 程式仍使用 Identity 內建端點，尚未遷移至已確認的 FoodLedger 自訂 Auth API。後續實作必須改用 `/api/auth/register`、`/api/auth/login` 與 `/api/users/me`，不可再把 `/register`、`/login` 或 `/manage/info` 視為正式契約。

Token 目前只保存在應用程式記憶體，不寫入 Flutter Web 持久儲存；完整 Refresh Token 流程仍等待後端規格確認。

目前在後端食物查詢、飲食紀錄查詢與營養統計 API 完成前，以下功能仍使用記憶體內的 Mock Repository：

- 內建食物資料與每 100 克營養資訊。
- 支援依食物名稱、代碼與描述搜尋。
- 支援選擇餐別、輸入克數並新增紀錄。
- 支援依日期查詢與刪除自己的紀錄。
- 依每日紀錄即時計算熱量、蛋白質、脂肪與碳水化合物。
- 首頁與紀錄頁共用相同 Riverpod 狀態，操作後會同步更新。

Mock 飲食資料只存在記憶體中，重新整理瀏覽器或重新啟動 App 後會回到預設內容。後端 API 完成後，保留 Repository interface，將 Mock 實作替換成 API 實作。

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

## 已確認的主要 API 契約

```http
POST   /api/auth/register
POST   /api/auth/login
GET    /api/users/me

GET    /api/defined-codes/meal-types

GET    /api/daily-records?date=2026-07-26
POST   /api/daily-records
PUT    /api/daily-records/{recordId}
DELETE /api/daily-records/{recordId}

GET    /api/nutrition-summary/daily?date=2026-07-26
GET    /api/nutrition-summary/weekly?date=2026-07-26
```

錯誤回應採 code-first 契約，前端以 `code` 對應文案、保留 `traceId` 供後端追查，並針對 validation error 保存欄位層級錯誤集合。

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
- [x] 建立 Design Tokens 與完整 Theme
- [x] 導入 Riverpod 與 GoRouter
- [x] 建立手機／桌面響應式 App Shell
- [x] 建立 Mock Repositories
- [x] 完成登入、註冊、首頁、紀錄、會員與管理後台 Prototype
