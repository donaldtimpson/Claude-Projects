import json, urllib.request, urllib.parse, os, time, sys
SP="/private/tmp/claude-501/-Users-donnytimpsonjc-Sources-Claude-Projects/ebcddf54-2f8a-4d1a-80a1-bd5f879c33fa/scratchpad"
UA={"User-Agent":"SoundItOut/0.1 (children's reading app)"}
def get(u,tries=3):
    for t in range(tries):
        try: return urllib.request.urlopen(urllib.request.Request(u,headers=UA),timeout=30).read()
        except Exception:
            if t==tries-1: raise
            time.sleep(1.0*(t+1))

d=json.load(open("/Users/donnytimpsonjc/Sources/Claude-Projects/content/reading/reading.json"))
new=[p["word"] for p in d["pictureWords"] if not p["images"]]
HINT=json.load(open(f"{SP}/hints.json"))
META=f"{SP}/cand2/meta.json"
meta = json.load(open(META)) if os.path.exists(META) else {}

for i,w in enumerate(new):
    if any(k.startswith(w+"__") for k in meta):   # already recorded
        continue
    q=HINT.get(w,w)
    try:
        p=urllib.parse.urlencode({"q":q,"license":"cc0,by","page_size":"4","mature":"false"})
        r=json.loads(get("https://api.openverse.org/v1/images/?"+p))
        for n,res in enumerate(r.get("results",[])[:4]):
            src=res.get("thumbnail") or res.get("url")
            if not src: continue
            key=f"{w}__{n}"; path=f"{SP}/cand2/{key}.jpg"
            try:
                if not os.path.exists(path):
                    img=get(src)
                    if len(img)<3000: continue
                    open(path,"wb").write(img)
                meta[key]={"creator":(res.get("creator") or "Unknown")[:50],
                           "license":res.get("license"),"url":res.get("foreign_landing_url")}
            except Exception: pass
        json.dump(meta, open(META,"w"), indent=1)     # write EVERY word, not at the end
    except Exception: pass
    time.sleep(0.2)
    if i % 20 == 0:
        print(f"{i}/{len(new)} words, {len(meta)} candidates", flush=True)
print(f"DONE {len(meta)} candidates across {len({k.split('__')[0] for k in meta})} words", flush=True)
