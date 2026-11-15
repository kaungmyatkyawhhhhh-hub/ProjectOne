import React from 'react';
import { defineEpisode, Timeline, LookDef, HudChip } from '../../engine';
import timeline from './timeline.json';
import words from './words.json';
import { S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11 } from './shots';

// The cover-up look: when Mayo says "nothing happened", the picture goes cold and a red DECREE chip blinks.
const coverLook: LookDef = {
  grade: (lv) => `saturate(${1 - 0.3 * lv}) hue-rotate(${-10 * lv}deg) contrast(${1 + 0.08 * lv})`,
  Overlay: ({ f }) => <HudChip f={f} label="DECREE" icon="dot" />,
};

export const mayoEvil = defineEpisode('MayoEvil', {
  timeline: timeline as Timeline,
  shots: { S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11 },
  looks: { cover: coverLook },
  words,
  captions: { hideShots: ['S7'], yByShot: { S8: 1012, S9: 1000 } },
});
