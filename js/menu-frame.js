(function () {
  'use strict';

  const KEY_OPEN = 'sql-ledger.menu.open';
  const KEY_ACTIVE = 'sql-ledger.menu.active';

  function safeJsonParse(raw, fallback) {
    try { return JSON.parse(raw); } catch (_) { return fallback; }
  }

  function loadOpenSet() {
    const raw = sessionStorage.getItem(KEY_OPEN);
    const arr = safeJsonParse(raw || '[]', []);
    return new Set(Array.isArray(arr) ? arr : []);
  }

  function saveOpenSet(openSet) {
    try { sessionStorage.setItem(KEY_OPEN, JSON.stringify(Array.from(openSet))); } catch (_) {}
  }

  function resetStoredState() {
    try {
      sessionStorage.removeItem(KEY_OPEN);
      sessionStorage.removeItem(KEY_ACTIVE);
    } catch (_) {}
  }

  function shouldResetOnLoad() {
    try {
      const last = sessionStorage.getItem(KEY_ACTIVE) || '';
      if (!last) return false;

      let s = last;
      try { s = decodeURIComponent(last); } catch (_) {}

      return /action=logout\b/i.test(s) || /login\.pl\b/i.test(s);
    } catch (_) {
      return false;
    }
  }

  function getPanelForButton(btn) {
    const panel = btn.nextElementSibling;
    if (panel && panel.classList && panel.classList.contains('submenu')) return panel;
    return null;
  }

  function isTopLevelButton(btn) {
    return !btn.closest('.submenu');
  }

  function closeSubtree(openSet, panel) {
    // Zárjunk be minden nyitott panelt a subtree-ben (gombpanel párok)
    panel.querySelectorAll('button.menu-header.open').forEach((b) => {
      const p = getPanelForButton(b);
      if (!p) return;
      setOpen(b, p, false);
      if (p.id) openSet.delete(p.id);
    });

      // Biztonság kedvéért: ha a panelek open class-szal vannak nyitva (gomb nélkül),
      // azt is zárjuk, és vegyük ki az openSet-ből.
      panel.querySelectorAll('.submenu.open').forEach((p) => {
        p.classList.remove('open');
        if (p.id) openSet.delete(p.id);
      });
  }

  function closeOtherTopLevel(openSet, currentBtn) {
    document.querySelectorAll('button.menu-header.open').forEach((btn) => {
      if (btn === currentBtn) return;
      if (!isTopLevelButton(btn)) return;

      const panel = getPanelForButton(btn);
      if (!panel) return;

      closeSubtree(openSet, panel);
      setOpen(btn, panel, false);
      if (panel.id) openSet.delete(panel.id);
    });
  }

  function setOpen(btn, panel, open) {
    btn.classList.toggle('open', open);
    panel.classList.toggle('open', open);
    btn.setAttribute('aria-expanded', open ? 'true' : 'false');
  }

  function setActive(link) {
    document.querySelectorAll('.menu-item.active').forEach((n) => n.classList.remove('active'));
    const item = link.closest('.menu-item');
    if (item) item.classList.add('active');
  }

  function openAncestors(openSet, panel) {
    let p = panel;
    while (p) {
      const btn = p.previousElementSibling;
      if (btn && btn.classList && btn.classList.contains('menu-header')) {
        setOpen(btn, p, true);
        if (p.id) openSet.add(p.id);
      }
      p = p.parentElement ? p.parentElement.closest('.submenu') : null;
    }
  }

  document.addEventListener('DOMContentLoaded', () => {
    document.documentElement.setAttribute('data-menu-js', '1');

    if (shouldResetOnLoad()) {
      resetStoredState();
    }

    const openSet = loadOpenSet();

    document.querySelectorAll('button.menu-header').forEach((btn) => {
      const panel = getPanelForButton(btn);
      if (!panel) return;

      const shouldOpen = (panel.id && openSet.has(panel.id));
      setOpen(btn, panel, shouldOpen);
    });

    document.addEventListener('click', (ev) => {
      const btn = ev.target.closest && ev.target.closest('button.menu-header');
      if (btn) {
        const panel = getPanelForButton(btn);
        if (!panel) return;

        const nowOpen = !panel.classList.contains('open');
        if (nowOpen && isTopLevelButton(btn)) {
          closeOtherTopLevel(openSet, btn);
        }

        setOpen(btn, panel, nowOpen);

        if (panel.id) {
          if (nowOpen) openSet.add(panel.id);
          else openSet.delete(panel.id);
          saveOpenSet(openSet);
        }
        return;
      }

      const link = ev.target.closest && ev.target.closest('.menu-item > a');
      if (link) {
        setActive(link);

        try { sessionStorage.setItem(KEY_ACTIVE, link.getAttribute('href') || ''); } catch (_) {}

        const panel = link.closest('.submenu');
        if (panel) {
          openAncestors(openSet, panel);
          saveOpenSet(openSet);
        }
      }
    });

    try {
      const href = sessionStorage.getItem(KEY_ACTIVE);
      if (href) {
        const link = Array.from(document.querySelectorAll('.menu-item > a'))
        .find((a) => (a.getAttribute('href') || '') === href);

        if (link) {
          setActive(link);
          const panel = link.closest('.submenu');
          if (panel) {
            openAncestors(openSet, panel);
            saveOpenSet(openSet);
          }
        }
      }
    } catch (_) {}
  });
})();
