import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Antiplagiat - Проверка текста на уникальность',
  description: 'AI-powered проверка текстов на плагиат. Быстро, точно, бесплатно. Поддержка русского и английского языков.',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="ru">
      <body>{children}</body>
    </html>
  )
}