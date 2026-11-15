import React from 'react';
import {
  Hero, Pose, basePose, poseAt, faceAt, kf, clamp, easeOut, easeIn, rnd, settle, camT, LOOKS, LEG_LEN, HEAD, stand,
  Rooftop, Classroom, CLS, SchoolDesk, Stairwell, Banister, stepTop, Tabletop, Schematic, SCH, SchLabel, CountUp, Arrow, DrawOn,
  PizzaSlice, PasteIn, Sparkle, TitleCard, Dial, Glow, Foreground, LightVeil, FocusRings, FONT, ShotProps,
} from '../../engine';

// "What if a guy named Mayo ruled the Earth?" Eleven shots on the rooftop, the classroom, the stairwell and the
// schematic. The power: whatever Mayo says becomes law. On "Done." a gold ring opens and a DECREE chip shows.

const MAYO = LOOKS.mayo;
const PIP = LOOKS.pipHood;
const GOLD = '#FFC94A';

/** A whole pizza from above: eight slices round a centre. */
const Pizza: React.FC<{ x: number; y: number; r: number; rot?: number }> = ({ x, y, r, rot = 0 }) => (
  <g>
    <circle cx={x + 10} cy={y + 14} r={r * 1.08} fill="#000" opacity={0.3} />
    <circle cx={x} cy={y} r={r * 1.1} fill="#E8E0D0" />
    <circle cx={x} cy={y} r={r * 1.1} fill="none" stroke="#C9BFAE" strokeWidth={4} />
    {Array.from({ length: 8 }).map((_, i) => (
      <PizzaSlice key={i} x={x} y={y} len={r} rot={rot + i * 45 + 22.5} shadow={0} />
    ))}
  </g>
);

// ---------- S1: medium, low angle on the roof: Mayo points up, "free pizza" ----------
export const S1: React.FC<ShotProps> = ({ t, len }) => {
  const pose = poseAt(t, [
    { f: 0, p: { x: 900, y: 790, scale: 1.8, yaw: 0.3, look: 0.5, armL: { a: 16, b: 6 }, armR: { a: 30, b: 20 }, headTilt: 0 } },
    { f: 10, p: { armR: { a: 40, b: 30 } } },
    { f: 18, p: { armR: { a: 168, b: 4 }, headTilt: -6, look: 0.8 }, ease: easeOut },
    { f: 22, p: { armR: { a: 160, b: 0 } } },
  ]);
  return (
    <g transform={camT(960, kf(t, [[0, 560], [len, 540]]), kf(t, [[0, 1.0], [len, 1.06]]))}>
      <Rooftop t={t + 20} sunX={1300} sunY={560} low={260} />
      <Hero look={MAYO} pose={{ ...pose, handR: t > 16 ? 'point' : 'open', ...faceAt(t, [[0, 'neutral'], [16, 'smug']]) }} rimId="rimR" shadow={0} />
      <Foreground blur={10}>
        <path d="M -40 1100 Q 80 820 260 780 Q 220 900 300 1100 Z" fill="#120C18" />
      </Foreground>
    </g>
  );
};

// ---------- S2: top-down insert: pizzas pop onto the table, one after another ----------
const PIZZAS = [
  { x: 700, y: 520, r: 210, at: -4 },
  { x: 1230, y: 470, r: 200, at: 3 },
  { x: 1000, y: 860, r: 190, at: 8 },
  { x: 380, y: 860, r: 170, at: 11 },
  { x: 1600, y: 850, r: 175, at: 13 },
  { x: 260, y: 300, r: 150, at: 15 },
  { x: 1660, y: 240, r: 150, at: 16 },
];
export const S2: React.FC<ShotProps> = ({ t, len }) => (
  <g transform={`translate(960 540) rotate(${-3 + t * 0.12}) scale(${1.04 + t * 0.004}) translate(-960 -540)`}>
    <Tabletop edge={1400} />
    <Glow x={960} y={460} r={760} o={0.35} />
    {PIZZAS.map((p, i) => (
      <PasteIn key={i} x={p.x} y={p.y} t={t - p.at} color={GOLD} ring={p.r * 1.3}>
        <Pizza x={p.x} y={p.y} r={p.r} rot={i * 17} />
      </PasteIn>
    ))}
    <Sparkle x={860} y={330} t={t - 4} s={1.4} />
    <Sparkle x={1380} y={300} t={t - 7} s={1.1} />
  </g>
);

// ---------- S3: wide, the classroom: Mayo at the board, pointing at a crossed-out Monday ----------
const WEEK = ['M', 'T', 'W', 'T', 'F'];
const Board: React.FC<{ t: number }> = ({ t }) => {
  const cross = clamp((t - 24) / 8);
  return (
    <g fontFamily={FONT.hand} fill="#F2EEE4">
      {WEEK.map((d, i) => (
        <g key={i}>
          <rect x={470 + i * 112} y={290} width={96} height={130} rx={6} fill="none" stroke="#F2EEE4" strokeWidth={4} opacity={0.85} />
          <text x={518 + i * 112} y={380} fontSize={72} textAnchor="middle" opacity={0.9}>{d}</text>
        </g>
      ))}
      {cross > 0 ? (
        <g stroke="#FF8A7A" strokeWidth={10} strokeLinecap="round">
          <path d={`M 466 286 L ${466 + 104 * cross} ${286 + 138 * cross}`} />
          {cross > 0.5 ? <path d={`M 570 286 L ${570 - 104 * (cross - 0.5) * 2} ${286 + 138 * (cross - 0.5) * 2}`} /> : null}
        </g>
      ) : null}
    </g>
  );
};
const S3_STAND = stand(CLS, 0.72, 0.12);
export const S3: React.FC<ShotProps> = ({ t, len }) => {
  const pose = poseAt(t, [
    { f: 0, p: { x: S3_STAND.x, y: S3_STAND.y, scale: S3_STAND.scale, yaw: -0.4, look: -0.7, armL: { a: 20, b: 10 }, armR: { a: 14, b: -6 } } },
    { f: 12, p: { armL: { a: 30, b: 20 } } },
    { f: 20, p: { armL: { a: 100, b: 4 }, headTilt: 4 }, ease: easeOut },
    { f: 24, p: { armL: { a: 94, b: 0 } } },
  ]);
  return (
    <g transform={camT(kf(t, [[0, 900], [len, 880]]), kf(t, [[0, 470], [len, 460]]), kf(t, [[0, 0.98], [len, 1.04]]))}>
      <Classroom t={t + 30} id="cl3" board={<Board t={t} />} />
      <Hero look={MAYO} pose={{ ...pose, handL: t > 18 ? 'point' : 'open', ...faceAt(t, [[0, 'neutral'], [22, 'smug']]) }} rimId="rimL" shadow={0.6} />
    </g>
  );
};

// ---------- S4: medium on Pip at his desk: both arms up; the class laughs ----------
export const S4: React.FC<ShotProps> = ({ t, len }) => {
  const pose = poseAt(t, [
    { f: 0, p: { x: 1260, y: 640, scale: 1, yaw: -0.35, look: -0.4, armL: { a: 30, b: 30 }, armR: { a: 30, b: 30 }, squash: 0.04 } },
    { f: 3, p: { armL: { a: 155, b: 10 }, armR: { a: 155, b: 10 }, squash: -0.05, headTilt: -6 }, ease: easeOut },
    { f: 7, p: { armL: { a: 146, b: 18 }, armR: { a: 146, b: 18 }, squash: 0, headTilt: -3 } },
  ]);
  return (
    <g transform={camT(kf(t, [[0, 1180], [len, 1190]]), 560, kf(t, [[0, 1.7], [len, 1.8]]))}>
      <Classroom t={t + 110} id="cl4" laugh={1} board={<Board t={60} />} />
      <Hero look={PIP} pose={{ ...pose, ...faceAt(t, [[0, 'happy']]) }} rimId="rimL" shadow={0} />
      <SchoolDesk x={1260} />
      <Foreground blur={10}>
        <path d="M 760 1100 Q 760 860 900 820 Q 1020 800 1060 900 L 1080 1100 Z" fill="#160F1C" />
        <circle cx={930} cy={760} r={110} fill="#1A1220" />
      </Foreground>
    </g>
  );
};

// ---------- the stairwell: Mayo on the landing, the household on the steps ----------
const LANDING = 420;
const onLanding = (x: number, s = 0.9, extra: Partial<Pose> = {}): Pose => ({ ...basePose, x, y: LANDING - LEG_LEN * s, scale: s, ...extra });
const onStep = (x: number, s = 0.9, extra: Partial<Pose> = {}): Pose => ({ ...basePose, x, y: stepTop(x) - LEG_LEN * s, scale: s, ...extra });

// ---------- S5: medium, low angle: Mayo on the landing, arm out over the stairs ----------
export const S5: React.FC<ShotProps> = ({ t, len }) => {
  const pose = poseAt(t, [
    { f: 0, p: { ...onLanding(300), yaw: 0.45, look: 0.7, armL: { a: 14, b: -6 }, armR: { a: 20, b: 10 } } },
    { f: 14, p: { armR: { a: 14, b: 20 } } },
    { f: 22, p: { armR: { a: 98, b: 4 }, headTilt: -5 }, ease: easeOut },
    { f: 26, p: { armR: { a: 90, b: 0 } } },
  ]);
  return (
    <g transform={camT(kf(t, [[0, 360], [len, 350]]), 300, kf(t, [[0, 1.6], [len, 1.7]]))}>
      <Stairwell t={t + 60} id="sw5" />
      <Hero look={MAYO} pose={{ ...pose, ...faceAt(t, [[0, 'neutral'], [20, 'smug']]) }} rimId="rimL" shadow={0.5} />
      <Foreground blur={10}>
        <path d="M 520 700 Q 560 520 700 500 Q 820 500 860 620 L 900 720 Z" fill="#140E1A" />
      </Foreground>
    </g>
  );
};

// ---------- S6: wide: Mo, Mum, the sister and the suit on the steps all bow to Mayo at once ----------
const BOWERS: { look: keyof typeof LOOKS; x: number; s: number }[] = [
  { look: 'mo', x: 560, s: 0.9 },
  { look: 'mom', x: 800, s: 0.9 },
  { look: 'sis', x: 1010, s: 0.64 },
  { look: 'suit', x: 1250, s: 0.9 },
];
const bowPose = (x: number, s: number, b: number): Pose =>
  onStep(x, s, { yaw: -0.55, look: -0.6, tilt: -20 * b, headTilt: -16 * b, armL: { a: 14 + 6 * b, b: -6 }, armR: { a: 14 + 6 * b, b: -6 } });
export const S6: React.FC<ShotProps> = ({ t, len }) => {
  const b = easeOut(clamp((t - 2) / 5)) + settle(t - 7, 0.06, 1.6, 4);
  return (
    <g transform={camT(800, kf(t, [[0, 560], [len, 555]]), kf(t, [[0, 0.98], [len, 1.02]]))}>
      <Stairwell t={t + 140} id="sw6" />
      <Hero look={MAYO} pose={{ ...onLanding(250), yaw: 0.45, look: 0.7, armR: { a: 90, b: 0 }, armL: { a: 14, b: -6 }, expr: 'smug' }} rimId="rimL" shadow={0.5} />
      {BOWERS.map((w, i) => (
        <Hero key={i} look={LOOKS[w.look]} pose={{ ...bowPose(w.x, w.s, b), expr: 'neutral', blink: b > 0.5 ? 1 : 0 }} rimId="rimL" shadow={0.5} />
      ))}
      <Banister />
    </g>
  );
};

// ---------- S7: the title, wide on the roof at dusk; Mayo, arms wide ----------
const ROOF_FEET = 840;
export const S7: React.FC<ShotProps> = ({ t, len }) => {
  const pose = poseAt(t, [
    { f: 0, p: { x: 960, y: ROOF_FEET - LEG_LEN * 0.62, scale: 0.62, yaw: 0, armL: { a: 20, b: 6 }, armR: { a: 20, b: 6 } } },
    { f: 16, p: {} },
    { f: 24, p: { armL: { a: 130, b: 10 }, armR: { a: 130, b: 10 } }, ease: easeOut },
  ]);
  return (
    <g transform={camT(960, kf(t, [[0, 520], [len, 545]]), kf(t, [[0, 1.0], [len, 1.07]]))}>
      <Rooftop t={t + 90} sunX={960} sunY={690 - 40 * easeOut(clamp(t / 40))} />
      <Hero look={MAYO} pose={{ ...pose, ...faceAt(t, [[0, 'happy']]) }} rimId="rimR" shadow={0.6} />
      <TitleCard t={t} lines={['WHAT IF MAYO', 'RULED THE EARTH?']} accent="EARTH" accentT={40} size={112} y={170} />
    </g>
  );
};

// ---------- S8: schematic: a crowd of people icons fills the grid; 8,230,000,000 counts up ----------
const Person: React.FC<{ x: number; y: number; s: number; o: number }> = ({ x, y, s, o }) => (
  <g transform={`translate(${x} ${y}) scale(${s})`} opacity={o} stroke={o > 0.9 ? SCH.live : SCH.dim} strokeWidth={4} fill="none">
    <circle cx={0} cy={-26} r={10} />
    <path d="M -14 14 Q -14 -12 0 -12 Q 14 -12 14 14" />
  </g>
);
const CROWD = Array.from({ length: 12 * 26 }).map((_, i) => {
  const c = i % 26;
  const r = Math.floor(i / 26);
  return { x: 110 + c * 66 + (r % 2) * 33, y: 260 + r * 44, k: rnd(7, i) };
});
export const S8: React.FC<ShotProps> = ({ t, len }) => (
  <g transform={`translate(960 540) scale(${kf(t, [[0, 1], [len, 1.05]])}) translate(-960 -540)`}>
    <Schematic t={t} id="sch8" />
    <SchLabel x={960} y={150} t={t - 2} text="PEOPLE ON EARTH" size={56} />
    {CROWD.map((p, i) => {
      const on = clamp((t - 4 - p.k * 40 - (p.x / 1920) * 20) / 5);
      return on > 0 ? <Person key={i} x={p.x} y={p.y} s={0.9} o={on} /> : null;
    })}
    <rect x={460} y={780} width={1000} height={170} rx={20} fill={SCH.ground} opacity={0.85} />
    <CountUp x={960} y={880} t={t - 10} to={8.23e9} dur={48} size={110} />
    <SchLabel x={960} y={935} t={t - 30} text="UN ESTIMATE, MID-2025" size={30} color={SCH.dim} />
  </g>
);

// ---------- S9: schematic: one second each, times 8.23 billion: the dial runs to 260 years ----------
export const S9: React.FC<ShotProps> = ({ t }) => {
  const yrs = 260 * easeIn(clamp((t - 22) / 66)) ** 0.6;
  return (
    <g>
      <Schematic t={t + 92} id="sch9" />
      <SchLabel x={520} y={300} t={t - 2} text="1 SECOND" size={84} />
      <SchLabel x={520} y={360} t={t - 6} text="PER PERSON, NO SLEEP" size={30} color={SCH.dim} />
      <SchLabel x={520} y={520} t={t - 10} text="× 8,230,000,000" size={64} />
      <DrawOn d="M 300 590 L 740 590" t={t - 14} dur={6} />
      <SchLabel x={520} y={700} t={t - 18} text="= 8,230,000,000 SECONDS" size={36} color={SCH.dim} />
      <Arrow x0={860} y0={520} x1={1150} y1={520} t={t - 20} />
      <Dial x={1480} y={500} r={210} p={yrs / 260} readout={`${Math.floor(yrs)}`} size={110} />
      <SchLabel x={1480} y={800} t={t - 24} text="YEARS" size={64} color={SCH.live} />
      <SchLabel x={1480} y={220} t={t - 88} text="OVER 250 YEARS" size={50} color={SCH.live} />
    </g>
  );
};

// ---------- S10: extreme close-up: "That's real." Mayo, worried; the light turns red ----------
export const S10: React.FC<ShotProps> = ({ t, len }) => {
  const sc = 4.4 * (1 + 0.05 * clamp(t / len));
  const head = { x: 960, y: 640 };
  const red = 0.25 + 0.4 * clamp(t / len);
  const pose: Pose = { ...basePose, x: head.x, y: head.y - HEAD.y * sc, scale: sc, yaw: 0.12, look: 0.1, armL: { a: 14, b: -6 }, armR: { a: 14, b: -6 }, ...faceAt(t, [[0, 'worried']]) };
  return (
    <g>
      <g filter="url(#blur16)">
        <g transform="translate(-600 -560) scale(2)">
          <Rooftop t={t + 200} sunX={980} sunY={600} red={red} low={180} />
        </g>
      </g>
      <rect x={0} y={0} width={1920} height={1080} fill="#07040C" opacity={0.22} />
      <Hero look={MAYO} pose={pose} rimId={t > len * 0.4 ? 'rimRed' : 'rimR'} shadow={0} />
    </g>
  );
};

// ---------- S11: wide: a queue packed up the whole stairwell toward Mayo; the light goes red ----------
const QUEUE_LOOKS: (keyof typeof LOOKS)[] = ['mo', 'mom', 'suit', 'pip', 'sis', 'pipInk', 'mom', 'mo', 'suit', 'pipHood', 'pip', 'mom', 'mo', 'suit'];
const QUEUE = Array.from({ length: 14 }).map((_, i) => ({ x: 470 + i * 88, look: QUEUE_LOOKS[i], s: QUEUE_LOOKS[i] === 'sis' ? 0.62 : 0.86, k: rnd(11, i) }));
export const S11: React.FC<ShotProps> = ({ t, len }) => {
  const red = easeOut(clamp(t / 14));
  return (
    <g transform={camT(kf(t, [[0, 820], [len, 760]]), kf(t, [[0, 560], [len, 520]]), kf(t, [[0, 0.95], [len, 1.12]]))}>
      <Stairwell t={t + 300} id="sw11" />
      <Hero look={MAYO} pose={{ ...onLanding(230), yaw: 0.45, look: 0.8, armL: { a: 30, b: 50 }, armR: { a: 30, b: 50 }, tilt: -4, ...faceAt(t, [[0, 'worried'], [20, 'shock']]) }} rimId="rimRed" shadow={0.5} />
      <FocusRings x={230} y={LANDING - LEG_LEN * 0.9 + HEAD.y * 0.9} t={t - 22} r0={30} color="#FF7A7A" />
      {QUEUE.map((q, i) => (
        <Hero key={i} look={LOOKS[q.look]} pose={{ ...onStep(q.x, q.s), yaw: -0.5, look: -0.7, armL: { a: 12, b: -4 }, armR: { a: 12, b: -4 }, headTilt: Math.sin(t / 9 + i) * 3, expr: q.k > 0.5 ? 'neutral' : 'happy' }} rimId="rimL" shadow={0.4} />
      ))}
      {/* more of the line, out of frame and below: heads in the dark */}
      {Array.from({ length: 10 }).map((_, i) => (
        <circle key={i} cx={1520 + i * 70} cy={920 + (i % 2) * 18} r={44} fill="#140E1A" opacity={0.9} />
      ))}
      <Banister />
      <rect x={-600} y={-600} width={3120} height={2280} fill="#C8202E" opacity={0.34 * red} style={{ mixBlendMode: 'multiply' }} />
      <Glow x={240} y={300} r={500} kind="red" o={0.35 * red} />
    </g>
  );
};
