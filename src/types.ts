export type Role = 'coach' | 'athlete' | 'parent';
export type Screen = 'home' | 'athlete' | 'lesson' | 'settings';
export type SessionStatus = 'draft' | 'published' | 'archived';
export type AssignmentStatus = 'planned' | 'active' | 'athlete_done' | 'coach_verified';

export interface Athlete {
  id: string;
  name: string;
  birthYear: number;
  team: string;
  seasonGoal: string;
  currentGoal: string;
}

export interface LessonSession {
  id: string;
  athleteId: string;
  date: string;
  type: '개인 레슨' | '팀 훈련' | '경기 리뷰';
  topic: string;
  strengths: string[];
  improvement: string;
  assignment: string;
  successCriteria: string;
  nextCheck: string;
  status: SessionStatus;
  assignmentStatus: AssignmentStatus;
  selfRating?: number;
  selfNote?: string;
  updatedAt?: string;
}
