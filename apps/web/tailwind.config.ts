import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        // Brand colors (Flutter AppColors 미러링)
        primary: {
          50: '#FFF5F5',
          100: '#FFE5E5',
          200: '#FFCCCC',
          300: '#FFA3A3',
          400: '#FF7A7A',
          500: '#FF3B30', // Main brand color
          600: '#DE332A', // CTA buttons (4.5:1 contrast)
          700: '#C92D25', // Pressed state
          800: '#A32620',
          900: '#7D1E19',
        },
        // Semantic colors
        semantic: {
          danger: '#B42318',
          'danger-light': '#FEE4E2',
          success: '#16A34A',
          'success-light': '#DCFCE7',
          warning: '#D97706',
          'warning-light': '#FEF3C7',
          info: '#2563EB',
          'info-light': '#DBEAFE',
        },
        // Subscription tier colors
        tier: {
          vip: '#8B5CF6',
          'vip-light': '#EDE9FE',
          standard: '#3B82F6',
          'standard-light': '#DBEAFE',
          basic: '#6B7280',
          'basic-light': '#F3F4F6',
        },
        // Surface/Background
        surface: {
          light: '#FFFFFF',
          dark: '#1C1C1E',
        },
        background: {
          light: '#F5F5F5',
          dark: '#000000',
        },
        // Neutral scale
        neutral: {
          50: '#FAFAFA',
          100: '#F5F5F5',
          200: '#E5E5E5',
          300: '#D4D4D4',
          400: '#A3A3A3',
          500: '#737373',
          600: '#525252',
          700: '#404040',
          800: '#262626',
          900: '#171717',
        },
      },
      // Spacing scale (Flutter AppSpacing 미러링)
      spacing: {
        xs: '4px',
        sm: '8px',
        md: '12px',
        base: '16px',
        lg: '20px',
        xl: '24px',
        '2xl': '32px',
        '3xl': '40px',
        '4xl': '48px',
      },
      // Border radius (Flutter AppRadius 미러링)
      borderRadius: {
        sm: '8px',
        md: '10px',
        lg: '14px',
        xl: '18px',
        '2xl': '24px',
      },
      // Max width for content containers
      maxWidth: {
        content: '1200px',
        narrow: '800px',
        wide: '1440px',
      },
      fontFamily: {
        sans: ['Pretendard', '-apple-system', 'BlinkMacSystemFont', 'system-ui', 'sans-serif'],
      },
      // Animations
      keyframes: {
        'fade-in': {
          '0%': { opacity: '0', transform: 'translateY(8px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        'slide-up': {
          '0%': { opacity: '0', transform: 'translateY(16px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        'count-up': {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
      },
      animation: {
        'fade-in': 'fade-in 0.3s ease-out',
        'slide-up': 'slide-up 0.4s ease-out',
        'count-up': 'count-up 0.6s ease-out',
      },
    },
  },
  plugins: [],
}

export default config
