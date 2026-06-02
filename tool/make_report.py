import base64, os

base = r"C:\dev\dailyapp"
shots = os.path.join(base, "shots")

def b64(p):
    with open(p, "rb") as f:
        return base64.b64encode(f.read()).decode()

hero = b64(os.path.join(shots, "hero0.png"))
bang = b64(os.path.join(shots, "bang_3.png"))
spin = b64(os.path.join(shots, "tap_3.png"))

html = f"""<!DOCTYPE html>
<html lang="ko"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>리볼버 룰렛 — 완성 보고서</title>
<style>
  :root {{ --bg:#140f0b; --card:#211811; --line:#3a2a1c; --gold:#ffd24a; --red:#c0392b; --txt:#e8d9c5; --mut:#b9a88f; }}
  * {{ box-sizing:border-box; }}
  body {{ margin:0; background:radial-gradient(circle at 30% 10%, #2a1d12, #140f0b 70%); color:var(--txt);
         font-family:'Segoe UI',system-ui,sans-serif; line-height:1.6; padding:32px 18px 60px; }}
  .wrap {{ max-width:980px; margin:0 auto; }}
  h1 {{ font-size:2.1rem; margin:0 0 4px; letter-spacing:2px; }}
  h1 .em {{ color:var(--red); }}
  .sub {{ color:var(--mut); margin-bottom:24px; }}
  .badges {{ display:flex; gap:8px; flex-wrap:wrap; margin:14px 0 26px; }}
  .badge {{ background:#1c2a1c; color:#9fe09f; border:1px solid #2f4a2f; padding:5px 12px; border-radius:20px; font-size:.85rem; font-weight:600; }}
  .grid {{ display:grid; grid-template-columns:repeat(auto-fit,minmax(280px,1fr)); gap:18px; }}
  .card {{ background:var(--card); border:1px solid var(--line); border-radius:14px; padding:18px 20px; }}
  .card h3 {{ margin:0 0 10px; color:var(--gold); font-size:1.05rem; }}
  ul {{ margin:8px 0 0; padding-left:18px; }} li {{ margin:5px 0; }}
  a {{ color:var(--gold); }}
  .links a {{ display:inline-block; background:#2a1d12; border:1px solid var(--line); padding:10px 16px;
             border-radius:10px; margin:6px 8px 0 0; text-decoration:none; font-weight:600; }}
  .shots {{ display:grid; grid-template-columns:repeat(auto-fit,minmax(300px,1fr)); gap:16px; margin-top:14px; }}
  figure {{ margin:0; }} figure img {{ width:100%; border-radius:12px; border:1px solid var(--line); display:block; }}
  figcaption {{ color:var(--mut); font-size:.85rem; margin-top:6px; text-align:center; }}
  .hero img {{ width:100%; border-radius:16px; border:1px solid var(--line); box-shadow:0 10px 40px rgba(0,0,0,.5); }}
  table {{ width:100%; border-collapse:collapse; margin-top:6px; font-size:.92rem; }}
  td {{ padding:7px 8px; border-bottom:1px solid var(--line); }} td:first-child {{ color:var(--mut); width:42%; }}
  .ok {{ color:#9fe09f; font-weight:700; }}
  h2 {{ margin:34px 0 12px; border-left:4px solid var(--red); padding-left:12px; }}
</style></head>
<body><div class="wrap">
  <h1>🔫 <span class="em">REVOLVER ROULETTE</span></h1>
  <div class="sub">오프라인 6연발 러시안룰렛 — 하루에 앱 하나 · 2일차 · 2026-06-02 완성·배포</div>

  <div class="badges">
    <span class="badge">✓ 안드로이드 에뮬 검증</span>
    <span class="badge">✓ 웹 Pages LIVE (200)</span>
    <span class="badge">✓ APK 빌드</span>
    <span class="badge">✓ 오프라인 (백엔드 0)</span>
    <span class="badge">✓ analyze 0 · test 2/2</span>
  </div>

  <div class="hero">
    <img src="data:image/png;base64,{hero}" alt="게임 화면">
  </div>

  <h2>바로 플레이 / 다운로드</h2>
  <div class="links">
    <a href="https://doonghwi.github.io/revolver-roulette/">🌐 웹에서 플레이</a>
    <a href="https://github.com/doonghwi/revolver-roulette">📦 GitHub 저장소</a>
    <a href="https://github.com/doonghwi/revolver-roulette/releases">📱 APK (revolver-roulette-v1.apk)</a>
  </div>
  <p style="color:var(--mut);font-size:.85rem;margin-top:10px;">
    ※ 웹은 첫 로딩 시 가로로 돌려서 보세요. 소리가 안 나면 화면을 한 번 탭한 뒤 시작됩니다(브라우저 오디오 정책).</p>

  <h2>요청사항 충족 체크</h2>
  <table>
    <tr><td>새 폴더 / 새 repo / 새 Pages</td><td class="ok">✓ revolver_roulette / revolver-roulette / 전용 도메인</td></tr>
    <tr><td>오프라인 (Firebase 불필요)</td><td class="ok">✓ 네트워크·백엔드 0</td></tr>
    <tr><td>가로(landscape) 기본</td><td class="ok">✓ 가로 고정 + 몰입형</td></tr>
    <tr><td>측면 리볼버 · 총구 우하향</td><td class="ok">✓ CustomPaint 자작, 우하향</td></tr>
    <tr><td>탭 위치 표시</td><td class="ok">✓ "여기 탭 · TAP" 펄스 표시</td></tr>
    <tr><td>가로 발사 카운터</td><td class="ok">✓ ●●○○○○ + 숫자</td></tr>
    <tr><td>생존 → 실린더 회전음 + 회전</td><td class="ok">✓ 회전 애니메이션 + 카운트+1</td></tr>
    <tr><td>명중 → 발사음 + 빨간 화면 + 리셋</td><td class="ok">✓ 빨간 플래시 + BANG + 재장전</td></tr>
    <tr><td>사운드 (회전음·발사음)</td><td class="ok">✓ Python 합성, 저작권0</td></tr>
    <tr><td>git 작성자 doonghwi (Claude 표기 X)</td><td class="ok">✓ doonghwi only</td></tr>
  </table>

  <h2>실제 동작 스크린샷 (에뮬레이터)</h2>
  <div class="shots">
    <figure><img src="data:image/png;base64,{spin}" alt="실린더 회전">
      <figcaption>생존 — 실린더가 회전합니다 (회전음 재생)</figcaption></figure>
    <figure><img src="data:image/png;base64,{bang}" alt="명중 빨간 화면">
      <figcaption>명중 — 빨간 화면 + 💥 BANG! + 발사음 + 재장전</figcaption></figure>
  </div>

  <div class="grid" style="margin-top:26px;">
    <div class="card"><h3>🎮 게임 방식</h3><ul>
      <li>6칸 중 랜덤 1칸에 실탄.</li>
      <li>화면을 탭하면 방아쇠를 당깁니다.</li>
      <li>살아남으면 실린더가 돌고 카운터가 오릅니다.</li>
      <li>실탄을 맞으면 빵! — 빨갛게 번쩍이고 재장전.</li></ul></div>
    <div class="card"><h3>🛠 기술</h3><ul>
      <li>Flutter (Android + Web)</li>
      <li>리볼버: CustomPaint 100% 자작 (이미지 에셋 0)</li>
      <li>사운드: 순수 Python으로 직접 합성 (저작권 0)</li>
      <li>audioplayers · 가로 고정 · PWA 캐시 무력화</li></ul></div>
  </div>

</div></body></html>"""

out = os.path.join(base, "revolver_roulette", "REPORT.html")
with open(out, "w", encoding="utf-8") as f:
    f.write(html)
print("wrote", out, len(html), "bytes")
