'use client'

import * as React from 'react'
import { useState } from 'react'
import { X, Image as ImageIcon } from 'lucide-react'
import { Button } from './button'
import { ImageUploader } from './image-uploader'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from './dialog'

interface ImageUploadModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onInsert: (url: string, alt?: string) => void
  folder?: string
}

export function ImageUploadModal({
  open,
  onOpenChange,
  onInsert,
  folder = 'content',
}: ImageUploadModalProps) {
  const [imageUrl, setImageUrl] = useState('')
  const [altText, setAltText] = useState('')

  const handleInsert = () => {
    if (imageUrl) {
      onInsert(imageUrl, altText || undefined)
      handleClose()
    }
  }

  const handleClose = () => {
    setImageUrl('')
    setAltText('')
    onOpenChange(false)
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <ImageIcon className="h-5 w-5" />
            이미지 삽입
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-4">
          {/* Image Uploader */}
          <ImageUploader
            bucket="campaign-images"
            folder={folder}
            value={imageUrl}
            onChange={setImageUrl}
            placeholder="이미지를 드래그하거나 클릭하여 업로드"
            showUrlInput={true}
          />

          {/* Alt Text Input */}
          {imageUrl && (
            <div className="space-y-2">
              <label className="text-sm font-medium text-gray-700">
                대체 텍스트 (선택사항)
              </label>
              <input
                type="text"
                value={altText}
                onChange={(e) => setAltText(e.target.value)}
                placeholder="이미지 설명을 입력하세요"
                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
              />
              <p className="text-xs text-gray-500">
                화면 읽기 프로그램 사용자를 위한 이미지 설명입니다.
              </p>
            </div>
          )}

          {/* Actions */}
          <div className="flex justify-end gap-2 pt-2">
            <Button
              type="button"
              variant="outline"
              onClick={handleClose}
            >
              취소
            </Button>
            <Button
              type="button"
              onClick={handleInsert}
              disabled={!imageUrl}
            >
              삽입
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}

export default ImageUploadModal
