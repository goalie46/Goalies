import { Athlete, LessonSession } from '../types';

export const athletes: Athlete[] = [
  { id: 'a1', name: '데모 골리 A', birthYear: 2012, team: 'North Stars U14', seasonGoal: '경기 흐름을 읽고 안정적인 세이브 선택하기', currentGoal: 'Rush 상황에서 적절한 depth 유지' },
  { id: 'a2', name: '데모 골리 B', birthYear: 2014, team: 'Ice Bears U12', seasonGoal: '기본 자세와 좌우 이동 안정화', currentGoal: 'Shuffle 중 stance 유지' },
  { id: 'a3', name: '데모 골리 C', birthYear: 2011, team: 'Blizzards U16', seasonGoal: '리바운드 이후 빠른 recovery', currentGoal: 'Rebound control 방향 만들기' },
];

export const sessions: LessonSession[] = [
  { id: 's1', athleteId: 'a1', date: '2026.09.12', type: '개인 레슨', topic: 'Rush depth / Tracking', strengths: ['공격수가 슛 가능한 위치에 들어오기 전까지 발을 유지했어요.'], improvement: '패스 옵션이 남아 있을 때 depth를 너무 일찍 높였어요.', assignment: '측면 진입에서 슛과 패스 옵션을 함께 확인하며 이동 시점을 조절해요.', successCriteria: '지정 훈련 5회 중 4회 이상 정한 이동 시점 지키기', nextCheck: '다음 경기 측면 진입 장면의 depth와 이동 시점', status: 'published', assignmentStatus: 'athlete_done', selfRating: 3, selfNote: '패스 옵션을 늦게 확인했다.', updatedAt: '2026.09.12 20:14' },
  { id: 's2', athleteId: 'a1', date: '2026.09.05', type: '팀 훈련', topic: 'Rebound control', strengths: ['스틱으로 낮은 슛의 방향을 잘 만들었어요.'], improvement: '세이브 후 puck tracking을 끝까지 유지해요.', assignment: '세이브 뒤 고개를 먼저 돌려 puck 찾기', successCriteria: '연속 6회 중 5회 puck을 먼저 찾기', nextCheck: 'Butterfly recovery drill', status: 'published', assignmentStatus: 'coach_verified' },
  { id: 's3', athleteId: 'a2', date: '2026.09.10', type: '개인 레슨', topic: 'Stance / Shuffle', strengths: ['손 위치가 몸 앞에서 안정적이었어요.'], improvement: '이동할 때 상체가 먼저 들리지 않도록 해요.', assignment: '낮은 자세로 3-cone shuffle', successCriteria: '3세트 동안 stance 높이 유지', nextCheck: '다음 레슨 워밍업', status: 'draft', assignmentStatus: 'planned' },
];

export const tags = ['Stance', 'Balance', 'Shuffle', 'T-push', 'C-cut', 'Power push', 'Rush depth', 'Angle', 'Square', 'Post depth', 'Butterfly', 'Block', 'React', 'RVH', 'Release read', 'Tracking', 'Screen', 'Deflection', 'Rebound control', 'Recovery'];
