export const STATS = [
  'Absurdism',
  'Freedom',
  'Faith',
  'Stability',
  'SelfAffirmation',
] as const;

export type StatKey = (typeof STATS)[number];

export interface Condition {
  stat?: StatKey;
  op?: '>' | '>=' | '<' | '<=' | '==' | '!=';
  value?: number;
  flag_set?: string;
  flag_unset?: string;
}

export interface Effect {
  stat?: StatKey;
  delta?: number;
  set_flag?: string;
  clear_flag?: string;
  journal?: string;
}

export interface Choice {
  text: string;
  next: string;
  conditions?: Condition[];
  effects?: Effect[];
}

export interface NodeDef {
  id: string;
  title?: string;
  body?: string;
  choices?: Choice[];
  end?: boolean;
}

export interface ContentDoc {
  start: string;
  nodes: NodeDef[];
}

export interface GameStateSnapshot {
  current: string;
  stats: Record<StatKey, number>;
  flags: Record<string, boolean>;
  visited: string[];
  journal: string[];
}
