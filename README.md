![GitHub stars](https://img.shields.io/github/stars/voipiran/AsteriskGrafana?style=for-the-badge)
![GitHub last commit](https://img.shields.io/github/last-commit/voipiran/AsteriskGrafana?style=for-the-badge)
![License](https://img.shields.io/github/license/voipiran/AsteriskGrafana?style=for-the-badge)

VOIPIRAN ChanSpy Pro
# شنود پیشرفته در سیستم‌های تلفنی Issabel و FreePBX

این پروژه به شما امکان می‌دهد انواع مختلف شنود تماس (ChanSpy) را به‌صورت حرفه‌ای روی سیستم‌های Issabel و FreePBX فعال کنید. این قابلیت به‌ویژه در مراکز تماس (Call Center) و سیستم‌های مانیتورینگ کیفیت تماس ارزشمند است.

چرا شنود پیشرفته مهم است؟

در سیستم‌های تلفنی VoIP، مدیر یا ناظر تماس نیاز دارد بدون ایجاد مزاحمت برای مکالمه اصلی، کیفیت سرویس را بررسی کند یا حتی در مواقع اضطراری، به اپراتور کمک کند. ChanSpy این امکان را فراهم می‌کند که:

# نحوه استفاده

پس از نصب، از داخلی خود به این شکل شماره‌گیری کنید:
کد شنود + شماره داخلی مقصد (مثلاً 3010 یعنی شنود ساده داخلی 10)

## حالت‌های شنود
توضیحات مختصر حالت‌ها:

*30X — شنود استاندارد (Listen) — فقط گوش دادن به مکالمه.

*31X — شنود «فقط این کانال» (مثلاً فقط صدای اپراتور/کارشناس) — مطابق نظر کد: Only listen to audio coming from this channel.

*32X — نجوا / Coach (Whisper) — شنونده می‌تواند با اپراتور نجوا کند و مشتری نجوا را نشنود.

*33X — نجوای خصوصی (Private Whisper) — امکان صحبت مستقیم با کارشناس بدون شنیدن طرف دیگر.

*34X — ورود کامل به تماس (Barge) — می‌توانید هم‌زمان با دو طرف صحبت کنید.

*35X — حالت DTMF Control — پس از ورود، با فشردن DTMF می‌توان حالت را تغییر داد (مثال نگاشت پیشنهادی زیر).

نمونهٔ نگاشت DTMF (موجود در توضیحات راهنما):

4 → فقط شنود

5 → نجوا (Whisper)

6 → ورود/بِرج (Barge)

## نصب سریع و آسان با اجرا دستور زیر بر روی کنسول لینوکس:


```
curl -L -o voiz-asterisk-chanspy.zip https://github.com/voipiran/voiz-asterisk-chanspy/archive/main.zip \
&& unzip voiz-asterisk-chanspy.zip \
&& cd voiz-asterisk-chanspy-main \
&& chmod 755 install.sh \
&& ./install.sh -y

```


## Give a Star! ⭐ یک ستاره با ما بدهید
If you like this project or plan to use it in the future, please give it a star. Thanks 🙏


English Section
VOIPIRAN ChanSpy Pro – Advanced Call Monitoring for Issabel & FreePBX

This project enables advanced call monitoring modes (ChanSpy) for Asterisk-based PBXs such as Issabel and FreePBX. It is especially valuable for call centers and quality assurance teams.

Why is this important?
Supervisors can listen to live calls, coach agents in real time, or even barge into calls when necessary — without disrupting customer experience unnecessarily.

Modes included:

30X. – Standard spy (listen silently)

31X. – Outgoing audio only (hear only the agent’s voice)

32X. – Whisper mode (coach the agent without the customer hearing)

33X. – Private whisper (talk to the agent without hearing the customer)

34X. – Barge mode (join the call as a 3rd participant)

Quick Install Command:
```
curl -L -o voiz-asterisk-chanspy.zip https://github.com/voipiran/voiz-asterisk-chanspy/archive/main.zip \
&& unzip voiz-asterisk-chanspy.zip \
&& cd voiz-asterisk-chanspy-main \
&& chmod 755 install.sh \
&& ./install.sh -y

```
