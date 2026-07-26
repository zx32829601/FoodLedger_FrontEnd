# 後端 API Contract 對接索引

本文件整理 FoodLedger 後端已確認的 API 契約，作為 Flutter 前端後續 DTO、API Service、Repository、Provider 與畫面實作依據。

> 後端 `docs/specs` 內的原始規格為唯一契約來源。若本文件、OpenAPI 或實際 API 行為不一致，應先與後端確認並同步規格，不在前端自行猜測欄位或錯誤格式。

## 規格來源

後端專案：`FoodLedger_BackEnd_By.Net`

- `docs/specs/auth-and-api-error-response.md`
- `docs/specs/defined-codes.md`
- `docs/specs/daily-records.md`
- `docs/specs/nutrition-summary.md`
- PR #18：`docs: add auth and daily record specs`
- PR #19：`docs: add nutrition summary spec`

## 共通對接原則

- JSON 欄位使用後端契約定義的 lower camel case。
- 所有需要登入的 API 使用目前登入身分，不傳遞或信任前端提供的 `userId`。
- 時間以 UTC 與 API 交換，前端顯示時才轉換為使用者時區。
- API 錯誤採 code-first；前端以 `code` 對應顯示文案，`message` 只作為 fallback。
- `traceId` 必須保留在錯誤模型中，供使用者回報與後端追查，但不得包含在一般 Log 的敏感資料中。
- API Base URL 透過 `FOOD_LEDGER_API_BASE_URL` 注入；不得 commit Token、密碼、Cookie、Connection String 或私鑰。

## Auth 與目前使用者

正式前端只使用 FoodLedger 自訂 Auth API：

| 方法 | Path | 用途 | 授權 |
| --- | --- | --- | --- |
| `POST` | `/api/auth/register` | 註冊並取得 Token 與使用者資料 | 否 |
| `POST` | `/api/auth/login` | 使用帳號或 Email 登入 | 否 |
| `GET` | `/api/users/me` | 取得目前登入使用者 | 是 |

### 註冊 Request

```json
{
  "userAccount": "food_user",
  "displayName": "Food 使用者",
  "email": "user@example.com",
  "password": "<由使用者輸入>"
}
```

欄位規則：

- `userAccount`：4 到 30 個字元；只允許英文字母、數字、底線與連字號；不得包含 `@` 或空白；唯一性不分大小寫。
- `displayName`：1 到 30 個字元；前後空白會 trim；可重複且不參與登入。
- `email`：必填、格式有效且唯一。
- `password`：至少 8 個字元，必須包含數字、英文小寫與英文大寫，不強制特殊符號。

### 登入 Request

```json
{
  "loginId": "food_user",
  "password": "<由使用者輸入>"
}
```

- `loginId` 可輸入 `userAccount` 或 Email。
- 包含 `@` 時後端視為 Email，否則視為 `userAccount`。
- 登入失敗統一使用 `Auth.InvalidCredentials`，前端不得顯示帳號或 Email 是否存在。

### Auth Response

註冊與登入成功皆回傳：

```json
{
  "accessToken": "...",
  "refreshToken": "...",
  "expiresIn": 3600,
  "user": {
    "userId": 1,
    "userAccount": "food_user",
    "displayName": "Food 使用者",
    "email": "user@example.com"
  }
}
```

`GET /api/users/me` 回傳與上方 `user` 相同的使用者 DTO。

前端不得繼續把 Identity 內建 `/register`、`/login`、`/manage/info` 視為正式契約。完整 Refresh Token 流程尚未納入目前規格，不應自行推測端點或行為。

## 統一 API 錯誤

### 一般錯誤

```json
{
  "code": "DailyRecord.NotFound",
  "message": "找不到指定的飲食紀錄。",
  "traceId": "...",
  "parameters": {
    "recordId": "123"
  }
}
```

### 欄位驗證錯誤

```json
{
  "code": "Validation.Failed",
  "message": "請確認輸入資料是否正確。",
  "traceId": "...",
  "errors": {
    "quantityInGrams": [
      {
        "code": "DailyRecord.QuantityMustBeGreaterThanZero",
        "message": "數量必須大於 0。",
        "parameters": {
          "min": 0
        }
      }
    ]
  }
}
```

前端錯誤模型至少需要保留：

- `code`
- `message`
- `traceId`
- `parameters`
- `errors` 中每個欄位的錯誤 `code`、fallback `message` 與 `parameters`

已確認的重要錯誤碼：

- `Auth.InvalidCredentials`
- `Auth.UserAccountAlreadyExists`
- `Auth.EmailAlreadyExists`
- `Validation.Failed`
- `DailyRecord.InvalidMealType`
- `DailyRecord.NotFound`
- `System.UnexpectedError`

## DefinedCode 與餐別

| 方法 | Path | 用途 | 授權 |
| --- | --- | --- | --- |
| `GET` | `/api/defined-codes/meal-types` | 取得可用餐別選項 | 否 |

Response item：

```json
{
  "code": "Breakfast",
  "displayName": "早餐",
  "sortOrder": 1
}
```

前端規則：

- 餐別 Select 不 hardcode code、顯示名稱或排序。
- API 只回傳 `IsActive = true` 的 `MealType`，並依 `sortOrder` 由小到大排序。
- 第一版 seed 為 `Breakfast`、`Lunch`、`Dinner`、`Snack`。
- `mealTypeCode` 是資料契約；`displayName` 只用於顯示。
- 載入失敗時應顯示可重試狀態，不使用前端自建餐別清單冒充後端結果。

待後端確認：DailyRecord 歷史資料可保留 inactive `mealTypeCode`，但目前餐別 API 只回 active code，且 DailyRecord 不回 `mealTypeDisplayName`。前端遇到查不到的歷史 code 時暫以原始 code 作為 fallback，不自行改寫資料。

## DailyRecord

| 方法 | Path | 用途 | 授權 |
| --- | --- | --- | --- |
| `GET` | `/api/daily-records?date=yyyy-MM-dd` | 取得指定日期的紀錄 | 是 |
| `POST` | `/api/daily-records` | 新增紀錄 | 是 |
| `PUT` | `/api/daily-records/{recordId}` | 修改自己的紀錄 | 是 |
| `DELETE` | `/api/daily-records/{recordId}` | 實體刪除自己的紀錄 | 是 |

新增與修改 Request：

```json
{
  "foodId": 10,
  "quantityInGrams": 150,
  "consumedAt": "2026-07-26T12:30:00Z",
  "mealTypeCode": "Lunch",
  "note": "今天吃比較少"
}
```

規則：

- 不傳 `userId`。
- `foodId` 必須存在。
- `quantityInGrams` 必須大於 0 且不超過 10000。
- `consumedAt` 不得晚於目前 UTC，送出前轉為 UTC。
- `mealTypeCode` 必須是 active `MealType`。
- `note` 選填，trim 後空字串視為 `null`，最大長度 500。
- `GET` 回 flat list，前端依 `mealTypeCode` 與 DefinedCode dictionary 分組。
- 查詢結果依 `consumedAt`、`recordId` 排序。
- 修改或刪除不存在、或不屬於目前使用者的紀錄，一律視為 404。
- 刪除成功回 `204 No Content`，第一版為實體刪除。

DailyRecord Response item：

```json
{
  "recordId": 1,
  "foodId": 10,
  "foodName": "雞胸肉",
  "quantityInGrams": 150,
  "consumedAt": "2026-07-26T12:30:00Z",
  "mealTypeCode": "Lunch",
  "note": "今天吃比較少",
  "nutrients": [
    {
      "nutrientId": 1,
      "code": "Protein",
      "displayName": "蛋白質",
      "amount": 46.5,
      "unit": "g"
    }
  ]
}
```

`nutrition-summary.md` 已明確指定對外欄位使用 `quantityInGrams`，因此前端不使用舊草稿中的 `quantity`。

## Nutrition Summary

| 方法 | Path | 用途 | 授權 |
| --- | --- | --- | --- |
| `GET` | `/api/nutrition-summary/daily?date=yyyy-MM-dd` | 單日總量與餐別統計 | 是 |
| `GET` | `/api/nutrition-summary/weekly?date=yyyy-MM-dd` | 焦點日期所在週的統計 | 是 |

### Daily Summary

Response：

- `date`
- `totals`
- `mealTypes`
- `mealTypes` 每項包含 `mealTypeCode` 與 `totals`
- 不包含 DailyRecord 明細

無紀錄時仍回 `200 OK`，`totals` 與餐別統計可為空集合。

### Weekly Summary

Response：

- `startDate`
- `endDate`
- `totals`
- `days`
- `days` 永遠包含週一到週日共 7 筆
- 沒資料的日期回 `totals = []`

`date` 是焦點日期，後端負責計算該日期所在的週一到週日。前端切換週期時傳入新的焦點日期，不自行改變後端週期定義。

### Nutrient

營養素 item：

```json
{
  "nutrientId": 1,
  "code": "Protein",
  "displayName": "蛋白質",
  "amount": 95.2,
  "unit": "g"
}
```

前端規則：

- 顯示時才格式化與四捨五入，不使用格式化字串進行運算。
- API 只回有資料的 nutrient；缺少的 nutrient 不可自行補 0。
- `DailyRecords` 負責紀錄明細，`NutritionSummary` 負責統計聚合，前端不混用兩者責任。
- 營養素由後端依最新 FoodNutrient 即時計算；前端不保存或推測 snapshot。

## 前端目前待遷移項目

| 區域 | 目前狀態 | 應調整方向 |
| --- | --- | --- |
| Auth path | 使用 Identity 內建 `/register`、`/login`、`/manage/info` | 改用 `/api/auth/register`、`/api/auth/login`、`/api/users/me` |
| 註冊表單 | 只有 Email 與 Password | 加入 `userAccount`、`displayName` |
| 登入表單 | 只接受 Email | 改為 `loginId`，支援帳號或 Email |
| Auth response | Token 與使用者資料分開取得 | 使用自訂 Auth response 的 `token + user` |
| API error | 依 HTTP status 與 Identity errors 推測 | 改為 code-first 與欄位錯誤 DTO |
| 餐別 | Flutter enum hardcode | 改由 DefinedCode API 載入 |
| DailyRecord | 使用 Mock Repository 與既有 domain 欄位 | 建立正式 DTO、API Service、Repository 與 CRUD |
| Nutrition | 使用 Mock Repository 計算 | 改串 daily / weekly summary，保留 UI 狀態邊界 |

## 建議前端實作順序

1. 建立 code-first API error DTO 與錯誤碼文案 mapping。
2. 更新 Auth DTO、表單、Repository 與 Session 流程。
3. 建立 DefinedCode DTO、Repository 與餐別載入狀態。
4. 建立 DailyRecord DTO 與查詢、新增、修改、刪除流程。
5. 建立 Daily 與 Weekly Nutrition Summary DTO、Repository 與畫面狀態。
6. 依 OpenAPI 與後端整合測試逐一驗證成功、驗證錯誤、401、404 與空資料情境。

## 不得 Commit 的資訊

- 真實密碼、Access Token、Refresh Token、Cookie。
- API key、私鑰、憑證、Android keystore、iOS certificate。
- Connection String、資料庫帳密、正式環境內部服務位址。
- 包含真實個資的 API response、Log 或測試資料。

`FOOD_LEDGER_API_BASE_URL` 是非敏感環境設定，但不同環境的實際值應由執行或部署環境注入。
