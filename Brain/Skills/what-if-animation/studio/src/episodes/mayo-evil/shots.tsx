import React from 'react';
import {
  Hero, Pose, basePose, poseAt, faceAt, kf, clamp, easeOut, easeIn, rnd, camT, LOOKS, LEG_LEN, HEAD,
  Rooftop, Stairwell, Tabletop, Schematic, SCH, SchLabel, CountUp, Glow, LightVeil, Foreground, FocusRings, FONT, ShotProps, joints, toWorld,
} from '../../engine';

// "What if Mayo was secretly evil?" Part 2 of Mayo's story. Nothing violent is shown: only the clues (a dropped cap,
// empty chairs, a list of names) and then the whole world finding out. The cover-up is the power: "Nothing happened."

const MAYO = LOOKS.mayo;
const MO = LOOKS.mo;
const RED = '#FF4A5A';

// ---------- S1: top-down insert: a guard's cap dropped on dark floorboards, one cold pool of light ----------
const GuardCap: React.FC<{ x: number; y: number; s: number; rot: number }> = ({ x, y, s, rot }) => (
  <g transform={`translate(${x} ${y}) rotate(${rot}) scale(${s})`}>
    <ellipse cx={12} cy={16} rx={150} ry={128} fill="#000" opacity={0.35} />
    <path d="M -40 60 Q 0 170 120 150 Q 60 110 40 60 Z" fill="#141826" />
    <circle cx={0} cy={0} r={118} fill="#22283C" stroke="#0C0E18" strokeWidth={8} />
    <circle cx={0} cy={0} r={86} fill="#2B3350" />
    <path d="M -70 -60 A 92 92 0 0 1 60 -70" stroke="#5A6488" strokeWidth={10} fill="none" opacity={0.6} strokeLinecap="round" />
    <path d="M 0 -34 L 10 -10 L 36 -8 L 16 8 L 22 34 L 0 20 L -22 34 L -16 8 L -36 -8 L -10 -10 Z" fill="#E9C46A" stroke="#7A5A20" strokeWidth={4} />
  </g>
);
export const S1: React.FC<ShotProps> = ({ t, len }) => (
  <g transform={`translate(960 540) rotate(${4 - t * 0.08}) scale(${1.02 + t * 0.004}) translate(-960 -540)`}>
    <Tabletop edge={1400} wood="#5A4636" grain="#4A3828" />
    <LightVeil id="s1veil" lights={[[980, 520, 430]]} o={0.78} />
    <Glow x={980} y={500} r={420} kind="cool" o={0.35} />
    <GuardCap x={980} y={540} s={1.5} rot={-24} />
    {/* scuffs on the boards, leading out of the light */}
    {[0, 1, 2, 3].map((i) => (
      <path key={i} d={`M ${1240 + i * 90} ${620 + i * 40} q 40 -10 70 6`} stroke="#2A1E16" strokeWidth={8} strokeLinecap="round" opacity={0.6} />
    ))}
  </g>
);

// ---------- S2: medium on the roof: Mayo shrugs, palms up, smug ----------
export const S2: React.FC<ShotProps> = ({ t, len }) => {
  const pose = poseAt(t, [
    { f: 0, p: { x: 900, y: 790, scale: 1.8, yaw: 0.25, look: 0.3, armL: { a: 14, b: -6 }, armR: { a: 14, b: -6 } } },
    { f: 10, p: { armL: { a: 10, b: -4 }, armR: { a: 10, b: -4 }, squash: 0.03 } },
    { f: 18, p: { armL: { a: 62, b: -70 }, armR: { a: 62, b: -70 }, headTilt: 10, squash: 0 }, ease: easeOut },
    { f: 22, p: { armL: { a: 58, b: -66 }, armR: { a: 58, b: -66 }, headTilt: 8 } },
  ]);
  return (
    <g transform={camT(960, kf(t, [[0, 560], [len, 545]]), kf(t, [[0, 1.0], [len, 1.05]]))}>
      <Rooftop t={t + 40} sunX={1300} sunY={600} low={260} red={0.12} />
      <Hero look={MAYO} pose={{ ...pose, ...faceAt(t, [[0, 'neutral'], [16, 'smug']]) }} rimId="rimR" shadow={0} />
      <Foreground blur={10}>
        <path d="M 1700 1100 Q 1760 840 1960 800 L 1960 1100 Z" fill="#120C18" />
      </Foreground>
    </g>
  );
};

// ---------- S3: top-down wide: a hundred empty chairs in rows, two knocked over ----------
const CHAIRS = Array.from({ length: 100 }).map((_, i) => ({ c: i % 10, r: Math.floor(i / 10), k: rnd(5, i) }));
const ChairTop: React.FC<{ x: number; y: number; rot: number; fallen?: boolean }> = ({ x, y, rot, fallen }) => (
  <g transform={`translate(${x} ${y}) rotate(${rot})`}>
    <rect x={-30} y={-22} width={64} height={60} rx={6} fill="#000" opacity={0.35} transform="translate(6 8)" />
    {fallen ? (
      <g>
        <rect x={-30} y={-10} width={60} height={22} rx={4} fill="#6A4E3C" />
        <rect x={-32} y={14} width={64} height={12} rx={4} fill="#4A3628" />
      </g>
    ) : (
      <g>
        <rect x={-28} y={-20} width={56} height={54} rx={6} fill="#7A5A44" stroke="#3A2A20" strokeWidth={3} />
        <rect x={-30} y={-30} width={60} height={14} rx={5} fill="#5A4232" stroke="#3A2A20" strokeWidth={3} />
      </g>
    )}
  </g>
);
export const S3: React.FC<ShotProps> = ({ t, len }) => (
  <g transform={`translate(960 540) rotate(${-2 + t * 0.04}) scale(${kf(t, [[0, 1.0], [len, 1.1]])}) translate(-960 -540)`}>
    <Tabletop edge={1400} wood="#4A3C34" grain="#3C3029" />
    {CHAIRS.map((ch, i) => (
      <g key={i} transform={`translate(${200 + ch.c * 190} ${-60 + ch.r * 150}) scale(1.7)`}><ChairTop x={0} y={0} rot={(ch.k - 0.5) * 10} fallen={i === 34 || i === 52} /></g>
    ))}
    <LightVeil id="s3veil" lights={[[960, 520, 720]]} o={0.45} />
    <Glow x={960} y={500} r={520} kind="cool" o={0.3} />
  </g>
);

// ---------- S4: close-up: Mayo, smug; "nothing happened" ----------
export const S4: React.FC<ShotProps> = ({ t, len }) => {
  const sc = 3.4 * (1 + 0.04 * clamp(t / len));
  const head = { x: 1060, y: 600 };
  const pose: Pose = { ...basePose, x: head.x, y: head.y - HEAD.y * sc, scale: sc, yaw: -0.3, look: -0.5, armL: { a: 14, b: -6 }, armR: { a: 14, b: -6 }, headTilt: kf(t, [[0, 0], [14, -7]]), ...faceAt(t, [[0, 'neutral'], [12, 'smug']]) };
  return (
    <g>
      <g filter="url(#blur16)">
        <g transform="translate(-500 -500) scale(1.9)">
          <Rooftop t={t + 120} sunX={900} sunY={600} red={0.15} low={160} />
        </g>
      </g>
      <rect x={0} y={0} width={1920} height={1080} fill="#07040C" opacity={0.28} />
      <Hero look={MAYO} pose={pose} rimId="rimL" shadow={0} />
    </g>
  );
};

// ---------- S5: medium on the landing: Mo reads a sheet of paper and freezes ----------
const LANDING = 420;
export const S5: React.FC<ShotProps> = ({ t, len }) => {
  const pose = poseAt(t, [
    { f: 0, p: { ...basePose, x: 320, y: LANDING - LEG_LEN * 0.9, scale: 0.9, yaw: 0.35, look: 0.5, armL: { a: 14, b: -6 }, armR: { a: 40, b: 70 }, headTilt: 10 } },
    { f: 20, p: { headTilt: 12 } },
    { f: 26, p: { headTilt: -4, squash: -0.04, armR: { a: 48, b: 74 } }, ease: easeOut },
    { f: 30, p: { headTilt: -2, squash: 0 } },
  ]);
  const h = toWorld(pose, joints(pose).armR.end);
  const shake = t > 26 ? Math.sin(t * 2.3) * 1.5 : 0;
  return (
    <g transform={camT(kf(t, [[0, 340], [len, 335]]), 300, kf(t, [[0, 1.6], [len, 1.75]]))}>
      <Stairwell t={t + 80} id="sw5e" />
      <Hero look={MO} pose={{ ...pose, ...faceAt(t, [[0, 'neutral'], [24, 'shock']]) }} rimId="rimL" shadow={0.5} />
      <g transform={`translate(${h.x + 6 + shake} ${h.y - 30}) rotate(-12)`}>
        <rect x={-30} y={-40} width={62} height={80} fill="#F2EEE4" stroke="#1A1622" strokeWidth={3} />
        {[0, 1, 2, 3, 4, 5].map((i) => (
          <path key={i} d={`M -20 ${-28 + i * 12} L 20 ${-28 + i * 12}`} stroke="#5A5A6A" strokeWidth={3} />
        ))}
      </g>
      <g transform={`translate(320 ${LANDING - LEG_LEN * 0.9 + HEAD.y * 0.9}) scale(0.4)`}><FocusRings x={0} y={0} t={t - 26} r0={60} /></g>
    </g>
  );
};

// ---------- S6: insert: the list, rows of names (scribbles), a red 100 circled at the bottom ----------
export const S6: React.FC<ShotProps> = ({ t, len }) => {
  const lines = Array.from({ length: 26 }).map((_, i) => ({ col: i % 2, row: Math.floor(i / 2), w: 180 + rnd(3, i) * 150 }));
  return (
    <g transform={`translate(960 540) rotate(${-4 + t * 0.06}) scale(${kf(t, [[0, 1.0], [len, 1.12]])}) translate(-960 -540)`}>
      <Tabletop edge={1400} wood="#4A3C34" grain="#3C3029" />
      <rect x={530} y={-20} width={880} height={1140} fill="#000" opacity={0.35} transform="translate(14 18)" />
      <rect x={530} y={-20} width={880} height={1140} fill="#F2EEE4" />
      {lines.map((l, i) => (
        <g key={i}>
          <circle cx={600 + l.col * 410} cy={80 + l.row * 64} r={7} fill="#3A3448" />
          <path d={`M ${620 + l.col * 410} ${80 + l.row * 64} q ${l.w * 0.25} -14 ${l.w * 0.5} 0 t ${l.w * 0.5} 0`} stroke="#3A3448" strokeWidth={5} fill="none" strokeLinecap="round" />
        </g>
      ))}
      <g opacity={clamp((t - 8) / 4)}>
        <ellipse cx={1180} cy={970} rx={130} ry={74} fill="none" stroke={RED} strokeWidth={10} transform="rotate(-6 1180 970)" />
        <text x={1180} y={1000} textAnchor="middle" fontFamily={FONT.hand} fontWeight={700} fontSize={96} fill={RED}>100</text>
      </g>
      <LightVeil id="s6veil" lights={[[960, 520, 640]]} o={0.4} />
    </g>
  );
};

// ---------- S7: the title, wide on the roof; the dusk reddening; Mayo alone ----------
const ROOF_FEET = 840;
export const S7: React.FC<ShotProps> = ({ t, len }) => (
  <g transform={camT(960, kf(t, [[0, 520], [len, 545]]), kf(t, [[0, 1.0], [len, 1.07]]))}>
    <Rooftop t={t + 160} sunX={960} sunY={700} red={0.35 * clamp(t / 40)} />
    <Hero look={MAYO} pose={{ ...basePose, x: 960, y: ROOF_FEET - LEG_LEN * 0.62, scale: 0.62, yaw: 0, armL: { a: 14, b: -6 }, armR: { a: 14, b: -6 }, ...faceAt(t, [[0, 'smug']]) }} rimId="rimR" shadow={0.6} />
    <TitleText t={t} />
  </g>
);
import { TitleCard } from '../../engine';
const TitleText: React.FC<{ t: number }> = ({ t }) => <TitleCard t={t} lines={['WHAT IF MAYO', 'WAS SECRETLY EVIL?']} accent="EVIL" accentT={36} size={108} y={170} />;

// ---------- S8: schematic: the crowd; 8,230,000,000 ----------
const Person: React.FC<{ x: number; y: number; s: number; o: number; c?: string }> = ({ x, y, s, o, c }) => (
  <g transform={`translate(${x} ${y}) scale(${s})`} opacity={o} stroke={c ?? (o > 0.9 ? SCH.live : SCH.dim)} strokeWidth={4} fill="none">
    <circle cx={0} cy={-26} r={10} />
    <path d="M -14 14 Q -14 -12 0 -12 Q 14 -12 14 14" />
  </g>
);
const CROWD = Array.from({ length: 12 * 26 }).map((_, i) => ({ x: 110 + (i % 26) * 66 + (Math.floor(i / 26) % 2) * 33, y: 260 + Math.floor(i / 26) * 44, k: rnd(7, i) }));
export const S8: React.FC<ShotProps> = ({ t, len }) => (
  <g transform={`translate(960 540) scale(${kf(t, [[0, 1], [len, 1.05]])}) translate(-960 -540)`}>
    <Schematic t={t} id="sch8e" />
    <SchLabel x={960} y={150} t={t - 2} text="PEOPLE MAYO RULES" size={56} />
    {CROWD.map((p, i) => {
      const on = clamp((t - 4 - p.k * 40 - (p.x / 1920) * 20) / 5);
      return on > 0 ? <Person key={i} x={p.x} y={p.y} s={0.9} o={on} /> : null;
    })}
    <rect x={460} y={748} width={1000} height={160} rx={20} fill={SCH.ground} opacity={0.88} />
    <CountUp x={960} y={845} t={t - 10} to={8.23e9} dur={48} size={110} />
    <SchLabel x={960} y={892} t={t - 30} text="UN ESTIMATE, MID-2025" size={30} color={SCH.dim} />
  </g>
);

// ---------- S9: schematic: one in every hundred lights up red; 82,300,000 ----------
const GRID = Array.from({ length: 100 }).map((_, i) => ({ c: i % 20, r: Math.floor(i / 20) }));
export const S9: React.FC<ShotProps> = ({ t }) => (
  <g>
    <Schematic t={t + 92} id="sch9e" />
    <SchLabel x={960} y={150} t={t - 2} text="1 IN EVERY 100" size={64} />
    {GRID.map((g, i) => {
      const hot = i === 47;
      const on = clamp((t - 2 - i * 0.12) / 4);
      return <Person key={i} x={390 + g.c * 60} y={290 + g.r * 74} s={1.1} o={on} c={hot && t > 16 ? RED : SCH.dim} />;
    })}
    {t > 16 ? <circle cx={390 + 7 * 60} cy={290 + 2 * 74 - 10} r={44 + Math.sin(t / 3) * 4} fill="none" stroke={RED} strokeWidth={5} /> : null}
    <CountUp x={960} y={810} t={t - 24} to={8.23e7} dur={50} size={120} color={RED} />
    <SchLabel x={960} y={880} t={t - 40} text="PEOPLE COMING FOR HIM" size={36} color={SCH.dim} />
  </g>
);

// ---------- S10: extreme close-up: "That's real." Mayo, worried; red light ----------
export const S10: React.FC<ShotProps> = ({ t, len }) => {
  const sc = 4.4 * (1 + 0.05 * clamp(t / len));
  const head = { x: 960, y: 640 };
  const pose: Pose = { ...basePose, x: head.x, y: head.y - HEAD.y * sc, scale: sc, yaw: 0.12, look: 0.1, armL: { a: 14, b: -6 }, armR: { a: 14, b: -6 }, ...faceAt(t, [[0, 'worried']]) };
  return (
    <g>
      <g filter="url(#blur16)">
        <g transform="translate(-600 -560) scale(2)">
          <Rooftop t={t + 200} sunX={980} sunY={600} red={0.5 + 0.3 * clamp(t / len)} low={180} />
        </g>
      </g>
      <rect x={0} y={0} width={1920} height={1080} fill="#07040C" opacity={0.22} />
      <Hero look={MAYO} pose={pose} rimId="rimRed" shadow={0} />
    </g>
  );
};

// ---------- S11: wide, low angle: a sea of heads and phone lights rises below the roof; Mayo backs away ----------
const HEADS = Array.from({ length: 72 }).map((_, i) => ({ x: -80 + (i % 24) * 90 + (Math.floor(i / 24) % 2) * 45, row: 2 - Math.floor(i / 24), k: rnd(13, i) }));
export const S11: React.FC<ShotProps> = ({ t, len }) => {
  const red = easeOut(clamp(t / 14));
  const rise = easeOut(clamp(t / 30));
  const pose = poseAt(t, [
    { f: 0, p: { ...basePose, x: 960, y: 860 - LEG_LEN * 0.9, scale: 0.9, yaw: 0.1, look: 0, armL: { a: 30, b: 40 }, armR: { a: 30, b: 40 } } },
    { f: 24, p: { x: 990, tilt: 6, armL: { a: 40, b: 70 }, armR: { a: 40, b: 70 } }, ease: easeOut },
  ]);
  return (
    <g transform={camT(kf(t, [[0, 960], [len, 960]]), kf(t, [[0, 540], [len, 520]]), kf(t, [[0, 1.0], [len, 1.12]]))}>
      <Rooftop t={t + 230} sunX={1180} sunY={600} red={red} blackout={clamp((t - 6) / 40)} low={40} cityLit={2.6} />
      <Hero look={MAYO} pose={{ ...pose, ...faceAt(t, [[0, 'worried'], [18, 'shock']]) }} rimId="rimRed" shadow={0} />
      {/* the crowd below the parapet: silhouettes, phone lights held up */}
      {HEADS.map((h, i) => {
        const y = 1260 - h.row * 80 - 190 * rise - h.k * 30 + Math.sin(t / 5 + i) * 4;
        return (
          <g key={i}>
            <path d={`M ${h.x - 62} ${y + 190} Q ${h.x - 60} ${y + 66} ${h.x} ${y + 60} Q ${h.x + 60} ${y + 66} ${h.x + 62} ${y + 190} Z`} fill={h.row ? '#1E1218' : '#0C070E'} />
            <circle cx={h.x} cy={y} r={46} fill={h.row ? '#1E1218' : '#0C070E'} />
            <path d={`M ${h.x - 40} ${y - 18} A 46 46 0 0 1 ${h.x + 30} ${y - 34}`} stroke="#FF6A6A" strokeWidth={4} fill="none" opacity={0.5} />
            {h.k > 0.45 ? (
              <g>
                <path d={`M ${h.x + 40} ${y + 70} L ${h.x + 56} ${y - 50}`} stroke="#0C070E" strokeWidth={16} strokeLinecap="round" />
                <rect x={h.x + 42} y={y - 100} width={28} height={48} rx={4} fill="#E8F4FF" />
                <circle cx={h.x + 56} cy={y - 76} r={60} fill="#BFE0FF" opacity={0.14} />
              </g>
            ) : null}
          </g>
        );
      })}
    </g>
  );
};
