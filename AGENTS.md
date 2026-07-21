# 個人身分

2 年經驗 .NET 軟體開發工程師，具備 OOP 與系統分析基礎，目前透過 FoodLedger 專案學習 Flutter 跨平台前端，並持續往後端工程師方向發展。

--- project-doc ---

# 專案概述

FoodLedger Frontend 是飲食紀錄與營養管理系統的跨平台使用者介面，使用 Flutter 支援 Web、Android 與 iOS。

專案將提供：

- 使用者登入、註冊與帳號管理。
- 今日熱量與營養素摘要首頁。
- 飲食紀錄新增、查詢、修改與刪除。
- 食物搜尋與份量選擇。
- 會員資料與營養目標設定。
- 管理員 Dashboard、使用者、食物資料與 Audit Log 管理。
- 未來透過 ASP.NET Core Admin API 查詢 Elasticsearch，不由 Flutter 直接連線 ELK。

目前先以 UI Prototype、Mock Repository 與響應式版型推進；後續透過 OpenAPI 契約串接 ASP.NET Core 後端。

# 技術棧

## 核心技術

- Flutter / Dart
- Material 3
- Riverpod：狀態管理與依賴注入
- GoRouter：路由、登入狀態與角色導向
- Dio：HTTP Client 與認證攔截器
- Freezed、json_serializable：不可變資料模型與 JSON 轉換
- flutter_secure_storage：手機端敏感資料儲存
- fl_chart：營養與管理統計圖表
- intl：日期、數字與多語系格式

## 後端整合

- ASP.NET Core Web API
- ASP.NET Core Identity
- Swagger / OpenAPI
- Problem Details 錯誤格式
- OpenTelemetry Trace ID

## 套件原則

- 新增套件前，先確認 Flutter SDK 或現有套件是否已提供相同能力。
- 不引入功能高度重疊的狀態管理、路由、HTTP 或序列化套件。
- 新增套件時需確認 Web、Android、iOS 支援狀態及維護活躍度。
- 不為尚未出現的需求預先引入大型框架。
- 任何新增 dependency 都必須有明確使用位置，不保留未使用套件。

# 預定專案結構

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

Feature 原則上依需要包含：

```text
feature/
├─ data/          # DTO、API service、Repository 實作
├─ domain/        # Domain model、Repository interface、必要的 Use Case
└─ presentation/  # Page、Widget、ViewModel / Provider
```

- 簡單功能不強制建立完整三層目錄。
- Use Case 只在跨 Repository、邏輯複雜或會重用時加入。
- Feature 私有元件優先留在 Feature 內，不要過早放進 `core/widgets`。
- `core` 只放真正跨 Feature 共用且語意穩定的能力。

# Coding Style

## Dart 命名慣例

- 檔案與資料夾使用 `lower_snake_case`，例如 `daily_record_page.dart`。
- Class、enum、extension、typedef 與 Widget 使用 `UpperCamelCase`，例如 `DailyRecordPage`。
- 變數、參數、方法與 Provider 使用 `lowerCamelCase`，例如 `selectedDate`、`dailyRecordProvider`。
- 私有成員以 `_` 開頭，例如 `_dio`、`_buildSummaryCard`。
- 常數使用 `lowerCamelCase`，例如 `defaultPageSize`；不要使用全大寫底線格式。
- Boolean 名稱應表達判斷語意，例如 `isLoading`、`hasRecords`、`canEdit`。
- Page 使用 `Page` 結尾，Dialog 使用 `Dialog` 結尾，Repository 使用 `Repository` 結尾。
- API request / response model 依用途使用 `Request`、`Response` 或 `Dto` 結尾。
- Riverpod Provider 名稱使用 `Provider` 結尾；Notifier 類別使用 `Notifier` 或 `Controller` 結尾並保持一致。
- 測試檔案使用 `_test.dart` 結尾，並對應被測檔案路徑。

## 格式與靜態分析

- 所有 Dart 程式碼必須通過 `dart format`。
- 所有變更必須通過 `flutter analyze`，不得新增 warning 或 analyzer ignore 來掩蓋可修正問題。
- 使用 `analysis_options.yaml` 與專案既有 lint；調整 lint 規則必須說明原因。
- Import 依 Dart formatter 與 analyzer 建議整理，移除未使用 import。
- 優先使用 `const` constructor 與 `const` Widget，但不要為追求 `const` 造成難懂的結構。
- 字串原則上使用單引號；若插值或內容可讀性更好，可使用適合的形式。
- 避免 `dynamic`；外部 JSON 必須在 data layer 轉換成明確型別。
- 不使用不必要的 `late` 與強制解包 `!`。若使用，程式結構必須能保證初始化或非 null。
- 非同步操作使用 `async` / `await`，並正確處理錯誤與 Widget lifecycle。
- 在 `await` 後使用 `BuildContext` 前，必須確認 `context.mounted` 或 `mounted`。

## Widget 與 UI

- Widget 只處理顯示與使用者事件轉交，不放 API 呼叫或商業邏輯。
- Page 負責組合畫面；可重用或有獨立語意的區塊拆成 Widget。
- 不以固定行數作為拆分標準，依責任、可讀性、重用性與測試需求拆分。
- 避免單一 `build` 方法包含過深巢狀結構；對具名畫面區塊使用私有 Widget 或方法。
- 重複使用的顏色、間距、圓角與字體必須來自 Theme 或 Design Tokens，不在畫面散落魔法值。
- 優先使用 Material 3 元件與語意，不自行重造按鈕、Dialog、Navigation 等基礎元件。
- 所有主要畫面必須考慮 Loading、Empty、Error、Disabled 與 Success feedback。
- 響應式判斷集中在共用 breakpoint 或 layout 元件，不在各畫面任意使用不同寬度門檻。
- 手機使用 Bottom Navigation，寬螢幕使用 Navigation Rail / Sidebar，但功能與路由保持一致。
- 互動元件需考慮鍵盤操作、Focus、Semantic label、色彩對比與觸控區域。
- 顯示文字不得直接散落於大量 Widget；預留 localization 邊界。

## 狀態管理

- Riverpod Provider 應有明確責任，不建立掌管整個 App 所有狀態的巨型 Provider。
- UI 暫時狀態留在 Widget，例如 Tab、動畫與尚未提交的局部輸入。
- 跨 Widget、非同步或業務狀態由 ViewModel / Notifier 管理。
- API 原始 DTO 不直接成為複雜畫面的可變 UI state；需要時轉換為 domain 或 view state。
- State 優先保持不可變，更新時建立新狀態。
- Provider 不直接依賴 Widget、`BuildContext` 或畫面生命週期。
- 不在 `build` 中觸發副作用；導頁、SnackBar 等副作用使用適合的 listener 或事件流程。
- 登入 session、使用者資料與權限狀態需有單一可信來源。

## API、Repository 與資料模型

- Page / Widget 不直接呼叫 Dio。
- Dio 只存在於 API service / client 邊界。
- Repository interface 隔離 Mock data 與正式 API 實作。
- Service 處理 HTTP 與序列化；Repository 處理快取、錯誤轉換與資料來源協調。
- DTO、domain model 與 UI state 依實際差異分離，不為了形式強制一對一複製。
- API model 必須使用明確型別，不在 presentation layer 操作 `Map<String, dynamic>`。
- 後端錯誤轉換成前端可處理的 sealed failure / exception 類型，不讓 Dio exception 穿透到 Widget。
- 分頁、排序與篩選使用一致的 request / response model。
- 時間以 UTC 與後端交換，顯示時才轉換成使用者時區。
- 金額、營養素與份量計算不得使用格式化後的字串進行運算。
- 使用者 ID 由後端登入身分決定；新增或修改自己的紀錄時，前端不得讓使用者指定 `UserId`。

## Routing 與授權

- 路由名稱與 path 集中管理，不在 Widget 中散落硬編碼 route string。
- GoRouter redirect 可改善登入與角色導向體驗，但不是安全邊界。
- Admin 頁面僅對 Admin 狀態顯示；後端仍必須以 Admin policy 驗證每個管理 API。
- Deep link 進入受保護頁面時，登入完成後應能回到原目標頁面。
- 不在 route query parameter 傳遞 token、密碼或敏感個資。

## 抽象與重構原則

- 不要為了抽象而抽象。
- 只有在能降低重複、隔離明確責任、降低複雜度或提升測試性時才抽出 helper、Widget 或類別。
- 只使用一次且語意清楚的簡單程式碼，優先保留直接寫法。
- 不建立只有單一轉呼叫、沒有隔離價值的 Use Case 或 wrapper。
- Refactor 後若呼叫端更難理解，應保留較簡單的版本。
- 不在功能變更中順便大規模格式化或重構無關檔案。

## 註解與文件

- 程式碼註解與 Dart doc comment 使用繁體中文。
- 匯出的 model、service、repository、notifier 或複雜 Widget 可使用 `///` Dart doc comment。
- 註解應說明設計意圖、限制、副作用與錯誤情境，不重述程式碼表面語法。
- 不為簡單 getter、明顯變數或單純 UI 排版加入冗餘註解。
- TODO 必須描述待處理事項與原因；若有 Issue，附上編號。
- 魔法數字與字串應抽成具名常數，或移到 Theme / Design Tokens。

# 錯誤處理

- 能處理的錯誤才捕捉；不得使用空的 `catch` 吞掉例外。
- UI 顯示可理解的錯誤訊息，不直接顯示 stack trace、Dio 內部錯誤或後端 exception detail。
- Log 不得包含密碼、access token、refresh token、Cookie、完整個資或其他敏感資訊。
- `401` 應交由統一 session 流程處理；`403` 必須與未登入狀態區分。
- 驗證錯誤應能對應到欄位；系統錯誤應保留 `traceId` 供後端追查。
- 網路逾時、離線與伺服器錯誤應有不同的可恢復操作，例如重試。

# 測試規範

## 測試類型

- Domain、formatter、validator、Repository 與 Notifier 使用 unit test。
- 主要 Widget 狀態與互動使用 widget test。
- 登入、新增飲食紀錄等核心流程使用 integration test。
- Repository 測試使用 fake / mock API service，不連線正式後端。

## 測試風格

- 測試檔案名稱使用 `<target>_test.dart`。
- `group` 描述被測類別或功能；`test` / `testWidgets` 描述條件與預期結果。
- 測試名稱使用清楚的繁體中文或一致英文，避免 `test1`、`works` 等無意義名稱。
- 測試內容遵循 Arrange / Act / Assert。
- 每個測試聚焦一個行為，可包含為驗證該行為必要的多個 assertion。
- 測試彼此獨立，不依賴執行順序或共用可變狀態。
- 時間相關測試使用可注入 Clock 或固定時間，不依賴目前系統時間。
- 測試需涵蓋成功、Loading、Empty、Error、權限與邊界情境。
- Golden test 僅用於視覺穩定且維護價值明確的核心元件。

## 變更最低要求

- 新增商業或狀態邏輯必須有 unit test。
- 修正 bug 時，優先先建立能重現問題的失敗測試。
- 重要畫面互動需有 widget test。
- 提交前至少執行：

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

- 影響 Web 平台、路由、套件或建置設定時，額外執行：

```powershell
flutter build web
```

# 安全規範

## 絕對禁止

- 在程式碼、測試、設定檔或 Git commit 寫死 API key、密碼、token、Cookie 或私鑰。
- Commit `.env`、Android keystore、iOS certificate、provisioning profile 或正式服務設定。
- 在 Log、analytics 或錯誤訊息輸出完整 token 與敏感個資。
- Flutter Web 直接連線 PostgreSQL、Elasticsearch 或其他內部資料服務。
- 只依賴前端隱藏按鈕或路由判斷保護管理功能。
- 自行實作密碼雜湊、token 加密或不成熟的驗證協定。

## 必須遵守

- 手機敏感資料使用平台安全儲存；Web 認證策略優先配合後端 Secure、HttpOnly Cookie。
- 正式 API URL 與非敏感環境設定透過 `--dart-define` 或部署環境注入。
- 前端驗證只改善操作體驗，後端仍需驗證所有輸入與權限。
- 外部連結、Deep link 與使用者輸入必須驗證後再使用。
- 管理員功能只能呼叫受後端 Admin policy 保護的 API。

# Git Branch & Commit Naming Conventions

## Branch 命名

格式：

```text
<type>/<description>
```

- 全部使用小寫英文。
- 單字以 hyphen 分隔。
- description 簡短表達單一目的。
- 不使用姓名、日期或 `temp`、`test` 等模糊名稱。

允許類型：

- `feat`：新功能
- `fix`：Bug 修正
- `refactor`：不改變外部行為的重構
- `docs`：文件更新
- `test`：測試新增或調整
- `chore`：套件、工具、建置與維護工作
- `ci`：CI/CD 設定

範例：

```text
chore/initialize-flutter
feat/add-daily-record-form
fix/handle-expired-session
docs/update-development-guide
```

Codex 建立分支時，若產品環境要求 `codex/` 前綴，使用：

```text
codex/<type>-<description>
```

例如：`codex/feat-add-daily-record-form`。

## Commit Message

標題格式：

```text
<type>: <summary>
```

規則：

- type 使用小寫英文，類型與 Branch 規則一致。
- summary 使用簡潔英文祈使語氣，不加句號。
- 每個 commit 聚焦單一邏輯目的，避免混入無關格式化或重構。
- 不使用 `update`、`changes`、`fix stuff` 等無法辨識內容的摘要。
- Commit body 與 Pull Request 說明使用繁體中文。
- Body 說明變更原因、影響範圍與驗證方式，不逐行重述 diff。
- 有 Breaking Change 時必須在 body 明確標示，並說明遷移方式。
- 不得 commit analyzer error、失敗測試、建置產物或敏感資訊。

建議類型：

- `feat`：新增使用者可見功能
- `fix`：修正錯誤
- `refactor`：重構且不改變功能
- `test`：新增或修正測試
- `docs`：文件變更
- `chore`：初始化、依賴或一般維護
- `ci`：CI/CD
- `style`：僅格式且沒有邏輯變更；通常應與原功能 commit 一起處理，避免大量獨立 style commit

範例：

```text
chore: initialize Flutter application
feat: add daily record form
fix: handle expired authentication session
test: add record notifier tests
docs: update frontend architecture
```

需要 body 時：

```text
feat: add daily record form

新增餐別、食物與份量輸入流程，資料暫時由 Mock Repository 提供。
包含表單驗證、載入狀態與新增成功回饋。

驗證：
- flutter analyze
- flutter test
```

## Commit 前流程

1. 執行 `git status -sb`，確認變更範圍。
2. 執行 `git diff`，逐項檢查程式碼、設定與敏感資訊。
3. 執行 formatter、analyzer 與相關測試。
4. 只 stage 本次功能相關檔案，不預設使用 `git add -A` 處理混合工作目錄。
5. 再次執行 `git diff --staged`，確認實際提交內容。
6. 使用符合規範的 commit message。
7. Commit 後確認 `git status -sb` 與分支狀態。

## Pull Request

- PR 標題遵循 `<type>: <summary>`。
- PR 說明使用繁體中文，至少包含：變更內容、原因、影響與驗證結果。
- UI 變更附上 Web 與手機寬度的畫面或錄影。
- 若有未完成項目、已知限制或後端依賴，必須明確列出。
- 不在 PR 中混入與目標無關的套件升級、格式化或重構。

# Agent 工作原則

- 修改前先讀取相關 README、AGENTS.md、現有架構與測試。
- 保留使用者既有修改，不覆蓋或回復無關變更。
- 實作以最小完整垂直切片為單位，避免一次建立大量未使用骨架。
- 每次變更需說明實際驗證結果；未執行的測試不得宣稱通過。
- 發現需求會擴大範圍、改變公開 API 或引入重大套件時，先向使用者說明取捨。
- 除非使用者明確要求，不自行 commit、push、建立 PR 或修改遠端狀態。
