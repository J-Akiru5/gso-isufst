import type { Metadata } from 'next'
import { ReportGenerator } from '@/components/reports/report-generator'
import { FileBarChart } from 'lucide-react'

export const metadata: Metadata = { title: 'Reports & Analytics' }

export default function ReportsPage() {
  return (
    <div className="space-y-6 animate-slide-up pb-10">
      {/* Page header */}
      <div className="flex items-center gap-3">
        <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center">
          <FileBarChart className="w-5 h-5 text-primary" />
        </div>
        <div>
          <h1 className="text-xl font-bold">Reports &amp; Analytics</h1>
          <p className="text-sm text-muted-foreground">
            Generate and export institutional data for the General Services Office.
          </p>
        </div>
      </div>

      <ReportGenerator />
    </div>
  )
}
