export const API_BASE_URL = 'http://localhost:5000/api';

export interface PostItem {
  id: string;
  userId: string;
  authorUsername: string;
  authorReputation: string;
  categoryId: number;
  categoryName: string;
  categoryColor: string;
  title: string;
  description: string;
  latitude: number;
  longitude: number;
  province: string;
  municipality: string;
  status: 'Active' | 'Resolved' | 'Hidden' | 'Archived';
  viewsCount: number;
  reactionsCount: number;
  confirmationsCount: number;
  images: string[];
  createdAt: string;
}

export interface ModerationReportItem {
  id: string;
  postId: string;
  postTitle: string;
  reporterUsername: string;
  reason: string;
  description: string;
  status: 'Pending' | 'Reviewed' | 'Dismissed' | 'ActionTaken';
  createdAt: string;
}

export interface CategoryItem {
  id: number;
  name: string;
  slug: string;
  description: string;
  iconName: string;
  colorHex: string;
  displayOrder: number;
}

export const api = {
  async getRecentPosts(): Promise<PostItem[]> {
    try {
      const res = await fetch(`${API_BASE_URL}/posts/recent?page=1&pageSize=30`);
      const data = await res.json();
      return data.data?.items || [];
    } catch {
      return [];
    }
  },

  async getCategories(): Promise<CategoryItem[]> {
    try {
      const res = await fetch(`${API_BASE_URL}/categories`);
      const data = await res.json();
      return data.data || [];
    } catch {
      return [];
    }
  },

  async getModerationReports(token?: string): Promise<ModerationReportItem[]> {
    try {
      const res = await fetch(`${API_BASE_URL}/moderation/reports`, {
        headers: token ? { Authorization: `Bearer ${token}` } : {}
      });
      const data = await res.json();
      return data.data?.items || [];
    } catch {
      return [];
    }
  }
};
