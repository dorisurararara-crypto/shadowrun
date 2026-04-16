# Shadow Run — Claude 작업 지침

## 머신 간 작업 교환: HANDOFF.md

이 프로젝트는 **Windows PC**와 **Mac** 두 머신에서 각각 Claude Code로 개발합니다.
- Windows: 주 개발 (코드 작성)
- Mac: iOS/watchOS 빌드·테스트·배포

### 세션 시작 시 반드시
1. `git pull`
2. `HANDOFF.md` 읽기
3. "## 최신" 블록에 **자기 앞으로 온 요청**이 있는지 확인
4. 있으면 수행 → 결과를 "## 최신"에 덧붙여 적고 → commit → push
5. 처리 완료된 이전 항목은 "## 이력"으로 이동

### 메시지 작성 형식
```
### YYYY-MM-DD HH:MM (From → To)
내용...
```
- From/To 는 `Windows` 또는 `Mac`
- 커밋 메시지: `chore: handoff <짧은 요약>`

### 현재 머신 식별
- 이 지시문을 읽는 Claude는 자신이 어느 머신인지 환경으로 판단:
  - `uname` 결과가 `Darwin` → Mac
  - Windows/WSL → Windows
