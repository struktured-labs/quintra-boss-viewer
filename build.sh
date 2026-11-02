#!/usr/bin/env bash
# Rebuild Tesla-friendly viewer from /workspace/boss-viewer/index.html (read-only source).
set -euo pipefail
SRC=${SRC:-/workspace/boss-viewer/index.html}
OUT=${OUT:-$(cd "$(dirname "$0")" && pwd)/site}
rm -rf "$OUT"; mkdir -p "$OUT/img"; touch "$OUT/.nojekyll"
python3 - "$SRC" "$OUT" <<'PY'
import re,sys,base64,hashlib,os
src,out=sys.argv[1:]; s=open(src).read(); names={}
def rep(m):
    b=base64.b64decode(m.group(1)); h=hashlib.sha1(b).hexdigest()[:12]
    if h not in names:
        names[h]='img/%s.png'%h; open(os.path.join(out,names[h]),'wb').write(b)
    return names[h]
s=re.sub(r'data:image/png;base64,([A-Za-z0-9+/=]+)',rep,s)
import shutil
base=os.path.dirname(src); refs=set()
def rep2(m):
    rel=m.group(1); dst='img/'+rel; os.makedirs(os.path.dirname(os.path.join(out,dst)),exist_ok=True)
    if rel not in refs: shutil.copy2(os.path.join(base,'frames',rel),os.path.join(out,dst)); refs.add(rel)
    return '"'+dst+'"'
s=re.sub(r'"frames/([^"]+\.png)"',rep2,s)
print(len(refs),'frame files copied')
assert 'base64' not in s
s=s.replace('<head>','<head><meta name=viewport content="width=device-width,initial-scale=1">',1)
css=('button,select{font-size:18px;min-height:48px;padding:8px 14px}'
     '#prev,#next{min-width:120px;font-size:22px}#tabs button{min-width:56px}'
     'img#spr{image-rendering:pixelated;image-rendering:crisp-edges}')
s=s.replace('</style>',css+'</style>',1)
open(os.path.join(out,'index.html'),'w').write(s)
print(len(names),'images,',len(s),'bytes html')
PY
