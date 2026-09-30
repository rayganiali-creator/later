import glob, base64, os
from concepts import concept_a, svg
from playwright.sync_api import sync_playwright
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),'..','..'))
font=base64.b64encode(open(f'{ROOT}/assets/fonts/Vazirmatn-Bold.ttf','rb').read()).decode()
shot=base64.b64encode(open(f'{ROOT}/store/assets/screenshots/01_home.png','rb').read()).decode()
html=f'''<style>@font-face{{font-family:V;src:url(data:font/ttf;base64,{font})}}
body{{margin:0;width:1024px;height:500px;background:linear-gradient(135deg,#6C5CE7,#3B3480);font-family:V;color:#fff;direction:rtl;display:flex;align-items:center;overflow:hidden}}
.t{{padding:0 70px;flex:1}}h1{{font-size:78px;margin:0 0 6px}}p{{font-size:32px;margin:0;opacity:.92;line-height:1.6}}
.s{{width:260px;margin-left:80px;transform:translateY(60px) rotate(-4deg);border-radius:28px;box-shadow:0 20px 50px #0006}}</style>
<div class=t><div style="display:flex;align-items:center;gap:20px">{svg(concept_a(),size=96)}<h1>بعداً</h1></div><p>الان لازم نیست؛<br>فقط فراموشش نکن.</p></div>
<img class=s src="data:image/png;base64,{shot}">'''
with sync_playwright() as p:
    exe=glob.glob('/opt/pw-browsers/chromium-*/chrome-linux/chrome')[0]
    b=p.chromium.launch(executable_path=exe,args=['--no-sandbox']);pg=b.new_page(viewport={'width':1024,'height':500})
    pg.set_content(html);pg.screenshot(path=f'{ROOT}/store/assets/feature_graphic_1024x500.png');b.close()
