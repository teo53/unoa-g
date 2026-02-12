'use client'

import { useState } from 'react'
import Image from 'next/image'
import { GalleryImage } from '@/lib/types/database'
import { Dialog, DialogContent } from '@/components/ui/dialog'
import { ChevronLeft, ChevronRight, X } from 'lucide-react'
import { Button } from '@/components/ui/button'

interface CampaignGalleryProps {
  galleryImages?: GalleryImage[] | null
  coverImage?: string | null
  title?: string
}

export function CampaignGallery({ galleryImages, coverImage, title }: CampaignGalleryProps) {
  const [selectedIndex, setSelectedIndex] = useState(0)
  const [isLightboxOpen, setIsLightboxOpen] = useState(false)

  // Ensure images is always an array
  const images = galleryImages || []

  // Combine cover image with gallery images if cover exists and not already in gallery
  const allImages: GalleryImage[] = [
    ...(coverImage && !images.some(img => img.url === coverImage)
      ? [{ url: coverImage, caption: title || '메인 이미지', display_order: -1 }]
      : []),
    ...images.sort((a, b) => a.display_order - b.display_order),
  ]

  if (allImages.length === 0) return null

  const currentImage = allImages[selectedIndex]

  const handlePrev = () => {
    setSelectedIndex((prev) => (prev > 0 ? prev - 1 : allImages.length - 1))
  }

  const handleNext = () => {
    setSelectedIndex((prev) => (prev < allImages.length - 1 ? prev + 1 : 0))
  }

  return (
    <div className="space-y-3">
      {/* Main Image */}
      <div
        className="relative aspect-[4/3] w-full rounded-xl overflow-hidden bg-gray-100 cursor-pointer group"
        onClick={() => setIsLightboxOpen(true)}
      >
        <Image
          src={currentImage.url}
          alt={currentImage.caption || '캠페인 이미지'}
          fill
          className="object-cover transition-transform group-hover:scale-105"
          priority
        />
        {/* Overlay on hover */}
        <div className="absolute inset-0 bg-black/0 group-hover:bg-black/10 transition-colors flex items-center justify-center">
          <span className="text-white opacity-0 group-hover:opacity-100 transition-opacity text-sm font-medium">
            클릭하여 확대
          </span>
        </div>
        {/* Image counter */}
        {allImages.length > 1 && (
          <div className="absolute bottom-3 right-3 bg-black/60 text-white text-xs px-2 py-1 rounded-full">
            {selectedIndex + 1} / {allImages.length}
          </div>
        )}
      </div>

      {/* Thumbnail Strip */}
      {allImages.length > 1 && (
        <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
          {allImages.map((image, index) => (
            <button
              key={index}
              onClick={() => setSelectedIndex(index)}
              className={`relative flex-shrink-0 w-16 h-16 rounded-lg overflow-hidden border-2 transition-all ${
                selectedIndex === index
                  ? 'border-pink-500 ring-2 ring-pink-200'
                  : 'border-transparent hover:border-gray-300'
              }`}
            >
              <Image
                src={image.url}
                alt={image.caption || `이미지 ${index + 1}`}
                fill
                className="object-cover"
              />
            </button>
          ))}
        </div>
      )}

      {/* Lightbox Dialog */}
      <Dialog open={isLightboxOpen} onOpenChange={setIsLightboxOpen}>
        <DialogContent className="max-w-[90vw] max-h-[90vh] p-0 bg-black border-none">
          <div className="relative w-full h-[80vh]">
            {/* Close button */}
            <Button
              variant="ghost"
              size="sm"
              className="absolute top-4 right-4 z-10 text-white hover:bg-white/20 p-2"
              onClick={() => setIsLightboxOpen(false)}
            >
              <X className="h-6 w-6" />
            </Button>

            {/* Navigation buttons */}
            {allImages.length > 1 && (
              <>
                <Button
                  variant="ghost"
                  size="sm"
                  className="absolute left-4 top-1/2 -translate-y-1/2 z-10 text-white hover:bg-white/20 h-12 w-12 p-2"
                  onClick={handlePrev}
                >
                  <ChevronLeft className="h-8 w-8" />
                </Button>
                <Button
                  variant="ghost"
                  size="sm"
                  className="absolute right-4 top-1/2 -translate-y-1/2 z-10 text-white hover:bg-white/20 h-12 w-12 p-2"
                  onClick={handleNext}
                >
                  <ChevronRight className="h-8 w-8" />
                </Button>
              </>
            )}

            {/* Main lightbox image */}
            <div className="relative w-full h-full">
              <Image
                src={currentImage.url}
                alt={currentImage.caption || '캠페인 이미지'}
                fill
                className="object-contain"
              />
            </div>

            {/* Caption */}
            {currentImage.caption && (
              <div className="absolute bottom-4 left-1/2 -translate-x-1/2 bg-black/60 text-white px-4 py-2 rounded-full text-sm">
                {currentImage.caption}
              </div>
            )}
          </div>
        </DialogContent>
      </Dialog>
    </div>
  )
}
