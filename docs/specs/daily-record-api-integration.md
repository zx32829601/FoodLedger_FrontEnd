# 飲食紀錄正式 API 串接規格

## Problem Statement

Flutter 飲食紀錄目前使用 Mock Repository。DailyRecord domain model 直接持有 Mock Food，餐別由本地 enum 與攝取時間推導，新增與刪除會讓整個列表進入 Loading，也尚未支援正式修改、後端欄位驗證、分頁食物搜尋或營養摘要 API。

若直接將 Mock Repository 替換成 HTTP request，Widget 將承擔資料拼接、錯誤轉換與 mutation 狀態，並且無法正確處理動態餐別、時區、語系、過期搜尋結果及 401 session。

## Solution

在既有 feature 分層內建立明確的 API service、Repository、domain model、sealed failure 與 Riverpod state boundary。食物搜尋、餐別、飲食紀錄與營養摘要全部改用正式 API；query 與 mutation 狀態分離，表單共用欄位與驗證，但新增與修改保有不同 Dialog。

前端不自行計算每日營養摘要，僅顯示後端結果；營養資料模型保留動態清單，第一版 UI 顯示四個核心營養素。

## User Stories

1. 作為使用者，我想搜尋正式食物資料，讓我能記錄真實食物。
2. 作為使用者，我想逐頁載入搜尋結果，讓大量資料仍能順暢操作。
3. 作為使用者，我想選擇後端提供的餐別，讓選項與停用狀態保持一致。
4. 作為使用者，我想輸入克數，讓份量與營養換算清楚一致。
5. 作為使用者，我想獨立設定日期、時間與餐別，讓系統忠實記錄我的實際情境。
6. 作為使用者，我想輸入最多 500 字元的選填備註，讓我能補充飲食情境。
7. 作為使用者，我想查看所選本地日期的紀錄，讓凌晨紀錄不會出現在錯誤日期。
8. 作為使用者，我想依餐別查看紀錄，讓每日內容容易閱讀。
9. 作為使用者，我想修改既有紀錄，讓我能修正食物、克數、時間、餐別與備註。
10. 作為使用者，我想在刪除前確認目標，避免誤刪。
11. 作為使用者，我想在操作失敗時保留原資料與表單內容，讓我可以修正或重試。
12. 作為使用者，我想看到可理解的欄位錯誤，讓我知道如何修正輸入。
13. 作為使用者，我想在 session 過期時回到統一登入流程，而不是看到一般資料錯誤。
14. 作為使用者，我想看到每日熱量、蛋白質、碳水與脂肪摘要。
15. 作為使用者，我想在網路離線或逾時時看到重試選項。
16. 作為使用者，我不希望新增或刪除時整個列表消失。
17. 作為使用者，我想在切換日期後看到正確資料，且慢速舊 request 不會覆蓋新日期。
18. 作為使用者，我想手動重新整理資料，讓其他裝置的變更可以同步。
19. 作為前端工程師，我想隔離 DTO 與 domain model，讓 API contract 變更不會直接滲入 Widget。
20. 作為前端工程師，我想讓 Dio exception 在 data layer 被轉換，避免 presentation layer 依賴 HTTP 實作。
21. 作為前端工程師，我想讓 query 與 mutation 狀態分離，讓畫面能維持既有資料。
22. 作為前端工程師，我想重用新增與修改的表單欄位與驗證，避免規則漂移。
23. 作為前端工程師，我想由單一 locale 與 timezone 來源建立 request，避免各 Widget 硬編碼。
24. 作為未來 React client 的維護者，我希望營養計算由後端統一負責。

## Implementation Decisions

- 正式串接在後端 Food Search、DailyRecord contract 與 Nutrition Summary API 穩定後，以獨立前端 PR 實作。
- Page 與 Widget 不直接使用 Dio。
- API service 負責 HTTP、request DTO 與 response DTO serialization。
- Repository 負責 DTO-to-domain mapping、session 記憶體快取、failure conversion 與資料來源協調。
- 不為單純轉呼叫建立 Use Case；跨 Repository 或可重用商業流程出現後再評估。
- DailyRecord domain model 保存 record ID、food summary、quantityGrams、UTC consumedAt、mealTypeCode 與 note。
- Food summary domain model保存 food ID、food code、display name、實際 lang code 與動態 nutrient list。
- Nutrient domain model保存 code、display name、數值與 unit code。
- MealType 不再使用固定 enum，改用後端驅動的 MealTypeOption model。
- MealTypeOption 包含 code、displayName 與 sortOrder。
- 餐別 options 使用獨立 MealTypeRepository 與 session 記憶體快取。
- 餐別首次載入失敗顯示可重試錯誤，不 fallback 到硬編碼資料。
- Create／Update 回 `DailyRecord.InvalidMealType` 時保留表單、刷新 options，並在 mealTypeCode 欄位提示重新選擇。
- 單一 locale provider 提供 BCP 47 lang code；第一版預設 `zh-TW`。
- 單一 timezone provider 提供 IANA timezone；Widget 不自行建立 timezone string。
- locale 改變時 invalidate Food Search、DailyRecord 與 Nutrition Summary。
- selected date 代表使用者本地日曆日期；Repository 將 date 與 IANA timezone 一併傳給後端。
- consumedAt 在表單以本地日期與時間顯示，提交前轉成 UTC。
- 日期、時間與餐別是獨立欄位；改變任一欄位不得偷偷修改其他欄位。
- 餐別不限制時段；前端可依時間提出預設建議，但使用者可自由修改。
- 建議餐別 code 不在後端 options 時，選擇 sortOrder 第一筆，不建立本地假選項。
- 第一版 API request／response 只使用 `quantityInGrams`，不支援其他份量單位；前端 domain model 內部維持 `quantityGrams`。
- RecordForm 共用食物、quantityGrams、consumedAt、mealTypeCode、note 與基本驗證。
- AddRecordDialog 與 EditRecordDialog 分開，保留各自標題、初始化、成功訊息與 mutation 語意。
- RecordForm 與 Dialog 不直接呼叫 Repository，提交事件交由 mutation controller。
- note trim 後空字串送 null，最大 500 字元，顯示字數提示。
- FoodSearchController 負責 query、debounce、取消舊 request、分頁與 stale response 防護。
- debounce 約 300–400ms；trim 後空 query 不呼叫 API。
- 新 query 從第一頁開始；捲動到底載入下一頁。
- 下一頁錯誤保留既有結果並提供底部重試。
- 搜尋 cache key 使用 query 與 langCode，只做 session 記憶體快取。
- query 變更或 Dialog 關閉時不保留選取狀態。
- dailyRecordsProvider 負責指定日期 query、首次 Loading、Empty、Error、refresh 與 cached data。
- recordMutationProvider 負責 create、update、delete 的 submitting、field errors 與 failure。
- mutation 期間保留列表資料，不把列表 state 改成 AsyncLoading。
- 所有 mutation 採 server-confirmed update，不做 optimistic update。
- CRUD 成功後 invalidate 當日 DailyRecord 與 Nutrition Summary。
- 修改後移到其他日期時，刷新目前日期並顯示紀錄已移動的成功提示。
- 刪除前顯示包含食物名稱與時間的確認 Dialog。
- 刪除期間只停用該筆操作；第一版不提供 Undo。
- Query 可以提供明確重試；POST、PUT、DELETE 不自動 retry。
- mutation 逾時時提示先刷新確認結果，再決定是否人工重送。
- 401 由既有 Authentication Controller 統一處理，不轉成 records failure。
- Records feature 建立 sealed failure，至少區分 validation、not found、network 與 server failure。
- Validation failure 保存 field errors 與可選 traceId。
- 404 修改／刪除顯示紀錄已不存在並刷新列表。
- System failure 保留 traceId 供回報，不顯示 Dio detail 或 stack trace。
- Nutrition Summary domain model保留完整動態 nutrient list。
- 第一版 UI 固定顯示 Calories、Protein、Carbohydrates 與 Fat。
- 核心營養素缺少時顯示破折號，不視為 0。
- UI 使用後端 unitCode 並只做顯示格式化，不重新計算摘要。
- kcal 顯示 0 位或最多 1 位小數；g 最多 1 位；mg／ug 依數值大小顯示 0–2 位。
- 切換日期、CRUD 成功、手動 refresh 與資料過期後 App resume 觸發刷新。
- 不使用固定 polling。
- 同日期可先顯示 session cache，再背景刷新。
- 舊日期或舊 query request 不得覆蓋目前 state。
- 第一版不做持久化離線 cache、離線 mutation queue 或 client-generated temporary record ID。

## Testing Decisions

- 測試外部行為，不測 private helper、Widget 樹細節或 Dio interceptor 內部實作。
- Repository seam 使用 fake API service，不連線正式後端。
- Repository unit test 驗證 DTO mapping、failure conversion、語系／時區參數與 cache 行為。
- Riverpod controller unit test 驗證 query 與 mutation state transition、invalidate、stale response 與錯誤保留。
- FoodSearchController 測試 debounce、取消舊 request、空 query、分頁、下一頁失敗與舊 response 防護。
- MealType provider 測試 session cache、排序、刷新及 invalid meal type recovery。
- RecordForm validator 測試 quantityGrams、未來時間、必填 mealTypeCode、note trim／null 與最大長度。
- Add／Edit Dialog 使用 widget test 驗證 Loading、Disabled、field error、成功關閉與失敗保留輸入。
- Records Page widget test涵蓋 Loading、Empty、Error、Success、refresh 與餐別分組。
- Delete confirmation widget test驗證取消、不重複提交、成功刷新與失敗保留。
- Nutrition Summary widget test驗證四個核心 nutrient、缺值破折號、unit 與格式化。
- 時間測試注入固定 clock 與 timezone，不使用系統目前時間。
- 核心 integration seam 是「登入 → 搜尋食物 → 新增紀錄 → 查看摘要 → 修改 → 刪除」。
- Integration test 以可控制的測試後端或 fake server 執行，不連線正式服務。
- 既有 ApiClient、Authentication Provider、Mock Repository 與 Records Provider 測試可作為風格 prior art。
- 提交前執行 dart format、flutter analyze、flutter test；影響 Web API 行為與畫面時額外執行 flutter build web。

## Out of Scope

- 食物詳細頁與 food detail API。
- FoodPortion 與非克數份量。
- 餐別時間限制。
- 前端營養摘要計算。
- Optimistic mutation 與 Undo delete。
- 固定 polling。
- 永久離線快取、同步 queue 與衝突解決。
- Idempotency key 實作。
- 顯示全部動態營養素的詳細 UI。
- 管理員食物或營養素維護功能。

## Further Notes

- 後端契約規格見 FoodLedger Backend 的 `food-search-and-nutrition.md`。
- 第一版不做 create idempotency key，且 mutation 不自動 retry。
- Idempotency key 未來用於避免 create request 因逾時、斷線或重送造成重複資料。
- 未來 client 應為單次新增操作產生穩定 key；重試必須沿用同一 key，不得每次產生新 key。
- 後端應以目前使用者與 key 建立唯一性邊界，相同 payload 回傳原始結果，不同 payload 重用 key 時拒絕。
- Idempotency key 不得被當成 authentication、authorization 或 record ID。
