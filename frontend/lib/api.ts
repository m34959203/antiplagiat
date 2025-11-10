/**
 * API Client для работы с Backend
 */

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'https://antiplagiat-api.onrender.com'

export interface CheckRequest {
  text: string
  mode?: 'fast' | 'deep'
  lang?: 'ru' | 'en' | 'kk'
  exclude_quotes?: boolean
  exclude_bibliography?: boolean
}

export interface Match {
  start: number
  end: number
  text: string
  source_id: number
  similarity: number
  type: 'lexical' | 'semantic'
}

export interface CheckResult {
  task_id: string
  status: string
  originality?: number
  total_words?: number
  total_chars?: number
  matches?: Match[]
  sources?: any[]
  created_at?: string
}

export class ApiClient {
  private baseUrl: string

  constructor(baseUrl: string = API_URL) {
    this.baseUrl = baseUrl
  }

  async createCheck(request: CheckRequest): Promise<{ task_id: string }> {
    const response = await fetch(`${this.baseUrl}/api/v1/check`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(request),
    })

    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.detail || 'Failed to create check')
    }

    return response.json()
  }

  async getCheckResult(taskId: string): Promise<CheckResult> {
    const response = await fetch(`${this.baseUrl}/api/v1/check/${taskId}`)

    if (!response.ok) {
      throw new Error('Failed to fetch result')
    }

    return response.json()
  }

  async getSources() {
    const response = await fetch(`${this.baseUrl}/api/v1/sources`)
    return response.json()
  }

  async healthCheck() {
    const response = await fetch(`${this.baseUrl}/health`)
    return response.json()
  }
}

export const apiClient = new ApiClient()