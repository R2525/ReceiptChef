# Receive Flutter — AI 영수증/식자재 매니저 (간단 가이드)

이 앱은 **영수증을 촬영/선택 → 항목 추출 → 결제목록/식자재 관리**를 돕는 간단한 예제 앱입니다.  
Google **Generative AI (Gemini)** 를 사용해 영수증 인식을 보조하고, 채팅으로 간단한 질의도 할 수 있습니다.

---

## 핵심 기능 (What this app does)

- **영수증 분석**: 채팅 화면에서 카메라/앨범을 선택해 영수증 이미지를 업로드하면, 품목/금액/날짜를 추출해 **결제목록**과 **식자재**에 반영
- **결제목록/상세**: 영수증별로 묶인 품목을 보고, 상세 화면에서 카테고리별 목록을 확인
- **식자재 관리**: 식자재 탭에서 모든 식자재를 일괄 확인
  - 유통기한이 오늘보다 **이전**이면 **빨간 배지(“유통기한 지남”)** 표시
  - 각 항목에 **삭제 버튼** 제공
- **채팅**: Gemini로 간단한 Q&A
  - 채팅을 이용한 **삭제/변경** 은 미구현

> 참고: 인증은 데모용(로컬)이며, `ApiService`는 샘플 서버 엔드포인트를 가리키도록 작성되어 있습니다.

---

### 1 Google Generative AI **API Key** 설정
파일: **`lib/services/generative_ai_service.dart`**

```dart
class GenerativeAIService {
  static const String _apiKey = "YOUR_GOOGLE_AI_STUDIO_API_KEY"; // ← 여기에 본인 키
  ...
}
```

- 키 발급: [Google AI Studio](https://aistudio.google.com/) 에서 발급

### 2 API 서버 베이스 URL (미완성)
파일: **`lib/services/api_service.dart`**

```dart
class ApiService {
  // 자신의 IP/도메인으로 변경
  static const String _baseUrl = 'http://192.168.xxx.xxx:8000';
  ...
}
```

---

## 개발 환경 (Prerequisites)

- **Flutter** (stable 최신) / **Dart**
---

## 사용 방법 (How to use)

1. **앱 실행 → 로그인**
   - 데모용 로그인: 이메일/패스워드 임의 입력 후 로그인 (로컬 상태 저장)
2. **하단 탭**
   - **결제목록**: 인식된 영수증이 카드 리스트로 표시됩니다.
   - **식자재**: 전체 식자재를 한 번에 확인.  
     - 유통기한이 지났다면 **빨간 ‘유통기한 지남’ 배지**가 표시됩니다.  
     - 각 항목의 **휴지통 아이콘(삭제 버튼)** 으로 개별 삭제가 가능합니다.
   - **채팅**: 우측 하단의 **+ 버튼** → **카메라/앨범** 선택 → 영수증 업로드/분석.
3. **영수증 상세**
   - 영수증 카드를 탭하면 카테고리별 품목 목록과 금액을 볼 수 있습니다.

---

## 주요 파일 구조 (Key files)

- `lib/screens/main_app.dart` — 하단 탭(결제목록/식자재/채팅/설정) 및 화면들
- `lib/screens/receipt_detail_screen.dart` — 영수증 상세 화면 (**경과 배지/삭제 UI 반영**)
- `lib/screens/chat_screen.dart` — 채팅 + 영수증 분석(카메라/앨범)
- `lib/services/generative_ai_service.dart` — **Gemini 연동, API Key 설정 위치**
- `lib/services/api_service.dart` — (옵션) 샘플 서버 API 엔드포인트
- `lib/providers/auth_provider.dart` — 앱 상태/영수증/식자재 관리 (`removeItemById` 제공)
- `lib/models/payment_item.dart` — 결제/식자재 항목 모델  
  - 여기 **extension** 으로 날짜 유틸 제공:  
    - `item.expiryAsDate` / `item.expiryFormatted` / `item.isExpired`

---
