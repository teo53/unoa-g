'use client'

import { useState } from 'react'
import { FaqItem } from '@/lib/types/database'
import { ChevronDown, HelpCircle, Search } from 'lucide-react'
import { cn } from '@/lib/utils'

interface FAQTabProps {
  faqs: FaqItem[]
}

export function FAQTab({ faqs }: FAQTabProps) {
  const [openItems, setOpenItems] = useState<Set<string>>(new Set())
  const [searchQuery, setSearchQuery] = useState('')

  if (faqs.length === 0) {
    return (
      <div className="text-center py-12">
        <HelpCircle className="h-12 w-12 text-gray-300 mx-auto mb-4" />
        <p className="text-gray-500">자주 묻는 질문이 없습니다.</p>
      </div>
    )
  }

  const filteredFaqs = searchQuery
    ? faqs.filter(
        faq =>
          faq.question.toLowerCase().includes(searchQuery.toLowerCase()) ||
          faq.answer.toLowerCase().includes(searchQuery.toLowerCase())
      )
    : faqs

  const toggleItem = (id: string) => {
    setOpenItems(prev => {
      const newSet = new Set(prev)
      if (newSet.has(id)) {
        newSet.delete(id)
      } else {
        newSet.add(id)
      }
      return newSet
    })
  }

  const expandAll = () => {
    setOpenItems(new Set(faqs.map(f => f.id)))
  }

  const collapseAll = () => {
    setOpenItems(new Set())
  }

  return (
    <div className="space-y-4">
      {/* Search & Controls */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
          <input
            type="text"
            placeholder="질문 검색..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-pink-200 focus:border-pink-300"
          />
        </div>
        <div className="flex gap-2">
          <button
            onClick={expandAll}
            className="px-3 py-2 text-sm text-gray-600 hover:text-pink-600 hover:bg-pink-50 rounded-lg transition-colors"
          >
            모두 펼치기
          </button>
          <button
            onClick={collapseAll}
            className="px-3 py-2 text-sm text-gray-600 hover:text-pink-600 hover:bg-pink-50 rounded-lg transition-colors"
          >
            모두 접기
          </button>
        </div>
      </div>

      {/* FAQ List */}
      {filteredFaqs.length === 0 ? (
        <div className="text-center py-8 text-gray-500">
          검색 결과가 없습니다.
        </div>
      ) : (
        <div className="divide-y divide-gray-200 border border-gray-200 rounded-xl overflow-hidden">
          {filteredFaqs.map((faq, index) => {
            const isOpen = openItems.has(faq.id)

            return (
              <div key={faq.id} className="bg-white">
                {/* Question */}
                <button
                  onClick={() => toggleItem(faq.id)}
                  className="w-full flex items-start gap-3 p-4 text-left hover:bg-gray-50 transition-colors"
                >
                  <span className="flex-shrink-0 w-6 h-6 bg-pink-100 text-pink-600 rounded-full flex items-center justify-center text-sm font-medium">
                    Q
                  </span>
                  <span className="flex-1 font-medium text-gray-900 pr-8">
                    {faq.question}
                  </span>
                  <ChevronDown
                    className={cn(
                      'h-5 w-5 text-gray-400 transition-transform flex-shrink-0',
                      isOpen && 'rotate-180'
                    )}
                  />
                </button>

                {/* Answer */}
                <div
                  className={cn(
                    'overflow-hidden transition-all duration-200',
                    isOpen ? 'max-h-96' : 'max-h-0'
                  )}
                >
                  <div className="px-4 pb-4 pt-0">
                    <div className="flex gap-3 pl-9">
                      <span className="flex-shrink-0 w-6 h-6 bg-gray-100 text-gray-600 rounded-full flex items-center justify-center text-sm font-medium">
                        A
                      </span>
                      <div className="flex-1 text-gray-700 text-sm leading-relaxed whitespace-pre-wrap">
                        {faq.answer}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )
          })}
        </div>
      )}

      {/* Contact CTA */}
      <div className="bg-gray-50 rounded-xl p-4 text-center">
        <p className="text-sm text-gray-600 mb-2">
          원하는 답변을 찾지 못하셨나요?
        </p>
        <button className="text-sm font-medium text-pink-600 hover:text-pink-700">
          크리에이터에게 문의하기 →
        </button>
      </div>
    </div>
  )
}
