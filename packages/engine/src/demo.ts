import type { ContentDoc } from './types';

export const demoContent: ContentDoc = {
  start: "camus_start",
  nodes: [
    { id: "camus_start", title: "The Tower That Isn't There",
      body: "You awaken in a desert. A tower looms at the horizon, always the same distance no matter how far you walk.",
      choices: [
        { text: "Approach the Tower", next: "camus_sandstorm" },
        { text: "Wander aimlessly", next: "camus_oasis" },
        { text: "Sit and observe", next: "camus_observe" }
      ]
    },

    { id: "camus_sandstorm", title: "Sandstorm & Guide",
      body: "A sandstorm erases the path. A figure offers guidance, though their footprints form a circle.",
      choices: [
        { text: "Follow the guide", next: "camus_circles",
          effects: [{ stat: "Absurdism", delta: 1, journal: "Even the guides are lost." }, { set_flag: "met_guide" }] },
        { text: "Refuse the guide", next: "camus_dunes",
          effects: [{ stat: "Stability", delta: 1, journal: "I search because I must." }] },
        { text: "Ignore and push forward", next: "camus_collapse",
          effects: [{ stat: "Faith", delta: 1 }, { stat: "Absurdism", delta: 1, journal: "Others carry me when I collapse." }] }
      ]
    },

    { id: "camus_circles", title: "Circles",
      body: "You walk for hours. The tower never gets closer. The guide smiles as if that were the point.",
      choices: [
        { text: "Confront the guide", next: "end_reflection",
          effects: [{ stat: "Absurdism", delta: 2 }, { stat: "Stability", delta: -1, journal: "Even the guides are lost." }] },
        { text: "Stay silent", next: "end_reflection",
          effects: [{ stat: "Absurdism", delta: 1, journal: "Silence changes nothing." }] }
      ]
    },

    { id: "camus_dunes", title: "Endless Dunes",
      body: "The tower vanishes. The dunes repeat themselves like pages of an unfinished book.",
      choices: [
        { text: "Keep searching", next: "end_reflection",
          effects: [{ stat: "Absurdism", delta: 1 }, { stat: "Stability", delta: 1, journal: "I search because I must." }] },
        { text: "Give up", next: "end_reflection",
          effects: [{ stat: "Absurdism", delta: 3 }, { stat: "Stability", delta: -2, journal: "Meaning can dissolve." }] }
      ]
    },

    { id: "camus_collapse", title: "Collapse",
      body: "You push forward until the world goes white. When you wake, a stranger drips water onto your lips.",
      choices: [
        { text: "Accept help", next: "end_reflection",
          effects: [{ stat: "Faith", delta: 1 }, { stat: "Absurdism", delta: 1, journal: "Others carry me when I collapse." }] }
      ]
    },

    { id: "camus_oasis", title: "Oasis Mirage",
      body: "Palm trees ripple in heat. The tower appears in the water's skin.",
      choices: [
        { text: "Investigate the mirage", next: "camus_mirror" },
        { text: "Rest at the oasis", next: "end_reflection",
          effects: [{ stat: "Faith", delta: 2, journal: "Dreams may be truer than paths." }] }
      ]
    },

    { id: "camus_mirror", title: "Mirror Wall",
      body: "A wall of mirrors shows you walking toward yourself from every direction.",
      choices: [
        { text: "Step through", next: "end_reflection",
          effects: [{ stat: "Absurdism", delta: 2 }, { stat: "Freedom", delta: 1, journal: "Beyond the mirror is only more of me." }] },
        { text: "Turn back", next: "end_reflection",
          effects: [{ stat: "Stability", delta: 1, journal: "Sometimes we turn away from ourselves." }] }
      ]
    },

    { id: "camus_observe", title: "Observation",
      body: "You sit for a long time. The tower creeps closer on its own.",
      choices: [
        { text: "Get up and walk (time loop)", next: "camus_start",
          effects: [{ journal: "The world rearranges when I return." }] },
        { text: "Remain sitting (riddles)", next: "end_reflection",
          effects: [{ stat: "Freedom", delta: 2, journal: "In refusing to answer, I answered." }] }
      ]
    },

    { id: "end_reflection", title: "Reflection",
      body: "There is no final resolution, only what you make of it.",
      choices: [
        { text: "Close your eyes.", next: "the_end", effects: [] }
      ]
    },

    { id: "the_end", title: "Pause",
      body: "This is the end of the demo content. Add more arcs by author in your content file.",
      choices: [], end: true
    }
  ]
};
