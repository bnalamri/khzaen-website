(function () {
  var html = document.documentElement;
  var langToggle = document.getElementById('langToggle');
  var menuBtn = document.getElementById('menuBtn');
  var mobileNav = document.getElementById('mobileNav');
  var roleSelect = document.getElementById('role');
  var form = document.getElementById('contactForm');
  var formNote = document.getElementById('formNote');

  function applyLang(lang) {
    html.setAttribute('lang', lang);
    html.setAttribute('dir', lang === 'ar' ? 'rtl' : 'ltr');
    try { localStorage.setItem('khzaen-lang', lang); } catch (e) {}
    translateSelectOptions(lang);
  }

  function translateSelectOptions(lang) {
    if (!roleSelect) return;
    Array.prototype.forEach.call(roleSelect.options, function (opt) {
      var text = opt.getAttribute('data-' + lang);
      if (text) opt.textContent = text;
    });
  }

  // restore saved preference, default to English
  var saved = null;
  try { saved = localStorage.getItem('khzaen-lang'); } catch (e) {}
  applyLang(saved === 'ar' ? 'ar' : 'en');

  langToggle.addEventListener('click', function () {
    var next = html.getAttribute('lang') === 'ar' ? 'en' : 'ar';
    applyLang(next);
  });

  menuBtn.addEventListener('click', function () {
    var open = mobileNav.classList.toggle('open');
    menuBtn.setAttribute('aria-expanded', open ? 'true' : 'false');
  });

  Array.prototype.forEach.call(mobileNav.querySelectorAll('a'), function (a) {
    a.addEventListener('click', function () {
      mobileNav.classList.remove('open');
      menuBtn.setAttribute('aria-expanded', 'false');
    });
  });

  if (form) {
    form.addEventListener('submit', function (e) {
      e.preventDefault();
      var lang = html.getAttribute('lang');
      formNote.textContent = lang === 'ar'
        ? 'شكرًا لك. سنعاود التواصل معك قريبًا. (يحتاج هذا النموذج إلى ربطه بخدمة بريد أو نظام فعلي لإرسال الرسائل.)'
        : 'Thank you. We will be in touch shortly. (This form needs to be connected to an email service or backend to actually send messages.)';
      form.reset();
      translateSelectOptions(lang);
    });
  }

  // Hero photo rotator
  var heroPhotos = document.querySelectorAll('.hero-photo');
  var heroTag = document.getElementById('heroPhotoTag');
  if (heroPhotos.length) {
    var heroIndex = 0;
    var heroReduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    function showHeroPhoto(i) {
      Array.prototype.forEach.call(heroPhotos, function (img, n) {
        img.classList.toggle('is-active', n === i);
      });
      if (heroTag) {
        Array.prototype.forEach.call(heroTag.querySelectorAll('[data-tag]'), function (el) {
          el.hidden = el.getAttribute('data-tag') !== String(i);
        });
      }
    }
    if (!heroReduceMotion) {
      setInterval(function () {
        heroIndex = (heroIndex + 1) % heroPhotos.length;
        showHeroPhoto(heroIndex);
      }, 4500);
    }
  }
})();
