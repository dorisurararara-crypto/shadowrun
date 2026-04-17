#!/usr/bin/env python3
"""
ElevenLabs v3 TTS 대량 생성 — Shadow Run 전용.

특징:
- 모델: eleven_v3 (audio tags 지원)
- Pro concurrent=2 기본
- language_code + apply_text_normalization=off (숫자/수사 수동 검수 전제)
- 카테고리별 voice_settings preset (horror/coach/calm/mystic)
- 출력: assets/audio/voice/{voice}_{mode}_{cat}_{lang}_v{NN}.mp3
- 이미 존재하면 스킵

Usage:
  export ELEVENLABS_API_KEY=sk_...
  python tmp/voice_scripts_v2/generate_v3.py
  python tmp/voice_scripts_v2/generate_v3.py --dry-run
  python tmp/voice_scripts_v2/generate_v3.py --mode doppelganger_public
  python tmp/voice_scripts_v2/generate_v3.py --voice halmeoni
  python tmp/voice_scripts_v2/generate_v3.py --workers 2
"""
import os, sys, json, time, argparse
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
import urllib.request, urllib.error

API_KEY = os.environ.get("ELEVENLABS_API_KEY")
if not API_KEY and "--dry-run" not in sys.argv:
    sys.exit("[err] ELEVENLABS_API_KEY env var not set")

ROOT = Path(__file__).resolve().parent.parent.parent
BANK_PATH = ROOT / "tmp" / "voice_scripts_v2" / "tts_bank.json"
SCRIPTS_DIR = ROOT / "tmp" / "voice_scripts_v2" / "scripts"
OUT_BASE = ROOT / "assets" / "audio" / "voice"

MODEL_ID = "eleven_v3"
FALLBACK_MODEL = "eleven_multilingual_v2"


def load_bank():
    return json.loads(BANK_PATH.read_text(encoding="utf-8"))


def load_scripts():
    out = {}
    for p in sorted(SCRIPTS_DIR.glob("*.json")):
        out[p.stem] = json.loads(p.read_text(encoding="utf-8"))
    return out


def iter_jobs(bank, scripts, args):
    jobs = []
    for mode_key, script in scripts.items():
        if args.mode and args.mode != mode_key:
            continue
        voices = script.get("voices", [])
        preset_name = script.get("preset", "coach_natural")
        settings = bank["voice_settings_presets"].get(preset_name)
        if not settings:
            print(f"[warn] preset {preset_name} missing, skipping mode {mode_key}")
            continue
        for cat, data in script.get("categories", {}).items():
            if cat.startswith("_"):
                continue
            for lang in ("ko", "en"):
                lines = data.get(lang, [])
                for idx, text in enumerate(lines, start=1):
                    for vname in voices:
                        if args.voice and vname != args.voice:
                            continue
                        vinfo = bank["voices"].get(vname)
                        if not vinfo:
                            continue
                        out = OUT_BASE / f"{vname}_{mode_key}_{cat}_{lang}_v{idx:02d}.mp3"
                        jobs.append({
                            "voice": vname,
                            "voice_id": vinfo["id"],
                            "mode": mode_key,
                            "category": cat,
                            "lang": lang,
                            "idx": idx,
                            "text": text,
                            "settings": settings,
                            "out": out,
                        })
    return jobs


def tts_call(voice_id, text, lang, settings, model_id):
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
    body = json.dumps({
        "text": text,
        "model_id": model_id,
        "language_code": lang,
        "apply_text_normalization": "off",
        "voice_settings": settings,
    }).encode("utf-8")
    req = urllib.request.Request(url, data=body, method="POST", headers={
        "xi-api-key": API_KEY,
        "Content-Type": "application/json",
        "Accept": "audio/mpeg",
    })
    with urllib.request.urlopen(req, timeout=180) as resp:
        return resp.read()


def tts_with_fallback(voice_id, text, lang, settings):
    try:
        return tts_call(voice_id, text, lang, settings, MODEL_ID), MODEL_ID
    except urllib.error.HTTPError as e:
        err_body = ""
        try:
            err_body = e.read().decode("utf-8", errors="replace")
        except Exception:
            pass
        if e.code in (400, 404, 422):
            # v3 가 특정 언어/설정 거부할 때 fallback
            try:
                # multilingual_v2 는 language_code·tags 미지원이므로 단순 호출
                url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
                body = json.dumps({
                    "text": text,
                    "model_id": FALLBACK_MODEL,
                    "voice_settings": settings,
                }).encode("utf-8")
                req = urllib.request.Request(url, data=body, method="POST", headers={
                    "xi-api-key": API_KEY,
                    "Content-Type": "application/json",
                    "Accept": "audio/mpeg",
                })
                with urllib.request.urlopen(req, timeout=180) as resp:
                    return resp.read(), FALLBACK_MODEL
            except Exception as e2:
                raise RuntimeError(f"v3 fail ({e.code}: {err_body[:180]}); fallback fail: {e2}")
        raise RuntimeError(f"v3 HTTP {e.code}: {err_body[:200]}")


def do_job(job):
    out = job["out"]
    if out.exists() and out.stat().st_size > 1024:
        return job, "skip", None
    out.parent.mkdir(parents=True, exist_ok=True)
    try:
        audio, model = tts_with_fallback(
            job["voice_id"], job["text"], job["lang"], job["settings"]
        )
        out.write_bytes(audio)
        return job, f"ok[{model}]", len(audio)
    except Exception as e:
        return job, "err", str(e)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--mode", help="mode key filter (doppelganger_public 등)")
    ap.add_argument("--voice", help="voice name filter (harry/callum/drill/halmeoni)")
    ap.add_argument("--workers", type=int, default=2)
    args = ap.parse_args()

    bank = load_bank()
    scripts = load_scripts()
    jobs = iter_jobs(bank, scripts, args)
    total_chars = sum(len(j["text"]) for j in jobs)

    print(f"[plan] modes={len(scripts)} jobs={len(jobs)} ~chars={total_chars}", flush=True)
    print(f"[plan] out={OUT_BASE}", flush=True)

    if args.dry_run:
        for j in jobs[:10]:
            print(f"  -> {j['out'].name} | {j['text'][:50]}", flush=True)
        if len(jobs) > 10:
            print(f"  ... +{len(jobs) - 10} more", flush=True)
        return

    OUT_BASE.mkdir(parents=True, exist_ok=True)
    t0 = time.time()
    ok = skip = err = 0
    total_bytes = 0
    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        futs = {ex.submit(do_job, j): j for j in jobs}
        for i, f in enumerate(as_completed(futs), 1):
            job, status, info = f.result()
            tag = f"{job['voice']}_{job['mode']}_{job['category']}_{job['lang']}_v{job['idx']:02d}"
            if status.startswith("ok"):
                ok += 1
                total_bytes += info or 0
                print(f"[{i}/{len(jobs)}] {tag} {status} {info}B", flush=True)
            elif status == "skip":
                skip += 1
                print(f"[{i}/{len(jobs)}] {tag} skip", flush=True)
            else:
                err += 1
                print(f"[{i}/{len(jobs)}] {tag} ERR: {info}", flush=True)

    dt = time.time() - t0
    print(f"\n[done] ok={ok} skip={skip} err={err} bytes={total_bytes} in {dt:.1f}s", flush=True)


if __name__ == "__main__":
    main()
