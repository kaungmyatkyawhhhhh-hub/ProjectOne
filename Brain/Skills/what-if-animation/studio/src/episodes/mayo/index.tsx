import React from 'react';
import { defineEpisode, Timeline, LookDef, HudChip } from '../../engine';
import timeline from './timeline.json';
import { S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11 } from './shots';

// The power's look: on "Done." the picture warms to gold for a beat and a DECREE chip blinks in; the gold ring and
// flash are drawn in the shot (PasteIn) and as fx cues.
const decreeLook: LookDef = {
  grade: (lv) => `sepia(${0.22 * lv}) saturate(${1 + 0.25 * lv}) brightness(${1 + 0.05 * lv})`,
  Overlay: ({ f }) => <HudChip f={f} label="DECREE" icon="dot" />,
};

export const mayo = defineEpisode('Mayo', {
  timeline: timeline as Timeline,
  shots: { S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11 },
  looks: { decree: decreeLook },
});
