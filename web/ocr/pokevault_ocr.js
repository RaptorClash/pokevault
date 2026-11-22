// Offline Smart-Hybrid Tesseract.js OCR wrapper for PokéVault Web
// Bundles DE/EN locally under ./ocr/lang/ and lazily caches extra languages in IndexedDB.
(function () {
  const LOCAL_LANGS = new Set(['deu', 'eng']);
  const REMOTE_TESSDATA_URL = 'https://tessdata.projectnaptha.com/4.0.0_fast';

  let activeWorker = null;
  let activeLang = null;
  let pendingChain = Promise.resolve();
  let reusableCanvas = null;
  const cachedExtraLangs = new Set();

  function getReusableCanvas(width, height) {
    if (!reusableCanvas) {
      reusableCanvas =
        typeof OffscreenCanvas !== 'undefined'
          ? new OffscreenCanvas(width, height)
          : document.createElement('canvas');
    }
    if (reusableCanvas.width !== width) reusableCanvas.width = width;
    if (reusableCanvas.height !== height) reusableCanvas.height = height;
    return reusableCanvas;
  }

  function getBaseHrefPath() {
    const baseEl = document.querySelector('base');
    const href = baseEl ? baseEl.getAttribute('href') : '/';
    if (!href || href === '/') return '/';
    return href.endsWith('/') ? href : href + '/';
  }

  async function isLangInIndexedDb(langCode) {
    if (cachedExtraLangs.has(langCode)) return true;
    try {
      const dbReq = indexedDB.open('keyval-store');
      return await new Promise((resolve) => {
        dbReq.onerror = () => resolve(false);
        dbReq.onupgradeneeded = () => {
          dbReq.transaction?.abort();
          resolve(false);
        };
        dbReq.onsuccess = () => {
          try {
            const db = dbReq.result;
            if (!db.objectStoreNames.contains('keyval')) {
              db.close();
              resolve(false);
              return;
            }
            const tx = db.transaction('keyval', 'readonly');
            const store = tx.objectStore('keyval');
            const keysReq = store.getAllKeys();
            keysReq.onsuccess = () => {
              const keys = keysReq.result || [];
              const found = keys.some(
                (k) => typeof k === 'string' && k.includes(langCode + '.traineddata')
              );
              if (found) cachedExtraLangs.add(langCode);
              db.close();
              resolve(found);
            };
            keysReq.onerror = () => {
              db.close();
              resolve(false);
            };
          } catch (_) {
            resolve(false);
          }
        };
      });
    } catch (_) {
      return false;
    }
  }

  async function ensureWorker(langCode) {
    if (!window.Tesseract || typeof window.Tesseract.createWorker !== 'function') {
      throw new Error('Tesseract.js ist noch nicht geladen.');
    }
    if (activeWorker && activeLang === langCode) {
      return { worker: activeWorker, cacheSource: LOCAL_LANGS.has(langCode) ? 'localBundled' : 'indexedDbCache' };
    }
    if (activeWorker) {
      try {
        await activeWorker.terminate();
      } catch (_) {}
      activeWorker = null;
      activeLang = null;
    }

    const base = getBaseHrefPath();
    const isLocal = LOCAL_LANGS.has(langCode);
    const alreadyCached = isLocal ? true : await isLangInIndexedDb(langCode);
    const langPath = isLocal ? `${base}ocr/lang` : REMOTE_TESSDATA_URL;

    activeWorker = await window.Tesseract.createWorker(langCode, 1, {
      workerPath: `${base}ocr/worker.min.js`,
      corePath: `${base}ocr/`,
      langPath,
      cacheMethod: 'write',
      logger: () => {},
    });
    activeLang = langCode;
    if (!isLocal) cachedExtraLangs.add(langCode);

    return {
      worker: activeWorker,
      cacheSource: isLocal
        ? 'localBundled'
        : alreadyCached
        ? 'indexedDbCache'
        : 'downloadedToIndexedDb',
    };
  }

  async function recognizeRgbaInternal(rgbaBytes, width, height, langCode) {
    if (!rgbaBytes || width <= 0 || height <= 0) {
      return { lines: [], cacheSource: 'localBundled', error: 'Empty frame' };
    }
    const expectedLen = width * height * 4;
    if (rgbaBytes.byteLength < expectedLen) {
      return { lines: [], cacheSource: 'localBundled', error: 'Buffer smaller than frame dimensions' };
    }
    const { worker, cacheSource } = await ensureWorker(langCode || 'eng');
    const canvas = getReusableCanvas(width, height);
    const ctx = canvas.getContext('2d');
    const clamped = new Uint8ClampedArray(rgbaBytes.buffer, rgbaBytes.byteOffset, expectedLen);
    const imgData = new ImageData(clamped, width, height);
    ctx.putImageData(imgData, 0, 0);

    const res = await worker.recognize(canvas);
    const rawText = res && res.data && typeof res.data.text === 'string' ? res.data.text : '';
    const lines = rawText
      .split(/\r?\n/)
      .map((l) => l.trim())
      .filter((l) => l.length > 0);
    return { lines, cacheSource, error: null };
  }

  window.pokevaultWebOcr = {
    recognizeRgba: function (rgbaBytes, width, height, langCode) {
      const task = pendingChain.then(() =>
        recognizeRgbaInternal(rgbaBytes, width, height, langCode)
      );
      pendingChain = task.catch(() => {});
      return task;
    },
    dispose: async function () {
      if (activeWorker) {
        try {
          await activeWorker.terminate();
        } catch (_) {}
        activeWorker = null;
        activeLang = null;
      }
    },
  };
})();
