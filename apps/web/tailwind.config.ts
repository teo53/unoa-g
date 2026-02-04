import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#FFF5F5',
          100: '#FFE5E5',
          200: '#FFCCCC',
          300: '#FFA3A3',
          400: '#FF7A7A',
          500: '#FF3B30', // Main brand color
          600: '#DE332A',
          700: '#C92D25',
          800: '#A32620',
          900: '#7D1E19',
        },
        surface: {
          light: '#FFFFFF',
          dark: '#1C1C1E',
        },
        background: {
          light: '#F5F5F5',
          dark: '#000000',
        },
      },
      fontFamily: {
        sans: ['Pretendard', '-apple-system', 'BlinkMacSystemFont', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}

export default config
