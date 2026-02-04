import Link from 'next/link'
import { ArrowRight, Heart, Star, Users } from 'lucide-react'
import { DEMO_MODE } from '@/lib/mock/demo-data'

export default function HomePage() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-white to-gray-50">
      {/* Demo Banner */}
      {DEMO_MODE && (
        <div className="bg-amber-50 border-b border-amber-200 px-4 py-2 text-center text-sm text-amber-800">
          Demo Mode - Mock data is displayed
        </div>
      )}
      {/* Header */}
      <header className="sticky top-0 z-50 bg-white/80 backdrop-blur-md border-b border-gray-100">
        <div className="max-w-6xl mx-auto px-4 h-16 flex items-center justify-between">
          <Link href="/" className="text-2xl font-bold text-primary-500">
            UNO A
          </Link>
          <nav className="flex items-center gap-4">
            <Link
              href="/funding"
              className="text-gray-600 hover:text-gray-900 transition-colors"
            >
              펀딩 둘러보기
            </Link>
            <Link
              href="/studio"
              className="px-4 py-2 bg-primary-500 text-white rounded-full hover:bg-primary-600 transition-colors"
            >
              크리에이터 스튜디오
            </Link>
          </nav>
        </div>
      </header>

      {/* Hero */}
      <section className="py-20 px-4">
        <div className="max-w-4xl mx-auto text-center">
          <h1 className="text-4xl md:text-6xl font-bold text-gray-900 mb-6">
            좋아하는 크리에이터의
            <br />
            <span className="text-primary-500">새로운 시작</span>을 응원하세요
          </h1>
          <p className="text-lg md:text-xl text-gray-600 mb-8 max-w-2xl mx-auto">
            UNO A에서 크리에이터들의 특별한 프로젝트를 후원하고,
            <br />
            세상에 하나뿐인 리워드를 받아보세요.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link
              href="/funding"
              className="inline-flex items-center justify-center gap-2 px-8 py-4 bg-primary-500 text-white rounded-full text-lg font-medium hover:bg-primary-600 transition-colors"
            >
              펀딩 둘러보기
              <ArrowRight className="w-5 h-5" />
            </Link>
            <Link
              href="/studio"
              className="inline-flex items-center justify-center gap-2 px-8 py-4 bg-white text-gray-900 rounded-full text-lg font-medium border-2 border-gray-200 hover:border-primary-500 transition-colors"
            >
              크리에이터로 시작하기
            </Link>
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="py-20 px-4 bg-white">
        <div className="max-w-6xl mx-auto">
          <h2 className="text-3xl font-bold text-center mb-12">
            UNO A가 특별한 이유
          </h2>
          <div className="grid md:grid-cols-3 gap-8">
            <div className="p-6 rounded-2xl bg-gray-50 hover:bg-gray-100 transition-colors">
              <div className="w-12 h-12 bg-primary-100 rounded-xl flex items-center justify-center mb-4">
                <Heart className="w-6 h-6 text-primary-500" />
              </div>
              <h3 className="text-xl font-semibold mb-2">진정한 팬 연결</h3>
              <p className="text-gray-600">
                크리에이터와 팬이 직접 소통하며 함께 프로젝트를 만들어갑니다.
              </p>
            </div>
            <div className="p-6 rounded-2xl bg-gray-50 hover:bg-gray-100 transition-colors">
              <div className="w-12 h-12 bg-primary-100 rounded-xl flex items-center justify-center mb-4">
                <Star className="w-6 h-6 text-primary-500" />
              </div>
              <h3 className="text-xl font-semibold mb-2">독점 리워드</h3>
              <p className="text-gray-600">
                후원자만을 위한 특별한 리워드와 혜택을 제공합니다.
              </p>
            </div>
            <div className="p-6 rounded-2xl bg-gray-50 hover:bg-gray-100 transition-colors">
              <div className="w-12 h-12 bg-primary-100 rounded-xl flex items-center justify-center mb-4">
                <Users className="w-6 h-6 text-primary-500" />
              </div>
              <h3 className="text-xl font-semibold mb-2">커뮤니티</h3>
              <p className="text-gray-600">
                같은 취향을 가진 팬들과 함께하는 특별한 경험을 선사합니다.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-20 px-4">
        <div className="max-w-4xl mx-auto text-center">
          <h2 className="text-3xl font-bold mb-4">
            지금 바로 시작하세요
          </h2>
          <p className="text-gray-600 mb-8">
            크리에이터로서 새로운 프로젝트를 시작하거나,
            <br />
            팬으로서 좋아하는 크리에이터를 응원해보세요.
          </p>
          <Link
            href="/funding"
            className="inline-flex items-center justify-center gap-2 px-8 py-4 bg-primary-500 text-white rounded-full text-lg font-medium hover:bg-primary-600 transition-colors"
          >
            펀딩 둘러보기
            <ArrowRight className="w-5 h-5" />
          </Link>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 px-4 bg-gray-900 text-white">
        <div className="max-w-6xl mx-auto">
          <div className="flex flex-col md:flex-row justify-between items-center gap-4">
            <div className="text-2xl font-bold">UNO A</div>
            <div className="flex gap-6 text-gray-400">
              <Link href="/funding" className="hover:text-white transition-colors">
                펀딩
              </Link>
              <Link href="/studio" className="hover:text-white transition-colors">
                스튜디오
              </Link>
              <Link href="/help" className="hover:text-white transition-colors">
                고객센터
              </Link>
            </div>
          </div>
          <div className="mt-8 pt-8 border-t border-gray-800 text-center text-gray-500 text-sm">
            &copy; {new Date().getFullYear()} UNO A. All rights reserved.
          </div>
        </div>
      </footer>
    </div>
  )
}
