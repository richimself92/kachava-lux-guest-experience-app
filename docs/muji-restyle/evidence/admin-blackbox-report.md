# Admin Command Center MUJI restyle: black-box re-run on the rebuilt build (2026-11-16)
Chrome via Playwright against http://127.0.0.1:3002 and the real backend. No stubs. Read-only: no message sent, no request confirmed, no files deleted.
Manifest: run-6a25467f-b046-4354-9549-35f62ce12681.json.

- J1 Dashboard PASS: "Overview", hairline KPI grid (3 / 6 / 30% / 1 / 1 / 32), activity table with real guests.
- J2 Requests PASS (read-only): 11 requests, Sophie Laurent detail opened, status "Confirmed" after reload.
- J3 Messages PASS (read-only): the earlier "Prueba MUJI admin" is still in the thread after reload. "Prueba MUJI 2" was not sent.
- J4 Reservations PASS: search "Sophie" gave 1 of 1, detail panel opened, all 4 tabs switch.
- J5 Service form PASS: the form opened and Cancel closed it. Nothing saved.
- J6 Mobile nav PASS: "Requests 3" and "Messages 2" are plain numbers, Tasks opened.

Square Send button: CONFIRMED. The Send button is a square with ~2px corners in admin-messages-375.png and admin-messages-1440.png (zoomed crops). The round-pill violation is fixed.
Remaining visual notes: the Send arrow is grey on brown (low contrast, probably the disabled state because the field is empty). "Reservati..." is truncated in the 375 app bar. "Serv..." is truncated in admin-service-form-932.png. The "H" of "Hiroshi" may be clipped in admin-reservations-932.png.

Console errors / pageerrors: 0. HTTP >=400: 0. Overflow: 0 violations on all 35 screenshots (5 screens x 7 widths: 375, 390, 768, 932, 1280, 1440, 1920).
Regenerated on the new build: all 35 admin-<screen>-<w>.png, plus admin-journey-{dashboard,request-detail,message-thread,reservations-search,reservations-folio,service-form,mobile-nav-375,mobile-tasks-375}.
STALE, taken on the previous build (round Send; not deleted per instructions): admin-journey-message-typed-1440.png, admin-journey-message-sent-1440.png, admin-journey-request-confirmed-1440.png, and the old manifest run-de25515c-b08b-42b3-b85c-4115553125ec.json.

check_evidence.py on the whole directory exits 1. Excerpt:
  FAIL: E2E evidence in . does not back a PASSED verdict
  - admin-journey-message-sent-1440.png / -typed-1440.png / -request-confirmed-1440.png are older than 120 minutes (stale run?)
  - run-de25515c-....json (mine, old), run-5fc1d712-....json and run-791fdd17-....json are too old
  - many guest-*.png are older than 120 minutes
None of the new admin-* files are listed as stale.
