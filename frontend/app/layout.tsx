import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Antiplagiat - AI Plagiarism Detection',
  description: 'Production-grade plagiarism detection platform with ML-powered analysis',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body style={{ margin: 0, padding: 0 }}>{children}</body>
    </html>
  )
}