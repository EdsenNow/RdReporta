export const API_BASE_URL = (import.meta.env.VITE_API_BASE_URL || 'http://localhost:5000/api').replace(/\/$/, '');
export type PostStatus = 'Active' | 'Resolved' | 'Hidden' | 'Archived';
export interface PostItem {
  id: string; userId: string; authorUsername: string; categoryId: number;
  categoryName: string; categoryColor: string; title: string; description: string;
  latitude: number; longitude: number; province: string; municipality: string;
  status: PostStatus; viewsCount: number; reactionsCount: number;
  confirmationsCount: number; images: string[]; createdAt: string;
}
export interface ModerationReportItem {
  id: string; postId: string; postTitle: string; reporterUsername: string;
  reason: string; description?: string; status: string; createdAt: string;
}
export interface CategoryItem {
  id: number; name: string; slug: string; description?: string;
  iconName: string; colorHex: string; displayOrder: number;
}
export interface Stats {
  totalPosts: number; activePosts: number; resolvedPosts: number;
  totalConfirmations: number; totalReactions: number; pendingReports: number;
}
export interface UserItem {
  id: string; displayName: string; username: string; email: string;
  avatarUrl?: string; isVerified: boolean; isActive: boolean; createdAt: string;
}
export interface Page<T> { items: T[]; totalCount: number; pageNumber: number; pageSize: number }
export interface Session { username: string; email: string; roles: string[]; accessToken: string; refreshToken: string }
const storageKey = 'rdreporta.admin.session';
export function getSession(): Session | null {
  try { return JSON.parse(sessionStorage.getItem(storageKey) || 'null'); } catch { return null; }
}
function saveSession(session: Session) { sessionStorage.setItem(storageKey, JSON.stringify(session)); }
export function clearSession() {
  sessionStorage.removeItem(storageKey);
  window.dispatchEvent(new Event('session-ended'));
}
let refreshing: Promise<void> | null = null;
class ApiError extends Error {
  status: number;
  constructor(message: string, status: number) { super(message); this.status = status; }
}
async function request<T>(path: string, init: RequestInit = {}, retry = true): Promise<T> {
  const session = getSession();
  const headers = new Headers(init.headers);
  headers.set('Content-Type', 'application/json');
  if (session) headers.set('Authorization', `Bearer ${session.accessToken}`);
  const response = await fetch(`${API_BASE_URL}${path}`, { ...init, headers });
  if (response.status === 401 && retry && session && !path.startsWith('/auth/')) {
    if (getSession()?.accessToken !== session.accessToken) return request<T>(path, init, false);
    if (!refreshing) refreshing = request<Session>('/auth/refresh', {
      method: 'POST', body: JSON.stringify({ accessToken: session.accessToken, refreshToken: session.refreshToken }),
    }, false).then(saveSession).finally(() => { refreshing = null; });
    try { await refreshing; } catch (error) {
      if (error instanceof ApiError && [400, 401].includes(error.status)) clearSession();
      throw error;
    }
    return request<T>(path, init, false);
  }
  const body = await response.json().catch(() => null);
  if (!response.ok || body?.success === false) {
    if (response.status === 401 && !path.startsWith('/auth/')) clearSession();
    const validation = body?.errors ? Object.values(body.errors).flat().join(' ') : '';
    throw new ApiError(body?.message || validation || (response.status === 403 ? 'No tienes permisos para esta acción.' : `No se pudo completar la solicitud (${response.status}).`), response.status);
  }
  return body.data as T;
}
export const api = {
  async login(email: string, password: string) {
    const session = await request<Session>('/auth/login', { method: 'POST', body: JSON.stringify({ email, password }) });
    if (!session.roles.some(r => ['Administrador', 'Moderador'].includes(r))) throw new Error('Esta cuenta no tiene acceso al panel.');
    saveSession(session);
    return session;
  },
  async logout() { try { await request('/auth/logout', { method: 'POST' }); } finally { clearSession(); } },
  getStats: () => request<Stats>('/management/stats'),
  getPosts: (params: URLSearchParams) => request<Page<PostItem>>(`/management/posts?${params}`),
  getPost: (id: string) => request<PostItem>(`/management/posts/${id}`),
  getUsers: (params: URLSearchParams) => request<Page<UserItem>>(`/management/users?${params}`),
  setUserVerification: (id: string, isVerified: boolean) => request(`/management/users/${id}/verification`, {
    method: 'PATCH', body: JSON.stringify({ isVerified }),
  }),
  getCategories: () => request<CategoryItem[]>('/categories'),
  getModerationReports: (page = 1) => request<Page<ModerationReportItem>>(`/moderation/reports?page=${page}&pageSize=20`),
  setStatus: (id: string, status: PostStatus) => request(`/management/posts/${id}/status`, { method: 'PATCH', body: JSON.stringify({ status }) }),
  resolve: (id: string, hidePost: boolean, resolutionNotes: string) => request(`/moderation/reports/${id}/resolve`, {
    method: 'POST', body: JSON.stringify({ status: hidePost ? 'ActionTaken' : 'Dismissed', hidePost, resolutionNotes }),
  }),
  saveCategory: (category: Omit<CategoryItem, 'id'>, id?: number) => request(id ? `/management/categories/${id}` : '/categories', {
    method: id ? 'PUT' : 'POST', body: JSON.stringify(category),
  }),
};
export function imageUrl(url: string) { return new URL(url, `${API_BASE_URL.replace(/\/api$/, '')}/`).href; }
