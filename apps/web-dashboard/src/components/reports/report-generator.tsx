'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { FileText, Table, FileSpreadsheet, Download, Loader2 } from 'lucide-react'
import { exportToCSV, exportToExcel, exportToPDF } from '@/lib/exports'
import { toast } from 'sonner'
import { format } from 'date-fns'

export function ReportGenerator() {
  const supabase = createClient()
  const [isLoading, setIsLoading] = useState(false)
  const [activeTab, setActiveTab] = useState('maintenance')

  // We could add DatePickers here for start/end dates, but for now we'll export all or recent data to keep it straightforward.
  
  const handleExport = async (formatType: 'pdf' | 'excel' | 'csv') => {
    setIsLoading(true)
    try {
      if (activeTab === 'maintenance') {
        const { data, error } = await supabase
          .from('maintenance_requests')
          .select('request_number, title, priority_level, status, created_at')
          .order('created_at', { ascending: false })
          
        if (error) throw error
        if (!data || data.length === 0) {
          toast.error('No data found for maintenance requests.')
          return
        }

        const formattedData = data.map(d => ({
          'Request No': d.request_number,
          'Title': d.title,
          'Priority': d.priority_level,
          'Status': d.status.replace(/_/g, ' '),
          'Date Submitted': format(new Date(d.created_at), 'MMM dd, yyyy'),
        }))

        if (formatType === 'pdf') {
          exportToPDF(
            'Maintenance Requests Report', 
            ['Request No', 'Title', 'Priority', 'Status', 'Date Submitted'], 
            formattedData.map(Object.values)
          )
        } else if (formatType === 'excel') {
          exportToExcel('maintenance_report', formattedData)
        } else {
          exportToCSV('maintenance_report', formattedData)
        }
      } 
      else if (activeTab === 'inventory') {
        const { data, error } = await supabase
          .from('inventory_items')
          .select('item_code, name, condition, quantity, is_borrowable, acquisition_date')
          .order('name')
          
        if (error) throw error
        if (!data || data.length === 0) {
          toast.error('No data found for inventory.')
          return
        }

        const formattedData = data.map(d => ({
          'Item Code': d.item_code,
          'Name': d.name,
          'Condition': d.condition,
          'Quantity': d.quantity,
          'Borrowable': d.is_borrowable ? 'Yes' : 'No',
          'Acquisition Date': d.acquisition_date ? format(new Date(d.acquisition_date), 'MMM dd, yyyy') : 'N/A',
        }))

        if (formatType === 'pdf') {
          exportToPDF(
            'Inventory Status Report', 
            ['Item Code', 'Name', 'Condition', 'Quantity', 'Borrowable', 'Acquisition Date'], 
            formattedData.map(Object.values)
          )
        } else if (formatType === 'excel') {
          exportToExcel('inventory_report', formattedData)
        } else {
          exportToCSV('inventory_report', formattedData)
        }
      }
      else if (activeTab === 'borrowing') {
        const { data, error } = await supabase
          .from('equipment_loans')
          .select('loan_number, item_id, loan_type, expected_return_date, status, created_at, inventory_items(name)')
          .order('created_at', { ascending: false })
          
        if (error) throw error
        if (!data || data.length === 0) {
          toast.error('No data found for equipment loans.')
          return
        }

        const formattedData = data.map(d => ({
          'Loan No': d.loan_number,
          'Item': (d.inventory_items as any)?.name || 'Unknown',
          'Type': d.loan_type,
          'Status': d.status.replace(/_/g, ' '),
          'Expected Return': format(new Date(d.expected_return_date), 'MMM dd, yyyy'),
          'Date Requested': format(new Date(d.created_at), 'MMM dd, yyyy'),
        }))

        if (formatType === 'pdf') {
          exportToPDF(
            'Equipment Borrowing Report', 
            ['Loan No', 'Item', 'Type', 'Status', 'Expected Return', 'Date Requested'], 
            formattedData.map(Object.values)
          )
        } else if (formatType === 'excel') {
          exportToExcel('borrowing_report', formattedData)
        } else {
          exportToCSV('borrowing_report', formattedData)
        }
      }

      toast.success('Report generated successfully!')
    } catch (error: any) {
      console.error(error)
      toast.error(error.message || 'Failed to generate report')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <Card className="max-w-4xl">
      <CardHeader>
        <CardTitle>Report Generator</CardTitle>
        <CardDescription>Select the type of report you want to generate and download it in your preferred format.</CardDescription>
      </CardHeader>
      <CardContent>
        <Tabs defaultValue="maintenance" value={activeTab} onValueChange={setActiveTab} className="w-full">
          <TabsList className="grid w-full grid-cols-3 mb-8">
            <TabsTrigger value="maintenance">Maintenance</TabsTrigger>
            <TabsTrigger value="inventory">Inventory</TabsTrigger>
            <TabsTrigger value="borrowing">Borrowing</TabsTrigger>
          </TabsList>
          
          <div className="space-y-6">
            <div className="bg-muted/30 p-6 rounded-lg border border-border flex flex-col items-center justify-center min-h-[200px] text-center">
              <Download className="w-10 h-10 text-muted-foreground mb-4 opacity-50" />
              <h3 className="text-lg font-medium mb-2">
                {activeTab === 'maintenance' && 'Maintenance Requests Overview'}
                {activeTab === 'inventory' && 'Current Inventory Status'}
                {activeTab === 'borrowing' && 'Equipment Borrowing History'}
              </h3>
              <p className="text-sm text-muted-foreground max-w-md">
                Generates a comprehensive report containing all current records from the database. Make sure you have pop-ups enabled for downloads.
              </p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <Button 
                onClick={() => handleExport('pdf')} 
                disabled={isLoading}
                variant="outline" 
                className="w-full h-14 flex flex-col gap-1 items-center justify-center hover:border-red-500/50 hover:bg-red-500/5"
              >
                {isLoading ? <Loader2 className="w-5 h-5 animate-spin" /> : <FileText className="w-5 h-5 text-red-500" />}
                <span className="text-xs font-semibold">Download PDF</span>
              </Button>
              <Button 
                onClick={() => handleExport('excel')} 
                disabled={isLoading}
                variant="outline" 
                className="w-full h-14 flex flex-col gap-1 items-center justify-center hover:border-green-500/50 hover:bg-green-500/5"
              >
                {isLoading ? <Loader2 className="w-5 h-5 animate-spin" /> : <FileSpreadsheet className="w-5 h-5 text-green-600" />}
                <span className="text-xs font-semibold">Download Excel</span>
              </Button>
              <Button 
                onClick={() => handleExport('csv')} 
                disabled={isLoading}
                variant="outline" 
                className="w-full h-14 flex flex-col gap-1 items-center justify-center hover:border-blue-500/50 hover:bg-blue-500/5"
              >
                {isLoading ? <Loader2 className="w-5 h-5 animate-spin" /> : <Table className="w-5 h-5 text-blue-500" />}
                <span className="text-xs font-semibold">Download CSV</span>
              </Button>
            </div>
          </div>
        </Tabs>
      </CardContent>
    </Card>
  )
}
