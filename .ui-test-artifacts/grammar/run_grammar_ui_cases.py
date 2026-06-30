import json
import os
import signal
import subprocess
import time
from pathlib import Path

ROOT = Path('/Users/lancer/.codex/worktrees/bffc/LingoPeek')
ART = ROOT / '.ui-test-artifacts' / 'grammar'
APP = ART / 'LingoPeekUITest.app'
EXE = APP / 'Contents' / 'MacOS' / 'LingoPeekUITest'
SCREEN_DIR = ART / 'screenshots'
SCREEN_DIR.mkdir(parents=True, exist_ok=True)

sentences = [
    "Although the proposal that the council approved in principle was designed to reduce costs, the incentives it created made agencies postpone maintenance until small issues became expensive failures.",
    "By the time the report was released, the engineers who had warned that the authentication service might fail under heavy load had already redesigned the module that controlled session renewal.",
    "The findings published last year call into question long-held assumptions that memory is consolidated while we sleep.",
    "Because the researchers who collected the survey data excluded participants whose answers were incomplete, the final model underestimated how strongly commuting time affected retention.",
    "What surprised the committee was not that the budget had increased, but that the teams responsible for forecasting demand had ignored the warnings they themselves had documented.",
    "If the platform continues to prioritize features that attract new users while neglecting the workflows that retain existing customers, revenue may grow briefly before support costs erase the gains.",
    "The contract, which had been negotiated before the supplier changed ownership, required the manufacturer to absorb delays that neither side could reasonably have predicted.",
    "Rather than simplifying the onboarding process, the checklist that managers introduced after the audit forced new employees to repeat information that had already been captured elsewhere.",
    "No sooner had the city announced the transit subsidy than several landlords raised rents near the stations where lower-income workers were expected to benefit most.",
    "The assumption that students learn more effectively when feedback is immediate becomes harder to defend when the task requires reflection rather than rapid correction."
]

def read_default(key, fallback=''):
    for domain in ['LingoPeek', 'com.lingopeek.LingoPeek']:
        try:
            value = subprocess.check_output(['defaults', 'read', domain, key], stderr=subprocess.DEVNULL, text=True).strip()
        except Exception:
            value = ''
        if value:
            return value
    return fallback

def run(cmd, **kwargs):
    return subprocess.run(cmd, cwd=ROOT, check=True, **kwargs)

def lingobar_window_id():
    swift = r'''
import CoreGraphics
let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
let list = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []
for info in list {
    if (info[kCGWindowOwnerName as String] as? String) == "LingoPeekUITest",
       (info[kCGWindowName as String] as? String) == "Lingobar",
       let id = info[kCGWindowNumber as String] as? UInt32 {
        print(id)
        break
    }
}
'''
    value = subprocess.check_output(['swift', '-'], input=swift, cwd=ROOT, text=True).strip()
    return value or None

# Refresh bundle from current build.
run(['swift', 'build', '--product', 'LingoPeek'], stdout=subprocess.DEVNULL)
subprocess.run(['pkill', '-f', 'LingoPeekUITest.app/Contents/MacOS/LingoPeekUITest'], stderr=subprocess.DEVNULL)
APP.mkdir(parents=True, exist_ok=True)
(APP / 'Contents' / 'MacOS').mkdir(parents=True, exist_ok=True)
subprocess.run(['cp', str(ROOT / '.build' / 'debug' / 'LingoPeek'), str(EXE)], check=True)
EXE.chmod(0o755)
info = APP / 'Contents' / 'Info.plist'
info.write_text('''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>LingoPeekUITest</string>
<key>CFBundleIdentifier</key><string>com.lingopeek.UITest</string>
<key>CFBundleName</key><string>LingoPeekUITest</string>
<key>CFBundleDisplayName</key><string>LingoPeekUITest</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>''')

token = read_default('aiAPIToken')
model = read_default('aiModel', 'deepseek-v4-flash')
base = read_default('aiBaseURL', 'https://api.deepseek.com')
if not token:
    raise SystemExit('No AI token available in defaults')

results = []
for index, sentence in enumerate(sentences, start=1):
    subprocess.run(['pkill', '-f', 'LingoPeekUITest.app/Contents/MacOS/LingoPeekUITest'], stderr=subprocess.DEVNULL)
    time.sleep(0.4)
    metrics = ART / f'case-{index:02d}.jsonl'
    log = ART / f'case-{index:02d}.log'
    screenshot = SCREEN_DIR / f'case-{index:02d}.png'
    for path in [metrics, log, screenshot]:
        try:
            path.unlink()
        except FileNotFoundError:
            pass

    defaults = [
        ('LINGOPEEK_UI_TEST_BYPASS_SETUP', '-bool', 'true'),
        ('LINGOPEEK_UI_TEST_SELECTION', sentence),
        ('LINGOPEEK_UI_TEST_METRICS_PATH', str(metrics)),
        ('aiAPIToken', token),
        ('aiModel', model),
        ('aiBaseURL', base),
    ]
    for item in defaults:
        if len(item) == 3 and item[1] == '-bool':
            subprocess.run(['defaults', 'write', 'com.lingopeek.UITest', item[0], item[1], item[2]], check=True)
        else:
            subprocess.run(['defaults', 'write', 'com.lingopeek.UITest', item[0], item[1]], check=True)

    start = time.perf_counter()
    with log.open('wb') as out:
        proc = subprocess.Popen([str(EXE)], cwd=ROOT, stdout=out, stderr=subprocess.STDOUT)

    events = []
    final_event = None
    deadline = time.perf_counter() + 70
    while time.perf_counter() < deadline:
        if metrics.exists():
            lines = metrics.read_text().splitlines()
            events = [json.loads(line) for line in lines if line.strip()]
            for event in events:
                if event.get('event') in {'complete', 'failure', 'partial_failure'}:
                    final_event = event
                    break
            if final_event:
                break
        if proc.poll() is not None:
            break
        time.sleep(0.25)

    # Give SwiftUI a moment to paint final state before screenshot.
    time.sleep(0.8)
    window_id = lingobar_window_id()
    if window_id:
        subprocess.run(['screencapture', '-x', '-l', window_id, str(screenshot)], check=False)
    else:
        subprocess.run(['screencapture', '-x', str(screenshot)], check=False)
    wall = time.perf_counter() - start
    subprocess.run(['pkill', '-f', 'LingoPeekUITest.app/Contents/MacOS/LingoPeekUITest'], stderr=subprocess.DEVNULL)

    spine = next((e for e in events if e.get('event') == 'spine'), None)
    complete = next((e for e in events if e.get('event') == 'complete'), None)
    failure = next((e for e in events if e.get('event') in {'failure', 'partial_failure'}), None)
    row = {
        'case': index,
        'sentence': sentence,
        'model': model,
        'status': (final_event or {}).get('event', 'timeout'),
        'spine_seconds': None if not spine else spine.get('elapsed'),
        'complete_seconds': None if not complete else complete.get('elapsed'),
        'wall_seconds': wall,
        'screenshot': str(screenshot),
        'error': None if not failure else failure.get('error'),
    }
    results.append(row)
    print(json.dumps(row, ensure_ascii=False), flush=True)

summary_path = ART / 'ui-test-summary.json'
summary_path.write_text(json.dumps(results, ensure_ascii=False, indent=2))
print(f'SUMMARY {summary_path}')
