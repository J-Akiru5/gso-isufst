import jsPDF from 'jspdf'
import autoTable from 'jspdf-autotable'
import * as XLSX from 'xlsx'
import { stringify } from 'csv-stringify/sync'

export async function exportToPDF(title: string, columns: string[], data: any[][]) {
  const doc = new jsPDF()
  
  // Add Header (Logo and Institutional Text)
  try {
    // Attempt to load the logo
    const img = new Image()
    img.src = '/assets/ISUFST_LOGO.png'
    await new Promise((resolve) => {
      img.onload = resolve
      img.onerror = resolve // proceed without image if error
    })
    
    if (img.width > 0) {
      // Add logo to top left
      doc.addImage(img, 'PNG', 14, 10, 20, 20)
    }
  } catch (e) {
    console.error('Could not load logo', e)
  }

  doc.setFontSize(14)
  doc.setFont('helvetica', 'bold')
  doc.text('Iloilo State University of Fisheries Science and Technology', 40, 18)
  
  doc.setFontSize(10)
  doc.setFont('helvetica', 'normal')
  doc.text('General Services Office (GSO)', 40, 24)
  
  doc.setFontSize(16)
  doc.setFont('helvetica', 'bold')
  doc.text(title, 14, 45)
  
  doc.setFontSize(10)
  doc.setFont('helvetica', 'normal')
  doc.text(`Generated on: ${new Date().toLocaleString()}`, 14, 52)

  autoTable(doc, {
    startY: 58,
    head: [columns],
    body: data,
    theme: 'grid',
    styles: { fontSize: 8 },
    headStyles: { fillColor: [0, 61, 98] }, // ISUFST Primary Blue
  })

  doc.save(`${title.replace(/\s+/g, '_').toLowerCase()}.pdf`)
}

export function exportToExcel(filename: string, data: Record<string, any>[]) {
  const worksheet = XLSX.utils.json_to_sheet(data)
  const workbook = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(workbook, worksheet, 'Report')
  
  // Generate buffer
  XLSX.writeFile(workbook, `${filename.replace(/\s+/g, '_').toLowerCase()}.xlsx`)
}

export function exportToCSV(filename: string, data: Record<string, any>[]) {
  const csvContent = stringify(data, { header: true })
  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
  const link = document.createElement('a')
  const url = URL.createObjectURL(blob)
  
  link.setAttribute('href', url)
  link.setAttribute('download', `${filename.replace(/\s+/g, '_').toLowerCase()}.csv`)
  link.style.visibility = 'hidden'
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
}
