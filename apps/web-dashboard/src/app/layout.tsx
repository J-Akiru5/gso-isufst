import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import { ThemeProvider } from '@/components/providers/theme-provider'
import { Toaster } from '@/components/ui/sonner'
import './globals.css'

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-sans',
  display: 'swap',
})

export const metadata: Metadata = {
  title: {
    default: 'ISUFST Management Portal',
    template: '%s | ISUFST Management Portal',
  },
  description:
    'Iloilo State University of Fisheries and Technology — General Services Office Management System for maintenance requests, equipment borrowing, and inventory management.',
  keywords: ['ISUFST', 'GSO', 'maintenance', 'equipment borrowing', 'inventory'],
  authors: [{ name: 'ISUFST GSO' }],
  robots: 'noindex, nofollow', // Internal system — not for public indexing
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" suppressHydrationWarning className={inter.variable}>
      <body className="font-sans antialiased">
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
        >
          {children}
          <Toaster richColors position="top-right" />
        </ThemeProvider>
      </body>
    </html>
  )
}
