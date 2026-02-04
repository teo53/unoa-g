'use client'

import * as React from 'react'
import { useState, useRef, useCallback } from 'react'
import { Upload, X, Image as ImageIcon, Link, Loader2 } from 'lucide-react'
import { Button } from './button'
import { Input } from './input'
import { cn } from '@/lib/utils'
import {
  uploadFile,
  deleteFile,
  extractPathFromUrl,
  isSupabaseStorageUrl,
  isValidImageUrl,
  type StorageBucket,
} from '@/lib/supabase/storage'

export interface ImageUploaderProps {
  bucket: StorageBucket
  folder?: string
  value?: string
  onChange: (url: string) => void
  onRemove?: () => void
  accept?: string
  maxSizeMB?: number
  aspectRatio?: number
  className?: string
  placeholder?: string
  showUrlInput?: boolean
  disabled?: boolean
}

export function ImageUploader({
  bucket,
  folder,
  value,
  onChange,
  onRemove,
  accept = 'image/jpeg,image/png,image/gif,image/webp',
  maxSizeMB = 5,
  aspectRatio,
  className,
  placeholder = '이미지를 드래그하거나 클릭하여 업로드',
  showUrlInput = true,
  disabled = false,
}: ImageUploaderProps) {
  const [isDragging, setIsDragging] = useState(false)
  const [isUploading, setIsUploading] = useState(false)
  const [uploadProgress, setUploadProgress] = useState(0)
  const [error, setError] = useState<string | null>(null)
  const [showUrlMode, setShowUrlMode] = useState(false)
  const [urlInput, setUrlInput] = useState('')

  const inputRef = useRef<HTMLInputElement>(null)

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    e.stopPropagation()
    if (!disabled) {
      setIsDragging(true)
    }
  }, [disabled])

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    e.stopPropagation()
    setIsDragging(false)
  }, [])

  const handleDrop = useCallback(async (e: React.DragEvent) => {
    e.preventDefault()
    e.stopPropagation()
    setIsDragging(false)

    if (disabled) return

    const files = e.dataTransfer.files
    if (files.length > 0) {
      await handleFileUpload(files[0])
    }
  }, [disabled, bucket, folder])

  const handleFileSelect = useCallback(async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files
    if (files && files.length > 0) {
      await handleFileUpload(files[0])
    }
    // Reset input
    if (inputRef.current) {
      inputRef.current.value = ''
    }
  }, [bucket, folder])

  const handleFileUpload = async (file: File) => {
    setError(null)
    setIsUploading(true)
    setUploadProgress(0)

    try {
      const result = await uploadFile({
        bucket,
        folder,
        file,
        onProgress: setUploadProgress,
      })

      if (result.error) {
        setError(result.error)
      } else {
        onChange(result.url)
      }
    } catch (err) {
      setError('업로드 중 오류가 발생했습니다.')
      console.error('Upload error:', err)
    } finally {
      setIsUploading(false)
      setUploadProgress(0)
    }
  }

  const handleRemove = useCallback(async () => {
    if (!value) return

    // If it's a Supabase Storage URL, delete the file
    if (isSupabaseStorageUrl(value)) {
      const path = extractPathFromUrl(value, bucket)
      if (path) {
        await deleteFile(bucket, path)
      }
    }

    onChange('')
    onRemove?.()
  }, [value, bucket, onChange, onRemove])

  const handleUrlSubmit = useCallback(() => {
    if (!urlInput.trim()) return

    if (!isValidImageUrl(urlInput)) {
      setError('올바른 이미지 URL을 입력해주세요.')
      return
    }

    setError(null)
    onChange(urlInput)
    setUrlInput('')
    setShowUrlMode(false)
  }, [urlInput, onChange])

  const handleClick = () => {
    if (!disabled && !isUploading) {
      inputRef.current?.click()
    }
  }

  // Calculate aspect ratio style
  const aspectRatioStyle = aspectRatio
    ? { aspectRatio: `${aspectRatio}` }
    : {}

  // Has image
  const hasImage = !!value

  return (
    <div className={cn('space-y-2', className)}>
      {/* Upload Area */}
      <div
        className={cn(
          'relative border-2 border-dashed rounded-lg transition-colors cursor-pointer overflow-hidden',
          isDragging && 'border-primary bg-primary/5',
          !isDragging && !hasImage && 'border-gray-300 hover:border-gray-400',
          hasImage && 'border-transparent',
          disabled && 'opacity-50 cursor-not-allowed',
          isUploading && 'cursor-wait'
        )}
        style={aspectRatioStyle}
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
        onDrop={handleDrop}
        onClick={handleClick}
      >
        {/* Hidden File Input */}
        <input
          ref={inputRef}
          type="file"
          accept={accept}
          onChange={handleFileSelect}
          className="hidden"
          disabled={disabled || isUploading}
        />

        {/* Content */}
        {hasImage ? (
          /* Image Preview */
          <div className="relative w-full h-full min-h-[120px]">
            <img
              src={value}
              alt="Uploaded"
              className="w-full h-full object-cover"
              onError={() => setError('이미지를 불러올 수 없습니다.')}
            />
            {/* Remove Button */}
            {!disabled && (
              <button
                type="button"
                onClick={(e) => {
                  e.stopPropagation()
                  handleRemove()
                }}
                className="absolute top-2 right-2 p-1.5 bg-black/50 hover:bg-black/70 rounded-full text-white transition-colors"
              >
                <X className="h-4 w-4" />
              </button>
            )}
          </div>
        ) : isUploading ? (
          /* Uploading State */
          <div className="flex flex-col items-center justify-center p-8 min-h-[120px]">
            <Loader2 className="h-8 w-8 text-primary animate-spin mb-2" />
            <p className="text-sm text-gray-500">업로드 중... {uploadProgress}%</p>
            <div className="w-full max-w-xs mt-2 h-2 bg-gray-200 rounded-full overflow-hidden">
              <div
                className="h-full bg-primary transition-all duration-300"
                style={{ width: `${uploadProgress}%` }}
              />
            </div>
          </div>
        ) : (
          /* Empty State */
          <div className="flex flex-col items-center justify-center p-8 min-h-[120px]">
            <div className={cn(
              'p-3 rounded-full mb-3',
              isDragging ? 'bg-primary/10' : 'bg-gray-100'
            )}>
              <Upload className={cn(
                'h-6 w-6',
                isDragging ? 'text-primary' : 'text-gray-400'
              )} />
            </div>
            <p className="text-sm text-gray-500 text-center">{placeholder}</p>
            <p className="text-xs text-gray-400 mt-1">
              JPG, PNG, GIF, WebP (최대 {maxSizeMB}MB)
            </p>
          </div>
        )}
      </div>

      {/* Error Message */}
      {error && (
        <p className="text-sm text-red-500 flex items-center gap-1">
          <X className="h-4 w-4" />
          {error}
        </p>
      )}

      {/* URL Input Toggle */}
      {showUrlInput && !hasImage && !isUploading && (
        <div className="space-y-2">
          {showUrlMode ? (
            <div className="flex gap-2">
              <Input
                placeholder="https://example.com/image.jpg"
                value={urlInput}
                onChange={(e) => setUrlInput(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleUrlSubmit()}
                disabled={disabled}
                className="flex-1"
              />
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={handleUrlSubmit}
                disabled={disabled || !urlInput.trim()}
              >
                <Link className="h-4 w-4" />
              </Button>
              <Button
                type="button"
                variant="ghost"
                size="sm"
                onClick={() => {
                  setShowUrlMode(false)
                  setUrlInput('')
                  setError(null)
                }}
              >
                <X className="h-4 w-4" />
              </Button>
            </div>
          ) : (
            <button
              type="button"
              onClick={() => setShowUrlMode(true)}
              className="text-xs text-gray-500 hover:text-gray-700 flex items-center gap-1"
              disabled={disabled}
            >
              <Link className="h-3 w-3" />
              URL로 직접 입력
            </button>
          )}
        </div>
      )}
    </div>
  )
}

export default ImageUploader
