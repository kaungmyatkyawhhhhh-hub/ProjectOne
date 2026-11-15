import React from 'react';
import { clamp, easeOut } from './anim';
import { FONT } from './fonts';

// On-screen captions, synced to the voice word by word: short punchy phrases (up to `max` words, broken at
// punctuation), big bold title face with a thick dark outline, the word being spoken lit in the accent colour,
// each phrase popping in with a small overshoot.

export type Word = { w: string; s: number; e: number; p?: string };
export type CaptionOpts = { max?: number; size?: number; y?: number; color?: string; accent?: string; hideShots?: string[]; yByShot?: Record<string, number> };

export const phrases = (words: Word[], max = 3) => {
  const out: Word[][] = [];
  let cur: Word[] = [];
  for (const w of words) {
    cur.push(w);
    if (cur.length >= max || /[.,:;!?…]/.test(w.p ?? '')) {
      out.push(cur);
      cur = [];
    }
  }
  if (cur.length) out.push(cur);
  return out;
};

export const Captions: React.FC<{ f: number; fps: number; words: Word[]; shot: string; opts?: CaptionOpts }> = ({ f, fps, words, shot, opts = {} }) => {
  const { max = 3, size = 92, y = 905, color = '#FFFFFF', accent = '#FFC94A', hideShots = [], yByShot = {} } = opts;
  if (hideShots.includes(shot)) return null;
  const t = f / fps;
  const ph = phrases(words, max);
  const i = ph.findIndex((g, k) => t >= g[0].s - 0.03 && t < (ph[k + 1] ? ph[k + 1][0].s - 0.03 : g[g.length - 1].e + 0.6));
  if (i < 0) return null;
  const g = ph[i];
  const age = (t - g[0].s + 0.03) * fps; // frames since the phrase appeared
  const pop = age < 0 ? 0 : age < 4 ? 0.7 + 0.42 * easeOut(clamp(age / 4)) : 1.12 - 0.12 * clamp((age - 4) / 3);
  const yy = yByShot[shot] ?? y;
  return (
    <g transform={`translate(960 ${yy}) scale(${pop})`}>
      <text textAnchor="middle" fontFamily={FONT.title} fontWeight={800} fontSize={size} letterSpacing={1} style={{ paintOrder: 'stroke' }} stroke="#0B0812" strokeWidth={size * 0.2} strokeLinejoin="round">
        {g.map((w, k) => {
          const live = t >= w.s - 0.03 && t < w.e + 0.08;
          return (
            <tspan key={k} fill={live ? accent : color} dx={k ? size * 0.28 : 0}>
              {(w.w + (w.p && /[?!]/.test(w.p) ? w.p.replace(/[^?!]/g, '') : '')).toUpperCase()}
            </tspan>
          );
        })}
      </text>
    </g>
  );
};
