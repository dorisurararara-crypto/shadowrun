/// Shadow Run 법적 문서 — 이용약관 / 개인정보처리방침
///
/// 한국어 우선 (주 타겟 시장: 한국). 앱 내 Privacy/Terms 바텀시트에서 참조.
/// 배포일: 2026-04-17. 앱 버전 1.0.0 기준.
///
/// 변경 시 [LegalTexts.lastUpdated] 갱신.
class LegalTexts {
  LegalTexts._();

  static const String lastUpdated = '2026-04-17';
  static const String developer = 'dorisurararara';
  static const String contactEmail = 'dorisurararara@gmail.com';
  static const String appName = 'Shadow Run';

  // ======================================================================
  // 개인정보 처리방침 (한국어)
  // ======================================================================
  static const String privacyPolicyKo = '''
$appName 개인정보 처리방침

최종 갱신: $lastUpdated

$appName(이하 "앱")은 이용자의 개인정보를 소중히 다루며, 『개인정보 보호법』
및 관련 법령을 준수합니다. 본 방침은 앱이 수집·이용·보관·보호하는 개인정보에
대해 투명하게 설명합니다.

[ 1. 수집하는 정보 ]

가. 기기 내부에만 저장되며 외부로 전송되지 않는 정보
  • 러닝 기록 : 거리·시간·페이스·경로(좌표)·심박수·칼로리
  • 프로필 사진 : 사용자가 선택해 기기에 저장한 얼굴 이미지
  • 설정 값 : 언어·테마·음성·공포 레벨·러닝화 등
  • 위치 정보(GPS) : 러닝 중 경로 추적용, 백그라운드 실시간

나. 결제 사업자를 통해서만 처리되는 정보
  • Apple App Store In-App Purchase / Google Play Billing
  • 앱은 구매 완료 여부(엔타이틀먼트 토큰)만 읽을 뿐
    카드번호·은행 정보를 직접 수집하지 않습니다.

다. 광고 식별자 (비 PRO 이용자에 한함)
  • Google AdMob이 기기 광고 ID(IDFA/GAID)를 사용하여 광고를 표시
  • 이용자는 OS 설정에서 언제든 재설정·차단할 수 있습니다.

[ 2. 수집 목적 ]

  1) 러닝 기록 저장 및 개인 통계 제공
  2) 도플갱어 추격 모드에서 과거 기록을 기반으로 경쟁 생성
  3) 프로필 사진을 지도 위 러너 마커로 표시
  4) PRO 기능(공포 레벨 3~5, 무제한 도전 등) 해제
  5) 비 PRO 이용자의 무료 앱 운영을 위한 광고 표시

[ 3. 보유 및 이용 기간 ]

  • 러닝 기록·설정·프로필 : 이용자가 앱을 삭제하거나 기기에서 초기화할 때까지
  • 결제 내역 : Apple / Google 계정 정책에 따름
  • 앱이 별도의 서버에 데이터를 업로드하거나 백업하지 않습니다.

[ 4. 제3자 제공 ]

$appName은 수집한 개인정보를 제3자에게 제공하지 않습니다. 다만 다음 경우는
예외입니다.

  • 법령이 이를 명시적으로 규정한 경우
  • 수사기관이 적법한 절차로 요구한 경우
  • 이용자의 생명·신체에 대한 급박한 위험을 막기 위해 필요한 경우

[ 5. 처리 위탁 ]

서비스 품질 개선을 위해 아래 사업자의 SDK를 이용합니다. 각 사업자는 자체
개인정보 처리방침을 따릅니다.

  • Google (Firebase 크래시 로그, Naver Map, Google Play Billing)
  • Apple (iOS App Store Connect, In-App Purchase)
  • Google AdMob (비 PRO 광고 노출 시에만)

[ 6. 이용자 권리 ]

  • 앱 삭제 : 기기 내 모든 러닝 기록·사진이 즉시 제거됩니다.
  • 설정 > 프로필 : 프로필 사진을 언제든 변경/삭제할 수 있습니다.
  • 위치 권한 : OS 시스템 설정에서 언제든 철회할 수 있습니다.
    (단, 러닝 경로 추적이 불가능해집니다.)
  • 문의 : $contactEmail

[ 7. 아동의 개인정보 ]

$appName은 만 14세 미만 아동을 대상으로 하지 않습니다. 실수로 아동의 정보가
수집된 경우 즉시 삭제하며, 보호자의 요청이 있을 경우 관련 모든 자료를 삭제합니다.

[ 8. 방침 변경 ]

본 방침이 변경되는 경우 앱 업데이트와 함께 변경 사항을 공지하며, 최종 갱신일을
갱신합니다. 중대한 변경 시 앱 실행 화면에서 별도 안내합니다.

[ 9. 연락처 ]

  개발자    : $developer
  이메일    : $contactEmail
  문의 시간 : 이메일 수령 후 7영업일 이내 회신

$appName을 이용해 주셔서 감사합니다.
''';

  // ======================================================================
  // Privacy Policy (English)
  // ======================================================================
  static const String privacyPolicyEn = '''
$appName Privacy Policy

Last updated: $lastUpdated

$appName ("the App") respects your privacy and complies with applicable data
protection laws including GDPR, CCPA, and Korea's Personal Information
Protection Act. This policy explains how the App collects, uses, stores, and
protects your information.

[ 1. Information We Collect ]

A. Stored only on your device, never transmitted
  • Run data: distance, duration, pace, route (GPS coordinates), heart rate,
    calories
  • Profile photo: face image you select and save locally
  • Settings: language, theme, voice, anxiety level, shoes, etc.
  • Location (GPS): used to trace your run path in real time

B. Handled solely by payment providers
  • Apple App Store In-App Purchase / Google Play Billing
  • The App only reads entitlement tokens indicating purchase completion.
    We never see card numbers or banking details.

C. Advertising identifier (free tier only)
  • Google AdMob uses your device advertising ID (IDFA / GAID) to show ads.
  • You may reset or block this ID anytime in OS settings.

[ 2. Purpose ]

  1) Save running records and present personal statistics
  2) Generate doppelgänger chase runs from your own past records
  3) Display your profile photo as a runner marker on the map
  4) Unlock PRO features (anxiety levels 3-5, unlimited challenges, etc.)
  5) Show ads in the free tier to sustain the App

[ 3. Retention ]

  • Runs / settings / profile: until you uninstall the App or wipe the device
  • Purchase history: governed by Apple / Google account policy
  • We do not upload or back up your data to our servers.

[ 4. Third-Party Disclosure ]

We do not sell or share your personal information with third parties, except:

  • When required by law
  • When a competent authority demands disclosure through due process
  • When necessary to prevent imminent harm to your life or safety

[ 5. Service Providers ]

The App uses the following SDKs to improve quality. Each provider maintains its
own privacy policy.

  • Google (Firebase crash logs, Naver Map, Google Play Billing)
  • Apple (iOS App Store Connect, In-App Purchase)
  • Google AdMob (only on the free tier)

[ 6. Your Rights ]

  • Uninstall : removes all records and photos from your device instantly.
  • Settings > Profile : change or delete your profile photo anytime.
  • Location : revoke GPS permission in OS settings anytime
    (run path tracking will no longer work).
  • Contact : $contactEmail

[ 7. Children ]

$appName is not directed at children under 14. If a child's data is collected
by mistake, we delete it immediately. Guardians may request removal of any
related records.

[ 8. Changes ]

If we update this policy we will announce changes with the App update and
refresh the "Last updated" date above. Material changes will trigger an
in-app notice.

[ 9. Contact ]

  Developer : $developer
  Email     : $contactEmail
  Response  : within 7 business days of receiving your email

Thank you for running with $appName.
''';

  // ======================================================================
  // 이용약관 (한국어)
  // ======================================================================
  static const String termsOfServiceKo = '''
$appName 이용약관

최종 갱신: $lastUpdated

본 약관은 $appName(이하 "앱")을 이용함에 있어 이용자와 개발자 사이의 권리,
의무 및 책임 사항을 규정합니다.

[ 제1조 (목적) ]

본 약관은 이용자가 앱이 제공하는 러닝 기록·도플갱어 추격·엔터테인먼트 기능을
이용함에 있어 발생하는 제반 사항을 정함을 목적으로 합니다.

[ 제2조 (용어의 정의) ]

  1. "이용자" : 앱을 스마트폰 또는 스마트워치에 설치하여 사용하는 자
  2. "PRO" : 유료 구독 또는 단건 구매를 통해 활성화되는 확장 기능
  3. "도플갱어 모드" : 과거 본인의 러닝 기록을 가상 러너로 재생해 추격당하는 모드
  4. "공포 레벨" : 점프스케어·음성·진동의 강도를 조절하는 1~5 단계

[ 제3조 (이용계약의 성립) ]

이용자가 앱을 설치하여 실행함으로써 본 약관에 동의한 것으로 간주하며, 이때
이용계약이 성립합니다. 미동의 시 즉시 앱을 삭제해 주십시오.

[ 제4조 (이용자의 의무) ]

  1) 러닝 중에는 주변 교통·보행자·지형·기상 상태를 항상 주의해야 합니다.
     $appName은 청각·시각을 점유할 수 있으므로, 도로 위에서 이어폰을 착용한 채
     도플갱어 모드를 시작하지 마십시오.
  2) 본인의 건강 상태에 맞는 강도로 러닝하십시오. 심박·혈압·관절 질환이 있는
     경우 의사 상담 후 이용을 권장합니다.
  3) 타인 또는 공공장소에서 허용되지 않은 방식으로 사진을 촬영·저장하지 마십시오.
  4) 앱을 리버스 엔지니어링하거나 결제 시스템을 우회하려 시도하지 마십시오.

[ 제5조 (앱의 의무) ]

  1) 앱은 안정적인 러닝 기록과 PRO 기능을 제공하기 위해 성실히 노력합니다.
  2) 앱은 이용자의 기록·사진·설정을 기기 내부에만 저장하며 외부로 전송하지
     않습니다.
  3) 앱은 법령이 정한 경우를 제외하고 이용자의 개인정보를 제3자에게 제공하지
     않습니다. (자세한 내용: 개인정보 처리방침 참조)

[ 제6조 (결제 및 환불) ]

  1) PRO 구매는 Apple App Store 또는 Google Play Store를 통해 처리됩니다.
  2) 환불 정책은 각 스토어의 기준을 따릅니다.
     • Apple : iTunes/App Store Support를 통해 신청
     • Google : Google Play Support를 통해 신청
  3) 무료 체험은 최초 1회 한정 7일간 제공되며, 체험 종료 시 자동으로 무료
     이용자로 전환됩니다. 체험 중 구매한 테마는 유지됩니다.
  4) 테마팩은 단건 구매이며 환불 후에는 해당 테마 사용이 불가합니다.

[ 제7조 (서비스 제공 중지) ]

다음 각 호의 경우 앱의 일부 또는 전부의 제공이 일시적으로 중단될 수 있습니다.
이 경우 사전 고지가 어려운 경우 사후 공지합니다.

  • OS 업데이트에 따른 호환성 문제
  • 결제 시스템(Apple/Google) 장애
  • 앱 업데이트 배포 시 긴급 점검
  • 서비스 운영상 합리적 사유

[ 제8조 (책임 제한) ]

  1) 앱은 엔터테인먼트 목적이며 의료·운동 전문 기관이 아닙니다.
     러닝 중 발생한 부상, 사고, 건강상의 문제에 대해 앱은 책임지지 않습니다.
  2) 공포 레벨 3~5는 급격한 심박 상승·불안·놀람 반응을 유발할 수 있습니다.
     심혈관 질환, 공황장애, 임신 중, 미성년자 등은 사용을 자제하십시오.
  3) GPS 오차, 기기 성능, 배터리 상태 등에 의해 러닝 기록이 부정확할 수 있으며,
     앱은 이를 공식 기록으로 보증하지 않습니다.
  4) 타인 또는 공공기물과의 충돌로 발생한 손해는 이용자 본인에게 책임이 있습니다.

[ 제9조 (지적재산권) ]

앱의 디자인·텍스트·한자 장식·영상·음성·음악·효과음·로고 등 모든 저작물은
개발자에게 저작권이 있으며, 무단 복제·배포·2차 창작이 금지됩니다.

[ 제10조 (약관의 변경) ]

약관이 변경되는 경우 앱 내 공지 및 업데이트 설명을 통해 고지합니다. 변경 이후
앱을 계속 이용하시면 변경된 약관에 동의한 것으로 간주됩니다. 동의하지 않으실
경우 앱을 삭제해 주십시오.

[ 제11조 (분쟁 해결) ]

본 약관과 관련한 분쟁이 발생할 경우 개발자와 이용자는 성실히 협의합니다.
협의가 이루어지지 않을 경우, 관할 법원은 민사소송법에 따른 서울중앙지방법원으로
합니다.

[ 제12조 (연락처) ]

  개발자    : $developer
  이메일    : $contactEmail
  문의 시간 : 이메일 수령 후 7영업일 이내 회신

$appName과 함께 안전하게 달리세요.
''';

  // ======================================================================
  // Terms of Service (English)
  // ======================================================================
  static const String termsOfServiceEn = '''
$appName Terms of Service

Last updated: $lastUpdated

These Terms govern the rights, duties, and responsibilities between users and
the developer when using $appName ("the App").

[ 1. Purpose ]

These Terms define the conditions under which you use the App's running
records, doppelgänger chase, and entertainment features.

[ 2. Definitions ]

  1. "User" — anyone who installs and runs the App on a phone or smartwatch
  2. "PRO" — extended features unlocked by subscription or one-time purchase
  3. "Doppelgänger Mode" — mode in which a past run is replayed as a ghost
     runner that chases you
  4. "Anxiety Level" — intensity of jumpscares / audio / haptics, levels 1-5

[ 3. Formation of the Contract ]

By installing and launching the App you are deemed to have accepted these
Terms, and the user contract is formed at that moment. If you do not agree,
please uninstall the App immediately.

[ 4. User Obligations ]

  1) Always be alert to traffic, pedestrians, terrain, and weather while
     running. The App can occupy your ears and eyes — do NOT start
     Doppelgänger Mode on a road while wearing earphones.
  2) Run at an intensity suited to your health. If you have any cardiac,
     vascular, or joint conditions, consult a physician before using the App.
  3) Do not photograph or store images of others in a manner not permitted
     by law or the venue.
  4) Do not reverse-engineer the App or attempt to bypass payment systems.

[ 5. Developer Obligations ]

  1) We strive to provide stable running records and PRO features.
  2) We store your records, photos, and settings only on your device and do
     not transmit them externally.
  3) We do not share your personal information with third parties except as
     required by law. (See our Privacy Policy for details.)

[ 6. Payments and Refunds ]

  1) PRO purchases are handled by the Apple App Store or Google Play Store.
  2) Refund policies follow each store's rules:
     • Apple : request through iTunes/App Store Support
     • Google : request through Google Play Support
  3) The free trial is offered once for 7 days. When it ends you are
     automatically moved to the free tier. Themes purchased during the trial
     remain yours.
  4) Theme packs are one-time purchases. Refunded themes can no longer be used.

[ 7. Service Interruption ]

Part or all of the App may be temporarily unavailable in the following cases.
When advance notice is not possible we will notify you afterwards.

  • Compatibility issues caused by OS updates
  • Payment system (Apple / Google) outage
  • Urgent maintenance during app updates
  • Reasonable operational causes

[ 8. Limitation of Liability ]

  1) The App is for entertainment and is not a medical or sports authority.
     We are not liable for any injury, accident, or health issue that occurs
     during a run.
  2) Anxiety levels 3-5 may trigger rapid heart rate, anxiety, or startle
     responses. Please refrain from use if you have cardiovascular disease,
     panic disorder, are pregnant, or are a minor.
  3) GPS accuracy, device performance, and battery state may cause inaccurate
     running records; we do not guarantee them as official results.
  4) You are solely responsible for any damage caused by collisions with
     others or public property.

[ 9. Intellectual Property ]

All creative works in the App — design, text, hanja decoration, video, audio,
music, sound effects, logos, etc. — belong to the developer. Unauthorized
copying, distribution, or derivative works are prohibited.

[ 10. Amendments ]

If we amend these Terms we will announce the changes in-app and in the update
notes. Continued use after the change constitutes acceptance. If you do not
agree, please uninstall the App.

[ 11. Disputes ]

In the event of a dispute the parties will negotiate in good faith. If
negotiation fails, the competent court is the Seoul Central District Court
(South Korea) pursuant to the Korean Civil Procedure Act.

[ 12. Contact ]

  Developer : $developer
  Email     : $contactEmail
  Response  : within 7 business days of receiving your email

Run safely with $appName.
''';
}
