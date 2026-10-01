#!/usr/bin/env python3
"""Create the Chinese 180-second explainer without changing the English original.
Requires Pillow, FFmpeg/FFprobe and macOS Tingting speech for a first build.
Cached speech WAVs and the packaged runtime clip support later rebuilds.
"""
from pathlib import Path
import argparse
import hashlib
import json
import re
import subprocess
import sys
from PIL import Image, ImageDraw, ImageFont
import build_video as shared

PROJECT = Path(__file__).resolve().parents[1]
VIDEO = PROJECT / 'video' / 'zh'
ASSETS = VIDEO / 'assets'
WORK = PROJECT.parent / '.tools' / 'video-zh-work'
DEMO = PROJECT / 'video' / 'assets' / 'runtime-demo.mp4'
DURATIONS = [20, 25, 25, 18, 18, 32, 30, 12]
run, digest = shared.run, shared.digest
FFMPEG, FFPROBE = shared.FFMPEG, shared.FFPROBE
BG, INK, MUTED, TEAL, GOLD = shared.BG, shared.INK, shared.MUTED, shared.TEAL, shared.GOLD


def font(size, mono=False, bold=False):
    if mono:
        return ImageFont.truetype('/System/Library/Fonts/Menlo.ttc', size)
    path = '/System/Library/Fonts/STHeiti Medium.ttc' if bold else '/System/Library/Fonts/STHeiti Light.ttc'
    return ImageFont.truetype(path, size, index=1)  # Heiti SC, not TTC index 0 (TC).


shared.font = font


def frame(title, subtitle, number):
    im = Image.new('RGB', (1920, 1080), BG)
    d = ImageDraw.Draw(im)
    d.line((80, 49, 1840, 49), fill='#29414c', width=2)
    d.text((80, 65), '呼吸城市 / 项目与代码讲解', font=font(23), fill=MUTED)
    d.text((1390, 65), '自动演示 / 合成音量输入', font=font(23), fill=TEAL)
    d.text((80, 122), title, font=font(52, bold=True), fill=INK)
    d.text((82, 194), subtitle, font=font(26), fill=MUTED)
    d.line((80, 920, 1840, 920), fill='#29414c', width=2)
    d.text((80, 1038), 'AI 辅助制作 / 中文合成旁白 / Processing 4.5.7 + Sound 2.4.0', font=font(21), fill=MUTED)
    d.text((1760, 1038), f'{number:02d}/12', font=font(19, mono=True), fill=MUTED)
    assert d.textlength(title, font=font(52, bold=True)) < 1760
    assert d.textlength(subtitle, font=font(26)) < 1760
    return im, d


def cards(cue_events=None):
    paths, refs = [], {}
    im, d = frame('呼吸城市', '用声音强度，让悉尼海港夜景产生实时变化', 1)
    d.text((86, 291), '从一口气，到一座会回应的城市', font=font(48, bold=True), fill=INK)
    for i, text in enumerate(['海港大桥、歌剧院与水面：全部由代码绘制', '轻输入：灯光柔和，运动缓慢', '强输入：城市变亮，海浪和粒子更活跃']):
        d.text((88, 398 + i * 51), text, font=font(29), fill=MUTED)
    for label, chinese, pos in [('calm', '安静', (82, 577)), ('strong', '强输入', (977, 577))]:
        shot = Image.open(PROJECT / 'video' / 'assets' / f'runtime-{label}.png').convert('RGB').resize((860, 484))
        im.paste(shot.crop((0, 92, 860, 385)), pos)
        d.text((pos[0]+12, pos[1]+245), chinese + ' / 程序实际运行静帧', font=font(23, bold=True), fill=INK)
    path = ASSETS/'01-intro.png'; im.save(path); paths.append((path, 20, False))
    im, d = frame('完整观察一次输入变化', '实际 Processing 渲染画面 / 每秒 30 帧的动画时钟 / 录像回放', 2)
    path = ASSETS/'02-demo.png'; im.save(path); paths.append((path, 25, True))
    e = shared.excerpt
    specs = [
        ('03-input', '01 / 麦克风声音怎样成为数值', '输入通道接入音量分析器，得到当前声音的均方根幅度。',
         [('BreathInput.pde', e('BreathInput.pde', 'microphone = new AudioIn', 'analyzer.input(microphone);')),
          ('BreathInput.pde', e('BreathInput.pde', 'float sample = analyzer.analyze();'))],
         'RMS 表示声音强弱；它不能判断声音是否来自呼吸。', 10, 29),
        ('04-calibration', '01 / 先估计房间的背景噪音', '安静采样三秒，以第 90 百分位估计噪音底值。',
         [('SignalEnvelope.java', e('SignalEnvelope.java', 'if (calibrationElapsed >=', 'calibrating = false;'))],
         '按 R 可重新校准；持续说话或吹气会抬高噪音估计。', 15, 28),
        ('05-gate', '01 / 用两道阈值减少反复开关', '开启阈值较高，关闭阈值较低，这种状态记忆称为滞回。',
         [('SignalEnvelope.java', e('SignalEnvelope.java', 'public float openingThreshold()', 'public float closingThreshold()')),
          ('SignalEnvelope.java', e('SignalEnvelope.java', 'if (gateOpen && raw', 'FULL_SCALE_ABOVE_GATE, 0, 1) : 0;'))],
         '阈值余量控制噪音抑制，灵敏度控制有效输入放大多少。', 18, 27),
        ('06-smoothing', '01 / 响应快一些，恢复慢一些', '指数平滑使用实际经过的秒数，让变化不依赖固定帧率。',
         [('SignalEnvelope.java', e('SignalEnvelope.java', 'public static float smooth', 'return current + (target - current) * amount;', after=1))],
         '上升时间常数 0.10 秒 / 下降时间常数 0.55 秒 / dt 表示经过的秒数', 18, 31),
        ('07-water', '02 / 同一个强度值驱动海浪', '累加“速度 × 时间”，输入突然变强时波浪位置也不会跳变。',
         [('CityScene.pde', e('CityScene.pde', 'wavePhase = (wavePhase + dt')),
          ('CityScene.pde', e('CityScene.pde', 'float amplitude = (0.65f + energy * 4.5f)'))],
         '从安静到活跃：速度 0.35–1.65 弧度/秒，基础振幅 0.65–5.15 像素。', 14, 29),
        ('08-light', '02 / 把声音强度映射成灯光', '在安静与活跃的颜色之间插值，让各层画面一起回应。',
         [('CityScene.pde', e('CityScene.pde', 'int calm = color(95 * shade', 'fill(lerpColor(calm, active'))],
         '天空、歌剧院和桥体改变颜色；窗户与倒影还会改变亮度。', 18, 32),
        ('09-emission', '03 / 粒子产生得快，也必须有上限', '输入越强，产生速率越高；对象数量始终受到硬限制。',
         [('VisualEffects.pde', e('VisualEffects.pde', 'final int MAX_PARTICLES', 'final int MAX_RIPPLES')),
          ('VisualEffects.pde', e('VisualEffects.pde', 'if (energy > 0.025)', 'emissionRemainder = emissionRemainder % 1;'))],
         '粒子最多 180 个，波纹最多 8 个；粒子满额不再新增，波纹满额替换最旧项。', 13, 26),
        ('10-expiry', '03 / 到期就回收，避免不断累积', '倒序遍历列表，删除对象后不会跳过尚未处理的元素。',
         [('VisualEffects.pde', e('VisualEffects.pde', 'for (int i = particles.size() - 1;', 'if (particle.life <= 0', after=1))],
         '每一帧依次更新、绘制并移除过期对象。', 11, 29),
        ('11-ripple', '03 / 让波纹继续记录这一口气的峰值', '触发后仍然更新强度，保留轻输入与强输入的区别。',
         [('VisualEffects.pde', e('VisualEffects.pde', 'if (currentWave != null) currentWave.strength')),
          ('VisualEffects.pde', e('VisualEffects.pde', 'radius += (55 + 150 * strength) * dt;'))],
         '避免把波纹强度永久固定在刚越过触发阈值的那一刻。', 6, 27),
    ]
    # Match internal card changes to the actual Mandarin clause boundaries.
    def cue(prefix, fallback):
        event = next((a for a,b,text in (cue_events or []) if text.startswith(prefix)), fallback)
        return round(event * 30) / 30
    water_start = cue('水面同时', 117.253)
    expiry_start = cue('每个对象都有寿命', 146.227)
    ripple_start = cue('当前波纹生成后', 153.706)
    light = list(specs[5]); light[0] = '07-light'; light[-2] = water_start - 106
    water = list(specs[4]); water[0] = '08-water'; water[-2] = 138 - water_start
    specs[4:6] = [tuple(light), tuple(water)]
    for index, length in [(6, expiry_start - 138), (7, ripple_start - expiry_start), (8, 168 - ripple_start)]:
        row = list(specs[index]); row[-2] = length; specs[index] = tuple(row)
    for stale in ['07-water.png', '08-light.png']:
        (ASSETS/stale).unlink(missing_ok=True)
    for number, (name, title, subtitle, groups, note, seconds, size) in enumerate(specs, 3):
        im, d = frame(title, subtitle, number); y = 263; refs[name] = []
        for file, lines in groups:
            d.text((106, y), f'{file} / 第 {lines[0][0]}–{lines[-1][0]} 行', font=font(23, bold=True), fill=GOLD)
            y += 46
            y = shared.draw_code(d, lines, 106, y, 1640, size, size+12) + 27
            refs[name].append({'file':file, 'first_line':lines[0][0], 'last_line':lines[-1][0], 'text':'\n'.join(t for _,t in lines)})
        assert y <= 858, (name, y)
        assert d.textlength(note, font=font(25)) < 1710
        d.text((107, 869), note, font=font(25), fill=TEAL)
        path = ASSETS/f'{name}.png'; im.save(path); paths.append((path, seconds, False))
    im, d = frame('代码可复查，过程有证据', '模拟画面、真人麦克风测试与个人反思分别记录。', 12)
    rows = [('已经保留', '最终代码、参数说明、修改前后版本与实际测试记录'),
            ('视频画面', '实际 Processing 程序渲染，使用明确标注的合成输入'),
            ('仍待补充', '真人测试观感确认、同伴反馈和真实课程资料'),
            ('帮助声明', '代码与讲解由 AI 辅助；本片使用中文合成旁白')]
    for i, (label, body) in enumerate(rows):
        y = 288 + i*139
        d.text((88, y), label, font=font(25, bold=True), fill=TEAL)
        d.text((88, y+45), body, font=font(31), fill=INK)
    path = ASSETS/'12-close.png'; im.save(path); paths.append((path, 12, False))
    (ASSETS/'source-excerpts.json').write_text(json.dumps(refs, ensure_ascii=False, indent=2)+'\n')
    return paths


def duration(path):
    return float(subprocess.check_output([FFPROBE, '-v', 'error', '-show_entries', 'format=duration', '-of', 'default=noprint_wrappers=1:nokey=1', str(path)]))


def speech_units(paragraph):
    # Synthesise caption-sized clauses separately so subtitle timing comes from
    # measured speech durations rather than estimated character proportions.
    clauses = re.findall(r'[^，。；：！？]+[，。；：！？]?', paragraph)
    units, current = [], ''
    for clause in clauses:
        if len(current + clause) > 31 and current:
            units.append(current); current = ''
        while len(clause) > 36:
            cut = 30
            units.append(clause[:cut] + '，'); clause = clause[cut:]
        current += clause
        if current.endswith(('。', '！', '？')):
            units.append(current); current = ''
    if current: units.append(current)
    return units


def audio():
    paragraphs = (VIDEO/'narration.txt').read_text().strip().split('\n\n')
    assert len(paragraphs) == 8
    captions, timing = [], []; offset = 0
    for i, (paragraph, seconds) in enumerate(zip(paragraphs, DURATIONS), 1):
        unit_paths, raw_durations, units = [], [], speech_units(paragraph)
        for j, unit in enumerate(units, 1):
            stem = f'speech-{i:02d}-{j:02d}'
            text = ASSETS/f'{stem}.txt'; wave = ASSETS/f'{stem}.wav'
            old = text.read_text() if text.exists() else ''
            if not wave.exists() or old != unit:
                text.write_text(unit)
                aiff = WORK/f'{stem}.aiff'
                run(['/usr/bin/say', '-v', 'Tingting', '-r', '200', '-f', text, '-o', aiff])
                if duration(aiff) < 0.2: raise ValueError('Empty host speech output; use native host execution for say')
                run([FFMPEG, '-v', 'error', '-y', '-i', aiff, '-ar', '48000', '-ac', '1', wave])
            unit_paths.append(wave); raw_durations.append(duration(wave))
        speed = sum(raw_durations)/(seconds - 1.2)
        if not 0.60 <= speed <= 1.65: raise ValueError(f'Chapter {i} needs narration revision: speed {speed}')
        listing = WORK/f'audio-{i:02d}.txt'
        listing.write_text(''.join(f"file '{p}'\n" for p in unit_paths))
        target = ASSETS/f'narration-{i:02d}.wav'
        run([FFMPEG, '-v', 'error', '-y', '-f', 'concat', '-safe', '0', '-i', listing,
             '-af', f'atempo={speed:.9f},adelay=500,apad', '-t', seconds, '-ar', '48000', '-ac', '1', target])
        cursor = offset + 0.5
        for unit, raw_seconds in zip(units, raw_durations):
            end = cursor + raw_seconds/speed
            captions.append((cursor, end, unit)); cursor = end
        timing.append({'chapter':i, 'target_seconds':seconds, 'raw_speech_seconds':sum(raw_durations), 'tempo_multiplier':speed, 'units':len(units)})
        offset += seconds
    listing = WORK/'audio-all.txt'
    listing.write_text(''.join(f"file '{ASSETS/f'narration-{i:02d}.wav'}'\n" for i in range(1,9)))
    run([FFMPEG, '-v', 'error', '-y', '-f', 'concat', '-safe', '0', '-i', listing, '-c:a', 'pcm_s16le', VIDEO/'narration.wav'])
    (VIDEO/'captions.zh-CN.srt').write_text('\n\n'.join(f'{i}\n{shared.timestamp(a)} --> {shared.timestamp(b)}\n{t}' for i,(a,b,t) in enumerate(captions,1))+'\n')
    header='''[Script Info]\nScriptType: v4.00+\nPlayResX: 1920\nPlayResY: 1080\nWrapStyle: 0\nScaledBorderAndShadow: yes\n[V4+ Styles]\nFormat: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding\nStyle: Default,Heiti SC,38,&H00E9E8E4,&H00FFFFFF,&H00211509,&H00211509,0,0,0,0,100,100,0,0,3,2,0,2,120,120,76,1\n[Events]\nFormat: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text\n'''
    (VIDEO/'captions.zh-CN.ass').write_text(header+'\n'.join(f'Dialogue: 0,{shared.timestamp(a,True)},{shared.timestamp(b,True)},Default,,0,0,0,,{t}' for a,b,t in captions)+'\n')
    (VIDEO/'audio-timing.json').write_text(json.dumps(timing, ensure_ascii=False, indent=2)+'\n')
    print('Speech chapters:', json.dumps(timing, ensure_ascii=False), flush=True)
    return captions


def build():
    cue_events = audio(); paths = cards(cue_events); segments = []
    for i,(card,seconds,is_demo) in enumerate(paths):
        target = WORK/f'segment-{i:02d}.mp4'; segments.append(target)
        cmd = [FFMPEG, '-v', 'error', '-y', '-loop', '1', '-framerate', '30', '-i', card]
        if is_demo:
            cmd += ['-i', DEMO, '-filter_complex', '[1:v]scale=1184:666,tpad=stop_mode=clone:stop_duration=1[scene];[0:v][scene]overlay=368:241:shortest=1[out]', '-map', '[out]']
        cmd += ['-t', seconds, '-an', '-r', '30', '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '19', '-threads', '4', '-pix_fmt', 'yuv420p', target]
        run(cmd)
    listing = WORK/'video-all.txt'; listing.write_text(''.join(f"file '{p}'\n" for p in segments))
    run([FFMPEG, '-v', 'error', '-y', '-f', 'concat', '-safe', '0', '-i', listing, '-c', 'copy', WORK/'visuals.mp4'])
    final = VIDEO/'BreathingCity_3min_Explainer_zh-CN.mp4'
    run([FFMPEG, '-v', 'error', '-y', '-i', WORK/'visuals.mp4', '-i', VIDEO/'narration.wav',
         '-vf', 'ass='+str(VIDEO/'captions.zh-CN.ass'), '-t', '180', '-c:v', 'libx264', '-preset', 'fast', '-crf', '20',
         '-threads', '4', '-pix_fmt', 'yuv420p', '-c:a', 'aac', '-b:a', '128k', '-metadata:s:a:0', 'language=zho',
         '-metadata', 'title=呼吸城市：项目与代码讲解', '-movflags', '+faststart', final])
    metadata = {'language':'zh-CN', 'voice':'Tingting / macOS synthetic Mandarin', 'duration_seconds':duration(final),
                'bytes':final.stat().st_size, 'sha256':digest(final), 'runtime_clip_sha256':digest(DEMO),
                'evidence':'Chinese presentation cards and synthetic narration; same actual Processing-rendered synthetic-input footage as English edition.',
                'subtitle_timing':'Measured individual speech-unit durations, scaled with the same chapter tempo as audio.',
                'source_sha256':{p.name:digest(p) for p in (PROJECT/'BreathingCity').iterdir() if p.suffix in ('.java','.pde')}}
    (VIDEO/'video-manifest.json').write_text(json.dumps(metadata, ensure_ascii=False, indent=2)+'\n')
    print(final, flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cards-only', action='store_true')
    parser.add_argument('--audio-only', action='store_true')
    args = parser.parse_args()
    ASSETS.mkdir(parents=True, exist_ok=True); WORK.mkdir(parents=True, exist_ok=True)
    if args.cards_only: cards()
    elif args.audio_only: audio()
    else: build()
