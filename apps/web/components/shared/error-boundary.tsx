'use client'

import React from 'react'
import { ErrorDisplay } from './error-display'
import { appLogger } from '@/lib/utils/logger'

interface ErrorBoundaryProps {
  children: React.ReactNode
  fallback?: React.ReactNode
  onError?: (error: Error, errorInfo: React.ErrorInfo) => void
}

interface ErrorBoundaryState {
  hasError: boolean
  error: Error | null
}

/**
 * ErrorBoundary
 *
 * Flutter ErrorBoundary 미러링.
 * 자식 컴포넌트에서 발생하는 에러를 catch하여 ErrorDisplay 렌더링.
 */
export class ErrorBoundary extends React.Component<ErrorBoundaryProps, ErrorBoundaryState> {
  constructor(props: ErrorBoundaryProps) {
    super(props)
    this.state = { hasError: false, error: null }
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo): void {
    appLogger.error(error, 'ErrorBoundary')

    if (this.props.onError) {
      this.props.onError(error, errorInfo)
    }
  }

  handleRetry = (): void => {
    this.setState({ hasError: false, error: null })
  }

  render(): React.ReactNode {
    if (this.state.hasError) {
      if (this.props.fallback) {
        return this.props.fallback
      }

      return (
        <ErrorDisplay
          title="예기치 않은 오류가 발생했습니다"
          message="페이지를 새로고침하거나 잠시 후 다시 시도해 주세요."
          errorCode={this.state.error?.name}
          onRetry={this.handleRetry}
        />
      )
    }

    return this.props.children
  }
}
