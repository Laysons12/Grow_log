# GrowLog — Portfolio Upload Details & Code (Professional Edition)

I have created 3 high-quality, dark-themed mockup images matching your portfolio style and copied them directly to your workspace under the directory: `portfolio_assets/`
* `growlog_dashboard.png`
* `growlog_checkin.png`
* `growlog_progress.png`

Below is the refined, highly professional project copy tailored to showcase your engineering and statistics background at [portfolio-os92.vercel.app](https://portfolio-os92.vercel.app/).

---

## 1. Project Details (Portfolio Card Copy)

### Title
GrowLog — Local-First Growth & Productivity Tracker

### Short Description
A high-performance, local-first Flutter application designed for tracking personal academic and skill growth. Features multi-profile data isolation, customized keyboard formatters, interactive trend charts, and native timezone-aligned exact alarm reminders.

### Key Skills/Technologies Used (Pills)
* Flutter (Dart)
* Hive DB
* FL Chart
* Platform Channels (Kotlin/Swift)
* Android AlarmManager & Local Notifications

### Full Description (Expandable/Detail Section)

**GrowLog** is a premium, local-first mobile productivity application built to help students and professionals structure, validate, and analyze their daily learning habits. The project showcases robust client-side state management, native system integration, and strict data validation pipelines.

#### Key Engineering Achievements:
* **Local-First Architecture & Data Partitioning:** Implemented a high-speed, persistent data layer using **Hive DB**. Engineered custom multi-profile sandboxing that partitions user entries, streaks, goals, and badges dynamically based on the active session's identifier (email hashes) with zero cross-profile leakage.
* **Native Platform Integration:** Created custom platform channels (`MethodChannel` in Kotlin and Swift) to query default system timezones dynamically, binding device configurations to Dart's timezone libraries. This guarantees that scheduled exact check-in notifications fire precisely at the user's localized time.
* **Android 13+ & 14+ Notification & Exact Alarm Compliance:** Integrated runtime notifications (`POST_NOTIFICATIONS`) and exact scheduling (`USE_EXACT_ALARM`) policies, designing custom vibration rhythms (3-second warning pulse) to ensure high-priority reminder delivery.
* **State Synchronization & Auto-Refresh:** Solved navigation state caching bugs by restructuring the tab page cycle. Added build-time database synchronization so that switching profiles instantly refreshes dashboards (user greetings, weekly bar charts, calendar logs, and goals list) without needing an app hot-restart.
* **Strict Input-Level Form Validation:** Built custom input constraints, keyboard-blocking formatters (`RoleOrClassFormatter`), and character restriction rules to enforce strict field invariants:
  - *Win of the Day:* Enforces a maximum of 200 letters and 5 numbers.
  - *What to Improve:* Enforces a maximum of 15 numbers and unlimited letters.
  - *Hours Studied:* Integrated dynamic double parsing, clamping manual numeric entries to `16.0` hours to prevent buffer or range overflow exploits (e.g. typing `9999`).
  - *Custom Topics:* Enforced a minimum of 3 letters and a maximum of 3 numbers.
* **Advanced Analytics Dashboard:** Utilized **FL Chart** to construct weekly progress graphs that dynamically map local dates and weekday indices (`Mon`–`Sun`) relative to the current timestamp.

---

## 2. Code Snippets to Paste

### A. HTML Code (Add inside `<div class="projects-stack">` in your `index.html`)
Copy and paste this card block in the `#projects` section of your portfolio:

```html
      <!-- GrowLog -->
      <div class="card crickzy-card" onclick="toggleGrowLogGallery()">
        <h3>GrowLog — Local-First Growth Tracker <span style="font-size: 11px; font-weight: normal; color: var(--text-muted); margin-left: 8px; background: rgba(255,255,255,0.05); padding: 4px 8px; border-radius: 100px;">Click to view photos</span></h3>
        <p>A premium Flutter application designed for tracking personal academic and skill development. Engineered with local-first Hive storage, multi-profile database isolation, custom keyboard formatters, interactive FL Charts, and native timezone-aligned exact alarm reminders. Features robust client-side state synchronization and automatic backup restoration pipelines.</p>
        
        <div class="proj-slideshow" id="growLogSlideshow" style="display: none;">
          <div class="proj-slide active"><img src="img/growlog_dashboard.png" alt="Home Dashboard" /></div>
          <div class="proj-slide"><img src="img/growlog_checkin.png" alt="Daily Check-in" /></div>
          <div class="proj-slide"><img src="img/growlog_progress.png" alt="Progress & Badges" /></div>
          <div class="proj-slide-dots">
            <span class="proj-dot active" onclick="event.stopPropagation(); growLogSlide(0)"></span>
            <span class="proj-dot" onclick="event.stopPropagation(); growLogSlide(1)"></span>
            <span class="proj-dot" onclick="event.stopPropagation(); growLogSlide(2)"></span>
          </div>
        </div>

        <div class="card-pills">
          <div class="card-pill">Flutter</div>
          <div class="card-pill">Dart</div>
          <div class="card-pill">Hive DB</div>
          <div class="card-pill">FL Chart</div>
          <div class="card-pill">Local Notifications</div>
        </div>
      </div>
```

### B. JavaScript Code (Add inside the `<script>` tag at the bottom of your `index.html`)
Copy and paste this logic to control the photo slider/slideshow toggles:

```javascript
  let growLogIdx = 0;
  function growLogSlide(i) {
    const slides = document.querySelectorAll('#growLogSlideshow .proj-slide');
    const dots = document.querySelectorAll('#growLogSlideshow .proj-dot');
    slides.forEach(s => s.classList.remove('active'));
    dots.forEach(d => d.classList.remove('active'));
    growLogIdx = i;
    slides[i].classList.add('active');
    dots[i].classList.add('active');
  }
  setInterval(() => {
    const slideshow = document.getElementById('growLogSlideshow');
    if(slideshow && slideshow.style.display !== 'none') {
      const slides = document.querySelectorAll('#growLogSlideshow .proj-slide');
      if (slides.length) growLogSlide((growLogIdx + 1) % slides.length);
    }
  }, 4000);

  function toggleGrowLogGallery() {
    const gallery = document.getElementById('growLogSlideshow');
    if (gallery.style.display === 'none' || gallery.style.display === '') {
      gallery.style.display = 'block';
    } else {
      gallery.style.display = 'none';
    }
  }
```
