'use client'

import { createClient } from './client'

export type StorageBucket = 'campaign-images' | 'team-avatars' | 'benefit-images'

export interface UploadOptions {
  bucket: StorageBucket
  folder?: string
  file: File
  onProgress?: (progress: number) => void
}

export interface UploadResult {
  url: string
  path: string
  error?: string
}

// File validation constants
const MAX_FILE_SIZE_MB = 5
const MAX_FILE_SIZE_BYTES = MAX_FILE_SIZE_MB * 1024 * 1024
const ALLOWED_MIME_TYPES = [
  'image/jpeg',
  'image/png',
  'image/gif',
  'image/webp',
]
const ALLOWED_EXTENSIONS = ['jpg', 'jpeg', 'png', 'gif', 'webp']

/**
 * Validate file before upload
 */
export function validateFile(file: File): { valid: boolean; error?: string } {
  // Check file size
  if (file.size > MAX_FILE_SIZE_BYTES) {
    return {
      valid: false,
      error: `파일 크기가 ${MAX_FILE_SIZE_MB}MB를 초과합니다. (현재: ${(file.size / 1024 / 1024).toFixed(2)}MB)`,
    }
  }

  // Check MIME type
  if (!ALLOWED_MIME_TYPES.includes(file.type)) {
    return {
      valid: false,
      error: `지원하지 않는 파일 형식입니다. (지원: JPG, PNG, GIF, WebP)`,
    }
  }

  // Check extension
  const extension = file.name.split('.').pop()?.toLowerCase()
  if (!extension || !ALLOWED_EXTENSIONS.includes(extension)) {
    return {
      valid: false,
      error: `지원하지 않는 파일 확장자입니다. (지원: ${ALLOWED_EXTENSIONS.join(', ')})`,
    }
  }

  return { valid: true }
}

/**
 * Generate unique filename with timestamp and random string
 */
export function generateFileName(originalName: string): string {
  const extension = originalName.split('.').pop()?.toLowerCase() || 'jpg'
  const timestamp = Date.now()
  const randomString = Math.random().toString(36).substring(2, 8)
  return `${timestamp}-${randomString}.${extension}`
}

/**
 * Get public URL for a file in storage
 */
export function getPublicUrl(bucket: StorageBucket, path: string): string {
  const supabase = createClient()
  const { data } = supabase.storage.from(bucket).getPublicUrl(path)
  return data.publicUrl
}

/**
 * Upload a file to Supabase Storage
 */
export async function uploadFile(options: UploadOptions): Promise<UploadResult> {
  const { bucket, folder, file, onProgress } = options

  // Validate file
  const validation = validateFile(file)
  if (!validation.valid) {
    return { url: '', path: '', error: validation.error }
  }

  const supabase = createClient()
  const fileName = generateFileName(file.name)
  const filePath = folder ? `${folder}/${fileName}` : fileName

  try {
    // Report initial progress
    onProgress?.(0)

    // Upload file
    const { data, error } = await supabase.storage
      .from(bucket)
      .upload(filePath, file, {
        cacheControl: '3600',
        upsert: false,
      })

    if (error) {
      console.error('Upload error:', error)
      return { url: '', path: '', error: `업로드 실패: ${error.message}` }
    }

    // Report completion
    onProgress?.(100)

    // Get public URL
    const url = getPublicUrl(bucket, data.path)

    return { url, path: data.path }
  } catch (err) {
    console.error('Upload exception:', err)
    return { url: '', path: '', error: '업로드 중 오류가 발생했습니다.' }
  }
}

/**
 * Delete a file from Supabase Storage
 */
export async function deleteFile(bucket: StorageBucket, path: string): Promise<{ success: boolean; error?: string }> {
  const supabase = createClient()

  try {
    const { error } = await supabase.storage.from(bucket).remove([path])

    if (error) {
      console.error('Delete error:', error)
      return { success: false, error: `삭제 실패: ${error.message}` }
    }

    return { success: true }
  } catch (err) {
    console.error('Delete exception:', err)
    return { success: false, error: '삭제 중 오류가 발생했습니다.' }
  }
}

/**
 * Extract path from public URL
 */
export function extractPathFromUrl(url: string, bucket: StorageBucket): string | null {
  try {
    // URL format: https://{project}.supabase.co/storage/v1/object/public/{bucket}/{path}
    const regex = new RegExp(`/storage/v1/object/public/${bucket}/(.+)$`)
    const match = url.match(regex)
    return match ? match[1] : null
  } catch {
    return null
  }
}

/**
 * Check if URL is a Supabase Storage URL
 */
export function isSupabaseStorageUrl(url: string): boolean {
  return url.includes('/storage/v1/object/public/')
}

/**
 * Check if URL is valid (basic validation)
 */
export function isValidImageUrl(url: string): boolean {
  if (!url) return false

  try {
    const urlObj = new URL(url)
    return ['http:', 'https:'].includes(urlObj.protocol)
  } catch {
    return false
  }
}
