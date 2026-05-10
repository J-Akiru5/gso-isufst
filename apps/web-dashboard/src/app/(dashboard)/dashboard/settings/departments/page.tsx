import { Metadata } from "next"
import { DepartmentsSettingsClient } from "@/components/settings/departments-settings-client"

export const metadata: Metadata = {
  title: "Departments Management | Settings",
  description: "Manage university departments.",
}

export default function DepartmentsSettingsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h3 className="text-lg font-medium">Departments</h3>
        <p className="text-sm text-muted-foreground">
          View and manage the university departments.
        </p>
      </div>
      <DepartmentsSettingsClient />
    </div>
  )
}
