'use client'

import { useState } from 'react'
import { GalleryImage } from '@/lib/types/database'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { ImageUploader } from '@/components/ui/image-uploader'
import { Plus, Trash2, GripVertical, ImageIcon } from 'lucide-react'

interface GalleryEditorProps {
  images: GalleryImage[]
  onChange: (images: GalleryImage[]) => void
}

export function GalleryEditor({ images, onChange }: GalleryEditorProps) {
  const [draggedIndex, setDraggedIndex] = useState<number | null>(null)

  const addImage = () => {
    const newImage: GalleryImage = {
      url: '',
      caption: '',
      display_order: images.length
    }
    onChange([...images, newImage])
  }

  const updateImage = (index: number, field: keyof GalleryImage, value: string | number) => {
    const updated = [...images]
    updated[index] = { ...updated[index], [field]: value }
    onChange(updated)
  }

  const removeImage = (index: number) => {
    const updated = images.filter((_, i) => i !== index)
    // Re-order remaining images
    updated.forEach((img, i) => {
      img.display_order = i
    })
    onChange(updated)
  }

  const handleDragStart = (index: number) => {
    setDraggedIndex(index)
  }

  const handleDragOver = (e: React.DragEvent, index: number) => {
    e.preventDefault()
    if (draggedIndex === null || draggedIndex === index) return

    const updated = [...images]
    const [removed] = updated.splice(draggedIndex, 1)
    updated.splice(index, 0, removed)

    // Update display_order
    updated.forEach((img, i) => {
      img.display_order = i
    })

    onChange(updated)
    setDraggedIndex(index)
  }

  const handleDragEnd = () => {
    setDraggedIndex(null)
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <Label className="text-base font-semibold">갤러리 이미지</Label>
        <Button type="button" variant="outline" size="sm" onClick={addImage}>
          <Plus className="h-4 w-4 mr-1" />
          이미지 추가
        </Button>
      </div>

      {images.length === 0 ? (
        <div className="border-2 border-dashed border-gray-200 rounded-lg p-8 text-center">
          <ImageIcon className="h-12 w-12 mx-auto text-gray-300 mb-3" />
          <p className="text-gray-500 text-sm">
            갤러리에 표시할 이미지를 추가하세요
          </p>
          <p className="text-gray-400 text-xs mt-1">
            드래그하여 순서를 변경할 수 있습니다
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          {images.map((image, index) => (
            <div
              key={index}
              draggable
              onDragStart={() => handleDragStart(index)}
              onDragOver={(e) => handleDragOver(e, index)}
              onDragEnd={handleDragEnd}
              className={`flex gap-3 p-3 border rounded-lg bg-white transition-all ${
                draggedIndex === index ? 'opacity-50 border-pink-300' : 'border-gray-200'
              }`}
            >
              {/* Drag Handle */}
              <div className="flex items-center cursor-grab active:cursor-grabbing">
                <GripVertical className="h-5 w-5 text-gray-400" />
              </div>

              {/* Image Uploader */}
              <div className="w-32 flex-shrink-0">
                <ImageUploader
                  bucket="campaign-images"
                  folder="gallery"
                  value={image.url}
                  onChange={(url) => updateImage(index, 'url', url)}
                  aspectRatio={1}
                  placeholder="이미지 업로드"
                  showUrlInput={false}
                />
              </div>

              {/* Caption Field */}
              <div className="flex-1 self-center">
                <Input
                  placeholder="캡션 (선택사항)"
                  value={image.caption || ''}
                  onChange={(e) => updateImage(index, 'caption', e.target.value)}
                  className="text-sm"
                />
              </div>

              {/* Delete Button */}
              <Button
                type="button"
                variant="ghost"
                size="sm"
                className="text-gray-400 hover:text-red-500 self-start"
                onClick={() => removeImage(index)}
              >
                <Trash2 className="h-4 w-4" />
              </Button>
            </div>
          ))}
        </div>
      )}

      <p className="text-xs text-gray-500">
        💡 팁: 첫 번째 이미지가 메인 갤러리 이미지로 표시됩니다
      </p>
    </div>
  )
}
