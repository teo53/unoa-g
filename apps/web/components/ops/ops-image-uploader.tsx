'use client'

import { useCallback, useRef, useState } from 'react'
import { Upload, X, Image as ImageIcon, RotateCcw, CheckCircle } from 'lucide-react'
import { createBrowserClient } from '@supabase/ssr'
import { DEMO_MODE } from '@/lib/mock/demo-data'
import { completeAssetUpload } from '@/lib/ops/ops-client'
import type { OpsAsset } from '@/lib/ops/ops-types'

interface OpsImageUploaderProps {
  onUploadComplete: (asset: OpsAsset) => void
  accept?: string
  maxSizeMb?: number
  tags?: string[]
}

type UploadStage = 'idle' | 'validating' | 'uploading' | 'registering' | 'done' | 'error'

const STAGE_LABELS: Record<UploadStage, string> = {
  idle: '',
  validating: '파일 검증 중...',
  uploading: '업로드 중...',
  registering: '등록 중...',
  done: '완료',
  error: '실패',
}

const STAGE_PROGRESS: Record<UploadStage, number> = {
  idle: 0,
  validating: 10,
  uploading: 50,
  registering: 85,
  done: 100,
  error: 0,
}

function formatFileSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}

export function OpsImageUploader({
  onUploadComplete,
  accept = 'image/*',
  maxSizeMb = 5,
  tags = [],
}: OpsImageUploaderProps) {
  const fileInputRef = useRef<HTMLInputElement>(null)
  const [dragActive, setDragActive] = useState(false)
  const [stage, setStage] = useState<UploadStage>('idle')
  const [preview, setPreview] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [currentFile, setCurrentFile] = useState<File | null>(null)
  const abortRef = useRef<AbortController | null>(null)

  const uploading = stage !== 'idle' && stage !== 'done' && stage !== 'error'
  const progress = STAGE_PROGRESS[stage]

  const resetState = useCallback(() => {
    setStage('idle')
    setPreview(null)
    setError(null)
    setCurrentFile(null)
    if (abortRef.current) {
      abortRef.current.abort()
      abortRef.current = null
    }
    if (fileInputRef.current) {
      fileInputRef.current.value = ''
    }
  }, [])

  const handleFile = useCallback(
    async (file: File) => {
      setError(null)
      setCurrentFile(file)
      setStage('validating')

      // Validate size
      if (file.size > maxSizeMb * 1024 * 1024) {
        setError(`파일 크기는 ${maxSizeMb}MB 이하여야 합니다.`)
        setStage('error')
        return
      }

      // Validate type
      if (!file.type.startsWith('image/')) {
        setError('이미지 파일만 업로드 가능합니다.')
        setStage('error')
        return
      }

      // Preview
      const objectUrl = URL.createObjectURL(file)
      setPreview(objectUrl)

      if (DEMO_MODE) {
        setStage('done')
        const mockAsset: OpsAsset = {
          id: `demo-asset-${Date.now()}`,
          file_name: file.name,
          storage_path: `ops/${file.name}`,
          public_url: objectUrl,
          mime_type: file.type,
          file_size: file.size,
          width: null,
          height: null,
          tags,
          alt_text: '',
          uploaded_by: 'demo-ops-1',
          created_at: new Date().toISOString(),
        }
        onUploadComplete(mockAsset)
        setTimeout(resetState, 1500)
        return
      }

      abortRef.current = new AbortController()

      try {
        setStage('uploading')

        const supabase = createBrowserClient(
          process.env.NEXT_PUBLIC_SUPABASE_URL || '',
          process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''
        )

        // Upload to storage
        const ext = file.name.split('.').pop() || 'png'
        const storagePath = `banners/${Date.now()}-${Math.random().toString(36).slice(2)}.${ext}`

        const { error: uploadError } = await supabase.storage
          .from('ops-assets')
          .upload(storagePath, file, {
            contentType: file.type,
            cacheControl: '3600',
          })

        if (uploadError) throw uploadError

        const { data: urlData } = supabase.storage
          .from('ops-assets')
          .getPublicUrl(storagePath)

        // Get image dimensions
        const img = new Image()
        img.src = objectUrl
        await new Promise((resolve) => (img.onload = resolve))

        setStage('registering')

        // Register asset in DB
        const asset = await completeAssetUpload({
          file_name: file.name,
          storage_path: storagePath,
          public_url: urlData.publicUrl,
          mime_type: file.type,
          file_size: file.size,
          width: img.naturalWidth,
          height: img.naturalHeight,
          tags,
          alt_text: '',
        })

        setStage('done')
        onUploadComplete(asset)
        setTimeout(resetState, 1500)
      } catch (err) {
        if (abortRef.current?.signal.aborted) return
        setError(err instanceof Error ? err.message : '업로드 실패')
        setStage('error')
      }
    },
    [maxSizeMb, tags, onUploadComplete, resetState]
  )

  const handleRetry = useCallback(() => {
    if (currentFile) {
      handleFile(currentFile)
    }
  }, [currentFile, handleFile])

  const handleCancel = useCallback(() => {
    if (abortRef.current) {
      abortRef.current.abort()
    }
    resetState()
  }, [resetState])

  const handleDrag = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    e.stopPropagation()
    if (e.type === 'dragenter' || e.type === 'dragover') {
      setDragActive(true)
    } else if (e.type === 'dragleave') {
      setDragActive(false)
    }
  }, [])

  const handleDrop = useCallback(
    (e: React.DragEvent) => {
      e.preventDefault()
      e.stopPropagation()
      setDragActive(false)

      if (e.dataTransfer.files?.[0]) {
        handleFile(e.dataTransfer.files[0])
      }
    },
    [handleFile]
  )

  const handleInputChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      if (e.target.files?.[0]) {
        handleFile(e.target.files[0])
      }
    },
    [handleFile]
  )

  return (
    <div className="space-y-2">
      {/* Drop Zone */}
      <div
        className={`relative border-2 border-dashed rounded-lg p-6 text-center transition-colors
          ${dragActive ? 'border-blue-500 bg-blue-50' : 'border-gray-300 hover:border-gray-400'}
          ${uploading ? 'pointer-events-none' : 'cursor-pointer'}
        `}
        onDragEnter={handleDrag}
        onDragLeave={handleDrag}
        onDragOver={handleDrag}
        onDrop={handleDrop}
        onClick={() => !uploading && !preview && fileInputRef.current?.click()}
      >
        <input
          ref={fileInputRef}
          type="file"
          accept={accept}
          className="hidden"
          onChange={handleInputChange}
        />

        {preview ? (
          <div className="relative">
            <img
              src={preview}
              alt="Preview"
              className="max-h-48 mx-auto rounded object-contain"
            />
            {stage === 'idle' && (
              <button
                className="absolute top-1 right-1 bg-white rounded-full p-1 shadow hover:bg-gray-100"
                onClick={(e) => {
                  e.stopPropagation()
                  resetState()
                }}
              >
                <X className="w-4 h-4" />
              </button>
            )}
          </div>
        ) : (
          <div className="flex flex-col items-center gap-2">
            <Upload className="w-8 h-8 text-gray-400" />
            <p className="text-sm text-gray-600">
              이미지를 드래그하거나 클릭하여 업로드
            </p>
            <p className="text-xs text-gray-400">
              최대 {maxSizeMb}MB / PNG, JPG, WebP
            </p>
          </div>
        )}

        {/* Progress bar overlay (inside drop zone) */}
        {(uploading || stage === 'done') && (
          <div className="mt-4 space-y-2">
            {/* File info */}
            {currentFile && (
              <div className="flex items-center justify-center gap-2 text-xs text-gray-500">
                <span className="truncate max-w-[200px]">{currentFile.name}</span>
                <span>{formatFileSize(currentFile.size)}</span>
              </div>
            )}

            {/* Progress bar */}
            <div className="h-2 bg-gray-200 rounded-full overflow-hidden mx-auto max-w-xs">
              <div
                className={`h-full rounded-full transition-all duration-500 ease-out ${
                  stage === 'done' ? 'bg-green-500' : 'bg-blue-500'
                }`}
                style={{ width: `${progress}%` }}
              />
            </div>

            {/* Stage label */}
            <div className="flex items-center justify-center gap-2">
              {stage === 'done' ? (
                <CheckCircle className="w-4 h-4 text-green-500" />
              ) : (
                <span className="w-3.5 h-3.5 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
              )}
              <span className="text-xs text-gray-600">{STAGE_LABELS[stage]}</span>
            </div>

            {/* Cancel button */}
            {uploading && (
              <button
                className="text-xs text-gray-500 hover:text-gray-700 underline pointer-events-auto"
                onClick={(e) => { e.stopPropagation(); handleCancel() }}
              >
                취소
              </button>
            )}
          </div>
        )}
      </div>

      {/* Error + Retry */}
      {stage === 'error' && (
        <div className="flex items-center gap-3 text-sm">
          <span className="text-red-600 flex-1">{error}</span>
          {currentFile && (
            <button
              className="inline-flex items-center gap-1 text-blue-600 hover:text-blue-800 text-xs font-medium"
              onClick={handleRetry}
            >
              <RotateCcw className="w-3.5 h-3.5" />
              다시 시도
            </button>
          )}
          <button
            className="text-xs text-gray-500 hover:text-gray-700"
            onClick={resetState}
          >
            닫기
          </button>
        </div>
      )}
    </div>
  )
}

/** Simple image selector from existing assets */
export function OpsAssetPicker({
  currentUrl,
  onSelect,
}: {
  currentUrl?: string
  onSelect: (url: string) => void
}) {
  if (currentUrl) {
    return (
      <div className="relative inline-block">
        <img
          src={currentUrl}
          alt="Selected"
          className="w-full max-h-48 object-contain rounded border"
        />
        <button
          className="absolute top-1 right-1 bg-white rounded-full p-1 shadow hover:bg-gray-100"
          onClick={() => onSelect('')}
        >
          <X className="w-4 h-4" />
        </button>
      </div>
    )
  }

  return (
    <div className="flex items-center gap-2 p-4 border border-dashed rounded-lg text-gray-400">
      <ImageIcon className="w-5 h-5" />
      <span className="text-sm">이미지를 선택하세요</span>
    </div>
  )
}
