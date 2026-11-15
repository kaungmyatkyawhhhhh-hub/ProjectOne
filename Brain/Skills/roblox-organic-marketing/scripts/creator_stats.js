// creator_stats.js: read a TikTok creator's profile in the built-in browser (read only; nothing is liked, followed or sent).
// 1. Open https://www.tiktok.com/@handle in the built-in browser.
// 2. Run this whole file with the browser's javascript tool. It scrolls the grid a little, then returns one row:
//    {handle, name, followers, likes, videos, bio, email, link, verified, posts:[views...], pinned, medianViews, p25, p75, under1kShare, row}
// Views come from the profile grid (newest first; pinned posts are left out of the median).
// Paste `row` into the shortlist table in references/templates.md.
(async () => {
  const sleep = ms => new Promise(r => setTimeout(r, ms));
  const num = s => { if (!s) return 0; s = String(s).trim().toUpperCase().replace(/,/g, '');
    const m = s.match(/^([\d.]+)\s*([KMB])?$/); if (!m) return +s || 0;
    return Math.round(parseFloat(m[1]) * ({K: 1e3, M: 1e6, B: 1e9}[m[2]] || 1)); };
  let user = {}, stats = {};
  try {
    const d = JSON.parse(document.getElementById('__UNIVERSAL_DATA_FOR_REHYDRATION__').textContent).__DEFAULT_SCOPE__['webapp.user-detail'].userInfo;
    user = d.user || {}; stats = d.statsV2 || d.stats || {};
  } catch (e) {}
  // the grid fills in a few seconds after load (grey placeholders first): wait for it
  for (let i = 0; i < 20 && !document.querySelector('[data-e2e="user-post-item"] [data-e2e="video-views"]'); i++) await sleep(750);
  for (let i = 0; i < 3; i++) { window.scrollBy(0, 1200); await sleep(1500); }
  const items = [...document.querySelectorAll('[data-e2e="user-post-item"]')];
  const posts = [], pinnedViews = [];
  for (const it of items) {
    const v = num((it.querySelector('[data-e2e="video-views"]') || {}).textContent);
    const pinned = /pinned/i.test(it.innerText);
    (pinned ? pinnedViews : posts).push(v);
  }
  window.scrollTo(0, 0);
  const recent = posts.slice(0, 12), sorted = [...recent].sort((a, b) => a - b);
  const q = p => sorted.length ? sorted[Math.min(sorted.length - 1, Math.floor(p * (sorted.length - 1) + 0.5))] : 0;
  const bio = user.signature || '';
  const email = (bio.match(/[\w.+-]+@[\w-]+\.[\w.]+/) || [''])[0];
  const out = {
    handle: '@' + (user.uniqueId || location.pathname.split('/')[1].replace('@', '')), name: user.nickname || '',
    followers: +(stats.followerCount || 0), likes: +(stats.heartCount || stats.heart || 0), videos: +(stats.videoCount || 0),
    bio, email, link: (user.bioLink && user.bioLink.link) || '', verified: !!user.verified, privateAccount: !!user.privateAccount,
    posts: recent, pinned: pinnedViews, medianViews: q(0.5), p25: q(0.25), p75: q(0.75),
    under1kShare: recent.length ? +(recent.filter(v => v < 1000).length / recent.length).toFixed(2) : null,
  };
  out.row = `| ${out.handle} | ${out.followers} | ${out.medianViews} (${out.p25}-${out.p75}) | ${recent.length} | ${out.email || '-'} | |`;
  return out;
})();
