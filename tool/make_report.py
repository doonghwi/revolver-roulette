import base64, os

base = r"C:\dev\dailyapp"
shots = os.path.join(base, "shots")

def b64(p):
    with open(p, "rb") as f:
        return base64.b64encode(f.read()).decode()

ready = b64(os.path.join(shots, "v2_ready.png"))
bang = b64(os.path.join(shots, "fire_1.png"))
sound = b64(os.path.join(shots, "sound_check.png"))

html = f"""<!DOCTYPE html>
<html lang="ko"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>리볼버 룰렛 — 수정 보고서 v1.1</title>
<style>
  :root {{ --bg:#140f0b; --card:#211811; --line:#3a2a1c; --gold:#ffd24a; --red:#c0392b; --txt:#e8d9c5; --mut:#b9a88f; }}
  * {{ box-sizing:border-box; }}
  body {{ margin:0; background:radial-gradient(circle at 30% 10%, #2a1d12, #140f0b 70%); color:var(--txt);
         font-family:'Segoe UI',system-ui,sans-serif; line-height:1.6; padding:32px 18px 60px; }}
  .wrap {{ max-width:980px; margin:0 auto; }}
  h1 {{ font-size:2rem; margin:0 0 4px; letter-spacing:2px; }} h1 .em {{ color:var(--red); }}
  .sub {{ color:var(--mut); margin-bottom:22px; }}
  h2 {{ margin:34px 0 12px; border-left:4px solid var(--red); padding-left:12px; }}
  .hero img, figure img {{ width:100%; border-radius:14px; border:1px solid var(--line); display:block; }}
  .hero img {{ box-shadow:0 10px 40px rgba(0,0,0,.5); border-radius:16px; }}
  .shots {{ display:grid; grid-template-columns:repeat(auto-fit,minmax(320px,1fr)); gap:16px; margin-top:12px; }}
  figure {{ margin:0; }} figcaption {{ color:var(--mut); font-size:.85rem; margin-top:6px; text-align:center; }}
  .fix {{ background:var(--card); border:1px solid var(--line); border-radius:14px; padding:16px 20px; margin:14px 0; }}
  .fix h3 {{ margin:0 0 6px; color:var(--gold); font-size:1.05rem; }}
  .tag {{ display:inline-block; font-size:.72rem; font-weight:800; padding:2px 9px; border-radius:999px; margin-left:8px; }}
  .done {{ background:#1c2a1c; color:#9fe09f; border:1px solid #2f4a2f; }}
  .links a {{ display:inline-block; background:#2a1d12; border:1px solid var(--line); padding:10px 16px;
             border-radius:10px; margin:6px 8px 0 0; text-decoration:none; font-weight:600; color:var(--gold); }}
  ul {{ margin:6px 0 0; padding-left:18px; }} li {{ margin:4px 0; }}
  .note {{ background:#241a10; border:1px solid #4a3a22; border-radius:10px; padding:12px 16px; font-size:.9rem; color:#d8c39a; margin-top:14px; }}
</style></head>
<body><div class="wrap">
  <h1>🔫 <span class="em">REVOLVER ROULETTE</span> — 수정 v1.1</h1>
  <div class="sub">요청하신 3가지를 모두 반영했습니다 · Day 2 업데이트</div>

  <div class="hero"><img src="data:image/png;base64,{ready}" alt="화면을 꽉 채운 리볼버"></div>

  <h2>요청 → 반영</h2>

  <div class="fix"><h3>1. 재시작 시 1발 쏜 상태로 시작하는 버그 <span class="tag done">FIXED</span></h3>
    재장전 회전 애니메이션이 끝날 때 카운터를 +1 하던 것이 원인이었습니다. 재장전 회전과 '생존' 회전을
    구분하는 플래그를 추가해, 이제 <b>항상 0발에서 시작</b>합니다. (에뮬에서 0 리셋 확인)</div>

  <div class="fix"><h3>2. 총을 가로 화면에 꽉 차게 · 더 사실적으로 · 탭 안내 제거 <span class="tag done">DONE</span></h3>
    <ul>
      <li>리볼버를 <b>화면 크기에 자동으로 꽉 차게</b> 다시 그렸습니다.</li>
      <li><b>총구는 오른쪽</b>, 손잡이·방아쇠는 왼쪽 아래 — 말씀하신 배치 그대로.</li>
      <li>환기 리브·이젝터 로드·전후방 조준기·실린더 래치·나무 그립 체커링 등 <b>디테일을 넣어 사실적</b>으로.</li>
      <li>화면 <b>아무 곳이나 탭</b>하면 발사되므로 "여기 탭" 안내는 제거했습니다.</li>
    </ul></div>

  <div class="fix"><h3>3. 소리 — 가장 많은 정성 <span class="tag done">대폭 개선</span></h3>
    <ul>
      <li>단순 합성을 버리고 <b>numpy + scipy DSP</b>로 새로 합성했습니다(여전히 저작권 0, 직접 생성).</li>
      <li><b>실린더 회전음</b>: 금속 래칫 클릭이 <b>점점 느려지며</b> 도는 소리 + 드럼 저음 울림 + 마지막 "철컥" 락 + 룸 리버브.</li>
      <li><b>총소리</b>: 초음속 크랙(날카로운 어택) + 머즐 블라스트(저음 스윕) + 바디 + 소프트클립 펀치 + 공간 반향 tail.</li>
      <li><b>공이치기 소리</b>를 추가해, 방아쇠를 누르는 순간 → (생존)회전 / (명중)총성으로 이어지는 긴장감.</li>
      <li>화면에도 <b>총구 화염</b>(별 모양 폭발)을 추가했습니다.</li>
    </ul>
    <div class="note">⚠️ 에뮬레이터는 무음(-no-audio)이라 제가 직접 소리를 들어 검증할 수 없습니다.
      대신 아래 파형·스펙트로그램으로 의도대로 합성됐는지 확인했어요. <b>실제 소리는 웹/실기기에서
      화면을 한 번 탭한 뒤</b> 들립니다(브라우저 오디오 정책). 들어보시고 더 손봐야 하면 꼭 알려주세요 —
      여기에 계속 공들이겠습니다.</div></div>

  <h2>검증 스크린샷</h2>
  <div class="shots">
    <figure><img src="data:image/png;base64,{bang}" alt="명중">
      <figcaption>명중 — 빨간 화면 + BANG! + <b>총구 화염</b>(오른쪽 총구)</figcaption></figure>
    <figure><img src="data:image/png;base64,{sound}" alt="사운드 파형/스펙트로그램">
      <figcaption>사운드 검증 — 회전음(감속 클릭열+lock)·총소리(크랙+저음)·공이 2단 클릭</figcaption></figure>
  </div>

  <h2>플레이 / 다운로드</h2>
  <div class="links">
    <a href="https://doonghwi.github.io/revolver-roulette/">🌐 웹에서 플레이 (소리 들어보기)</a>
    <a href="https://github.com/doonghwi/revolver-roulette/releases/tag/v1.1.0">📱 APK v1.1.0</a>
    <a href="https://doonghwi.github.io/dailyapp-dashboard/revolver-roulette.html">📜 빌드 로그</a>
  </div>
  <p style="color:var(--mut);font-size:.85rem;margin-top:10px;">
    ※ 웹은 첫 1회 새로고침(Ctrl+Shift+R)으로 최신 버전을 받으세요.</p>

</div></body></html>"""

out = os.path.join(base, "revolver_roulette", "REPORT.html")
with open(out, "w", encoding="utf-8") as f:
    f.write(html)
print("wrote", out, len(html), "bytes")
