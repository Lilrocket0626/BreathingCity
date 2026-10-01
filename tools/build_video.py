#!/usr/bin/env python3
"""Build the 180-second explainer from genuine Processing frames and final source.

Dependencies: Python 3 + Pillow, ffmpeg/ffprobe, and macOS `say` (Samantha).
No desktop recording or external image/video material is used. Generated cards are
presentation graphics; the labelled demo is captured by Processing's save().
Run from any directory: python tools/build_video.py --frames /path/to/frames
A later rebuild can reuse video/assets/runtime-demo.mp4 and narration-*.wav.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import math
from pathlib import Path
import re
import shutil
import subprocess
import textwrap
from PIL import Image, ImageDraw, ImageFont

PROJECT = Path(__file__).resolve().parents[1]
VIDEO = PROJECT / 'video'
ASSETS = VIDEO / 'assets'
WORK = PROJECT.parent / '.tools' / 'video-work'
FFMPEG = shutil.which('ffmpeg') or '/opt/homebrew/bin/ffmpeg'
FFPROBE = shutil.which('ffprobe') or '/opt/homebrew/bin/ffprobe'
WIDTH, HEIGHT, FPS = 1920, 1080, 30
BG = '#091521'
PANEL = '#112332'
INK = '#eee8d9'
MUTED = '#98b0b8'
TEAL = '#79c8cc'
GOLD = '#e0b77f'
DURATIONS = [20, 25, 25, 18, 18, 32, 30, 12]


def run(args):
    subprocess.run([str(v) for v in args], check=True)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def font(size, mono=False, bold=False):
    if mono:
        path = '/System/Library/Fonts/Menlo.ttc'
    else:
        path = '/System/Library/Fonts/Supplemental/Arial Bold.ttf' if bold else '/System/Library/Fonts/Supplemental/Arial.ttf'
    if not Path(path).exists():
        path = '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf' if mono else '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
    return ImageFont.truetype(path, size)


def timestamp(seconds, ass=False):
    if ass:
        centis = round(seconds * 100)
        return f'{centis//360000}:{centis//6000%60:02d}:{centis//100%60:02d}.{centis%100:02d}'
    ms = round(seconds * 1000)
    return f'{ms//3600000:02d}:{ms//60000%60:02d}:{ms//1000%60:02d},{ms%1000:03d}'


def wrap_pixels(draw, text, f, width):
    lines, row = [], ''
    for word in text.split():
        proposal = (row + ' ' + word).strip()
        if draw.textlength(proposal, font=f) > width and row:
            lines.append(row)
            row = word
        else:
            row = proposal
    if row:
        lines.append(row)
    return lines


def base(title, kicker, number):
    im = Image.new('RGB', (WIDTH, HEIGHT), BG)
    d = ImageDraw.Draw(im)
    d.line((80, 49, 1840, 49), fill='#29414c', width=2)
    d.text((80, 64), 'BREATHING CITY / CODE EXPLAINER', font=font(21, bold=True), fill=MUTED)
    d.text((1350, 64), 'AUTO DEMO / SYNTHETIC RMS', font=font(21, bold=True), fill=TEAL)
    d.text((80, 119), title, font=font(52, bold=True), fill=INK)
    d.text((82, 184), kicker, font=font(26), fill=MUTED)
    d.line((80, 922, 1840, 922), fill='#29414c', width=2)
    d.text((80, 1037), 'AI-assisted code  /  Synthetic English narration  /  Processing 4.5.7 + Sound 2.4.0', font=font(19), fill=MUTED)
    d.text((1760, 1037), f'{number:02d}/12', font=font(19, mono=True), fill=MUTED)
    return im, d


def excerpt(file, begin, end=None, before=0, after=0):
    lines = (PROJECT/'BreathingCity'/file).read_text().splitlines()
    start = next(i for i,l in enumerate(lines) if begin in l)
    finish = next(i for i in range(start,len(lines)) if end in lines[i]) if end else start
    a, b = max(0,start-before), min(len(lines),finish+after+1)
    return [(i+1,lines[i]) for i in range(a,b)]


TOKENS = re.compile(r'//.*|"(?:[^"\\]|\\.)*"|\b(?:public|private|final|static|class|void|float|int|boolean|if|else|for|return|new|true|false|null)\b|\b\d+(?:\.\d+)?f?\b')


def draw_code(d, entries, x, y, max_width, size=30, leading=43):
    # Token colouring changes presentation only; characters are copied verbatim.
    f = font(size, mono=True)
    dedent = min((len(s)-len(s.lstrip()) for _,s in entries if s.strip()), default=0)
    for lineno,source in entries:
        text = source[dedent:]
        wrapped = textwrap.wrap(text, width=max(30, int(max_width/d.textlength('M',font=f))),
                                replace_whitespace=False, drop_whitespace=False) or ['']
        for row_index,line in enumerate(wrapped):
            d.text((x, y), str(lineno) if row_index == 0 else '↳', font=font(size-3,mono=True), fill='#627e8a')
            cursor = x + 84
            last = 0
            for match in TOKENS.finditer(line):
                plain=line[last:match.start()]
                d.text((cursor,y),plain,font=f,fill=INK); cursor+=d.textlength(plain,font=f)
                token=match.group()
                colour=MUTED if token.startswith('//') else GOLD if token.startswith('"') or token[0].isdigit() else TEAL
                d.text((cursor,y),token,font=f,fill=colour); cursor+=d.textlength(token,font=f)
                last=match.end()
            d.text((cursor,y),line[last:],font=f,fill=INK)
            y+=leading
    return y


def code_card(name, title, subtitle, groups, note, number, size=29):
    im,d=base(title,subtitle,number)
    y=263
    source_refs=[]
    for file,entries in groups:
        ref=f'{file}  /  lines {entries[0][0]}–{entries[-1][0]}'
        d.text((106,y),ref,font=font(23,bold=True),fill=GOLD)
        y+=46
        y=draw_code(d,entries,106,y,1640,size,size+12)
        y+=27
        source_refs.append({'file':file,'first_line':entries[0][0],'last_line':entries[-1][0], 'text':'\n'.join(l for _,l in entries)})
    if y>858:
        raise ValueError(f'Code card {name} overflows: y={y}')
    d.text((107,869),note,font=font(25),fill=TEAL)
    dest=ASSETS/f'{name}.png';im.save(dest)
    return dest,source_refs


def create_cards(demo):
    for label,t in [('calm',4),('gentle',7),('strong',14),('recovery',21)]:
        run([FFMPEG,'-hide_banner','-loglevel','error','-y','-ss',t,'-i',demo,'-frames:v','1',ASSETS/f'runtime-{label}.png'])
    cards=[];refs={}
    im,d=base('Breathing City','Sydney Harbour, responding to sound intensity',1)
    d.text((86,282),'A city that listens.',font=font(60,bold=True),fill=INK)
    for i,t in enumerate(['Code-drawn harbour + landmarks','Gentle input → quiet light and motion','Stronger input → brighter, more active city']):
        d.text((88,385+i*54),t,font=font(28),fill=MUTED)
    for label,pos in [('calm',(82,577)),('strong',(977,577))]:
        shot=Image.open(ASSETS/f'runtime-{label}.png').convert('RGB').resize((860,484))
        shot=shot.crop((0,92,860,385)) # labelled crop of runtime artwork, excludes application HUD
        im.paste(shot,pos)
        d.text((pos[0]+12,pos[1]+245),label.upper()+' / ACTUAL RUNTIME STILL',font=font(20,bold=True),fill=INK)
    im.save(ASSETS/'01-intro.png');cards.append((ASSETS/'01-intro.png',20,None))
    im,d=base('One continuous input sequence','Actual Processing-rendered frames / 30 fps animation clock / replay',2)
    # Runtime video goes inside this reserved rectangle; no desktop is captured.
    im.save(ASSETS/'02-demo.png');cards.append((ASSETS/'02-demo.png',25,'demo'))
    specs=[
      ('03-input','01 / From microphone to a number','Signal conditioning begins in BreathInput.',
       [('BreathInput.pde',excerpt('BreathInput.pde','microphone = new AudioIn','analyzer.input(microphone);')),
        ('BreathInput.pde',excerpt('BreathInput.pde','float sample = analyzer.analyze();'))],
       'RMS measures loudness. It does not classify breath.',10,29),
      ('04-calibration','01 / Estimate the room-noise floor','Three seconds of quiet input; the 90th percentile rejects isolated clicks.',
       [('SignalEnvelope.java',excerpt('SignalEnvelope.java','if (calibrationElapsed >=','calibrating = false;'))],
       'Calibration is repeated with R. Sustained sound during calibration biases the floor.',15,28),
      ('05-gate','01 / A gate that stays stable','Separate opening and closing thresholds reduce rapid on/off switching.',
       [('SignalEnvelope.java',excerpt('SignalEnvelope.java','public float openingThreshold()','public float closingThreshold()')),
        ('SignalEnvelope.java',excerpt('SignalEnvelope.java','if (gateOpen && raw','FULL_SCALE_ABOVE_GATE, 0, 1) : 0;'))],
       'Margin rejects more background noise; sensitivity changes the usable input range.',18,27),
      ('06-smoothing','01 / Respond quickly. Settle gradually.','The time constant is measured in seconds, independent of frame count.',
       [('SignalEnvelope.java',excerpt('SignalEnvelope.java','public static float smooth','return current + (target - current) * amount;',after=1))],
       'Attack: 0.10 s   /   Release: 0.55 s   /   dt: elapsed seconds',18,31),
      ('07-water','02 / Map one signal into moving water','Accumulate speed × dt; changing speed does not jump the wave position.',
       [('CityScene.pde',excerpt('CityScene.pde','wavePhase = (wavePhase + dt')),
        ('CityScene.pde',excerpt('CityScene.pde','float amplitude = (0.65f + energy * 4.5f)'))],
       'Calm → active: 0.35–1.65 rad/s and 0.65–5.15 px × depth.',14,29),
      ('08-light','02 / Map the same signal into light','Interpolate colours between the quiet and active scene.',
       [('CityScene.pde',excerpt('CityScene.pde','int calm = color(95 * shade','fill(lerpColor(calm, active'))],
       'The opera-house shells, bridge, windows, reflections and sky share the same energy.',18,32),
      ('09-emission','03 / Effects have an explicit budget','Emission responds to energy; the object count has a hard ceiling.',
       [('VisualEffects.pde',excerpt('VisualEffects.pde','final int MAX_PARTICLES','final int MAX_RIPPLES')),
        ('VisualEffects.pde',excerpt('VisualEffects.pde','if (energy > 0.025)','emissionRemainder = emissionRemainder % 1;'))],
       'At capacity, extra emission is dropped. There is no backlog of deferred particles.',13,26),
      ('10-expiry','03 / Remove effects as their lives expire','Backward iteration remains correct when ArrayList indices shift.',
       [('VisualEffects.pde',excerpt('VisualEffects.pde','for (int i = particles.size() - 1;','if (particle.life <= 0',after=1))],
       'Each frame updates, draws and removes expired objects.',11,29),
      ('11-ripple','03 / Preserve the strength of each event','A ripple keeps tracking its peak after the threshold crossing.',
       [('VisualEffects.pde',excerpt('VisualEffects.pde','if (currentWave != null) currentWave.strength')),
        ('VisualEffects.pde',excerpt('VisualEffects.pde','radius += (55 + 150 * strength) * dt;'))],
       'Strong input can now produce stronger ripples, rather than freezing near the trigger.',6,27),
    ]
    for n,(name,title,sub,groups,note,duration,size) in enumerate(specs,3):
        p,r=code_card(name,title,sub,groups,note,n,size);cards.append((p,duration,None));refs[name]=r
    im,d=base('Reviewable code. Honest evidence.','The demonstration and the hardware test are different kinds of evidence.',12)
    rows=[('INCLUDED','Final sketch • parameter guide • change history • test records'),
          ('VIDEO EVIDENCE','Real Processing rendering, driven by labelled synthetic RMS'),
          ('STILL REQUIRED','Hardware microphone checks and genuine student / peer reflection'),
          ('DISCLOSURE','AI-assisted code and documentation; macOS synthetic narration')]
    for i,(label,body) in enumerate(rows):
        y=288+i*139
        d.text((88,y),label,font=font(23,bold=True),fill=TEAL)
        d.text((88,y+45),body,font=font(31),fill=INK)
    im.save(ASSETS/'12-close.png');cards.append((ASSETS/'12-close.png',12,None))
    (ASSETS/'source-excerpts.json').write_text(json.dumps(refs,indent=2)+'\n')
    return cards


def create_audio():
    paras=(VIDEO/'narration.txt').read_text().strip().split('\n\n')
    if len(paras)!=len(DURATIONS): raise ValueError('Expected eight narration paragraphs')
    captions=[];offset=0
    for index,(paragraph,duration) in enumerate(zip(paras,DURATIONS)):
        txt=ASSETS/f'narration-{index+1:02d}.txt';txt.write_text(paragraph+'\n')
        aiff=WORK/f'narration-{index+1:02d}.aiff'
        wave=ASSETS/f'narration-{index+1:02d}.wav'
        if not wave.exists():
            run(['say','-v','Samantha','-r','150','-f',txt,'-o',aiff])
            probe=json.loads(subprocess.check_output([FFPROBE,'-v','quiet','-show_format','-of','json',str(aiff)]))
            actual=float(probe['format']['duration'])
            target=duration-1.4
            speed=actual/target
            if not .5<=speed<=2: raise ValueError('Unexpected narration speed')
            run([FFMPEG,'-hide_banner','-loglevel','error','-y','-i',aiff,
                 '-af',f'atempo={speed:.7f},adelay=500|500,apad','-t',duration,'-ar','48000','-ac','1',wave])
        words=paragraph.split();chunks=[]
        while words:
            n=min(14,len(words));
            # Prefer a nearby sentence boundary, when it does not make tiny captions.
            for k in range(min(14,len(words)),7,-1):
                if words[k-1].endswith(('.',':',';')):n=k;break
            chunks.append(' '.join(words[:n]));words=words[n:]
        cursor=offset+.5;seconds_per_word=(duration-1.4)/len(paragraph.split())
        for chunk in chunks:
            end=cursor+len(chunk.split())*seconds_per_word
            captions.append((cursor,end,chunk));cursor=end
        offset+=duration
    with (WORK/'audio-concat.txt').open('w') as f:
        for i in range(8): f.write("file '"+str(ASSETS/f'narration-{i+1:02d}.wav')+"'\n")
    run([FFMPEG,'-hide_banner','-loglevel','error','-y','-f','concat','-safe','0','-i',WORK/'audio-concat.txt','-c:a','pcm_s16le',VIDEO/'narration.wav'])
    (VIDEO/'captions.srt').write_text('\n\n'.join(f'{i+1}\n{timestamp(a)} --> {timestamp(b)}\n'+ '\n'.join(textwrap.wrap(t,90)) for i,(a,b,t) in enumerate(captions))+'\n')
    header='''[Script Info]\nScriptType: v4.00+\nPlayResX: 1920\nPlayResY: 1080\nWrapStyle: 0\nScaledBorderAndShadow: yes\n[V4+ Styles]\nFormat: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding\nStyle: Default,Arial,31,&H00E9E8E4,&H00FFFFFF,&H00211509,&H00211509,0,0,0,0,100,100,0,0,3,2,0,2,120,120,72,1\n[Events]\nFormat: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text\n'''
    events=[]
    for a,b,t in captions:
        content='\\N'.join(textwrap.wrap(t,104))
        events.append(f'Dialogue: 0,{timestamp(a,True)},{timestamp(b,True)},Default,,0,0,0,,{content}')
    (VIDEO/'captions.ass').write_text(header+'\n'.join(events)+'\n')


def build(frames):
    ASSETS.mkdir(parents=True,exist_ok=True);WORK.mkdir(parents=True,exist_ok=True)
    demo=ASSETS/'runtime-demo.mp4'
    if frames and frames.exists():
        paths=sorted(frames.glob('*.png'))
        if len(paths)<720: raise ValueError(f'Need 720 actual runtime frames; found {len(paths)}')
        # Source capture uses 0-based six-digit filenames, exactly 30 animation fps.
        run([FFMPEG,'-hide_banner','-loglevel','error','-y','-framerate','30','-start_number','0','-i',frames/'%06d.png','-frames:v','720',
             '-c:v','libx264','-preset','fast','-crf','17','-pix_fmt','yuv420p','-movflags','+faststart',demo])
        frame_info={'source_directory':str(frames),'frame_count_used':720,'animation_fps':30,
                    'first_frame_sha256':digest(paths[0]),'last_frame_sha256':digest(paths[719]),
                    'method':'Processing save() from the running final Java sketch; labelled synthetic RMS; not desktop capture or microphone proof'}
        (ASSETS/'capture-provenance.json').write_text(json.dumps(frame_info,indent=2)+'\n')
    if not demo.exists(): raise FileNotFoundError('Supply --frames from an actual Processing capture first')
    cards=create_cards(demo);create_audio()
    segment_files=[]
    for i,(card,duration,kind) in enumerate(cards):
        dest=WORK/f'segment-{i:02d}.mp4';segment_files.append(dest)
        cmd=[FFMPEG,'-hide_banner','-loglevel','error','-y','-loop','1','-framerate','30','-i',card]
        if kind=='demo':
            cmd+=['-i',demo,'-filter_complex','[1:v]scale=1184:666,tpad=stop_mode=clone:stop_duration=1[scene];[0:v][scene]overlay=368:241:shortest=1[out]','-map','[out]']
        cmd+=['-t',duration,'-an','-r','30','-c:v','libx264','-preset','veryfast','-crf','19','-threads','4','-pix_fmt','yuv420p',dest]
        run(cmd)
    with (WORK/'video-concat.txt').open('w') as f:
        for p in segment_files:f.write("file '"+str(p)+"'\n")
    run([FFMPEG,'-hide_banner','-loglevel','error','-y','-f','concat','-safe','0','-i',WORK/'video-concat.txt','-c','copy',WORK/'visuals.mp4'])
    final=VIDEO/'BreathingCity_3min_Explainer.mp4'
    # All paths in the working directory are controlled by this build script.
    run([FFMPEG,'-hide_banner','-loglevel','error','-y','-i',WORK/'visuals.mp4','-i',VIDEO/'narration.wav',
         '-vf','ass='+str(VIDEO/'captions.ass'),'-t','180','-c:v','libx264','-preset','fast','-crf','20','-threads','4',
         '-pix_fmt','yuv420p','-c:a','aac','-b:a','128k','-movflags','+faststart',final])
    probe=json.loads(subprocess.check_output([FFPROBE,'-v','quiet','-show_format','-show_streams','-of','json',str(final)]))
    metadata={'title':'Breathing City: project, interaction, and three code explanations','duration_seconds':float(probe['format']['duration']),
              'resolution':'1920x1080','fps':30,'video':'H.264 / yuv420p','audio':'AAC; Samantha macOS synthetic English narration',
              'ai_disclosure':'Code, documentation and this explainer were prepared with AI assistance; narration is synthetic, not the student voice.',
              'evidence_boundary':'Demo video is a real Processing-rendered synthetic RMS sequence; it is not proof of live microphone/breath interaction.',
              'sha256':digest(final),'bytes':final.stat().st_size,
              'sources':{p.name:digest(p) for p in (PROJECT/'BreathingCity').iterdir() if p.suffix in ('.java','.pde')},
              'ffprobe':probe}
    (VIDEO/'video-manifest.json').write_text(json.dumps(metadata,indent=2)+'\n')
    print(final)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--frames',type=Path,default=None)
    parser.add_argument('--prepare-audio',action='store_true')
    args=parser.parse_args()
    ASSETS.mkdir(parents=True,exist_ok=True);WORK.mkdir(parents=True,exist_ok=True)
    if args.prepare_audio:create_audio()
    else:build(args.frames)
