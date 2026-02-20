'use client'

interface ChatMessage {
  text: string
  isCreator: boolean
  name?: string
  delay: number
  emoji?: string
}

const chatMessages: ChatMessage[] = [
  { text: '오늘 공연 최고였어요!!! 🎤', isCreator: false, name: '팬A', delay: 0.3 },
  { text: '사랑해요 ❤️', isCreator: false, name: '팬B', delay: 0.9 },
  { text: '고마워요 여러분~ 오늘 정말 행복했어요 🥰', isCreator: true, delay: 1.8 },
  { text: '다음 공연 언제예요?? 기대돼요!', isCreator: false, name: '팬C', delay: 2.8 },
  { text: '앵콜 감사합니다! 💜', isCreator: false, name: '팬A', delay: 3.5, emoji: '💜' },
]

export function PhoneMockup({ variant = 'creator' }: { variant?: 'creator' | 'fan' }) {
  const messages = variant === 'fan'
    ? chatMessages.filter(m => m.isCreator || m.name === '팬A').map(m => ({
        ...m,
        name: m.isCreator ? undefined : undefined,
      }))
    : chatMessages

  return (
    <div className="phone-frame animate-float-slow">
      <div className="phone-screen">
        {/* Status bar */}
        <div className="h-12 bg-white flex items-center justify-center border-b border-gray-100 pt-6">
          <span className="text-xs font-semibold text-gray-900">
            {variant === 'creator' ? '내 채널' : '하늘달'}
          </span>
        </div>

        {/* Chat messages */}
        <div className="flex-1 p-3 space-y-2 overflow-hidden">
          {messages.map((msg, i) => (
            <div
              key={i}
              className={`flex ${msg.isCreator ? 'justify-end' : 'justify-start'}`}
              style={{
                animation: `chat-bubble-in 0.5s ease-out ${msg.delay}s both`,
              }}
            >
              <div className={`max-w-[80%] ${msg.isCreator ? 'order-1' : ''}`}>
                {!msg.isCreator && variant === 'creator' && msg.name && (
                  <span className="text-[10px] text-gray-400 ml-1 mb-0.5 block">
                    {msg.name}
                  </span>
                )}
                <div
                  className={`px-3 py-2 rounded-2xl text-[11px] leading-relaxed ${
                    msg.isCreator
                      ? 'bg-primary-500 text-white rounded-br-md'
                      : 'bg-gray-100 text-gray-800 rounded-bl-md'
                  }`}
                >
                  {msg.text}
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Input bar */}
        <div className="absolute bottom-0 left-0 right-0 h-12 bg-white border-t border-gray-100 flex items-center px-3 gap-2">
          <div className="flex-1 h-8 bg-gray-50 rounded-full px-3 flex items-center">
            <span className="text-[10px] text-gray-400">
              {variant === 'creator' ? '전체에게 메시지 보내기...' : '메시지 보내기...'}
            </span>
          </div>
          <div className="w-7 h-7 bg-primary-500 rounded-full flex items-center justify-center">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="white">
              <path d="M2 21l21-9L2 3v7l15 2-15 2v7z" />
            </svg>
          </div>
        </div>
      </div>
    </div>
  )
}
