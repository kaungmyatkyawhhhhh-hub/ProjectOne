# Atlas myth, story cutscenes and Roblox text to speech (researched 31 Oct 2026)

## Atlas (Greek myth)
- Atlas was a Titan. After the Titans lost the war against the Olympians, Zeus punished him to hold up the SKY (the heavens) forever, at the western edge of the world.
- He did NOT hold the Earth. The famous Farnese Atlas statue (a Roman marble copy, Naples) shows him kneeling with the CELESTIAL globe (the sky with the constellations) on his shoulders; later people read the globe as the Earth.
- Heracles once held the sky for him while Atlas fetched the golden apples.
- GYM ARC's story (owner's idea, our own): a meteor falls toward Earth, Atlas catches it and holds it up "like the statue of Atlas". It's a new legend, not the myth; the caption says "like the statue", which is true.

## Roblox text to speech (AudioTextToSpeech)
- An engine feature (no uploaded audio). Text up to 300 characters; VoiceId (1 British male, 2 British female, 3/5 US male, 4/6 US female, 7/8 Australian, 9/10 retro, 11 host, plus Spanish/German/Italian/French); Speed 0.5-2; Pitch -12..12 semitones; Volume 0-3; AutoLocalize.
- LoadAsync() makes the audio (yields); Play(); wire it (Wire SourceInstance -> AudioDeviceOutput / AudioEmitter).
- Limits: 1 + 6 x concurrent users requests per minute per experience; 4 a second per user.
- GYM ARC: the story narrator (TrainerStories). In Studio the lines didn't load; test live.

Sources: https://talesoftimesforgotten.com/2017/02/09/misunderstood-myths-part-five-atlas/ , https://www.newworldencyclopedia.org/entry/Atlas_(mythology) , https://create.roblox.com/docs/reference/engine/classes/AudioTextToSpeech , https://create.roblox.com/docs/tutorials/use-case-tutorials/audio/add-text-to-speech
